import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_play/snake/classic/classic_snake.dart';

ClassicSnake _createSnake({
  int columns = 10,
  int rows = 10,
  VoidCallback? onDeath,
}) {
  return ClassicSnake(
    columns: columns,
    rows: rows,
    cellSize: 20,
    gridOffset: Vector2.zero(),
    onDeath: onDeath ?? () {},
  );
}

void _tick(ClassicSnake snake, {int times = 1}) {
  for (int i = 0; i < times; i++) {
    snake.update(0.2);
  }
}

void main() {
  group('ClassicSnake', () {
    test('starts at center moving right with length 3', () {
      final snake = _createSnake();
      expect(snake.body.length, 3);
      expect(snake.body[0], const Point(7, 5));
      expect(snake.body[1], const Point(6, 5));
      expect(snake.body[2], const Point(5, 5));
      expect(snake.currentDirection, Direction.right);
      expect(snake.isDead, false);
    });

    test('changeDirection ignores reverse direction (left when moving right)',
        () {
      final snake = _createSnake();
      snake.changeDirection(Direction.left);
      _tick(snake);
      // Should still move right, ignoring left
      expect(snake.body[0], const Point(8, 5));
      expect(snake.currentDirection, Direction.right);
    });

    test('changeDirection accepts non-reverse direction (up)', () {
      final snake = _createSnake();
      snake.changeDirection(Direction.up);
      _tick(snake);
      expect(snake.body[0], const Point(7, 4));
      expect(snake.currentDirection, Direction.up);
    });

    test('input buffer depth is 2, third input is discarded', () {
      final snake = _createSnake();
      // Queue two direction changes
      snake.changeDirection(Direction.up);
      snake.changeDirection(Direction.left);
      // Third should be discarded
      snake.changeDirection(Direction.down);

      _tick(snake); // processes up
      expect(snake.currentDirection, Direction.up);
      expect(snake.body[0], const Point(7, 4));

      _tick(snake); // processes left
      expect(snake.currentDirection, Direction.left);
      expect(snake.body[0], const Point(6, 4));
    });

    test('grow() increases body length by 1 on next tick', () {
      final snake = _createSnake();
      expect(snake.body.length, 3);
      snake.grow();
      _tick(snake);
      expect(snake.body.length, 4);
      expect(snake.body[0], const Point(8, 5));
    });

    test('wall collision: moving right at column edge triggers isDead', () {
      final snake = _createSnake();
      // Head starts at (7,5) in a 10-column grid (max index 9)
      // Need 3 ticks to reach column 9, then one more to go out of bounds
      _tick(snake, times: 2); // head at (9,5)
      expect(snake.isDead, false);
      _tick(snake); // head would be at (10,5) - out of bounds
      expect(snake.isDead, true);
    });

    test('self collision triggers isDead', () {
      final snake = _createSnake();
      // Grow the snake long enough to be able to collide with itself
      // We need at least length 5 to make a U-turn
      snake.grow();
      _tick(snake); // length 4, head at (8,5)
      snake.grow();
      _tick(snake); // length 5, head at (9,5)

      // Now turn up, left, down to collide with self
      snake.changeDirection(Direction.up);
      _tick(snake); // head at (9,4)
      snake.changeDirection(Direction.left);
      _tick(snake); // head at (8,4)
      snake.changeDirection(Direction.down);
      _tick(snake); // head at (8,5) - this is where the body is
      expect(snake.isDead, true);
    });

    test('death animation calls onDeath after 500ms', () {
      bool deathCalled = false;
      final snake = _createSnake(onDeath: () => deathCalled = true);

      // Move snake to wall
      _tick(snake, times: 2); // head at (9,5)
      _tick(snake); // wall collision, isDead = true
      expect(snake.isDead, true);
      expect(deathCalled, false);

      // Death animation runs for 500ms
      snake.update(0.4);
      expect(deathCalled, false);
      snake.update(0.1);
      expect(deathCalled, true);
    });

    test('occupiedCells returns body', () {
      final snake = _createSnake();
      expect(snake.occupiedCells, snake.body);
    });
  });
}
