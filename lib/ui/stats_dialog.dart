import 'package:flutter/material.dart';
import '../core/localization.dart';
import '../core/preferences_manager.dart';
import '../core/theme_manager.dart';
import '../engine/board_generator.dart';

class StatsDialog extends StatefulWidget {
  final AppTheme theme;
  final PreferencesManager prefs;

  const StatsDialog({
    super.key,
    required this.theme,
    required this.prefs,
  });

  @override
  State<StatsDialog> createState() => _StatsDialogState();
}

class _StatsDialogState extends State<StatsDialog> {
  String _formatTime(int? sec) {
    if (sec == null) return '--:--';
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final loc = AppLocalizations(Localizations.localeOf(context));

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(22.0),
        decoration: BoxDecoration(
          color: theme.cardBackground,
          borderRadius: BorderRadius.circular(24.0),
          border: Border.all(
            color: theme.tileUnrevealedBorder,
            width: 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.emoji_events_rounded,
                        color: theme.iconActive, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      loc.t('stats_title'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: theme.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  color: theme.textSecondary,
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Difficulty tabs stats
            ...Difficulty.values.map((d) {
              final stats = widget.prefs.getStats(d);
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.isDark
                      ? const Color(0xFF18181D)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${loc.t(d.nameKey)} (${d.cols}x${d.rows}, ${d.mines} ${loc.t('mines')})',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: theme.iconActive,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatCol(loc.t('games_played'), '${stats.played}', theme),
                        _buildStatCol(loc.t('games_won'), '${stats.won}', theme),
                        _buildStatCol(loc.t('games_lost'), '${stats.lost}', theme),
                        _buildStatCol(loc.t('win_rate'), '${stats.winRate.toStringAsFixed(0)}%', theme),
                        _buildStatCol(loc.t('best_time'), _formatTime(stats.bestTimeSeconds), theme),
                      ],
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 8),

            // Reset Button
            Align(
              alignment: Alignment.center,
              child: TextButton.icon(
                onPressed: () async {
                  await widget.prefs.resetStats();
                  setState(() {});
                },
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: Text(
                  loc.t('restart'),
                  style: const TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: theme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCol(String label, String value, AppTheme theme) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: theme.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: theme.textSecondary,
          ),
        ),
      ],
    );
  }
}
