// lib/minesweeper/minesweeper_board.dart
import 'dart:collection';
import 'dart:math';
import 'minesweeper_cell.dart';

class MinesweeperBoard {
  final int rows;
  final int cols;
  final int totalMines;
  final Random _random = Random();

  late List<List<MinesweeperCell>> grid;
  int flagCount = 0;
  bool isFirstMove = true;
  MinesweeperGameState gameState = MinesweeperGameState.playing;

  MinesweeperBoard({
    required this.rows,
    required this.cols,
    required this.totalMines,
  }) {
    grid = List.generate(
      rows,
      (_) => List.generate(cols, (_) => MinesweeperCell()),
    );
  }

  /// Test constructor: create board from a 2D int grid.
  /// -1 = mine, any other value = non-mine cell.
  /// Non-negative values in the input are ignored — adjacentMines is
  /// auto-computed from mine positions. The values (0, 1, 2, ...) are
  /// for human readability only.
  /// Skips first-move mine placement.
  MinesweeperBoard.fromGrid(List<List<int>> values)
      : rows = values.length,
        cols = values[0].length,
        totalMines = values.expand((r) => r).where((v) => v == -1).length {
    isFirstMove = false;
    grid = List.generate(rows, (r) {
      return List.generate(cols, (c) {
        return MinesweeperCell(isMine: values[r][c] == -1);
      });
    });
    _computeAdjacentMines();
  }

  int get remainingMines => totalMines - flagCount;

  /// Reveal a cell. Triggers mine placement on first move.
  void reveal(int row, int col) {
    if (gameState != MinesweeperGameState.playing) return;
    final cell = grid[row][col];
    if (cell.isFlagged || cell.isRevealed) return;

    if (isFirstMove) {
      _placeMines(row, col);
      isFirstMove = false;
    }

    if (cell.isMine) {
      _triggerLoss();
      return;
    }

    cell.isRevealed = true;

    if (cell.adjacentMines == 0) {
      _floodFill(row, col);
    }

    _checkWin();
  }

  /// Chord reveal: if a revealed number cell has exactly enough adjacent flags,
  /// reveal all unflagged, unrevealed neighbors.
  void chordReveal(int row, int col) {
    if (gameState != MinesweeperGameState.playing) return;
    final cell = grid[row][col];
    if (!cell.isRevealed || cell.adjacentMines == 0) return;

    int adjacentFlags = 0;
    for (final (nr, nc) in _neighbors(row, col)) {
      if (grid[nr][nc].isFlagged) adjacentFlags++;
    }

    if (adjacentFlags != cell.adjacentMines) return;

    for (final (nr, nc) in _neighbors(row, col)) {
      final neighbor = grid[nr][nc];
      if (!neighbor.isRevealed && !neighbor.isFlagged) {
        if (neighbor.isMine) {
          _triggerLoss();
          return;
        }
        neighbor.isRevealed = true;
        if (neighbor.adjacentMines == 0) {
          _floodFill(nr, nc);
        }
      }
    }

    _checkWin();
  }

  /// Toggle flag on an unrevealed cell.
  void toggleFlag(int row, int col) {
    if (gameState != MinesweeperGameState.playing) return;
    final cell = grid[row][col];
    if (cell.isRevealed) return;

    cell.isFlagged = !cell.isFlagged;
    flagCount += cell.isFlagged ? 1 : -1;
  }

  /// Place mines randomly, avoiding the safe zone around (safeRow, safeCol).
  void _placeMines(int safeRow, int safeCol) {
    final candidates = <(int, int)>[];
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        // Exclude the safe zone (3x3 area centered on click, clamped to bounds)
        if ((r - safeRow).abs() <= 1 && (c - safeCol).abs() <= 1) continue;
        candidates.add((r, c));
      }
    }

    candidates.shuffle(_random);
    for (int i = 0; i < totalMines && i < candidates.length; i++) {
      final (r, c) = candidates[i];
      grid[r][c].isMine = true;
    }

    _computeAdjacentMines();
  }

  /// Compute adjacentMines for every cell.
  void _computeAdjacentMines() {
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (grid[r][c].isMine) continue;
        int count = 0;
        for (final (nr, nc) in _neighbors(r, c)) {
          if (grid[nr][nc].isMine) count++;
        }
        grid[r][c].adjacentMines = count;
      }
    }
  }

  /// BFS flood fill from an empty (adjacentMines == 0) cell.
  void _floodFill(int startRow, int startCol) {
    final queue = Queue<(int, int)>();
    queue.add((startRow, startCol));

    while (queue.isNotEmpty) {
      final (r, c) = queue.removeFirst();
      for (final (nr, nc) in _neighbors(r, c)) {
        final neighbor = grid[nr][nc];
        if (neighbor.isRevealed || neighbor.isFlagged || neighbor.isMine) continue;
        neighbor.isRevealed = true;
        if (neighbor.adjacentMines == 0) {
          queue.add((nr, nc));
        }
      }
    }
  }

  /// Trigger loss: reveal all mines, mark wrong flags.
  void _triggerLoss() {
    gameState = MinesweeperGameState.lost;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final cell = grid[r][c];
        if (cell.isMine) {
          cell.isRevealed = true;
        } else if (cell.isFlagged) {
          cell.isWrongFlag = true;
        }
      }
    }
  }

  /// Check if all non-mine cells are revealed.
  void _checkWin() {
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final cell = grid[r][c];
        if (!cell.isMine && !cell.isRevealed) return;
      }
    }
    gameState = MinesweeperGameState.won;
  }

  /// Get valid neighbor coordinates.
  List<(int, int)> _neighbors(int row, int col) {
    final result = <(int, int)>[];
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final nr = row + dr;
        final nc = col + dc;
        if (nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
          result.add((nr, nc));
        }
      }
    }
    return result;
  }
}
