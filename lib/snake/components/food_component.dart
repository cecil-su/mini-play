import 'package:flame/components.dart';
import 'dart:ui';
import 'dart:math';

abstract class FoodComponent<T> extends PositionComponent {
  static const Color foodColor = Color(0xFFE84545);
  static const int _maxSpawnAttempts = 1000;

  void respawn(List<T> occupied, Vector2 areaSize);
}

class GridFood extends FoodComponent<Point<int>> {
  final int columns;
  final int rows;
  final double cellSize;
  final Vector2 gridOffset;
  int gridX = 0;
  int gridY = 0;

  GridFood({
    required this.columns,
    required this.rows,
    required this.cellSize,
    required this.gridOffset,
  }) {
    size = Vector2.all(cellSize);
  }

  void spawnInitial(List<Point<int>> occupiedCells) {
    final random = Random();
    int attempts = 0;
    do {
      gridX = (columns ~/ 2) + random.nextInt(columns ~/ 2);
      gridY = random.nextInt(rows);
      attempts++;
    } while (occupiedCells.any((c) => c.x == gridX && c.y == gridY) &&
        attempts < FoodComponent._maxSpawnAttempts);
    if (attempts >= FoodComponent._maxSpawnAttempts) {
      _fallbackSpawn(occupiedCells);
    }
    _updatePosition();
  }

  @override
  void respawn(List<Point<int>> occupiedCells, Vector2 areaSize) {
    final random = Random();
    int attempts = 0;
    do {
      gridX = random.nextInt(columns);
      gridY = random.nextInt(rows);
      attempts++;
    } while (occupiedCells.any((c) => c.x == gridX && c.y == gridY) &&
        attempts < FoodComponent._maxSpawnAttempts);
    if (attempts >= FoodComponent._maxSpawnAttempts) {
      _fallbackSpawn(occupiedCells);
    }
    _updatePosition();
  }

  void _fallbackSpawn(List<Point<int>> occupied) {
    for (int x = 0; x < columns; x++) {
      for (int y = 0; y < rows; y++) {
        if (!occupied.any((c) => c.x == x && c.y == y)) {
          gridX = x;
          gridY = y;
          return;
        }
      }
    }
  }

  void _updatePosition() {
    position = Vector2(
      gridOffset.x + gridX * cellSize,
      gridOffset.y + gridY * cellSize,
    );
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(size.toRect(), const Radius.circular(2)),
      Paint()..color = FoodComponent.foodColor,
    );
  }
}

class FreeFood extends FoodComponent<Vector2> {
  static const double radius = 8.0;
  final Vector2 areaMin;
  final Vector2 areaMax;

  FreeFood({required this.areaMin, required this.areaMax}) {
    size = Vector2.all(radius * 2);
  }

  void spawnInitial(Vector2 snakeHeadPos) {
    final random = Random();
    position = Vector2(
      snakeHeadPos.x + 50 + random.nextDouble() * 100,
      areaMin.y + random.nextDouble() * (areaMax.y - areaMin.y),
    );
    position.x = position.x.clamp(areaMin.x + radius, areaMax.x - radius);
    position.y = position.y.clamp(areaMin.y + radius, areaMax.y - radius);
  }

  @override
  void respawn(List<Vector2> segments, Vector2 areaSize) {
    final random = Random();
    bool tooClose;
    int attempts = 0;
    do {
      position = Vector2(
        areaMin.x +
            radius +
            random.nextDouble() * (areaMax.x - areaMin.x - 2 * radius),
        areaMin.y +
            radius +
            random.nextDouble() * (areaMax.y - areaMin.y - 2 * radius),
      );
      tooClose = segments.any((seg) => position.distanceTo(seg) < 32);
      attempts++;
    } while (tooClose && attempts < FoodComponent._maxSpawnAttempts);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(
      Offset(radius, radius),
      radius,
      Paint()..color = FoodComponent.foodColor,
    );
  }
}
