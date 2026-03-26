import 'dart:math';

enum FruitCatcherMode { timed, classic, endless }

class FruitCatcherConfig {
  // World coordinate system (matches Breakout: 3:4 aspect ratio)
  static const double aspectRatio = 3 / 4;
  static const double worldWidth = aspectRatio; // 0.75
  static const double worldHeight = 1.0;

  // Basket
  static const double basketY = 0.92;
  static const double basketWidth = 0.12;
  static const double basketHeight = 0.03;

  // Item sizes
  static const double fruitRadius = 0.018;
  static const double bombRadius = 0.02;

  // Keyboard speed (normalized units/sec)
  static const double keyboardSpeed = 0.8;

  // Mode parameters
  final int lives;
  final int maxLives;
  final double timeLimit;
  final int bombPenalty;
  final bool bombInstantDeath;

  // Difficulty initial parameters
  final double initialSpawnInterval;
  final double minSpawnInterval;
  final double initialFallSpeed;
  final double maxFallSpeedMultiplier;
  final double initialBombRatio;
  final double maxBombRatio;

  // Difficulty curve constants
  final double k1;
  final double k2;
  final double k3;
  final double k4;

  // Combo time bonus (timed mode)
  final int comboStreakForBonus;
  final double comboBonusTime;

  // Wave settings (endless mode)
  final double wavePauseDuration;
  final int itemsPerWave;

  // Opening protection
  final int protectedSpawns;

  // Life recovery (classic mode)
  final int streakForLifeRecovery;

  const FruitCatcherConfig._({
    required this.lives,
    required this.maxLives,
    required this.timeLimit,
    required this.bombPenalty,
    required this.bombInstantDeath,
    required this.initialSpawnInterval,
    required this.minSpawnInterval,
    required this.initialFallSpeed,
    required this.maxFallSpeedMultiplier,
    required this.initialBombRatio,
    required this.maxBombRatio,
    required this.k1,
    required this.k2,
    required this.k3,
    required this.k4,
    required this.comboStreakForBonus,
    required this.comboBonusTime,
    required this.wavePauseDuration,
    required this.itemsPerWave,
    required this.protectedSpawns,
    required this.streakForLifeRecovery,
  });

  static FruitCatcherConfig forMode(FruitCatcherMode mode) {
    switch (mode) {
      case FruitCatcherMode.classic:
        return const FruitCatcherConfig._(
          lives: 5,
          maxLives: 5,
          timeLimit: 0,
          bombPenalty: 0,
          bombInstantDeath: false,
          initialSpawnInterval: 0.8,
          minSpawnInterval: 0.3,
          initialFallSpeed: 0.33,
          maxFallSpeedMultiplier: 2.0,
          initialBombRatio: 0.10,
          maxBombRatio: 0.20,
          k1: 0.15,
          k2: 0.12,
          k3: 0.10,
          k4: 8.0,
          comboStreakForBonus: 0,
          comboBonusTime: 0,
          wavePauseDuration: 0,
          itemsPerWave: 0,
          protectedSpawns: 5,
          streakForLifeRecovery: 20,
        );
      case FruitCatcherMode.timed:
        return const FruitCatcherConfig._(
          lives: 0,
          maxLives: 0,
          timeLimit: 60.0,
          bombPenalty: 2,
          bombInstantDeath: false,
          initialSpawnInterval: 0.8,
          minSpawnInterval: 0.3,
          initialFallSpeed: 0.33,
          maxFallSpeedMultiplier: 2.0,
          initialBombRatio: 0.10,
          maxBombRatio: 0.20,
          k1: 0.15,
          k2: 0.12,
          k3: 0.10,
          k4: 8.0,
          comboStreakForBonus: 5,
          comboBonusTime: 2.0,
          wavePauseDuration: 0,
          itemsPerWave: 0,
          protectedSpawns: 5,
          streakForLifeRecovery: 0,
        );
      case FruitCatcherMode.endless:
        return const FruitCatcherConfig._(
          lives: 0,
          maxLives: 0,
          timeLimit: 0,
          bombPenalty: 0,
          bombInstantDeath: true,
          initialSpawnInterval: 0.6,
          minSpawnInterval: 0.3,
          initialFallSpeed: 0.40,
          maxFallSpeedMultiplier: 2.0,
          initialBombRatio: 0.15,
          maxBombRatio: 0.20,
          k1: 0.18,
          k2: 0.15,
          k3: 0.12,
          k4: 6.0,
          comboStreakForBonus: 0,
          comboBonusTime: 0,
          wavePauseDuration: 2.0,
          itemsPerWave: 15,
          protectedSpawns: 5,
          streakForLifeRecovery: 0,
        );
    }
  }

  // Asymptotic difficulty formulas
  double spawnInterval(double level) =>
      minSpawnInterval +
      (initialSpawnInterval - minSpawnInterval) / (1 + level * k1);

  double fallSpeed(double level) {
    final maxSpeed = initialFallSpeed * maxFallSpeedMultiplier;
    final speed = initialFallSpeed * (1 + level * k2 / (1 + level * k3));
    return min(speed, maxSpeed);
  }

  double bombRatio(double level) =>
      initialBombRatio +
      (maxBombRatio - initialBombRatio) * level / (level + k4);

  // Combo score mapping: 1,1,1,2,2,3,3,5,5,8,8,...
  static int comboScore(int combo) {
    if (combo <= 2) return 1;
    final tier = (combo - 1) ~/ 2;
    const values = [1, 2, 3, 5, 8, 13, 21];
    return tier < values.length ? values[tier] : values.last;
  }
}
