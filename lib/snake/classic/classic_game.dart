import 'package:flame/game.dart';

import '../components/food_component.dart';
import '../components/grid_background.dart';
import '../components/grid_snake_game.dart';
import 'classic_snake.dart';

class ClassicGame extends GridSnakeGame {
  static const int gridSize = 20;

  ClassicGame({required super.onGameOver});

  @override
  Future<void> onLoad() async {
    final cellSize =
        ((size.x < size.y ? size.x : size.y) / gridSize).floorToDouble();
    final gridOffset = Vector2(
      (size.x - cellSize * gridSize) / 2,
      (size.y - cellSize * gridSize) / 2,
    );

    await add(GridBackground(
      columns: gridSize,
      rows: gridSize,
      cellSize: cellSize,
      offset: gridOffset,
    ));

    snake = ClassicSnake(
      columns: gridSize,
      rows: gridSize,
      cellSize: cellSize,
      gridOffset: gridOffset,
      onDeath: handleDeath,
    );
    await add(snake);

    food = GridFood(
      columns: gridSize,
      rows: gridSize,
      cellSize: cellSize,
      gridOffset: gridOffset,
    );
    await add(food);
    food.spawnInitial(snake.occupiedCells);
  }
}
