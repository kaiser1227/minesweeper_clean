import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minesweeper_clean/core/localization.dart';
import 'package:minesweeper_clean/core/theme_manager.dart';
import 'package:minesweeper_clean/ui/interactive_guide_overlay.dart';

void main() {
  testWidgets('InteractiveGuideOverlay renders steps and advances', (tester) async {
    int step = 0;
    bool dismissed = false;

    await tester.pumpWidget(
      MaterialApp(
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Stack(
            children: [
              StatefulBuilder(
                builder: (context, setState) {
                  return InteractiveGuideOverlay(
                    theme: const AppTheme(AppThemeMode.oledDark),
                    currentStep: step,
                    onNextStep: () {
                      setState(() {
                        step++;
                      });
                    },
                    onPrevStep: () {
                      setState(() {
                        step--;
                      });
                    },
                    onDismiss: () {
                      dismissed = true;
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify step 1 title is visible
    expect(find.textContaining('1'), findsWidgets);

    // Tap Next
    final nextBtn = find.byType(ElevatedButton);
    expect(nextBtn, findsOneWidget);
    await tester.tap(nextBtn);
    await tester.pumpAndSettle();

    expect(step, equals(1));

    // Tap Close
    final closeBtn = find.byIcon(Icons.close_rounded);
    await tester.tap(closeBtn);
    await tester.pumpAndSettle();

    expect(dismissed, isTrue);
  });
}
