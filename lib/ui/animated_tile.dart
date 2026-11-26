import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme_manager.dart';
import '../engine/cell_model.dart';

class AnimatedTile extends StatefulWidget {
  final CellModel cell;
  final AppTheme theme;
  final double size;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const AnimatedTile({
    super.key,
    required this.cell,
    required this.theme,
    required this.size,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<AnimatedTile> createState() => _AnimatedTileState();
}

class _AnimatedTileState extends State<AnimatedTile> {
  Timer? _longPressTimer;
  bool _isPressed = false;
  bool _longPressed = false;
  bool _dragCancelled = false;
  Offset? _downPosition;

  // Ultra-responsive long press duration for fast speedrunning (220ms vs default 500ms)
  static const Duration _fastLongPressDuration = Duration(milliseconds: 220);
  static const double _slopDistance = 10.0;

  void _onPointerDown(PointerDownEvent event) {
    _downPosition = event.position;
    _longPressed = false;
    _dragCancelled = false;
    setState(() {
      _isPressed = true;
    });

    _longPressTimer?.cancel();
    _longPressTimer = Timer(_fastLongPressDuration, () {
      if (!_dragCancelled && mounted) {
        _longPressed = true;
        setState(() {
          _isPressed = false;
        });
        widget.onLongPress();
      }
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_downPosition != null) {
      final distance = (event.position - _downPosition!).distance;
      if (distance > _slopDistance) {
        _cancelInteraction();
      }
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _longPressTimer?.cancel();
    final wasPressed = _isPressed;
    final hadLongPressed = _longPressed;
    final wasCancelled = _dragCancelled;

    setState(() {
      _isPressed = false;
    });

    if (wasPressed && !hadLongPressed && !wasCancelled) {
      widget.onTap();
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _cancelInteraction();
  }

  void _cancelInteraction() {
    _longPressTimer?.cancel();
    if (_isPressed || !_dragCancelled) {
      setState(() {
        _isPressed = false;
        _dragCancelled = true;
      });
    }
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double margin = 1.0;
    final double innerSize = (widget.size - (margin * 2)).clamp(12.0, 60.0);

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOutCubic,
        child: Container(
          width: widget.size,
          height: widget.size,
          padding: const EdgeInsets.all(margin),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            decoration: _buildDecoration(widget.cell, widget.theme),
            child: Center(
              child: _buildTileContent(widget.cell, widget.theme, innerSize),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildDecoration(CellModel cell, AppTheme theme) {
    // 1. Hint active or pulse
    if (cell.isHighlighted && !cell.isRevealed) {
      final hintColor =
          cell.isSafeHint ? theme.hintSafePulse : theme.hintMinePulse;
      return BoxDecoration(
        color: cell.isFlagged
            ? theme.tileUnrevealed
            : hintColor.withOpacity(0.25),
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: hintColor, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: hintColor.withOpacity(0.4),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      );
    }

    // 2. Revealed mine
    if (cell.isRevealed && cell.isMine) {
      return BoxDecoration(
        color: theme.tileDetonated,
        borderRadius: BorderRadius.circular(4.0),
      );
    }

    // 3. Revealed safe cell
    if (cell.isRevealed) {
      return BoxDecoration(
        color: theme.tileRevealed,
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: theme.tileRevealedBorder, width: 0.5),
      );
    }

    // 4. Unrevealed tile
    return BoxDecoration(
      color: theme.tileUnrevealed,
      borderRadius: BorderRadius.circular(4.0),
      border: Border.all(color: theme.tileUnrevealedBorder, width: 0.8),
      boxShadow: theme.isDark
          ? null
          : [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
    );
  }

  Widget _buildTileContent(CellModel cell, AppTheme theme, double innerSize) {
    // If flagged
    if (cell.isFlagged) {
      return Icon(
        Icons.flag_rounded,
        color: theme.flagColor,
        size: innerSize * 0.65,
      );
    }

    // If revealed mine
    if (cell.isRevealed && cell.isMine) {
      return Icon(
        Icons.circle_rounded,
        color: Colors.white,
        size: innerSize * 0.45,
      );
    }

    // If revealed number > 0
    if (cell.isRevealed && cell.neighborMines > 0) {
      return Text(
        '${cell.neighborMines}',
        style: TextStyle(
          color: theme.getNumberColor(cell.neighborMines),
          fontWeight: FontWeight.w800,
          fontSize: innerSize * 0.58,
          height: 1.0,
        ),
      );
    }

    // If hint active
    if (cell.isHighlighted && !cell.isRevealed) {
      final hintColor =
          cell.isSafeHint ? theme.hintSafePulse : theme.hintMinePulse;
      return Icon(
        cell.isSafeHint ? Icons.check_circle_outline : Icons.flag_outlined,
        color: hintColor,
        size: innerSize * 0.55,
      );
    }

    return const SizedBox.shrink();
  }
}
