import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

enum Direction { up, down, left, right }

class ClassicSnake extends Component {
  final int columns;
  final int rows;
  final double cellSize;
  final Vector2 gridOffset;
  final VoidCallback onDeath;

  late List<Point<int>> body;
  Direction currentDirection = Direction.right;
  final List<Direction> _inputBuffer = [];
  double _tickTimer = 0;
  bool isDead = false;
  bool _shouldGrow = false;

  double _deathTimer = 0;
  bool _isFlashRed = false;

  static const Color _headColor = Color(0xFF4ECCA3);
  static const Color _tailColor = Color(0xFF0E8263);
  static const Color _deathColor = Color(0xFFE84545);

  ClassicSnake({
    required this.columns,
    required this.rows,
    required this.cellSize,
    required this.gridOffset,
    required this.onDeath,
  }) {
    final centerX = columns ~/ 2;
    final centerY = rows ~/ 2;
    body = [
      Point(centerX + 2, centerY),
      Point(centerX + 1, centerY),
      Point(centerX, centerY),
    ];
  }

  List<Point<int>> get occupiedCells => body;

  void changeDirection(Direction dir) {
    final effective =
        _inputBuffer.isNotEmpty ? _inputBuffer.last : currentDirection;

    if (_isReverse(dir, effective)) return;

    if (_inputBuffer.length < 2) {
      _inputBuffer.add(dir);
    }
  }

  bool _isReverse(Direction a, Direction b) {
    return (a == Direction.up && b == Direction.down) ||
        (a == Direction.down && b == Direction.up) ||
        (a == Direction.left && b == Direction.right) ||
        (a == Direction.right && b == Direction.left);
  }

  void grow() {
    _shouldGrow = true;
  }

  @override
  void update(double dt) {
    if (isDead) {
      _deathTimer += dt;
      final flashIndex = (_deathTimer / 0.083).floor();
      _isFlashRed = flashIndex.isOdd;
      if (_deathTimer >= 0.5) {
        onDeath();
      }
      return;
    }

    _tickTimer += dt;
    if (_tickTimer >= 0.2) {
      _tickTimer -= 0.2;

      if (_inputBuffer.isNotEmpty) {
        currentDirection = _inputBuffer.removeAt(0);
      }

      final head = body.first;
      late Point<int> newHead;
      switch (currentDirection) {
        case Direction.up:
          newHead = Point(head.x, head.y - 1);
        case Direction.down:
          newHead = Point(head.x, head.y + 1);
        case Direction.left:
          newHead = Point(head.x - 1, head.y);
        case Direction.right:
          newHead = Point(head.x + 1, head.y);
      }

      // Wall collision
      if (newHead.x < 0 ||
          newHead.x >= columns ||
          newHead.y < 0 ||
          newHead.y >= rows) {
        isDead = true;
        return;
      }

      // Self collision — exclude last element if not growing
      final checkBody =
          _shouldGrow ? body : body.sublist(0, body.length - 1);
      if (checkBody.any((p) => p.x == newHead.x && p.y == newHead.y)) {
        isDead = true;
        return;
      }

      body.insert(0, newHead);
      if (_shouldGrow) {
        _shouldGrow = false;
      } else {
        body.removeLast();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    for (int i = 0; i < body.length; i++) {
      final segment = body[i];
      final Color color;
      if (_isFlashRed) {
        color = _deathColor;
      } else {
        final t = body.length > 1 ? i / (body.length - 1) : 0.0;
        color = Color.lerp(_headColor, _tailColor, t)!;
      }

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          gridOffset.x + segment.x * cellSize,
          gridOffset.y + segment.y * cellSize,
          cellSize,
          cellSize,
        ),
        const Radius.circular(2),
      );
      canvas.drawRRect(rect, Paint()..color = color);
    }
  }
}
