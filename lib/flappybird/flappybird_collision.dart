// lib/flappybird/flappybird_collision.dart

class FlappybirdCollision {
  /// Circle vs axis-aligned rectangle collision (boolean only).
  static bool circleHitsRect({
    required double cx, required double cy, required double cr,
    required double rx, required double ry, required double rw, required double rh,
  }) {
    final closestX = cx.clamp(rx, rx + rw);
    final closestY = cy.clamp(ry, ry + rh);
    final dx = cx - closestX;
    final dy = cy - closestY;
    return dx * dx + dy * dy <= cr * cr;
  }
}
