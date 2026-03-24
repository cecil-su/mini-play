# Flappy Bird Game Design

## Overview

Flappy Bird — 点击屏幕让小鸟向上跳跃，穿过上下管道间的缺口。碰到管道或地面即死亡。按飞行距离计分，通过管道有额外加分。

- **技术栈：** CustomPaint + Ticker（和 Breakout 一致）
- **坐标系：** 高度归一化，worldHeight = 1.0，worldWidth = 9/16 = 0.5625
- **Aspect Ratio：** 9:16（竖屏）
- **3 个难度模式：** Easy / Normal / Hard
- **视觉风格：** 纯几何形状（Phase 3 风格）
- **dt 限制：** `dt = dt.clamp(0.0, 0.033)` 防止切换标签页后物理爆炸

## Game Modes

| 参数 | Easy | Normal | Hard |
|------|------|--------|------|
| 重力加速度 | 1.2 | 1.6 | 2.0 |
| 跳跃力（瞬时上升速度） | -0.45 | -0.5 | -0.55 |
| 最大速度 maxVelocity | 1.0 | 1.2 | 1.5 |
| 管道水平间距 | 0.55 | 0.45 | 0.35 |
| 管道缺口大小 | 0.28 | 0.22 | 0.18 |
| 管道滚动速度 | 0.25 | 0.35 | 0.45 |
| 地面滚动速度 | 同管道速度 | 同管道速度 | 同管道速度 |
| 缺口位置范围（Y） | 0.2 ~ 0.7 | 0.15 ~ 0.75 | 0.12 ~ 0.78 |

- 所有值为归一化坐标，实际像素 = 值 × canvasHeight
- 跳跃力为负值（向上），重力为正值（向下）
- 速度为每秒移动的归一化距离
- 缺口位置约束：`gapCenterY - gapSize/2 >= 0.03` 且 `gapCenterY + gapSize/2 <= 0.87`（确保上下管道最小可见高度 >= 0.03）

## Data Models

```
Bird
  x: double          // 固定水平位置 = worldWidth × 0.2（约 0.1125）
  y: double          // 当前垂直位置（归一化）
  velocity: double   // 当前垂直速度
  rotation: double   // 倾斜角度（由速度映射）
  radius: double     // 碰撞半径（0.025）
  wingPhase: double  // 翅膀动画相位

Pipe
  x: double          // 管道左边缘 X 坐标（归一化，水平方向）
  gapCenterY: double // 缺口中心 Y 坐标
  width: double      // 管道宽度（0.08）
  passed: bool       // 是否已被通过（用于加分）

Cloud
  x: double          // 椭圆中心 X 坐标
  y: double          // 椭圆中心 Y 坐标（范围 0.05 ~ 0.35）
  radius: double     // 椭圆水平半径（范围 0.03 ~ 0.08），垂直半径 = radius × 0.6
  speed: double      // 滚动速度 = pipeSpeed × 0.3

Ground
  offsetX: double    // 滚动偏移量（取模实现无限滚动）
  height: double     // 地面高度（0.1，即 y=0.9 到 y=1.0）
```

- Bird 的 x 固定不动，世界向左滚动
- Pipe 从右侧生成，向左移动，离开屏幕后回收
- Cloud 速度约为管道速度的 0.3 倍，产生远景视差

## Pipe Generation

- 首根管道在 `x = worldWidth + 0.1` 处生成
- 后续管道在 `x = lastPipe.x + pipeSpacing` 处生成（精确间距控制）
- 生成触发条件：当最后一根管道的 `x < worldWidth` 时（即进入屏幕可见区域）
- `gapCenterY` 在模式对应范围内随机生成，受约束确保上下管道最小高度
- 管道离开屏幕后回收：`pipe.x + pipe.width < -0.05`
- 同屏最大管道数约 3-4 根（由间距和速度自然决定）

## Physics & Collision

### Gravity & Jump

```
每帧更新：
  bird.velocity += gravity × dt
  bird.velocity = clamp(bird.velocity, -maxVelocity, maxVelocity)  // 先限速再移动
  bird.y += bird.velocity × dt

跳跃时：
  bird.velocity = jumpPower  // 瞬时设为负值（向上）
```

无跳跃冷却时间——每次 tap 都立即覆盖当前速度为 jumpPower，与原版 Flappy Bird 一致。

### Bird Rotation

- rotation 由 velocity 线性映射：上升时鸟头朝上（-30°），下降时朝下（最大 +90°）
- `rotation = clamp(velocity × rotationFactor, -π/6, π/2)`
- `rotationFactor = π/2`（即速度 1.0 时旋转到 90°）

### Collision Detection (Circle vs Rectangle)

- 小鸟视为圆形（center + radius）
- 管道视为两个矩形（上管道 + 下管道）
- 在 `flappybird_collision.dart` 中实现独立的 circle-rect 碰撞函数（返回 bool），不依赖 breakout 模块
- 碰撞优先级：地面 > 管道 > 天花板
- 碰到地面或管道 → 游戏结束
- 天花板 = y 轴 0.0。当 `bird.y - bird.radius < 0` 时，`bird.y = bird.radius`，`bird.velocity = 0`（停止上升，不反弹，不死亡）

### Pipe Pass Detection

- 当 `pipe.x + pipe.width < bird.x` 且 `!pipe.passed` 时，标记 passed，加分

## Input Handling

### Touch/Click

- GestureDetector 的 `onTapDown` → 触发跳跃
- 游戏未开始时，第一次点击同时启动游戏

### Keyboard

- 空格键 / 上箭头 → 跳跃
- 使用 `KeyDownEvent` 触发（非连续按压，每次按下只跳一次）

### Pause

- 由 GameScaffold 统一管理
- 暂停时 Ticker 继续运行但跳过 update
- 切后台自动暂停

## Scoring

### Distance Score

- 每帧累加：`score += pipeSpeed × dt × 100`
- 显示为整数（取 floor）

### Pipe Bonus

- 每通过一对管道 +10 分
- 触觉反馈：`HapticFeedback.lightImpact()`

### Death Feedback

- `HapticFeedback.heavyImpact()`

### High Score

- 使用 ScoreService，key 格式 `highscore_flappybird_{mode}`
- 模式枚举：`FlappybirdMode.easy`, `.normal`, `.hard`，`.name` 产生 `easy`, `normal`, `hard`
- GameOverPage 显示：Score、Pipes（管道通过数）、模式名

## Rendering

### Score Display

- 使用 GameScaffold 的分数栏显示分数和最高分（与其他游戏一致）
- scoreNotifier 绑定实时分数，bestScore 在进入页面时从 ScoreService 加载

### Draw Order (bottom to top)

1. 渐变天空背景（顶部浅蓝 → 底部深蓝）
2. 云朵层（几何椭圆，视差滚动，速度 = 管道 × 0.3）
3. 管道（矩形，绿色渐变，顶部加管帽装饰，管帽圆角半径 0.005）
4. 地面（棕/绿条纹，无限滚动）
5. 小鸟（圆形身体 + 三角形翅膀，翅膀按 wingPhase 上下摆动）
6. 覆盖层（Ready 状态的 "Tap to Start" 提示，白色字号 0.04 × canvasHeight）

### Bird Animation

- 每帧更新：`wingPhase += 10.0 × dt`（频率 10 rad/s，约 1.6 次/秒）
- 翅膀振幅：0.01（归一化）
- 翅膀三角形相对于鸟身体的垂直偏移 = sin(wingPhase) × amplitude
- 身体随 rotation 旋转（Canvas.rotate）

### Pipe Style

- 主体：绿色渐变矩形
- 管帽：比主体宽一点的矩形（每侧多出 0.005），高度固定（0.02），稍深的绿色，圆角 0.005

### Parallax Effect

- 云朵：游戏开始时生成 4 朵，随机 x（0 ~ worldWidth）、y（0.05 ~ 0.35）、radius（0.03 ~ 0.08）
- 云朵向左滚动，当 `x + radius < 0` 时传送到右侧 `x = worldWidth + radius + random(0, 0.1)`
- 地面层：与管道同速滚动，用 offsetX 取模实现无缝循环

### Paint Optimization

- paintVersion 每帧递增（持续动画）
- 暂停/结束时停止递增

## Game State Flow

```
Ready → Playing → Dead → GameOver
```

- **Ready：** 小鸟在 `(bird.x, 0.4)` 微微上下浮动（振幅 0.02，频率 3 rad/s），显示 "Tap to Start"（白色，字号 0.04 × canvasHeight，居中），管道不动，云朵和地面不滚动
- **Playing：** 第一次点击后进入，开始物理和滚动
- **Dead：** 碰撞后进入，`bird.velocity = 0`（从碰撞点开始坠落），管道和地面停止滚动，小鸟以正常重力坠落，旋转锁定 +90°（头朝下）。当 `bird.y + bird.radius >= 1.0 - ground.height` 时转入 GameOver
- **GameOver：** 跳转 GameOverPage，显示分数和管道通过数

## File Structure

```
lib/flappybird/
├── flappybird_config.dart       # FlappybirdMode enum + FlappybirdConfig 工厂
├── flappybird_models.dart       # Bird, Pipe, Cloud, Ground 数据类
├── flappybird_game.dart         # 核心逻辑：物理、碰撞、管道生成、计分
├── flappybird_collision.dart    # 独立的 circle-rect 碰撞检测（返回 bool）
├── flappybird_painter.dart      # CustomPainter：天空、云、管道、地面、鸟、HUD
├── flappybird_colors.dart       # 颜色常量（天空渐变、管道绿、地面棕绿、鸟身体色等）
├── flappybird_page.dart         # StatefulWidget：Ticker、输入、GameScaffold
└── flappybird_mode_page.dart    # 模式选择页（3 张 GameModeCard）
```

### Routing

- `/flappybird` → FlappybirdModePage
- `/flappybird/play` → FlappybirdPage(mode)

### Game Registry

- Phase 3，icon `Icons.flutter_dash`
- Description: "Tap to fly through gaps between pipes"
