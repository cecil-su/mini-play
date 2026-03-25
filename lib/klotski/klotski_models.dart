// lib/klotski/klotski_models.dart

import 'klotski_config.dart';

/// 游戏中的方块实例（可变位置）
class Block {
  final int id;
  final BlockType type;
  final String label;
  int row;
  int col;

  Block({
    required this.id,
    required this.type,
    required this.label,
    required this.row,
    required this.col,
  });

  int get width => type.width;
  int get height => type.height;

  Block copy() => Block(
    id: id,
    type: type,
    label: label,
    row: row,
    col: col,
  );
}

/// 关卡定义中的方块描述（const 构造）
class BlockDef {
  final BlockType type;
  final String label;
  final int row;
  final int col;

  const BlockDef(this.type, this.label, this.row, this.col);
}

/// 关卡定义
class KlotskiLevel {
  final String name;
  final String nameEn;
  final List<BlockDef> blocks;
  final int minMoves;
  final KlotskiDifficulty difficulty;
  final List<KlotskiMove>? solution; // 预计算的最优解路径

  const KlotskiLevel({
    required this.name,
    required this.nameEn,
    required this.blocks,
    required this.minMoves,
    required this.difficulty,
    this.solution,
  });
}

/// BFS 路径节点 / 移动记录
class KlotskiMove {
  final BlockType blockType;
  final int fromRow;
  final int fromCol;
  final Direction direction;
  final int distance;

  const KlotskiMove({
    required this.blockType,
    required this.fromRow,
    required this.fromCol,
    required this.direction,
    this.distance = 1,
  });
}
