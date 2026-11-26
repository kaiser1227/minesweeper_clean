import 'package:flutter/material.dart';
import '../core/theme_manager.dart';
import '../engine/cell_model.dart';
import 'animated_tile.dart';

class BoardView extends StatelessWidget {
  final List<List<CellModel>> grid;
  final AppTheme theme;
  final bool isFlagMode;
  final Function(int r, int c) onCellTap;
  final Function(int r, int c) onCellLongPress;
  final TransformationController transformationController;

  const BoardView({
    super.key,
    required this.grid,
    required this.theme,
    this.isFlagMode = false,
    required this.onCellTap,
    required this.onCellLongPress,
    required this.transformationController,
  });

  @override
  Widget build(BuildContext context) {
    if (grid.isEmpty) return const SizedBox.shrink();

    final rows = grid.length;
    final cols = grid[0].length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - 24;
        final availableHeight = constraints.maxHeight - 24;

        final double tileSizeByWidth = availableWidth / cols;
        final double tileSizeByHeight = availableHeight / rows;
        double optimalTileSize = tileSizeByWidth < tileSizeByHeight
            ? tileSizeByWidth
            : tileSizeByHeight;

        optimalTileSize = optimalTileSize.clamp(28.0, 48.0);

        final boardWidth = cols * optimalTileSize;
        final boardHeight = rows * optimalTileSize;

        return SizedBox.expand(
          child: InteractiveViewer(
            transformationController: transformationController,
            constrained: false,
            alignment: Alignment.center,
            boundaryMargin: const EdgeInsets.all(320.0),
            minScale: 0.3,
            maxScale: 3.5,
            clipBehavior: Clip.hardEdge,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: boardWidth,
              height: boardHeight,
              decoration: isFlagMode
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(6.0),
                      border: Border.all(
                        color: theme.flagColor.withOpacity(0.6),
                        width: 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.flagColor.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    )
                  : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(rows, (r) {
                  return SizedBox(
                    height: optimalTileSize,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(cols, (c) {
                        final cell = grid[r][c];
                        return AnimatedTile(
                          key: ValueKey('tile_${r}_$c'),
                          cell: cell,
                          theme: theme,
                          size: optimalTileSize,
                          onTap: () => onCellTap(r, c),
                          onLongPress: () => onCellLongPress(r, c),
                        );
                      }),
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}
