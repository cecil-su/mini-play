// lib/klotski/klotski_solver.dart

import 'dart:collection';
import 'klotski_config.dart';
import 'klotski_models.dart';

class KlotskiSolver {
  /// 状态编码：同类型方块按位置排序后拼接（规范化）
  static String encodeState(List<Block> blocks) {
    final sorted = blocks.toList()
      ..sort((a, b) {
        final tc = a.type.index.compareTo(b.type.index);
        if (tc != 0) return tc;
        final rc = a.row.compareTo(b.row);
        return rc != 0 ? rc : a.col.compareTo(b.col);
      });
    return sorted.map((b) => '${b.type.index},${b.row},${b.col}').join(';');
  }

  /// BFS 求最优解。返回移动序列，null 表示无解，空列表表示已胜利。
  static List<KlotskiMove>? solve(List<Block> blocks) {
    // 检查是否已胜利
    if (_isWon(blocks)) return [];

    final visited = HashSet<String>();
    final queue = Queue<_SolverState>();

    final initialState = _copyBlocks(blocks);
    final initialCode = encodeState(initialState);
    visited.add(initialCode);
    queue.add(_SolverState(initialState, []));

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();

      // 枚举所有方块的所有方向和距离
      for (final block in current.blocks) {
        for (final dir in Direction.values) {
          // 枚举距离 1..maxDist
          for (int dist = 1; ; dist++) {
            if (!_canMoveDistance(current.blocks, block.id, dir, dist)) break;

            // 生成新状态
            final newBlocks = _copyBlocks(current.blocks);
            final movedBlock = newBlocks.firstWhere((b) => b.id == block.id);
            movedBlock.row += dir.dy * dist;
            movedBlock.col += dir.dx * dist;

            final code = encodeState(newBlocks);
            if (visited.contains(code)) continue;
            visited.add(code);

            final move = KlotskiMove(
              blockType: block.type,
              fromRow: block.row,
              fromCol: block.col,
              direction: dir,
              distance: dist,
            );
            final newPath = [...current.path, move];

            if (_isWon(newBlocks)) return newPath;

            queue.add(_SolverState(newBlocks, newPath));
          }
        }
      }
    }

    return null; // 无解
  }

  static bool _isWon(List<Block> blocks) {
    final cao = blocks.firstWhere((b) => b.type == BlockType.cao);
    return cao.row == exitRow && cao.col == exitCol;
  }

  static List<Block> _copyBlocks(List<Block> blocks) {
    return blocks.map((b) => b.copy()).toList();
  }

  static bool _canMoveDistance(
      List<Block> blocks, int blockId, Direction dir, int distance) {
    final block = blocks.firstWhere((b) => b.id == blockId);
    final grid = _buildGrid(blocks);
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

  static List<List<int>> _buildGrid(List<Block> blocks) {
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
}

class _SolverState {
  final List<Block> blocks;
  final List<KlotskiMove> path;

  _SolverState(this.blocks, this.path);
}
