# Flappy Bird Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a Flappy Bird game with 3 difficulty modes, physics-based flight, pipe obstacles, parallax backgrounds, and geometric visual style.

**Architecture:** CustomPaint + Ticker pattern (same as Breakout). Game logic in `FlappybirdGame`, rendering in `FlappybirdPainter`, UI wiring in `FlappybirdPage`. Height-normalized coordinate system (worldHeight=1.0, worldWidth=0.5625 for 9:16 aspect ratio).

**Tech Stack:** Flutter 3.41.5, CustomPaint, Ticker, SharedPreferences (via ScoreService)

**Spec:** `docs/superpowers/specs/2026-03-24-flappybird-design.md`

---

### Task 1: Config and Models

**Files:**
- Create: `lib/flappybird/flappybird_config.dart`
- Create: `lib/flappybird/flappybird_models.dart`

- [ ] **Step 1: Create config file with mode enum and config class**

```dart
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
          gravity: 1.2,
          jumpPower: -0.45,
          maxVelocity: 1.0,
          pipeSpacing: 0.55,
          gapSize: 0.28,
          pipeSpeed: 0.25,
          gapMinY: 0.2,
          gapMaxY: 0.7,
        );
      case FlappybirdMode.normal:
        return const FlappybirdConfig(
          gravity: 1.6,
          jumpPower: -0.5,
          maxVelocity: 1.2,
          pipeSpacing: 0.45,
          gapSize: 0.22,
          pipeSpeed: 0.35,
          gapMinY: 0.15,
          gapMaxY: 0.75,
        );
      case FlappybirdMode.hard:
        return const FlappybirdConfig(
          gravity: 2.0,
          jumpPower: -0.55,
          maxVelocity: 1.5,
          pipeSpacing: 0.35,
          gapSize: 0.18,
          pipeSpeed: 0.45,
          gapMinY: 0.12,
          gapMaxY: 0.78,
        );
    }
  }
}
```

- [ ] **Step 2: Create models file**

```dart
// lib/flappybird/flappybird_models.dart

enum GameState { ready, playing, dead, gameOver }

class Bird {
  double x;
  double y;
  double velocity;
  double rotation;
  final double radius;
  double wingPhase;

  Bird({
    required this.x,
    required this.y,
    this.velocity = 0,
    this.rotation = 0,
    this.radius = 0.025,
    this.wingPhase = 0,
  });
}

class Pipe {
  double x;
  final double gapCenterY;
  final double width;
  bool passed;

  Pipe({
    required this.x,
    required this.gapCenterY,
    this.width = 0.08,
    this.passed = false,
  });
}

class Cloud {
  double x;
  final double y;
  final double radius;
  final double speed;

  Cloud({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
  });
}

class Ground {
  double offsetX;
  final double height;

  Ground({this.offsetX = 0, this.height = 0.1});
}
```

- [ ] **Step 3: Verify build**

Run: `fvm flutter build web --release --base-href "/mini-play/" 2>&1 | tail -5`
Expected: Build succeeds (new files are not imported yet, so no impact)

- [ ] **Step 4: Commit**

```bash
git add lib/flappybird/flappybird_config.dart lib/flappybird/flappybird_models.dart
git commit -m "feat(flappybird): add config and data models"
```

---

### Task 2: Collision Detection

**Files:**
- Create: `lib/flappybird/flappybird_collision.dart`
- Create: `test/flappybird/flappybird_collision_test.dart`

- [ ] **Step 1: Write collision tests**

```dart
// test/flappybird/flappybird_collision_test.dart
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
      // Circle at (0.11, 0.15) with radius 0.025 → closest edge at x=0.08
      // distance = 0.11 - 0.08 = 0.03 > 0.025
      expect(
        FlappybirdCollision.circleHitsRect(
          cx: 0.11, cy: 0.15, cr: 0.025,
          rx: 0.0, ry: 0.0, rw: 0.08, rh: 0.3,
        ),
        isFalse,
      );
    });

    test('returns true when circle touches rect corner', () {
      // Circle at (0.097, 0.017) with radius 0.025
      // corner at (0.08, 0.0), dist = sqrt(0.017^2 + 0.017^2) ≈ 0.024 < 0.025
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/flappybird/flappybird_collision_test.dart`
Expected: FAIL — `flappybird_collision.dart` does not exist yet

- [ ] **Step 3: Implement collision**

```dart
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
    return dx * dx + dy * dy < cr * cr;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `fvm flutter test test/flappybird/flappybird_collision_test.dart`
Expected: All 5 tests PASS

- [ ] **Step 5: Commit**

```bash
git add lib/flappybird/flappybird_collision.dart test/flappybird/flappybird_collision_test.dart
git commit -m "feat(flappybird): add circle-rect collision detection with tests"
```

---

### Task 3: Colors

**Files:**
- Create: `lib/flappybird/flappybird_colors.dart`

- [ ] **Step 1: Create colors file**

```dart
// lib/flappybird/flappybird_colors.dart
import 'package:flutter/material.dart';

class FlappybirdColors {
  // Sky gradient
  static const Color skyTop = Color(0xFF87CEEB);    // light blue
  static const Color skyBottom = Color(0xFF4A90D9);  // deeper blue

  // Bird
  static const Color birdBody = Color(0xFFF0C040);   // yellow
  static const Color birdWing = Color(0xFFE8A020);    // darker yellow/orange
  static const Color birdEye = Colors.white;
  static const Color birdPupil = Colors.black;

  // Pipes
  static const Color pipeBody = Color(0xFF4CAF50);       // green
  static const Color pipeBodyDark = Color(0xFF388E3C);    // darker green for gradient
  static const Color pipeCap = Color(0xFF2E7D32);         // cap green
  static const Color pipeCapDark = Color(0xFF1B5E20);     // cap dark

  // Ground
  static const Color groundTop = Color(0xFF8BC34A);    // grass green
  static const Color groundBottom = Color(0xFF795548);  // brown earth

  // Cloud
  static const Color cloud = Color(0x66FFFFFF);  // semi-transparent white

  // HUD / overlay
  static const Color overlayText = Colors.white;
  static const Color overlayTextShadow = Color(0x88000000);
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/flappybird/flappybird_colors.dart
git commit -m "feat(flappybird): add color constants"
```

---

### Task 4: Core Game Logic

**Files:**
- Create: `lib/flappybird/flappybird_game.dart`
- Create: `test/flappybird/flappybird_game_test.dart`

- [ ] **Step 1: Write game logic tests**

```dart
// test/flappybird/flappybird_game_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_play/flappybird/flappybird_config.dart';
import 'package:mini_play/flappybird/flappybird_game.dart';
import 'package:mini_play/flappybird/flappybird_models.dart';

void main() {
  late FlappybirdGame game;

  setUp(() {
    game = FlappybirdGame(config: FlappybirdConfig.forMode(FlappybirdMode.normal));
  });

  group('initial state', () {
    test('starts in ready state', () {
      expect(game.state, GameState.ready);
    });

    test('bird starts at correct position', () {
      expect(game.bird.x, closeTo(FlappybirdConfig.birdX, 0.001));
      expect(game.bird.y, closeTo(0.4, 0.001));
      expect(game.bird.velocity, 0);
    });

    test('score starts at zero', () {
      expect(game.score, 0);
      expect(game.pipesPassed, 0);
    });

    test('has 4 clouds', () {
      expect(game.clouds.length, 4);
    });

    test('has no pipes in ready state', () {
      expect(game.pipes.isEmpty, isTrue);
    });
  });

  group('jump', () {
    test('first jump transitions to playing state', () {
      game.jump();
      expect(game.state, GameState.playing);
    });

    test('jump sets bird velocity to jumpPower', () {
      game.jump();
      expect(game.bird.velocity, game.config.jumpPower);
    });

    test('jump ignored in dead state', () {
      game.jump(); // start playing
      // Manually set dead
      game.state = GameState.dead;
      final vel = game.bird.velocity;
      game.jump();
      expect(game.bird.velocity, vel); // unchanged
    });
  });

  group('physics update', () {
    test('gravity increases velocity downward', () {
      game.jump(); // start playing
      game.bird.velocity = 0;
      game.update(0.016);
      expect(game.bird.velocity, greaterThan(0));
    });

    test('bird y position changes with velocity', () {
      game.jump();
      final y0 = game.bird.y;
      game.update(0.1);
      expect(game.bird.y, isNot(closeTo(y0, 0.0001)));
    });

    test('velocity is clamped to maxVelocity', () {
      game.jump();
      game.bird.velocity = 10.0; // way above max
      game.update(0.016);
      expect(game.bird.velocity, lessThanOrEqualTo(game.config.maxVelocity));
    });

    test('ceiling clamps bird position and zeroes velocity', () {
      game.jump();
      game.bird.y = 0.01; // near top
      game.bird.velocity = -1.0; // moving up fast
      game.update(0.1);
      expect(game.bird.y, greaterThanOrEqualTo(game.bird.radius));
      expect(game.bird.velocity, 0);
    });
  });

  group('ground collision', () {
    test('hitting ground transitions to dead state', () {
      game.jump(); // playing
      game.bird.y = 0.88; // near ground (ground top = 0.9)
      game.bird.velocity = 1.0;
      game.update(0.1);
      expect(game.state, GameState.dead);
    });
  });

  group('pipe generation', () {
    test('pipes generated after game starts and update runs', () {
      game.jump();
      // Run enough updates for first pipe to appear
      for (int i = 0; i < 10; i++) {
        game.update(0.033);
      }
      expect(game.pipes.isNotEmpty, isTrue);
    });
  });

  group('scoring', () {
    test('score increases during playing state', () {
      game.jump();
      game.update(0.1);
      expect(game.score, greaterThan(0));
    });

    test('passing pipe gives bonus', () {
      game.jump();
      // Place a pipe that the bird has already passed
      game.pipes.add(Pipe(
        x: -0.1, // far left, past bird
        gapCenterY: 0.5,
      ));
      final scoreBefore = game.score;
      game.update(0.016);
      expect(game.score, greaterThan(scoreBefore));
      expect(game.pipesPassed, 1);
    });
  });

  group('dead state', () {
    test('bird falls to ground in dead state', () {
      game.jump();
      game.state = GameState.dead;
      game.bird.velocity = 0;
      game.bird.y = 0.5;
      game.update(0.033);
      expect(game.bird.y, greaterThan(0.5));
    });

    test('transitions to gameOver when bird hits ground', () {
      game.jump();
      game.state = GameState.dead;
      game.bird.y = 0.89;
      game.bird.velocity = 1.0;
      game.update(0.1);
      expect(game.state, GameState.gameOver);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `fvm flutter test test/flappybird/flappybird_game_test.dart`
Expected: FAIL — `flappybird_game.dart` does not exist yet

- [ ] **Step 3: Implement core game logic**

```dart
// lib/flappybird/flappybird_game.dart
import 'dart:math';
import 'flappybird_collision.dart';
import 'flappybird_config.dart';
import 'flappybird_models.dart';

class FlappybirdGame {
  final FlappybirdConfig config;
  final Random _rng = Random();

  // State
  GameState state = GameState.ready;
  late Bird bird;
  List<Pipe> pipes = [];
  List<Cloud> clouds = [];
  final Ground ground = Ground();
  int pipesPassed = 0;
  double _rawScore = 0;
  int get score => _rawScore.floor();

  // Ready state bob animation
  double _bobPhase = 0;

  FlappybirdGame({required this.config}) {
    bird = Bird(x: FlappybirdConfig.birdX, y: 0.4);
    _initClouds();
  }

  void _initClouds() {
    clouds.clear();
    for (int i = 0; i < 4; i++) {
      clouds.add(Cloud(
        x: _rng.nextDouble() * FlappybirdConfig.worldWidth,
        y: 0.05 + _rng.nextDouble() * 0.3,
        radius: 0.03 + _rng.nextDouble() * 0.05,
        speed: config.pipeSpeed * 0.3,
      ));
    }
  }

  void jump() {
    if (state == GameState.dead || state == GameState.gameOver) return;
    if (state == GameState.ready) {
      state = GameState.playing;
      _spawnFirstPipe();
    }
    bird.velocity = config.jumpPower;
  }

  void _spawnFirstPipe() {
    pipes.add(_createPipe(FlappybirdConfig.worldWidth + 0.1));
  }

  Pipe _createPipe(double x) {
    final minGap = config.gapMinY;
    final maxGap = config.gapMaxY;
    final gapCenterY = minGap + _rng.nextDouble() * (maxGap - minGap);
    // Clamp to ensure min pipe visibility (0.03)
    final halfGap = config.gapSize / 2;
    final clampedY = gapCenterY.clamp(halfGap + 0.03, 1.0 - FlappybirdConfig.groundHeight - halfGap - 0.03);
    return Pipe(x: x, gapCenterY: clampedY);
  }

  void update(double dt) {
    switch (state) {
      case GameState.ready:
        _updateReady(dt);
        break;
      case GameState.playing:
        _updatePlaying(dt);
        break;
      case GameState.dead:
        _updateDead(dt);
        break;
      case GameState.gameOver:
        break;
    }
  }

  void _updateReady(double dt) {
    _bobPhase += 3.0 * dt;
    bird.y = 0.4 + sin(_bobPhase) * 0.02;
    bird.wingPhase += 10.0 * dt;
  }

  void _updatePlaying(double dt) {
    // Bird physics
    bird.velocity += config.gravity * dt;
    bird.velocity = bird.velocity.clamp(-config.maxVelocity, config.maxVelocity);
    bird.y += bird.velocity * dt;

    // Bird rotation
    bird.rotation = (bird.velocity * FlappybirdConfig.rotationFactor).clamp(-pi / 6, pi / 2);

    // Wing animation
    bird.wingPhase += 10.0 * dt;

    // Ceiling check
    if (bird.y - bird.radius < 0) {
      bird.y = bird.radius;
      bird.velocity = 0;
    }

    // Ground check
    if (bird.y + bird.radius >= 1.0 - ground.height) {
      _die();
      return;
    }

    // Move pipes
    for (final pipe in pipes) {
      pipe.x -= config.pipeSpeed * dt;
    }

    // Pipe pass detection
    for (final pipe in pipes) {
      if (!pipe.passed && pipe.x + pipe.width < bird.x) {
        pipe.passed = true;
        pipesPassed++;
        _rawScore += 10;
      }
    }

    // Pipe collision
    for (final pipe in pipes) {
      if (_birdHitsPipe(pipe)) {
        _die();
        return;
      }
    }

    // Pipe generation
    if (pipes.isNotEmpty && pipes.last.x < FlappybirdConfig.worldWidth) {
      pipes.add(_createPipe(pipes.last.x + config.pipeSpacing));
    }

    // Pipe cleanup
    pipes.removeWhere((p) => p.x + p.width < -0.05);

    // Distance score
    _rawScore += config.pipeSpeed * dt * 100;

    // Scroll ground
    ground.offsetX -= config.pipeSpeed * dt;

    // Scroll clouds
    for (final cloud in clouds) {
      cloud.x -= cloud.speed * dt;
      if (cloud.x + cloud.radius < 0) {
        cloud.x = FlappybirdConfig.worldWidth + cloud.radius + _rng.nextDouble() * 0.1;
      }
    }
  }

  bool _birdHitsPipe(Pipe pipe) {
    final halfGap = config.gapSize / 2;
    // Upper pipe: from y=0 to gapCenterY - halfGap
    final upperBottom = pipe.gapCenterY - halfGap;
    if (upperBottom > 0) {
      if (FlappybirdCollision.circleHitsRect(
        cx: bird.x, cy: bird.y, cr: bird.radius,
        rx: pipe.x, ry: 0, rw: pipe.width, rh: upperBottom,
      )) return true;
    }
    // Lower pipe: from gapCenterY + halfGap to ground top
    final lowerTop = pipe.gapCenterY + halfGap;
    final lowerHeight = (1.0 - ground.height) - lowerTop;
    if (lowerHeight > 0) {
      if (FlappybirdCollision.circleHitsRect(
        cx: bird.x, cy: bird.y, cr: bird.radius,
        rx: pipe.x, ry: lowerTop, rw: pipe.width, rh: lowerHeight,
      )) return true;
    }
    return false;
  }

  void _die() {
    state = GameState.dead;
    bird.velocity = 0;
  }

  void _updateDead(double dt) {
    // Bird falls with gravity, rotation locked at 90 degrees
    bird.velocity += config.gravity * dt;
    bird.velocity = bird.velocity.clamp(-config.maxVelocity, config.maxVelocity);
    bird.y += bird.velocity * dt;
    bird.rotation = pi / 2;

    if (bird.y + bird.radius >= 1.0 - ground.height) {
      bird.y = 1.0 - ground.height - bird.radius;
      state = GameState.gameOver;
    }
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `fvm flutter test test/flappybird/flappybird_game_test.dart`
Expected: All tests PASS

- [ ] **Step 5: Commit**

```bash
git add lib/flappybird/flappybird_game.dart test/flappybird/flappybird_game_test.dart
git commit -m "feat(flappybird): add core game logic with physics, pipes, scoring"
```

---

### Task 5: Painter (Rendering)

**Files:**
- Create: `lib/flappybird/flappybird_painter.dart`

Reference files:
- `lib/breakout/breakout_painter.dart` — same CustomPainter pattern
- `docs/superpowers/specs/2026-03-24-flappybird-design.md` — draw order and visual specs

- [ ] **Step 1: Implement painter**

```dart
// lib/flappybird/flappybird_painter.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'flappybird_colors.dart';
import 'flappybird_config.dart';
import 'flappybird_game.dart';
import 'flappybird_models.dart';

class FlappybirdPainter extends CustomPainter {
  final FlappybirdGame game;
  final int paintVersion;

  FlappybirdPainter({required this.game, required this.paintVersion});

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;

    // 1. Sky gradient background
    final skyRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(
      skyRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [FlappybirdColors.skyTop, FlappybirdColors.skyBottom],
        ).createShader(skyRect),
    );

    // 2. Clouds (parallax layer)
    for (final cloud in game.clouds) {
      final cx = cloud.x * h;
      final cy = cloud.y * h;
      final rx = cloud.radius * h;
      final ry = rx * 0.6;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2),
        Paint()..color = FlappybirdColors.cloud,
      );
    }

    // 3. Pipes
    final halfGap = game.config.gapSize / 2;
    const capHeight = 0.02;
    const capExtra = 0.005;

    for (final pipe in game.pipes) {
      final px = pipe.x * h;
      final pw = pipe.width * h;
      final capH = capHeight * h;
      final capW = pw + capExtra * 2 * h;
      final capX = px - capExtra * h;

      // Upper pipe
      final upperBottom = (pipe.gapCenterY - halfGap) * h;
      if (upperBottom > 0) {
        // Pipe body
        canvas.drawRect(
          Rect.fromLTWH(px, 0, pw, upperBottom - capH),
          Paint()
            ..shader = LinearGradient(
              colors: [FlappybirdColors.pipeBodyDark, FlappybirdColors.pipeBody],
            ).createShader(Rect.fromLTWH(px, 0, pw, upperBottom)),
        );
        // Pipe cap
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(capX, upperBottom - capH, capW, capH),
            Radius.circular(0.005 * h),
          ),
          Paint()
            ..shader = LinearGradient(
              colors: [FlappybirdColors.pipeCapDark, FlappybirdColors.pipeCap],
            ).createShader(Rect.fromLTWH(capX, 0, capW, capH)),
        );
      }

      // Lower pipe
      final lowerTop = (pipe.gapCenterY + halfGap) * h;
      final groundTop = (1.0 - game.ground.height) * h;
      if (lowerTop < groundTop) {
        // Pipe cap
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(capX, lowerTop, capW, capH),
            Radius.circular(0.005 * h),
          ),
          Paint()
            ..shader = LinearGradient(
              colors: [FlappybirdColors.pipeCapDark, FlappybirdColors.pipeCap],
            ).createShader(Rect.fromLTWH(capX, lowerTop, capW, capH)),
        );
        // Pipe body
        canvas.drawRect(
          Rect.fromLTWH(px, lowerTop + capH, pw, groundTop - lowerTop - capH),
          Paint()
            ..shader = LinearGradient(
              colors: [FlappybirdColors.pipeBodyDark, FlappybirdColors.pipeBody],
            ).createShader(Rect.fromLTWH(px, lowerTop, pw, groundTop - lowerTop)),
        );
      }
    }

    // 4. Ground (scrolling stripes)
    final groundTop = (1.0 - game.ground.height) * h;
    final groundH = game.ground.height * h;
    // Grass strip
    canvas.drawRect(
      Rect.fromLTWH(0, groundTop, size.width, groundH * 0.3),
      Paint()..color = FlappybirdColors.groundTop,
    );
    // Earth
    canvas.drawRect(
      Rect.fromLTWH(0, groundTop + groundH * 0.3, size.width, groundH * 0.7),
      Paint()..color = FlappybirdColors.groundBottom,
    );
    // Scrolling tick marks on grass
    final tickSpacing = 0.03 * h;
    final offset = (game.ground.offsetX * h) % tickSpacing;
    final tickPaint = Paint()
      ..color = FlappybirdColors.groundBottom.withValues(alpha: 0.3)
      ..strokeWidth = 2;
    for (double tx = offset; tx < size.width; tx += tickSpacing) {
      canvas.drawLine(
        Offset(tx, groundTop),
        Offset(tx, groundTop + groundH * 0.3),
        tickPaint,
      );
    }

    // 5. Bird
    _drawBird(canvas, h);

    // 6. Overlay (ready state)
    if (game.state == GameState.ready) {
      final fontSize = 0.04 * h;
      final tp = TextPainter(
        text: TextSpan(
          text: 'Tap to Start',
          style: TextStyle(
            color: FlappybirdColors.overlayText,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(color: FlappybirdColors.overlayTextShadow, blurRadius: 4),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset((size.width - tp.width) / 2, h * 0.6));
      tp.dispose();
    }
  }

  void _drawBird(Canvas canvas, double h) {
    final bx = game.bird.x * h;
    final by = game.bird.y * h;
    final r = game.bird.radius * h;

    canvas.save();
    canvas.translate(bx, by);
    canvas.rotate(game.bird.rotation);

    // Body (circle)
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()..color = FlappybirdColors.birdBody,
    );

    // Wing (triangle, oscillating)
    final wingOffset = sin(game.bird.wingPhase) * 0.01 * h;
    final wingPath = Path()
      ..moveTo(-r * 0.3, wingOffset)
      ..lineTo(-r * 1.2, wingOffset + r * 0.5)
      ..lineTo(-r * 0.3, wingOffset + r * 0.3)
      ..close();
    canvas.drawPath(wingPath, Paint()..color = FlappybirdColors.birdWing);

    // Eye
    canvas.drawCircle(
      Offset(r * 0.3, -r * 0.2),
      r * 0.25,
      Paint()..color = FlappybirdColors.birdEye,
    );
    canvas.drawCircle(
      Offset(r * 0.4, -r * 0.2),
      r * 0.12,
      Paint()..color = FlappybirdColors.birdPupil,
    );

    // Beak (small triangle)
    final beakPath = Path()
      ..moveTo(r * 0.7, 0)
      ..lineTo(r * 1.2, r * 0.1)
      ..lineTo(r * 0.7, r * 0.25)
      ..close();
    canvas.drawPath(beakPath, Paint()..color = const Color(0xFFE84545));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant FlappybirdPainter old) =>
      paintVersion != old.paintVersion;
}
```

- [ ] **Step 2: Verify build**

Run: `fvm flutter build web --release --base-href "/mini-play/" 2>&1 | tail -5`
Expected: Build succeeds (painter not wired up yet)

- [ ] **Step 3: Commit**

```bash
git add lib/flappybird/flappybird_painter.dart
git commit -m "feat(flappybird): add CustomPainter with full rendering and HUD"
```

---

### Task 6: Game Page (Ticker, Input, Scaffold)

**Files:**
- Create: `lib/flappybird/flappybird_page.dart`

Reference files:
- `lib/breakout/breakout_page.dart` — same Ticker + GameScaffold pattern

- [ ] **Step 1: Implement game page**

```dart
// lib/flappybird/flappybird_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../shared/game_over_data.dart';
import '../shared/game_over_page.dart';
import '../shared/game_scaffold.dart';
import '../shared/score_service.dart';
import 'flappybird_config.dart';
import 'flappybird_game.dart';
import 'flappybird_models.dart';
import 'flappybird_painter.dart';

class FlappybirdPage extends StatefulWidget {
  final FlappybirdMode mode;

  const FlappybirdPage({super.key, required this.mode});

  @override
  State<FlappybirdPage> createState() => _FlappybirdPageState();
}

class _FlappybirdPageState extends State<FlappybirdPage>
    with TickerProviderStateMixin {
  Key _gameKey = UniqueKey();
  late FlappybirdGame _game;
  final ValueNotifier<int> _scoreNotifier = ValueNotifier<int>(0);
  int _bestScore = 0;
  int _paintVersion = 0;
  bool _isPaused = false;
  bool _gameOverHandled = false;
  late Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  String get _modeName {
    switch (widget.mode) {
      case FlappybirdMode.easy:
        return 'Easy';
      case FlappybirdMode.normal:
        return 'Normal';
      case FlappybirdMode.hard:
        return 'Hard';
    }
  }

  bool get _canUpdate =>
      !_isPaused && _game.state != GameState.gameOver;

  @override
  void initState() {
    super.initState();
    _createGame();
    _loadBestScore();
    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  void _createGame() {
    final config = FlappybirdConfig.forMode(widget.mode);
    _game = FlappybirdGame(config: config);
    _isPaused = false;
    _scoreNotifier.value = 0;
    _lastElapsed = Duration.zero;
    _gameOverHandled = false;
  }

  Future<void> _loadBestScore() async {
    _bestScore =
        await ScoreService().getHighScore('flappybird', widget.mode.name);
    if (mounted) setState(() {});
  }

  void _onTick(Duration elapsed) {
    if (_lastElapsed == Duration.zero) {
      _lastElapsed = elapsed;
      return;
    }

    final dtRaw = (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    final dt = dtRaw.clamp(0.0, 0.033);

    if (!_canUpdate) return;

    _game.update(dt);
    _scoreNotifier.value = _game.score;
    _paintVersion++;
    setState(() {});

    // Haptic on pipe pass
    if (_game.pipesPassed > 0 &&
        _game.pipes.any((p) => p.passed && p.x + p.width >= _game.bird.x - 0.01)) {
      // Only trigger on the frame the pipe is first passed
    }

    if (_game.state == GameState.dead && !_gameOverHandled) {
      HapticFeedback.heavyImpact();
    }

    if (_game.state == GameState.gameOver && !_gameOverHandled) {
      _gameOverHandled = true;
      _ticker.stop();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _onGameOver();
      });
    }
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.space:
        case LogicalKeyboardKey.arrowUp:
          if (_canUpdate) _game.jump();
          return KeyEventResult.handled;
        case LogicalKeyboardKey.escape:
          Navigator.maybePop(context);
          return KeyEventResult.handled;
        default:
          return KeyEventResult.ignored;
      }
    }
    return KeyEventResult.ignored;
  }

  void _onTapDown(TapDownDetails details) {
    if (!_canUpdate) return;
    _game.jump();
  }

  void _onPause() => _isPaused = true;
  void _onResume() => _isPaused = false;

  Future<void> _onGameOver() async {
    await ScoreService()
        .saveHighScore('flappybird', widget.mode.name, _game.score);
    final best =
        await ScoreService().getHighScore('flappybird', widget.mode.name);
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameOverPage(
          data: GameOverData(
            gameName: 'flappybird',
            mode: widget.mode.name,
            stats: {
              'Score': '${_game.score}',
              'Best': '$best',
              'Pipes': '${_game.pipesPassed}',
            },
            replayCallback: _replay,
            actions: [
              GameOverAction(
                label: 'Play Again',
                onPressed: _replay,
                isPrimary: true,
              ),
              GameOverAction(
                label: 'Choose Mode',
                onPressed: () {},
              ),
              GameOverAction(
                label: 'Home',
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
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
      title: 'Flappy Bird - $_modeName',
      scoreNotifier: _scoreNotifier,
      bestScore: _bestScore,
      onPause: _onPause,
      onResume: _onResume,
      canPause: () => _game.state == GameState.ready || _game.state == GameState.playing,
      child: Focus(
        autofocus: true,
        onKeyEvent: _onKeyEvent,
        child: Center(
          child: AspectRatio(
            aspectRatio: FlappybirdConfig.aspectRatio,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onTapDown: _onTapDown,
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: FlappybirdPainter(
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

- [ ] **Step 2: Verify build**

Run: `fvm flutter build web --release --base-href "/mini-play/" 2>&1 | tail -5`
Expected: Build succeeds

- [ ] **Step 3: Commit**

```bash
git add lib/flappybird/flappybird_page.dart
git commit -m "feat(flappybird): add game page with Ticker loop, input handling, scaffold"
```

---

### Task 7: Mode Selection Page

**Files:**
- Create: `lib/flappybird/flappybird_mode_page.dart`

Reference: `lib/breakout/breakout_mode_page.dart`

- [ ] **Step 1: Create mode page**

```dart
// lib/flappybird/flappybird_mode_page.dart
import 'package:flutter/material.dart';
import '../shared/game_mode_card.dart';
import 'flappybird_config.dart';

class FlappybirdModePage extends StatelessWidget {
  const FlappybirdModePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Flappy Bird'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GameModeCard(
            title: 'Easy',
            description: 'Slow speed, wide gaps. Great for practice.',
            icon: Icons.sentiment_satisfied,
            accent: const Color(0xFF4ECCA3),
            gameName: 'flappybird',
            scoreKey: 'easy',
            route: '/flappybird/play',
            arguments: FlappybirdMode.easy,
          ),
          GameModeCard(
            title: 'Normal',
            description: 'Standard speed and gaps. The classic experience.',
            icon: Icons.flutter_dash,
            accent: const Color(0xFF3A86FF),
            gameName: 'flappybird',
            scoreKey: 'normal',
            route: '/flappybird/play',
            arguments: FlappybirdMode.normal,
          ),
          GameModeCard(
            title: 'Hard',
            description: 'Fast speed, tight gaps. Only for the brave.',
            icon: Icons.local_fire_department,
            accent: const Color(0xFFE84545),
            gameName: 'flappybird',
            scoreKey: 'hard',
            route: '/flappybird/play',
            arguments: FlappybirdMode.hard,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/flappybird/flappybird_mode_page.dart
git commit -m "feat(flappybird): add mode selection page"
```

---

### Task 8: Wire Up Routing and Game Registry

**Files:**
- Modify: `lib/main.dart` — add routes for `/flappybird` and `/flappybird/play`
- Modify: `lib/home/game_registry.dart` — add Flappy Bird entry as Phase 3

- [ ] **Step 1: Add routes to main.dart**

Add these imports at the top of `lib/main.dart`:

```dart
import 'flappybird/flappybird_config.dart';
import 'flappybird/flappybird_mode_page.dart';
import 'flappybird/flappybird_page.dart';
```

Add these cases before the `default:` case in the `switch (settings.name)` block:

```dart
          case '/flappybird':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const FlappybirdModePage(),
            );
          case '/flappybird/play':
            final mode = settings.arguments as FlappybirdMode? ?? FlappybirdMode.normal;
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => FlappybirdPage(mode: mode),
            );
```

- [ ] **Step 2: Add to game registry**

Add this entry to `lib/home/game_registry.dart` after the Breakout entry (inside the `games` list):

```dart
    GameInfo(
      name: 'Flappy Bird',
      icon: Icons.flutter_dash,
      description: 'Tap to fly through gaps between pipes',
      phase: 3,
      route: '/flappybird',
      implemented: true,
      hasModePage: true,
    ),
```

- [ ] **Step 3: Verify full build**

Run: `fvm flutter build web --release --base-href "/mini-play/" 2>&1 | tail -5`
Expected: Build succeeds with no errors

- [ ] **Step 4: Run all tests**

Run: `fvm flutter test`
Expected: All tests pass (including new flappybird tests)

- [ ] **Step 5: Commit**

```bash
git add lib/main.dart lib/home/game_registry.dart
git commit -m "feat(flappybird): wire up routing and enable in game registry"
```

---

### Task 9: Final Integration and Squash Commit

**Files:** None new — verification only

- [ ] **Step 1: Run the app locally to verify**

Run: `fvm flutter run -d chrome`
Expected: Home page shows Flappy Bird in Phase 3 section. Tap to enter mode page. Select Normal. Game shows sky gradient, clouds, "Tap to Start". Tap to play. Bird flies, pipes scroll, score increases. Hitting pipe or ground triggers death fall and Game Over page.

- [ ] **Step 2: Run all tests one final time**

Run: `fvm flutter test`
Expected: All tests pass

- [ ] **Step 3: Squash into single feature commit**

```bash
git reset --soft HEAD~8
git commit -m "feat: add Flappy Bird game with 3 modes, parallax background, and physics engine"
```

- [ ] **Step 4: Verify clean state**

Run: `git log --oneline -3`
Expected: Single new commit for all Flappy Bird files

---

## Haptic Feedback Note

The haptic feedback for pipe pass (`HapticFeedback.lightImpact()`) should be triggered in `_onTick` when a pipe's `passed` flag changes from false to true. Track this with a `_lastPipesPassed` counter:

```dart
// In _onTick, after _game.update(dt):
if (_game.pipesPassed > _lastPipesPassed) {
  HapticFeedback.lightImpact();
  _lastPipesPassed = _game.pipesPassed;
}
```

Add `int _lastPipesPassed = 0;` as a field in `_FlappybirdPageState`, reset to 0 in `_createGame()`. This belongs in Task 6 (flappybird_page.dart).
