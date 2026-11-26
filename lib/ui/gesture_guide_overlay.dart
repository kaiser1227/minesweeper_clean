import 'package:flutter/material.dart';
import '../core/theme_manager.dart';

class GestureGuideOverlay extends StatefulWidget {
  final AppTheme theme;
  final VoidCallback onDismiss;

  const GestureGuideOverlay({
    super.key,
    required this.theme,
    required this.onDismiss,
  });

  @override
  State<GestureGuideOverlay> createState() => _GestureGuideOverlayState();
}

class _GestureGuideOverlayState extends State<GestureGuideOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.88)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.88, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 40,
      ),
    ]).animate(_animController);

    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return GestureDetector(
      onTap: widget.onDismiss,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.black.withOpacity(0.65),
        alignment: Alignment.center,
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated Gesture Demonstration Circle
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Expanding ripple ring
                    Transform.scale(
                      scale: 1.0 + (_pulseAnim.value * 0.9),
                      child: Opacity(
                        opacity: (1.0 - _pulseAnim.value).clamp(0.0, 1.0),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.iconActive,
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Center simulated tile
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: theme.tileUnrevealed,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: theme.iconActive,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: _animController.value > 0.55
                            ? Icon(
                                Icons.flag_rounded,
                                color: theme.flagColor,
                                size: 30,
                              )
                            : Text(
                                '0',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: theme.iconActive,
                                ),
                              ),
                      ),
                    ),

                    // Animated Finger Icon
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Transform.scale(
                        scale: _scaleAnim.value,
                        child: Icon(
                          Icons.touch_app_rounded,
                          size: 42,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Universal No-Text Gesture Guide Pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: theme.cardBackground,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tap -> Open
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.touch_app_outlined,
                              size: 20, color: theme.iconActive),
                          const SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded,
                              size: 14, color: theme.textSecondary),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.tileRevealed,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: theme.tileRevealedBorder),
                            ),
                            child: Text(
                              '0',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: theme.iconActive,
                              ),
                            ),
                          ),
                        ],
                      ),

                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        height: 20,
                        width: 1,
                        color: theme.textSecondary.withOpacity(0.3),
                      ),

                      // Long-press -> Flag
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.touch_app_rounded,
                              size: 20, color: theme.flagColor),
                          const SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded,
                              size: 14, color: theme.textSecondary),
                          const SizedBox(width: 6),
                          Icon(Icons.flag_rounded,
                              size: 20, color: theme.flagColor),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Tap to start indicator
                Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white.withOpacity(0.6),
                  size: 28,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
