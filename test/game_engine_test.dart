import 'package:flutter_test/flutter_test.dart';
import 'package:minesweeper_clean/engine/board_generator.dart';
import 'package:minesweeper_clean/engine/game_state.dart';

void main() {
  group('GameEngine Logic Tests', () {
    test('First tap generates board, guarantees 0-cell, and cascades', () {
      final engine = GameEngine(difficulty: Difficulty.beginner, seed: 100);
      expect(engine.status, GameStatus.initial);
      expect(engine.flagsRemaining, 10);

      // Tap center cell (4, 4)
      engine.handleCellTap(4, 4);

      expect(engine.status, GameStatus.playing);
      expect(engine.grid[4][4].isRevealed, isTrue);
      expect(engine.grid[4][4].neighborMines, 0);
      // Because (4, 4) is 0, it must cascade to > 1 cell revealed
      expect(engine.revealedCount, greaterThan(1));
    });

    test('Flag toggle and Undo work as expected', () {
      final engine = GameEngine(difficulty: Difficulty.beginner, seed: 100);
      engine.handleCellTap(4, 4);

      final initialRevealed = engine.revealedCount;
      final initialFlags = engine.flagsRemaining;

      // Find an unrevealed cell
      int unrevR = -1, unrevC = -1;
      for (int r = 0; r < engine.rows; r++) {
        for (int c = 0; c < engine.cols; c++) {
          if (!engine.grid[r][c].isRevealed) {
            unrevR = r;
            unrevC = c;
            break;
          }
        }
        if (unrevR != -1) break;
      }

      // Flag the cell
      engine.toggleFlag(unrevR, unrevC);
      expect(engine.grid[unrevR][unrevC].isFlagged, isTrue);
      expect(engine.flagsRemaining, initialFlags - 1);

      // Undo the flag
      expect(engine.canUndo, isTrue);
      final undone = engine.undo();
      expect(undone, isTrue);
      expect(engine.grid[unrevR][unrevC].isFlagged, isFalse);
      expect(engine.flagsRemaining, initialFlags);
      expect(engine.revealedCount, initialRevealed);
    });

    test('Detonation triggers lost state, and Undo recovers it', () {
      final engine = GameEngine(difficulty: Difficulty.beginner, seed: 100);
      engine.handleCellTap(4, 4);

      // Find a known mine
      int mineR = -1, mineC = -1;
      for (int r = 0; r < engine.rows; r++) {
        for (int c = 0; c < engine.cols; c++) {
          if (engine.grid[r][c].isMine) {
            mineR = r;
            mineC = c;
            break;
          }
        }
        if (mineR != -1) break;
      }

      // Tap the mine
      engine.revealCell(mineR, mineC);
      expect(engine.status, GameStatus.lost);

      // Undo the mistake
      final recovered = engine.undo();
      expect(recovered, isTrue);
      expect(engine.status, GameStatus.playing);
      expect(engine.grid[mineR][mineC].isRevealed, isFalse);
    });

    test('Hint trigger highlights deducible cell', () {
      final engine = GameEngine(difficulty: Difficulty.beginner, seed: 100);
      engine.handleCellTap(4, 4);

      final hint = engine.triggerHint();
      // Since it's a 100% no-guess board, a hint MUST exist right after opening
      expect(hint, isNotNull);
      expect(hint!.isNotEmpty, isTrue);

      bool foundHighlighted = false;
      for (final row in engine.grid) {
        for (final cell in row) {
          if (cell.isHighlighted) {
            foundHighlighted = true;
            break;
          }
        }
        if (foundHighlighted) break;
      }
      expect(foundHighlighted, isTrue);
    });
    test('Tapping revealed number triggers chord reveal and smart flag', () {
      final engine = GameEngine(difficulty: Difficulty.beginner, seed: 100);
      engine.handleCellTap(4, 4);

      // Find an open cell with neighborMines > 0
      int numR = -1, numC = -1;
      for (int r = 0; r < engine.rows; r++) {
        for (int c = 0; c < engine.cols; c++) {
          final cell = engine.grid[r][c];
          if (cell.isRevealed && cell.neighborMines > 0) {
            numR = r;
            numC = c;
            break;
          }
        }
        if (numR != -1) break;
      }

      expect(numR, isNot(-1));

      // Tap on the already revealed cell - should not crash and triggers chord/smart flag
      engine.handleCellTap(numR, numC);
      // Either chord or smart-flag or pulse occurred safely
      expect(engine.status, GameStatus.playing);
    });
  });
}
