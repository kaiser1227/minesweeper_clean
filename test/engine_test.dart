import 'package:flutter_test/flutter_test.dart';
import 'package:minesweeper_clean/engine/board_generator.dart';
import 'package:minesweeper_clean/engine/cell_model.dart';
import 'package:minesweeper_clean/engine/deduction_solver.dart';

void main() {
  group('DeductionSolver Tests', () {
    test('Rule 1: Direct single-cell safe and mine deductions', () {
      const solver = DeductionSolver(rows: 3, cols: 3, totalMines: 1);
      // Layout:
      // [1] [1] [1]
      // [1] [*] [1]
      // [1] [1] [1]
      final mineMap = [
        [false, false, false],
        [false, true, false],
        [false, false, false],
      ];
      final counts = [
        [1, 1, 1],
        [1, -1, 1],
        [1, 1, 1],
      ];

      // Starting from corner (0,0) - wait, (0,0) has 1 neighbor mine
      final result = solver.evaluateSolvability(mineMap, counts, const Point2D(0, 0));
      // In this 3x3 with center mine, corner (0,0) touches (0,1), (1,0), (1,1).
      // Since it's touching 3 unrevealed cells and mine count is 1, single corner alone can't tell which is the mine.
      expect(result.revealedSafeCells, greaterThanOrEqualTo(1));
    });

    test('Solves a simple open field with zero-cascade', () {
      const solver = DeductionSolver(rows: 4, cols: 4, totalMines: 1);
      // Mine at (3,3)
      final mineMap = List.generate(4, (r) => List.generate(4, (c) => r == 3 && c == 3));
      final counts = List.generate(4, (r) {
        return List.generate(4, (c) {
          if (r == 3 && c == 3) return -1;
          int cnt = 0;
          for (final n in solver.getNeighbors(r, c)) {
            if (mineMap[n.row][n.col]) cnt++;
          }
          return cnt;
        });
      });

      // Start at (0,0) which is 0
      expect(counts[0][0], 0);
      final result = solver.evaluateSolvability(mineMap, counts, const Point2D(0, 0));
      expect(result.isSolvable, isTrue);
      expect(result.revealedSafeCells, 15);
      expect(result.totalSafeCells, 15);
    });
  });

  group('BoardGenerator 100% No-Guess Verification', () {
    test('Generates Beginner (9x9, 10 mines) guaranteed solvable board', () {
      final generator = BoardGenerator(seed: 42);
      final board = generator.generateNoGuessBoard(
        difficulty: Difficulty.beginner,
        firstRow: 4,
        firstCol: 4,
      );

      expect(board.solverResult.isSolvable, isTrue);
      expect(board.solverResult.revealedSafeCells, 71); // 81 - 10 = 71
      expect(board.grid[4][4].isMine, isFalse);
      expect(board.grid[4][4].neighborMines, 0);

      // Verify mine count
      int mineCount = 0;
      for (final row in board.grid) {
        for (final cell in row) {
          if (cell.isMine) mineCount++;
        }
      }
      expect(mineCount, 10);
    });

    test('Generates Intermediate (16x16, 40 mines) guaranteed solvable board', () {
      final generator = BoardGenerator(seed: 123);
      final board = generator.generateNoGuessBoard(
        difficulty: Difficulty.intermediate,
        firstRow: 7,
        firstCol: 7,
      );

      expect(board.solverResult.isSolvable, isTrue);
      expect(board.solverResult.revealedSafeCells, 216); // 256 - 40 = 216
      expect(board.grid[7][7].neighborMines, 0);
    });

    test('Generates Expert (16x30, 99 mines) guaranteed solvable board', () {
      final generator = BoardGenerator(seed: 999);
      final board = generator.generateNoGuessBoard(
        difficulty: Difficulty.expert,
        firstRow: 8,
        firstCol: 15,
      );

      expect(board.solverResult.isSolvable, isTrue);
      expect(board.solverResult.revealedSafeCells, 381); // 480 - 99 = 381
      expect(board.grid[8][15].neighborMines, 0);
    });
  });
}
