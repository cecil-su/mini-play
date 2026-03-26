import 'package:flutter/material.dart';

import 'game_of_life_colors.dart';
import 'game_of_life_config.dart';
import 'game_of_life_game.dart';

class GameOfLifePainter extends CustomPainter {
  final GameOfLifeGame game;
  final double cellSize;
  final int paintVersion;
  final Set<(int, int)>? previewCells;
  final Set<(int, int)>? lockedCells;

  GameOfLifePainter({
    required this.game,
    required this.cellSize,
    required this.paintVersion,
    this.previewCells,
    this.lockedCells,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw grid lines (only when zoomed in enough)
    if (cellSize >= GameOfLifeConfig.gridLineThreshold) {
      _drawGridLines(canvas, size);
    }

    // Draw alive cells using batched Path per color
    _drawCells(canvas);

    // Draw preview cells (pattern placement)
    if (previewCells != null && previewCells!.isNotEmpty) {
      _drawCellSet(canvas, previewCells!, GameOfLifeColors.cellPreview);
    }
  }

  void _drawGridLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = GameOfLifeColors.gridLine
      ..strokeWidth = 0.5;

    final w = GameOfLifeConfig.gridWidth;
    final h = GameOfLifeConfig.gridHeight;

    for (int x = 0; x <= w; x++) {
      final dx = x * cellSize;
      canvas.drawLine(Offset(dx, 0), Offset(dx, h * cellSize), paint);
    }
    for (int y = 0; y <= h; y++) {
      final dy = y * cellSize;
      canvas.drawLine(Offset(0, dy), Offset(w * cellSize, dy), paint);
    }
  }

  void _drawCells(Canvas canvas) {
    if (game.isEmpty) return;

    final alivePath = Path();
    final newBornPath = Path();
    final lockedPath = Path();

    final lockedSet = lockedCells ?? const {};
    final newBornSet = game.newBornCells;

    for (int y = game.minY; y <= game.maxY; y++) {
      final rowOff = y * GameOfLifeConfig.gridWidth;
      for (int x = game.minX; x <= game.maxX; x++) {
        if (game.current[rowOff + x] == 1) {
          final rect = Rect.fromLTWH(
            x * cellSize,
            y * cellSize,
            cellSize,
            cellSize,
          );
          if (lockedSet.contains((x, y))) {
            lockedPath.addRect(rect);
          } else if (newBornSet.contains((x, y))) {
            newBornPath.addRect(rect);
          } else {
            alivePath.addRect(rect);
          }
        }
      }
    }

    final alivePaint = Paint()..color = GameOfLifeColors.cellAlive;
    final newBornPaint = Paint()..color = GameOfLifeColors.cellNew;
    final lockedPaint = Paint()..color = GameOfLifeColors.cellLocked;

    canvas.drawPath(alivePath, alivePaint);
    canvas.drawPath(newBornPath, newBornPaint);
    canvas.drawPath(lockedPath, lockedPaint);
  }

  void _drawCellSet(Canvas canvas, Set<(int, int)> cells, Color color) {
    final path = Path();
    for (final (x, y) in cells) {
      path.addRect(Rect.fromLTWH(
        x * cellSize,
        y * cellSize,
        cellSize,
        cellSize,
      ));
    }
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(GameOfLifePainter oldDelegate) =>
      oldDelegate.paintVersion != paintVersion;
}

/// Small thumbnail painter for pattern previews in encyclopedia/challenge lists.
class PatternThumbnailPainter extends CustomPainter {
  final List<(int, int)> cells;
  final Color color;
  final int patternWidth;
  final int patternHeight;

  PatternThumbnailPainter({
    required this.cells,
    this.color = GameOfLifeColors.cellAlive,
    required this.patternWidth,
    required this.patternHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (cells.isEmpty) return;

    final cellW = size.width / (patternWidth + 2);
    final cellH = size.height / (patternHeight + 2);
    final cellSize = cellW < cellH ? cellW : cellH;
    final offsetX = (size.width - (patternWidth + 2) * cellSize) / 2 + cellSize;
    final offsetY =
        (size.height - (patternHeight + 2) * cellSize) / 2 + cellSize;

    final path = Path();
    for (final (x, y) in cells) {
      path.addRect(Rect.fromLTWH(
        offsetX + x * cellSize,
        offsetY + y * cellSize,
        cellSize,
        cellSize,
      ));
    }
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(PatternThumbnailPainter oldDelegate) =>
      oldDelegate.cells != cells;
}
