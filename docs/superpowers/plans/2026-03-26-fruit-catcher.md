# Fruit Catcher 实现计划

**目标:** 实现水果接住游戏，包含经典/限时/无尽三种模式，Combo 系统，渐近式难度曲线
**架构:** 遵循 Breakout 模式——Config/Models/Colors 定义数据，Game 管理逻辑，Painter 渲染 Canvas，Page 处理 Ticker 和输入，GameScaffold 包裹 UI
**技术栈:** Flutter CustomPaint + Ticker，归一化坐标系（3:4 竖屏）
**设计文档:** docs/superpowers/specs/2026-03-26-fruit-catcher-design.md
**新增依赖:** 无
**测试模式:** 非 TDD — 通过运行游戏验证

---

### Task 1: Config + Models + Colors（基础数据层）  ✅

**文件:**
- 创建: `lib/fruit_catcher/fruit_catcher_config.dart`
- 创建: `lib/fruit_catcher/fruit_catcher_models.dart`
- 创建: `lib/fruit_catcher/fruit_catcher_colors.dart`

**Step 1: fruit_catcher_config.dart**

定义模式枚举、配置类、难度公式、世界坐标系：

```dart
enum FruitCatcherMode { classic, timed, endless }

class FruitCatcherConfig {
  // 世界坐标系（与 Breakout 一致）
  static const double aspectRatio = 3 / 4;
  static const double worldWidth = aspectRatio; // 0.75
  static const double worldHeight = 1.0;

  // 模式参数
  final int lives;           // 经典: 5, 限时/无尽: 0(不用)
  final int maxLives;
  final double timeLimit;    // 限时: 60.0, 其他: 0(不用)
  final int bombPenalty;     // 限时: -2, 其他: 0
  final bool bombInstantDeath; // 无尽: true

  // 难度初始参数
  final double initialSpawnInterval;
  final double minSpawnInterval;
  final double initialFallSpeed;
  final double maxFallSpeedMultiplier;
  final double initialBombRatio;
  final double maxBombRatio;

  // 难度曲线常数 k1-k4
  final double k1, k2, k3, k4;

  // Combo 加时（限时模式）
  final int comboStreakForBonus;  // 连续接住 5 个
  final double comboBonusTime;   // +2 秒

  // 波次设置（无尽模式）
  final double wavePauseDuration; // 2 秒
  final int itemsPerWave;         // 基础每波数量

  // 开局保护
  final int protectedSpawns;     // 前 5 个保证水果

  // 命恢复（经典模式）
  final int streakForLifeRecovery; // 连续 20 个恢复 1 命

  // 篮子参数
  static const double basketY = 0.92;
  static const double basketWidth = 0.12;
  static const double basketHeight = 0.03;

  // 物体尺寸
  static const double fruitRadius = 0.018;
  static const double bombRadius = 0.02;

  // 键盘速度
  static const double keyboardSpeed = 0.8; // 归一化单位/秒

  static FruitCatcherConfig forMode(FruitCatcherMode mode) { ... }
}
```

三种模式的工厂方法参数：

| 参数 | Classic | Timed | Endless |
|------|---------|-------|---------|
| lives | 5 | 0 | 0 |
| maxLives | 5 | 0 | 0 |
| timeLimit | 0 | 60.0 | 0 |
| bombPenalty | 0 | 2 | 0 |
| bombInstantDeath | false | false | true |
| initialSpawnInterval | 0.8 | 0.8 | 0.6 |
| minSpawnInterval | 0.3 | 0.3 | 0.3 |
| initialFallSpeed | 0.33 | 0.33 | 0.40 |
| maxFallSpeedMultiplier | 2.0 | 2.0 | 2.0 |
| initialBombRatio | 0.10 | 0.10 | 0.15 |
| maxBombRatio | 0.20 | 0.20 | 0.20 |
| comboStreakForBonus | 0 | 5 | 0 |
| comboBonusTime | 0 | 2.0 | 0 |
| wavePauseDuration | 0 | 0 | 2.0 |
| itemsPerWave | 0 | 0 | 15 |
| protectedSpawns | 5 | 5 | 5 |
| streakForLifeRecovery | 20 | 0 | 0 |

难度公式方法：

```dart
double spawnInterval(double level) =>
    minSpawnInterval + (initialSpawnInterval - minSpawnInterval) / (1 + level * k1);

double fallSpeed(double level) =>
    initialFallSpeed * (1 + level * k2 / (1 + level * k3));

double bombRatio(double level) =>
    initialBombRatio + (maxBombRatio - initialBombRatio) * level / (level + k4);
```

**Step 2: fruit_catcher_models.dart**

```dart
enum FruitType { red, orange, yellow, green, purple }

class FruitItem {
  double x, y;
  double speed;       // 当前下落速度
  final bool isBomb;
  final FruitType? fruitType;  // null if bomb

  bool get isOffScreen => y > FruitCatcherConfig.worldHeight + FruitCatcherConfig.fruitRadius;
  double get radius => isBomb ? FruitCatcherConfig.bombRadius : FruitCatcherConfig.fruitRadius;
}

class Basket {
  double x;           // 中心 x
  double targetX;     // 目标 x（用于 lerp）
  double get y => FruitCatcherConfig.basketY;
  double get width => FruitCatcherConfig.basketWidth;
  double get height => FruitCatcherConfig.basketHeight;
}

class FloatingText {
  double x, y;
  double age;          // 已存活时间
  final String text;
  final Color color;
  static const double duration = 0.8; // 总持续时间
  double get alpha => (1.0 - age / duration).clamp(0.0, 1.0);
  bool get isDead => age >= duration;
}
```

**Step 3: fruit_catcher_colors.dart**

```dart
class FruitCatcherColors {
  static const Color background = Color(0xFF1A1A2E);
  static const Color basketBase = Color(0xFF8B5E3C);    // 棕色篮子
  static const Color basketHighlight = Color(0xFFD4A574);

  // 水果颜色 by FruitType
  static const Map<FruitType, Color> fruitColors = {
    FruitType.red:    Color(0xFFE84545),
    FruitType.orange: Color(0xFFF0A040),
    FruitType.yellow: Color(0xFFF0D040),
    FruitType.green:  Color(0xFF4ECCA3),
    FruitType.purple: Color(0xFFBB86FC),
  };

  static const Color bomb = Color(0xFF2A2A2A);
  static const Color bombFlash = Color(0xFFE84545);
  static const Color comboText = Color(0xFFF0C040);
  static const Color scoreFloat = Color(0xFF4ECCA3);
  static const Color penaltyFloat = Color(0xFFE84545);
  static const Color hudText = Colors.white70;
}
```

**验证:** `fvm flutter analyze lib/fruit_catcher/` — 无错误

---

### Task 2: 碰撞检测  ✅

**文件:**
- 创建: `lib/fruit_catcher/fruit_catcher_collision.dart`

碰撞检测极简——只需 AABB 矩形碰撞（水果/炸弹底部 vs 篮子顶部）：

```dart
class FruitCatcherCollision {
  /// 检测掉落物是否被篮子接住
  /// item 用外接矩形，basket 用矩形
  static bool caught(FruitItem item, Basket basket) {
    final ix = item.x - item.radius;
    final iy = item.y - item.radius;
    final iw = item.radius * 2;
    final ih = item.radius * 2;
    final bx = basket.x - basket.width / 2;
    final by = basket.y - basket.height / 2;
    return ix < bx + basket.width && ix + iw > bx &&
           iy < by + basket.height && iy + ih > by;
  }
}
```

**验证:** `fvm flutter analyze lib/fruit_catcher/fruit_catcher_collision.dart` — 无错误

---

### Task 3: 游戏核心逻辑  ✅

**文件:**
- 创建: `lib/fruit_catcher/fruit_catcher_game.dart`

这是最核心的文件，包含所有游戏状态和 update 逻辑。

**核心状态:**

```dart
class FruitCatcherGame {
  final FruitCatcherConfig config;
  final FruitCatcherMode mode;
  final Random _rng = Random();

  late Basket basket;
  List<FruitItem> items = [];
  List<FloatingText> floatingTexts = [];

  // 计分
  int score = 0;
  int combo = 0;           // 当前连击数
  int maxCombo = 0;        // 最高连击
  int fruitsCaught = 0;    // 接住水果总数
  int totalSpawned = 0;    // 生成总数（不含炸弹）
  int bombsDodged = 0;     // 成功躲开的炸弹数

  // 难度
  double difficultyLevel = 0;
  double spawnTimer = 0;

  // 模式专属
  int lives = 0;           // 经典
  double timeRemaining = 0; // 限时
  int wave = 1;            // 无尽
  int waveItemsRemaining = 0;
  double wavePauseTimer = 0;
  int consecutiveCatches = 0; // 用于命恢复和加时

  // 保护期
  int protectedRemaining = 0;

  // 视觉状态
  double elapsed = 0;      // 总时间（用于闪烁动画）
  double shakeTimer = 0;
  double redFlashTimer = 0;
  double basketSquash = 0; // 篮子压缩动画

  // 游戏状态
  bool isGameOver = false;

  // 统计
  double survivalTime = 0; // 存活时间
}
```

**关键方法:**

```dart
// 构造函数：初始化篮子、生命、时间等
FruitCatcherGame({required this.config, required this.mode}) {
  basket = Basket(x: worldWidth / 2, targetX: worldWidth / 2);
  lives = config.lives;
  timeRemaining = config.timeLimit;
  protectedRemaining = config.protectedSpawns;
  if (mode == FruitCatcherMode.endless) {
    waveItemsRemaining = config.itemsPerWave;
  }
}

// 主更新循环
void update(double dt) {
  if (isGameOver) return;
  elapsed += dt;
  survivalTime += dt;

  // 更新篮子位置（lerp）
  _updateBasket(dt);

  // 更新难度等级
  _updateDifficulty(dt);

  // 无尽模式波次暂停
  if (wavePauseTimer > 0) { wavePauseTimer -= dt; return; }

  // 限时模式倒计时
  if (mode == FruitCatcherMode.timed) {
    timeRemaining -= dt;
    if (timeRemaining <= 0) { timeRemaining = 0; isGameOver = true; return; }
  }

  // 生成新物体
  _updateSpawning(dt);

  // 更新所有掉落物
  _updateItems(dt);

  // 碰撞检测
  _checkCollisions();

  // 清理离屏物体 + 漏接处理
  _cleanupItems();

  // 更新浮字
  _updateFloatingTexts(dt);

  // 更新视觉效果计时器
  _updateEffects(dt);
}

// 篮子移动（键盘）
void moveBasketByKeys(Set<String> keysPressed, double dt) {
  double dx = 0;
  for (final key in keysPressed) {
    if (key == 'left') dx -= FruitCatcherConfig.keyboardSpeed * dt;
    if (key == 'right') dx += FruitCatcherConfig.keyboardSpeed * dt;
  }
  if (dx != 0) {
    basket.targetX = (basket.targetX + dx).clamp(
      basket.width / 2, FruitCatcherConfig.worldWidth - basket.width / 2);
  }
}

// 篮子移动（触摸/鼠标相对位移）
void moveBasketRelative(double dx) {
  basket.targetX = (basket.targetX + dx).clamp(
    basket.width / 2, FruitCatcherConfig.worldWidth - basket.width / 2);
}

// 篮子移动（鼠标绝对位置）
void moveBasketTo(double x) {
  basket.targetX = x.clamp(
    basket.width / 2, FruitCatcherConfig.worldWidth - basket.width / 2);
}
```

**难度更新逻辑（`_updateDifficulty`）:**
- 经典: `difficultyLevel = fruitsCaught / 10.0`
- 限时: `difficultyLevel = (config.timeLimit - timeRemaining) / 10.0`
- 无尽: `difficultyLevel = (wave - 1).toDouble()`

**生成逻辑（`_updateSpawning`）:**
- 累加 `spawnTimer += dt`
- 当 `spawnTimer >= config.spawnInterval(difficultyLevel)` 时生成
- 保护期内强制水果，否则按 `config.bombRatio(difficultyLevel)` 概率生成炸弹
- x 位置随机 `[radius, worldWidth - radius]`
- 下落速度 = `config.fallSpeed(difficultyLevel)`
- 无尽模式递减 `waveItemsRemaining`，归 0 时触发波次暂停

**碰撞处理（`_checkCollisions`）:**
- 遍历 items，对每个检测 `FruitCatcherCollision.caught(item, basket)`
- 接住水果: `combo++`, 计算 combo 分值, `score += comboScore`, 添加浮字, 触发篮子压缩动画
- 接住炸弹: 根据模式处理（经典扣命/限时扣分/无尽结束），`combo = 0`, 触发红闪
- Combo 分值映射: `[1,1,1,2,2,3,3,5,5,8,...]`（斐波那契风格递增）

**漏接处理（`_cleanupItems`）:**
- 水果离屏: 经典模式扣命 + 屏幕抖动，`combo = 0`
- 炸弹离屏: `bombsDodged++`（统计用）

**Combo 加时（限时模式）:**
- `consecutiveCatches++`，每达到 `config.comboStreakForBonus` 次：`timeRemaining += config.comboBonusTime`

**命恢复（经典模式）:**
- `consecutiveCatches` 每达到 `config.streakForLifeRecovery` 且 `lives < maxLives`：`lives++`

**验证:** `fvm flutter analyze lib/fruit_catcher/fruit_catcher_game.dart` — 无错误

---

### Task 4: Painter 渲染  ✅

**文件:**
- 创建: `lib/fruit_catcher/fruit_catcher_painter.dart`

**绘制顺序:**

1. 背景（纯色）
2. 掉落物（水果圆形 + 炸弹闪烁圆形）
3. 篮子（梯形，带压缩动画）
4. 浮字（+N 上飘，-2 红色）
5. HUD（连击数、倒计时/命数/波次）
6. 效果叠加层（红闪、屏幕抖动通过 canvas.translate）

**关键渲染模式:**

```dart
class FruitCatcherPainter extends CustomPainter {
  final FruitCatcherGame game;
  final int paintVersion;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.height; // 缩放因子

    // 屏幕抖动
    if (game.shakeTimer > 0) {
      final intensity = game.shakeTimer * 8.0;
      canvas.translate(
        (game._rng.nextDouble() - 0.5) * intensity,
        (game._rng.nextDouble() - 0.5) * intensity,
      );
    }

    // 1. 背景
    _drawBackground(canvas, size);

    // 2. 掉落物
    for (final item in game.items) {
      if (item.isBomb) {
        _drawBomb(canvas, item, s);
      } else {
        _drawFruit(canvas, item, s);
      }
    }

    // 3. 篮子（梯形）
    _drawBasket(canvas, s);

    // 4. 浮字
    for (final ft in game.floatingTexts) {
      _drawFloatingText(canvas, ft, s);
    }

    // 5. HUD
    _drawHUD(canvas, size);

    // 6. 红闪叠加
    if (game.redFlashTimer > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.red.withValues(alpha: game.redFlashTimer * 0.3),
      );
    }
  }

  void _drawBomb(Canvas canvas, FruitItem item, double s) {
    // 闪烁: alpha 在 0.6-1.0 之间用 sin 调制
    final alpha = 0.8 + 0.2 * sin(game.elapsed * 8.0);
    canvas.drawCircle(
      Offset(item.x * s, item.y * s),
      item.radius * s,
      Paint()..color = FruitCatcherColors.bomb.withValues(alpha: alpha),
    );
    // 红色光晕
    canvas.drawCircle(
      Offset(item.x * s, item.y * s),
      item.radius * s * 1.3,
      Paint()
        ..color = FruitCatcherColors.bombFlash.withValues(alpha: 0.15 * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  void _drawBasket(Canvas canvas, double s) {
    // 梯形篮子，竖向压缩动画
    final squash = game.basketSquash > 0 ? 0.8 : 1.0;
    // 用 Path 画梯形
    final path = Path();
    final bx = game.basket.x * s;
    final by = game.basket.y * s;
    final hw = game.basket.width * s / 2;
    final hh = game.basket.height * s * squash / 2;
    // 上宽 > 下宽的梯形
    path.moveTo(bx - hw, by - hh);       // 左上
    path.lineTo(bx + hw, by - hh);       // 右上
    path.lineTo(bx + hw * 0.7, by + hh); // 右下
    path.lineTo(bx - hw * 0.7, by + hh); // 左下
    path.close();
    canvas.drawPath(path, Paint()..color = FruitCatcherColors.basketBase);
  }

  void _drawHUD(Canvas canvas, Size size) {
    // 根据模式绘制不同 HUD
    // 经典: 底部左侧画命数（心形或圆形）
    // 限时: 顶部中央画倒计时
    // 无尽: 底部右侧画波次
    // 通用: Combo 显示在篮子上方
  }

  @override
  bool shouldRepaint(covariant FruitCatcherPainter old) =>
      paintVersion != old.paintVersion;
}
```

**验证:** `fvm flutter analyze lib/fruit_catcher/fruit_catcher_painter.dart` — 无错误

---

### Task 5: 游戏页面（Ticker + 输入 + 生命周期）  ✅

**文件:**
- 创建: `lib/fruit_catcher/fruit_catcher_page.dart`

完全遵循 Breakout page 模式：

**核心结构:**

```dart
class FruitCatcherPage extends StatefulWidget {
  final FruitCatcherMode mode;
  const FruitCatcherPage({super.key, required this.mode});
  @override
  State<FruitCatcherPage> createState() => _FruitCatcherPageState();
}

class _FruitCatcherPageState extends State<FruitCatcherPage>
    with TickerProviderStateMixin {
  Key _gameKey = UniqueKey();
  late FruitCatcherGame _game;
  final ValueNotifier<int> _scoreNotifier = ValueNotifier<int>(0);
  int _bestScore = 0;
  int _paintVersion = 0;
  bool _isPaused = false;
  bool _gameOverHandled = false;
  late Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  final Set<String> _keysPressed = {};
  Size _canvasSize = Size.zero;
}
```

**关键实现点:**

1. **Ticker `_onTick`**: 计算 dt（clamp 0.033），调用 `_game.moveBasketByKeys`、`_game.update(dt)`，更新 `_scoreNotifier`，`setState`
2. **键盘输入**: `Focus` + `onKeyEvent`，方向键/AD 添加到 `_keysPressed`，Space 无用（无发射动作）
3. **触摸输入**: `GestureDetector.onPanUpdate` → `_game.moveBasketRelative(dx / _canvasSize.height)`
4. **鼠标悬浮**: `Listener.onPointerHover` → `_game.moveBasketTo(event.localPosition.dx / _canvasSize.height)`
5. **暂停/恢复**: 遵循 GameScaffold 模式
6. **GameOver**: 500ms 延迟后 Navigator.push GameOverPage

**UI 布局（与 Breakout 一致）:**

```dart
GameScaffold(
  key: _gameKey,
  title: 'Fruit Catcher - $_modeName',
  scoreNotifier: _scoreNotifier,
  bestScore: _bestScore,
  onPause: _onPause,
  onResume: _onResume,
  canPause: () => !_game.isGameOver,
  child: Focus(
    autofocus: true,
    onKeyEvent: _onKeyEvent,
    child: Center(
      child: AspectRatio(
        aspectRatio: FruitCatcherConfig.aspectRatio,
        child: LayoutBuilder(
          builder: (context, constraints) {
            _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
            return Listener(
              onPointerHover: _onPointerHover,
              child: GestureDetector(
                onPanUpdate: _onPanUpdate,
                child: CustomPaint(
                  size: _canvasSize,
                  painter: FruitCatcherPainter(
                    game: _game, paintVersion: _paintVersion),
                ),
              ),
            );
          },
        ),
      ),
    ),
  ),
)
```

**GameOver 统计（按模式）:**

```dart
final stats = <String, String>{
  'Score': '${_game.score}',
  'Best': '$best',
  'Caught': '${_game.fruitsCaught}',
  'Max Combo': '${_game.maxCombo}',
  'Accuracy': '${(_game.fruitsCaught / max(1, _game.totalSpawned) * 100).round()}%',
};
if (widget.mode == FruitCatcherMode.classic || widget.mode == FruitCatcherMode.endless) {
  stats['Time'] = formatTime(_game.survivalTime.round());
}
if (widget.mode == FruitCatcherMode.endless) {
  stats['Wave'] = '${_game.wave}';
}
```

**验证:** `fvm flutter analyze lib/fruit_catcher/fruit_catcher_page.dart` — 无错误

---

### Task 6: 模式选择页  ✅

**文件:**
- 创建: `lib/fruit_catcher/fruit_catcher_mode_page.dart`

遵循 Breakout mode page 模式，三个 `GameModeCard`：

```dart
class FruitCatcherModePage extends StatelessWidget {
  const FruitCatcherModePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('Fruit Catcher'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Timed 标为推荐
          GameModeCard(
            title: 'Timed ⭐',
            description: '60s countdown. Catch fruits, dodge bombs. Combo streaks add time!',
            icon: Icons.timer,
            accent: const Color(0xFF4ECCA3),
            gameName: 'fruit_catcher',
            scoreKey: 'timed',
            route: '/fruit_catcher/play',
            arguments: FruitCatcherMode.timed,
          ),
          GameModeCard(
            title: 'Classic',
            description: '5 lives. Miss a fruit or catch a bomb to lose a life.',
            icon: Icons.favorite,
            accent: const Color(0xFFE84545),
            gameName: 'fruit_catcher',
            scoreKey: 'classic',
            route: '/fruit_catcher/play',
            arguments: FruitCatcherMode.classic,
          ),
          GameModeCard(
            title: 'Endless',
            description: 'One bomb ends it all. Survive waves of increasing difficulty.',
            icon: Icons.all_inclusive,
            accent: const Color(0xFFF0C040),
            gameName: 'fruit_catcher',
            scoreKey: 'endless',
            route: '/fruit_catcher/play',
            arguments: FruitCatcherMode.endless,
          ),
        ],
      ),
    );
  }
}
```

**验证:** `fvm flutter analyze lib/fruit_catcher/fruit_catcher_mode_page.dart` — 无错误

---

### Task 7: 路由注册 + GameRegistry  ✅

**文件:**
- 修改: `lib/main.dart`
- 修改: `lib/home/game_registry.dart`

**Step 1: main.dart**

添加 import 和两条路由（在 `/klotski/play` 之后，`default` 之前）：

```dart
// 新增 import
import 'fruit_catcher/fruit_catcher_config.dart';
import 'fruit_catcher/fruit_catcher_mode_page.dart';
import 'fruit_catcher/fruit_catcher_page.dart';

// 新增路由
case '/fruit_catcher':
  return MaterialPageRoute(
    settings: settings,
    builder: (_) => const FruitCatcherModePage(),
  );
case '/fruit_catcher/play':
  final mode = settings.arguments as FruitCatcherMode? ?? FruitCatcherMode.timed;
  return MaterialPageRoute(
    settings: settings,
    builder: (_) => FruitCatcherPage(mode: mode),
  );
```

注意默认模式为 `timed`（推荐模式）。

**Step 2: game_registry.dart**

在 games 列表中添加（Flappy Bird 之后）：

```dart
GameInfo(
  name: 'Fruit Catcher',
  icon: Icons.shopping_basket,
  description: 'Catch falling fruits, dodge bombs',
  phase: 3,
  route: '/fruit_catcher',
  implemented: true,
  hasModePage: true,
),
```

**验证:** `fvm flutter analyze` — 无错误，`fvm flutter run -d chrome` — 主页显示 Fruit Catcher 卡片，点击进入模式选择页

---

### Task 8: 集成测试 + 调参  ✅

**文件:** 无新增，微调现有文件

**Step 1: 运行游戏，逐模式验证**

运行: `fvm flutter run -d chrome`

验证清单：
- [ ] 主页显示 Fruit Catcher 卡片
- [ ] 模式选择页显示三个模式，Timed 排第一且有推荐标记
- [ ] **经典模式**: 水果下落、篮子可移动（键盘+鼠标）、接住加分、Combo 递增、漏接扣命、炸弹扣命、5 命用完结束、结算页统计正确
- [ ] **限时模式**: 60 秒倒计时、连击加时（+2s）、炸弹 -2 分、分数不低于 0、时间到结束
- [ ] **无尽模式**: 波次推进、波间 2 秒暂停、炸弹一碰即死、难度从较高起点开始
- [ ] **通用**: 开局前 5 个无炸弹、Combo 浮字显示、屏幕抖动（漏接）、红闪（炸弹）、篮子压缩动画、高分保存和读取、暂停/恢复正常

**Step 2: 难度曲线调参**

通过实际游玩调整 k1-k4 常数：
- 确保经典模式一般玩家能玩到 40-70 秒
- 确保限时模式后期仍有正期望（炸弹比不超过 20%）
- 确保无尽模式前 30 秒就有挑战感

**验证:** 所有模式可正常游玩，难度曲线手感合理
