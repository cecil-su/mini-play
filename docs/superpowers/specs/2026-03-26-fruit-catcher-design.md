# Fruit Catcher（水果接住）

**日期:** 2026-03-26

## 背景

mini-play 游戏合集的第 9 个游戏，Phase 3 最后一个。水果从天空掉落，玩家移动篮子接住水果、躲避炸弹。核心学习点：随机生成、难度曲线、物理下落。

## 核心玩法

- 水果从屏幕顶部随机位置生成并下落
- 玩家水平移动底部篮子接住水果得分
- 炸弹混在水果中，必须躲避
- 无道具系统，纯粹靠操作和反应
- **Combo 系统**：连续接住水果触发连击，分值递增（1-1-1-2-2-3-3-5...），漏接或碰炸弹重置连击

## 游戏模式

### 经典模式（Classic）
- 5 条命，漏接水果扣 1 命，接到炸弹扣 1 命
- 连续接住 20 个水果（不漏接不碰弹）恢复 1 命，上限 5
- 难度驱动：按接住水果数量递增
- 结束条件：命用完

### 限时模式（Timed）— 默认推荐
- 60 秒倒计时
- 接水果按 Combo 加分，接到炸弹 -2 分，漏接无惩罚
- 分数下限为 0（不会出现负分）
- **连击加时**：连续接住 5 个额外 +2 秒（游戏时长可超过 60 秒）
- 难度驱动：按已过时间连续递增
- 结束条件：时间到

### 无尽模式（Endless）
- 无命数限制，无时间限制
- 接水果按 Combo 加分，接到炸弹直接结束
- **波次节奏**：每过一个波次有 2 秒短暂空白期（喘息），然后下一波开始
- 难度驱动：按波次递增，使用独立的较高初始难度参数
- 结束条件：接到炸弹

## 难度系统

### 参数

| 参数 | 初始值 | 上限 | 说明 |
|------|--------|------|------|
| 生成间隔 | 0.8s | 0.3s | 两个物体之间的生成时间间隔 |
| 下落速度 | 屏幕高度/3 每秒 | 2× 初速 | 物体从顶到底的速度 |
| 炸弹占比 | 10% | 20% | 生成物体中炸弹的比例 |

### 渐近式公式

三个参数使用独立曲线，避免同时到达拐点导致难度突变：

```
spawnInterval(level) = minInterval + (maxInterval - minInterval) / (1 + level * k1)
fallSpeed(level)     = baseSpeed * (1 + level * k2 / (1 + level * k3))
bombRatio(level)     = minRate + (maxRate - minRate) * level / (level + k4)
```

k1-k4 为调参常数，实现时微调。

### 模式差异

| 参数 | 经典 | 限时 | 无尽 |
|------|------|------|------|
| 难度驱动 | 接住数量 | 已过时间 | 波次 |
| 初始间隔 | 0.8s | 0.8s | 0.6s |
| 初始炸弹比 | 10% | 10% | 15% |
| 初始速度倍率 | 1.0× | 1.0× | 1.2× |

### 开局保护

所有模式：前 5 个生成物体保证为水果，给玩家热身适应。

## 水果与炸弹

### 水果
- 5 种颜色：红、橙、黄、绿、紫（纯视觉区分，基础分值均为 1）
- 圆形几何体
- 随机从屏幕顶部生成，x 范围考虑水果半径避免超出篮子可达区域

### 炸弹
- 黑色圆形，带脉冲闪烁效果（sin 函数调制 alpha）
- 视觉上与水果明显区分

## 控制方案

### 移动端（触摸）
- `GestureDetector.onPanUpdate` 处理拖拽相对位移
- 首次触摸记录偏移量（offset mode），避免篮子瞬移跳跃

### Web 鼠标
- `Listener.onPointerHover` 实现鼠标悬浮绝对跟随
- 鼠标 x 坐标直接映射篮子位置

### Web 键盘
- `Focus` + `onKeyEvent`，方向键/AD 控制速度
- 加速曲线：按下 100ms 加速到满速，松开 50ms 衰减到 0
- 键盘移动速度随难度适当提升，确保理论上可全接

### 篮子平滑
- 触摸/鼠标：高 lerp 系数（接近 1），几乎无延迟
- 键盘：lerp 用于加减速曲线

## 视觉设计

### 几何风格（Phase 3）
- 水果：彩色圆形/椭圆
- 炸弹：黑色圆形 + 脉冲闪烁
- 篮子：梯形或弧形
- 背景：纯色或浅渐变

### 反馈效果
- 接住水果：篮子微弹性形变（竖向压缩 10% → 弹回，200ms）+ "+1" 浮字上飘消失
- Combo 反馈：连击计数显示（"Combo x5"），递增时视觉加强
- 接住炸弹：屏幕短暂红闪 + "-2" 浮字（限时模式）
- 漏接水果：屏幕短暂抖动（Canvas translate 实现）

### HUD
- 分数：通过 GameScaffold 的 scoreNotifier 显示
- 最高分：通过 GameScaffold 的 bestScore 显示
- 连击数：Canvas HUD 区域绘制
- 倒计时（限时模式）：Canvas HUD 区域绘制
- 命数（经典模式）：Canvas HUD 区域绘制
- 波次（无尽模式）：Canvas HUD 区域绘制

## 结算页面

使用 GameOverPage + GameOverData，显示统计：

| 统计项 | 经典 | 限时 | 无尽 |
|--------|------|------|------|
| 得分 | ✓ | ✓ | ✓ |
| 接住水果数 | ✓ | ✓ | ✓ |
| 最高连击 | ✓ | ✓ | ✓ |
| 准确率 | ✓ | ✓ | ✓ |
| 存活时间 | ✓ | - | ✓ |
| 波次 | - | - | ✓ |

操作按钮：Play Again / Choose Mode / Home

## 技术架构

### 文件结构

```
lib/fruit_catcher/
  fruit_catcher_config.dart    — 模式枚举、配置参数、难度公式
  fruit_catcher_mode_page.dart — 模式选择页（限时标为推荐）
  fruit_catcher_page.dart      — 游戏页面（Ticker、输入、生命周期）
  fruit_catcher_game.dart      — 游戏逻辑（状态、更新、碰撞）
  fruit_catcher_painter.dart   — Canvas 渲染（水果、炸弹、篮子、HUD、特效）
  fruit_catcher_models.dart    — 数据模型（FruitItem、Basket、FloatingText）
  fruit_catcher_colors.dart    — 颜色常量
  fruit_catcher_collision.dart — AABB 碰撞检测
```

### 坐标系

- `aspectRatio = 3/4`（与 Breakout 一致，竖屏）
- 归一化坐标系：worldWidth = 0.75, worldHeight = 1.0
- Painter 按 `size.height` 缩放到实际像素

### 集成

- GameScaffold 包裹游戏页面（返回、暂停、分数）
- ScoreService 存储高分（key: `highscore_fruit_catcher_<mode>`）
- GameRegistry 注册游戏信息
- main.dart 添加路由：`/fruit_catcher` → 模式页，`/fruit_catcher/play` → 游戏页

### 关键实现注意

- 暂停恢复时重置 `_lastElapsed`，dt 加 clamp 上限（0.033s）
- 水果生成 x 范围：`[radius, worldWidth - radius]`
- 限时模式计时器在 `game.update(dt)` 中递减（非 Timer）
- 浮字对象列表：update 中递增 y + 衰减 alpha，paint 中绘制 TextPainter
- 屏幕抖动：Canvas.translate(shakeX, shakeY)，由衰减计时器驱动
- 炸弹闪烁：sin(elapsed * frequency) 调制 alpha

### 预留音效触发点

接住水果、接住炸弹、Combo x3/x5/x10、漏接、游戏结束。第一版不实现音效，但代码中预留回调点。
