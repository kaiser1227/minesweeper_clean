import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minesweeper_clean/core/theme_manager.dart';
import 'package:minesweeper_clean/engine/board_generator.dart';
import 'package:minesweeper_clean/engine/cell_model.dart';
import 'package:minesweeper_clean/ui/board_view.dart';
import 'package:minesweeper_clean/ui/header_bar.dart';

void main() {
  group('BoardView Multi-touch & Large Board Gesture Tests', () {
    testWidgets('30x16 expert board renders all tiles including rightmost tile (0, 29) and handles tap',
        (WidgetTester tester) async {
      const rows = 16;
      const cols = 30;
      final grid = List.generate(
        rows,
        (r) => List.generate(
          cols,
          (c) => CellModel(row: r, col: c),
        ),
      );

      const theme = AppTheme(AppThemeMode.oledDark);
      final controller = TransformationController();

      int? tappedRow;
      int? tappedCol;
      int? longPressedRow;
      int? longPressedCol;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 800,
              child: BoardView(
                grid: grid,
                theme: theme,
                transformationController: controller,
                onCellTap: (r, c) {
                  tappedRow = r;
                  tappedCol = c;
                },
                onCellLongPress: (r, c) {
                  longPressedRow = r;
                  longPressedCol = c;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check InteractiveViewer properties
      final ivFinder = find.byType(InteractiveViewer);
      expect(ivFinder, findsOneWidget);
      final iv = tester.widget<InteractiveViewer>(ivFinder);
      expect(iv.constrained, isFalse, reason: 'InteractiveViewer must have constrained: false for large boards');
      expect(iv.minScale, 0.3);
      expect(iv.maxScale, 3.5);
      expect(iv.clipBehavior, Clip.hardEdge);

      // Verify leftmost tile (0, 0) is found and can be tapped
      final leftTileFinder = find.byKey(const ValueKey('tile_0_0'));
      expect(leftTileFinder, findsOneWidget);
      await tester.tap(leftTileFinder);
      await tester.pump();
      expect(tappedRow, 0);
      expect(tappedCol, 0);

      // Verify rightmost tile (0, 29) exists in the widget tree
      final rightTileFinder = find.byKey(const ValueKey('tile_0_29'));
      expect(rightTileFinder, findsOneWidget);

      // Pan board to the left so that tile (0, 29) is centered in the viewport
      // Board width is 30 * 28 = 840 px. Pan by -500 px.
      controller.value = Matrix4.identity()..translate(-500.0, 0.0);
      await tester.pumpAndSettle();

      // Now tap the rightmost tile (0, 29)
      await tester.tap(rightTileFinder, warnIfMissed: false);
      await tester.pump();
      expect(tappedRow, 0);
      expect(tappedCol, 29, reason: 'Rightmost tile (0, 29) must receive tap after scroll');

      // Test long press on bottom-right tile (15, 29)
      final bottomRightTileFinder = find.byKey(const ValueKey('tile_15_29'));
      expect(bottomRightTileFinder, findsOneWidget);
      await tester.longPress(bottomRightTileFinder, warnIfMissed: false);
      await tester.pump();
      expect(longPressedRow, 15);
      expect(longPressedCol, 29, reason: 'Bottom-right tile (15, 29) must receive long press');
    });
  });

  group('HeaderBar UI Visibility & Usability Tests', () {
    testWidgets('HeaderBar displays vibration icon, trophy icon, and triggers snackbar on vibration toggle',
        (WidgetTester tester) async {
      bool vibration = true;
      bool statsOpened = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return HeaderBar(
                  theme: const AppTheme(AppThemeMode.oledDark),
                  elapsedTimeSeconds: 42,
                  flagsRemaining: 10,
                  difficulty: Difficulty.beginner,
                  isFlagMode: false,
                  canUndo: true,
                  hasActiveHint: false,
                  soundEnabled: true,
                  vibrationEnabled: vibration,
                  onRestart: () {},
                  onToggleFlagMode: () {},
                  onUndo: () {},
                  onHint: () {},
                  onToggleSound: () {},
                  onToggleVibration: () {
                    setState(() {
                      vibration = !vibration;
                    });
                  },
                  onToggleTheme: () {},
                  onSelectDifficulty: (_) {},
                  onOpenStats: () {
                    statsOpened = true;
                  },
                  onOpenHelp: () {},
                  onOpenLanguage: () {},
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Trophy icon (Icons.emoji_events_rounded) is rendered
      final trophyFinder = find.byIcon(Icons.emoji_events_rounded);
      expect(trophyFinder, findsOneWidget, reason: 'Trophy icon must be used for game stats');
      await tester.tap(trophyFinder);
      expect(statsOpened, isTrue);

      // 2. Vibration icon (Icons.vibration_rounded) when ON
      final vibOnFinder = find.byIcon(Icons.vibration_rounded);
      expect(vibOnFinder, findsOneWidget);

      // Tap vibration button to toggle OFF
      await tester.tap(vibOnFinder);
      await tester.pump(); // Start snackbar animation
      await tester.pump(const Duration(milliseconds: 100));

      // SnackBar with vibration off feedback is visible
      expect(find.byType(SnackBar), findsOneWidget);

      // Now vibration icon should be mobile_off_rounded
      expect(find.byIcon(Icons.mobile_off_rounded), findsWidgets);

      // 3. Check tooltips exist
      expect(find.byType(Tooltip), findsWidgets);
    });
  });
}
