// lib/breakout/breakout_game.dart
import 'dart:math';
import 'breakout_config.dart';
import 'breakout_models.dart';
import 'breakout_collision.dart';

class BreakoutGame {
  final BreakoutConfig config;
  final BreakoutMode mode;
  final Random _rng = Random();

  // Game state
  List<Ball> balls = [];
  late Paddle paddle;
  List<Brick> bricks = [];
  List<PowerUp> activePowerUps = [];
  int lives = 0;
  int score = 0;
  int bricksDestroyed = 0;
  int round = 1;
  bool livesLostThisRound = false;
  int roundBricksDestroyed = 0;
  int roundScoreGained = 0;
  double currentBallSpeed = 0;
  bool isGameOver = false;
  bool isWon = false;
  bool waitingToLaunch = true;

  // Power-up timers (seconds remaining)
  double widenTimer = 0;
  double shrinkTimer = 0;
  double penetrateTimer = 0;

  // Visual effect state
  double lifeLossPauseTimer = 0;
  int paddleSquashFrames = 0;
  int paddleFlashFrames = 0;
  String? roundOverlayText;
  double roundOverlayTimer = 0;

  // Per-round tracking for round overlay stats
  int _roundStartBricks = 0;
  int _roundStartScore = 0;

  // Scoring
  double get effectiveMultiplier {
    if (mode == BreakoutMode.endless) {
      return config.scoreMultiplier * config.endlessMultiplier(round);
    }
    return config.scoreMultiplier;
  }

  static const double paddleY = 0.92;
  static const double brickAreaTop = 0.05;
  static const double brickAreaHeight = 0.35;
  static const double paddleSpeed = 1.0;
  static const int maxBalls = 12;
  static const int maxPowerUpsOnScreen = 3;
  static const double powerUpSize = 0.03;
  static const double brickSpacing = 0.003;
  int brickHitsThisFrame = 0;

  BreakoutGame({required this.config, required this.mode}) {
    lives = config.lives;
    currentBallSpeed = config.ballSpeed;
    _initPaddle();
    _generateBricks();
    _spawnBallOnPaddle();
  }

  void _initPaddle() {
    paddle = Paddle(
      x: BreakoutConfig.worldWidth / 2,
      y: paddleY,
      baseWidth: config.paddleWidth,
    );
  }

  void _spawnBallOnPaddle() {
    balls.clear();
    balls.add(Ball(
      x: paddle.x,
      y: paddle.y - paddle.height / 2 - 0.012 - 0.002,
      radius: 0.012,
    ));
    waitingToLaunch = true;
  }

  void _generateBricks() {
    bricks.clear();
    for (int r = 0; r < config.brickRows; r++) {
      for (int c = 0; c < BreakoutConfig.brickCols; c++) {
        final isTopRow = r < 2;
        final hp = _randomHp(isTopRow);
        bricks.add(Brick(row: r, col: c, hp: hp, maxHp: hp));
      }
    }
  }

  int _randomHp(bool isTopRow) {
    if (config.maxBrickHp == 1) return 1;
    final hp2Chance = isTopRow ? 0.50 : 0.15;
    return _rng.nextDouble() < hp2Chance ? 2 : 1;
  }

  // --- Brick geometry helpers ---

  double get brickWidth =>
      (BreakoutConfig.worldWidth - brickSpacing * (BreakoutConfig.brickCols + 1)) / BreakoutConfig.brickCols;
  double get brickHeight =>
      brickAreaHeight / config.brickRows - brickSpacing;

  double brickX(int col) => brickSpacing + col * (brickWidth + brickSpacing);
  double brickY(int row) => brickAreaTop + row * (brickHeight + brickSpacing);

  // --- Launch ---

  void launchBall() {
    if (!waitingToLaunch || isGameOver || isWon) return;
    final ball = balls.first;
    final angle = (_rng.nextDouble() * 60 - 30) * pi / 180;
    ball.vx = currentBallSpeed * sin(angle);
    ball.vy = -currentBallSpeed * cos(angle);
    waitingToLaunch = false;
  }

  // --- Paddle movement ---

  void movePaddleRelative(double dx) {
    if (isGameOver || isWon) return;
    paddle.x = (paddle.x + dx).clamp(
      paddle.width / 2,
      BreakoutConfig.worldWidth - paddle.width / 2,
    );
    if (waitingToLaunch && balls.isNotEmpty) {
      balls.first.x = paddle.x;
    }
  }

  void movePaddleByKeys(Set<String> keysPressed, double dt) {
    if (isGameOver || isWon) return;
    double dx = 0;
    for (final key in keysPressed) {
      if (key == 'left') dx -= paddleSpeed * dt;
      if (key == 'right') dx += paddleSpeed * dt;
    }
    if (dx != 0) movePaddleRelative(dx);
  }

  // --- Main update loop ---

  void update(double dt) {
    if (isGameOver || isWon) return;

    // Life loss pause (power-up timers still tick per spec)
    if (lifeLossPauseTimer > 0) {
      lifeLossPauseTimer -= dt;
      _updatePowerUpTimers(dt);
      return;
    }

    // Round overlay
    if (roundOverlayTimer > 0) {
      roundOverlayTimer -= dt;
      if (roundOverlayTimer <= 0) roundOverlayText = null;
      return;
    }

    if (waitingToLaunch) return;

    // Update power-up timers
    _updatePowerUpTimers(dt);

    // Update visual effects
    for (final brick in bricks) {
      if (brick.flashFrames > 0) brick.flashFrames--;
      if (brick.hp <= 0 && brick.fadeFrames > 0) brick.fadeFrames--;
    }
    // Remove fully faded bricks
    bricks.removeWhere((b) => b.hp <= 0 && b.fadeFrames <= 0);
    if (paddleSquashFrames > 0) paddleSquashFrames--;
    if (paddleFlashFrames > 0) paddleFlashFrames--;

    // Move and collide each ball (with tunneling subdivision)
    for (final ball in balls) {
      ball.collidedThisFrame = false;
      _updateBall(ball, dt);
    }

    // Batch process brick damage
    _processBrickDamage();

    // Move power-ups and check collection
    _updatePowerUps(dt);

    // Check win/loss
    _checkRoundComplete();
    _checkGameOver();
  }

  void _updateBall(Ball ball, double dt) {
    final displacement = ball.speed * dt;
    if (displacement > ball.radius && ball.speed > 0) {
      final steps = (displacement / ball.radius).ceil();
      final subDt = dt / steps;
      for (int i = 0; i < steps; i++) {
        _moveBallStep(ball, subDt);
        if (ball.collidedThisFrame) break;
      }
    } else {
      _moveBallStep(ball, dt);
    }
  }

  void _moveBallStep(Ball ball, double dt) {
    ball.x += ball.vx * dt;
    ball.y += ball.vy * dt;
    _collideBall(ball);
  }

  void _collideBall(Ball ball) {
    // 1. Left/right walls
    if (ball.x - ball.radius <= 0) {
      ball.vx = ball.vx.abs();
      ball.x = ball.radius;
      ball.collidedThisFrame = true;
      return;
    }
    if (ball.x + ball.radius >= BreakoutConfig.worldWidth) {
      ball.vx = -ball.vx.abs();
      ball.x = BreakoutConfig.worldWidth - ball.radius;
      ball.collidedThisFrame = true;
      return;
    }

    // 2. Top wall
    if (ball.y - ball.radius <= 0) {
      ball.vy = ball.vy.abs();
      ball.y = ball.radius;
      ball.collidedThisFrame = true;
      return;
    }

    // 3. Bottom out-of-bounds
    if (ball.y + ball.radius >= BreakoutConfig.worldHeight) {
      ball.vy = 0;
      ball.vx = 0;
      ball.y = BreakoutConfig.worldHeight + ball.radius;
      return;
    }

    // 4. Paddle collision
    if (ball.vy > 0) {
      final result = BreakoutCollision.circleRect(
        cx: ball.x, cy: ball.y, cr: ball.radius,
        rx: paddle.x - paddle.width / 2,
        ry: paddle.y - paddle.height / 2,
        rw: paddle.width,
        rh: paddle.height,
      );
      if (result.hit) {
        final ratio = ((ball.x - paddle.x) / (paddle.width / 2)).clamp(-1.0, 1.0);
        final angle = ratio * 60 * pi / 180;
        ball.vx = ball.speed * sin(angle);
        ball.vy = -(ball.speed * cos(angle)).abs();
        ball.y = paddle.y - paddle.height / 2 - ball.radius;
        ball.collidedThisFrame = true;
        paddleSquashFrames = 3;
        return;
      }
    }

    // 5. Brick collision
    if (ball.collidedThisFrame) return;
    for (final brick in bricks) {
      if (!brick.isActive) continue;
      if (brick.hitThisFrame) continue; // skip bricks already hit (prevents substep duplicate hits)
      final bx = brickX(brick.col);
      final by = brickY(brick.row);
      final result = BreakoutCollision.circleRect(
        cx: ball.x, cy: ball.y, cr: ball.radius,
        rx: bx, ry: by, rw: brickWidth, rh: brickHeight,
      );
      if (result.hit) {
        brick.hitThisFrame = true;
        brick.flashFrames = 3;

        if (ball.isPenetrating) {
          ball.penetrateHits--;
          if (ball.penetrateHits <= 0) {
            // Last penetrate hit: bounce off this brick normally
            ball.isPenetrating = false;
            final (nvx, nvy) = BreakoutCollision.reflect(
              ball.vx, ball.vy, result.normalX, result.normalY,
            );
            ball.vx = nvx;
            ball.vy = nvy;
            ball.x += result.normalX * result.overlap;
            ball.y += result.normalY * result.overlap;
            ball.collidedThisFrame = true;
            return;
          }
          // Still penetrating: continue checking more bricks
          continue;
        } else {
          final (nvx, nvy) = BreakoutCollision.reflect(
            ball.vx, ball.vy, result.normalX, result.normalY,
          );
          ball.vx = nvx;
          ball.vy = nvy;
          ball.x += result.normalX * result.overlap;
          ball.y += result.normalY * result.overlap;
          ball.collidedThisFrame = true;
          return;
        }
      }
    }
  }

  void _processBrickDamage() {
    brickHitsThisFrame = 0;
    final destroyedBricks = <Brick>[];
    for (final brick in bricks) {
      if (brick.hitThisFrame) {
        brick.hp--;
        brick.hitThisFrame = false;
        brickHitsThisFrame++;
        if (brick.hp <= 0) {
          destroyedBricks.add(brick);
        }
      }
    }

    for (final brick in destroyedBricks) {
      brick.fadeFrames = 3;
      score += (brick.score * effectiveMultiplier).round();
      bricksDestroyed++;
      _trySpawnPowerUp(brick);
    }
  }

  // --- Power-ups ---

  void _trySpawnPowerUp(Brick brick) {
    if (activePowerUps.length >= maxPowerUpsOnScreen) return;
    if (_rng.nextDouble() > config.powerUpChance) return;

    final type = _randomPowerUpType();
    if (type == null) return;

    activePowerUps.add(PowerUp(
      x: brickX(brick.col) + brickWidth / 2,
      y: brickY(brick.row) + brickHeight / 2,
      type: type,
    ));
  }

  PowerUpType? _randomPowerUpType() {
    final weights = <PowerUpType, int>{
      PowerUpType.widen: 3,
      PowerUpType.multiBall: 3,
      PowerUpType.penetrate: 3,
      PowerUpType.extraLife: (lives < config.maxLives) ? 1 : 0,
    };
    if (config.hasNegativePowerUps) {
      weights[PowerUpType.shrink] = 1;
    }

    final totalWeight = weights.values.fold(0, (a, b) => a + b);
    if (totalWeight == 0) return null;

    var roll = _rng.nextInt(totalWeight);
    for (final entry in weights.entries) {
      roll -= entry.value;
      if (roll < 0) return entry.key;
    }
    return null;
  }

  void _updatePowerUps(double dt) {
    final toRemove = <PowerUp>[];
    for (final pu in activePowerUps) {
      pu.y += pu.fallSpeed * dt;

      if (BreakoutCollision.rectRect(
        ax: pu.x - powerUpSize / 2, ay: pu.y - powerUpSize / 2,
        aw: powerUpSize, ah: powerUpSize,
        bx: paddle.x - paddle.width / 2, by: paddle.y - paddle.height / 2,
        bw: paddle.width, bh: paddle.height,
      )) {
        _activatePowerUp(pu.type);
        toRemove.add(pu);
        continue;
      }

      if (pu.y > BreakoutConfig.worldHeight + powerUpSize) {
        toRemove.add(pu);
      }
    }
    activePowerUps.removeWhere(toRemove.contains);
  }

  void _clampPaddlePosition() {
    paddle.x = paddle.x.clamp(
      paddle.width / 2,
      BreakoutConfig.worldWidth - paddle.width / 2,
    );
  }

  void _activatePowerUp(PowerUpType type) {
    paddleFlashFrames = 3;
    switch (type) {
      case PowerUpType.widen:
        shrinkTimer = 0;
        widenTimer = 8.0;
        paddle.width = paddle.baseWidth * 2;
        _clampPaddlePosition();
        break;
      case PowerUpType.shrink:
        widenTimer = 0;
        shrinkTimer = 8.0;
        paddle.width = paddle.baseWidth * 0.5;
        _clampPaddlePosition();
        break;
      case PowerUpType.multiBall:
        if (balls.length < maxBalls) {
          final source = balls.firstWhere((b) => b.speed > 0, orElse: () => balls.first);
          final b1 = source.copy();
          final b2 = source.copy();
          final angle1 = 20 * pi / 180;
          final cosA = cos(angle1), sinA = sin(angle1);
          b1.vx = source.vx * cosA - source.vy * sinA;
          b1.vy = source.vx * sinA + source.vy * cosA;
          b2.vx = source.vx * cosA + source.vy * sinA;
          b2.vy = -source.vx * sinA + source.vy * cosA;
          balls.addAll([b1, b2]);
          while (balls.length > maxBalls) {
            balls.removeLast();
          }
        }
        break;
      case PowerUpType.penetrate:
        penetrateTimer = 3.0;
        for (final ball in balls) {
          ball.isPenetrating = true;
          ball.penetrateHits = 5;
        }
        break;
      case PowerUpType.extraLife:
        if (lives < config.maxLives) lives++;
        break;
    }
  }

  void _updatePowerUpTimers(double dt) {
    if (widenTimer > 0) {
      widenTimer -= dt;
      if (widenTimer <= 0) {
        widenTimer = 0;
        paddle.width = paddle.baseWidth;
      }
    }
    if (shrinkTimer > 0) {
      shrinkTimer -= dt;
      if (shrinkTimer <= 0) {
        shrinkTimer = 0;
        paddle.width = paddle.baseWidth;
      }
    }
    if (penetrateTimer > 0) {
      penetrateTimer -= dt;
      if (penetrateTimer <= 0) {
        penetrateTimer = 0;
        for (final ball in balls) {
          ball.isPenetrating = false;
          ball.penetrateHits = 0;
        }
      }
    }
  }

  // --- Round / life management ---

  void _checkRoundComplete() {
    if (bricks.every((b) => !b.isActive)) {
      if (mode == BreakoutMode.endless) {
        _startNewRound();
      } else {
        isWon = true;
      }
    }
  }

  void _startNewRound() {
    // Compute per-round stats BEFORE adding bonus (show brick score only)
    roundBricksDestroyed = bricksDestroyed - _roundStartBricks;
    roundScoreGained = score - _roundStartScore;

    final bonus = livesLostThisRound ? 100 : 200;
    score += bonus;

    // Speed increment uses current round (before increment) for diminishing formula
    currentBallSpeed = min(
      currentBallSpeed + config.speedIncrementForRound(round),
      config.maxBallSpeed,
    );

    round++;
    livesLostThisRound = false;

    _roundStartBricks = bricksDestroyed;
    _roundStartScore = score;

    widenTimer = 0;
    shrinkTimer = 0;
    penetrateTimer = 0;
    paddle.width = paddle.baseWidth;
    activePowerUps.clear();

    _generateBricks();
    _spawnBallOnPaddle();

    roundOverlayText = 'Round $round\nBricks: $roundBricksDestroyed  Score: $roundScoreGained';
    roundOverlayTimer = 1.0;
  }

  void _checkGameOver() {
    if (isWon) return;

    balls.removeWhere((b) => b.y > BreakoutConfig.worldHeight);

    if (balls.isEmpty && !waitingToLaunch) {
      lives--;
      livesLostThisRound = true;
      if (lives <= 0) {
        isGameOver = true;
      } else {
        lifeLossPauseTimer = 1.0;
        _spawnBallOnPaddle();
      }
    }
  }

}
