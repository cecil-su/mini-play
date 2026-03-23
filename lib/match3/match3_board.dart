// lib/match3/match3_board.dart
import 'dart:math';

import 'match3_gem.dart';

class Match3Board {
  static const int rows = 8;
  static const int cols = 8;
  static final int gemTypeCount = GemType.values.length;

  final Random _random = Random();
  int _nextId = 0;

  /// The grid: grid[row][col], row 0 is the top.
  late List<List<Gem?>> grid;

  Match3Board() {
    grid = List.generate(rows, (_) => List.filled(cols, null));
    _fillInitialBoard();
  }

  int _genId() => _nextId++;

  GemType _randomType() => GemType.values[_random.nextInt(gemTypeCount)];

  /// Fill the board ensuring no initial matches.
  void _fillInitialBoard() {
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        GemType type;
        do {
          type = _randomType();
        } while (_wouldMatch(r, c, type));
        grid[r][c] = Gem(type: type, id: _genId());
      }
    }

    // Ensure there is at least one valid move.
    if (!hasValidMoves()) {
      _fillInitialBoard();
    }
  }

  /// Check if placing [type] at (row, col) would create a match of 3+.
  bool _wouldMatch(int row, int col, GemType type) {
    // Check horizontal: two to the left
    if (col >= 2 &&
        grid[row][col - 1]?.type == type &&
        grid[row][col - 2]?.type == type) {
      return true;
    }
    // Check vertical: two above
    if (row >= 2 &&
        grid[row - 1][col]?.type == type &&
        grid[row - 2][col]?.type == type) {
      return true;
    }
    return false;
  }

  /// Check if swapping (r1,c1) with (r2,c2) is a valid adjacent swap.
  bool isAdjacentSwap(int r1, int c1, int r2, int c2) {
    final dr = (r1 - r2).abs();
    final dc = (c1 - c2).abs();
    return (dr == 1 && dc == 0) || (dr == 0 && dc == 1);
  }

  /// Swap two gems (does not check adjacency).
  void swap(int r1, int c1, int r2, int c2) {
    final temp = grid[r1][c1];
    grid[r1][c1] = grid[r2][c2];
    grid[r2][c2] = temp;
  }

  /// Find all matches on the board.
  /// Returns a set of (row, col) positions that are part of matches.
  Set<(int, int)> findMatches() {
    final matched = <(int, int)>{};

    // Horizontal matches
    for (int r = 0; r < rows; r++) {
      int c = 0;
      while (c < cols) {
        final type = grid[r][c]?.type;
        if (type == null) {
          c++;
          continue;
        }
        int end = c + 1;
        while (end < cols && grid[r][end]?.type == type) {
          end++;
        }
        if (end - c >= 3) {
          for (int i = c; i < end; i++) {
            matched.add((r, i));
          }
        }
        c = end;
      }
    }

    // Vertical matches
    for (int c = 0; c < cols; c++) {
      int r = 0;
      while (r < rows) {
        final type = grid[r][c]?.type;
        if (type == null) {
          r++;
          continue;
        }
        int end = r + 1;
        while (end < rows && grid[end][c]?.type == type) {
          end++;
        }
        if (end - r >= 3) {
          for (int i = r; i < end; i++) {
            matched.add((i, c));
          }
        }
        r = end;
      }
    }

    return matched;
  }

  /// Remove matched gems (set to null).
  void removeMatches(Set<(int, int)> matches) {
    for (final (r, c) in matches) {
      grid[r][c] = null;
    }
  }

  /// Apply gravity: gems fall down to fill empty spaces.
  /// Returns a list of (fromRow, fromCol, toRow, toCol) moves for animation.
  List<(int, int, int, int)> applyGravity() {
    final moves = <(int, int, int, int)>[];

    for (int c = 0; c < cols; c++) {
      int writeRow = rows - 1;
      for (int r = rows - 1; r >= 0; r--) {
        if (grid[r][c] != null) {
          if (r != writeRow) {
            grid[writeRow][c] = grid[r][c];
            grid[r][c] = null;
            moves.add((r, c, writeRow, c));
          }
          writeRow--;
        }
      }
    }

    return moves;
  }

  /// Fill empty cells at the top with new gems.
  /// Returns a list of (row, col, gem) for animation.
  List<(int, int, Gem)> fillEmpty() {
    final newGems = <(int, int, Gem)>[];

    for (int c = 0; c < cols; c++) {
      for (int r = 0; r < rows; r++) {
        if (grid[r][c] == null) {
          final gem = Gem(type: _randomType(), id: _genId());
          grid[r][c] = gem;
          newGems.add((r, c, gem));
        }
      }
    }

    return newGems;
  }

  /// Check if there is any valid swap that produces a match.
  bool hasValidMoves() {
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        // Try swap right
        if (c + 1 < cols) {
          swap(r, c, r, c + 1);
          final hasMatch = findMatches().isNotEmpty;
          swap(r, c, r, c + 1); // swap back
          if (hasMatch) return true;
        }
        // Try swap down
        if (r + 1 < rows) {
          swap(r, c, r + 1, c);
          final hasMatch = findMatches().isNotEmpty;
          swap(r, c, r + 1, c); // swap back
          if (hasMatch) return true;
        }
      }
    }
    return false;
  }

  /// Shuffle the board while ensuring no matches exist and valid moves are available.
  void shuffle() {
    // Collect all current gem types
    final types = <GemType>[];
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (grid[r][c] != null) {
          types.add(grid[r][c]!.type);
        }
      }
    }
    types.shuffle(_random);

    // Place them back ensuring no matches
    int idx = 0;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        grid[r][c] = Gem(type: types[idx++], id: _genId());
      }
    }

    // If we still have matches or no valid moves, try again
    if (findMatches().isNotEmpty || !hasValidMoves()) {
      // Reset and fill fresh
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          grid[r][c] = null;
        }
      }
      _fillInitialBoard();
    }
  }

  /// Calculate score for matches: base 10 per gem, multiplied by cascade level.
  static int calculateScore(int matchedCount, int cascadeLevel) {
    return matchedCount * 10 * cascadeLevel;
  }
}
