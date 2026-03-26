import 'dart:math';

import 'fruit_catcher_collision.dart';
import 'fruit_catcher_colors.dart';
import 'fruit_catcher_config.dart';
import 'fruit_catcher_models.dart';

class FruitCatcherGame {
  final FruitCatcherConfig config;
  final FruitCatcherMode mode;
  final Random _rng = Random();

  late Basket basket;
  final List<FruitItem> items = [];
  final List<FloatingText> floatingTexts = [];

  // Scoring
  int score = 0;
  int combo = 0;
  int maxCombo = 0;
  int fruitsCaught = 0;
  int totalFruitSpawned = 0;
  int bombsDodged = 0;

  // Difficulty
  double difficultyLevel = 0;
  double _spawnTimer = 0;

  // Classic mode
  int lives = 0;
  int consecutiveCatches = 0;

  // Timed mode
  double timeRemaining = 0;

  // Endless mode
  int wave = 1;
  int _waveItemsRemaining = 0;
  double wavePauseTimer = 0;

  // Protection
  int _protectedRemaining = 0;

  // Visual state
  double elapsed = 0;
  double shakeTimer = 0;
  double redFlashTimer = 0;
  double basketSquash = 0;

  // Per-frame haptic flags (reset each update)
  int fruitCaughtThisFrame = 0;
  bool bombCaughtThisFrame = false;

  // Game state
  bool isGameOver = false;
  double survivalTime = 0;

  FruitCatcherGame({required this.config, required this.mode}) {
    basket = Basket(
      x: FruitCatcherConfig.worldWidth / 2,
      targetX: FruitCatcherConfig.worldWidth / 2,
    );
    lives = config.lives;
    timeRemaining = config.timeLimit;
    _protectedRemaining = config.protectedSpawns;
    if (mode == FruitCatcherMode.endless) {
      _waveItemsRemaining = config.itemsPerWave;
    }
  }

  // --- Input ---

  void moveBasketByKeys(Set<String> keysPressed, double dt) {
    if (isGameOver) return;
    double dx = 0;
    for (final key in keysPressed) {
      if (key == 'left') dx -= FruitCatcherConfig.keyboardSpeed * dt;
      if (key == 'right') dx += FruitCatcherConfig.keyboardSpeed * dt;
    }
    if (dx != 0) {
      basket.targetX = (basket.targetX + dx).clamp(
        basket.width / 2,
        FruitCatcherConfig.worldWidth - basket.width / 2,
      );
    }
  }

  void moveBasketRelative(double dx) {
    if (isGameOver) return;
    basket.targetX = (basket.targetX + dx).clamp(
      basket.width / 2,
      FruitCatcherConfig.worldWidth - basket.width / 2,
    );
  }

  void moveBasketTo(double x) {
    if (isGameOver) return;
    basket.targetX = x.clamp(
      basket.width / 2,
      FruitCatcherConfig.worldWidth - basket.width / 2,
    );
  }

  // --- Main update loop ---

  void update(double dt) {
    if (isGameOver) return;
    elapsed += dt;
    survivalTime += dt;
    fruitCaughtThisFrame = 0;
    bombCaughtThisFrame = false;

    _updateBasket(dt);
    _updateDifficulty();
    _updateEffects(dt);
    _updateFloatingTexts(dt);

    // Endless wave pause
    if (wavePauseTimer > 0) {
      wavePauseTimer -= dt;
      return;
    }

    // Timed countdown
    if (mode == FruitCatcherMode.timed) {
      timeRemaining -= dt;
      if (timeRemaining <= 0) {
        timeRemaining = 0;
        isGameOver = true;
        return;
      }
    }

    _updateSpawning(dt);
    _updateItems(dt);
    _checkCollisions();
    _cleanupItems();
  }

  // --- Private methods ---

  void _updateBasket(double dt) {
    // High lerp factor for responsive feel
    const lerpFactor = 15.0;
    final t = (lerpFactor * dt).clamp(0.0, 1.0);
    basket.x = basket.x + (basket.targetX - basket.x) * t;

    if (basketSquash > 0) {
      basketSquash = (basketSquash - dt * 5).clamp(0.0, 1.0);
    }
  }

  void _updateDifficulty() {
    switch (mode) {
      case FruitCatcherMode.classic:
        difficultyLevel = fruitsCaught / 10.0;
      case FruitCatcherMode.timed:
        difficultyLevel = max(0, (config.timeLimit - timeRemaining) / 10.0);
      case FruitCatcherMode.endless:
        difficultyLevel = (wave - 1).toDouble();
    }
  }

  void _updateSpawning(double dt) {
    // Endless: check wave completion
    if (mode == FruitCatcherMode.endless && _waveItemsRemaining <= 0) {
      // Only start next wave when all items have left the screen
      if (items.isEmpty) {
        wave++;
        _waveItemsRemaining = min(config.itemsPerWave + wave * 2, 50);
        wavePauseTimer = config.wavePauseDuration;
      }
      return;
    }

    _spawnTimer += dt;
    final interval = config.spawnInterval(difficultyLevel);
    if (_spawnTimer >= interval) {
      _spawnTimer -= interval;
      _spawnItem();
    }
  }

  void _spawnItem() {
    final bool isBomb;
    if (_protectedRemaining > 0) {
      _protectedRemaining--;
      isBomb = false;
    } else {
      isBomb = _rng.nextDouble() < config.bombRatio(difficultyLevel);
    }

    final radius =
        isBomb ? FruitCatcherConfig.bombRadius : FruitCatcherConfig.fruitRadius;
    final minX = radius;
    final maxX = FruitCatcherConfig.worldWidth - radius;
    final x = minX + _rng.nextDouble() * (maxX - minX);
    final speed = config.fallSpeed(difficultyLevel);

    FruitType? fruitType;
    if (!isBomb) {
      fruitType = FruitType.values[_rng.nextInt(FruitType.values.length)];
      totalFruitSpawned++;
    }

    items.add(FruitItem(
      x: x,
      y: -radius,
      speed: speed,
      isBomb: isBomb,
      fruitType: fruitType,
    ));

    if (mode == FruitCatcherMode.endless) {
      _waveItemsRemaining--;
    }
  }

  void _updateItems(double dt) {
    for (final item in items) {
      item.y += item.speed * dt;
    }
  }

  void _checkCollisions() {
    final caught = <FruitItem>[];
    for (final item in items) {
      if (FruitCatcherCollision.caught(item, basket)) {
        caught.add(item);
      }
    }

    for (final item in caught) {
      items.remove(item);
      if (item.isBomb) {
        _onBombCaught(item);
      } else {
        _onFruitCaught(item);
      }
    }
  }

  void _onFruitCaught(FruitItem item) {
    final comboScore = FruitCatcherConfig.comboScore(combo);
    score += comboScore;
    combo++;
    if (combo > maxCombo) maxCombo = combo;
    fruitsCaught++;
    consecutiveCatches++;
    basketSquash = 1.0;
    fruitCaughtThisFrame++;

    // Floating score text
    floatingTexts.add(FloatingText(
      x: item.x,
      y: basket.y - basket.height,
      text: '+$comboScore',
      color: FruitCatcherColors.scoreFloat,
    ));

    // Combo time bonus (timed mode)
    if (config.comboStreakForBonus > 0 &&
        consecutiveCatches % config.comboStreakForBonus == 0) {
      timeRemaining = min(timeRemaining + config.comboBonusTime,
          config.timeLimit + 30);
      floatingTexts.add(FloatingText(
        x: item.x,
        y: basket.y - basket.height - 0.04,
        text: '+${config.comboBonusTime.round()}s',
        color: FruitCatcherColors.comboText,
      ));
    }

    // Life recovery (classic mode)
    if (config.streakForLifeRecovery > 0 &&
        consecutiveCatches % config.streakForLifeRecovery == 0 &&
        lives < config.maxLives) {
      lives++;
    }
  }

  void _onBombCaught(FruitItem item) {
    if (isGameOver) return;
    combo = 0;
    consecutiveCatches = 0;
    redFlashTimer = 0.3;
    bombCaughtThisFrame = true;

    if (config.bombInstantDeath) {
      // Endless mode: instant death
      isGameOver = true;
      return;
    }

    if (config.bombPenalty > 0) {
      // Timed mode: score penalty
      score = max(0, score - config.bombPenalty);
      floatingTexts.add(FloatingText(
        x: item.x,
        y: basket.y - basket.height,
        text: '-${config.bombPenalty}',
        color: FruitCatcherColors.penaltyFloat,
      ));
    }

    if (config.lives > 0) {
      // Classic mode: lose life
      lives--;
      shakeTimer = 0.3;
      if (lives <= 0) {
        isGameOver = true;
      }
    }
  }

  void _cleanupItems() {
    final offScreen = <FruitItem>[];
    for (final item in items) {
      if (item.isOffScreen) {
        offScreen.add(item);
      }
    }

    for (final item in offScreen) {
      items.remove(item);
      if (item.isBomb) {
        bombsDodged++;
      } else {
        _onFruitMissed();
      }
    }
  }

  void _onFruitMissed() {
    if (isGameOver) return;
    combo = 0;
    consecutiveCatches = 0;

    if (mode == FruitCatcherMode.classic) {
      lives--;
      shakeTimer = 0.3;
      if (lives <= 0) {
        isGameOver = true;
      }
    }
    // Timed: no penalty for missing
    // Endless: no penalty for missing (only bombs kill)
  }

  void _updateFloatingTexts(double dt) {
    for (final ft in floatingTexts) {
      ft.age += dt;
      ft.y -= FloatingText.riseSpeed * dt;
    }
    floatingTexts.removeWhere((ft) => ft.isDead);
  }

  void _updateEffects(double dt) {
    if (shakeTimer > 0) {
      shakeTimer = (shakeTimer - dt).clamp(0.0, 1.0);
    }
    if (redFlashTimer > 0) {
      redFlashTimer = (redFlashTimer - dt).clamp(0.0, 1.0);
    }
  }
}
