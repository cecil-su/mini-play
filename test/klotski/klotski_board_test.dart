import 'package:flutter_test/flutter_test.dart';
import 'package:mini_play/klotski/klotski_config.dart';
import 'package:mini_play/klotski/klotski_models.dart';
import 'package:mini_play/klotski/klotski_board.dart';

/// 测试布局（简化版，便于验证核心逻辑）：
///
///   col: 0  1  2  3
/// row 0: [曹 曹] .  .
/// row 1: [曹 曹] .  .
/// row 2:  兵  .  .  .
/// row 3:  .  .  .  .
/// row 4:  .  .  .  .
///
/// 曹操在(0,0)，1个兵在(2,0)，大量空格。
/// 曹操需要移到(3,1)才能胜利。
const _simpleBlocks = [
  BlockDef(BlockType.cao, '曹', 0, 0),
  BlockDef(BlockType.soldier, '兵', 2, 0),
];

/// 胜利布局：曹操已在出口位置(3,1)
const _wonBlocks = [
  BlockDef(BlockType.cao, '曹', 3, 1),
  BlockDef(BlockType.soldier, '兵', 0, 0),
];

/// 边界测试布局：曹操在右上角(0,2)
const _cornerBlocks = [
  BlockDef(BlockType.cao, '曹', 0, 2),
  BlockDef(BlockType.soldier, '兵', 2, 0),
];

void main() {
  group('KlotskiBoard', () {
    test('initializes with correct number of blocks', () {
      final board = KlotskiBoard(_simpleBlocks);
      expect(board.blocks.length, 2);
      expect(board.moves, 0);
      expect(board.isWon, false);
    });

    test('builds occupancy grid correctly', () {
      final board = KlotskiBoard(_simpleBlocks);
      final grid = board.buildOccupancyGrid();
      // 曹操 2x2 at (0,0): fills (0,0)(0,1)(1,0)(1,1)
      final caoId = board.blocks.firstWhere((b) => b.type == BlockType.cao).id;
      expect(grid[0][0], caoId);
      expect(grid[0][1], caoId);
      expect(grid[1][0], caoId);
      expect(grid[1][1], caoId);
      // 兵 1x1 at (2,0)
      final soldierId = board.blocks.firstWhere((b) => b.type == BlockType.soldier).id;
      expect(grid[2][0], soldierId);
      // empty cells
      expect(grid[2][1], -1);
      expect(grid[3][0], -1);
      expect(grid[4][3], -1);
    });

    test('canMove returns true for valid move into empty space', () {
      final board = KlotskiBoard(_simpleBlocks);
      final soldier = board.blocks.firstWhere((b) => b.type == BlockType.soldier);
      // 兵 at (2,0) can move right (2,1 is empty)
      expect(board.canMove(soldier.id, Direction.right), true);
      // 兵 at (2,0) can move down (3,0 is empty)
      expect(board.canMove(soldier.id, Direction.down), true);
    });

    test('canMove returns false for move out of bounds', () {
      final board = KlotskiBoard(_cornerBlocks);
      final cao = board.blocks.firstWhere((b) => b.type == BlockType.cao);
      // 曹操 2x2 at (0,2): right edge, can't move right (would need col 4)
      expect(board.canMove(cao.id, Direction.right), false);
      // can't move up (row -1)
      expect(board.canMove(cao.id, Direction.up), false);
    });

    test('canMove returns false for move into occupied cell', () {
      final board = KlotskiBoard(_simpleBlocks);
      final soldier = board.blocks.firstWhere((b) => b.type == BlockType.soldier);
      // 兵 at (2,0) can't move up — (1,0) is occupied by 曹操
      expect(board.canMove(soldier.id, Direction.up), false);
    });

    test('maxDistance returns correct max cells', () {
      final board = KlotskiBoard(_simpleBlocks);
      final soldier = board.blocks.firstWhere((b) => b.type == BlockType.soldier);
      // 兵 at (2,0) moving right: (2,1)(2,2)(2,3) all empty → max 3
      expect(board.maxDistance(soldier.id, Direction.right), 3);
      // 兵 at (2,0) moving down: (3,0)(4,0) empty → max 2
      expect(board.maxDistance(soldier.id, Direction.down), 2);
      // 兵 at (2,0) moving up: (1,0) is 曹操 → max 0
      expect(board.maxDistance(soldier.id, Direction.up), 0);
    });

    test('moveBlock updates position and increments moves', () {
      final board = KlotskiBoard(_simpleBlocks);
      final soldier = board.blocks.firstWhere((b) => b.type == BlockType.soldier);
      board.moveBlock(soldier.id, Direction.right);
      expect(soldier.row, 2);
      expect(soldier.col, 1);
      expect(board.moves, 1);
    });

    test('multi-cell move counts as 1 step', () {
      final board = KlotskiBoard(_simpleBlocks);
      final soldier = board.blocks.firstWhere((b) => b.type == BlockType.soldier);
      board.moveBlock(soldier.id, Direction.right, 3);
      expect(soldier.row, 2);
      expect(soldier.col, 3);
      expect(board.moves, 1);
    });

    test('undo restores previous state and decrements moves', () {
      final board = KlotskiBoard(_simpleBlocks);
      final soldier = board.blocks.firstWhere((b) => b.type == BlockType.soldier);
      board.moveBlock(soldier.id, Direction.right);
      expect(board.moves, 1);
      expect(board.canUndo, true);

      board.undo();
      expect(soldier.row, 2);
      expect(soldier.col, 0);
      expect(board.moves, 0);
      expect(board.canUndo, false);
    });

    test('reset restores initial state', () {
      final board = KlotskiBoard(_simpleBlocks);
      final soldier = board.blocks.firstWhere((b) => b.type == BlockType.soldier);
      board.moveBlock(soldier.id, Direction.right);
      board.moveBlock(soldier.id, Direction.down);
      expect(board.moves, 2);

      board.reset();
      expect(board.moves, 0);
      expect(soldier.row, 2);
      expect(soldier.col, 0);
      expect(board.canUndo, false);
    });

    test('isWon returns true when cao reaches exit', () {
      final board = KlotskiBoard(_wonBlocks);
      expect(board.isWon, true);
    });

    test('isWon returns false when cao is not at exit', () {
      final board = KlotskiBoard(_simpleBlocks);
      expect(board.isWon, false);
    });
  });
}
