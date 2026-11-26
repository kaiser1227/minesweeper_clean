/// Represents the immutable/reactive state of a single tile on the Minesweeper board.
class CellModel {
  final int row;
  final int col;
  final bool isMine;
  final int neighborMines;
  final bool isRevealed;
  final bool isFlagged;
  final bool isHighlighted; // True when highlighted by logic hint
  final bool isSafeHint; // True if hint marks this cell as guaranteed safe
  final int rippleDelayMs; // Staggered ripple animation offset in ms

  const CellModel({
    required this.row,
    required this.col,
    this.isMine = false,
    this.neighborMines = 0,
    this.isRevealed = false,
    this.isFlagged = false,
    this.isHighlighted = false,
    this.isSafeHint = true,
    this.rippleDelayMs = 0,
  });

  CellModel copyWith({
    int? row,
    int? col,
    bool? isMine,
    int? neighborMines,
    bool? isRevealed,
    bool? isFlagged,
    bool? isHighlighted,
    bool? isSafeHint,
    int? rippleDelayMs,
  }) {
    return CellModel(
      row: row ?? this.row,
      col: col ?? this.col,
      isMine: isMine ?? this.isMine,
      neighborMines: neighborMines ?? this.neighborMines,
      isRevealed: isRevealed ?? this.isRevealed,
      isFlagged: isFlagged ?? this.isFlagged,
      isHighlighted: isHighlighted ?? this.isHighlighted,
      isSafeHint: isSafeHint ?? this.isSafeHint,
      rippleDelayMs: rippleDelayMs ?? this.rippleDelayMs,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CellModel &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col &&
          isMine == other.isMine &&
          neighborMines == other.neighborMines &&
          isRevealed == other.isRevealed &&
          isFlagged == other.isFlagged &&
          isHighlighted == other.isHighlighted &&
          isSafeHint == other.isSafeHint;

  @override
  int get hashCode => Object.hash(
        row,
        col,
        isMine,
        neighborMines,
        isRevealed,
        isFlagged,
        isHighlighted,
        isSafeHint,
      );
}

/// Coordinate point helper
class Point2D {
  final int row;
  final int col;

  const Point2D(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Point2D &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => '($row, $col)';
}
