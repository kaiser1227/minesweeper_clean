import 'package:flutter/material.dart';
import '../core/localization.dart';
import '../core/theme_manager.dart';
import '../engine/board_generator.dart';

class DifficultyDialog extends StatelessWidget {
  final AppTheme theme;
  final Difficulty currentDifficulty;
  final ValueChanged<Difficulty> onSelectDifficulty;

  const DifficultyDialog({
    super.key,
    required this.theme,
    required this.currentDifficulty,
    required this.onSelectDifficulty,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(Localizations.localeOf(context));

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
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
                    Icon(
                      Icons.tune_rounded,
                      color: theme.iconActive,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      loc.t('select_difficulty'),
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

            // Difficulty Cards
            ...Difficulty.values.map((d) {
              final isSelected = d == currentDifficulty;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () {
                    onSelectDifficulty(d);
                    Navigator.of(context).pop();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (theme.isDark
                              ? const Color(0xFF27272A)
                              : const Color(0xFFE2E8F0))
                          : (theme.isDark
                              ? const Color(0xFF18181D)
                              : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? theme.iconActive
                            : theme.tileUnrevealedBorder.withOpacity(0.5),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(d).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              _getDifficultyIcon(d),
                              color: _getDifficultyColor(d),
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.t(d.nameKey),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${d.cols}x${d.rows} • ${d.mines} ${loc.t('mines')}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: theme.iconActive,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(Difficulty d) {
    switch (d) {
      case Difficulty.beginner:
        return const Color(0xFF10B981);
      case Difficulty.intermediate:
        return const Color(0xFFF59E0B);
      case Difficulty.expert:
        return const Color(0xFFEF4444);
    }
  }

  IconData _getDifficultyIcon(Difficulty d) {
    switch (d) {
      case Difficulty.beginner:
        return Icons.sentiment_satisfied_alt_rounded;
      case Difficulty.intermediate:
        return Icons.fitness_center_rounded;
      case Difficulty.expert:
        return Icons.local_fire_department_rounded;
    }
  }
}
