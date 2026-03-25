// lib/flappybird/flappybird_config.dart
import 'dart:math';

enum FlappybirdMode { easy, normal, hard }

class FlappybirdConfig {
  final double gravity;
  final double jumpPower;
  final double maxVelocity;
  final double pipeSpacing;
  final double gapSize;
  final double pipeSpeed;
  final double gapMinY;
  final double gapMaxY;

  const FlappybirdConfig({
    required this.gravity,
    required this.jumpPower,
    required this.maxVelocity,
    required this.pipeSpacing,
    required this.gapSize,
    required this.pipeSpeed,
    required this.gapMinY,
    required this.gapMaxY,
  });

  static const double aspectRatio = 9 / 16;
  static const double worldWidth = aspectRatio; // 0.5625
  static const double worldHeight = 1.0;
  static const double groundHeight = 0.1;
  static const double birdX = worldWidth * 0.2; // ~0.1125
  static const double birdRadius = 0.025;
  static const double pipeWidth = 0.08;
  static const double rotationFactor = pi / 2;

  static FlappybirdConfig forMode(FlappybirdMode mode) {
    switch (mode) {
      case FlappybirdMode.easy:
        return const FlappybirdConfig(
          gravity: 0.9,
          jumpPower: -0.50,
          maxVelocity: 1.0,
          pipeSpacing: 0.55,
          gapSize: 0.28,
          pipeSpeed: 0.25,
          gapMinY: 0.2,
          gapMaxY: 0.7,
        );
      case FlappybirdMode.normal:
        return const FlappybirdConfig(
          gravity: 1.4,
          jumpPower: -0.55,
          maxVelocity: 1.2,
          pipeSpacing: 0.45,
          gapSize: 0.22,
          pipeSpeed: 0.35,
          gapMinY: 0.15,
          gapMaxY: 0.75,
        );
      case FlappybirdMode.hard:
        return const FlappybirdConfig(
          gravity: 2.2,
          jumpPower: -0.58,
          maxVelocity: 1.5,
          pipeSpacing: 0.38,
          gapSize: 0.20,
          pipeSpeed: 0.45,
          gapMinY: 0.12,
          gapMaxY: 0.74,
        );
    }
  }
}
