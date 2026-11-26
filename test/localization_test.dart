import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:minesweeper_clean/core/localization.dart';

void main() {
  group('AppLocalizations 12-language verification', () {
    test('All 12 supported locales are declared', () {
      expect(AppLocalizations.supportedLocales.length, 12);
    });

    const requiredKeys = [
      'app_title',
      'diff_beginner',
      'diff_intermediate',
      'diff_expert',
      'time',
      'best_time',
      'mines',
      'victory',
      'game_over',
      'undo',
      'hint',
      'restart',
      'settings',
      'sound',
      'vibration',
      'theme',
      'dark_oled',
      'paper_light',
      'stats',
      'games_played',
      'games_won',
      'win_rate',
      'no_guess_guarantee',
      'tap_to_reveal',
      'hold_to_flag',
      'close',
      'stats_title',
      'vibration_on',
      'vibration_off',
      'tooltip_vibration',
      'tooltip_sound',
      'tooltip_theme',
      'tooltip_stats',
    ];

    for (final loc in AppLocalizations.supportedLocales) {
      test('Language ${loc.languageCode}_${loc.countryCode ?? ''} has all keys', () {
        final localizations = AppLocalizations(loc);
        for (final key in requiredKeys) {
          final translated = localizations.t(key);
          expect(translated, isNotEmpty,
              reason: 'Key "$key" is missing or empty in locale $loc');
          expect(translated, isNot(equals(key)),
              reason: 'Key "$key" was not translated in locale $loc');
        }
      });
    }

    test('Falls back gracefully to English on unknown locale', () {
      final loc = AppLocalizations(const Locale('xx'));
      expect(loc.t('victory'), 'Solved');
    });
  });
}
