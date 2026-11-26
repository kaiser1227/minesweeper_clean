import 'package:flutter/material.dart';
import '../core/localization.dart';
import '../core/theme_manager.dart';

class InteractiveGuideOverlay extends StatelessWidget {
  final AppTheme theme;
  final int currentStep;
  final VoidCallback onNextStep;
  final VoidCallback onPrevStep;
  final VoidCallback onDismiss;

  const InteractiveGuideOverlay({
    super.key,
    required this.theme,
    required this.currentStep,
    required this.onNextStep,
    required this.onPrevStep,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(Localizations.localeOf(context));
    final isLastStep = currentStep >= 4;

    final String titleKey = 'guide_step${currentStep}_title';
    final String descKey = 'guide_step${currentStep}_desc';

    return Positioned(
      left: 16,
      right: 16,
      bottom: 24,
      child: SafeArea(
        child: Material(
          color: Colors.transparent,
          elevation: 12,
          shadowColor: Colors.black.withOpacity(0.35),
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: theme.cardBackground,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: theme.iconActive.withOpacity(0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.iconActive.withOpacity(0.12),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Row: Step Badge + Title + Close Button
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: theme.iconActive.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${loc.t('guide_step')} ${currentStep + 1}/5',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: theme.iconActive,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        loc.t(titleKey),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: theme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: onDismiss,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: theme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Guide Content with Step Icon
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: _getStepIconColor(currentStep).withOpacity(0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getStepIcon(currentStep),
                        size: 18,
                        color: _getStepIconColor(currentStep),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        loc.t(descKey),
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.45,
                          color: theme.textPrimary.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Bottom Controls: Back, Dots, Next
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back Button
                    if (currentStep > 0)
                      TextButton.icon(
                        onPressed: onPrevStep,
                        icon: const Icon(Icons.arrow_back_rounded, size: 14),
                        label: Text(
                          loc.t('guide_prev'),
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.textSecondary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      )
                    else
                      const SizedBox(width: 40),

                    // Progress Dots
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (index) {
                        final isCur = index == currentStep;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: isCur ? 14 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isCur
                                ? theme.iconActive
                                : theme.textSecondary.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),

                    // Next / Finish Button
                    ElevatedButton(
                      onPressed: isLastStep ? onDismiss : onNextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.iconActive,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isLastStep
                                ? loc.t('guide_finish')
                                : loc.t('guide_next'),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!isLastStep) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_rounded, size: 13),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getStepIcon(int step) {
    switch (step) {
      case 0:
        return Icons.touch_app_rounded;
      case 1:
        return Icons.pin_rounded;
      case 2:
        return Icons.flag_rounded;
      case 3:
        return Icons.bolt_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
  }

  Color _getStepIconColor(int step) {
    switch (step) {
      case 0:
        return const Color(0xFF3B82F6);
      case 1:
        return const Color(0xFFF59E0B);
      case 2:
        return const Color(0xFFEF4444);
      case 3:
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF10B981);
    }
  }
}
