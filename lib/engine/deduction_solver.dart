import 'cell_model.dart';

/// Represents a single deductive logical deduction step
class DeductionStep {
  final List<Point2D> safeCells;
  final List<Point2D> mineCells;
  final List<Point2D> sourceClueCells; // Clues that justify this deduction
  final String ruleType; // 'single', 'subset', 'bounds', 'global'

  const DeductionStep({
    required this.safeCells,
    required this.mineCells,
    required this.sourceClueCells,
    required this.ruleType,
  });

  bool get isEmpty => safeCells.isEmpty && mineCells.isEmpty;
  bool get isNotEmpty => !isEmpty;
}

/// Result of full board solvability analysis
class SolverResult {
  final bool isSolvable;
  final int revealedSafeCells;
  final int totalSafeCells;
  final List<DeductionStep> steps;

  const SolverResult({
    required this.isSolvable,
    required this.revealedSafeCells,
    required this.totalSafeCells,
    required this.steps,
  });
}

/// Logical deduction solver for No-Guess Minesweeper
class DeductionSolver {
  final int rows;
  final int cols;
  final int totalMines;

  const DeductionSolver({
    required this.rows,
    required this.cols,
    required this.totalMines,
  });

  bool isInBounds(int r, int c) => r >= 0 && r < rows && c >= 0 && c < cols;

  List<Point2D> getNeighbors(int r, int c) {
    final list = <Point2D>[];
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final nr = r + dr;
        final nc = c + dc;
        if (isInBounds(nr, nc)) {
          list.add(Point2D(nr, nc));
        }
      }
    }
    return list;
  }

  /// Evaluates whether a given mine layout can be 100% solved without guessing
  /// starting from [startPoint] (which must be a safe cell, ideally a 0).
  SolverResult evaluateSolvability(
    List<List<bool>> mineMap,
    List<List<int>> neighborCounts,
    Point2D startPoint,
  ) {
    // Current solver knowledge state
    // revealed[r][c] == true means the solver has revealed this cell
    final revealed = List.generate(rows, (_) => List.filled(cols, false));
    // flagged[r][c] == true means the solver has deduced a mine here
    final flagged = List.generate(rows, (_) => List.filled(cols, false));

    int totalSafeCells = 0;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (!mineMap[r][c]) totalSafeCells++;
      }
    }

    // Step 0: Reveal the starting cell and cascade if 0
    int revealedSafeCount = 0;
    void reveal(Point2D p) {
      if (revealed[p.row][p.col] || flagged[p.row][p.col]) return;
      revealed[p.row][p.col] = true;
      revealedSafeCount++;

      // Cascade open if 0
      if (neighborCounts[p.row][p.col] == 0) {
        final queue = <Point2D>[p];
        while (queue.isNotEmpty) {
          final curr = queue.removeLast();
          for (final n in getNeighbors(curr.row, curr.col)) {
            if (!revealed[n.row][n.col] && !flagged[n.row][n.col]) {
              revealed[n.row][n.col] = true;
              revealedSafeCount++;
              if (neighborCounts[n.row][n.col] == 0) {
                queue.add(n);
              }
            }
          }
        }
      }
    }

    reveal(startPoint);

    final steps = <DeductionStep>[];

    // Iterative logical deduction loop
    bool progress = true;
    while (progress && revealedSafeCount < totalSafeCells) {
      progress = false;

      // Find all frontier revealed clues
      final frontier = <Point2D>[];
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          if (revealed[r][c] && neighborCounts[r][c] > 0) {
            // Check if it has any unrevealed neighbors
            bool hasUnrevealed = false;
            for (final n in getNeighbors(r, c)) {
              if (!revealed[n.row][n.col] && !flagged[n.row][n.col]) {
                hasUnrevealed = true;
                break;
              }
            }
            if (hasUnrevealed) frontier.add(Point2D(r, c));
          }
        }
      }

      if (frontier.isEmpty && revealedSafeCount < totalSafeCells) {
        // Frontier is empty but game not solved: stuck or isolated
        break;
      }

      // Rule 1: Single-cell deductions
      for (final p in frontier) {
        final neighbors = getNeighbors(p.row, p.col);
        final unrevealed = <Point2D>[];
        int flagCount = 0;

        for (final n in neighbors) {
          if (flagged[n.row][n.col]) {
            flagCount++;
          } else if (!revealed[n.row][n.col]) {
            unrevealed.add(n);
          }
        }

        final remMines = neighborCounts[p.row][p.col] - flagCount;

        if (unrevealed.isNotEmpty) {
          // Rule 1A: remMines == 0 => all unrevealed are safe
          if (remMines == 0) {
            final safeList = List<Point2D>.from(unrevealed);
            steps.add(DeductionStep(
              safeCells: safeList,
              mineCells: const [],
              sourceClueCells: [p],
              ruleType: 'single',
            ));
            for (final s in safeList) {
              reveal(s);
            }
            progress = true;
            break;
          }

          // Rule 1B: remMines == unrevealed.length => all unrevealed are mines
          if (remMines == unrevealed.length) {
            final mineList = List<Point2D>.from(unrevealed);
            steps.add(DeductionStep(
              safeCells: const [],
              mineCells: mineList,
              sourceClueCells: [p],
              ruleType: 'single',
            ));
            for (final m in mineList) {
              flagged[m.row][m.col] = true;
            }
            progress = true;
            break;
          }
        }
      }

      if (progress) continue;

      // Rule 2: Subset-Superset Reductions (Pairwise overlaps: 1-1, 1-2, etc.)
      // Map each frontier clue to its unrevealed set and remaining mines
      final clueInfo = <Point2D, _ClueData>{};
      for (final p in frontier) {
        final neighbors = getNeighbors(p.row, p.col);
        final unrevealed = <Point2D>{};
        int flagCount = 0;
        for (final n in neighbors) {
          if (flagged[n.row][n.col]) {
            flagCount++;
          } else if (!revealed[n.row][n.col]) {
            unrevealed.add(n);
          }
        }
        clueInfo[p] = _ClueData(
          unrevealed: unrevealed,
          remMines: neighborCounts[p.row][p.col] - flagCount,
        );
      }

      final frontierList = frontier;
      for (int i = 0; i < frontierList.length; i++) {
        final p1 = frontierList[i];
        final info1 = clueInfo[p1]!;
        if (info1.unrevealed.isEmpty) continue;

        for (int j = 0; j < frontierList.length; j++) {
          if (i == j) continue;
          final p2 = frontierList[j];
          final info2 = clueInfo[p2]!;
          if (info2.unrevealed.isEmpty) continue;

          // Check if info1.unrevealed is a subset of info2.unrevealed
          if (info2.unrevealed.containsAll(info1.unrevealed)) {
            final diff = info2.unrevealed.difference(info1.unrevealed);
            final diffMines = info2.remMines - info1.remMines;

            if (diff.isNotEmpty) {
              // If diffMines == 0 => all cells in diff are safe!
              if (diffMines == 0) {
                final safeList = diff.toList();
                steps.add(DeductionStep(
                  safeCells: safeList,
                  mineCells: const [],
                  sourceClueCells: [p1, p2],
                  ruleType: 'subset',
                ));
                for (final s in safeList) {
                  reveal(s);
                }
                progress = true;
                break;
              }

              // If diffMines == diff.length => all cells in diff are mines!
              if (diffMines == diff.length) {
                final mineList = diff.toList();
                steps.add(DeductionStep(
                  safeCells: const [],
                  mineCells: mineList,
                  sourceClueCells: [p1, p2],
                  ruleType: 'subset',
                ));
                for (final m in mineList) {
                  flagged[m.row][m.col] = true;
                }
                progress = true;
                break;
              }
            }
          }
        }
        if (progress) break;
      }

      if (progress) continue;

      // Rule 3: Coupled bounds intersection
      // For any two overlapping clues A and B:
      // S_both = U(A) ∩ U(B)
      // S_onlyA = U(A) \ U(B)
      // S_onlyB = U(B) \ U(A)
      // max(0, rem(A) - |S_onlyA|, rem(B) - |S_onlyB|) <= m_both <= min(rem(A), rem(B), |S_both|)
      for (int i = 0; i < frontierList.length; i++) {
        final p1 = frontierList[i];
        final info1 = clueInfo[p1]!;
        if (info1.unrevealed.isEmpty) continue;

        for (int j = i + 1; j < frontierList.length; j++) {
          final p2 = frontierList[j];
          final info2 = clueInfo[p2]!;
          if (info2.unrevealed.isEmpty) continue;

          final intersection = info1.unrevealed.intersection(info2.unrevealed);
          if (intersection.isEmpty) continue;

          final only1 = info1.unrevealed.difference(intersection);
          final only2 = info2.unrevealed.difference(intersection);

          final minBoth1 = info1.remMines - only1.length;
          final minBoth2 = info2.remMines - only2.length;
          int minBoth = 0;
          if (minBoth1 > minBoth) minBoth = minBoth1;
          if (minBoth2 > minBoth) minBoth = minBoth2;

          int maxBoth = intersection.length;
          if (info1.remMines < maxBoth) maxBoth = info1.remMines;
          if (info2.remMines < maxBoth) maxBoth = info2.remMines;

          // Check if only1 can be deduced
          if (only1.isNotEmpty) {
            // If minBoth == info1.remMines => only1 has 0 mines (all safe)
            if (minBoth == info1.remMines) {
              final safeList = only1.toList();
              steps.add(DeductionStep(
                safeCells: safeList,
                mineCells: const [],
                sourceClueCells: [p1, p2],
                ruleType: 'bounds',
              ));
              for (final s in safeList) {
                reveal(s);
              }
              progress = true;
              break;
            }
            // If maxBoth == info1.remMines - only1.length => all only1 are mines
            if (info1.remMines - maxBoth == only1.length) {
              final mineList = only1.toList();
              steps.add(DeductionStep(
                safeCells: const [],
                mineCells: mineList,
                sourceClueCells: [p1, p2],
                ruleType: 'bounds',
              ));
              for (final m in mineList) {
                flagged[m.row][m.col] = true;
              }
              progress = true;
              break;
            }
          }

          // Check if only2 can be deduced
          if (only2.isNotEmpty) {
            if (minBoth == info2.remMines) {
              final safeList = only2.toList();
              steps.add(DeductionStep(
                safeCells: safeList,
                mineCells: const [],
                sourceClueCells: [p1, p2],
                ruleType: 'bounds',
              ));
              for (final s in safeList) {
                reveal(s);
              }
              progress = true;
              break;
            }
            if (info2.remMines - maxBoth == only2.length) {
              final mineList = only2.toList();
              steps.add(DeductionStep(
                safeCells: const [],
                mineCells: mineList,
                sourceClueCells: [p1, p2],
                ruleType: 'bounds',
              ));
              for (final m in mineList) {
                flagged[m.row][m.col] = true;
              }
              progress = true;
              break;
            }
          }
        }
        if (progress) break;
      }

      if (progress) continue;

      // Rule 4: Global Mine Count deduction (End-game remaining mines)
      int currentFlags = 0;
      int unrevealedCount = 0;
      final unrevealedList = <Point2D>[];
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          if (flagged[r][c]) {
            currentFlags++;
          } else if (!revealed[r][c]) {
            unrevealedCount++;
            unrevealedList.add(Point2D(r, c));
          }
        }
      }

      final remGlobalMines = totalMines - currentFlags;
      if (unrevealedCount > 0) {
        if (remGlobalMines == 0) {
          // All unrevealed remaining cells are safe!
          steps.add(DeductionStep(
            safeCells: unrevealedList,
            mineCells: const [],
            sourceClueCells: const [],
            ruleType: 'global',
          ));
          for (final s in unrevealedList) {
            reveal(s);
          }
          progress = true;
        } else if (remGlobalMines == unrevealedCount) {
          // All unrevealed remaining cells are mines!
          steps.add(DeductionStep(
            safeCells: const [],
            mineCells: unrevealedList,
            sourceClueCells: const [],
            ruleType: 'global',
          ));
          for (final m in unrevealedList) {
            flagged[m.row][m.col] = true;
          }
          progress = true;
        }
      }
    }

    final isSolvable = (revealedSafeCount == totalSafeCells);
    return SolverResult(
      isSolvable: isSolvable,
      revealedSafeCells: revealedSafeCount,
      totalSafeCells: totalSafeCells,
      steps: steps,
    );
  }

  /// Calculates the next logically guaranteed hint step based on the player's
  /// CURRENT interactive board state.
  DeductionStep? findNextHint(
    List<List<CellModel>> grid,
  ) {
    // 1. Single cell deductions
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final cell = grid[r][c];
        if (!cell.isRevealed || cell.neighborMines == 0) continue;

        final neighbors = getNeighbors(r, c);
        final unrevealed = <Point2D>[];
        int flagCount = 0;

        for (final n in neighbors) {
          final nc = grid[n.row][n.col];
          if (nc.isFlagged) {
            flagCount++;
          } else if (!nc.isRevealed) {
            unrevealed.add(n);
          }
        }

        if (unrevealed.isEmpty) continue;

        final remMines = cell.neighborMines - flagCount;

        if (remMines == 0) {
          return DeductionStep(
            safeCells: unrevealed,
            mineCells: const [],
            sourceClueCells: [Point2D(r, c)],
            ruleType: 'single',
          );
        }

        if (remMines == unrevealed.length) {
          return DeductionStep(
            safeCells: const [],
            mineCells: unrevealed,
            sourceClueCells: [Point2D(r, c)],
            ruleType: 'single',
          );
        }
      }
    }

    // 2. Subset reductions
    final frontier = <Point2D>[];
    final clueMap = <Point2D, _ClueData>{};

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final cell = grid[r][c];
        if (!cell.isRevealed || cell.neighborMines == 0) continue;

        final neighbors = getNeighbors(r, c);
        final unrevealed = <Point2D>{};
        int flagCount = 0;

        for (final n in neighbors) {
          final nc = grid[n.row][n.col];
          if (nc.isFlagged) {
            flagCount++;
          } else if (!nc.isRevealed) {
            unrevealed.add(n);
          }
        }

        if (unrevealed.isNotEmpty) {
          final p = Point2D(r, c);
          frontier.add(p);
          clueMap[p] = _ClueData(
            unrevealed: unrevealed,
            remMines: cell.neighborMines - flagCount,
          );
        }
      }
    }

    for (int i = 0; i < frontier.length; i++) {
      final p1 = frontier[i];
      final info1 = clueMap[p1]!;
      for (int j = 0; j < frontier.length; j++) {
        if (i == j) continue;
        final p2 = frontier[j];
        final info2 = clueMap[p2]!;

        if (info2.unrevealed.containsAll(info1.unrevealed)) {
          final diff = info2.unrevealed.difference(info1.unrevealed);
          final diffMines = info2.remMines - info1.remMines;

          if (diff.isNotEmpty) {
            if (diffMines == 0) {
              return DeductionStep(
                safeCells: diff.toList(),
                mineCells: const [],
                sourceClueCells: [p1, p2],
                ruleType: 'subset',
              );
            }
            if (diffMines == diff.length) {
              return DeductionStep(
                safeCells: const [],
                mineCells: diff.toList(),
                sourceClueCells: [p1, p2],
                ruleType: 'subset',
              );
            }
          }
        }
      }
    }

    // 3. Global count hint
    int currentFlags = 0;
    final unrevealedAll = <Point2D>[];
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final cell = grid[r][c];
        if (cell.isFlagged) {
          currentFlags++;
        } else if (!cell.isRevealed) {
          unrevealedAll.add(Point2D(r, c));
        }
      }
    }

    final remGlobal = totalMines - currentFlags;
    if (unrevealedAll.isNotEmpty) {
      if (remGlobal == 0) {
        return DeductionStep(
          safeCells: unrevealedAll,
          mineCells: const [],
          sourceClueCells: const [],
          ruleType: 'global',
        );
      }
      if (remGlobal == unrevealedAll.length) {
        return DeductionStep(
          safeCells: const [],
          mineCells: unrevealedAll,
          sourceClueCells: const [],
          ruleType: 'global',
        );
      }
    }

    return null;
  }
}

class _ClueData {
  final Set<Point2D> unrevealed;
  final int remMines;

  _ClueData({required this.unrevealed, required this.remMines});
}
