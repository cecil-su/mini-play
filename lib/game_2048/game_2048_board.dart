import 'dart:math';
import 'game_2048_tile.dart';

enum Direction { up, down, left, right }

class _BoardSnapshot {
  final List<Tile> tiles;
  final int score;
  final int moveCount;

  _BoardSnapshot({
    required this.tiles,
    required this.score,
    required this.moveCount,
  });
}

class GameBoard {
  final int gridSize;
  final Random _random = Random();

  List<Tile> _tiles = [];
  int _score = 0;
  int _moveCount = 0;
  bool _hasReached2048 = false;

  final List<_BoardSnapshot> _undoStack = [];
  int _undoRemaining = 3;

  List<Tile> get tiles => _tiles;
  int get score => _score;
  int get moveCount => _moveCount;
  bool get hasReached2048 => _hasReached2048;
  int get undoRemaining => _undoRemaining;

  GameBoard({required this.gridSize}) {
    _spawnTile();
    _spawnTile();
  }

  /// Test constructor: create board from a 2D value grid.
  /// Does not spawn random tiles. Zeros are empty cells.
  GameBoard.fromValues(this.gridSize, List<List<int>> values) {
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (values[r][c] != 0) {
          final tile = Tile(value: values[r][c], row: r, col: c);
          tile.isNew = false;
          _tiles.add(tile);
        }
      }
    }
  }

  /// Convert tiles to a 2D value grid (for logic and testing).
  List<List<int>> toGrid() {
    final grid = List.generate(gridSize, (_) => List.filled(gridSize, 0));
    for (final tile in _tiles) {
      grid[tile.row][tile.col] = tile.value;
    }
    return grid;
  }

  /// Build a 2D tile reference grid for O(1) cell lookup.
  List<List<Tile?>> _buildTileGrid() {
    final grid = List.generate(
      gridSize, (_) => List<Tile?>.filled(gridSize, null),
    );
    for (final tile in _tiles) {
      grid[tile.row][tile.col] = tile;
    }
    return grid;
  }

  /// Slide tiles in the given direction. Returns true if the board changed.
  bool slide(Direction direction) {
    // Save previous positions for animation
    for (final tile in _tiles) {
      tile.savePreviousPosition();
      tile.isNew = false;
      tile.mergedFrom = null;
    }

    // Snapshot BEFORE the slide loop because _setLine mutates tile objects
    // in-place (row/col). Must capture positions before they change.
    _pushUndoSnapshot();

    // Build grid once for O(1) cell lookup in _getLine.
    final grid = _buildTileGrid();

    int scoreGained = 0;
    bool moved = false;
    final newTiles = <Tile>[];

    for (int i = 0; i < gridSize; i++) {
      final line = _getLine(i, direction, grid);
      final result = _slideLine(line);
      scoreGained += result.scoreGained;
      if (result.moved) moved = true;
      _setLine(i, direction, result.tiles, newTiles);
    }

    if (!moved) {
      _undoStack.removeLast();
      return false;
    }

    // Trim undo stack to 3 entries now that we know the move is valid.
    if (_undoStack.length > 3) {
      _undoStack.removeAt(0);
    }

    _tiles = newTiles;
    _score += scoreGained;
    _moveCount++;

    // Check for 2048
    if (!_hasReached2048) {
      for (final tile in _tiles) {
        if (tile.value >= 2048) {
          _hasReached2048 = true;
          break;
        }
      }
    }

    _spawnTile();
    return true;
  }

  /// Get a line of tiles for processing (row or column depending on direction).
  List<Tile?> _getLine(int index, Direction direction, List<List<Tile?>> grid) {
    final line = <Tile?>[];

    for (int i = 0; i < gridSize; i++) {
      int r, c;
      switch (direction) {
        case Direction.left:
          r = index; c = i;
        case Direction.right:
          r = index; c = gridSize - 1 - i;
        case Direction.up:
          r = i; c = index;
        case Direction.down:
          r = gridSize - 1 - i; c = index;
      }
      line.add(grid[r][c]);
    }
    return line;
  }

  /// Slide and merge a single line. Returns merged result.
  _SlideResult _slideLine(List<Tile?> line) {
    final nonNull = line.where((t) => t != null).toList();
    final result = <Tile>[];
    int scoreGained = 0;
    bool moved = false;

    int i = 0;
    while (i < nonNull.length) {
      if (i + 1 < nonNull.length && nonNull[i]!.value == nonNull[i + 1]!.value) {
        // Merge
        final merged = Tile(
          value: nonNull[i]!.value * 2,
          row: 0, col: 0, // position set later by _setLine
        );
        merged.isNew = false;
        merged.mergedFrom = [nonNull[i]!, nonNull[i + 1]!];
        result.add(merged);
        scoreGained += merged.value;
        i += 2;
      } else {
        result.add(nonNull[i]!);
        i++;
      }
    }

    // Check if anything moved
    if (result.length != nonNull.length) {
      moved = true; // merges happened
    } else {
      for (int j = 0; j < result.length; j++) {
        if (line[j] == null || line[j] != result[j]) {
          moved = true;
          break;
        }
      }
    }

    return _SlideResult(tiles: result, scoreGained: scoreGained, moved: moved);
  }

  /// Place result tiles back into their positions.
  void _setLine(int index, Direction direction, List<Tile> lineTiles, List<Tile> newTiles) {
    for (int i = 0; i < lineTiles.length; i++) {
      final tile = lineTiles[i];
      int r, c;
      switch (direction) {
        case Direction.left:
          r = index; c = i;
        case Direction.right:
          r = index; c = gridSize - 1 - i;
        case Direction.up:
          r = i; c = index;
        case Direction.down:
          r = gridSize - 1 - i; c = index;
      }
      tile.row = r;
      tile.col = c;
      // For merged tiles, set previousRow/Col from one of the source tiles
      if (tile.mergedFrom != null) {
        tile.previousRow = tile.mergedFrom![0].previousRow;
        tile.previousCol = tile.mergedFrom![0].previousCol;
      }
      newTiles.add(tile);
    }
  }

  /// Spawn a random tile (90% = 2, 10% = 4) in an empty cell.
  void _spawnTile() {
    final empty = <(int, int)>[];
    final grid = toGrid();
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (grid[r][c] == 0) {
          empty.add((r, c));
        }
      }
    }
    if (empty.isEmpty) return;
    final pos = empty[_random.nextInt(empty.length)];
    final value = _random.nextDouble() < 0.9 ? 2 : 4;
    _tiles.add(Tile(value: value, row: pos.$1, col: pos.$2));
  }

  /// Check if the game is over (no empty cells and no adjacent equal cells).
  bool get isGameOver {
    final grid = toGrid();
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (grid[r][c] == 0) return false;
        if (c + 1 < gridSize && grid[r][c] == grid[r][c + 1]) return false;
        if (r + 1 < gridSize && grid[r][c] == grid[r + 1][c]) return false;
      }
    }
    return true;
  }

  /// Get the maximum tile value on the board.
  int get maxTileValue {
    int max = 0;
    for (final tile in _tiles) {
      if (tile.value > max) max = tile.value;
    }
    return max;
  }

  /// Push current state to undo stack.
  /// Note: does NOT trim here — trimming happens in slide() after confirming
  /// the move is valid, to avoid evicting a valid entry on a no-op slide.
  void _pushUndoSnapshot() {
    _undoStack.add(_BoardSnapshot(
      tiles: _tiles.map((t) => t.copy()).toList(),
      score: _score,
      moveCount: _moveCount,
    ));
  }

  /// Undo the last move. Returns true if successful.
  /// Note: does not restore [hasReached2048] — once the 2048 milestone is
  /// reached, it stays set so the congratulations overlay is shown only once.
  bool undo() {
    if (_undoStack.isEmpty || _undoRemaining <= 0) return false;
    final snapshot = _undoStack.removeLast();
    _tiles = snapshot.tiles;
    _score = snapshot.score;
    _moveCount = snapshot.moveCount;
    _undoRemaining--;
    return true;
  }
}

class _SlideResult {
  final List<Tile> tiles;
  final int scoreGained;
  final bool moved;

  _SlideResult({
    required this.tiles,
    required this.scoreGained,
    required this.moved,
  });
}
