import 'dart:math';

enum PieceType { I, O, T, S, Z, J, L }

class Piece {
  final PieceType type;
  int rotation; // 0-3
  int row; // top-left anchor row
  int col; // top-left anchor col

  Piece({required this.type, this.rotation = 0, this.row = 0, this.col = 0});

  Piece copy() => Piece(type: type, rotation: rotation, row: row, col: col);

  /// Get the cells occupied by this piece relative to (row, col).
  List<(int, int)> get cells {
    final shape = _shapes[type]![rotation % 4];
    return shape.map((c) => (row + c.$1, col + c.$2)).toList();
  }

  /// Rotate clockwise, returning a new Piece.
  Piece rotated() => copy()..rotation = (rotation + 1) % 4;

  static const Map<PieceType, List<List<(int, int)>>> _shapes = {
    PieceType.I: [
      [(0, 0), (0, 1), (0, 2), (0, 3)],
      [(0, 2), (1, 2), (2, 2), (3, 2)],
      [(2, 0), (2, 1), (2, 2), (2, 3)],
      [(0, 1), (1, 1), (2, 1), (3, 1)],
    ],
    PieceType.O: [
      [(0, 0), (0, 1), (1, 0), (1, 1)],
      [(0, 0), (0, 1), (1, 0), (1, 1)],
      [(0, 0), (0, 1), (1, 0), (1, 1)],
      [(0, 0), (0, 1), (1, 0), (1, 1)],
    ],
    PieceType.T: [
      [(0, 0), (0, 1), (0, 2), (1, 1)],
      [(0, 0), (1, 0), (2, 0), (1, 1)],
      [(1, 0), (1, 1), (1, 2), (0, 1)],
      [(0, 1), (1, 1), (2, 1), (1, 0)],
    ],
    PieceType.S: [
      [(0, 1), (0, 2), (1, 0), (1, 1)],
      [(0, 0), (1, 0), (1, 1), (2, 1)],
      [(0, 1), (0, 2), (1, 0), (1, 1)],
      [(0, 0), (1, 0), (1, 1), (2, 1)],
    ],
    PieceType.Z: [
      [(0, 0), (0, 1), (1, 1), (1, 2)],
      [(0, 1), (1, 0), (1, 1), (2, 0)],
      [(0, 0), (0, 1), (1, 1), (1, 2)],
      [(0, 1), (1, 0), (1, 1), (2, 0)],
    ],
    PieceType.J: [
      [(0, 0), (1, 0), (1, 1), (1, 2)],
      [(0, 0), (0, 1), (1, 0), (2, 0)],
      [(0, 0), (0, 1), (0, 2), (1, 2)],
      [(0, 1), (1, 1), (2, 0), (2, 1)],
    ],
    PieceType.L: [
      [(0, 2), (1, 0), (1, 1), (1, 2)],
      [(0, 0), (1, 0), (2, 0), (2, 1)],
      [(0, 0), (0, 1), (0, 2), (1, 0)],
      [(0, 0), (0, 1), (1, 1), (2, 1)],
    ],
  };

  /// Wall kick offsets for rotation (SRS-like simplified).
  static const List<(int, int)> _wallKicks = [
    (0, 0),
    (0, -1),
    (0, 1),
    (0, -2),
    (0, 2),
    (-1, 0),
    (1, 0),
  ];

  /// Try to rotate with wall kicks, returning the successful piece or null.
  Piece? tryRotate(bool Function(Piece) isValid) {
    final rotated = this.rotated();
    for (final (dr, dc) in _wallKicks) {
      final kicked = rotated.copy()
        ..row = rotated.row + dr
        ..col = rotated.col + dc;
      if (isValid(kicked)) return kicked;
    }
    return null;
  }
}

/// 7-bag random piece generator.
class PieceBag {
  final Random _random = Random();
  final List<PieceType> _bag = [];

  PieceType next() {
    if (_bag.isEmpty) {
      _bag.addAll(PieceType.values);
      _bag.shuffle(_random);
    }
    return _bag.removeLast();
  }
}
