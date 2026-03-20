// test/minesweeper/minesweeper_board_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_play/minesweeper/minesweeper_board.dart';
import 'package:mini_play/minesweeper/minesweeper_cell.dart';

void main() {
  group('MinesweeperBoard initialization', () {
    test('creates grid with correct dimensions', () {
      final board = MinesweeperBoard(rows: 9, cols: 9, totalMines: 10);
      expect(board.grid.length, 9);
      expect(board.grid[0].length, 9);
    });

    test('starts with no mines placed', () {
      final board = MinesweeperBoard(rows: 9, cols: 9, totalMines: 10);
      final mineCount = board.grid.expand((row) => row).where((c) => c.isMine).length;
      expect(mineCount, 0);
      expect(board.isFirstMove, true);
    });

    test('starts in playing state', () {
      final board = MinesweeperBoard(rows: 9, cols: 9, totalMines: 10);
      expect(board.gameState, MinesweeperGameState.playing);
    });
  });

  group('Mine placement', () {
    test('places correct number of mines after first reveal', () {
      final board = MinesweeperBoard(rows: 9, cols: 9, totalMines: 10);
      board.reveal(4, 4);
      final mineCount = board.grid.expand((row) => row).where((c) => c.isMine).length;
      expect(mineCount, 10);
      expect(board.isFirstMove, false);
    });

    test('first click and neighbors are safe', () {
      final board = MinesweeperBoard(rows: 9, cols: 9, totalMines: 10);
      board.reveal(4, 4);
      // Check 3x3 area around (4,4) is mine-free
      for (int dr = -1; dr <= 1; dr++) {
        for (int dc = -1; dc <= 1; dc++) {
          expect(board.grid[4 + dr][4 + dc].isMine, false,
              reason: 'Cell (${4 + dr}, ${4 + dc}) should be safe');
        }
      }
    });

    test('corner click has smaller safe zone', () {
      final board = MinesweeperBoard(rows: 9, cols: 9, totalMines: 10);
      board.reveal(0, 0);
      // Corner: only 4 cells in safe zone
      expect(board.grid[0][0].isMine, false);
      expect(board.grid[0][1].isMine, false);
      expect(board.grid[1][0].isMine, false);
      expect(board.grid[1][1].isMine, false);
    });
  });

  group('Reveal logic', () {
    test('reveals a number cell', () {
      final board = MinesweeperBoard(rows: 9, cols: 9, totalMines: 10);
      board.reveal(0, 0); // triggers mine placement
      // After first reveal, the clicked cell should be revealed
      expect(board.grid[0][0].isRevealed, true);
    });

    test('flood fill reveals connected empty cells', () {
      final board = MinesweeperBoard.fromGrid([
        [0, 0, 1, -1],
        [0, 0, 1, 1],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      board.reveal(3, 0);
      // All 0-cells and their number-cell borders should be revealed
      // Row 3: all empty, row 2: all empty, row 1: [0,0] empty
      // The flood fill should reveal everything except the mine and its immediate numbers
      expect(board.grid[3][0].isRevealed, true);
      expect(board.grid[2][0].isRevealed, true);
      expect(board.grid[0][0].isRevealed, true);
      expect(board.grid[0][2].isRevealed, true); // number 1, boundary of flood
      expect(board.grid[0][3].isRevealed, false); // mine, not revealed
    });

    test('revealing a mine triggers loss', () {
      final board = MinesweeperBoard.fromGrid([
        [-1, 1, 0],
        [1, 1, 0],
        [0, 0, 0],
      ]);
      board.reveal(0, 0);
      expect(board.gameState, MinesweeperGameState.lost);
    });

    test('loss reveals all mines', () {
      final board = MinesweeperBoard.fromGrid([
        [-1, 1, 0],
        [1, 1, 0],
        [0, 0, -1],
      ]);
      board.reveal(0, 0);
      expect(board.grid[0][0].isRevealed, true); // detonated mine
      expect(board.grid[2][2].isRevealed, true); // other mine revealed
    });

    test('loss marks wrong flags', () {
      final board = MinesweeperBoard.fromGrid([
        [-1, 1, 0],
        [1, 1, 0],
        [0, 0, 0],
      ]);
      board.toggleFlag(1, 1); // flag a non-mine cell
      board.reveal(0, 0); // trigger loss
      expect(board.grid[1][1].isWrongFlag, true);
    });

    test('ignores reveal on flagged cell', () {
      final board = MinesweeperBoard.fromGrid([
        [0, 1, -1],
        [0, 1, 1],
        [0, 0, 0],
      ]);
      board.toggleFlag(0, 2); // flag the mine
      board.reveal(0, 2); // should be ignored
      expect(board.gameState, MinesweeperGameState.playing);
    });

    test('ignores reveal on already revealed cell', () {
      final board = MinesweeperBoard.fromGrid([
        [0, 1, -1],
        [0, 1, 1],
        [0, 0, 0],
      ]);
      board.reveal(2, 0); // reveals via flood fill
      final revealedBefore = board.grid.expand((r) => r).where((c) => c.isRevealed).length;
      board.reveal(2, 0); // reveal again — no-op
      final revealedAfter = board.grid.expand((r) => r).where((c) => c.isRevealed).length;
      expect(revealedAfter, revealedBefore);
    });
  });

  group('Win condition', () {
    test('wins when all non-mine cells are revealed', () {
      final board = MinesweeperBoard.fromGrid([
        [0, 1, -1],
        [0, 1, 1],
        [0, 0, 0],
      ]);
      // Reveal all non-mine cells
      board.reveal(0, 0); // flood fill reveals most cells
      // Check which cells are not yet revealed
      for (int r = 0; r < 3; r++) {
        for (int c = 0; c < 3; c++) {
          if (!board.grid[r][c].isMine && !board.grid[r][c].isRevealed) {
            board.reveal(r, c);
          }
        }
      }
      expect(board.gameState, MinesweeperGameState.won);
    });
  });

  group('Flag logic', () {
    test('toggleFlag places and removes flag', () {
      final board = MinesweeperBoard(rows: 9, cols: 9, totalMines: 10);
      board.toggleFlag(0, 0);
      expect(board.grid[0][0].isFlagged, true);
      expect(board.flagCount, 1);

      board.toggleFlag(0, 0);
      expect(board.grid[0][0].isFlagged, false);
      expect(board.flagCount, 0);
    });

    test('cannot flag revealed cell', () {
      final board = MinesweeperBoard.fromGrid([
        [0, 1, -1],
        [0, 1, 1],
        [0, 0, 0],
      ]);
      board.reveal(2, 0);
      board.toggleFlag(2, 0); // should be ignored
      expect(board.grid[2][0].isFlagged, false);
    });
  });

  group('Chord reveal', () {
    test('chord reveals unflagged neighbors when flags match count', () {
      final board = MinesweeperBoard.fromGrid([
        [-1, 1, 0],
        [1, 1, 0],
        [0, 0, 0],
      ]);
      board.reveal(1, 1); // reveal the "1" cell
      board.toggleFlag(0, 0); // flag the mine
      board.chordReveal(1, 1); // should reveal all unflagged neighbors
      expect(board.grid[0][1].isRevealed, true);
      expect(board.grid[1][0].isRevealed, true);
    });

    test('chord does nothing when flags dont match count', () {
      final board = MinesweeperBoard.fromGrid([
        [-1, 1, 0],
        [1, 1, 0],
        [0, 0, 0],
      ]);
      board.reveal(1, 1);
      // No flags placed, adjacentMines is 1
      board.chordReveal(1, 1); // should do nothing
      expect(board.grid[0][1].isRevealed, false);
    });

    test('chord on wrong flag triggers loss', () {
      final board = MinesweeperBoard.fromGrid([
        [-1, 2, -1],
        [1, 2, 1],
        [0, 0, 0],
      ]);
      board.reveal(1, 0); // reveal "1"
      board.toggleFlag(0, 1); // flag a non-mine cell (wrong!)
      board.chordReveal(1, 0); // adjacentFlags(1) == adjacentMines(1), reveals (0,0) which is a mine
      expect(board.gameState, MinesweeperGameState.lost);
    });

    test('chord ignores unrevealed cells', () {
      final board = MinesweeperBoard.fromGrid([
        [-1, 1, 0],
        [1, 1, 0],
        [0, 0, 0],
      ]);
      board.chordReveal(1, 1); // cell not revealed — should do nothing
      expect(board.grid[0][1].isRevealed, false);
    });
  });

  group('Remaining mines', () {
    test('remainingMines is totalMines minus flagCount', () {
      final board = MinesweeperBoard(rows: 9, cols: 9, totalMines: 10);
      expect(board.remainingMines, 10);
      board.toggleFlag(0, 0);
      expect(board.remainingMines, 9);
      board.toggleFlag(0, 1);
      expect(board.remainingMines, 8);
    });
  });
}
