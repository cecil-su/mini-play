import 'package:flutter_test/flutter_test.dart';
import 'package:mini_play/klotski/klotski_config.dart';
import 'package:mini_play/klotski/klotski_models.dart';
import 'package:mini_play/klotski/klotski_board.dart';
import 'package:mini_play/klotski/klotski_solver.dart';

/// 2步即可通关：曹操在(1,1)，兵在(3,1)。
/// 解法：兵移开 → 曹操下滑到(3,1)。
const _twoStepBlocks = [
  BlockDef(BlockType.cao, '曹', 1, 1),
  BlockDef(BlockType.soldier, '兵', 3, 1),
];

/// 已在胜利位置
const _wonBlocks = [
  BlockDef(BlockType.cao, '曹', 3, 1),
  BlockDef(BlockType.soldier, '兵', 0, 0),
];

/// 横刀立马经典布局
/// row 0: 张 曹 曹 赵
/// row 1: 张 曹 曹 赵
/// row 2: 马 关 关 黄
/// row 3: 马 兵 兵 黄
/// row 4: 兵 __ __ 兵
const _hengDaoLiMa = [
  BlockDef(BlockType.general, '张', 0, 0),
  BlockDef(BlockType.cao, '曹', 0, 1),
  BlockDef(BlockType.general, '赵', 0, 3),
  BlockDef(BlockType.general, '马', 2, 0),
  BlockDef(BlockType.guanyu, '关', 2, 1),
  BlockDef(BlockType.general, '黄', 2, 3),
  BlockDef(BlockType.soldier, '兵', 4, 0),
  BlockDef(BlockType.soldier, '兵', 3, 1),
  BlockDef(BlockType.soldier, '兵', 3, 2),
  BlockDef(BlockType.soldier, '兵', 4, 3),
];

/// 用 Board 回放解序列，验证最终到达胜利状态
bool _replaySolution(List<BlockDef> defs, List<KlotskiMove> solution) {
  final board = KlotskiBoard(defs);
  for (final move in solution) {
    // 在当前 board 状态中找到匹配 move 的方块
    final block = board.blocks.firstWhere(
      (b) => b.type == move.blockType && b.row == move.fromRow && b.col == move.fromCol,
      orElse: () => throw StateError(
        'No block found: ${move.blockType} at (${move.fromRow},${move.fromCol})',
      ),
    );
    final maxDist = board.maxDistance(block.id, move.direction);
    if (move.distance > maxDist) {
      throw StateError(
        'Invalid move: distance ${move.distance} > maxDistance $maxDist',
      );
    }
    board.moveBlock(block.id, move.direction, move.distance);
  }
  return board.isWon;
}

void main() {
  group('KlotskiSolver', () {
    group('encodeState', () {
      test('same-type blocks at swapped positions produce same encoding', () {
        final blocks1 = [
          Block(id: 0, type: BlockType.cao, label: '曹', row: 0, col: 1),
          Block(id: 1, type: BlockType.soldier, label: '兵', row: 4, col: 0),
          Block(id: 2, type: BlockType.soldier, label: '兵', row: 4, col: 3),
        ];
        final blocks2 = [
          Block(id: 0, type: BlockType.cao, label: '曹', row: 0, col: 1),
          Block(id: 1, type: BlockType.soldier, label: '兵', row: 4, col: 3),
          Block(id: 2, type: BlockType.soldier, label: '兵', row: 4, col: 0),
        ];
        expect(
          KlotskiSolver.encodeState(blocks1),
          KlotskiSolver.encodeState(blocks2),
        );
      });

      test('different states produce different encoding', () {
        final blocks1 = [
          Block(id: 0, type: BlockType.cao, label: '曹', row: 0, col: 1),
          Block(id: 1, type: BlockType.soldier, label: '兵', row: 4, col: 0),
        ];
        final blocks2 = [
          Block(id: 0, type: BlockType.cao, label: '曹', row: 0, col: 1),
          Block(id: 1, type: BlockType.soldier, label: '兵', row: 4, col: 1),
        ];
        expect(
          KlotskiSolver.encodeState(blocks1),
          isNot(KlotskiSolver.encodeState(blocks2)),
        );
      });
    });

    group('solve', () {
      test('returns empty path for already-won state', () {
        final board = KlotskiBoard(_wonBlocks);
        final result = KlotskiSolver.solve(board.blocks);
        expect(result, isNotNull);
        expect(result!.length, 0);
      });

      test('solves a simple 2-step puzzle', () {
        final board = KlotskiBoard(_twoStepBlocks);
        final result = KlotskiSolver.solve(board.blocks);
        expect(result, isNotNull);
        expect(result!.length, 2);
        // 验证回放
        expect(_replaySolution(_twoStepBlocks, result), true);
      });

      test('solves heng dao li ma and solution replays to victory', () {
        final board = KlotskiBoard(_hengDaoLiMa);
        final result = KlotskiSolver.solve(board.blocks);
        expect(result, isNotNull);
        // 验证解可以回放到胜利（不断言具体步数，由 BFS 确定）
        expect(_replaySolution(_hengDaoLiMa, result!), true);
        // 打印实际步数供参考
        // ignore: avoid_print
        print('横刀立马 BFS 最优解: ${result.length} 块步');
      }, timeout: const Timeout(Duration(seconds: 60)));
    });
  });
}
