import 'package:flutter/material.dart';
import '../core/localization.dart';
import '../core/theme_manager.dart';

class VictoryDialog extends StatelessWidget {
  final AppTheme theme;
  final int timeSeconds;
  final bool isNewBest;
  final VoidCallback onPlayAgain;
  final VoidCallback onClose;

  const VictoryDialog({
    super.key,
    required this.theme,
    required this.timeSeconds,
    required this.isNewBest,
    required this.onPlayAgain,
    required this.onClose,
  });

  String _formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(Localizations.localeOf(context));

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: theme.cardBackground,
          borderRadius: BorderRadius.circular(24.0),
          border: Border.all(
            color: theme.hintSafePulse.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.hintSafePulse.withOpacity(0.25),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Victory Icon
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: theme.hintSafePulse.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.emoji_events_rounded,
                size: 48,
                color: theme.hintSafePulse,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              loc.t('victory'),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: theme.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),

            // No guess badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.iconActive.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '✦ ${loc.t('no_guess_guarantee')} ✦',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.iconActive,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Time Display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timer_outlined, size: 22, color: theme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  _formatTime(timeSeconds),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: theme.textPrimary,
                  ),
                ),
              ],
            ),

            if (isNewBest) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '★ ${loc.t('best_time')} ★',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 28),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onClose,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.textSecondary,
                      side: BorderSide(color: theme.tileUnrevealedBorder),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      loc.t('close'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onPlayAgain,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.hintSafePulse,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.refresh_rounded, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          loc.t('restart'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
