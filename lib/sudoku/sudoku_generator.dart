// lib/sudoku/sudoku_generator.dart
import 'dart:math';
import 'sudoku_cell.dart';

class GeneratorResult {
  final List<List<int>> puzzle;
  final List<List<int>> solution;
  GeneratorResult(this.puzzle, this.solution);
}

class SudokuGenerator {
  static final _random = Random();

  /// Generate a puzzle synchronously.
  static GeneratorResult generate(SudokuDifficulty difficulty) {
    const maxRestarts = 5;
    GeneratorResult? bestResult;

    for (int attempt = 0; attempt < maxRestarts; attempt++) {
      final board = List.generate(9, (_) => List.filled(9, 0));
      if (!_fillBoard(board, 0)) continue;

      final solution = board.map((r) => List<int>.from(r)).toList();
      final puzzle = board.map((r) => List<int>.from(r)).toList();

      final holesCount = _digHoles(puzzle, difficulty.emptyCells);

      if (bestResult == null || holesCount > _countEmpty(bestResult.puzzle)) {
        bestResult = GeneratorResult(puzzle, solution);
      }

      if (holesCount >= difficulty.emptyCells - 3) {
        return bestResult;
      }
    }

    return bestResult!;
  }

  static bool _fillBoard(List<List<int>> board, int pos) {
    if (pos == 81) return true;
    final r = pos ~/ 9, c = pos % 9;
    if (board[r][c] != 0) return _fillBoard(board, pos + 1);

    final digits = [1, 2, 3, 4, 5, 6, 7, 8, 9]..shuffle(_random);
    for (final d in digits) {
      if (_isValid(board, r, c, d)) {
        board[r][c] = d;
        if (_fillBoard(board, pos + 1)) return true;
        board[r][c] = 0;
      }
    }
    return false;
  }

  static int _digHoles(List<List<int>> board, int target) {
    final positions = <int>[for (int i = 0; i < 81; i++) i]..shuffle(_random);
    int removed = 0;

    for (final pos in positions) {
      if (removed >= target) break;
      final r = pos ~/ 9, c = pos % 9;
      if (board[r][c] == 0) continue;

      final backup = board[r][c];
      board[r][c] = 0;

      if (_hasUniqueSolution(board)) {
        removed++;
      } else {
        board[r][c] = backup;
      }
    }

    return removed;
  }

  /// Fast unique-solution check using bitmask constraint solver.
  static bool _hasUniqueSolution(List<List<int>> board) {
    final count = [0];
    // Build bitmask constraints: rowMask[r] has bits set for digits used in row r
    final rowMask = List.filled(9, 0);
    final colMask = List.filled(9, 0);
    final boxMask = List.filled(9, 0);

    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final v = board[r][c];
        if (v != 0) {
          final bit = 1 << v;
          rowMask[r] |= bit;
          colMask[c] |= bit;
          boxMask[(r ~/ 3) * 3 + c ~/ 3] |= bit;
        }
      }
    }

    _solveBitmask(board, rowMask, colMask, boxMask, count, 2);
    return count[0] == 1;
  }

  static void _solveBitmask(
    List<List<int>> board,
    List<int> rowMask,
    List<int> colMask,
    List<int> boxMask,
    List<int> count,
    int limit,
  ) {
    if (count[0] >= limit) return;

    // MRV: find empty cell with fewest candidates
    int bestR = -1, bestC = -1, bestCandidates = 0x3FE; // bits 1-9
    int bestPopCount = 10;

    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (board[r][c] != 0) continue;
        final box = (r ~/ 3) * 3 + c ~/ 3;
        final used = rowMask[r] | colMask[c] | boxMask[box];
        final candidates = 0x3FE & ~used; // bits 1-9 not used
        if (candidates == 0) return; // dead end
        final pop = _popCount(candidates);
        if (pop < bestPopCount) {
          bestR = r;
          bestC = c;
          bestCandidates = candidates;
          bestPopCount = pop;
          if (pop == 1) break;
        }
      }
      if (bestPopCount == 1) break;
    }

    if (bestR == -1) {
      count[0]++;
      return;
    }

    final box = (bestR ~/ 3) * 3 + bestC ~/ 3;
    var bits = bestCandidates;
    while (bits != 0) {
      if (count[0] >= limit) return;
      final bit = bits & (-bits); // lowest set bit
      bits &= bits - 1; // clear lowest bit
      final d = _bitToDigit(bit);

      board[bestR][bestC] = d;
      rowMask[bestR] |= bit;
      colMask[bestC] |= bit;
      boxMask[box] |= bit;

      _solveBitmask(board, rowMask, colMask, boxMask, count, limit);

      board[bestR][bestC] = 0;
      rowMask[bestR] &= ~bit;
      colMask[bestC] &= ~bit;
      boxMask[box] &= ~bit;
    }
  }

  static int _popCount(int x) {
    x = x - ((x >> 1) & 0x55555555);
    x = (x & 0x33333333) + ((x >> 2) & 0x33333333);
    return (((x + (x >> 4)) & 0x0F0F0F0F) * 0x01010101) >> 24;
  }

  static int _bitToDigit(int bit) {
    // bit is a power of 2 (1<<d), return d
    int d = 0;
    while (bit > 1) {
      bit >>= 1;
      d++;
    }
    return d;
  }

  /// Count solutions up to [limit]. Public for testing.
  static int countSolutions(List<List<int>> board, {int limit = 2}) {
    final count = [0];
    final rowMask = List.filled(9, 0);
    final colMask = List.filled(9, 0);
    final boxMask = List.filled(9, 0);

    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final v = board[r][c];
        if (v != 0) {
          final bit = 1 << v;
          rowMask[r] |= bit;
          colMask[c] |= bit;
          boxMask[(r ~/ 3) * 3 + c ~/ 3] |= bit;
        }
      }
    }

    // Check for conflicts: scan for duplicate values in rows/cols/boxes
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final v = board[r][c];
        if (v == 0) continue;
        // Check rest of row
        for (int c2 = c + 1; c2 < 9; c2++) {
          if (board[r][c2] == v) return 0;
        }
        // Check rest of column
        for (int r2 = r + 1; r2 < 9; r2++) {
          if (board[r2][c] == v) return 0;
        }
        // Check rest of box
        final br = (r ~/ 3) * 3, bc = (c ~/ 3) * 3;
        for (int r2 = r; r2 < br + 3; r2++) {
          for (int c2 = (r2 == r ? c + 1 : bc); c2 < bc + 3; c2++) {
            if (board[r2][c2] == v) return 0;
          }
        }
      }
    }

    _solveBitmask(board, rowMask, colMask, boxMask, count, limit);
    return count[0];
  }

  static bool _isValid(List<List<int>> board, int row, int col, int digit) {
    for (int c = 0; c < 9; c++) {
      if (board[row][c] == digit) return false;
    }
    for (int r = 0; r < 9; r++) {
      if (board[r][col] == digit) return false;
    }
    final br = (row ~/ 3) * 3, bc = (col ~/ 3) * 3;
    for (int r = br; r < br + 3; r++) {
      for (int c = bc; c < bc + 3; c++) {
        if (board[r][c] == digit) return false;
      }
    }
    return true;
  }

  static int _countEmpty(List<List<int>> board) {
    int count = 0;
    for (final row in board) {
      for (final v in row) {
        if (v == 0) count++;
      }
    }
    return count;
  }
}
