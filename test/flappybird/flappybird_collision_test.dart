import 'package:flutter_test/flutter_test.dart';
import 'package:mini_play/flappybird/flappybird_collision.dart';

void main() {
  group('circleHitsRect', () {
    test('returns false when circle is far from rect', () {
      expect(
        FlappybirdCollision.circleHitsRect(
          cx: 0.5, cy: 0.5, cr: 0.025,
          rx: 0.0, ry: 0.0, rw: 0.08, rh: 0.3,
        ),
        isFalse,
      );
    });

    test('returns true when circle overlaps rect', () {
      expect(
        FlappybirdCollision.circleHitsRect(
          cx: 0.09, cy: 0.15, cr: 0.025,
          rx: 0.0, ry: 0.0, rw: 0.08, rh: 0.3,
        ),
        isTrue,
      );
    });

    test('returns true when circle is inside rect', () {
      expect(
        FlappybirdCollision.circleHitsRect(
          cx: 0.04, cy: 0.15, cr: 0.025,
          rx: 0.0, ry: 0.0, rw: 0.08, rh: 0.3,
        ),
        isTrue,
      );
    });

    test('returns false when circle just misses rect edge', () {
      expect(
        FlappybirdCollision.circleHitsRect(
          cx: 0.11, cy: 0.15, cr: 0.025,
          rx: 0.0, ry: 0.0, rw: 0.08, rh: 0.3,
        ),
        isFalse,
      );
    });

    test('returns true when circle touches rect corner', () {
      expect(
        FlappybirdCollision.circleHitsRect(
          cx: 0.097, cy: 0.017, cr: 0.025,
          rx: 0.0, ry: 0.0, rw: 0.08, rh: 0.3,
        ),
        isTrue,
      );
    });
  });
}
