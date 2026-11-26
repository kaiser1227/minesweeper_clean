import 'package:flutter/material.dart';

enum AppThemeMode {
  oledDark,
  cleanPaper,
}

class AppTheme {
  final AppThemeMode mode;

  const AppTheme(this.mode);

  bool get isDark => mode == AppThemeMode.oledDark;

  Color get scaffoldBackground =>
      isDark ? const Color(0xFF000000) : const Color(0xFFF8FAFC);

  Color get cardBackground =>
      isDark ? const Color(0xFF121215) : const Color(0xFFFFFFFF);

  Color get headerBackground =>
      isDark ? const Color(0xFF0D0D10) : const Color(0xFFF1F5F9);

  // Unrevealed tile colors
  Color get tileUnrevealed =>
      isDark ? const Color(0xFF1E1E24) : const Color(0xFFE2E8F0);

  Color get tileUnrevealedBorder =>
      isDark ? const Color(0xFF2C2C35) : const Color(0xFFCBD5E1);

  // Revealed tile colors
  Color get tileRevealed =>
      isDark ? const Color(0xFF0A0A0C) : const Color(0xFFFFFFFF);

  Color get tileRevealedBorder =>
      isDark ? const Color(0xFF18181D) : const Color(0xFFE2E8F0);

  // Mine & Detonation colors
  Color get tileDetonated => const Color(0xFFDC2626); // Crimson red
  Color get tileMineRevealed =>
      isDark ? const Color(0xFF2D1515) : const Color(0xFFFEE2E2);

  // Flag color
  Color get flagColor => const Color(0xFFEF4444); // Vivid red

  // Hint colors
  Color get hintSafePulse => const Color(0xFF10B981); // Emerald pulse
  Color get hintMinePulse => const Color(0xFFF59E0B); // Amber pulse

  // Primary Text & Icon color
  Color get textPrimary =>
      isDark ? const Color(0xFFF4F4F5) : const Color(0xFF0F172A);

  Color get textSecondary =>
      isDark ? const Color(0xFF71717A) : const Color(0xFF64748B);

  Color get iconActive => const Color(0xFF38BDF8); // Sky blue
  Color get iconInactive =>
      isDark ? const Color(0xFF52525B) : const Color(0xFF94A3B8);

  // Number colors for clues 1-8
  Color getNumberColor(int number) {
    switch (number) {
      case 1:
        return const Color(0xFF3B82F6); // Blue
      case 2:
        return const Color(0xFF10B981); // Emerald Green
      case 3:
        return const Color(0xFFEF4444); // Red
      case 4:
        return const Color(0xFF8B5CF6); // Purple
      case 5:
        return const Color(0xFFF59E0B); // Amber
      case 6:
        return const Color(0xFF06B6D4); // Cyan
      case 7:
        return const Color(0xFFEC4899); // Pink
      case 8:
        return isDark ? const Color(0xFFA1A1AA) : const Color(0xFF475569);
      default:
        return textPrimary;
    }
  }

  ThemeData toThemeData() {
    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: scaffoldBackground,
      cardColor: cardBackground,
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
        onPrimary: Colors.white,
        secondary: const Color(0xFF10B981),
        onSecondary: Colors.white,
        error: const Color(0xFFEF4444),
        onError: Colors.white,
        surface: cardBackground,
        onSurface: textPrimary,
      ),
    );
  }
}
