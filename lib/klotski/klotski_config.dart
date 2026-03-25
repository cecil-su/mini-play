// lib/klotski/klotski_config.dart

/// 棋盘常量
const int boardRows = 5;
const int boardCols = 4;
const int exitRow = 3; // 曹操胜利时左上角行
const int exitCol = 1; // 曹操胜利时左上角列

/// 方块类型
enum BlockType {
  cao,     // 2×2 曹操
  guanyu,  // 1×2 横（关羽）
  general, // 1×2 竖（将军）
  soldier, // 1×1 兵卒
}

extension BlockTypeSize on BlockType {
  int get width => switch (this) {
    BlockType.cao => 2,
    BlockType.guanyu => 2,
    BlockType.general => 1,
    BlockType.soldier => 1,
  };

  int get height => switch (this) {
    BlockType.cao => 2,
    BlockType.guanyu => 1,
    BlockType.general => 2,
    BlockType.soldier => 1,
  };
}

/// 移动方向
enum Direction {
  up(0, -1),
  down(0, 1),
  left(-1, 0),
  right(1, 0);

  final int dx; // 列偏移
  final int dy; // 行偏移

  const Direction(this.dx, this.dy);
}

/// 难度分级
enum KlotskiDifficulty {
  beginner('初学', 'Beginner', 0, 10),
  advanced('进阶', 'Advanced', 10, 15),
  master('大师', 'Master', 25, 10);

  final String label;
  final String labelEn;
  final int startIndex;
  final int count;

  const KlotskiDifficulty(this.label, this.labelEn, this.startIndex, this.count);
}
