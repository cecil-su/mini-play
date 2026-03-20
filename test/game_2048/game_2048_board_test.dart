import 'package:flutter_test/flutter_test.dart';
import 'package:mini_play/game_2048/game_2048_board.dart';
import 'package:mini_play/game_2048/game_2048_tile.dart';

void main() {
  setUp(() => Tile.resetIdCounter());

  group('GameBoard initialization', () {
    test('starts with 2 tiles on a 4x4 grid', () {
      final board = GameBoard(gridSize: 4);
      expect(board.tiles.length, 2);
      expect(board.score, 0);
      expect(board.moveCount, 0);
    });

    test('starts with 2 tiles on a 3x3 grid', () {
      final board = GameBoard(gridSize: 3);
      expect(board.tiles.length, 2);
    });
  });

  group('Slide mechanics', () {
    test('slide left merges adjacent equal tiles', () {
      final board = GameBoard.fromValues(4, [
        [2, 2, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      final moved = board.slide(Direction.left);
      expect(moved, true);
      final grid = board.toGrid();
      expect(grid[0][0], 4);
      expect(board.score, 4);
    });

    test('slide left: [2,2,2,2] produces [4,4,0,0]', () {
      final board = GameBoard.fromValues(4, [
        [2, 2, 2, 2],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      board.slide(Direction.left);
      final grid = board.toGrid();
      expect(grid[0][0], 4);
      expect(grid[0][1], 4);
      expect(board.score, 8);
    });

    test('slide right merges toward right edge', () {
      final board = GameBoard.fromValues(4, [
        [0, 0, 2, 2],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      board.slide(Direction.right);
      final grid = board.toGrid();
      expect(grid[0][3], 4);
    });

    test('slide down merges downward', () {
      final board = GameBoard.fromValues(4, [
        [2, 0, 0, 0],
        [2, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      board.slide(Direction.down);
      final grid = board.toGrid();
      expect(grid[3][0], 4);
    });

    test('slide up merges upward', () {
      final board = GameBoard.fromValues(4, [
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [2, 0, 0, 0],
        [2, 0, 0, 0],
      ]);
      board.slide(Direction.up);
      final grid = board.toGrid();
      expect(grid[0][0], 4);
    });

    test('no-op slide returns false', () {
      final board = GameBoard.fromValues(4, [
        [2, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      final moved = board.slide(Direction.left);
      expect(moved, false);
    });

    test('slide spawns new tile when board changes', () {
      final board = GameBoard.fromValues(4, [
        [0, 0, 2, 2],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      final tileCountBefore = board.tiles.length;
      board.slide(Direction.left);
      expect(board.tiles.length, greaterThanOrEqualTo(tileCountBefore));
    });

    test('moveCount increments on valid move', () {
      final board = GameBoard.fromValues(4, [
        [0, 0, 2, 2],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      board.slide(Direction.left);
      expect(board.moveCount, 1);
    });
  });

  group('Game over detection', () {
    test('game is not over when empty cells exist', () {
      final board = GameBoard.fromValues(4, [
        [2, 4, 2, 4],
        [4, 2, 4, 2],
        [2, 4, 2, 4],
        [4, 2, 4, 0],
      ]);
      expect(board.isGameOver, false);
    });

    test('game is over when no moves possible', () {
      final board = GameBoard.fromValues(4, [
        [2, 4, 2, 4],
        [4, 2, 4, 2],
        [2, 4, 2, 4],
        [4, 2, 4, 2],
      ]);
      expect(board.isGameOver, true);
    });

    test('game is not over when adjacent equal cells exist', () {
      final board = GameBoard.fromValues(4, [
        [2, 4, 2, 4],
        [4, 2, 4, 2],
        [2, 4, 2, 4],
        [4, 2, 4, 4],
      ]);
      expect(board.isGameOver, false);
    });
  });

  group('Undo system', () {
    test('undo restores previous state', () {
      final board = GameBoard.fromValues(4, [
        [0, 0, 2, 2],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      board.slide(Direction.left);
      expect(board.score, 4);
      final undone = board.undo();
      expect(undone, true);
      expect(board.score, 0);
      final grid = board.toGrid();
      expect(grid[0][2], 2);
      expect(grid[0][3], 2);
    });

    test('undo restores state after slide without merge', () {
      final board = GameBoard.fromValues(4, [
        [0, 0, 0, 2],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      board.slide(Direction.left);
      final grid1 = board.toGrid();
      expect(grid1[0][0], 2);
      board.undo();
      final grid2 = board.toGrid();
      expect(grid2[0][3], 2); // must restore to original col
      expect(grid2[0][0], 0);
    });

    test('undo limited to 3 times', () {
      final board = GameBoard.fromValues(4, [
        [2, 2, 4, 4],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      expect(board.undoRemaining, 3);
      board.slide(Direction.left);
      board.slide(Direction.right);
      board.slide(Direction.left);

      expect(board.undo(), true);
      expect(board.undoRemaining, 2);
      expect(board.undo(), true);
      expect(board.undoRemaining, 1);
      expect(board.undo(), true);
      expect(board.undoRemaining, 0);
      expect(board.undo(), false);
    });
  });

  group('2048 detection', () {
    test('hasReached2048 is true when a tile reaches 2048', () {
      final board = GameBoard.fromValues(4, [
        [1024, 1024, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      board.slide(Direction.left);
      expect(board.hasReached2048, true);
    });
  });

  group('maxTileValue', () {
    test('returns the highest tile value', () {
      final board = GameBoard.fromValues(4, [
        [2, 4, 8, 16],
        [32, 64, 128, 256],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      expect(board.maxTileValue, 256);
    });
  });
}
