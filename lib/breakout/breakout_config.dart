// lib/breakout/breakout_config.dart
import 'dart:math';

enum BreakoutMode { classic, hard, endless }

class BreakoutConfig {
  final int lives;
  final double ballSpeed;
  final double maxBallSpeed;
  final double paddleWidth;
  final int brickRows;
  static const int brickCols = 8;
  final int maxBrickHp;
  final double powerUpChance;
  final bool hasNegativePowerUps;
  final double speedIncrement;
  final double scoreMultiplier;
  final int maxLives;

  const BreakoutConfig({
    required this.lives,
    required this.ballSpeed,
    this.maxBallSpeed = 1.2,
    required this.paddleWidth,
    required this.brickRows,
    required this.maxBrickHp,
    required this.powerUpChance,
    this.hasNegativePowerUps = true,
    this.speedIncrement = 0.0,
    this.scoreMultiplier = 1.0,
    this.maxLives = 5,
  });

  static const double aspectRatio = 3 / 4;
  static const double worldWidth = aspectRatio; // 0.75
  static const double worldHeight = 1.0;

  static BreakoutConfig forMode(BreakoutMode mode) {
    switch (mode) {
      case BreakoutMode.classic:
        return const BreakoutConfig(
          lives: 3,
          ballSpeed: 0.6,
          paddleWidth: 0.15,
          brickRows: 5,
          maxBrickHp: 2,
          powerUpChance: 0.20,
          scoreMultiplier: 1.0,
        );
      case BreakoutMode.hard:
        return const BreakoutConfig(
          lives: 1,
          ballSpeed: 0.9,
          paddleWidth: 0.15,
          brickRows: 6,
          maxBrickHp: 2,
          powerUpChance: 0.15,
          scoreMultiplier: 1.5,
        );
      case BreakoutMode.endless:
        return const BreakoutConfig(
          lives: 3,
          ballSpeed: 0.6,
          paddleWidth: 0.15,
          brickRows: 4,
          maxBrickHp: 2,
          powerUpChance: 0.25,
          speedIncrement: 0.05,
          scoreMultiplier: 1.0,
        );
    }
  }

  /// Diminishing speed increment for endless mode
  double speedIncrementForRound(int round) {
    if (speedIncrement == 0) return 0;
    return speedIncrement / (1 + 0.1 * round);
  }

  /// Endless mode score multiplier: 1 + 0.5 * (round - 1), capped at 5
  double endlessMultiplier(int round) {
    return min(1 + 0.5 * (round - 1), 5.0);
  }
}
