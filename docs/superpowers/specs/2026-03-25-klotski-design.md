# 华容道 (Klotski) Game Design

## Overview

华容道 — 经典三国主题滑块益智游戏。在 4×5 棋盘上滑动不同大小的方块，将曹操（2×2）移到底部出口。35 个精选关卡，3 个难度分级，BFS 求解器提供提示，星级评分系统。

- **技术栈：** Widget-based（Stack + Transform.translate），参考 2048 动画模式
- **棋盘：** 4 列 × 5 行，出口固定在底部正中（第 1-2 列）
- **操作：** 拖拽为主，支持多格滑动，轴锁定
- **主题：** 三国人物（曹操、关羽、张飞等），木质棋盘风
- **无音效**

## Block Types

| 类型 | 尺寸 | 标签 | 颜色 | 数量 |
|------|------|------|------|------|
| 曹操 (cao) | 2×2 | 曹 | 红金 `#C62828` | 1（固定） |
| 关羽 (guanyu) | 1×2 横 | 关 | 深绿 `#2E7D32` | 0-1 |
| 将军 (general) | 1×2 竖 | 张/赵/马/黄 | 蓝 `#1565C0` | 0-5 |
| 兵卒 (soldier) | 1×1 | 兵 | 土黄 `#F9A825` | 0-6 |

注：支持非标准方块组合，不同关卡的横/竖/兵数量可变化。唯一固定的是有且仅有 1 个曹操（2×2），且棋盘上恰好有 2 个空格。

### Block Visual Design

- 每个方块显示单个汉字标签（曹/关/张/赵/马/黄/兵）
- 圆角矩形，内边距 2px，圆角半径 4px
- 微妙的内阴影/浮雕效果模拟木质感
- 将军方块根据人物分配不同的蓝色系色调区分

## Data Model

### BlockType

```dart
enum BlockType {
  cao,      // 2×2
  guanyu,   // 1×2 横（关羽专用）
  general,  // 1×2 竖
  soldier,  // 1×1
}
```

每种类型的尺寸：

```dart
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
```

### Block

```dart
class Block {
  final int id;
  final BlockType type;
  final String label;  // 显示的汉字（曹/关/张/赵/马/黄/兵）
  int row;             // 左上角行（0-based）
  int col;             // 左上角列（0-based）

  int get width => type.width;
  int get height => type.height;
}
```

### BlockDef（关卡定义用）

```dart
class BlockDef {
  final BlockType type;
  final String label;
  final int row;
  final int col;
  const BlockDef(this.type, this.label, this.row, this.col);
}
```

### KlotskiLevel

```dart
class KlotskiLevel {
  final String name;       // 中文布局名（如 '横刀立马'）
  final String nameEn;     // 英文名（如 'Heng Dao Li Ma'）
  final List<BlockDef> blocks;
  final int minMoves;      // 最优解步数
  final KlotskiDifficulty difficulty;

  const KlotskiLevel({...});
}
```

### KlotskiBoard（游戏逻辑）

```dart
class KlotskiBoard {
  List<Block> blocks;
  int moves = 0;
  bool _won = false;

  // 派生占位网格：5行×4列，存 block.id 或 -1（空）
  List<List<int>> _buildOccupancyGrid();

  // 移动验证
  bool canMove(int blockId, Direction dir);

  // 多格移动：返回该方向最大可移动格数（BFS 枚举和拖拽夹紧都依赖此方法）
  // 算法：从 dist=1 开始逐步检测，直到 canMoveWithDistance 返回 false
  // canMoveWithDistance 与 canMove 相同，但偏移乘以 dist
  int maxDistance(int blockId, Direction dir);

  // 执行移动（推入撤销栈）
  void moveBlock(int blockId, Direction dir, [int distance = 1]);

  // 撤销
  bool get canUndo;
  void undo();

  // 重置
  void reset();

  // 胜利判定：曹操左上角在 (3, 1)
  bool get isWon;
}
```

### Move Validation

```dart
bool canMove(int blockId, Direction dir) {
  final block = _findBlock(blockId);
  final grid = _buildOccupancyGrid();
  final dr = dir.dy;  // up=-1, down=1
  final dc = dir.dx;  // left=-1, right=1
  final newRow = block.row + dr;
  final newCol = block.col + dc;

  for (int r = 0; r < block.height; r++) {
    for (int c = 0; c < block.width; c++) {
      final tr = newRow + r;
      final tc = newCol + c;
      if (tr < 0 || tr >= 5 || tc < 0 || tc >= 4) return false;
      if (grid[tr][tc] != -1 && grid[tr][tc] != block.id) return false;
    }
  }
  return true;
}
```

### Win Condition

曹操（2×2）的左上角到达 `(row=3, col=1)`，即覆盖 `(3,1)(3,2)(4,1)(4,2)`，从底部正中出口滑出。

## Undo System

参考 Sokoban 的快照模式：

```dart
class _BoardSnapshot {
  final List<(int id, int row, int col)> blockPositions;
  final int moves;
}
```

- 每次 `moveBlock` 前推入快照
- `undo()` 弹出最后一个快照并恢复
- **无限撤销**，无次数限制
- 重置清空撤销栈

## BFS Solver & Hint System

### Solver

BFS 求最优解，状态空间约 25K-65K，移动端 <200ms。

**步数定义（重要）：** 1 步 = 将一个方块向某方向移动任意格数（与用户计分一致）。BFS 枚举时，对每个方块每个方向的所有合法距离（1 到 maxDistance）各算 1 步。这样 BFS 求出的 minMoves 与经典华容道文献一致（如横刀立马 = 81 步）。

**状态编码：** 将所有方块按类型和位置排序后生成字符串哈希。同类型方块可互换（除曹操外），需规范化排序以减少状态数。

```dart
String encodeState(List<Block> blocks) {
  final sorted = blocks.toList()
    ..sort((a, b) {
      final tc = a.type.index.compareTo(b.type.index);
      if (tc != 0) return tc;
      final rc = a.row.compareTo(b.row);
      return rc != 0 ? rc : a.col.compareTo(b.col);
    });
  // 用分隔符防止不同字段值拼接时产生歧义
  return sorted.map((b) => '${b.type.index},${b.row},${b.col}').join(';');
}
```

**KlotskiMove（BFS 路径节点）：**

BFS 在规范化状态上运行，不存在固定的 block.id。移动记录使用"方块的类型 + 起始位置"来唯一标识方块，提示系统据此在当前游戏状态中找到对应的真实方块。

```dart
class KlotskiMove {
  final BlockType blockType;  // 方块类型
  final int fromRow;          // 移动前的左上角行
  final int fromCol;          // 移动前的左上角列
  final Direction direction;
  final int distance;         // 移动格数（≥ 1）
}
```

**BFS 流程：**
1. 从当前状态开始，对每个方块、每个方向，枚举距离 1 到 `maxDistance(block, dir)`，每种组合生成一个子状态（= 1 步）
2. 对每个新状态检查是否访问过（用 `Set<String>` 存已访问状态哈希）
3. 找到胜利状态时沿父指针回溯路径
4. 返回 `List<KlotskiMove>` 最优解序列

**性能：**
- **Native（Android/iOS）：** 状态空间约 25K-65K（标准布局），BFS 通常 10-50ms，不需要 Isolate。
- **Web（dart2js）：** 字符串编码 + HashSet 在 JS 中慢 3-10x，大师级关卡可能达 200-500ms。保底方案：用 `compute()` 避免 UI 阻塞。
- **预计算初始解：** 开发阶段用 BFS 求解器生成所有 35 关的最优解序列，硬编码到 `klotski_levels.dart`。运行时仅对"玩家已偏离最优路径"的状态做实时 BFS。这是 Web 端性能的终极保底。
- **非标准方块组合** 的状态空间可能超出 65K，实现时需逐关实测求解时间。

### Hint System

**提示次数按难度递增：**

| 难度 | 初学 | 进阶 | 大师 |
|------|------|------|------|
| 每关提示次数 | 5 次 | 8 次 | 12 次 |

- 点击提示按钮 → BFS 从当前状态求解 → 高亮下一步应移动的方块 + 方向箭头脉冲动画
- 玩家走了非提示步骤后，缓存的解失效，下次提示重新求解
- 重置关卡时提示次数恢复
- 提示不影响星级评分
- **观看解法（兜底）：** 提示用完后，允许观看完整解法动画演示。使用后该关标记为"已观看解法"，仅计为通关（1 星），不参与更高星级评分。确保休闲玩家不会被彻底卡死

## Difficulty & Levels

### Difficulty Tiers

3 个难度等级，关卡数不均分（中间最多，两端较少）：

```dart
enum KlotskiDifficulty {
  beginner('初学', 'Beginner', 0, 10),   // minMoves 约 17-50
  advanced('进阶', 'Advanced', 10, 15),   // minMoves 约 51-85
  master('大师', 'Master', 25, 10);       // minMoves 约 86-138

  final String label;
  final String labelEn;
  final int startIndex;
  final int count;
  const KlotskiDifficulty(this.label, this.labelEn, this.startIndex, this.count);
}
```

**为什么 3 级而非 4 级：** 真实华容道布局中 minMoves < 30 的极少（约 3-5 个），无法撑起独立的"入门"级。进阶级（51-85 步）是布局最密集的区间，给 15 关。

### Tier Unlock（双轨制）

满足星数 **或** 通关数任一条件即可解锁，确保不同类型玩家都不会被卡住：

| 难度 | 星数条件 | OR 通关条件 | 最大可获星数 |
|------|---------|-----------|------------|
| 初学 | 默认解锁 | — | 30 |
| 进阶 | 累计 8 星 | OR 初学通关 6 关 | 45 |
| 大师 | 累计 30 星 | OR 进阶通关 10 关 | 30 |

**容错分析：**
- 解锁进阶：初学 10 关全 1 星 = 10 星 > 8 星，轻松达标
- 解锁大师（星数路径）：初学全 1 星(10) + 进阶全 1 星(15) = 25 星，只需其中 5 关拿到 2 星即可
- 解锁大师（通关路径）：进阶 15 关中通关 10 关（67%），不看星数

同一难度内关卡**自由选择**，无需顺序通关。

### Star Rating

采用"固定容错 + 比例容错"混合公式，解决纯比例制对低步数关卡不公平的问题：

```
3 星阈值 = minMoves + max(baseMargin, minMoves × ratio)
2 星阈值 = minMoves + max(baseMargin × 2, minMoves × ratio2)
1 星 = 通关即获得
```

| 难度 | 3星 baseMargin | 3星 ratio | 2星 baseMargin | 2星 ratio |
|------|---------------|-----------|---------------|-----------|
| 初学 | 8 | 0.15 | 16 | 0.40 |
| 进阶 | 10 | 0.20 | 20 | 0.50 |
| 大师 | 12 | 0.25 | 24 | 0.60 |

**示例计算：**

| 关卡 | minMoves | 3星≤ | 3星容错 | 2星≤ | 2星容错 |
|------|---------|------|--------|------|--------|
| 初学 17步 | 17 | 25 | 8 步 | 37 | 20 步 |
| 初学 40步 | 40 | 48 | 8 步 | 56 | 16 步 |
| 进阶 70步 | 70 | 84 | 14 步 | 105 | 35 步 |
| 大师 100步 | 100 | 125 | 25 步 | 160 | 60 步 |
| 大师 138步 | 138 | 173 | 35 步 | 221 | 83 步 |

**最优步数（minMoves 具体数值）在首次通关后才显示。**

### 35 Levels

每关使用经典华容道布局，附中文名称。**具体关卡列表在实现阶段通过以下流程确定：**

#### 关卡构建流程（实现阶段执行）

1. **获取布局编码**：从经典华容道数据库（尉迟方 53 关、klotski.online 等）获取棋盘初始状态的精确编码
2. **BFS 验证**：用求解器逐一计算每个布局的真实 minMoves（块步：移动一块 = 1 步）
3. **选关排序**：按 BFS 验证后的 minMoves 排序，选取 35 关分配到 3 个难度
4. **预计算解序列**：将每关的最优解路径硬编码，用于提示系统和 Web 端性能保底

#### 已确认的关键数据点

| 布局名 | minMoves | 可信度 |
|--------|----------|--------|
| 横刀立马 | 81 步 | 多个独立 BFS 确认 |
| 峰回路转 | 138 步 | 标准布局已知最难，BFS 确认 |

#### 真实 minMoves 分布特征

- 范围：约 17-138 步（块步）
- 分布：右偏正态，峰值在 70-90 步区间
- < 30 步：极少（约 3-5 个经典命名布局）
- 30-50 步：约 8-12 个
- 51-85 步：最密集（约 15-20 个）
- 86-138 步：约 8-12 个

#### 关卡分配目标

| 难度 | 关卡数 | minMoves 范围 | 选关来源 |
|------|-------|--------------|---------|
| 初学 | 10 关 | 17-50 步 | 经典命名布局为主，不足部分从穷举数据库选取并赋予三国名称 |
| 进阶 | 15 关 | 51-85 步 | 布局最丰富区间，含"横刀立马"(81 步) |
| 大师 | 10 关 | 86-138 步 | 含"峰回路转"(138 步)作为终极关 |

#### 关卡多样性要求

- 至少 5 关包含关羽（1×2 横放方块），提供独特的横向解法路径
- 将军数量应有 3-4 种不同配置（2/3/4/5 个）
- 兵的数量应有变化，确保视觉和策略多样性

## Scoring

### Primary Metric: Move Count

- 每次有效移动（含多格滑动）计为 **1 步**
- 撤销时步数 -1
- 重置时步数归零

### No Time Pressure

- 不显示计时器
- 通关后在结果页显示用时作为参考信息
- 时间不影响星级评分

### High Score Storage

```dart
ScoreService().saveHighScore('klotski', 'level_$index', moves, lowerIsBetter: true);
```

**ScoreService 扩展需求：** 当前 `getBestScore()` 返回 `0`（非 `null`），无法区分"从未通关"和"已通关"。华容道需要此区分来控制首次通关反馈、minMoves 显示、步数变色等。解决方案二选一：
- **方案 A**：增加 `Future<int?> getBestScoreOrNull(game, mode)` 方法
- **方案 B**：使用独立 bool key（如 `klotski_level_0_completed`）标记通关状态

星级不单独存储，每次从最佳步数 + minMoves 实时计算。累计星数在关卡选择页初始化时一次性加载所有关卡的最佳步数后计算。

### Move Counter Color Feedback

步数计数器根据当前进度变色，颜色阈值基于星级公式计算：

| 步数范围 | 颜色 | 含义 |
|---------|------|------|
| ≤ 3 星阈值 | 绿 `#4ECCA3` | 3 星范围内 |
| ≤ 2 星阈值 | 黄 `#F0C040` | 2 星范围内 |
| > 2 星阈值 | 红 `#E84545` | 超出 2 星（仍可通关拿 1 星） |

**变色启用策略（分难度）：**
- **初学 / 进阶：始终启用**变色（颜色不泄露具体 minMoves 值，仅提供模糊的表现反馈）
- **大师：首次通关后启用**（保留探索乐趣，避免高步数关卡的挫败感）
- minMoves 具体数值始终在首次通关后才显示

## UI Design

### Page Flow

Home → KlotskiModePage（关卡选择）→ KlotskiPage（游戏）→ GameOverPage

### Mode Page（关卡选择）

参考 Sokoban 模式页：

- 按难度分组显示，每组有彩色标题栏
- 每关显示为方块瓦片：关卡号 + 布局名 + 星级 + 最佳步数
- 每组标题栏显示 "X/Y 星" 进度和进度条
- 未解锁的难度灰显，显示解锁条件（"需要 X 星 或 通关 Y 关"）
- 难度颜色：初学 `#4ECCA3`、进阶 `#3A86FF`、大师 `#E84545`

### Game Page Layout（竖屏）

```
+-------------------------------+
|  [←] 横刀立马 (#26)    [||]  |  ← GameScaffold 顶栏
|  步数: 23        最佳: 18     |  ← 分数栏
+-------------------------------+
|  [撤销]  [提示💡×N]  [重置]   |  ← 操作栏（N=5/8/12 按难度）
+-------------------------------+
|                               |
|     ┌──┬─────┬──┐            |
|     │兵│ 张  │兵│            |
|     │  │     │  │            |
|     ├──┤曹 操├──┤            |
|     │马│     │赵│            |
|     │  ├──┬──┤  │            |
|     │  │关 羽│  │            |
|     ├──┼──┼──┼──┤            |
|     │兵│  │  │兵│            |
|     └──┴==╧==┴──┘            |
|          EXIT                 |
|                               |
+-------------------------------+
```

- 棋盘使用 `LayoutBuilder` 计算 cellSize（需扣除操作栏高度约 48px）：
  `cellSize = min(availableWidth / 4, (availableHeight - 48) / 5)`
- 棋盘居中显示
- 出口处（底部第 1-2 列）显示金色脉冲光效

### Interaction

#### Drag（主要操作）

1. 手指触碰方块 → 方块视觉抬起（阴影 + 1.02x 缩放）
2. 拖拽 > 8px 后锁定轴向（水平或垂直）
3. 方块跟随手指移动，被障碍物或边界夹住时停止
4. 支持一次拖拽多格（经过空格时持续移动）
5. 释放时：偏移 > 0.4 × cellSize → 吸附到该方向最近的合法格位（不超过 maxDistance）；否则弹回原位
6. 吸附动画 150ms `Curves.easeOutCubic`，弹回动画 100ms `Curves.easeOut`

#### Keyboard（Web/Desktop）

- 点击方块选中 → 方向键移动
- Tab 切换选中方块
- Z：撤销
- R：重置（需确认）

### Victory Animation

1. 触觉反馈 `HapticFeedback.mediumImpact()`
2. 短暂停顿 300ms
3. 曹操方块从出口向下滑出（500ms, `Curves.easeInCubic`）
4. 其余方块渐隐并缩小（400ms，与步骤 3 并行）
5. 几何纸屑从出口迸发（与步骤 3 同时触发）
6. 从胜利触发起 **1500ms** 后跳转 GameOverPage（动画总时长约 1200ms，留 300ms 余量）

**实现归属：** 胜利动画在 `KlotskiPage` 级编排（非 Block Widget 内部），使用 1 个 `AnimationController`（总时长 800ms），通过 `Interval` 分别驱动曹操滑出和其他方块渐隐。播放期间通过 `bool _isVictoryAnimating` 禁用所有方块的拖拽输入。`KlotskiPage` 需使用 `TickerProviderStateMixin`（非 Single）以支持多个 controller。

### GameOver Stats

```dart
// 通过 ScoreService 判断是否首次通关（需扩展 API，见 High Score Storage 章节）
final isFirstCompletion = /* getBestScoreOrNull 返回 null */;

title: '恭喜通关'
stats: {
  '关卡': level.name,
  '步数': moves,
  if (!isFirstCompletion) '最优': level.minMoves,
  '用时': formatTime(elapsed),
  '评级': '⭐⭐⭐',
}
```

**通关引导按钮：**
- "下一关" — 如果当前难度有下一关可用
- "再试一次" — 如果未达 3 星，附提示"目标 3 星！"
- 如果通关后累计星数/通关数刚好解锁了新难度，显示 "恭喜！XX 难度已解锁！"

### Tutorial（渐进式引导）

前 3 关提供渐进式教学，覆盖操作、策略、工具三个层面：

**第 1 关（操作）：** 首次进入时触发
1. 高亮一个可移动方块 + 浮动箭头 → "拖动方块来移动"
2. 玩家首次移动后，高亮出口 + 脉冲 → "让曹操到达出口"

**第 2 关（策略）：** 首次进入时触发
1. 高亮一个挡在曹操路径上的方块 → "移开挡路的方块，为曹操开辟道路"

**第 3 关（工具）：** 首次进入时触发
1. Tooltip 指向提示按钮 → "卡住了？试试提示功能"
2. Tooltip 指向撤销按钮 → "走错了？撤销重来"

后续关卡不再显示教程。

## File Structure

```
lib/klotski/
├── klotski_config.dart         # BlockType enum, KlotskiDifficulty enum, 棋盘常量
├── klotski_models.dart         # Block, BlockDef, KlotskiLevel, KlotskiMove
├── klotski_board.dart          # KlotskiBoard 游戏逻辑（移动验证、撤销、胜利判定）
├── klotski_levels.dart         # const List<KlotskiLevel> 所有关卡布局
├── klotski_solver.dart         # BFS 求解器、提示路径计算
├── klotski_colors.dart         # 颜色常量（方块、棋盘、出口）
├── klotski_block_widget.dart   # 单个方块 Widget（拖拽 + 动画）
├── klotski_mode_page.dart      # 关卡选择页（难度分组）
└── klotski_page.dart           # 游戏主页（GameScaffold + Stack 棋盘 + 操作栏）
                                  # 含私有 Widget：_KlotskiBoardBackground（网格线 + 出口标记）
```

## Integration

### Game Registry

```dart
GameInfo(
  name: 'Klotski',
  icon: Icons.view_compact,
  description: '华容道 - 滑动方块，释放曹操',
  phase: 6,
  route: '/klotski',
  implemented: true,
  hasModePage: true,
)
```

### Routing (main.dart)

```dart
case '/klotski':
  return MaterialPageRoute(builder: (_) => const KlotskiModePage());
case '/klotski/play':
  final levelIndex = settings.arguments as int? ?? 0;
  return MaterialPageRoute(builder: (_) => KlotskiPage(levelIndex: levelIndex));
```

## Shared Utilities Used

- `GameScaffold` — 顶栏、暂停/恢复、分数显示
- `ScoreService` — 最佳步数持久化（`lowerIsBetter: true`）
- `GameModeCard` — 不使用（关卡选择用自定义瓦片）
- `GameOverPage` — 通关结果展示（`title: '恭喜通关'`）
- `formatTime()` — 时间格式化

## State Management

StatefulWidget + setState，与项目现有模式一致：

- `ValueNotifier<int>` 绑定步数到 GameScaffold
- `setState()` 刷新棋盘和操作栏
- `Stopwatch` 记录用时（首次移动时启动，通关时停止）
- 暂停时阻止所有输入

## Rendering Approach

Widget-based（非 CustomPaint），原因：

1. 方块有多种尺寸，Widget 的 `width/height` 自然处理
2. 拖拽手势用 `GestureDetector` 包裹每个方块，比 Canvas hit-testing 简单
3. 方块上显示汉字标签，用 `Text` widget 比 `TextPainter` 方便
4. 参考 2048 的 `AnimatedTileWidget` 模式：`AnimationController` + `Transform.translate`

### Block Widget Pattern

```dart
class KlotskiBlockWidget extends StatefulWidget {
  final Block block;
  final double cellSize;
  // 查询回调：拖拽开始时缓存四个方向的最大可移动格数，用于夹紧手指偏移
  final int Function(Direction dir) maxDistance;
  // 提交回调：用户拖拽/吸附完成后调用，触发 board.moveBlock
  final void Function(Direction dir, int distance) onMoved;
}

class _KlotskiBlockWidgetState extends State<KlotskiBlockWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Offset _dragOffset = Offset.zero;
  Axis? _lockedAxis;
  bool _isDragging = false;
  // onPanStart 时缓存四个方向限制，onPanUpdate 用于夹紧偏移量
  Map<Direction, int> _maxDistances = {};
}
```

### Board Stack

```dart
Stack(
  children: [
    // 背景网格 + 出口标记
    KlotskiBoardBackground(cellSize: cellSize),
    // 所有方块
    for (final block in board.blocks)
      KlotskiBlockWidget(
        key: ValueKey(block.id),
        block: block,
        cellSize: cellSize,
        maxDistance: (dir) => board.maxDistance(block.id, dir),
        onMoved: (dir, dist) => _handleMove(block.id, dir, dist),
      ),
  ],
)
```
