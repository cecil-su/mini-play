// lib/breakout/breakout_collision.dart
import 'dart:math';

/// Result of a collision check
class CollisionResult {
  final bool hit;
  final double normalX; // collision normal
  final double normalY;
  final double overlap; // penetration depth

  const CollisionResult({
    this.hit = false,
    this.normalX = 0,
    this.normalY = 0,
    this.overlap = 0,
  });

  static const none = CollisionResult();
}

class BreakoutCollision {
  /// Circle vs axis-aligned rectangle collision.
  /// Returns collision result with normal and overlap for position correction.
  static CollisionResult circleRect({
    required double cx, required double cy, required double cr,
    required double rx, required double ry, required double rw, required double rh,
  }) {
    // Find closest point on rect to circle center
    final closestX = cx.clamp(rx, rx + rw);
    final closestY = cy.clamp(ry, ry + rh);

    final dx = cx - closestX;
    final dy = cy - closestY;
    final distSq = dx * dx + dy * dy;

    if (distSq >= cr * cr) return CollisionResult.none;

    final dist = sqrt(distSq);

    if (dist == 0) {
      // Circle center is inside rect — push out via shortest axis
      final leftDist = cx - rx;
      final rightDist = (rx + rw) - cx;
      final topDist = cy - ry;
      final bottomDist = (ry + rh) - cy;
      final minDist = [leftDist, rightDist, topDist, bottomDist].reduce(min);

      double nx = 0, ny = 0;
      if (minDist == leftDist) { nx = -1; }
      else if (minDist == rightDist) { nx = 1; }
      else if (minDist == topDist) { ny = -1; }
      else { ny = 1; }

      return CollisionResult(
        hit: true,
        normalX: nx,
        normalY: ny,
        overlap: cr + minDist,
      );
    }

    return CollisionResult(
      hit: true,
      normalX: dx / dist,
      normalY: dy / dist,
      overlap: cr - dist,
    );
  }

  /// Reflect velocity around collision normal
  static (double, double) reflect(double vx, double vy, double nx, double ny) {
    final dot = vx * nx + vy * ny;
    return (vx - 2 * dot * nx, vy - 2 * dot * ny);
  }

  /// Rect vs rect collision (for power-up catching)
  static bool rectRect({
    required double ax, required double ay, required double aw, required double ah,
    required double bx, required double by, required double bw, required double bh,
  }) {
    return ax < bx + bw && ax + aw > bx && ay < by + bh && ay + ah > by;
  }
}
