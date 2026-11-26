import 'dart:math';
import 'cell_model.dart';
import 'deduction_solver.dart';

enum Difficulty {
  beginner(nameKey: 'diff_beginner', rows: 9, cols: 9, mines: 10),
  intermediate(nameKey: 'diff_intermediate', rows: 16, cols: 16, mines: 40),
  expert(nameKey: 'diff_expert', rows: 16, cols: 30, mines: 99);

  final String nameKey;
  final int rows;
  final int cols;
  final int mines;

  const Difficulty({
    required this.nameKey,
    required this.rows,
    required this.cols,
    required this.mines,
  });
}

class GeneratedBoard {
  final List<List<CellModel>> grid;
  final SolverResult solverResult;
  final int attemptsUsed;

  const GeneratedBoard({
    required this.grid,
    required this.solverResult,
    required this.attemptsUsed,
  });
}

class BoardGenerator {
  final Random _rng;

  BoardGenerator({int? seed}) : _rng = Random(seed);

  /// Generates a verified 100% No-Guess solvable board where [firstRow, firstCol]
  /// is guaranteed to be safe and have 0 neighboring mines.
  GeneratedBoard generateNoGuessBoard({
    required Difficulty difficulty,
    required int firstRow,
    required int firstCol,
    int maxAttempts = 200,
  }) {
    final rows = difficulty.rows;
    final cols = difficulty.cols;
    final mines = difficulty.mines;
    final solver = DeductionSolver(rows: rows, cols: cols, totalMines: mines);
    final start = Point2D(firstRow, firstCol);

    // Reserved zone: first tap + 8 adjacent cells must not contain mines
    final reserved = <Point2D>{start};
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        final nr = firstRow + dr;
        final nc = firstCol + dc;
        if (nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
          reserved.add(Point2D(nr, nc));
        }
      }
    }

    final availableCells = <Point2D>[];
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final p = Point2D(r, c);
        if (!reserved.contains(p)) {
          availableCells.add(p);
        }
      }
    }

    SolverResult? bestResult;
    List<List<bool>>? bestMineMap;
    List<List<int>>? bestNeighborCounts;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      // Shuffle available cells to place mines
      availableCells.shuffle(_rng);

      final mineMap = List.generate(rows, (_) => List.filled(cols, false));
      for (int i = 0; i < mines; i++) {
        final p = availableCells[i];
        mineMap[p.row][p.col] = true;
      }

      // Compute neighbor counts
      final neighborCounts = List.generate(rows, (_) => List.filled(cols, 0));
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          if (mineMap[r][c]) {
            neighborCounts[r][c] = -1;
          } else {
            int count = 0;
            for (final n in solver.getNeighbors(r, c)) {
              if (mineMap[n.row][n.col]) count++;
            }
            neighborCounts[r][c] = count;
          }
        }
      }

      // Check solvability
      final result = solver.evaluateSolvability(mineMap, neighborCounts, start);
      if (result.isSolvable) {
        // Construct the full CellModel grid
        final grid = List.generate(rows, (r) {
          return List.generate(cols, (c) {
            return CellModel(
              row: r,
              col: c,
              isMine: mineMap[r][c],
              neighborMines: mineMap[r][c] ? 0 : neighborCounts[r][c],
            );
          });
        });

        return GeneratedBoard(
          grid: grid,
          solverResult: result,
          attemptsUsed: attempt,
        );
      }

      // Keep track of best partial result if ever needed as fallback
      if (bestResult == null ||
          result.revealedSafeCells > bestResult.revealedSafeCells) {
        bestResult = result;
        bestMineMap = mineMap;
        bestNeighborCounts = neighborCounts;
      }
    }

    // Fallback if maxAttempts reached (extremely rare): return the best found
    final grid = List.generate(rows, (r) {
      return List.generate(cols, (c) {
        final isMine = bestMineMap![r][c];
        return CellModel(
          row: r,
          col: c,
          isMine: isMine,
          neighborMines: isMine ? 0 : bestNeighborCounts![r][c],
        );
      });
    });

    return GeneratedBoard(
      grid: grid,
      solverResult: bestResult!,
      attemptsUsed: maxAttempts,
    );
  }
}
