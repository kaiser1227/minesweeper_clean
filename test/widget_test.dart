import 'package:flutter_test/flutter_test.dart';
import 'package:minesweeper_clean/core/preferences_manager.dart';
import 'package:minesweeper_clean/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('MinesweeperApp loads and renders HUD and board correctly',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'pref_tutorial_seen': true, // skip tutorial in test
    });

    final prefs = PreferencesManager();
    await prefs.init();

    await tester.pumpWidget(MinesweeperApp(prefs: prefs));
    await tester.pumpAndSettle();

    // Verify HUD elements rendered: Restart, Undo, Hint, Flag
    expect(find.byType(MinesweeperScreen), findsOneWidget);

    // Initial flags remaining should be 10 for beginner
    expect(find.text('010'), findsOneWidget);

    // Timer starts at 000
    expect(find.text('000'), findsOneWidget);
  });
}
