import 'package:flutter_test/flutter_test.dart';
import 'package:mini_play/game_of_life/game_of_life_game.dart';

void main() {
  late GameOfLifeGame game;

  setUp(() {
    game = GameOfLifeGame();
  });

  group('evolve', () {
    test('empty grid stays empty', () {
      game.evolve();
      expect(game.aliveCellCount, 0);
      expect(game.generation, 1);
    });

    test('block (2x2) is still life - no change after evolve', () {
      game.setCell(10, 10, 1);
      game.setCell(11, 10, 1);
      game.setCell(10, 11, 1);
      game.setCell(11, 11, 1);
      expect(game.aliveCellCount, 4);

      game.evolve();
      expect(game.aliveCellCount, 4);
      expect(game.cellAt(10, 10), 1);
      expect(game.cellAt(11, 10), 1);
      expect(game.cellAt(10, 11), 1);
      expect(game.cellAt(11, 11), 1);
    });

    test('blinker oscillates with period 2', () {
      // Horizontal blinker
      game.setCell(10, 10, 1);
      game.setCell(11, 10, 1);
      game.setCell(12, 10, 1);

      game.evolve();
      // Should become vertical
      expect(game.cellAt(11, 9), 1);
      expect(game.cellAt(11, 10), 1);
      expect(game.cellAt(11, 11), 1);
      expect(game.cellAt(10, 10), 0);
      expect(game.cellAt(12, 10), 0);
      expect(game.aliveCellCount, 3);

      game.evolve();
      // Should return to horizontal
      expect(game.cellAt(10, 10), 1);
      expect(game.cellAt(11, 10), 1);
      expect(game.cellAt(12, 10), 1);
      expect(game.aliveCellCount, 3);
    });

    test('glider moves diagonally after 4 generations', () {
      // Standard glider at (10,10)
      game.setCell(11, 10, 1);
      game.setCell(12, 11, 1);
      game.setCell(10, 12, 1);
      game.setCell(11, 12, 1);
      game.setCell(12, 12, 1);

      for (int i = 0; i < 4; i++) {
        game.evolve();
      }

      // Should have moved (+1, +1) diagonally
      expect(game.aliveCellCount, 5);
      expect(game.cellAt(12, 11), 1);
      expect(game.cellAt(13, 12), 1);
      expect(game.cellAt(11, 13), 1);
      expect(game.cellAt(12, 13), 1);
      expect(game.cellAt(13, 13), 1);
    });

    test('single cell dies (underpopulation)', () {
      game.setCell(50, 50, 1);
      game.evolve();
      expect(game.cellAt(50, 50), 0);
      expect(game.aliveCellCount, 0);
    });

    test('newBornCells tracks cells born this generation', () {
      // Blinker: when it oscillates, two new cells are born
      game.setCell(10, 10, 1);
      game.setCell(11, 10, 1);
      game.setCell(12, 10, 1);

      game.evolve();
      // (11,9) and (11,11) are new, (11,10) survived
      expect(game.newBornCells.contains((11, 9)), true);
      expect(game.newBornCells.contains((11, 11)), true);
      expect(game.newBornCells.contains((11, 10)), false); // survived, not born
    });
  });

  group('toroidal boundary', () {
    test('glider wraps around right edge to left', () {
      // Place glider near right edge
      final x = GameOfLifeGame.gridWidth - 2;
      game.setCell(x, 10, 1);
      game.setCell(x + 1, 11, 1); // wraps
      game.setCell(x - 1, 12, 1);
      game.setCell(x, 12, 1);
      game.setCell(x + 1, 12, 1); // wraps

      // Run 4 generations
      for (int i = 0; i < 4; i++) {
        game.evolve();
      }

      // Glider should have wrapped around and still be alive
      expect(game.aliveCellCount, 5);
    });

    test('glider wraps around bottom edge to top', () {
      final y = GameOfLifeGame.gridHeight - 2;
      game.setCell(10, y - 1, 1);
      game.setCell(11, y, 1);
      game.setCell(9, y + 1, 1); // wraps
      game.setCell(10, y + 1, 1); // wraps
      game.setCell(11, y + 1, 1); // wraps

      for (int i = 0; i < 4; i++) {
        game.evolve();
      }

      expect(game.aliveCellCount, 5);
    });
  });

  group('detection', () {
    test('isStillLife returns true for block after evolve', () {
      game.setCell(10, 10, 1);
      game.setCell(11, 10, 1);
      game.setCell(10, 11, 1);
      game.setCell(11, 11, 1);

      // Need at least one evolve to have history
      game.evolve();
      game.evolve();

      expect(game.isStillLife(), true);
    });

    test('isOscillator returns true for blinker after 2+ generations', () {
      game.setCell(10, 10, 1);
      game.setCell(11, 10, 1);
      game.setCell(12, 10, 1);

      // Need enough history to detect period
      for (int i = 0; i < 4; i++) {
        game.evolve();
      }

      expect(game.isOscillator(), true);
    });

    test('isSpaceship returns true for glider after 4+ generations', () {
      game.setCell(11, 10, 1);
      game.setCell(12, 11, 1);
      game.setCell(10, 12, 1);
      game.setCell(11, 12, 1);
      game.setCell(12, 12, 1);

      for (int i = 0; i < 8; i++) {
        game.evolve();
      }

      expect(game.isSpaceship(), true);
    });

    test('detectPeriod returns 2 for blinker', () {
      game.setCell(10, 10, 1);
      game.setCell(11, 10, 1);
      game.setCell(12, 10, 1);

      for (int i = 0; i < 4; i++) {
        game.evolve();
      }

      expect(game.detectPeriod(), 2);
    });

    test('detectPeriod returns 4 for glider', () {
      game.setCell(11, 10, 1);
      game.setCell(12, 11, 1);
      game.setCell(10, 12, 1);
      game.setCell(11, 12, 1);
      game.setCell(12, 12, 1);

      for (int i = 0; i < 8; i++) {
        game.evolve();
      }

      expect(game.detectPeriod(), 4);
    });

    test('detectPeriod returns 0 for unstable pattern', () {
      // R-pentomino is chaotic for ~1000 generations
      game.setCell(11, 10, 1);
      game.setCell(12, 10, 1);
      game.setCell(10, 11, 1);
      game.setCell(11, 11, 1);
      game.setCell(11, 12, 1);

      for (int i = 0; i < 20; i++) {
        game.evolve();
      }

      expect(game.detectPeriod(), 0);
    });
  });

  group('hash', () {
    test('same state produces same hash', () {
      game.setCell(10, 10, 1);
      game.setCell(11, 10, 1);
      game.setCell(12, 10, 1);
      final hash1 = game.computeStateHash();

      final game2 = GameOfLifeGame();
      game2.setCell(10, 10, 1);
      game2.setCell(11, 10, 1);
      game2.setCell(12, 10, 1);
      final hash2 = game2.computeStateHash();

      expect(hash1, hash2);
    });

    test('different states produce different hashes', () {
      game.setCell(10, 10, 1);
      game.setCell(11, 10, 1);
      final hash1 = game.computeStateHash();

      final game2 = GameOfLifeGame();
      game2.setCell(10, 10, 1);
      game2.setCell(11, 11, 1);
      final hash2 = game2.computeStateHash();

      expect(hash1, isNot(hash2));
    });

    test('translated pattern produces same normalized hash', () {
      // Pattern at (10, 10)
      game.setCell(10, 10, 1);
      game.setCell(11, 10, 1);
      game.setCell(12, 10, 1);
      final hash1 = game.computeStateHash();

      // Same pattern at (50, 50)
      final game2 = GameOfLifeGame();
      game2.setCell(50, 50, 1);
      game2.setCell(51, 50, 1);
      game2.setCell(52, 50, 1);
      final hash2 = game2.computeStateHash();

      expect(hash1, hash2);
    });
  });

  group('aliveRatio', () {
    test('returns 0 for empty grid', () {
      expect(game.aliveRatio, 0);
    });

    test('returns correct ratio after setting cells', () {
      game.setCell(0, 0, 1);
      game.setCell(1, 0, 1);
      expect(game.aliveRatio, 2 / GameOfLifeGame.gridSize);
    });
  });

  group('toggleCell', () {
    test('toggles cell on and off', () {
      game.toggleCell(5, 5);
      expect(game.cellAt(5, 5), 1);
      expect(game.aliveCellCount, 1);

      game.toggleCell(5, 5);
      expect(game.cellAt(5, 5), 0);
      expect(game.aliveCellCount, 0);
    });
  });

  group('clear', () {
    test('resets all state', () {
      game.setCell(10, 10, 1);
      game.evolve();
      game.clear();

      expect(game.aliveCellCount, 0);
      expect(game.generation, 0);
      expect(game.isEmpty, true);
    });
  });
}
