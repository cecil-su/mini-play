import 'package:flutter_test/flutter_test.dart';
import 'package:mini_play/game_of_life/game_of_life_challenges.dart';
import 'package:mini_play/game_of_life/game_of_life_challenge_runner.dart';
import 'package:mini_play/game_of_life/game_of_life_game.dart';

void main() {
  group('ChallengeRunner', () {
    test('level 1: placing block cells achieves still life goal', () {
      final game = GameOfLifeGame();
      final runner = ChallengeRunner(
        level: ChallengeLevels.all[0],
        game: game,
      );

      // Place a block
      runner.toggleCell(10, 10);
      runner.toggleCell(11, 10);
      runner.toggleCell(10, 11);
      runner.toggleCell(11, 11);
      expect(runner.userCellCount, 4);

      runner.start();
      expect(runner.state, ChallengeState.running);

      // Run enough generations for detection
      for (int i = 0; i < 5; i++) {
        runner.tick();
      }

      expect(runner.state, ChallengeState.success);
      expect(runner.stars, greaterThan(0));
    });

    test('level 2: placing blinker cells achieves oscillator goal', () {
      final game = GameOfLifeGame();
      final runner = ChallengeRunner(
        level: ChallengeLevels.all[1],
        game: game,
      );

      // Place a blinker
      runner.toggleCell(10, 10);
      runner.toggleCell(11, 10);
      runner.toggleCell(12, 10);
      expect(runner.userCellCount, 3);

      runner.start();

      for (int i = 0; i < 10; i++) {
        runner.tick();
      }

      expect(runner.state, ChallengeState.success);
      expect(runner.stars, 3); // 3 cells = 3 stars
    });

    test('level 3: placing glider cells achieves spaceship goal', () {
      final game = GameOfLifeGame();
      final runner = ChallengeRunner(
        level: ChallengeLevels.all[2],
        game: game,
      );

      // Place a glider
      runner.toggleCell(11, 10);
      runner.toggleCell(12, 11);
      runner.toggleCell(10, 12);
      runner.toggleCell(11, 12);
      runner.toggleCell(12, 12);
      expect(runner.userCellCount, 5);

      runner.start();

      for (int i = 0; i < 20; i++) {
        runner.tick();
      }

      expect(runner.state, ChallengeState.success);
      expect(runner.stars, 3); // 5 cells = 3 stars
    });

    test('level 5: pattern survives beyond 10 generations', () {
      final game = GameOfLifeGame();
      final runner = ChallengeRunner(
        level: ChallengeLevels.all[4],
        game: game,
      );

      // Place a block (survives forever)
      runner.toggleCell(10, 10);
      runner.toggleCell(11, 10);
      runner.toggleCell(10, 11);
      runner.toggleCell(11, 11);

      runner.start();

      for (int i = 0; i < 15; i++) {
        runner.tick();
        if (runner.isFinished) break;
      }

      expect(runner.state, ChallengeState.success);
    });

    test('timeout triggers failed state when maxGenerations exceeded', () {
      final game = GameOfLifeGame();
      final runner = ChallengeRunner(
        level: ChallengeLevels.all[0], // Still life goal, max 50 gens
        game: game,
      );

      // Place unstable pattern (R-pentomino) that won't be still life
      runner.toggleCell(11, 10);
      runner.toggleCell(12, 10);
      runner.toggleCell(10, 11);
      runner.toggleCell(11, 11);
      runner.toggleCell(11, 12);

      runner.start();

      for (int i = 0; i < 60; i++) {
        runner.tick();
        if (runner.isFinished) break;
      }

      expect(runner.state, ChallengeState.failed);
      expect(runner.failReason, isNotNull);
    });

    test('star calculation: fewer cells = more stars', () {
      final level = ChallengeLevels.all[0]; // starThresholds: [4, 5, 8]
      expect(level.calcStars(4), 3);
      expect(level.calcStars(5), 2);
      expect(level.calcStars(8), 1);
      expect(level.calcStars(9), 0);
    });

    test('editing state: can add/remove cells on non-locked positions', () {
      final game = GameOfLifeGame();
      final runner = ChallengeRunner(
        level: ChallengeLevels.all[3], // Level 4 has locked cells at (5,5) (6,5)
        game: game,
      );

      // Can edit non-locked position
      expect(runner.toggleCell(7, 7), true);
      expect(runner.userCellCount, 1);

      // Can remove it
      expect(runner.toggleCell(7, 7), true);
      expect(runner.userCellCount, 0);
    });

    test('editing state: cannot modify locked cells', () {
      final game = GameOfLifeGame();
      final runner = ChallengeRunner(
        level: ChallengeLevels.all[3], // Level 4 has locked cells
        game: game,
      );

      // Cannot toggle locked cell
      expect(runner.toggleCell(5, 5), false);
      expect(runner.userCellCount, 0);
    });

    test('reset restores initial state', () {
      final game = GameOfLifeGame();
      final runner = ChallengeRunner(
        level: ChallengeLevels.all[3],
        game: game,
      );

      runner.toggleCell(7, 7);
      runner.start();
      runner.tick();

      runner.reset();
      expect(runner.state, ChallengeState.editing);
      expect(runner.userCellCount, 0);
      expect(game.generation, 0);
    });
  });
}
