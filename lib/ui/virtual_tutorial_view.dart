import 'package:flutter/material.dart';
import '../core/audio_controller.dart';
import '../core/haptic_controller.dart';
import '../core/localization.dart';
import '../core/theme_manager.dart';
import '../engine/cell_model.dart';
import 'animated_tile.dart';

class VirtualTutorialView extends StatefulWidget {
  final AppTheme theme;
  final AudioController audio;
  final HapticController haptic;
  final VoidCallback onExit;

  const VirtualTutorialView({
    super.key,
    required this.theme,
    required this.audio,
    required this.haptic,
    required this.onExit,
  });

  @override
  State<VirtualTutorialView> createState() => _VirtualTutorialViewState();
}

class _VirtualTutorialViewState extends State<VirtualTutorialView>
    with SingleTickerProviderStateMixin {
  late TransformationController _transController;
  late AnimationController _animController;
  late Animation<double> _pulseAnim;
  late Animation<double> _fingerScaleAnim;

  int _step = 0; // 0: 탭, 1: 롱클릭, 2: 코드, 3: 드래그, 4: 완료
  bool _stepSuccess = false;
  late List<List<CellModel>> _grid;

  @override
  void initState() {
    super.initState();
    _transController = TransformationController();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _fingerScaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.85)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.85, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 30,
      ),
    ]).animate(_animController);

    _initVirtualGrid();
  }

  void _initVirtualGrid() {
    // 4x4 가상 보드 (지뢰는 (2,2) 1개만 배치)
    _grid = List.generate(4, (r) {
      return List.generate(4, (c) {
        final isMine = (r == 2 && c == 2);
        int neighborMines = 0;
        if (!isMine) {
          // (2,2)와의 거리 계산
          if ((r - 2).abs() <= 1 && (c - 2).abs() <= 1) {
            neighborMines = 1;
          }
        }
        return CellModel(
          row: r,
          col: c,
          isMine: isMine,
          neighborMines: neighborMines,
          isRevealed: false,
          isFlagged: false,
        );
      });
    });
  }

  @override
  void dispose() {
    _transController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // Step 0: 탭 액션 처리
  void _handleTap(int r, int c) {
    if (_step == 0) {
      if (r == 0 && c == 1) {
        _triggerStep0Success();
      }
    } else if (_step == 2) {
      if (r == 1 && c == 1) {
        _triggerStep2Success();
      }
    }
  }

  // Step 1: 롱클릭 액션 처리
  void _handleLongPress(int r, int c) {
    if (_step == 1) {
      if (r == 2 && c == 2) {
        _triggerStep1Success();
      }
    }
  }

  void _triggerStep0Success() {
    setState(() {
      _stepSuccess = true;
      // (0,1) 및 주변 0 빈공간 연쇄 개방
      for (int r = 0; r < 4; r++) {
        for (int c = 0; c < 4; c++) {
          final cell = _grid[r][c];
          // 지뢰(2,2)와 지뢰 우하단 타일 제외하고 개방
          if (cell.neighborMines == 0 || (r == 1 && c == 1) || (r == 2 && c == 1) || (r == 1 && c == 2)) {
            _grid[r][c] = cell.copyWith(isRevealed: true);
          }
        }
      }
    });

    widget.audio.playCascade();
    widget.haptic.lightImpact();

    Future.delayed(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      setState(() {
        _step = 1;
        _stepSuccess = false;
      });
    });
  }

  void _triggerStep1Success() {
    setState(() {
      _stepSuccess = true;
      _grid[2][2] = _grid[2][2].copyWith(isFlagged: true);
    });

    widget.audio.playFlag();
    widget.haptic.mediumImpact();

    Future.delayed(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      setState(() {
        _step = 2;
        _stepSuccess = false;
      });
    });
  }

  void _triggerStep2Success() {
    setState(() {
      _stepSuccess = true;
      // 남은 모든 안전 타일 일괄 오픈
      for (int r = 0; r < 4; r++) {
        for (int c = 0; c < 4; c++) {
          if (!_grid[r][c].isMine) {
            _grid[r][c] = _grid[r][c].copyWith(isRevealed: true);
          }
        }
      }
    });

    widget.audio.playClick();
    widget.haptic.lightImpact();

    Future.delayed(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      setState(() {
        _step = 3;
        _stepSuccess = false;
      });
    });
  }

  void _triggerStep3Success() {
    if (_step != 3 || _stepSuccess) return;

    setState(() {
      _stepSuccess = true;
    });

    widget.audio.playWin();
    widget.haptic.victoryPattern();

    Future.delayed(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      setState(() {
        _step = 4;
        _stepSuccess = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final loc = AppLocalizations(Localizations.localeOf(context));

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: SafeArea(
        child: Stack(
          children: [
            // Main Column
            Column(
              children: [
                // Top Header Toolbar
                _buildTopToolbar(loc, theme),

                // Virtual 4x4 Board in InteractiveViewer
                Expanded(
                  child: Center(
                    child: _buildInteractiveBoard(theme),
                  ),
                ),

                // Bottom Coach Message Card
                _buildBottomCoachCard(loc, theme),
              ],
            ),

            // Step 4: Celebration Overlay if completed
            if (_step == 4) _buildCompletionOverlay(loc, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildTopToolbar(AppLocalizations loc, AppTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: theme.headerBackground,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.school_rounded, color: theme.iconActive, size: 22),
              const SizedBox(width: 8),
              Text(
                loc.t('tutorial_title'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: theme.textPrimary,
                ),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: widget.onExit,
            icon: const Icon(Icons.close_rounded, size: 16),
            label: Text(
              loc.t('tutorial_exit'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            style: TextButton.styleFrom(
              foregroundColor: theme.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveBoard(AppTheme theme) {
    const double tileSize = 64.0;
    const double boardWidth = 4 * tileSize;
    const double boardHeight = 4 * tileSize;

    return InteractiveViewer(
      transformationController: _transController,
      constrained: false,
      boundaryMargin: const EdgeInsets.all(160),
      minScale: 0.6,
      maxScale: 2.5,
      onInteractionUpdate: (details) {
        if (_step == 3) {
          _triggerStep3Success();
        }
      },
      child: SizedBox(
        width: boardWidth,
        height: boardHeight,
        child: Stack(
          children: [
            // 4x4 Grid
            Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(4, (r) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(4, (c) {
                    final cell = _grid[r][c];
                    return AnimatedTile(
                      cell: cell,
                      theme: theme,
                      size: tileSize,
                      onTap: () => _handleTap(r, c),
                      onLongPress: () => _handleLongPress(r, c),
                    );
                  }),
                );
              }),
            ),

            // Live Gesture Guide Target Spotlight
            if (!_stepSuccess) ...[
              if (_step == 0)
                _buildTargetHighlight(
                  r: 0,
                  c: 1,
                  tileSize: tileSize,
                  theme: theme,
                  isLongPress: false,
                ),
              if (_step == 1)
                _buildTargetHighlight(
                  r: 2,
                  c: 2,
                  tileSize: tileSize,
                  theme: theme,
                  isLongPress: true,
                ),
              if (_step == 2)
                _buildTargetHighlight(
                  r: 1,
                  c: 1,
                  tileSize: tileSize,
                  theme: theme,
                  isLongPress: false,
                  customColor: const Color(0xFF8B5CF6),
                ),
              if (_step == 3)
                _buildDragIndicator(boardWidth, boardHeight, theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTargetHighlight({
    required int r,
    required int c,
    required double tileSize,
    required AppTheme theme,
    required bool isLongPress,
    Color? customColor,
  }) {
    final effectiveColor =
        customColor ?? (isLongPress ? theme.flagColor : theme.iconActive);

    return Positioned(
      left: c * tileSize,
      top: r * tileSize,
      width: tileSize,
      height: tileSize,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Expanding Pulse Border
                Transform.scale(
                  scale: 1.0 + (_pulseAnim.value * 0.4),
                  child: Opacity(
                    opacity: (1.0 - _pulseAnim.value).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: effectiveColor,
                          width: 3.5,
                        ),
                      ),
                    ),
                  ),
                ),

                // Inner Target Ring
                Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: effectiveColor,
                      width: 2.5,
                    ),
                  ),
                ),

                // Animated Finger Gesture
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Transform.scale(
                    scale: isLongPress ? 0.85 : _fingerScaleAnim.value,
                    child: Icon(
                      isLongPress
                          ? Icons.touch_app_rounded
                          : Icons.touch_app_outlined,
                      size: 34,
                      color: Colors.white.withOpacity(0.95),
                      shadows: const [
                        Shadow(color: Colors.black, blurRadius: 8),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDragIndicator(double w, double h, AppTheme theme) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            final offset = (_animController.value - 0.5) * 50;
            return Center(
              child: Transform.translate(
                offset: Offset(offset, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_back_ios_rounded,
                        color: Colors.white70, size: 24),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.swipe_rounded,
                      size: 48,
                      color: theme.iconActive,
                      shadows: const [
                        Shadow(color: Colors.black54, blurRadius: 10)
                      ],
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: Colors.white70, size: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomCoachCard(AppLocalizations loc, AppTheme theme) {
    String badge = '';
    String prompt = '';

    if (_step == 0) {
      badge = loc.t('tutorial_step1_badge');
      prompt = _stepSuccess
          ? loc.t('tutorial_step1_success')
          : loc.t('tutorial_step1_prompt');
    } else if (_step == 1) {
      badge = loc.t('tutorial_step2_badge');
      prompt = _stepSuccess
          ? loc.t('tutorial_step2_success')
          : loc.t('tutorial_step2_prompt');
    } else if (_step == 2) {
      badge = loc.t('tutorial_step3_badge');
      prompt = _stepSuccess
          ? loc.t('tutorial_step3_success')
          : loc.t('tutorial_step3_prompt');
    } else if (_step == 3) {
      badge = loc.t('tutorial_step4_badge');
      prompt = _stepSuccess
          ? loc.t('tutorial_step4_success')
          : loc.t('tutorial_step4_prompt');
    } else {
      badge = loc.t('tutorial_step5_title');
      prompt = loc.t('tutorial_step5_desc');
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _stepSuccess
              ? const Color(0xFF10B981)
              : theme.iconActive.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Step Progress Dots & Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _stepSuccess
                      ? const Color(0xFF10B981).withOpacity(0.18)
                      : theme.iconActive.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _stepSuccess
                        ? const Color(0xFF10B981)
                        : theme.iconActive,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(4, (index) {
                  final active = index <= _step;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: active ? 16 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: active
                          ? theme.iconActive
                          : theme.textSecondary.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Message Prompt
          Row(
            children: [
              Icon(
                _stepSuccess
                    ? Icons.check_circle_rounded
                    : Icons.tips_and_updates_rounded,
                color: _stepSuccess
                    ? const Color(0xFF10B981)
                    : theme.iconActive,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  prompt,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: theme.textPrimary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionOverlay(AppLocalizations loc, AppTheme theme) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(28.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.emoji_events_rounded,
            color: Color(0xFFFBBF24),
            size: 72,
          ),
          const SizedBox(height: 16),
          Text(
            loc.t('tutorial_step5_title'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            loc.t('tutorial_step5_desc'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: widget.onExit,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.iconActive,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              child: Text(
                loc.t('tutorial_start_real_game'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
