import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../engine/board_generator.dart';

class GameStats {
  final int played;
  final int won;
  final int? bestTimeSeconds;

  const GameStats({
    required this.played,
    required this.won,
    this.bestTimeSeconds,
  });

  int get lost => played - won >= 0 ? played - won : 0;
  double get winRate => played > 0 ? (won / played) * 100 : 0.0;
}

class PreferencesManager {
  static const _keyDarkTheme = 'pref_dark_theme';
  static const _keySound = 'pref_sound';
  static const _keyVibration = 'pref_vibration';
  static const _keyTutorialSeen = 'pref_tutorial_seen';
  static const _keyDifficulty = 'pref_difficulty';
  static const _keyLanguageCode = 'pref_language_code';
  static const _keyCountryCode = 'pref_country_code';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Locale? get savedLocale {
    final lang = _prefs.getString(_keyLanguageCode);
    if (lang == null) return null;
    final country = _prefs.getString(_keyCountryCode);
    return country != null ? Locale(lang, country) : Locale(lang);
  }

  Future<void> setLocale(Locale? locale) async {
    if (locale == null) {
      await _prefs.remove(_keyLanguageCode);
      await _prefs.remove(_keyCountryCode);
    } else {
      await _prefs.setString(_keyLanguageCode, locale.languageCode);
      if (locale.countryCode != null) {
        await _prefs.setString(_keyCountryCode, locale.countryCode!);
      } else {
        await _prefs.remove(_keyCountryCode);
      }
    }
  }

  bool get isDarkTheme => _prefs.getBool(_keyDarkTheme) ?? true;
  Future<void> setDarkTheme(bool val) => _prefs.setBool(_keyDarkTheme, val);

  bool get soundEnabled => _prefs.getBool(_keySound) ?? true;
  Future<void> setSoundEnabled(bool val) => _prefs.setBool(_keySound, val);

  bool get vibrationEnabled => _prefs.getBool(_keyVibration) ?? true;
  Future<void> setVibrationEnabled(bool val) =>
      _prefs.setBool(_keyVibration, val);

  bool get hasSeenTutorial => _prefs.getBool(_keyTutorialSeen) ?? false;
  Future<void> setTutorialSeen(bool val) =>
      _prefs.setBool(_keyTutorialSeen, val);

  Difficulty get difficulty {
    final name = _prefs.getString(_keyDifficulty);
    if (name == Difficulty.intermediate.name) return Difficulty.intermediate;
    if (name == Difficulty.expert.name) return Difficulty.expert;
    return Difficulty.beginner;
  }

  Future<void> setDifficulty(Difficulty diff) =>
      _prefs.setString(_keyDifficulty, diff.name);

  // Stats
  GameStats getStats(Difficulty diff) {
    final played = _prefs.getInt('stats_played_${diff.name}') ?? 0;
    final won = _prefs.getInt('stats_won_${diff.name}') ?? 0;
    final best = _prefs.getInt('stats_best_${diff.name}');
    return GameStats(played: played, won: won, bestTimeSeconds: best);
  }

  Future<void> recordGameResult({
    required Difficulty diff,
    required bool isWon,
    int? timeSeconds,
    bool wasAlreadyCounted = false,
  }) async {
    final currentStats = getStats(diff);
    final newPlayed = wasAlreadyCounted ? currentStats.played : currentStats.played + 1;
    final newWon = isWon ? currentStats.won + 1 : currentStats.won;

    await _prefs.setInt('stats_played_${diff.name}', newPlayed);
    await _prefs.setInt('stats_won_${diff.name}', newWon);

    if (isWon && timeSeconds != null) {
      final currentBest = currentStats.bestTimeSeconds;
      if (currentBest == null || timeSeconds < currentBest) {
        await _prefs.setInt('stats_best_${diff.name}', timeSeconds);
      }
    }
  }

  Future<void> resetStats() async {
    for (final d in Difficulty.values) {
      await _prefs.remove('stats_played_${d.name}');
      await _prefs.remove('stats_won_${d.name}');
      await _prefs.remove('stats_best_${d.name}');
    }
  }
}
