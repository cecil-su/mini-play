# Flappy Bird Game Design

## Overview

Flappy Bird — 点击屏幕让小鸟向上跳跃，穿过上下管道间的缺口。碰到管道或地面即死亡。按飞行距离计分，通过管道有额外加分。

- **技术栈：** CustomPaint + Ticker（和 Breakout 一致）
- **坐标系：** 高度归一化（0-1），宽度按 aspect ratio 计算
- **Aspect Ratio：** 9:16（竖屏）
- **3 个难度模式：** Easy / Normal / Hard
- **视觉风格：** 纯几何形状（Phase 3 风格）

## Game Modes

| 参数 | Easy | Normal | Hard |
|------|------|--------|------|
| 重力加速度 | 1.2 | 1.6 | 2.0 |
| 跳跃力（瞬时上升速度） | -0.45 | -0.5 | -0.55 |
| 管道水平间距 | 0.55 | 0.45 | 0.35 |
| 管道缺口大小 | 0.28 | 0.22 | 0.18 |
| 管道滚动速度 | 0.25 | 0.35 | 0.45 |
| 地面滚动速度 | 同管道速度 | 同管道速度 | 同管道速度 |
| 缺口位置范围（Y） | 0.2 ~ 0.7 | 0.15 ~ 0.75 | 0.1 ~ 0.8 |

- 所有值为归一化坐标，实际像素 = 值 × canvasHeight
- 跳跃力为负值（向上），重力为正值（向下）
- 速度为每秒移动的归一化距离

## Data Models

```
Bird
  x: double          // 固定水平位置（约 0.2 × width）
  y: double          // 当前垂直位置
  velocity: double   // 当前垂直速度
  rotation: double   // 倾斜角度（由速度映射）
  radius: double     // 碰撞半径（0.025）
  wingPhase: double  // 翅膀动画相位

Pipe
  x: double          // 管道左边缘 X 坐标
  gapCenterY: double // 缺口中心 Y 坐标
  width: double      // 管道宽度（0.08 × height）
  passed: bool       // 是否已被通过（用于加分）

Cloud
  x: double          // 水平位置
  y: double          // 垂直位置
  size: double       // 大小（随机）
  speed: double      // 滚动速度（比管道慢，产生视差）

Ground
  offsetX: double    // 滚动偏移量（取模实现无限滚动）
  height: double     // 地面高度（0.1）
```

- Bird 的 x 固定不动，世界向左滚动
- Pipe 从右侧生成，向左移动，离开屏幕后回收
- Cloud 速度约为管道速度的 0.3 倍，产生远景视差

## Physics & Collision

### Gravity & Jump

```
每帧更新：
  bird.velocity += gravity × dt
  bird.y += bird.velocity × dt
  bird.velocity = clamp(bird.velocity, -maxVelocity, maxVelocity)

跳跃时：
  bird.velocity = jumpPower  // 瞬时设为负值（向上）
```

### Bird Rotation

- rotation 由 velocity 线性映射：上升时鸟头朝上（-30°），下降时朝下（最大 +90°）
- `rotation = clamp(velocity × rotationFactor, -π/6, π/2)`

### Collision Detection (Circle vs Rectangle)

- 小鸟视为圆形（center + radius）
- 管道视为两个矩形（上管道 + 下管道）
- 复用 Breakout 的 circle-rect 碰撞逻辑
- 碰撞优先级：地面 > 管道 > 天花板
- 碰到地面或管道 → 游戏结束
- 碰到天花板 → 速度归零弹回（不死亡）

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
- GameOverPage 显示：Score、Pipes（管道通过数）、模式名

## Rendering

### Draw Order (bottom to top)

1. 渐变天空背景（顶部浅蓝 → 底部深蓝）
2. 云朵层（几何椭圆，视差滚动，速度 = 管道 × 0.3）
3. 管道（圆角矩形，绿色渐变，顶部加管帽装饰）
4. 地面（棕/绿条纹，无限滚动）
5. 小鸟（圆形身体 + 三角形翅膀，翅膀按 wingPhase 上下摆动）
6. HUD（当前分数居中顶部，大字号白色带阴影）
7. 覆盖层（准备开始提示、游戏结束）

### Bird Animation

- 翅膀拍动：wingPhase 以固定频率递增，三角形翅膀 Y 偏移 = sin(wingPhase) × amplitude
- 身体随 rotation 旋转（Canvas.rotate）

### Pipe Style

- 主体：绿色渐变矩形
- 管帽：比主体宽一点的矩形，高度固定（0.02），稍深的绿色

### Parallax Effect

- 云朵层：3-5 朵随机大小的椭圆，速度慢于管道
- 地面层：与管道同速滚动，用 offsetX 取模实现无缝循环

### Paint Optimization

- paintVersion 每帧递增（持续动画）
- 暂停/结束时停止递增

## Game State Flow

```
Ready → Playing → Dead → GameOver
```

- **Ready：** 小鸟在屏幕中央微微上下浮动，显示 "Tap to Start"，管道不动
- **Playing：** 第一次点击后进入，开始物理和滚动
- **Dead：** 碰撞后进入，小鸟受重力坠落到地面（约 0.5 秒），期间不可操作
- **GameOver：** 坠落结束后跳转 GameOverPage，显示分数和管道通过数

## File Structure

```
lib/flappybird/
├── flappybird_config.dart       # FlappybirdMode enum + FlappybirdConfig 工厂
├── flappybird_models.dart       # Bird, Pipe, Cloud, Ground 数据类
├── flappybird_game.dart         # 核心逻辑：物理、碰撞、管道生成、计分
├── flappybird_collision.dart    # circle-rect 碰撞检测
├── flappybird_painter.dart      # CustomPainter：天空、云、管道、地面、鸟、HUD
├── flappybird_page.dart         # StatefulWidget：Ticker、输入、GameScaffold
└── flappybird_mode_page.dart    # 模式选择页（3 张 GameModeCard）
```

### Routing

- `/flappybird` → FlappybirdModePage
- `/flappybird/play` → FlappybirdPage(mode)

### Game Registry

- Phase 3，icon `Icons.flutter_dash`
- Description: "Tap to fly through gaps between pipes"
