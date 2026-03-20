import 'package:flame/game.dart';

import '../classic/classic_snake.dart';
import '../components/food_component.dart';
import '../components/grid_background.dart';
import '../components/grid_snake_game.dart';

class AdaptiveGame extends GridSnakeGame {
  static const double _cellSize = 20.0;
  late int columns;
  late int rows;

  AdaptiveGame({required super.onGameOver});

  @override
  Future<void> onLoad() async {
    final maxColumns = (size.x / _cellSize).floor();
    final maxRows = (size.y / _cellSize).floor();
    columns = maxColumns.clamp(5, 40);
    rows = maxRows.clamp(5, 40);
    final gridOffset = Vector2(
      (size.x - _cellSize * columns) / 2,
      (size.y - _cellSize * rows) / 2,
    );

    await add(GridBackground(
      columns: columns,
      rows: rows,
      cellSize: _cellSize,
      offset: gridOffset,
    ));

    snake = ClassicSnake(
      columns: columns,
      rows: rows,
      cellSize: _cellSize,
      gridOffset: gridOffset,
      onDeath: handleDeath,
    );
    await add(snake);

    food = GridFood(
      columns: columns,
      rows: rows,
      cellSize: _cellSize,
      gridOffset: gridOffset,
    );
    await add(food);
    food.spawnInitial(snake.occupiedCells);
  }
}
