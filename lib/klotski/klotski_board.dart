// lib/klotski/klotski_board.dart

import 'klotski_config.dart';
import 'klotski_models.dart';

class _BoardSnapshot {
  final List<(int id, int row, int col)> blockPositions;
  final int moves;

  _BoardSnapshot(List<Block> blocks, this.moves)
      : blockPositions = blocks.map((b) => (b.id, b.row, b.col)).toList();

  void restore(List<Block> blocks) {
    for (final (id, row, col) in blockPositions) {
      final block = blocks.firstWhere((b) => b.id == id);
      block.row = row;
      block.col = col;
    }
  }
}

class KlotskiBoard {
  final List<Block> blocks;
  final List<BlockDef> _initialDefs;
  int moves = 0;
  final List<_BoardSnapshot> _history = [];

  KlotskiBoard(List<BlockDef> defs)
      : _initialDefs = defs,
        blocks = _createBlocks(defs);

  static List<Block> _createBlocks(List<BlockDef> defs) {
    return List.generate(defs.length, (i) {
      final d = defs[i];
      return Block(
        id: i,
        type: d.type,
        label: d.label,
        row: d.row,
        col: d.col,
      );
    });
  }

  bool get isWon {
    final cao = blocks.firstWhere((b) => b.type == BlockType.cao);
    return cao.row == exitRow && cao.col == exitCol;
  }

  bool get canUndo => _history.isNotEmpty;

  /// 构建 5x4 占位网格，空格为 -1，方块为 block.id
  List<List<int>> buildOccupancyGrid() {
    final grid = List.generate(boardRows, (_) => List.filled(boardCols, -1));
    for (final block in blocks) {
      for (int r = 0; r < block.height; r++) {
        for (int c = 0; c < block.width; c++) {
          grid[block.row + r][block.col + c] = block.id;
        }
      }
    }
    return grid;
  }

  /// 检查方块能否向指定方向移动 1 格
  bool canMove(int blockId, Direction dir) {
    return _canMoveDistance(blockId, dir, 1);
  }

  bool _canMoveDistance(int blockId, Direction dir, int distance) {
    final block = blocks.firstWhere((b) => b.id == blockId);
    final grid = buildOccupancyGrid();
    final newRow = block.row + dir.dy * distance;
    final newCol = block.col + dir.dx * distance;

    for (int r = 0; r < block.height; r++) {
      for (int c = 0; c < block.width; c++) {
        final tr = newRow + r;
        final tc = newCol + c;
        if (tr < 0 || tr >= boardRows || tc < 0 || tc >= boardCols) {
          return false;
        }
        if (grid[tr][tc] != -1 && grid[tr][tc] != blockId) {
          return false;
        }
      }
    }
    return true;
  }

  /// 返回方块在指定方向最大可移动格数
  int maxDistance(int blockId, Direction dir) {
    int dist = 0;
    while (_canMoveDistance(blockId, dir, dist + 1)) {
      dist++;
    }
    return dist;
  }

  /// 执行移动，推入撤销栈
  void moveBlock(int blockId, Direction dir, [int distance = 1]) {
    assert(distance > 0 && distance <= maxDistance(blockId, dir),
        'Invalid move: distance $distance, max ${maxDistance(blockId, dir)}');
    _history.add(_BoardSnapshot(blocks, moves));
    final block = blocks.firstWhere((b) => b.id == blockId);
    block.row += dir.dy * distance;
    block.col += dir.dx * distance;
    moves++;
  }

  /// 撤销上一步
  void undo() {
    if (_history.isEmpty) return;
    final snap = _history.removeLast();
    snap.restore(blocks);
    moves = snap.moves;
  }

  /// 重置到初始状态
  void reset() {
    _history.clear();
    moves = 0;
    for (int i = 0; i < _initialDefs.length; i++) {
      blocks[i].row = _initialDefs[i].row;
      blocks[i].col = _initialDefs[i].col;
    }
  }
}
