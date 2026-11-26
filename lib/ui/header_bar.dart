import 'package:flutter/material.dart';
import '../core/localization.dart';
import '../core/theme_manager.dart';
import '../engine/board_generator.dart';
import 'difficulty_dialog.dart';

class HeaderBar extends StatelessWidget {
  final AppTheme theme;
  final int elapsedTimeSeconds;
  final int flagsRemaining;
  final Difficulty difficulty;
  final bool isFlagMode;
  final bool canUndo;
  final bool hasActiveHint;
  final bool soundEnabled;
  final bool vibrationEnabled;

  final VoidCallback onRestart;
  final VoidCallback onToggleFlagMode;
  final VoidCallback onUndo;
  final VoidCallback onHint;
  final VoidCallback onToggleSound;
  final VoidCallback onToggleVibration;
  final VoidCallback onToggleTheme;
  final Function(Difficulty) onSelectDifficulty;
  final VoidCallback onOpenStats;
  final VoidCallback onOpenHelp;
  final VoidCallback onOpenLanguage;

  const HeaderBar({
    super.key,
    required this.theme,
    required this.elapsedTimeSeconds,
    required this.flagsRemaining,
    required this.difficulty,
    required this.isFlagMode,
    required this.canUndo,
    required this.hasActiveHint,
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.onRestart,
    required this.onToggleFlagMode,
    required this.onUndo,
    required this.onHint,
    required this.onToggleSound,
    required this.onToggleVibration,
    required this.onToggleTheme,
    required this.onSelectDifficulty,
    required this.onOpenStats,
    required this.onOpenHelp,
    required this.onOpenLanguage,
  });

  String _formatCounter(int val) {
    if (val < -99) return '-99';
    if (val < 0) return '-${val.abs().toString().padLeft(2, '0')}';
    if (val > 999) return '999';
    return val.toString().padLeft(3, '0');
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(Localizations.localeOf(context));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: theme.headerBackground,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Row: Minimal Quick Utility Toolbar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Difficulty Dropdown Chip [ 초급 (9x9) ▾ ]
                InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => DifficultyDialog(
                        theme: theme,
                        currentDifficulty: difficulty,
                        onSelectDifficulty: onSelectDifficulty,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9.0,
                      vertical: 5.0,
                    ),
                    decoration: BoxDecoration(
                      color: theme.isDark
                          ? const Color(0xFF27272A)
                          : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.tileUnrevealedBorder.withOpacity(0.5),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${loc.t(difficulty.nameKey)} (${difficulty.cols}x${difficulty.rows})',
                          style: TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w800,
                            color: theme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.arrow_drop_down_rounded,
                          size: 18,
                          color: theme.iconActive,
                        ),
                      ],
                    ),
                  ),
                ),

                // Utility Icons: Help, Language, Sound, Haptics, Theme, Stats
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildIconButton(
                      icon: Icons.help_outline_rounded,
                      isActive: true,
                      tooltip: loc.t('tooltip_help'),
                      onTap: onOpenHelp,
                    ),
                    _buildIconButton(
                      icon: Icons.language_rounded,
                      isActive: true,
                      tooltip: loc.t('tooltip_language'),
                      onTap: onOpenLanguage,
                    ),
                    _buildIconButton(
                      icon: soundEnabled
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                      isActive: soundEnabled,
                      tooltip: soundEnabled
                          ? '${loc.t('tooltip_sound')} (ON)'
                          : '${loc.t('tooltip_sound')} (OFF)',
                      onTap: onToggleSound,
                    ),
                    _buildIconButton(
                      icon: vibrationEnabled
                          ? Icons.vibration_rounded
                          : Icons.mobile_off_rounded,
                      isActive: vibrationEnabled,
                      tooltip: vibrationEnabled
                          ? '${loc.t('tooltip_vibration')} (${loc.t('vibration_on')})'
                          : '${loc.t('tooltip_vibration')} (${loc.t('vibration_off')})',
                      onTap: () {
                        onToggleVibration();
                        final nextState = !vibrationEnabled;
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  nextState
                                      ? Icons.vibration_rounded
                                      : Icons.mobile_off_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  nextState
                                      ? loc.t('vibration_on')
                                      : loc.t('vibration_off'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            duration: const Duration(milliseconds: 1000),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: const EdgeInsets.symmetric(
                              horizontal: 48,
                              vertical: 24,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildIconButton(
                      icon: Icons.brightness_6_rounded,
                      isActive: true,
                      tooltip: loc.t('tooltip_theme'),
                      onTap: onToggleTheme,
                    ),
                    _buildIconButton(
                      icon: Icons.emoji_events_rounded,
                      isActive: true,
                      tooltip: loc.t('tooltip_stats'),
                      onTap: onOpenStats,
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Main Game HUD: [Mine Counter] [Restart / Face] [Timer] & Action Buttons
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: theme.cardBackground,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(
                  color: theme.tileUnrevealedBorder.withOpacity(0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Mines Left Digital Counter
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.circle_rounded,
                        size: 14,
                        color: theme.flagColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatCounter(flagsRemaining),
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: theme.flagColor,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),

                  // Center Action Buttons: Undo (↶), Restart (↻), Hint (💡), Flag Toggle (🚩)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Undo (↶)
                      _buildActionCircle(
                        icon: Icons.undo_rounded,
                        isEnabled: canUndo,
                        tooltip: loc.t('undo'),
                        theme: theme,
                        onTap: onUndo,
                      ),
                      const SizedBox(width: 8),

                      // Restart (↻)
                      _buildActionCircle(
                        icon: Icons.refresh_rounded,
                        isEnabled: true,
                        isPrimary: true,
                        tooltip: loc.t('restart'),
                        theme: theme,
                        onTap: onRestart,
                      ),
                      const SizedBox(width: 8),

                      // Logic Hint (💡)
                      _buildActionCircle(
                        icon: Icons.lightbulb_rounded,
                        isEnabled: true,
                        isActive: hasActiveHint,
                        activeColor: theme.hintSafePulse,
                        tooltip: loc.t('hint'),
                        theme: theme,
                        onTap: onHint,
                      ),
                      const SizedBox(width: 8),

                      // Flag Toggle Mode (🚩)
                      _buildActionCircle(
                        icon: Icons.flag_rounded,
                        isEnabled: true,
                        isActive: isFlagMode,
                        activeColor: theme.flagColor,
                        tooltip: loc.t('hold_to_flag'),
                        theme: theme,
                        onTap: onToggleFlagMode,
                      ),
                    ],
                  ),

                  // Elapsed Timer (⏱️)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: theme.iconActive,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatCounter(elapsedTimeSeconds),
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: theme.iconActive,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    Widget button = IconButton(
      icon: Icon(icon, size: 19),
      color: isActive ? theme.iconActive : theme.iconInactive,
      visualDensity: VisualDensity.compact,
      splashRadius: 16,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 31, minHeight: 32),
      onPressed: onTap,
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip,
        child: button,
      );
    }
    return button;
  }

  Widget _buildActionCircle({
    required IconData icon,
    required bool isEnabled,
    bool isPrimary = false,
    bool isActive = false,
    Color? activeColor,
    String? tooltip,
    required AppTheme theme,
    required VoidCallback onTap,
  }) {
    final effectiveColor = isActive
        ? (activeColor ?? theme.iconActive)
        : (isEnabled ? theme.textPrimary : theme.iconInactive.withOpacity(0.35));

    final bgColor = isActive
        ? (activeColor?.withOpacity(0.18) ?? theme.iconActive.withOpacity(0.18))
        : (isPrimary
            ? (theme.isDark
                ? const Color(0xFF27272A)
                : const Color(0xFFE2E8F0))
            : Colors.transparent);

    Widget circle = InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(7.0),
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: isActive
              ? Border.all(color: activeColor ?? theme.iconActive, width: 1.5)
              : null,
        ),
        child: Icon(
          icon,
          size: 20,
          color: effectiveColor,
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip,
        child: circle,
      );
    }
    return circle;
  }
}
