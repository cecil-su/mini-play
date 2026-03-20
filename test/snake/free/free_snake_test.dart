import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_play/snake/free/free_snake.dart';

FreeSnake _createSnake({
  VoidCallback? onDeath,
  Vector2? areaMin,
  Vector2? areaMax,
}) {
  return FreeSnake(
    areaMin: areaMin ?? Vector2(0, 0),
    areaMax: areaMax ?? Vector2(500, 500),
    onDeath: onDeath ?? () {},
  );
}

void main() {
  group('FreeSnake initialization', () {
    test('starts at center of play area', () {
      final snake = _createSnake();
      expect(snake.headPosition.x, 250);
      expect(snake.headPosition.y, 250);
      expect(snake.isDead, false);
      expect(snake.heading, 0);
    });

    test('segments returns at least head position', () {
      final snake = _createSnake();
      final segs = snake.segments;
      expect(segs.length, greaterThanOrEqualTo(1));
      expect(segs.first.x, closeTo(snake.headPosition.x, 0.01));
      expect(segs.first.y, closeTo(snake.headPosition.y, 0.01));
    });
  });

  group('FreeSnake movement', () {
    test('moves forward in heading direction (right)', () {
      final snake = _createSnake();
      final startX = snake.headPosition.x;
      final startY = snake.headPosition.y;
      snake.update(0.5);
      // heading = 0 → moves right, speed = 120 → 60px in 0.5s
      expect(snake.headPosition.x, closeTo(startX + 60, 0.1));
      expect(snake.headPosition.y, closeTo(startY, 0.1));
    });

    test('steer(1) turns clockwise', () {
      final snake = _createSnake();
      snake.steer(1);
      snake.update(0.5);
      // turnRate = pi, so 0.5s → heading = pi/2
      expect(snake.heading, closeTo(pi / 2, 0.01));
    });

    test('steer(-1) turns counter-clockwise', () {
      final snake = _createSnake();
      snake.steer(-1);
      snake.update(0.5);
      expect(snake.heading, closeTo(-pi / 2, 0.01));
    });

    test('steer(0) maintains current heading', () {
      final snake = _createSnake();
      snake.steer(1);
      snake.update(0.25);
      final headingAfterTurn = snake.heading;
      snake.steer(0);
      snake.update(0.5);
      expect(snake.heading, closeTo(headingAfterTurn, 0.001));
    });
  });

  group('FreeSnake growth', () {
    test('grow increases segment count over time', () {
      final snake = _createSnake();
      // Build up path history
      for (int i = 0; i < 60; i++) {
        snake.update(1 / 60);
      }
      final segmentsBefore = snake.segments.length;
      snake.grow();
      // Move enough for the new segment to appear
      for (int i = 0; i < 60; i++) {
        snake.update(1 / 60);
      }
      expect(snake.segments.length, greaterThan(segmentsBefore));
    });

    test('segments are spaced along path', () {
      final snake = _createSnake();
      // Move forward to build path history
      for (int i = 0; i < 120; i++) {
        snake.update(1 / 60);
      }
      final segs = snake.segments;
      expect(segs.length, 3);
      // Segments should be roughly segmentSpacing (18px) apart
      for (int i = 0; i < segs.length - 1; i++) {
        final dist = segs[i].distanceTo(segs[i + 1]);
        expect(dist, closeTo(FreeSnake.segmentSpacing, 1.0));
      }
    });
  });

  group('FreeSnake wall collision', () {
    test('dies on right boundary', () {
      final snake = _createSnake(
        areaMin: Vector2(0, 0),
        areaMax: Vector2(300, 300),
      );
      // Starts at (150, 150), heading right at 120px/s
      // Wall at x + segmentRadius(8) > 300 → x > 292
      snake.update(1.0); // head at ~270
      expect(snake.isDead, false);
      snake.update(0.3); // head at ~306
      expect(snake.isDead, true);
    });

    test('dies on top boundary', () {
      final snake = _createSnake(
        areaMin: Vector2(0, 0),
        areaMax: Vector2(500, 500),
      );
      // Turn upward (heading = -pi/2)
      snake.steer(-1);
      snake.update(0.5); // heading = -pi/2
      snake.steer(0);
      // Now heading up, move until wall
      for (int i = 0; i < 100; i++) {
        if (snake.isDead) break;
        snake.update(1 / 60);
      }
      expect(snake.isDead, true);
      // Died from top wall, not side wall
      expect(snake.headPosition.y - FreeSnake.segmentRadius, lessThan(0));
    });
  });

  group('FreeSnake death animation', () {
    test('calls onDeath after 500ms', () {
      bool deathCalled = false;
      final snake = _createSnake(
        onDeath: () => deathCalled = true,
        areaMin: Vector2(0, 0),
        areaMax: Vector2(100, 100),
      );
      // Move right until wall (starts at 50, boundary at 92)
      snake.update(0.5); // head at ~110, past wall
      expect(snake.isDead, true);
      expect(deathCalled, false);

      snake.update(0.4);
      expect(deathCalled, false);
      snake.update(0.1);
      expect(deathCalled, true);
    });

    test('onDeath fires only once', () {
      int deathCount = 0;
      final snake = _createSnake(
        onDeath: () => deathCount++,
        areaMin: Vector2(0, 0),
        areaMax: Vector2(100, 100),
      );
      snake.update(0.5); // die
      snake.update(0.5); // past 500ms
      snake.update(0.5); // well past
      expect(deathCount, 1);
    });
  });

  group('FreeSnake path history', () {
    test('does not grow unbounded', () {
      final snake = _createSnake(
        areaMin: Vector2(0, 0),
        areaMax: Vector2(10000, 10000),
      );
      // Run many frames — snake should not crash or slow down
      for (int i = 0; i < 1000; i++) {
        if (snake.isDead) break;
        snake.update(1 / 60);
      }
      // Snake is still functional
      expect(snake.isDead, false);
      expect(snake.segments.isNotEmpty, true);
    });
  });
}
