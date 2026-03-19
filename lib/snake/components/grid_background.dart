import 'package:flame/components.dart';
import 'dart:ui';

class GridBackground extends Component {
  final int columns;
  final int rows;
  final double cellSize;
  final Vector2 offset;

  GridBackground({
    required this.columns,
    required this.rows,
    required this.cellSize,
    required this.offset,
  });

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = const Color(0xFF1E2A4A)
      ..strokeWidth = 1;

    for (int i = 0; i <= columns; i++) {
      final x = offset.x + i * cellSize;
      canvas.drawLine(
        Offset(x, offset.y),
        Offset(x, offset.y + rows * cellSize),
        paint,
      );
    }

    for (int i = 0; i <= rows; i++) {
      final y = offset.y + i * cellSize;
      canvas.drawLine(
        Offset(offset.x, y),
        Offset(offset.x + columns * cellSize, y),
        paint,
      );
    }
  }
}
