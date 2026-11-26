import 'dart:async';
import 'board_generator.dart';
import 'cell_model.dart';
import 'deduction_solver.dart';

enum GameStatus {
  initial,
  playing,
  won,
  lost,
}

/// Represents a snapshot of the grid for Undo support
class GridSnapshot {
  final List<List<CellModel>> grid;
  final GameStatus status;
  final int elapsedTimeSeconds;
  final int flagsRemaining;

  GridSnapshot({
    required this.grid,
    required this.status,
    required this.elapsedTimeSeconds,
    required this.flagsRemaining,
  });

  static GridSnapshot capture(
    List<List<CellModel>> grid,
    GameStatus status,
    int elapsed,
    int flags,
  ) {
    final clonedGrid = List.generate(
      grid.length,
      (r) => List.generate(grid[r].length, (c) => grid[r][c]),
    );
    return GridSnapshot(
      grid: clonedGrid,
      status: status,
      elapsedTimeSeconds: elapsed,
      flagsRemaining: flags,
    );
  }
}

class GameEngine {
  Difficulty difficulty;
  final BoardGenerator _generator;
  late DeductionSolver _solver;

  GameStatus status = GameStatus.initial;
  List<List<CellModel>> grid = [];
  bool isFlagMode = false;
  int elapsedTimeSeconds = 0;
  Timer? _timer;

  // History stack for Undo
  final List<GridSnapshot> _history = [];
  static const int maxHistory = 50;

  // Active Hint State
  DeductionStep? currentHint;

  // Callbacks
  Function()? onStateChanged;
  Function(Point2D clickedPoint, int totalRevealed)? onCascadeReveal;
  Function()? onFlagPlaced;
  Function()? onFlagRemoved;
  Function()? onDetonate;
  Function()? onVictory;
  Function()? onHintShown;

  GameEngine({
    this.difficulty = Difficulty.beginner,
    int? seed,
  }) : _generator = BoardGenerator(seed: seed) {
    _initEngine();
  }

  int get rows => difficulty.rows;
  int get cols => difficulty.cols;
  int get totalMines => difficulty.mines;

  int get flagsUsed {
    int count = 0;
    for (final row in grid) {
      for (final cell in row) {
        if (cell.isFlagged) count++;
      }
    }
    return count;
  }

  int get flagsRemaining => totalMines - flagsUsed;

  int get revealedCount {
    int count = 0;
    for (final row in grid) {
      for (final cell in row) {
        if (cell.isRevealed) count++;
      }
    }
    return count;
  }

  int get totalSafeCells => (rows * cols) - totalMines;

  bool get canUndo => _history.isNotEmpty;

  void _initEngine() {
    _solver = DeductionSolver(
      rows: rows,
      cols: cols,
      totalMines: totalMines,
    );
    _resetGrid();
  }

  void _resetGrid() {
    _timer?.cancel();
    _timer = null;
    elapsedTimeSeconds = 0;
    status = GameStatus.initial;
    currentHint = null;
    _history.clear();

    grid = List.generate(rows, (r) {
      return List.generate(cols, (c) {
        return CellModel(row: r, col: c);
      });
    });
    onStateChanged?.call();
  }

  /// Change difficulty and restart game
  void setDifficulty(Difficulty newDiff) {
    if (difficulty == newDiff && status == GameStatus.initial) return;
    difficulty = newDiff;
    _initEngine();
  }

  /// Restart current board
  void restart() {
    _resetGrid();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (status == GameStatus.playing) {
        elapsedTimeSeconds++;
        onStateChanged?.call();
      }
    });
  }

  void _saveSnapshot() {
    _history.add(GridSnapshot.capture(
      grid,
      status,
      elapsedTimeSeconds,
      flagsRemaining,
    ));
    if (_history.length > maxHistory) {
      _history.removeAt(0);
    }
  }

  /// Undo the last action
  bool undo() {
    if (_history.isEmpty) return false;

    final snapshot = _history.removeLast();
    grid = snapshot.grid;
    status = snapshot.status;
    elapsedTimeSeconds = snapshot.elapsedTimeSeconds;
    currentHint = null;

    if (status == GameStatus.playing && _timer == null) {
      _startTimer();
    } else if (status != GameStatus.playing) {
      _timer?.cancel();
      _timer = null;
    }

    onStateChanged?.call();
    return true;
  }

  /// Primary action when tapping on a tile (r, c)
  void handleCellTap(int r, int c) {
    if (status == GameStatus.won || status == GameStatus.lost) return;

    final cell = grid[r][c];

    // 1. If tapping an already revealed number: Chording or Smart Flag!
    if (cell.isRevealed) {
      chordReveal(r, c);
      return;
    }

    // 2. If Flag Mode is active: toggle flag
    if (isFlagMode) {
      toggleFlag(r, c);
      return;
    }

    // 3. Unrevealed tile: normal safe reveal
    revealCell(r, c);
  }

  /// Secondary action (Fast long-press on mobile or right-click on web/desktop)
  void handleCellLongPress(int r, int c) {
    if (status == GameStatus.won || status == GameStatus.lost) return;

    final cell = grid[r][c];

    // If long-pressing a revealed number: Smart Flag remaining mines
    if (cell.isRevealed) {
      smartFlagAdjacent(r, c);
      return;
    }

    toggleFlag(r, c);
  }

  /// Toggle flag on cell (r, c)
  void toggleFlag(int r, int c) {
    final cell = grid[r][c];
    if (cell.isRevealed) {
      chordReveal(r, c);
      return;
    }

    _saveSnapshot();
    clearHint();

    final newFlagged = !cell.isFlagged;
    grid[r][c] = cell.copyWith(isFlagged: newFlagged);

    if (newFlagged) {
      onFlagPlaced?.call();
    } else {
      onFlagRemoved?.call();
    }

    _checkVictoryCondition();
    onStateChanged?.call();
  }

  /// Reveals a cell at (r, c)
  void revealCell(int r, int c) {
    final cell = grid[r][c];
    if (cell.isRevealed || cell.isFlagged) return;

    // Handle First Tap: Generate 100% No-Guess board with 0-clue at (r, c)
    if (status == GameStatus.initial) {
      final generated = _generator.generateNoGuessBoard(
        difficulty: difficulty,
        firstRow: r,
        firstCol: c,
      );
      grid = generated.grid;
      status = GameStatus.playing;
      _startTimer();
    }

    _saveSnapshot();
    clearHint();

    final target = grid[r][c];
    if (target.isMine) {
      // Detonation!
      _handleDetonation(r, c);
      return;
    }

    // Safe reveal: compute cascade
    final newlyRevealed = _performCascade(r, c);
    onCascadeReveal?.call(Point2D(r, c), newlyRevealed);

    _checkVictoryCondition();
    onStateChanged?.call();
  }

  /// Chording: Quick reveal adjacent unflagged cells when number equals adjacent flags,
  /// or Smart Flag when all remaining unrevealed neighbors are guaranteed mines!
  void chordReveal(int r, int c) {
    final cell = grid[r][c];
    if (!cell.isRevealed || cell.neighborMines == 0) return;

    final neighbors = _solver.getNeighbors(r, c);
    int flagCount = 0;
    final unrevealed = <Point2D>[];

    for (final n in neighbors) {
      final nc = grid[n.row][n.col];
      if (nc.isFlagged) {
        flagCount++;
      } else if (!nc.isRevealed) {
        unrevealed.add(n);
      }
    }

    // Case 1: Flag count equals clue -> Open remaining unrevealed safe cells!
    if (flagCount == cell.neighborMines && unrevealed.isNotEmpty) {
      _saveSnapshot();
      clearHint();

      bool hitMine = false;
      int newlyRevealed = 0;

      for (final p in unrevealed) {
        final target = grid[p.row][p.col];
        if (target.isMine) {
          hitMine = true;
          _handleDetonation(p.row, p.col);
          break;
        } else {
          newlyRevealed += _performCascade(p.row, p.col);
        }
      }

      if (!hitMine) {
        onCascadeReveal?.call(Point2D(r, c), newlyRevealed);
        _checkVictoryCondition();
        onStateChanged?.call();
      }
      return;
    }

    // Case 2: Unrevealed neighbors count equals remaining mines needed -> Smart Flag!
    final neededMines = cell.neighborMines - flagCount;
    if (neededMines > 0 && unrevealed.length == neededMines) {
      smartFlagAdjacent(r, c);
      return;
    }

    // Case 3: Condition not yet met -> Brief pulse highlight on neighbors (classic depressed feedback)
    if (unrevealed.isNotEmpty) {
      _pulseNeighbors(unrevealed);
    }
  }

  /// Smart Flag: Automatically flags all remaining unrevealed neighbors if they must all be mines
  void smartFlagAdjacent(int r, int c) {
    final cell = grid[r][c];
    if (!cell.isRevealed || cell.neighborMines == 0) return;

    final neighbors = _solver.getNeighbors(r, c);
    int flagCount = 0;
    final unflagged = <Point2D>[];

    for (final n in neighbors) {
      final nc = grid[n.row][n.col];
      if (nc.isFlagged) {
        flagCount++;
      } else if (!nc.isRevealed) {
        unflagged.add(n);
      }
    }

    final neededMines = cell.neighborMines - flagCount;
    if (neededMines > 0 && unflagged.length == neededMines) {
      _saveSnapshot();
      clearHint();

      for (final p in unflagged) {
        grid[p.row][p.col] = grid[p.row][p.col].copyWith(isFlagged: true);
      }
      onFlagPlaced?.call();
      _checkVictoryCondition();
      onStateChanged?.call();
    }
  }

  Timer? _pulseTimer;
  void _pulseNeighbors(List<Point2D> cells) {
    _pulseTimer?.cancel();
    for (final p in cells) {
      grid[p.row][p.col] = grid[p.row][p.col].copyWith(
        isHighlighted: true,
        isSafeHint: false,
      );
    }
    onStateChanged?.call();

    _pulseTimer = Timer(const Duration(milliseconds: 200), () {
      for (final p in cells) {
        if (p.row < rows && p.col < cols) {
          grid[p.row][p.col] = grid[p.row][p.col].copyWith(isHighlighted: false);
        }
      }
      onStateChanged?.call();
    });
  }

  int _performCascade(int startR, int startC) {
    int count = 0;
    final queue = <Point2D>[Point2D(startR, startC)];
    final visited = <Point2D>{Point2D(startR, startC)};

    // Calculate ripple delay based on distance
    grid[startR][startC] = grid[startR][startC].copyWith(
      isRevealed: true,
      rippleDelayMs: 0,
    );
    count++;

    while (queue.isNotEmpty) {
      final curr = queue.removeAt(0);
      final currCell = grid[curr.row][curr.col];

      if (currCell.neighborMines == 0) {
        for (final n in _solver.getNeighbors(curr.row, curr.col)) {
          if (!visited.contains(n)) {
            visited.add(n);
            final nc = grid[n.row][n.col];
            if (!nc.isRevealed && !nc.isFlagged && !nc.isMine) {
              final dr = (n.row - startR).abs();
              final dc = (n.col - startC).abs();
              final dist = dr + dc;
              grid[n.row][n.col] = nc.copyWith(
                isRevealed: true,
                rippleDelayMs: dist * 30, // 30ms staggered ripple
              );
              count++;
              if (nc.neighborMines == 0) {
                queue.add(n);
              }
            }
          }
        }
      }
    }
    return count;
  }

  void _handleDetonation(int r, int c) {
    _timer?.cancel();
    _timer = null;
    status = GameStatus.lost;

    // Reveal all mines, highlighting the detonated one
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final cell = grid[row][col];
        if (cell.isMine) {
          grid[row][col] = cell.copyWith(isRevealed: true);
        }
      }
    }
    onDetonate?.call();
    onStateChanged?.call();
  }

  void _checkVictoryCondition() {
    if (revealedCount == totalSafeCells && status != GameStatus.lost) {
      _timer?.cancel();
      _timer = null;
      status = GameStatus.won;

      // Automatically flag all remaining mines
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          final cell = grid[r][c];
          if (cell.isMine && !cell.isFlagged) {
            grid[r][c] = cell.copyWith(isFlagged: true);
          }
        }
      }

      onVictory?.call();
      onStateChanged?.call();
    }
  }

  /// Compute and activate the next logical hint
  DeductionStep? triggerHint() {
    if (status != GameStatus.playing) return null;

    clearHint();

    final hint = _solver.findNextHint(grid);
    if (hint != null && hint.isNotEmpty) {
      currentHint = hint;

      // Highlight target cells
      for (final s in hint.safeCells) {
        grid[s.row][s.col] = grid[s.row][s.col].copyWith(
          isHighlighted: true,
          isSafeHint: true,
        );
      }
      for (final m in hint.mineCells) {
        grid[m.row][m.col] = grid[m.row][m.col].copyWith(
          isHighlighted: true,
          isSafeHint: false,
        );
      }

      onHintShown?.call();
      onStateChanged?.call();
    }
    return hint;
  }

  void clearHint() {
    if (currentHint == null) return;
    currentHint = null;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (grid[r][c].isHighlighted) {
          grid[r][c] = grid[r][c].copyWith(isHighlighted: false);
        }
      }
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _pulseTimer?.cancel();
    _pulseTimer = null;
  }
}
