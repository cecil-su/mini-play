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

  // Dead state timer
  double _deadTimer = 0;

  FlappybirdGame({required this.config}) {
    bird = Bird(x: FlappybirdConfig.birdX, y: 0.35);
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
    bird.wingPhase += 1.0; // flap on jump
  }

  void _spawnFirstPipe() {
    pipes.add(_createPipe(FlappybirdConfig.worldWidth + 0.4));
  }

  Pipe _createPipe(double x) {
    final minGap = config.gapMinY;
    final maxGap = config.gapMaxY;
    final gapCenterY = minGap + _rng.nextDouble() * (maxGap - minGap);
    // Clamp to ensure min pipe visibility (0.03)
    final halfGap = config.gapSize / 2;
    final clampedY = gapCenterY.clamp(halfGap + 0.03, 1.0 - FlappybirdConfig.groundHeight - halfGap - 0.03);
    return Pipe(x: x, gapCenterY: clampedY, width: FlappybirdConfig.pipeWidth);
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
    bird.y = 0.35 + sin(_bobPhase) * 0.02;
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

    // Scroll ground (modulo to prevent float overflow)
    ground.offsetX -= config.pipeSpeed * dt;
    if (ground.offsetX < -1.0) ground.offsetX += 1.0;

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
    bird.velocity = bird.velocity.clamp(0, config.maxVelocity);
    _deadTimer = 0;
  }

  void _updateDead(double dt) {
    // Bird falls with gravity, rotation locked at 90 degrees
    _deadTimer += dt;
    bird.velocity += config.gravity * dt;
    bird.velocity = bird.velocity.clamp(-config.maxVelocity, config.maxVelocity);
    bird.y += bird.velocity * dt;
    bird.rotation = pi / 2;

    if (bird.y + bird.radius >= 1.0 - ground.height || _deadTimer >= 1.0) {
      bird.y = (1.0 - ground.height - bird.radius).clamp(0, 1.0);
      state = GameState.gameOver;
    }
  }
}
