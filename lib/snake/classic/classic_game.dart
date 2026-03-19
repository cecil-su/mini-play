import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../components/food_component.dart';
import '../components/grid_background.dart';
import 'classic_snake.dart';

class ClassicGame extends FlameGame with KeyboardEvents, PanDetector {
  final ValueNotifier<int> scoreNotifier = ValueNotifier(0);
  final void Function(Map<String, String> stats) onGameOver;
  bool isPaused = false;

  static const int gridSize = 20;
  late double cellSize;
  late Vector2 gridOffset;
  late ClassicSnake snake;
  late GridFood food;
  double gameTime = 0;

  // Swipe detection state
  Vector2? _dragStart;
  bool _swipeFired = false;

  ClassicGame({required this.onGameOver});

  @override
  Color backgroundColor() => const Color(0xFF16213E);

  @override
  Future<void> onLoad() async {
    cellSize =
        ((size.x < size.y ? size.x : size.y) / gridSize).floorToDouble();
    gridOffset = Vector2(
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
      onDeath: _handleDeath,
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

  @override
  void update(double dt) {
    if (isPaused) return;
    super.update(dt);
    if (snake.isDead) return;
    gameTime += dt;
    if (snake.body.first.x == food.gridX &&
        snake.body.first.y == food.gridY) {
      snake.grow();
      scoreNotifier.value++;
      food.respawn(snake.occupiedCells, Vector2.zero());
    }
  }

  @override
  KeyEventResult onKeyEvent(
      KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (isPaused || snake.isDead) return KeyEventResult.ignored;
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;
    Direction? dir;
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyW) {
      dir = Direction.up;
    }
    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.keyS) {
      dir = Direction.down;
    }
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.keyA) {
      dir = Direction.left;
    }
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyD) {
      dir = Direction.right;
    }

    if (dir != null) {
      snake.changeDirection(dir);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void onPanStart(DragStartInfo info) {
    _dragStart = info.eventPosition.global;
    _swipeFired = false;
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (_swipeFired || _dragStart == null) return;
    if (isPaused || snake.isDead) return;

    final current = info.eventPosition.global;
    final delta = current - _dragStart!;
    if (delta.length < 20) return;

    Direction dir;
    if (delta.x.abs() > delta.y.abs()) {
      dir = delta.x > 0 ? Direction.right : Direction.left;
    } else {
      dir = delta.y > 0 ? Direction.down : Direction.up;
    }
    snake.changeDirection(dir);
    _swipeFired = true;
  }

  @override
  void onPanEnd(DragEndInfo info) {
    _dragStart = null;
    _swipeFired = false;
  }

  void _handleDeath() {
    final minutes = (gameTime ~/ 60).toString().padLeft(2, '0');
    final seconds = (gameTime.toInt() % 60).toString().padLeft(2, '0');
    onGameOver({
      'Score': '${scoreNotifier.value}',
      'Time': '$minutes:$seconds',
      'Length': '${3 + scoreNotifier.value}',
    });
  }
}
