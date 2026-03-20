import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

class FreeSnake extends Component {
  static const double speed = 120.0;
  static const double turnRate = pi;
  static const double segmentRadius = 8.0;
  static const double segmentSpacing = 18.0;

  static const Color _headColor = Color(0xFF4ECCA3);
  static const Color _tailColor = Color(0xFF0E8263);
  static const Color _deathColor = Color(0xFFE84545);

  final Vector2 areaMin;
  final Vector2 areaMax;
  final VoidCallback onDeath;

  late Vector2 headPosition;
  double heading = 0;
  int steerDirection = 0;
  final List<Vector2> _pathHistory = [];
  int _segmentCount = 3;
  bool isDead = false;
  List<Vector2> _cachedSegments = [];

  double _deathTimer = 0;
  bool _isFlashRed = false;
  bool _deathCallbackFired = false;

  FreeSnake({
    required this.areaMin,
    required this.areaMax,
    required this.onDeath,
  }) {
    headPosition = Vector2(
      (areaMin.x + areaMax.x) / 2,
      (areaMin.y + areaMax.y) / 2,
    );
    _pathHistory.add(headPosition.clone());
  }

  void steer(int direction) {
    steerDirection = direction;
  }

  void grow() {
    _segmentCount++;
  }

  List<Vector2> get segments {
    final result = <Vector2>[headPosition.clone()];
    if (_pathHistory.length < 2) return result;

    double distanceAccumulated = 0;
    int segmentsPlaced = 1;

    for (int i = _pathHistory.length - 1; i > 0 && segmentsPlaced < _segmentCount; i--) {
      final current = _pathHistory[i];
      final previous = _pathHistory[i - 1];
      final segDist = current.distanceTo(previous);
      distanceAccumulated += segDist;

      while (distanceAccumulated >= segmentSpacing && segmentsPlaced < _segmentCount) {
        distanceAccumulated -= segmentSpacing;
        // Interpolate position along this path segment
        final overshoot = distanceAccumulated;
        final t = segDist > 0 ? overshoot / segDist : 0.0;
        final pos = Vector2(
          previous.x + (current.x - previous.x) * t,
          previous.y + (current.y - previous.y) * t,
        );
        result.add(pos);
        segmentsPlaced++;
      }
    }

    return result;
  }

  @override
  void update(double dt) {
    if (isDead) {
      _deathTimer += dt;
      final flashIndex = (_deathTimer / 0.083).floor();
      _isFlashRed = flashIndex.isOdd;
      if (_deathTimer >= 0.5 && !_deathCallbackFired) {
        _deathCallbackFired = true;
        onDeath();
      }
      return;
    }

    // Update heading
    heading += steerDirection * turnRate * dt;

    // Move head
    headPosition += Vector2(cos(heading), sin(heading)) * speed * dt;

    // Append to path history
    _pathHistory.add(headPosition.clone());

    // Trim path history to avoid unbounded growth.
    // Each entry is one frame's movement (~2px at 60fps). The 0.5 divisor
    // provides a conservative margin so segments remain smooth at low frame rates.
    final maxPathLength = (_segmentCount + 2) * (segmentSpacing / 0.5).ceil();
    if (_pathHistory.length > maxPathLength) {
      _pathHistory.removeRange(0, _pathHistory.length - maxPathLength);
    }

    // Wall collision
    if (headPosition.x - segmentRadius < areaMin.x ||
        headPosition.x + segmentRadius > areaMax.x ||
        headPosition.y - segmentRadius < areaMin.y ||
        headPosition.y + segmentRadius > areaMax.y) {
      isDead = true;
      return;
    }

    // Cache segments for reuse in render() — avoids recomputing the path walk.
    _cachedSegments = segments;

    // Self collision — check head vs body segments (skip first 5)
    for (int i = 5; i < _cachedSegments.length; i++) {
      if (headPosition.distanceTo(_cachedSegments[i]) < segmentRadius * 2) {
        isDead = true;
        return;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final segs = _cachedSegments.isNotEmpty ? _cachedSegments : segments;

    // Draw body segments first (tail to head), head last on top
    for (int i = segs.length - 1; i >= 0; i--) {
      final segment = segs[i];
      final Color color;
      if (_isFlashRed) {
        color = _deathColor;
      } else {
        final t = segs.length > 1 ? i / (segs.length - 1) : 0.0;
        color = Color.lerp(_headColor, _tailColor, t)!;
      }

      canvas.drawCircle(
        Offset(segment.x, segment.y),
        segmentRadius,
        Paint()..color = color,
      );
    }
  }
}
