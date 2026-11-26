import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minesweeper_clean/core/audio_controller.dart';
import 'package:minesweeper_clean/core/haptic_controller.dart';
import 'package:minesweeper_clean/core/localization.dart';
import 'package:minesweeper_clean/core/theme_manager.dart';
import 'package:minesweeper_clean/ui/virtual_tutorial_view.dart';

void main() {
  testWidgets('VirtualTutorialView renders 4x4 virtual board and handles exit',
      (WidgetTester tester) async {
    bool exited = false;

    await tester.pumpWidget(
      MaterialApp(
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: VirtualTutorialView(
          theme: const AppTheme(AppThemeMode.oledDark),
          audio: AudioController(enabled: false),
          haptic: HapticController(enabled: false),
          onExit: () {
            exited = true;
          },
        ),
      ),
    );

    // Initial pump (VirtualTutorialView has repeat animation, so use pump with duration)
    await tester.pump(const Duration(milliseconds: 100));

    // 1. Initial Step 0 verify
    expect(find.byType(VirtualTutorialView), findsOneWidget);
    expect(find.byIcon(Icons.touch_app_outlined), findsWidgets);

    // 2. Test Exit button
    final exitButton = find.byIcon(Icons.close_rounded);
    expect(exitButton, findsOneWidget);
    await tester.tap(exitButton);
    await tester.pump(const Duration(milliseconds: 100));

    expect(exited, isTrue);
  });
}
