// lib/sokoban/sokoban_board.dart

import 'sokoban_levels.dart';

enum CellType { floor, wall, goal }

enum Direction { up, down, left, right }

class Position {
  final int row;
  final int col;

  const Position(this.row, this.col);

  Position move(Direction dir) {
    switch (dir) {
      case Direction.up:
        return Position(row - 1, col);
      case Direction.down:
        return Position(row + 1, col);
      case Direction.left:
        return Position(row, col - 1);
      case Direction.right:
        return Position(row, col + 1);
    }
  }

  @override
  bool operator ==(Object other) =>
      other is Position && other.row == row && other.col == col;

  @override
  int get hashCode => row * 1000 + col;
}

class _Snapshot {
  final Position player;
  final Set<Position> boxes;

  _Snapshot(this.player, Set<Position> boxes)
      : boxes = Set<Position>.from(boxes);
}

class SokobanBoard {
  late final int rows;
  late final int cols;
  late final List<List<CellType>> grid;
  late Position player;
  late Set<Position> boxes;
  late Set<Position> goals;
  int moves = 0;
  bool _won = false;
  final List<_Snapshot> _history = [];

  bool get isWon => _won;
  bool get canUndo => _history.isNotEmpty;

  SokobanBoard(SokobanLevel level) {
    _parse(level.data);
  }

  void _parse(List<String> data) {
    rows = data.length;
    cols = data.fold<int>(0, (m, line) => line.length > m ? line.length : m);
    grid = List.generate(rows, (_) => List.filled(cols, CellType.wall));
    boxes = {};
    goals = {};
    player = const Position(0, 0);

    for (int r = 0; r < rows; r++) {
      final line = data[r];
      for (int c = 0; c < line.length; c++) {
        final ch = line[c];
        switch (ch) {
          case ' ':
            grid[r][c] = CellType.floor;
          case '#':
            grid[r][c] = CellType.wall;
          case '@':
            grid[r][c] = CellType.floor;
            player = Position(r, c);
          case '+':
            grid[r][c] = CellType.goal;
            goals.add(Position(r, c));
            player = Position(r, c);
          case '\$':
            grid[r][c] = CellType.floor;
            boxes.add(Position(r, c));
          case '.':
            grid[r][c] = CellType.goal;
            goals.add(Position(r, c));
          case '*':
            grid[r][c] = CellType.goal;
            goals.add(Position(r, c));
            boxes.add(Position(r, c));
        }
      }
    }
  }

  bool tryMove(Direction dir) {
    if (_won) return false;

    final nextPos = player.move(dir);
    if (!_inBounds(nextPos) || grid[nextPos.row][nextPos.col] == CellType.wall) {
      return false;
    }

    if (boxes.contains(nextPos)) {
      final boxDest = nextPos.move(dir);
      if (!_inBounds(boxDest) ||
          grid[boxDest.row][boxDest.col] == CellType.wall ||
          boxes.contains(boxDest)) {
        return false;
      }
      // Save state before move
      _history.add(_Snapshot(player, boxes));
      boxes.remove(nextPos);
      boxes.add(boxDest);
      player = nextPos;
      moves++;
    } else {
      // Save state before move
      _history.add(_Snapshot(player, boxes));
      player = nextPos;
      moves++;
    }

    // Check win
    if (goals.every((g) => boxes.contains(g))) {
      _won = true;
    }

    return true;
  }

  void undo() {
    if (_history.isEmpty) return;
    final snap = _history.removeLast();
    player = snap.player;
    boxes = snap.boxes;
    moves--;
    _won = false;
  }

  void reset(SokobanLevel level) {
    _history.clear();
    moves = 0;
    _won = false;
    _parse(level.data);
  }

  bool _inBounds(Position p) =>
      p.row >= 0 && p.row < rows && p.col >= 0 && p.col < cols;
}
