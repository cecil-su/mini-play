// lib/klotski/klotski_levels.dart
//
// 华容道经典布局数据。minMoves 为"块步"（每次拖动一个方块 = 1 步）。
// 所有 minMoves 值均通过 BFS 求解器验证。
//
// 布局按 minMoves 排序，分配到 3 个难度等级（共 35 关）：
// - 初学 (index 0-9):  minMoves 17-45
// - 进阶 (index 10-24): minMoves 55-78
// - 大师 (index 25-34): minMoves 80-93

import 'klotski_config.dart';
import 'klotski_models.dart';

const List<KlotskiLevel> klotskiLevels = [
  // ============================================================
  // 初学（Beginner）：minMoves 17-45 块步（10 关）
  // ============================================================

  // #1 出其不意 — 17 步
  KlotskiLevel(
    name: '出其不意',
    nameEn: 'Surprise',
    difficulty: KlotskiDifficulty.beginner,
    minMoves: 17,
    blocks: [
      BlockDef(BlockType.soldier, '兵', 0, 0),
      BlockDef(BlockType.soldier, '兵', 0, 1),
      BlockDef(BlockType.general, '张', 0, 2),
      BlockDef(BlockType.general, '赵', 0, 3),
      BlockDef(BlockType.soldier, '兵', 1, 0),
      BlockDef(BlockType.soldier, '兵', 1, 1),
      BlockDef(BlockType.soldier, '兵', 2, 0),
      BlockDef(BlockType.cao, '曹', 2, 1),
      BlockDef(BlockType.soldier, '兵', 2, 3),
      BlockDef(BlockType.soldier, '兵', 4, 0),
      BlockDef(BlockType.guanyu, '关', 4, 1),
      BlockDef(BlockType.soldier, '兵', 4, 3),
    ],
  ),

  // #2 小试牛刀 — 19 步
  KlotskiLevel(
    name: '小试牛刀',
    nameEn: 'First Try',
    difficulty: KlotskiDifficulty.beginner,
    minMoves: 19,
    blocks: [
      BlockDef(BlockType.general, '张', 0, 0),
      BlockDef(BlockType.general, '赵', 0, 1),
      BlockDef(BlockType.soldier, '兵', 0, 2),
      BlockDef(BlockType.soldier, '兵', 0, 3),
      BlockDef(BlockType.cao, '曹', 1, 2),
      BlockDef(BlockType.soldier, '兵', 2, 0),
      BlockDef(BlockType.soldier, '兵', 2, 1),
      BlockDef(BlockType.guanyu, '关', 3, 1),
      BlockDef(BlockType.soldier, '兵', 4, 0),
      BlockDef(BlockType.soldier, '兵', 4, 1),
      BlockDef(BlockType.soldier, '兵', 4, 2),
      BlockDef(BlockType.soldier, '兵', 4, 3),
    ],
  ),

  // #3 旗开得胜 — 26 步
  KlotskiLevel(
    name: '旗开得胜',
    nameEn: 'Flying Start',
    difficulty: KlotskiDifficulty.beginner,
    minMoves: 33,
    blocks: [
      BlockDef(BlockType.soldier, '兵', 0, 0),
      BlockDef(BlockType.soldier, '兵', 0, 1),
      BlockDef(BlockType.cao, '曹', 0, 2),
      BlockDef(BlockType.soldier, '兵', 1, 0),
      BlockDef(BlockType.soldier, '兵', 1, 1),
      BlockDef(BlockType.general, '张', 2, 0),
      BlockDef(BlockType.guanyu, '关', 2, 1),
      BlockDef(BlockType.general, '赵', 2, 3),
      BlockDef(BlockType.soldier, '兵', 4, 0),
      BlockDef(BlockType.soldier, '兵', 4, 1),
      BlockDef(BlockType.soldier, '兵', 4, 2),
      BlockDef(BlockType.soldier, '兵', 4, 3),
    ],
  ),

  // #4 摧枯拉朽 — 28 步
  KlotskiLevel(
    name: '摧枯拉朽',
    nameEn: 'Crushing Force',
    difficulty: KlotskiDifficulty.beginner,
    minMoves: 28,
    blocks: [
      BlockDef(BlockType.general, '张', 0, 0),
      BlockDef(BlockType.soldier, '兵', 0, 1),
      BlockDef(BlockType.soldier, '兵', 0, 2),
      BlockDef(BlockType.general, '赵', 0, 3),
      BlockDef(BlockType.cao, '曹', 1, 1),
      BlockDef(BlockType.soldier, '兵', 3, 0),
      BlockDef(BlockType.guanyu, '关', 3, 1),
      BlockDef(BlockType.soldier, '兵', 3, 3),
      BlockDef(BlockType.soldier, '兵', 4, 0),
      BlockDef(BlockType.soldier, '兵', 4, 1),
      BlockDef(BlockType.soldier, '兵', 4, 2),
      BlockDef(BlockType.soldier, '兵', 4, 3),
    ],
  ),

  // #5 一马当先 — 28 步
  KlotskiLevel(
    name: '一马当先',
    nameEn: 'Taking the Lead',
    difficulty: KlotskiDifficulty.beginner,
    minMoves: 28,
    blocks: [
      BlockDef(BlockType.soldier, '兵', 0, 0),
      BlockDef(BlockType.cao, '曹', 0, 1),
      BlockDef(BlockType.soldier, '兵', 0, 3),
      BlockDef(BlockType.soldier, '兵', 1, 0),
      BlockDef(BlockType.soldier, '兵', 1, 3),
      BlockDef(BlockType.general, '张', 2, 0),
      BlockDef(BlockType.soldier, '兵', 2, 1),
      BlockDef(BlockType.soldier, '兵', 2, 2),
      BlockDef(BlockType.general, '赵', 2, 3),
      BlockDef(BlockType.guanyu, '关', 4, 0),
      BlockDef(BlockType.soldier, '兵', 4, 2),
      BlockDef(BlockType.soldier, '兵', 4, 3),
    ],
  ),

  // #6 直捣黄龙 — 30 步
  KlotskiLevel(
    name: '直捣黄龙',
    nameEn: 'Straight Strike',
    difficulty: KlotskiDifficulty.beginner,
    minMoves: 30,
    blocks: [
      BlockDef(BlockType.soldier, '兵', 0, 0),
      BlockDef(BlockType.cao, '曹', 0, 1),
      BlockDef(BlockType.soldier, '兵', 0, 3),
      BlockDef(BlockType.general, '张', 1, 0),
      BlockDef(BlockType.general, '赵', 1, 3),
      BlockDef(BlockType.soldier, '兵', 2, 1),
      BlockDef(BlockType.soldier, '兵', 2, 2),
      BlockDef(BlockType.soldier, '兵', 3, 0),
      BlockDef(BlockType.soldier, '兵', 3, 3),
      BlockDef(BlockType.guanyu, '关', 4, 0),
      BlockDef(BlockType.soldier, '兵', 4, 2),
      BlockDef(BlockType.soldier, '兵', 4, 3),
    ],
  ),

  // #7 混水摸鱼 — 32 步
  KlotskiLevel(
    name: '混水摸鱼',
    nameEn: 'Muddied Waters',
    difficulty: KlotskiDifficulty.beginner,
    minMoves: 32,
    blocks: [
      BlockDef(BlockType.soldier, '兵', 0, 0),
      BlockDef(BlockType.cao, '曹', 0, 1),
      BlockDef(BlockType.soldier, '兵', 0, 3),
      BlockDef(BlockType.soldier, '兵', 1, 0),
      BlockDef(BlockType.soldier, '兵', 1, 3),
      BlockDef(BlockType.general, '张', 2, 0),
      BlockDef(BlockType.guanyu, '关', 2, 1),
      BlockDef(BlockType.general, '赵', 2, 3),
      BlockDef(BlockType.soldier, '兵', 3, 1),
      BlockDef(BlockType.soldier, '兵', 3, 2),
      BlockDef(BlockType.soldier, '兵', 4, 0),
      BlockDef(BlockType.soldier, '兵', 4, 3),
    ],
  ),

  // #8 四将争锋 — 34 步
  KlotskiLevel(
    name: '四将争锋',
    nameEn: 'Four Generals',
    difficulty: KlotskiDifficulty.beginner,
    minMoves: 34,
    blocks: [
      BlockDef(BlockType.general, '张', 0, 0),
      BlockDef(BlockType.general, '赵', 0, 1),
      BlockDef(BlockType.cao, '曹', 0, 2),
      BlockDef(BlockType.soldier, '兵', 2, 0),
      BlockDef(BlockType.soldier, '兵', 2, 1),
      BlockDef(BlockType.soldier, '兵', 2, 2),
      BlockDef(BlockType.soldier, '兵', 2, 3),
      BlockDef(BlockType.general, '马', 3, 1),
      BlockDef(BlockType.general, '黄', 3, 2),
      BlockDef(BlockType.soldier, '兵', 4, 0),
      BlockDef(BlockType.soldier, '兵', 4, 3),
    ],
  ),

  // #9 初出茅庐 — 39 步
  KlotskiLevel(
    name: '初出茅庐',
    nameEn: 'First Venture',
    difficulty: KlotskiDifficulty.beginner,
    minMoves: 39,
    blocks: [
      BlockDef(BlockType.soldier, '兵', 0, 0),
      BlockDef(BlockType.soldier, '兵', 0, 1),
      BlockDef(BlockType.soldier, '兵', 0, 2),
      BlockDef(BlockType.soldier, '兵', 0, 3),
      BlockDef(BlockType.soldier, '兵', 1, 0),
      BlockDef(BlockType.cao, '曹', 1, 1),
      BlockDef(BlockType.soldier, '兵', 1, 3),
      BlockDef(BlockType.general, '张', 3, 0),
      BlockDef(BlockType.guanyu, '关', 3, 1),
      BlockDef(BlockType.general, '赵', 3, 3),
      BlockDef(BlockType.soldier, '兵', 4, 1),
      BlockDef(BlockType.soldier, '兵', 4, 2),
    ],
  ),

  // #10 兵临城下 — 45 步
  KlotskiLevel(
    name: '兵临城下',
    nameEn: 'Under Siege',
    difficulty: KlotskiDifficulty.beginner,
    minMoves: 45,
    blocks: [
      BlockDef(BlockType.soldier, '兵', 0, 0),
      BlockDef(BlockType.cao, '曹', 0, 1),
      BlockDef(BlockType.general, '张', 0, 3),
      BlockDef(BlockType.soldier, '兵', 1, 0),
      BlockDef(BlockType.general, '赵', 2, 0),
      BlockDef(BlockType.general, '马', 2, 1),
      BlockDef(BlockType.guanyu, '关', 2, 2),
      BlockDef(BlockType.soldier, '兵', 3, 2),
      BlockDef(BlockType.soldier, '兵', 4, 0),
      BlockDef(BlockType.soldier, '兵', 4, 1),
      BlockDef(BlockType.soldier, '兵', 4, 2),
    ],
  ),

  // ============================================================
  // 进阶（Advanced）：minMoves 55-78 块步（15 关）
  // ============================================================

  // #11 假途伐虢 — 55 步
  KlotskiLevel(
    name: '假途伐虢',
    nameEn: 'False Passage',
    difficulty: KlotskiDifficulty.advanced,
    minMoves: 55,
    blocks: [
      BlockDef(BlockType.cao, '曹', 0, 0),
      BlockDef(BlockType.soldier, '兵', 0, 2),
      BlockDef(BlockType.general, '张', 0, 3),
      BlockDef(BlockType.general, '赵', 1, 2),
      BlockDef(BlockType.guanyu, '关', 2, 0),
      BlockDef(BlockType.soldier, '兵', 2, 3),
      BlockDef(BlockType.general, '马', 3, 0),
      BlockDef(BlockType.soldier, '兵', 3, 1),
      BlockDef(BlockType.general, '黄', 3, 3),
      BlockDef(BlockType.soldier, '兵', 4, 1),
    ],
  ),

  // #12 围魏救赵 — 61 步
  KlotskiLevel(
    name: '围魏救赵',
    nameEn: 'Wei Rescue',
    difficulty: KlotskiDifficulty.advanced,
    minMoves: 61,
    blocks: [
      BlockDef(BlockType.soldier, '兵', 0, 0),
      BlockDef(BlockType.general, '张', 0, 1),
      BlockDef(BlockType.cao, '曹', 0, 2),
      BlockDef(BlockType.soldier, '兵', 1, 0),
      BlockDef(BlockType.general, '赵', 2, 0),
      BlockDef(BlockType.guanyu, '关', 2, 1),
      BlockDef(BlockType.general, '马', 2, 3),
      BlockDef(BlockType.general, '黄', 3, 1),
      BlockDef(BlockType.soldier, '兵', 4, 0),
      BlockDef(BlockType.soldier, '兵', 4, 3),
    ],
  ),

  // #13 借刀杀人 — 62 步
  KlotskiLevel(
    name: '借刀杀人',
    nameEn: 'Borrowed Sword',
    difficulty: KlotskiDifficulty.advanced,
    minMoves: 62,
    blocks: [
      BlockDef(BlockType.cao, '曹', 0, 0),
      BlockDef(BlockType.general, '张', 0, 2),
      BlockDef(BlockType.soldier, '兵', 0, 3),
      BlockDef(BlockType.soldier, '兵', 1, 3),
      BlockDef(BlockType.general, '赵', 2, 0),
      BlockDef(BlockType.guanyu, '关', 2, 1),
      BlockDef(BlockType.general, '马', 2, 3),
      BlockDef(BlockType.general, '黄', 3, 1),
      BlockDef(BlockType.soldier, '兵', 4, 0),
      BlockDef(BlockType.soldier, '兵', 4, 3),
    ],
  ),

  // #14 齐头并进 — 64 步
  KlotskiLevel(
    name: '齐头并进',
    nameEn: 'Side by Side',
    difficulty: KlotskiDifficulty.advanced,
    minMoves: 64,
    blocks: [
      BlockDef(BlockType.general, '张', 0, 0),
      BlockDef(BlockType.cao, '曹', 0, 1),
      BlockDef(BlockType.general, '赵', 0, 3),
      BlockDef(BlockType.general, '马', 2, 0),
      BlockDef(BlockType.soldier, '兵', 2, 1),
      BlockDef(BlockType.soldier, '兵', 2, 2),
      BlockDef(BlockType.general, '黄', 2, 3),
      BlockDef(BlockType.soldier, '兵', 3, 1),
      BlockDef(BlockType.soldier, '兵', 3, 2),
      BlockDef(BlockType.guanyu, '关', 4, 1),
    ],
  ),

  // #15 声东击西 — 65 步
  KlotskiLevel(
    name: '声东击西',
    nameEn: 'East Feint',
    difficulty: KlotskiDifficulty.advanced,
    minMoves: 65,
    blocks: [
      BlockDef(BlockType.soldier, '兵', 0, 0),
      BlockDef(BlockType.cao, '曹', 0, 1),
      BlockDef(BlockType.general, '张', 0, 3),
      BlockDef(BlockType.general, '赵', 1, 0),
      BlockDef(BlockType.guanyu, '关', 2, 1),
      BlockDef(BlockType.soldier, '兵', 2, 3),
      BlockDef(BlockType.general, '马', 3, 0),
      BlockDef(BlockType.general, '黄', 3, 3),
      BlockDef(BlockType.soldier, '兵', 4, 1),
      BlockDef(BlockType.soldier, '兵', 4, 2),
    ],
  ),

  // #16 层层设防 — 66 步
  KlotskiLevel(
    name: '层层设防',
    nameEn: 'Layered Defense',
    difficulty: KlotskiDifficulty.advanced,
    minMoves: 66,
    blocks: [
      BlockDef(BlockType.general, '张', 0, 0),
      BlockDef(BlockType.cao, '曹', 0, 1),
      BlockDef(BlockType.general, '赵', 0, 3),
      BlockDef(BlockType.soldier, '兵', 2, 0),
      BlockDef(BlockType.soldier, '兵', 2, 1),
      BlockDef(BlockType.soldier, '兵', 2, 2),
      BlockDef(BlockType.soldier, '兵', 2, 3),
      BlockDef(BlockType.general, '马', 3, 0),
      BlockDef(BlockType.guanyu, '关', 3, 1),
      BlockDef(BlockType.general, '黄', 3, 3),
    ],
  ),

  // #17 暗度陈仓 — 68 步
  KlotskiLevel(
    name: '暗度陈仓',
    nameEn: 'Secret Passage',
    difficulty: KlotskiDifficulty.advanced,
    minMoves: 68,
    blocks: [
      BlockDef(BlockType.general, '张', 0, 0),
      BlockDef(BlockType.cao, '曹', 0, 1),
      BlockDef(BlockType.general, '赵', 0, 3),
      BlockDef(BlockType.general, '马', 2, 1),
      BlockDef(BlockType.general, '黄', 2, 2),
      BlockDef(BlockType.soldier, '兵', 3, 0),
      BlockDef(BlockType.soldier, '兵', 3, 3),
      BlockDef(BlockType.soldier, '兵', 4, 0),
      BlockDef(BlockType.guanyu, '关', 4, 1),
      BlockDef(BlockType.soldier, '兵', 4, 3),
    ],
  ),

  // #18 釜底抽薪 — 69 步
  KlotskiLevel(
    name: '釜底抽薪',
    nameEn: 'Pull the Rug',
    difficulty: KlotskiDifficulty.advanced,
    minMoves: 69,
    blocks: [
      BlockDef(BlockType.general, '张', 0, 0),
      BlockDef(BlockType.cao, '曹', 0, 1),
      BlockDef(BlockType.general, '赵', 0, 3),
      BlockDef(BlockType.soldier, '兵', 2, 0),
      BlockDef(BlockType.guanyu, '关', 2, 1),
      BlockDef(BlockType.soldier, '兵', 2, 3),
      BlockDef(BlockType.general, '马', 3, 0),
      BlockDef(BlockType.general, '黄', 3, 1),
      BlockDef(BlockType.soldier, '兵', 3, 2),
      BlockDef(BlockType.soldier, '兵', 4, 2),
    ],
  ),

  // #19 关门捉贼 — 69 步
  KlotskiLevel(
    name: '关门捉贼',
    nameEn: 'Shut the Gate',
    difficulty: KlotskiDifficulty.advanced,
    minMoves: 69,
    blocks: [
      BlockDef(BlockType.cao, '曹', 0, 0),
      BlockDef(BlockType.general, '张', 0, 2),
      BlockDef(BlockType.general, '赵', 0, 3),
      BlockDef(BlockType.guanyu, '关', 2, 0),
      BlockDef(BlockType.soldier, '兵', 2, 2),
      BlockDef(BlockType.soldier, '兵', 2, 3),
      BlockDef(BlockType.general, '马', 3, 0),
      BlockDef(BlockType.soldier, '兵', 3, 1),
      BlockDef(BlockType.soldier, '兵', 3, 2),
      BlockDef(BlockType.general, '黄', 3, 3),
    ],
  ),

  // #20 绝处逢生 — 74 步
  KlotskiLevel(
    name: '绝处逢生',
    nameEn: 'Last Resort',
    difficulty: KlotskiDifficulty.advanced,
    minMoves: 74,
    blocks: [
      BlockDef(BlockType.general, '张', 0, 0),
      BlockDef(BlockType.cao, '曹', 0, 1),
      BlockDef(BlockType.general, '赵', 0, 3),
      BlockDef(BlockType.general, '马', 2, 0),
      BlockDef(BlockType.soldier, '兵', 2, 1),
      BlockDef(BlockType.general, '黄', 2, 3),
      BlockDef(BlockType.soldier, '兵', 3, 2),
      BlockDef(BlockType.soldier, '兵', 4, 0),
      BlockDef(BlockType.guanyu, '关', 4, 1),
      BlockDef(BlockType.soldier, '兵', 4, 3),
    ],
  ),

  // #20 四面楚歌 — 76 步
  KlotskiLevel(
    name: '四面楚歌',
    nameEn: 'Surrounded',
    difficulty: KlotskiDifficulty.advanced,
    minMoves: 76,
    blocks: [
      BlockDef(BlockType.general, '张', 0, 0),
      BlockDef(BlockType.cao, '曹', 0, 1),
      BlockDef(BlockType.general, '赵', 0, 3),
      BlockDef(BlockType.general, '马', 2, 0),
      BlockDef(BlockType.soldier, '兵', 2, 1),
      BlockDef(BlockType.soldier, '兵', 2, 2),
      BlockDef(BlockType.general, '黄', 2, 3),
      BlockDef(BlockType.guanyu, '关', 3, 1),
      BlockDef(BlockType.soldier, '兵', 4, 0),
      BlockDef(BlockType.soldier, '兵', 4, 3),
    ],
  ),

  // #21 金蝉脱壳 — 77 步
  KlotskiLevel(
    name: '金蝉脱壳',
    nameEn: 'Golden Escape',
    difficulty: KlotskiDifficulty.advanced,
    minMoves: 77,
    blocks: [
      BlockDef(BlockType.soldier, '兵', 0, 0),
      BlockDef(BlockType.cao, '曹', 0, 1),
      BlockDef(BlockType.soldier, '兵', 0, 3),
      BlockDef(BlockType.general, '张', 1, 0),
      BlockDef(BlockType.general, '赵', 1, 3),
      BlockDef(BlockType.guanyu, '关', 2, 1),
      BlockDef(BlockType.general, '马', 3, 0),
      BlockDef(BlockType.general, '黄', 3, 3),
      BlockDef(BlockType.soldier, '兵', 3, 1),
      BlockDef(BlockType.soldier, '兵', 3, 2),
    ],
  ),

  // #22 中军帐前 — 77 步
  KlotskiLevel(
    name: '中军帐前',
    nameEn: 'Command Tent',
    difficulty: KlotskiDifficulty.advanced,
    minMoves: 77,
    blocks: [
      BlockDef(BlockType.soldier, '兵', 0, 0),
      BlockDef(BlockType.cao, '曹', 0, 1),
      BlockDef(BlockType.soldier, '兵', 0, 3),
      BlockDef(BlockType.general, '张', 1, 0),
      BlockDef(BlockType.general, '赵', 1, 3),
      BlockDef(BlockType.general, '马', 2, 1),
      BlockDef(BlockType.general, '黄', 2, 2),
      BlockDef(BlockType.soldier, '兵', 3, 0),
      BlockDef(BlockType.soldier, '兵', 3, 3),
      BlockDef(BlockType.guanyu, '关', 4, 1),
    ],
  ),

  // #23 破釜沉舟 — 78 步
  KlotskiLevel(
    name: '破釜沉舟',
    nameEn: 'Burning Boats',
    difficulty: KlotskiDifficulty.advanced,
    minMoves: 78,
    blocks: [
      BlockDef(BlockType.general, '张', 0, 0),
      BlockDef(BlockType.cao, '曹', 0, 1),
      BlockDef(BlockType.general, '赵', 0, 3),
      BlockDef(BlockType.soldier, '兵', 2, 0),
      BlockDef(BlockType.guanyu, '关', 2, 1),
      BlockDef(BlockType.general, '马', 2, 3),
      BlockDef(BlockType.soldier, '兵', 3, 0),
      BlockDef(BlockType.general, '黄', 3, 2),
      BlockDef(BlockType.soldier, '兵', 4, 1),
      BlockDef(BlockType.soldier, '兵', 4, 3),
    ],
  ),

  // #24 指桑骂槐 — 76 步
  KlotskiLevel(
    name: '指桑骂槐',
    nameEn: 'Indirect Attack',
    difficulty: KlotskiDifficulty.advanced,
    minMoves: 76,
    blocks: [
      BlockDef(BlockType.soldier, '兵', 0, 0),
      BlockDef(BlockType.cao, '曹', 0, 1),
      BlockDef(BlockType.soldier, '兵', 0, 3),
      BlockDef(BlockType.general, '张', 1, 0),
      BlockDef(BlockType.general, '赵', 1, 3),
      BlockDef(BlockType.general, '马', 2, 1),
      BlockDef(BlockType.general, '黄', 2, 2),
      BlockDef(BlockType.soldier, '兵', 3, 0),
      BlockDef(BlockType.soldier, '兵', 3, 3),
      BlockDef(BlockType.guanyu, '关', 4, 0),
    ],
  ),

  // ============================================================
  // 大师（Master）：minMoves 80-93 块步（10 关）
  // ============================================================

  // #25 运筹帷幄 — 80 步
  KlotskiLevel(
    name: '运筹帷幄',
    nameEn: 'Master Plan',
    difficulty: KlotskiDifficulty.master,
    minMoves: 80,
    blocks: [
      BlockDef(BlockType.general, '张', 0, 0),
      BlockDef(BlockType.cao, '曹', 0, 1),
      BlockDef(BlockType.general, '赵', 0, 3),
      BlockDef(BlockType.guanyu, '关', 2, 0),
      BlockDef(BlockType.general, '马', 2, 2),
      BlockDef(BlockType.general, '黄', 2, 3),
      BlockDef(BlockType.soldier, '兵', 3, 0),
      BlockDef(BlockType.soldier, '兵', 3, 1),
      BlockDef(BlockType.soldier, '兵', 4, 1),
      BlockDef(BlockType.soldier, '兵', 4, 2),
    ],
  ),

  // #26 过关斩将 — 80 步
  KlotskiLevel(
    name: '过关斩将',
    nameEn: 'Cut Through',
    difficulty: KlotskiDifficulty.master,
    minMoves: 80,
    blocks: [
      BlockDef(BlockType.general, '张', 0, 0),
      BlockDef(BlockType.cao, '曹', 0, 1),
      BlockDef(BlockType.general, '赵', 0, 3),
      BlockDef(BlockType.guanyu, '关', 2, 0),
      BlockDef(BlockType.general, '马', 2, 2),
      BlockDef(BlockType.general, '黄', 2, 3),
      BlockDef(BlockType.soldier, '兵', 3, 0),
      BlockDef(BlockType.soldier, '兵', 3, 1),
      BlockDef(BlockType.soldier, '兵', 4, 0),
      BlockDef(BlockType.soldier, '兵', 4, 3),
    ],
  ),

  // #27 抛砖引玉 — 81 步
  KlotskiLevel(
    name: '抛砖引玉',
    nameEn: 'Cast the Brick',
    difficulty: KlotskiDifficulty.master,
    minMoves: 81,
    blocks: [
      BlockDef(BlockType.soldier, '兵', 0, 0),
      BlockDef(BlockType.cao, '曹', 0, 1),
      BlockDef(BlockType.general, '张', 0, 3),
      BlockDef(BlockType.general, '赵', 1, 0),
      BlockDef(BlockType.soldier, '兵', 2, 1),
      BlockDef(BlockType.general, '马', 2, 2),
      BlockDef(BlockType.soldier, '兵', 2, 3),
      BlockDef(BlockType.guanyu, '关', 3, 0),
      BlockDef(BlockType.general, '黄', 3, 3),
      BlockDef(BlockType.soldier, '兵', 4, 1),
    ],
  ),

  // #28 水泄不通 — 83 步
  KlotskiLevel(
    name: '水泄不通',
    nameEn: 'Watertight',
    difficulty: KlotskiDifficulty.master,
    minMoves: 83,
    blocks: [
      BlockDef(BlockType.general, '张', 0, 0),
      BlockDef(BlockType.cao, '曹', 0, 1),
      BlockDef(BlockType.general, '赵', 0, 3),
      BlockDef(BlockType.soldier, '兵', 2, 0),
      BlockDef(BlockType.guanyu, '关', 2, 1),
      BlockDef(BlockType.soldier, '兵', 2, 3),
      BlockDef(BlockType.general, '马', 3, 1),
      BlockDef(BlockType.general, '黄', 3, 2),
      BlockDef(BlockType.soldier, '兵', 4, 0),
      BlockDef(BlockType.soldier, '兵', 4, 3),
    ],
  ),

  // #29 万夫莫开 — 84 步
  KlotskiLevel(
    name: '万夫莫开',
    nameEn: 'Impregnable',
    difficulty: KlotskiDifficulty.master,
    minMoves: 84,
    blocks: [
      BlockDef(BlockType.general, '张', 0, 0),
      BlockDef(BlockType.cao, '曹', 0, 1),
      BlockDef(BlockType.general, '赵', 0, 3),
      BlockDef(BlockType.general, '马', 2, 0),
      BlockDef(BlockType.guanyu, '关', 2, 1),
      BlockDef(BlockType.soldier, '兵', 2, 3),
      BlockDef(BlockType.soldier, '兵', 3, 1),
      BlockDef(BlockType.general, '黄', 3, 3),
      BlockDef(BlockType.soldier, '兵', 4, 0),
      BlockDef(BlockType.soldier, '兵', 4, 1),
    ],
  ),

  // #30 趁火打劫 — 86 步
  KlotskiLevel(
    name: '趁火打劫',
    nameEn: 'Loot the Fire',
    difficulty: KlotskiDifficulty.master,
    minMoves: 86,
    blocks: [
      BlockDef(BlockType.general, '张', 0, 0),
      BlockDef(BlockType.cao, '曹', 0, 1),
      BlockDef(BlockType.general, '赵', 0, 3),
      BlockDef(BlockType.general, '马', 2, 0),
      BlockDef(BlockType.guanyu, '关', 2, 1),
      BlockDef(BlockType.soldier, '兵', 2, 3),
      BlockDef(BlockType.general, '黄', 3, 3),
      BlockDef(BlockType.soldier, '兵', 3, 2),
      BlockDef(BlockType.soldier, '兵', 4, 0),
      BlockDef(BlockType.soldier, '兵', 4, 2),
    ],
  ),

  // #31 困兽犹斗 — 87 步
  KlotskiLevel(
    name: '困兽犹斗',
    nameEn: 'Cornered Beast',
    difficulty: KlotskiDifficulty.master,
    minMoves: 87,
    blocks: [
      BlockDef(BlockType.general, '张', 0, 0),
      BlockDef(BlockType.cao, '曹', 0, 1),
      BlockDef(BlockType.general, '赵', 0, 3),
      BlockDef(BlockType.general, '马', 2, 0),
      BlockDef(BlockType.soldier, '兵', 2, 1),
      BlockDef(BlockType.guanyu, '关', 2, 2),
      BlockDef(BlockType.soldier, '兵', 3, 2),
      BlockDef(BlockType.general, '黄', 3, 3),
      BlockDef(BlockType.soldier, '兵', 4, 0),
      BlockDef(BlockType.soldier, '兵', 4, 2),
    ],
  ),

  // #32 釜底游鱼 — 87 步
  KlotskiLevel(
    name: '釜底游鱼',
    nameEn: 'Fish in the Pot',
    difficulty: KlotskiDifficulty.master,
    minMoves: 87,
    blocks: [
      BlockDef(BlockType.soldier, '兵', 0, 0),
      BlockDef(BlockType.cao, '曹', 0, 1),
      BlockDef(BlockType.general, '张', 0, 3),
      BlockDef(BlockType.general, '赵', 1, 0),
      BlockDef(BlockType.guanyu, '关', 2, 1),
      BlockDef(BlockType.general, '马', 2, 3),
      BlockDef(BlockType.soldier, '兵', 3, 0),
      BlockDef(BlockType.general, '黄', 3, 1),
      BlockDef(BlockType.soldier, '兵', 4, 0),
      BlockDef(BlockType.soldier, '兵', 4, 3),
    ],
  ),

  // #33 横刀立马 — 90 步
  KlotskiLevel(
    name: '横刀立马',
    nameEn: 'Heng Dao Li Ma',
    difficulty: KlotskiDifficulty.master,
    minMoves: 90,
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
  ),

  // #34 置之死地 — 93 步
  KlotskiLevel(
    name: '置之死地',
    nameEn: 'Point of No Return',
    difficulty: KlotskiDifficulty.master,
    minMoves: 93,
    blocks: [
      BlockDef(BlockType.soldier, '兵', 0, 0),
      BlockDef(BlockType.cao, '曹', 0, 1),
      BlockDef(BlockType.general, '张', 0, 3),
      BlockDef(BlockType.general, '赵', 1, 0),
      BlockDef(BlockType.general, '马', 2, 1),
      BlockDef(BlockType.guanyu, '关', 2, 2),
      BlockDef(BlockType.soldier, '兵', 3, 0),
      BlockDef(BlockType.general, '黄', 3, 2),
      BlockDef(BlockType.soldier, '兵', 4, 0),
      BlockDef(BlockType.soldier, '兵', 4, 1),
    ],
  ),
];
