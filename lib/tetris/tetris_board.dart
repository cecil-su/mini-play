import 'tetris_piece.dart';

enum TetrisGameMode { classic, sprint, marathon }

class TetrisBoard {
  static const int rows = 20;
  static const int cols = 10;
  static const int maxLevel = 15;

  final TetrisGameMode mode;
  final PieceBag _bag = PieceBag();

  /// Grid: null = empty, PieceType = locked cell color.
  final List<List<PieceType?>> grid;

  late Piece currentPiece;
  late PieceType nextPieceType;

  int score = 0;
  int linesCleared = 0;
  int level = 1;
  bool isGameOver = false;
  bool isWon = false; // for Sprint mode

  TetrisBoard({required this.mode})
      : grid = List.generate(rows, (_) => List.filled(cols, null)) {
    final firstType = _bag.next();
    nextPieceType = _bag.next();
    currentPiece = _spawnPiece(firstType);
    if (!_isValid(currentPiece)) {
      isGameOver = true;
    }
  }

  /// Milliseconds per drop tick for the current level.
  int get dropInterval {
    // Speed curve: level 1 = 800ms, level 15 = 80ms
    const baseInterval = 800;
    const minInterval = 80;
    final interval = baseInterval - ((level - 1) * (baseInterval - minInterval) ~/ (maxLevel - 1));
    return interval.clamp(minInterval, baseInterval);
  }

  Piece _spawnPiece(PieceType type) {
    // Spawn at top center
    final piece = Piece(type: type, row: 0, col: 3);
    return piece;
  }

  bool _isValid(Piece piece) {
    for (final (r, c) in piece.cells) {
      if (r < 0 || r >= rows || c < 0 || c >= cols) return false;
      if (r >= 0 && grid[r][c] != null) return false;
    }
    return true;
  }

  /// Move current piece left. Returns true if moved.
  bool moveLeft() {
    if (isGameOver || isWon) return false;
    final moved = currentPiece.copy()..col = currentPiece.col - 1;
    if (_isValid(moved)) {
      currentPiece = moved;
      return true;
    }
    return false;
  }

  /// Move current piece right. Returns true if moved.
  bool moveRight() {
    if (isGameOver || isWon) return false;
    final moved = currentPiece.copy()..col = currentPiece.col + 1;
    if (_isValid(moved)) {
      currentPiece = moved;
      return true;
    }
    return false;
  }

  /// Rotate current piece clockwise. Returns true if rotated.
  bool rotate() {
    if (isGameOver || isWon) return false;
    final rotated = currentPiece.tryRotate(_isValid);
    if (rotated != null) {
      currentPiece = rotated;
      return true;
    }
    return false;
  }

  /// Soft drop: move piece down one row. Returns true if moved.
  bool softDrop() {
    if (isGameOver || isWon) return false;
    final moved = currentPiece.copy()..row = currentPiece.row + 1;
    if (_isValid(moved)) {
      currentPiece = moved;
      return true;
    }
    return false;
  }

  /// Hard drop: instantly drop piece to bottom.
  /// Returns the number of rows dropped.
  int hardDrop() {
    if (isGameOver || isWon) return 0;
    int dropped = 0;
    while (true) {
      final moved = currentPiece.copy()..row = currentPiece.row + 1;
      if (_isValid(moved)) {
        currentPiece = moved;
        dropped++;
      } else {
        break;
      }
    }
    _lockPiece();
    return dropped;
  }

  /// Called by game timer: try to drop one row, lock if can't.
  /// Returns true if the piece was locked (a new piece was spawned).
  bool tick() {
    if (isGameOver || isWon) return false;
    if (!softDrop()) {
      _lockPiece();
      return true;
    }
    return false;
  }

  /// Lock the current piece into the grid and spawn next.
  void _lockPiece() {
    // Place piece cells into grid
    for (final (r, c) in currentPiece.cells) {
      if (r >= 0 && r < rows && c >= 0 && c < cols) {
        grid[r][c] = currentPiece.type;
      }
    }

    // Clear completed lines
    final cleared = _clearLines();
    if (cleared > 0) {
      linesCleared += cleared;
      score += _scoreForLines(cleared) * level;
      _updateLevel();

      // Sprint mode: check if 40 lines reached
      if (mode == TetrisGameMode.sprint && linesCleared >= 40) {
        isWon = true;
        return;
      }
    }

    // Spawn next piece
    currentPiece = _spawnPiece(nextPieceType);
    nextPieceType = _bag.next();

    if (!_isValid(currentPiece)) {
      isGameOver = true;
    }
  }

  /// Clear full lines, returns count of cleared lines.
  int _clearLines() {
    int cleared = 0;
    for (int r = rows - 1; r >= 0; r--) {
      if (grid[r].every((cell) => cell != null)) {
        grid.removeAt(r);
        grid.insert(0, List.filled(cols, null));
        cleared++;
        r++; // re-check same index since rows shifted down
      }
    }
    return cleared;
  }

  int _scoreForLines(int lines) {
    switch (lines) {
      case 1:
        return 100;
      case 2:
        return 300;
      case 3:
        return 500;
      case 4:
        return 800;
      default:
        return 0;
    }
  }

  void _updateLevel() {
    final newLevel = (linesCleared ~/ 10) + 1;
    if (mode == TetrisGameMode.marathon) {
      level = newLevel.clamp(1, maxLevel);
    } else {
      level = newLevel;
    }
  }

  /// Get the ghost piece position (where piece would land).
  Piece get ghostPiece {
    final ghost = currentPiece.copy();
    while (true) {
      final next = ghost.copy()..row = ghost.row + 1;
      if (_isValid(next)) {
        ghost.row = next.row;
      } else {
        break;
      }
    }
    return ghost;
  }
}
