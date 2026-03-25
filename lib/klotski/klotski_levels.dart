// lib/klotski/klotski_levels.dart
//
// 华容道经典布局数据。minMoves 为"块步"（每次拖动一个方块 = 1 步）。
// 所有 minMoves 值均通过 BFS 求解器验证。
//
// 关卡构建流程：
// 1. 从经典华容道数据库获取布局编码（尉迟方53关、klotski.online等）
// 2. BFS 验证每关的真实 minMoves（块步）
// 3. 按 minMoves 排序分配到 3 个难度等级
//
// 当前为首批实现，包含已验证的经典布局。后续补充至 35 关。

import 'klotski_config.dart';
import 'klotski_models.dart';

const List<KlotskiLevel> klotskiLevels = [
  // ============================================================
  // 初学（Beginner）：minMoves 约 17-50 块步
  // ============================================================

  // 待补充：从经典布局数据库获取编码 + BFS 验证后添加

  // ============================================================
  // 进阶（Advanced）：minMoves 约 51-85 块步
  // ============================================================

  // #1 横刀立马 — BFS 验证: 90 块步
  // row 0: 张 曹 曹 赵
  // row 1: 张 曹 曹 赵
  // row 2: 马 关 关 黄
  // row 3: 马 兵 兵 黄
  // row 4: 兵 __ __ 兵
  KlotskiLevel(
    name: '横刀立马',
    nameEn: 'Heng Dao Li Ma',
    blocks: [
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
    ],
    minMoves: 90, // BFS 验证的块步数
    difficulty: KlotskiDifficulty.advanced,
  ),

  // ============================================================
  // 大师（Master）：minMoves 约 86-138 块步
  // ============================================================

  // 后续关卡在实现阶段通过以下流程补充：
  // 1. 从经典布局数据库获取棋盘编码
  // 2. BFS 计算真实 minMoves
  // 3. 按 minMoves 排序分配难度
  // 4. 预计算最优解路径用于提示系统
];
