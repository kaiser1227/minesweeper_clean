import 'package:flutter_test/flutter_test.dart';
import 'package:minesweeper_clean/core/preferences_manager.dart';
import 'package:minesweeper_clean/engine/board_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PreferencesManager correctly records loss and calculates winRate', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = PreferencesManager();
    await prefs.init();

    const diff = Difficulty.beginner;

    // 1. Initially all 0
    var stats = prefs.getStats(diff);
    expect(stats.played, equals(0));
    expect(stats.won, equals(0));
    expect(stats.lost, equals(0));
    expect(stats.winRate, equals(0.0));

    // 2. Record 1 Loss
    await prefs.recordGameResult(diff: diff, isWon: false);
    stats = prefs.getStats(diff);
    expect(stats.played, equals(1));
    expect(stats.won, equals(0));
    expect(stats.lost, equals(1));
    expect(stats.winRate, equals(0.0));

    // 3. Record 1 Win
    await prefs.recordGameResult(diff: diff, isWon: true, timeSeconds: 45);
    stats = prefs.getStats(diff);
    expect(stats.played, equals(2));
    expect(stats.won, equals(1));
    expect(stats.lost, equals(1));
    expect(stats.winRate, equals(50.0));
    expect(stats.bestTimeSeconds, equals(45));

    // 4. Undo scenario: Was already counted as loss, now converted to win
    await prefs.recordGameResult(
      diff: diff,
      isWon: true,
      timeSeconds: 30,
      wasAlreadyCounted: true,
    );
    stats = prefs.getStats(diff);
    expect(stats.played, equals(2)); // played remains 2
    expect(stats.won, equals(2));
    expect(stats.lost, equals(0));
    expect(stats.winRate, equals(100.0));
    expect(stats.bestTimeSeconds, equals(30)); // new best time
  });
}
