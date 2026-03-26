# Game of Life 实现计划

**目标:** 实现 Conway's Game of Life 三模式游戏（沙盒/挑战/图鉴百科），300×300 环面网格，15 个预设图案，15 个挑战关卡
**架构:** 12+ 个文件，核心引擎纯 Dart 逻辑与 UI 分离。Uint8List 双缓冲网格，InteractiveViewer + CustomPainter 渲染，FNV-1a 哈希历史检测。
**技术栈:** Flutter CustomPainter, InteractiveViewer, Listener, Ticker, SharedPreferences
**设计文档:** docs/superpowers/specs/2026-03-26-game-of-life-design.md
**新增依赖:** 无
**测试模式:** 仅关键路径（演化逻辑、目标检测）

## 执行波次（并行优化）

| Wave | 可并行任务 | 前置条件 |
|------|-----------|---------|
| 1 | T1 配置配色 | 无 |
| 2 | T2 引擎, T4 图案数据 | T1 |
| 3 | T3 引擎测试, T5 Painter, T6 Widgets, T8a 关卡定义 | T2+T4 |
| 4 | T7a 核心沙盒, T8b 挑战运行器, T11 图鉴百科 | T5+T6 |
| 5 | T7b 图案放置, T9 挑战测试, T10 挑战页面, T13 新手引导 | T7a+T8b |
| 6 | T12 模式选择页+集成 | T7a+T10+T11 |
| 7 | T14 模式间流转+收尾 | 全部 |

---

### Task 1: 配置与配色  ✅

**文件:**
- 创建: `lib/game_of_life/game_of_life_config.dart`
- 创建: `lib/game_of_life/game_of_life_colors.dart`

**Step 1: 创建配置常量**

`game_of_life_config.dart`:
```dart
class GameOfLifeConfig {
  static const int gridWidth = 300;
  static const int gridHeight = 300;
  static const int gridSize = gridWidth * gridHeight; // 90000

  // 速度档位（代/秒）
  static const List<int> speedLevels = [3, 10, 30];
  static const List<String> speedLabels = ['慢', '中', '快'];

  // 缩放
  static const double minScale = 0.5;
  static const double maxScale = 8.0;
  static const double gridLineThreshold = 8.0; // px/格 以上显示网格线

  // 历史
  static const int historyCapacity = 30;

  // 上限
  static const double pauseThreshold = 0.5; // 活细胞占比超过 50% 自动暂停

  // 每帧最大演化代数（"最快"档限制）
  static const int maxStepsPerFrameWeb = 3;
  static const int maxStepsPerFrameNative = 5;

  // 挑战
  static const String gameName = 'gameoflife';
}

// 交互模式
enum InteractionMode { draw, pan, placingPattern }

// 路由参数
enum GameOfLifeMode { sandbox, challenge, encyclopedia }
```

`game_of_life_colors.dart`:
```dart
class GameOfLifeColors {
  static const Color background = Color(0xFF1A1A2E);
  static const Color gridLine = Color(0xFF2A2A3E);
  static const Color cellAlive = Color(0xFF00FF88);
  static const Color cellNew = Color(0xFF66FFB2);    // 浅绿高亮
  static const Color cellLocked = Color(0xFF4488FF);  // 挑战锁定
  static const Color cellPreview = Color(0x6600FF88); // 半透明绿
}
```

**Step 2: 验证**
运行: `cd D:/Workspace/ai/mini-play && fvm flutter analyze lib/game_of_life/`
预期: No issues found

---

### Task 2: 核心演化引擎  ✅

**依赖:** T1
**文件:**
- 创建: `lib/game_of_life/game_of_life_game.dart`

**Step 1: 实现核心引擎**

关键接口：
```dart
class HistoryBuffer {
  final List<int> _hashes;
  final List<int> _generations;
  final List<double> _centerXs, _centerYs;
  final List<int> _aliveCounts;

  void push(int hash, int generation, double cx, double cy, int alive);
  int detectPeriod(int currentHash); // 返回周期，0=未检测到
  bool hasCenterShift(int period);   // 周期内中心是否平移（飞船判定）
}

class GameOfLifeGame {
  Uint8List _bufferA, _bufferB;
  late Uint8List current, next;
  final HistoryBuffer _history = HistoryBuffer();

  int generation = 0;
  int aliveCellCount = 0;
  // Bounding box
  int minX, maxX, minY, maxY;
  // 上一代新生细胞（用于高亮渲染）
  Set<(int, int)> newBornCells = {};

  // 核心方法
  void toggleCell(int x, int y);          // 切换单个细胞
  void setCells(Set<(int, int)> cells);   // 批量设置（图案放置）
  void clear();                            // 清空
  void evolve();                           // 演化一代，同时记录 newBornCells

  // 状态查询
  int cellAt(int x, int y);
  bool get isEmpty;
  double get aliveRatio;                   // aliveCellCount / gridSize

  // 历史/检测
  int computeStateHash();                  // FNV-1a 归一化坐标哈希
  int detectPeriod();                      // 当前状态的周期检测
  bool isStillLife();                      // 静物（周期=1）
  bool isOscillator();                     // 振荡器（周期>1, 中心不动）
  bool isSpaceship();                      // 飞船（周期>0, 中心平移）
  int? matchKnownPattern(List<int> knownHashes); // 匹配预设图案哈希，返回索引
}
```

引用 `GameOfLifeConfig.gridWidth/gridHeight/historyCapacity` 常量。

演化算法核心：双缓冲 Uint8List，bounding box 优化扫描，环面取模，展开循环 8 邻居计数。每代结束后交换缓冲区，更新 bounding box、活细胞计数和 newBornCells，push 哈希到历史缓冲区。

**Step 2: 验证**
运行: `cd D:/Workspace/ai/mini-play && fvm flutter analyze lib/game_of_life/game_of_life_game.dart`
预期: No issues found

---

### Task 3: 演化引擎测试  ✅

**依赖:** T2
**文件:**
- 创建: `test/game_of_life/game_of_life_game_test.dart`

**Step 1: 写测试**

测试用例：
```dart
group('GameOfLifeGame', () {
  group('evolve', () {
    test('empty grid stays empty');
    test('block (2x2) is still life - no change after evolve');
    test('blinker oscillates with period 2');
    test('glider moves diagonally after 4 generations');
    test('single cell dies (underpopulation)');
    test('3 cells in L-shape: center survives, corner dies, new cell born');
    test('newBornCells tracks cells born this generation');
  });

  group('toroidal boundary', () {
    test('glider wraps around right edge to left');
    test('glider wraps around bottom edge to top');
  });

  group('detection', () {
    test('isStillLife returns true for block after evolve');
    test('isOscillator returns true for blinker after 2+ generations');
    test('isSpaceship returns true for glider after 4+ generations');
    test('detectPeriod returns 2 for blinker');
    test('detectPeriod returns 4 for glider');
    test('detectPeriod returns 0 for random unstable pattern');
  });

  group('hash', () {
    test('same state produces same hash');
    test('different states produce different hashes');
    test('translated pattern produces same normalized hash (spaceship)');
  });

  group('aliveRatio', () {
    test('returns 0 for empty grid');
    test('returns correct ratio after setting cells');
  });
});
```

**Step 2: 跑测试确认通过**
运行: `cd D:/Workspace/ai/mini-play && fvm flutter test test/game_of_life/`
预期: All tests passed

---

### Task 4: 预设图案数据  ✅

**依赖:** T1
**文件:**
- 创建: `lib/game_of_life/game_of_life_patterns.dart`

**Step 1: 定义图案数据结构和 15 个图案**

```dart
class PatternCategory {
  static const String stillLife = 'still_life';
  static const String oscillator = 'oscillator';
  static const String spaceship = 'spaceship';
  static const String methuselah = 'methuselah';
  static const String gun = 'gun';
}

class GameOfLifePattern {
  final String id;
  final String name;        // 中文名
  final String nameEn;      // 英文名
  final String category;
  final List<(int, int)> cells; // 相对坐标
  final int width, height;
  final String brief;       // 一句话说明（图案库用）
  // 图鉴百科额外信息
  final String? discoverer;
  final int? year;
  final int? period;        // 振荡器周期
  final String? speed;      // 飞船速度如 "c/4"
  final String description; // 详细描述
  final int normalizedHash; // 预计算的归一化哈希（用于沙盒图案识别）
}

// 15 个图案：
// 静物(4): Block, Beehive, Loaf, Boat
// 振荡器(5): Blinker, Toad, Beacon, Pulsar, Pentadecathlon
// 飞船(2): Glider, LWSS
// 长寿(3): R-pentomino, Diehard, Acorn
// 枪(1): Gosper Glider Gun
static const List<GameOfLifePattern> allPatterns = [...];
```

每个图案的坐标数据从 LifeWiki 标准 RLE 格式手动转换为 `(int, int)` 列表。`normalizedHash` 在开发时预计算并硬编码。

**Step 2: 验证**
运行: `cd D:/Workspace/ai/mini-play && fvm flutter analyze lib/game_of_life/game_of_life_patterns.dart`
预期: No issues found

---

### Task 5: CustomPainter 渲染  ✅

**依赖:** T1, T2
**文件:**
- 创建: `lib/game_of_life/game_of_life_painter.dart`

**Step 1: 实现画家**

```dart
class GameOfLifePainter extends CustomPainter {
  final GameOfLifeGame game;
  final double cellSize;
  final int paintVersion;          // 用于 shouldRepaint
  final Set<(int, int)>? previewCells; // 图案放置预览
  final Set<(int, int)>? lockedCells;  // 挑战锁定细胞

  @override
  void paint(Canvas canvas, Size size) {
    // 1. 背景已由容器处理
    // 2. 画网格线（仅当 cellSize > gridLineThreshold）
    // 3. 遍历 bounding box 范围画活细胞（合并为 Path 一次 drawPath）
    //    - 新生细胞（game.newBornCells）：cellNew
    //    - 锁定细胞：cellLocked
    //    - 普通细胞：cellAlive
    // 4. 画预览细胞（半透明）
  }

  @override
  bool shouldRepaint(GameOfLifePainter old) => old.paintVersion != paintVersion;
}

/// 小尺寸缩略图画家（图鉴列表和挑战关卡预览用）
class PatternThumbnailPainter extends CustomPainter {
  final List<(int, int)> cells;
  final Color color;
  // 根据 cells 的 bounding box 自动缩放到 canvas 大小
}
```

关键优化：同色细胞用 `Path.addRect()` 合并，一次 `canvas.drawPath()` 提交。

**Step 2: 验证**
运行: `cd D:/Workspace/ai/mini-play && fvm flutter analyze lib/game_of_life/game_of_life_painter.dart`
预期: No issues found

---

### Task 6: 共享 UI 组件  ✅

**依赖:** T1, T4
**文件:**
- 创建: `lib/game_of_life/game_of_life_widgets.dart`

**Step 1: 实现共享组件**

```dart
// 顶部信息栏（代数 + 活细胞数 + 运行状态）
class GameOfLifeInfoBar extends StatelessWidget {
  final int generation;
  final int aliveCells;
  final bool isRunning;
  final int speedIndex;
}

// 底部控制栏（沙盒模式 5 按钮）
class GameOfLifeControlBar extends StatelessWidget {
  final bool isRunning;
  final int speedIndex;
  final InteractionMode interactionMode;
  final VoidCallback onTogglePlay;
  final VoidCallback onStep;
  final VoidCallback onSpeedChange;
  final VoidCallback onClear;
  final VoidCallback onPatternLibrary;
  final VoidCallback onToggleDrawMode;
}

// 图案库面板（DraggableScrollableSheet）
// 点击图案库按钮 toggle 展开/折叠（Web 端备用交互）
class PatternLibrarySheet extends StatefulWidget {
  final List<GameOfLifePattern> patterns;
  final void Function(GameOfLifePattern) onSelect;
}

// 图案放置工具条（旋转/确认/取消）
class PatternPlacementBar extends StatelessWidget {
  final VoidCallback onRotate;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final int rotation; // 0/1/2/3 × 90°
}
```

**Step 2: 验证**
运行: `cd D:/Workspace/ai/mini-play && fvm flutter analyze lib/game_of_life/game_of_life_widgets.dart`
预期: No issues found

---

### Task 7a: 核心沙盒页面  ✅

**依赖:** T2, T4, T5, T6
**文件:**
- 创建: `lib/game_of_life/game_of_life_page.dart`

**Step 1: 实现沙盒核心**

核心结构：
```dart
class GameOfLifePage extends StatefulWidget {
  final GameOfLifePattern? initialPattern; // 从图鉴跳转时带入
}

class _GameOfLifePageState extends State<GameOfLifePage>
    with SingleTickerProviderStateMixin {
  late GameOfLifeGame _game;
  late Ticker _ticker;
  final _transformController = TransformationController();
  final _generationNotifier = ValueNotifier<int>(0);

  // 状态
  bool _isRunning = false;
  InteractionMode _interactionMode = InteractionMode.draw;
  int _speedIndex = 1;           // 默认"中"
  int _paintVersion = 0;
  Duration _lastElapsed = Duration.zero;
  double _accumulator = 0;
  bool? _dragIsDrawing;          // 拖拽方向：true=画，false=擦，null=未开始
}
```

**关键技术方案：**

**手势系统（Listener 替代 GestureDetector，避免手势竞技场冲突）：**
```dart
InteractiveViewer(
  transformationController: _transformController,
  constrained: false,
  panEnabled: _interactionMode == InteractionMode.pan,
  scaleEnabled: true, // 双指缩放始终可用
  minScale: GameOfLifeConfig.minScale,
  maxScale: GameOfLifeConfig.maxScale,
  boundaryMargin: EdgeInsets.all(max(screenWidth, screenHeight) * 0.5),
  child: Listener(
    onPointerDown: _interactionMode == InteractionMode.draw ? _onPointerDown : null,
    onPointerMove: _interactionMode == InteractionMode.draw ? _onPointerMove : null,
    onPointerUp: _interactionMode == InteractionMode.draw ? _onPointerUp : null,
    child: SizedBox(
      width: cellSize * GameOfLifeConfig.gridWidth,
      height: cellSize * GameOfLifeConfig.gridHeight,
      child: CustomPaint(painter: GameOfLifePainter(...)),
    ),
  ),
)
```

**Toggle 语义 + 首格方向决定画/擦：**
```dart
void _onPointerDown(PointerDownEvent e) {
  final (gx, gy) = _screenToGrid(e.localPosition);
  final isAlive = _game.cellAt(gx, gy) == 1;
  _dragIsDrawing = !isAlive; // 首格为空→后续画；首格有→后续擦
  _game.toggleCell(gx, gy);
  _incrementPaintVersion();
}
void _onPointerMove(PointerMoveEvent e) {
  final (gx, gy) = _screenToGrid(e.localPosition);
  final isAlive = _game.cellAt(gx, gy) == 1;
  if (_dragIsDrawing == true && !isAlive) { _game.toggleCell(gx, gy); ... }
  if (_dragIsDrawing == false && isAlive) { _game.toggleCell(gx, gy); ... }
}
```

**Ticker + 速度 + 每帧多代限制：**
```dart
void _onTick(Duration elapsed) {
  if (!_isRunning) { _lastElapsed = elapsed; return; }
  final dt = (elapsed - _lastElapsed).inMicroseconds / 1e6;
  _lastElapsed = elapsed;
  _accumulator += dt;

  final stepInterval = 1.0 / GameOfLifeConfig.speedLevels[_speedIndex];
  final maxSteps = kIsWeb
      ? GameOfLifeConfig.maxStepsPerFrameWeb
      : GameOfLifeConfig.maxStepsPerFrameNative;
  int steps = 0;
  while (_accumulator >= stepInterval && steps < maxSteps) {
    _game.evolve();
    _accumulator -= stepInterval;
    steps++;
    // 自动暂停：活细胞占比超过 50%
    if (_game.aliveRatio >= GameOfLifeConfig.pauseThreshold) {
      _isRunning = false;
      _showAutoPauseSnackbar();
      break;
    }
  }
  if (steps > 0) {
    _generationNotifier.value = _game.generation;
    _incrementPaintVersion();
  }
}
```

**Ticker pause/resume：** `_onPause` 时 `_ticker.stop()`，`_onResume` 时 `_ticker.start()` + `_lastElapsed = Duration.zero`。

**GameScaffold 适配：**
```dart
GameScaffold(
  title: 'Game of Life',
  scoreNotifier: _generationNotifier,
  bestScore: _game.aliveCellCount, // 每帧 setState 更新
  scoreLabel: 'Gen',
  bestLabel: 'Cells',
  bestFormatter: (n) => '${_game.aliveCellCount}',
  onPause: _onPause,
  onResume: _onResume,
  child: Column(children: [Expanded(canvas), ControlBar]),
)
```

**沙盒最高代数持久化：** dispose 时或暂停时调用 `ScoreService().saveHighScore('gameoflife', 'sandbox', _game.generation)`。

**Step 2: 验证**
运行: `cd D:/Workspace/ai/mini-play && fvm flutter run -d chrome`
手动验证: 能画细胞（toggle 语义）、播放/暂停/单步、速度切换、清空（二次确认）、画笔/移动切换、boundaryMargin 正常、环面边界正常

---

### Task 7b: 图案放置功能  ✅

**依赖:** T7a, T4
**文件:**
- 修改: `lib/game_of_life/game_of_life_page.dart`

**Step 1: 添加图案放置功能**

- 图案库面板：底栏图案库按钮点击展开 DraggableScrollableSheet（同时支持点击 toggle 展开/折叠）
- 选中图案后：`_interactionMode = InteractionMode.placingPattern`
- 画布上 Listener 事件改为：移动=更新预览位置（吸附网格），点击=确认放置
- 底栏切换为 PatternPlacementBar（旋转/确认/取消）
- 旋转：90° 步进，转换 cells 坐标 `(x, y) → (y, -x)`
- 确认放置：`_game.setCells(rotatedCells)`，退出放置模式
- 取消：退出放置模式，回到画笔模式
- 预览渲染：传 `previewCells` 给 Painter

**Step 2: 验证**
运行: `cd D:/Workspace/ai/mini-play && fvm flutter run -d chrome`
手动验证: 打开图案库、选择图案、预览跟随手指、旋转、确认放置、取消放置

---

### Task 8a: 挑战关卡定义  ✅

**依赖:** T1, T4
**文件:**
- 创建: `lib/game_of_life/game_of_life_challenges.dart`

**Step 1: 定义关卡数据结构和 15 关**

```dart
enum ChallengeGoalType {
  stillLife,      // 达成静物
  oscillator,     // 达成振荡器
  spaceship,      // 达成飞船
  survive,        // 存活超过 N 代
  extinct,        // N 代内全部消亡
  population,     // N 代后活细胞数达标
  oscillatorMinPeriod, // 达成周期 >= N 的振荡器
}

class ChallengeLevel {
  final int id;                    // 1-15
  final String title;              // 自然语言标题
  final String description;        // 目标描述（自然语言）
  final Set<(int, int)> initialCells;   // 初始细胞
  final Set<(int, int)> lockedCells;    // 不可编辑区域
  final Set<(int, int)>? editableArea;  // 可编辑区域限制（null=无限制）
  final ChallengeGoalType goalType;
  final int goalParam;             // N 值
  final int maxGenerations;        // 最大运行代数
  final List<int> starThresholds;  // [3星, 2星, 1星] 的最大细胞数
  final String? hintPatternId;     // 关联图鉴图案 ID
  final List<String>? tutorialSteps; // 前 2 关教学提示步骤
}

static const List<ChallengeLevel> levels = [...]; // 15 关
```

关卡 1-2 的 `tutorialSteps` 包含教学文字（如"提示：静物是指不再变化的图案。试试放一个 2×2 的方块"）。

**Step 2: 验证**
运行: `cd D:/Workspace/ai/mini-play && fvm flutter analyze lib/game_of_life/game_of_life_challenges.dart`
预期: No issues found

---

### Task 8b: 挑战运行器  ✅

**依赖:** T1, T2, T8a
**文件:**
- 创建: `lib/game_of_life/game_of_life_challenge_runner.dart`

**Step 1: 实现挑战运行器**

```dart
enum ChallengeState { editing, running, success, failed }

class ChallengeRunner {
  final ChallengeLevel level;
  final GameOfLifeGame game;
  ChallengeState state = ChallengeState.editing;
  int userCellCount = 0;      // 用户放置的细胞数
  int stars = 0;
  String? failReason;         // 失败原因

  void start();               // editing → running
  void tick();                 // 每帧调用，检查目标和终止条件
  bool _checkGoal();           // 根据 goalType 检查
  bool _checkTimeout();        // 超过 maxGenerations → failed
  int _calcStars();            // userCellCount vs starThresholds

  /// 跳过动画快进到结果（批处理 + yield 不阻塞 UI）
  Future<void> skipToResult(VoidCallback onProgress) async {
    while (state == ChallengeState.running) {
      for (int i = 0; i < 50 && state == ChallengeState.running; i++) {
        tick();
      }
      onProgress(); // 更新 UI
      await Future.delayed(Duration.zero); // 让出事件循环
    }
  }

  /// 编辑时校验：不能修改 lockedCells
  bool canEditCell(int x, int y);
}
```

**Step 2: 验证**
运行: `cd D:/Workspace/ai/mini-play && fvm flutter analyze lib/game_of_life/game_of_life_challenge_runner.dart`
预期: No issues found

---

### Task 9: 挑战运行器测试  ✅

**依赖:** T8b
**文件:**
- 创建: `test/game_of_life/game_of_life_challenge_test.dart`

**Step 1: 写测试**

```dart
group('ChallengeRunner', () {
  test('level 1: placing block cells achieves still life goal');
  test('level 2: placing blinker cells achieves oscillator goal');
  test('level 3: placing glider cells achieves spaceship goal');
  test('level 4: correct placement causes extinction within 5 generations');
  test('level 5: pattern survives beyond 10 generations');
  test('timeout triggers failed state when maxGenerations exceeded');
  test('star calculation: fewer cells = more stars');
  test('editing state: can add/remove cells on non-locked positions');
  test('editing state: cannot modify locked cells');
  test('skipToResult completes without blocking');
});
```

**Step 2: 跑测试确认通过**
运行: `cd D:/Workspace/ai/mini-play && fvm flutter test test/game_of_life/`
预期: All tests passed

---

### Task 10: 挑战模式页面  ✅

**依赖:** T5, T6, T8b
**文件:**
- 创建: `lib/game_of_life/game_of_life_challenge_page.dart`

**Step 1: 实现挑战页面**

两个视图合在一个文件中：

**关卡列表视图：**
- ListView 显示 15 关，每关卡片含：序号、标题、目标描述、目标图案小预览（PatternThumbnailPainter）、星级
- 未通关显示灰色星星，已通关显示金色
- 通过 ScoreService 加载每关最佳细胞数，动态计算星级
- 点击进入关卡游玩视图

**关卡游玩视图：**
- 复用 GameOfLifePainter 渲染网格（锁定细胞蓝色，用户细胞绿色）
- 前 2 关：如有 `tutorialSteps`，编辑阶段显示步骤提示 overlay
- 顶部：关卡标题 + 目标描述 + 目标进度（运行时显示，如"目标：存活 10 代 | 当前：第 3 代"）
- 底部：编辑状态显示"确认运行"按钮 + 已用细胞计数；运行状态显示进度 + "跳过"按钮
- ChallengeRunner 驱动状态机
- 成功时：弹出星级动画 + 保存分数
- 失败时：显示 `failReason` + "重试"按钮
- InteractiveViewer 聚焦到关卡活跃区域（初始 zoom 适配关卡大小）

**ScoreService 持久化方案：**
- 每关存 best cell count：`ScoreService().saveHighScore('gameoflife', 'challenge_$id', userCellCount, lowerIsBetter: true)`
- 星级从 cell count + starThresholds 动态计算，不额外存储
- 模式选择页总星数从 15 关动态加总

**Step 2: 验证**
运行: `cd D:/Workspace/ai/mini-play && fvm flutter run -d chrome`
手动验证: 关卡列表、进入关卡、编辑、前 2 关教学提示、运行演化、目标进度、跳过快进、成功/失败、星级评分

---

### Task 11: 图鉴百科页面  ✅

**依赖:** T2, T4, T5
**文件:**
- 创建: `lib/game_of_life/game_of_life_encyclopedia_page.dart`

**Step 1: 实现图鉴页面**

两个视图：

**图案列表视图：**
- 顶部：可滚动 FilterChip 分类栏（全部/静物/振荡器/飞船/长寿/枪）
- GridView 两列，每个图案卡片含：静态缩略图（PatternThumbnailPainter）、名称（中英）、一句话说明
- hover/长按播放预览动画：`MouseRegion(onEnter/onExit)` + `GestureDetector(onLongPress)` 触发缩略图变为小型动画（共享 Ticker，只对当前 hover/长按的卡片播放）
- 点击进入详情视图

**图案详情视图：**
- 上半（50-60%）：大画布自动播放演化动画（用 Ticker + 小型 GameOfLifeGame 实例 + 画家）
- 下半：信息卡片
  - 元数据 key-value 布局：周期/速度、细胞数、发现者、年份
  - 特性描述段落
- 底部固定按钮："在沙盒中打开"

**Step 2: 验证**
运行: `cd D:/Workspace/ai/mini-play && fvm flutter run -d chrome`
手动验证: 分类浏览、hover/长按预览动画、详情页动画、在沙盒中打开

---

### Task 12: 模式选择页 + 项目集成  ✅

**依赖:** T7a, T10, T11
**文件:**
- 创建: `lib/game_of_life/game_of_life_mode_page.dart`
- 修改: `lib/home/game_registry.dart`
- 修改: `lib/main.dart`

**Step 1: 实现模式选择页**

使用 GameModeCard 组件：
```dart
GameModeCard(
  title: '沙盒',
  description: '自由创作，探索生命演化',
  icon: Icons.brush,
  accent: GameOfLifeColors.cellAlive,
  gameName: GameOfLifeConfig.gameName,
  scoreKey: 'sandbox',
  route: '/gameoflife/sandbox',
  bestFormatter: (gen) => gen > 0 ? 'Gen $gen' : '',
),
GameModeCard(
  title: '挑战',
  description: '15 关目标挑战',
  icon: Icons.emoji_events,
  accent: Colors.amber,
  gameName: GameOfLifeConfig.gameName,
  scoreKey: 'challenge_total', // 动态加总写入
  route: '/gameoflife/challenge',
  bestFormatter: (stars) => stars > 0 ? '$stars ⭐' : '',
),
GameModeCard(
  title: '图鉴百科',
  description: '探索经典图案',
  icon: Icons.auto_stories,
  accent: Colors.blueAccent,
  gameName: GameOfLifeConfig.gameName,
  scoreKey: 'encyclopedia',
  route: '/gameoflife/encyclopedia',
  bestFormatter: (_) => '', // 无分数概念，隐藏
),
```

挑战模式总星数：模式页 initState 时从 15 关动态计算并写入 `challenge_total`。

**Step 2: 注册到 GameRegistry**

```dart
GameInfo(
  name: 'Game of Life',
  icon: Icons.grid_on,
  description: '生命游戏 - 细胞自动机模拟器',
  phase: 4,
  route: '/gameoflife',
  implemented: true,
  hasModePage: true,
),
```

**Step 3: 注册路由**

在 `main.dart` 添加 4 条路由：
- `/gameoflife` → GameOfLifeModePage
- `/gameoflife/sandbox` → GameOfLifePage（接收可选 `GameOfLifePattern?` 参数）
- `/gameoflife/challenge` → GameOfLifeChallengePage
- `/gameoflife/encyclopedia` → GameOfLifeEncyclopediaPage（接收可选 `String? patternId` 参数）

**Step 4: 验证**
运行: `cd D:/Workspace/ai/mini-play && fvm flutter run -d chrome`
手动验证: 主页看到 Game of Life 卡片，模式选择页三个卡片正常，三个模式都能跳转

---

### Task 13: 新手引导  ✅

**依赖:** T7a
**文件:**
- 修改: `lib/game_of_life/game_of_life_page.dart`

**Step 1: 添加首次进入引导 overlay**

使用 SharedPreferences 记录（key: `gameoflife_onboarding_shown`）。

引导步骤（4 步 overlay）：
1. "点击格子创建或删除生命细胞" — 高亮画布中央区域
2. "按播放按钮，观察细胞按规则演化" — 高亮播放按钮
3. "从图案库选择经典图案放到画布上" — 高亮图案库按钮
4. "切换移动模式来平移和缩放画布" — 高亮模式切换按钮

实现为 Stack overlay widget，"下一步"/"跳过"/"知道了"。

**Step 2: 验证**
运行: `cd D:/Workspace/ai/mini-play && fvm flutter run -d chrome`
手动验证: 首次进入沙盒看到引导，完成后不再显示

---

### Task 14: 模式间流转 + 收尾  ✅

**依赖:** 全部
**文件:**
- 修改: `lib/game_of_life/game_of_life_page.dart`（接收图案参数 + 图案识别提示）
- 修改: `lib/game_of_life/game_of_life_challenge_page.dart`（跳转图鉴链接）
- 修改: `lib/game_of_life/game_of_life_encyclopedia_page.dart`（在沙盒中打开）

**Step 1: 实现跨模式跳转**

- 图鉴详情 → 沙盒：`Navigator.pushReplacementNamed('/gameoflife/sandbox', arguments: pattern)`
- 挑战关卡 → 图鉴：如有 `hintPatternId`，显示"查看目标图案"链接，`Navigator.pushNamed('/gameoflife/encyclopedia', arguments: patternId)`
- 沙盒接收 pattern 参数时：自动进入放置模式，预览居中

**Step 2: 沙盒图案识别提示**

在沙盒中，演化暂停或检测到静物/振荡器时：
- 将当前状态归一化哈希与 `allPatterns` 的 `normalizedHash` 比对
- 匹配时显示 SnackBar："检测到 XX 图案" + "查看图鉴"按钮
- 点击跳转 `Navigator.pushNamed('/gameoflife/encyclopedia', arguments: patternId)`
- 只在首次匹配到新图案时提示（避免重复提示）

**Step 3: 最终全量验证**
运行:
```bash
cd D:/Workspace/ai/mini-play
fvm flutter analyze lib/game_of_life/
fvm flutter test test/game_of_life/
fvm flutter run -d chrome
```

手动验证清单:
- [ ] 主页看到 Game of Life
- [ ] 模式选择页三个卡片正常显示
- [ ] 沙盒：画细胞（toggle 语义，首格方向决定画/擦）、播放/暂停/单步、速度切换、清空
- [ ] 沙盒：画笔/移动模式切换
- [ ] 沙盒：图案库打开、选择图案、旋转、放置
- [ ] 沙盒：演化运行中可编辑细胞
- [ ] 沙盒：新手引导首次显示
- [ ] 沙盒：活细胞 50% 自动暂停
- [ ] 沙盒：检测到已知图案时提示气泡
- [ ] 沙盒：最高代数持久化
- [ ] 挑战：关卡列表、星级显示
- [ ] 挑战：进入关卡、编辑、前 2 关教学提示
- [ ] 挑战：运行演化、目标进度、跳过快进
- [ ] 挑战：成功/失败、星级评分、ScoreService 持久化
- [ ] 图鉴：分类浏览、hover/长按预览动画
- [ ] 图鉴：详情页动画、在沙盒中打开
- [ ] 跨模式跳转正常（图鉴→沙盒、挑战→图鉴）
- [ ] 环面边界：Glider 穿越边界正常
- [ ] Web 端每帧最多 3 代演化
