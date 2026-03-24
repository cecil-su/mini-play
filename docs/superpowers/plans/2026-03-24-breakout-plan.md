# Breakout Game Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Breakout (brick-breaker) game to the mini-play Flutter project with three modes (Classic, Hard, Endless), power-ups, and physics-based ball movement.

**Architecture:** Pure Flutter + Ticker (vsync-driven) + CustomPaint. Game logic lives in `BreakoutGame` class, rendering in `BreakoutPainter`. Height-normalized coordinate system (Y: 0-1, X: 0-0.75) ensures isotropic physics. Follows Tetris-like patterns for page structure, score service, and game scaffold integration.

**Tech Stack:** Flutter 3.41.5, Dart, CustomPaint, Ticker, SharedPreferences (via ScoreService)

**Spec:** `docs/superpowers/specs/2026-03-24-breakout-design.md`

---

## File Map

| File | Responsibility |
|------|---------------|
| `lib/breakout/breakout_config.dart` | `BreakoutMode` enum + `BreakoutConfig` class with per-mode parameters |
| `lib/breakout/breakout_models.dart` | Data models: `Ball`, `Paddle`, `Brick`, `PowerUp`, `PowerUpType` |
| `lib/breakout/breakout_colors.dart` | Color constants for bricks, power-ups, paddle, background |
| `lib/breakout/breakout_collision.dart` | Collision detection: circle-rect, reflect, rect-rect |
| `lib/breakout/breakout_game.dart` | Core game logic: state, physics loop, power-up system, scoring, life/round management |
| `lib/breakout/breakout_painter.dart` | `CustomPainter` subclass: draws all game elements, HUD, visual effects |
| `lib/breakout/breakout_page.dart` | `StatefulWidget`: Ticker loop, input handling, GameScaffold integration, game over flow |
| `lib/breakout/breakout_mode_page.dart` | Mode selection page with 3 `GameModeCard` widgets |
| `lib/main.dart` | Add `/breakout` and `/breakout/play` routes (modify) |
| `lib/home/game_registry.dart` | Add Breakout entry to games list (modify) |

---

### Task 1: Config and Models

**Files:**
- Create: `lib/breakout/breakout_config.dart`
- Create: `lib/breakout/breakout_models.dart`

- [ ] **Step 1: Create breakout_config.dart**

```dart
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
```

- [ ] **Step 2: Create breakout_models.dart**

```dart
// lib/breakout/breakout_models.dart
import 'dart:math';

enum PowerUpType { widen, multiBall, penetrate, extraLife, shrink }

class Ball {
  double x, y;
  double vx, vy;
  double radius;
  bool isPenetrating;
  int penetrateHits;
  bool collidedThisFrame;

  Ball({
    required this.x,
    required this.y,
    this.vx = 0,
    this.vy = 0,
    this.radius = 0.012,
    this.isPenetrating = false,
    this.penetrateHits = 0,
    this.collidedThisFrame = false,
  });

  Ball copy() => Ball(
        x: x, y: y, vx: vx, vy: vy,
        radius: radius,
        isPenetrating: isPenetrating,
        penetrateHits: penetrateHits,
      );

  double get speed => sqrt(vx * vx + vy * vy);

  void setSpeed(double newSpeed) {
    final currentSpeed = speed;
    if (currentSpeed == 0) return;
    final scale = newSpeed / currentSpeed;
    vx *= scale;
    vy *= scale;
  }
}

class Paddle {
  double x, y;
  double baseWidth;
  double width;
  double height;

  Paddle({
    required this.x,
    required this.y,
    required this.baseWidth,
    double? width,
    this.height = 0.015,
  }) : width = width ?? baseWidth;
}

class Brick {
  final int row;
  final int col;
  int hp;
  final int maxHp;
  bool hitThisFrame;
  int flashFrames; // for visual hit feedback
  int fadeFrames;  // for destruction fade-out (3 frames)

  Brick({
    required this.row,
    required this.col,
    required this.hp,
    required this.maxHp,
    this.hitThisFrame = false,
    this.flashFrames = 0,
    this.fadeFrames = 0,
  });

  bool get isDestroyed => hp <= 0 && fadeFrames <= 0;
  bool get isActive => hp > 0; // still hittable

  int get score {
    switch (maxHp) {
      case 1: return 10;
      case 2: return 20;
      default: return 10;
    }
  }
}

class PowerUp {
  double x, y;
  final PowerUpType type;
  final double fallSpeed;

  PowerUp({
    required this.x,
    required this.y,
    required this.type,
    this.fallSpeed = 0.3,
  });
}
```

- [ ] **Step 3: Verify files compile**

Run: `cd D:/Workspace/ai/mini-play && fvm flutter analyze lib/breakout/breakout_config.dart lib/breakout/breakout_models.dart`
Expected: No errors

- [ ] **Step 4: Commit**

```bash
git add lib/breakout/breakout_config.dart lib/breakout/breakout_models.dart
git commit -m "feat(breakout): add config and data models"
```

---

### Task 2: Colors

**Files:**
- Create: `lib/breakout/breakout_colors.dart`

- [ ] **Step 1: Create breakout_colors.dart**

```dart
// lib/breakout/breakout_colors.dart
import 'package:flutter/material.dart';
import 'breakout_models.dart';

class BreakoutColors {
  static const Color background = Color(0xFF1A1A2E);
  static const Color paddle = Color(0xFF4ECCA3);
  static const Color paddleWiden = Color(0xFF3A86FF);
  static const Color paddleShrink = Color(0xFFE84545);
  static const Color ball = Colors.white;
  static const Color ballPenetrating = Color(0xFFBB86FC);
  static const Color hudText = Colors.white70;
  static const Color lifeIcon = Color(0xFFE84545);

  // Brick colors by HP state
  static Color forBrick(int hp, int maxHp) {
    if (maxHp == 1) return const Color(0xFF4ECCA3); // green
    // maxHp == 2
    if (hp == 2) return const Color(0xFFF0A040); // orange (full)
    return const Color(0xFFF0C040); // yellow (damaged)
  }

  // Power-up colors
  static Color forPowerUp(PowerUpType type) {
    switch (type) {
      case PowerUpType.widen: return const Color(0xFF3A86FF);
      case PowerUpType.multiBall: return const Color(0xFF4ECCA3);
      case PowerUpType.penetrate: return const Color(0xFFBB86FC);
      case PowerUpType.extraLife: return const Color(0xFFE84545);
      case PowerUpType.shrink: return const Color(0xFF888888);
    }
  }

  // Power-up icon text
  static String powerUpIcon(PowerUpType type) {
    switch (type) {
      case PowerUpType.widen: return '↔';
      case PowerUpType.multiBall: return '×3';
      case PowerUpType.penetrate: return '↓';
      case PowerUpType.extraLife: return '♥';
      case PowerUpType.shrink: return '↕';
    }
  }
}
```

- [ ] **Step 2: Verify compiles**

Run: `cd D:/Workspace/ai/mini-play && fvm flutter analyze lib/breakout/breakout_colors.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/breakout/breakout_colors.dart
git commit -m "feat(breakout): add color definitions"
```

---

### Task 3: Collision Detection

**Files:**
- Create: `lib/breakout/breakout_collision.dart`

- [ ] **Step 1: Create breakout_collision.dart**

This is the most algorithmically dense file. It handles circle-rect collision with overlap resolution.

```dart
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
```

- [ ] **Step 2: Verify compiles**

Run: `cd D:/Workspace/ai/mini-play && fvm flutter analyze lib/breakout/breakout_collision.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/breakout/breakout_collision.dart
git commit -m "feat(breakout): add collision detection with overlap resolution"
```

---

### Task 4: Core Game Logic

**Files:**
- Create: `lib/breakout/breakout_game.dart`

This is the largest file (~350 lines). It manages game state, physics, power-ups, scoring, and life/round management. Split into substeps for manageability.

**Note:** Individual file compilation (`flutter analyze lib/breakout/...`) works per-task. Full-app compilation (`flutter analyze` without file target) will only pass after Task 8 wires up routing.

- [ ] **Step 1: Create breakout_game.dart — class skeleton, initialization, paddle, ball launch**

Write the file with: class declaration, all fields and constants, constructor, `_initPaddle`, `_spawnBallOnPaddle`, `_generateBricks`, `_randomHp`, brick geometry helpers, `launchBall`, `movePaddleRelative`, `movePaddleByKeys`, `_clampPaddlePosition`, and `reset`.

- [ ] **Step 2: Add update loop, ball physics, and collision**

Add to the same file: `update`, `_updateBall`, `_moveBallStep`, `_collideBall` (walls, paddle, bricks with penetrating ball support), `_processBrickDamage`.

- [ ] **Step 3: Add power-up system**

Add to the same file: `_trySpawnPowerUp`, `_randomPowerUpType`, `_updatePowerUps`, `_activatePowerUp`, `_updatePowerUpTimers`.

- [ ] **Step 4: Add round/life management**

Add to the same file: `_checkRoundComplete`, `_startNewRound`, `_checkGameOver`, `effectiveMultiplier` getter.

The complete file contents (all substeps combined):

```dart
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
  int paddleFlashFrames = 0; // flash on power-up activation
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
  static const double brickSpacing = 0.003; // ~2px equivalent
  int brickHitsThisFrame = 0; // for haptic feedback tracking

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
    final brickWidth = (BreakoutConfig.worldWidth - brickSpacing * (BreakoutConfig.brickCols + 1)) / BreakoutConfig.brickCols;
    final brickHeight = brickAreaHeight / config.brickRows - brickSpacing;

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
    // Row-weighted distribution
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
    final angle = (_rng.nextDouble() * 60 - 30) * pi / 180; // -30 to +30 deg
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
    // Keys are checked externally, this receives direction
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
      // Subdivide to prevent tunneling
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

    // 3. Bottom out-of-bounds (handled after all balls processed)
    if (ball.y + ball.radius >= BreakoutConfig.worldHeight) {
      ball.vy = 0;
      ball.vx = 0;
      ball.y = BreakoutConfig.worldHeight + ball.radius; // mark as out
      return;
    }

    // 4. Paddle collision
    if (ball.vy > 0) { // only when moving downward
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
        ball.vy = -(ball.speed * cos(angle)).abs(); // always upward
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
            ball.isPenetrating = false;
            ball.collidedThisFrame = true;
            return; // lost penetration, stop
          }
          // Still penetrating: continue checking more bricks
          continue;
        } else {
          // Reflect velocity
          final (nvx, nvy) = BreakoutCollision.reflect(
            ball.vx, ball.vy, result.normalX, result.normalY,
          );
          ball.vx = nvx;
          ball.vy = nvy;
          // Reposition
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
        if (brick.isDestroyed) {
          destroyedBricks.add(brick);
        }
      }
    }

    for (final brick in destroyedBricks) {
      brick.fadeFrames = 3; // fade-out animation
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
    // Weights: widen=3, multiBall=3, penetrate=3, extraLife=1, shrink=1(if enabled)
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

      // Check paddle catch
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

      // Off screen
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
    paddleFlashFrames = 3; // visual feedback for any power-up activation
    switch (type) {
      case PowerUpType.widen:
        shrinkTimer = 0; // override shrink
        widenTimer = 8.0;
        paddle.width = paddle.baseWidth * 2;
        _clampPaddlePosition();
        break;
      case PowerUpType.shrink:
        widenTimer = 0; // override widen
        shrinkTimer = 8.0;
        paddle.width = paddle.baseWidth * 0.5;
        _clampPaddlePosition();
        break;
      case PowerUpType.multiBall:
        if (balls.length < maxBalls) {
          final source = balls.firstWhere((b) => b.speed > 0, orElse: () => balls.first);
          final b1 = source.copy();
          final b2 = source.copy();
          // Offset angles by +/-20 degrees
          final angle1 = 20 * pi / 180;
          final cosA = cos(angle1), sinA = sin(angle1);
          b1.vx = source.vx * cosA - source.vy * sinA;
          b1.vy = source.vx * sinA + source.vy * cosA;
          b2.vx = source.vx * cosA + source.vy * sinA;
          b2.vy = -source.vx * sinA + source.vy * cosA;
          balls.addAll([b1, b2]);
          // Cap at maxBalls
          while (balls.length > maxBalls) balls.removeLast();
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
    if (bricks.every((b) => b.isDestroyed)) {
      if (mode == BreakoutMode.endless) {
        _startNewRound();
      } else {
        isWon = true;
      }
    }
  }

  void _startNewRound() {
    final bonus = livesLostThisRound ? 100 : 200;
    score += bonus;

    // Compute per-round stats for overlay
    roundBricksDestroyed = bricksDestroyed - _roundStartBricks;
    roundScoreGained = score - _roundStartScore;

    round++;
    livesLostThisRound = false;

    // Track start of new round for next delta
    _roundStartBricks = bricksDestroyed;
    _roundStartScore = score;

    // Increase speed
    currentBallSpeed = min(
      currentBallSpeed + config.speedIncrementForRound(round),
      config.maxBallSpeed,
    );

    // Clear power-up effects
    widenTimer = 0;
    shrinkTimer = 0;
    penetrateTimer = 0;
    paddle.width = paddle.baseWidth;
    activePowerUps.clear();

    // Generate new bricks
    _generateBricks();
    _spawnBallOnPaddle();

    // Show round overlay with previous round stats
    roundOverlayText = 'Round $round\nBricks: $roundBricksDestroyed  Score: $roundScoreGained';
    roundOverlayTimer = 1.0;
  }

  void _checkGameOver() {
    if (isWon) return; // don't penalize after winning

    // Remove out-of-bounds balls
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

  // --- Reset for replay ---

  void reset() {
    lives = config.lives;
    score = 0;
    bricksDestroyed = 0;
    round = 1;
    livesLostThisRound = false;
    currentBallSpeed = config.ballSpeed;
    isGameOver = false;
    isWon = false;
    widenTimer = 0;
    shrinkTimer = 0;
    penetrateTimer = 0;
    activePowerUps.clear();
    _initPaddle();
    _generateBricks();
    _spawnBallOnPaddle();
  }
}
```

- [ ] **Step 5: Verify compiles**

Run: `cd D:/Workspace/ai/mini-play && fvm flutter analyze lib/breakout/breakout_game.dart`
Expected: No errors

- [ ] **Step 6: Commit**

```bash
git add lib/breakout/breakout_game.dart
git commit -m "feat(breakout): add core game logic with physics, power-ups, scoring"
```

---

### Task 5: Painter

**Files:**
- Create: `lib/breakout/breakout_painter.dart`

- [ ] **Step 1: Create breakout_painter.dart**

```dart
// lib/breakout/breakout_painter.dart
import 'package:flutter/material.dart';
import 'breakout_colors.dart';
import 'breakout_config.dart';
import 'breakout_game.dart';
import 'breakout_models.dart';

class BreakoutPainter extends CustomPainter {
  final BreakoutGame game;
  final int paintVersion;

  BreakoutPainter({required this.game, required this.paintVersion});

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    // Scale factor: multiply normalized coords by h to get pixels
    final s = h;

    // 1. Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = BreakoutColors.background,
    );

    // 2. Bricks (including fading-out destroyed bricks)
    for (final brick in game.bricks) {
      final bx = game.brickX(brick.col) * s;
      final by = game.brickY(brick.row) * s;
      final bw = game.brickWidth * s;
      final bh = game.brickHeight * s;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(bx, by, bw, bh),
        const Radius.circular(3),
      );

      // Fade-out for destroyed bricks
      double opacity = 1.0;
      if (brick.hp <= 0 && brick.fadeFrames > 0) {
        opacity = brick.fadeFrames / 3.0;
      }

      Color color;
      if (brick.flashFrames > 0) {
        color = Colors.white.withValues(alpha: opacity);
      } else {
        color = BreakoutColors.forBrick(brick.hp > 0 ? brick.hp : 1, brick.maxHp).withValues(alpha: opacity);
      }
      canvas.drawRRect(rect, Paint()..color = color);

      // Subtle border
      if (opacity > 0.5) {
        canvas.drawRRect(
          rect,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.15 * opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5,
        );
      }
    }

    // 3. Power-ups
    for (final pu in game.activePowerUps) {
      final px = pu.x * s - BreakoutGame.powerUpSize * s / 2;
      final py = pu.y * s - BreakoutGame.powerUpSize * s / 2;
      final ps = BreakoutGame.powerUpSize * s;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(px, py, ps, ps),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, Paint()..color = BreakoutColors.forPowerUp(pu.type));

      // Icon text
      final tp = TextPainter(
        text: TextSpan(
          text: BreakoutColors.powerUpIcon(pu.type),
          style: TextStyle(color: Colors.white, fontSize: ps * 0.6, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(px + (ps - tp.width) / 2, py + (ps - tp.height) / 2));
    }

    // 4. Balls
    for (final ball in game.balls) {
      if (ball.y > BreakoutConfig.worldHeight) continue;
      final color = ball.isPenetrating ? BreakoutColors.ballPenetrating : BreakoutColors.ball;
      canvas.drawCircle(
        Offset(ball.x * s, ball.y * s),
        ball.radius * s,
        Paint()..color = color,
      );
      if (ball.isPenetrating) {
        // Glow effect
        canvas.drawCircle(
          Offset(ball.x * s, ball.y * s),
          ball.radius * s * 1.5,
          Paint()
            ..color = BreakoutColors.ballPenetrating.withValues(alpha: 0.2)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }
    }

    // 5. Paddle
    final Color paddleColor;
    if (game.paddleFlashFrames > 0) {
      paddleColor = Colors.white; // flash on power-up activation
    } else if (game.widenTimer > 0) {
      paddleColor = BreakoutColors.paddleWiden;
    } else if (game.shrinkTimer > 0) {
      paddleColor = BreakoutColors.paddleShrink;
    } else {
      paddleColor = BreakoutColors.paddle;
    }
    final squash = game.paddleSquashFrames > 0 ? 0.7 : 1.0;
    final pw = game.paddle.width * s;
    final ph = game.paddle.height * s * squash;
    final px = game.paddle.x * s - pw / 2;
    final py = game.paddle.y * s - ph / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(px, py, pw, ph), const Radius.circular(4)),
      Paint()..color = paddleColor,
    );

    // 6. HUD - Lives
    final lifeRadius = 6.0;
    for (int i = 0; i < game.lives; i++) {
      canvas.drawCircle(
        Offset(lifeRadius + 2 + i * (lifeRadius * 2 + 4), size.height - lifeRadius - 4),
        lifeRadius,
        Paint()..color = BreakoutColors.lifeIcon,
      );
    }

    // HUD - Round (endless)
    if (game.mode == BreakoutMode.endless) {
      final tp = TextPainter(
        text: TextSpan(
          text: 'R${game.round}',
          style: TextStyle(color: BreakoutColors.hudText, fontSize: 14),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(size.width - tp.width - 8, size.height - tp.height - 4));
    }

    // HUD - Active power-up timers
    double timerX = lifeRadius + 2 + game.lives * (lifeRadius * 2 + 4) + 8;
    if (game.widenTimer > 0) {
      _drawTimerBadge(canvas, timerX, size.height - 16, '↔ ${game.widenTimer.ceil()}s', BreakoutColors.paddleWiden);
      timerX += 50;
    }
    if (game.shrinkTimer > 0) {
      _drawTimerBadge(canvas, timerX, size.height - 16, '↕ ${game.shrinkTimer.ceil()}s', BreakoutColors.paddleShrink);
      timerX += 50;
    }
    if (game.penetrateTimer > 0) {
      _drawTimerBadge(canvas, timerX, size.height - 16, '↓ ${game.penetrateTimer.ceil()}s', BreakoutColors.ballPenetrating);
    }

    // Life loss flash overlay
    if (game.lifeLossPauseTimer > 0.7) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.white.withValues(alpha: 0.3),
      );
    }

    // Round overlay
    if (game.roundOverlayText != null) {
      final tp = TextPainter(
        text: TextSpan(
          text: game.roundOverlayText,
          style: const TextStyle(
            color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(
        (size.width - tp.width) / 2,
        (size.height - tp.height) / 2,
      ));
    }

    // "Tap to launch" hint
    if (game.waitingToLaunch && game.roundOverlayTimer <= 0) {
      final tp = TextPainter(
        text: const TextSpan(
          text: 'Tap to launch',
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(
        (size.width - tp.width) / 2,
        size.height * 0.7,
      ));
    }
  }

  void _drawTimerBadge(Canvas canvas, double x, double y, String text, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(covariant BreakoutPainter old) =>
      paintVersion != old.paintVersion;
}
```

- [ ] **Step 2: Verify compiles**

Run: `cd D:/Workspace/ai/mini-play && fvm flutter analyze lib/breakout/breakout_painter.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/breakout/breakout_painter.dart
git commit -m "feat(breakout): add CustomPainter with full rendering and HUD"
```

---

### Task 6: Game Page (Ticker, Input, Scaffold Integration)

**Files:**
- Create: `lib/breakout/breakout_page.dart`

- [ ] **Step 1: Create breakout_page.dart**

```dart
// lib/breakout/breakout_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../shared/format_time.dart';
import '../shared/game_over_data.dart';
import '../shared/game_over_page.dart';
import '../shared/game_scaffold.dart';
import '../shared/score_service.dart';
import 'breakout_config.dart';
import 'breakout_game.dart';
import 'breakout_painter.dart';

class BreakoutPage extends StatefulWidget {
  final BreakoutMode mode;

  const BreakoutPage({super.key, required this.mode});

  @override
  State<BreakoutPage> createState() => _BreakoutPageState();
}

class _BreakoutPageState extends State<BreakoutPage>
    with TickerProviderStateMixin {
  Key _gameKey = UniqueKey();
  late BreakoutGame _game;
  final ValueNotifier<int> _scoreNotifier = ValueNotifier<int>(0);
  int _bestScore = 0;
  int _paintVersion = 0;
  bool _isPaused = false;
  bool _gameOverHandled = false;
  late Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  int _elapsedSeconds = 0;
  double _elapsedAccumulator = 0;
  final Set<String> _keysPressed = {};
  Size _canvasSize = Size.zero;

  String get _modeName {
    switch (widget.mode) {
      case BreakoutMode.classic: return 'Classic';
      case BreakoutMode.hard: return 'Hard';
      case BreakoutMode.endless: return 'Endless';
    }
  }

  bool get _canPlay => !_isPaused && !_game.isGameOver && !_game.isWon;

  @override
  void initState() {
    super.initState();
    _createGame();
    _loadBestScore();
    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  void _createGame() {
    final config = BreakoutConfig.forMode(widget.mode);
    _game = BreakoutGame(config: config, mode: widget.mode);
    _elapsedSeconds = 0;
    _elapsedAccumulator = 0;
    _isPaused = false;
    _scoreNotifier.value = 0;
    _lastElapsed = Duration.zero;
    _keysPressed.clear();
    _gameOverHandled = false;
  }

  Future<void> _loadBestScore() async {
    _bestScore = await ScoreService().getHighScore('breakout', widget.mode.name);
    if (mounted) setState(() {});
  }

  void _onTick(Duration elapsed) {
    if (_lastElapsed == Duration.zero) {
      _lastElapsed = elapsed;
      return;
    }

    final dtRaw = (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    final dt = dtRaw.clamp(0.0, 0.033); // cap at ~2 frames

    if (!_canPlay) return;

    // Keyboard movement
    _game.movePaddleByKeys(_keysPressed, dt);

    // Update game
    _game.update(dt);

    // Track time (exclude pauses inside game: lifeLoss, roundOverlay)
    if (_game.lifeLossPauseTimer <= 0 && _game.roundOverlayTimer <= 0 && !_game.waitingToLaunch) {
      _elapsedAccumulator += dt;
      if (_elapsedAccumulator >= 1.0) {
        _elapsedSeconds += _elapsedAccumulator.floor();
        _elapsedAccumulator %= 1.0;
      }
    }

    _scoreNotifier.value = _game.score;
    _paintVersion++;
    setState(() {});

    // Check game over (with guard to prevent multiple pushes)
    if ((_game.isGameOver || _game.isWon) && !_gameOverHandled) {
      _gameOverHandled = true;
      _ticker.stop();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _onGameOver();
      });
    }
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowLeft:
        case LogicalKeyboardKey.keyA:
          _keysPressed.add('left');
          return KeyEventResult.handled;
        case LogicalKeyboardKey.arrowRight:
        case LogicalKeyboardKey.keyD:
          _keysPressed.add('right');
          return KeyEventResult.handled;
        case LogicalKeyboardKey.space:
          _game.launchBall();
          return KeyEventResult.handled;
        case LogicalKeyboardKey.escape:
          Navigator.maybePop(context);
          return KeyEventResult.handled;
        default:
          return KeyEventResult.ignored;
      }
    } else if (event is KeyUpEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowLeft:
        case LogicalKeyboardKey.keyA:
          _keysPressed.remove('left');
          return KeyEventResult.handled;
        case LogicalKeyboardKey.arrowRight:
        case LogicalKeyboardKey.keyD:
          _keysPressed.remove('right');
          return KeyEventResult.handled;
        default:
          return KeyEventResult.ignored;
      }
    }
    return KeyEventResult.ignored;
  }

  void _onTapDown(TapDownDetails details) {
    if (!_canPlay) return;
    if (_game.waitingToLaunch) {
      _game.launchBall();
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_canPlay) return;
    if (_canvasSize.height == 0) return;
    // Relative drag: convert pixel delta to normalized units
    final dx = details.delta.dx / _canvasSize.height; // use height for normalization
    _game.movePaddleRelative(dx);
  }

  void _onPause() => _isPaused = true;
  void _onResume() => _isPaused = false;

  Future<void> _onGameOver() async {
    await ScoreService().saveHighScore('breakout', widget.mode.name, _game.score);
    final best = await ScoreService().getHighScore('breakout', widget.mode.name);
    if (!mounted) return;

    final stats = <String, String>{
      'Score': '${_game.score}',
      'Best': '$best',
      'Bricks': '${_game.bricksDestroyed}',
      'Time': formatTime(_elapsedSeconds),
    };
    if (widget.mode == BreakoutMode.endless) {
      stats['Rounds'] = '${_game.round}';
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameOverPage(
          data: GameOverData(
            gameName: 'breakout',
            mode: widget.mode.name,
            stats: stats,
            replayCallback: _replay,
            title: _game.isWon ? 'You Win!' : null,
            actions: [
              GameOverAction(
                label: 'Play Again',
                onPressed: () {
                  Navigator.pop(context); // pop GameOverPage first
                  _replay();
                },
                isPrimary: true,
              ),
              GameOverAction(
                label: 'Choose Mode',
                onPressed: () => Navigator.pop(context),
              ),
              GameOverAction(
                label: 'Home',
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _replay() {
    setState(() {
      _gameKey = UniqueKey();
      _createGame();
      // Restart ticker (reuse via stop/start, reset elapsed tracking)
      if (!_ticker.isActive) {
        _ticker.stop();
        _ticker.dispose();
        _ticker = createTicker(_onTick);
        _ticker.start();
      }
    });
    _loadBestScore();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scoreNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      key: _gameKey,
      title: 'Breakout - $_modeName',
      scoreNotifier: _scoreNotifier,
      bestScore: _bestScore,
      onPause: _onPause,
      onResume: _onResume,
      canPause: () => !_game.isGameOver && !_game.isWon,
      child: Focus(
        autofocus: true,
        onKeyEvent: _onKeyEvent,
        child: Center(
          child: AspectRatio(
            aspectRatio: BreakoutConfig.aspectRatio,
            child: LayoutBuilder(
              builder: (context, constraints) {
                _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
                return GestureDetector(
                  onTapDown: _onTapDown,
                  onPanUpdate: _onPanUpdate,
                  child: CustomPaint(
                    size: _canvasSize,
                    painter: BreakoutPainter(
                      game: _game,
                      paintVersion: _paintVersion,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify compiles**

Run: `cd D:/Workspace/ai/mini-play && fvm flutter analyze lib/breakout/breakout_page.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/breakout/breakout_page.dart
git commit -m "feat(breakout): add game page with Ticker loop, input handling, scaffold"
```

---

### Task 7: Mode Page

**Files:**
- Create: `lib/breakout/breakout_mode_page.dart`

- [ ] **Step 1: Create breakout_mode_page.dart**

```dart
// lib/breakout/breakout_mode_page.dart
import 'package:flutter/material.dart';
import '../shared/game_mode_card.dart';
import 'breakout_config.dart';

class BreakoutModePage extends StatelessWidget {
  const BreakoutModePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Breakout'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GameModeCard(
            title: 'Classic',
            description: '3 lives, standard speed. Clear all bricks to win.',
            icon: Icons.play_arrow,
            accent: const Color(0xFF4ECCA3),
            gameName: 'breakout',
            scoreKey: 'classic',
            route: '/breakout/play',
            arguments: BreakoutMode.classic,
          ),
          GameModeCard(
            title: 'Hard',
            description: '1 life, 1.5x ball speed. One mistake and it\'s over.',
            icon: Icons.local_fire_department,
            accent: const Color(0xFFE84545),
            gameName: 'breakout',
            scoreKey: 'hard',
            route: '/breakout/play',
            arguments: BreakoutMode.hard,
          ),
          GameModeCard(
            title: 'Endless',
            description: 'Survive as long as you can. Speed increases each round.',
            icon: Icons.all_inclusive,
            accent: const Color(0xFF3A86FF),
            gameName: 'breakout',
            scoreKey: 'endless',
            route: '/breakout/play',
            arguments: BreakoutMode.endless,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Verify compiles**

Run: `cd D:/Workspace/ai/mini-play && fvm flutter analyze lib/breakout/breakout_mode_page.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/breakout/breakout_mode_page.dart
git commit -m "feat(breakout): add mode selection page"
```

---

### Task 8: Routing and Registry Integration

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/home/game_registry.dart`

- [ ] **Step 1: Add Breakout to game_registry.dart**

After the Sudoku entry (line 87), add:

```dart
    GameInfo(
      name: 'Breakout',
      icon: Icons.sports_tennis,
      description: 'Break bricks with a ball and paddle',
      phase: 5,
      route: '/breakout',
      implemented: true,
      hasModePage: true,
    ),
```

- [ ] **Step 2: Add routes to main.dart**

Add imports at top of `main.dart`:

```dart
import 'breakout/breakout_config.dart';
import 'breakout/breakout_mode_page.dart';
import 'breakout/breakout_page.dart';
```

Add route cases before the `default:` case (after `/sudoku/play` case):

```dart
          case '/breakout':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const BreakoutModePage(),
            );
          case '/breakout/play':
            final mode = settings.arguments as BreakoutMode? ?? BreakoutMode.classic;
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => BreakoutPage(mode: mode),
            );
```

- [ ] **Step 3: Verify full app compiles**

Run: `cd D:/Workspace/ai/mini-play && fvm flutter analyze`
Expected: No errors

- [ ] **Step 4: Commit**

```bash
git add lib/main.dart lib/home/game_registry.dart
git commit -m "feat(breakout): wire up routing and enable in game registry"
```

---

### Task 9: Integration Testing and Polish

**Files:**
- May modify any `lib/breakout/` file for bug fixes

- [ ] **Step 1: Run the app and navigate to Breakout**

Run: `cd D:/Workspace/ai/mini-play && fvm flutter run -d chrome`

Verify:
- Breakout appears on home page with correct icon and description
- Tapping opens mode selection page with 3 modes
- Each mode card shows "Best: --" initially

- [ ] **Step 2: Test Classic mode gameplay**

- Tap Classic -> game starts with ball on paddle
- Tap to launch -> ball fires upward
- Ball bounces off walls, bricks, paddle correctly
- Bricks change color when damaged, disappear when destroyed
- Score updates in top bar
- Power-ups drop and can be caught
- Losing all 3 lives triggers game over
- Clearing all bricks shows "You Win!"

- [ ] **Step 3: Test Hard mode**

- 1 life, faster ball
- Single miss -> immediate game over

- [ ] **Step 4: Test Endless mode**

- Clear round -> "Round 2" overlay
- Ball speed increases
- Round multiplier applies to score
- Round bonus awarded

- [ ] **Step 5: Test input**

- Touch: relative drag moves paddle smoothly
- Keyboard: arrow keys / A/D for paddle, Space to launch
- Pause button works, resume works
- Back button returns to mode page

- [ ] **Step 6: Fix any issues found**

Address bugs discovered during testing.

- [ ] **Step 7: Final commit**

```bash
git add -u
git commit -m "fix(breakout): integration fixes from manual testing"
```

---

### Task 10: Haptic Feedback

**Files:**
- Modify: `lib/breakout/breakout_page.dart`

- [ ] **Step 1: Add haptic feedback calls**

In `_onTick()`, after `_game.update(dt)`, check for events and trigger haptics:

```dart
// After _game.update(dt):
if (_game.lifeLossPauseTimer > 0.9) {
  // Just started life loss pause
  HapticFeedback.heavyImpact();
}
```

For brick hits (any hit, not just destruction), check the `brickHitsThisFrame` counter:

```dart
if (_game.brickHitsThisFrame > 0) {
  HapticFeedback.lightImpact();
}
```

No additional field tracking needed — `brickHitsThisFrame` is reset each frame in `_processBrickDamage()`.

- [ ] **Step 2: Verify compiles and test on device**

Run: `cd D:/Workspace/ai/mini-play && fvm flutter analyze lib/breakout/breakout_page.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/breakout/breakout_page.dart
git commit -m "feat(breakout): add haptic feedback for brick hits and life loss"
```
