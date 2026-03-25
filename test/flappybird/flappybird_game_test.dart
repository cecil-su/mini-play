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
      expect(game.bird.y, closeTo(0.35, 0.001));
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
        width: FlappybirdConfig.pipeWidth,
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
