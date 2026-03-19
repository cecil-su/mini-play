import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../components/food_component.dart';
import 'free_snake.dart';

class FreeGame extends FlameGame with KeyboardEvents, MultiTouchTapDetector {
  final ValueNotifier<int> scoreNotifier = ValueNotifier(0);
  final void Function(Map<String, String> stats) onGameOver;
  bool isPaused = false;
  double gameTime = 0;

  late FreeSnake snake;
  late FreeFood food;
  late Vector2 areaMin;
  late Vector2 areaMax;

  FreeGame({required this.onGameOver});

  @override
  Color backgroundColor() => const Color(0xFF16213E);

  @override
  Future<void> onLoad() async {
    areaMin = Vector2(10, 10);
    areaMax = Vector2(size.x - 10, size.y - 10);

    snake = FreeSnake(
      areaMin: areaMin,
      areaMax: areaMax,
      onDeath: _handleDeath,
    );
    await add(snake);

    food = FreeFood(areaMin: areaMin, areaMax: areaMax);
    await add(food);
    food.spawnInitial(snake.headPosition);
  }

  @override
  void update(double dt) {
    if (isPaused) return;
    super.update(dt);
    if (snake.isDead) return;
    gameTime += dt;

    // Food collision: head center to food center < 16px
    final foodCenter = food.position + Vector2.all(FreeFood.radius);
    if (snake.headPosition.distanceTo(foodCenter) < 16) {
      snake.grow();
      scoreNotifier.value++;
      food.respawn(snake.segments, size);
    }
  }

  @override
  void render(Canvas canvas) {
    // Draw play area boundary
    final borderPaint = Paint()
      ..color = const Color(0xFF4A4A6A)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawRect(
      Rect.fromLTRB(areaMin.x, areaMin.y, areaMax.x, areaMax.y),
      borderPaint,
    );
    super.render(canvas);
  }

  @override
  KeyEventResult onKeyEvent(
      KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (isPaused || snake.isDead) return KeyEventResult.ignored;

    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        snake.steer(-1);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        snake.steer(1);
        return KeyEventResult.handled;
      }
    }
    if (event is KeyUpEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
          event.logicalKey == LogicalKeyboardKey.arrowRight) {
        snake.steer(0);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  void onTapDown(int pointerId, TapDownInfo info) {
    if (isPaused || snake.isDead) return;
    final touchX = info.eventPosition.widget.x;
    snake.steer(touchX < size.x / 2 ? -1 : 1);
  }

  @override
  void onTapUp(int pointerId, TapUpInfo info) {
    snake.steer(0);
  }

  @override
  void onTapCancel(int pointerId) {
    snake.steer(0);
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
