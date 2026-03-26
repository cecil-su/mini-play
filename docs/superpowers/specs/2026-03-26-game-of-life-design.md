# Game of Life (生命游戏)

**日期:** 2026-03-27（修订版，基于 Agent Teams 评审）

## 背景

mini-play 游戏合集 Phase 4（AI & Strategy）的第 3 个游戏。Conway's Game of Life 细胞自动机模拟器，不是传统得分游戏，而是集沙盒探索、挑战关卡、图案百科于一体的交互式模拟器。

## 讨论

### 模式设计
- 考虑过单一沙盒模式（简单但缺乏引导）和多模式方案
- 最终选择三模式：沙盒 + 挑战 + 图鉴百科，覆盖自由探索、目标驱动、教育学习三种用户动机
- 图鉴百科独立成模式，提供完整的图案介绍和发现历史

### 网格边界
- 有限边界：简单但边缘效应影响演化
- 环面（Toroidal）：消除边缘效应，性能可预测
- 动态扩展（Set）：最还原理论定义但 InteractiveViewer 不兼容真正无限，Set 有 GC 压力
- **最终选择：300×300 Uint8List 环面网格** — 消除边缘效应，O(1) 数组访问无 GC，90KB 内存，覆盖所有预设图案

### 渲染方案
- 纯 CustomPainter：需自己处理平移缩放手势
- InteractiveViewer（非 builder）+ CustomPainter：沿用扫雷方案，固定尺寸画布，**选择此方案**
- InteractiveViewer.builder：无实际收益（CustomPainter 已自行做视口裁剪）
- WebGL/Shader：性能极佳但复杂度过高，不符合项目风格

## 方案

### 三个模式

**沙盒模式：**
- InteractiveViewer（constrained: false）+ CustomPainter 实现平移缩放
- 画笔/移动模式切换按钮：画笔模式单指 toggle 细胞（点空位=画，点已有=擦，长按拖拽连续绘制/擦除），移动模式单指平移，双指缩放始终可用
- 运行时允许编辑细胞（不禁用，符合主流 Game of Life 实现）
- 底部控制栏（5 个按钮）：图案库 / 单步 / 播放暂停 / 速度 / 清空（含二次确认）
- 速度 3 档循环切换：慢(3代/秒) / 中(10代/秒) / 快(30代/秒)
- 图案库面板：DraggableScrollableSheet 底部上拉，FilterChip 横向滚动分类
- 图案放置模式：选中图案后进入临时模式，显示半透明预览跟随手指，底部出现旋转/确认/取消工具条。确认放置后自动退出放置模式
- 代数计数器 + 活细胞数显示（顶部信息栏）
- 首次进入新手引导：3-4 步 overlay 提示，可跳过

**挑战模式：**
- 15 关，分三档（入门/进阶/高级），1-3 星评分
- 关卡列表页，显示名称、目标描述（自然语言，非术语）、目标图案可视化预览、星级
- 完整状态机：编辑→确认→运行(最多 maxGenerations 代)→成功/失败→查看结果→重试/下一关
- 进入关卡：显示初始状态，锁定细胞用蓝色标记不可编辑
- 用户在允许区域添加细胞，确认后运行演化，自动检测目标
- 运行时显示目标进度（如"目标：存活 10 代 | 当前：第 3 代"）
- 失败时显示原因 + 重试按钮；成功时星星动画 + 评分
- 星级评分：用的细胞数越少星越多
- 前 2 关兼具教学功能

**图鉴百科模式：**
- 分类：可滚动 TabBar 或 FilterChip（全部 / 静物 / 振荡器 / 飞船 / 枪与工厂 / 其他）
- 列表默认静态缩略图（避免全部动画的视觉噪音），hover/长按播放预览
- 详情页：上半部大画布动画展示（占 50-60%），下半部信息卡片（元数据用 key-value 标签布局）
- 说明文字：名称、发现者、年份、周期/速度、细胞数、特性描述
- "在沙盒中打开"按钮固定底部

### 模式间流转
- 图鉴详情页 → "在沙盒中打开"跳转沙盒并放置图案
- 挑战关卡说明 → "查看目标图案"链接跳转图鉴对应条目
- 沙盒中检测到已知图案时 → 轻量提示气泡，可点击跳转图鉴详情

### 挑战关卡设计

入门（教学，自然语言描述）：
1. 放置 4 个细胞，让它们稳定成方块形状（不再变化）— Block
2. 放置 3 个细胞，让它们在两种形态间反复切换 — Blinker
3. 放置 5 个细胞，让它们组成会移动的图案 — Glider
4. 在这些细胞旁放置新细胞，让所有细胞在 5 代内全部消失
5. 放置细胞，让图案持续存活超过 10 代

进阶（6-10）：限定区域制造特定图案、最少细胞达成目标等

高级（11-15）：制造周期 > 2 的振荡器、让活细胞数在 50 代后超过初始 3 倍等

每关定义：初始状态、锁定区域、可编辑区域、目标类型和参数、maxGenerations、三个星级的细胞数阈值。

**目标检测机制：**
- 静物检测：连续 2 代哈希相同（周期=1）
- 振荡器检测：FNV-1a 哈希 + 30 代环形缓冲区检测周期循环，且 bounding box 中心不变
- 飞船检测：归一化坐标哈希匹配（消除平移影响），且 bounding box 中心发生位移
- 存活/消亡：检查指定代数后活细胞数
- 挑战关卡可特化检测参数（如已知 Glider 周期=4, 位移=(1,1)），避免通用检测的复杂度

### 预设图案（15 个精选）

| 分类 | 图案 | 数量 |
|------|------|------|
| 静物 | Block, Beehive, Loaf, Boat | 4 |
| 振荡器 | Blinker (P2), Toad (P2), Beacon (P2), Pulsar (P15), Pentadecathlon (P15) | 5 |
| 飞船 | Glider, LWSS | 2 |
| 长寿图案 | R-pentomino, Diehard, Acorn | 3 |
| 枪 | Gosper Glider Gun | 1 |

沙盒图案库：名称（中英双语）、分类标签、坐标数据、尺寸、一句话说明。
图鉴百科额外：发现者、年份、周期/速度、特性描述。

## 约束与非功能需求

- **性能：** 300×300 全网格扫描 Web 端 ~4-5ms，VM 端 ~2ms，均在 16ms 帧预算内。"最快"档每帧最多跑 3 代（Web）/ 5 代（VM）。
- **上限：** 300×300 = 90000 格，理论最大活细胞 90000，实际密度不超 30-50%。Gosper Glider Gun 持续产生 Glider 时，自动暂停在活细胞达网格 50% 时并提示用户。
- **平台：** Web + Android 双端，画笔/移动模式切换适配触屏和鼠标
- **兼容：** 不引入新依赖，纯 Flutter CustomPainter 渲染

## 架构

### 文件结构

```
lib/game_of_life/
├── game_of_life_mode_page.dart         — 模式选择页（沙盒/挑战/图鉴）
├── game_of_life_page.dart              — 沙盒模式主页面
├── game_of_life_challenge_page.dart    — 挑战模式页面（列表+关卡）
├── game_of_life_challenge_runner.dart  — 挑战运行和目标检测逻辑
├── game_of_life_encyclopedia_page.dart — 图鉴百科页面（列表+详情）
├── game_of_life_game.dart              — 核心演化逻辑（纯 Dart，无 UI）
├── game_of_life_painter.dart           — CustomPainter 渲染（沙盒/挑战/图鉴共用）
├── game_of_life_config.dart            — 常量配置
├── game_of_life_colors.dart            — 配色方案
├── game_of_life_patterns.dart          — 15 个预设图案数据 + 图鉴描述文字
├── game_of_life_challenges.dart        — 15 个挑战关卡定义
└── game_of_life_widgets.dart           — 共享 UI 组件（信息栏、控制栏、图案库面板等）
```

### 核心数据结构

- 网格：300×300 `Uint8List` 双缓冲（current + next 交替），环面边界（取模）
- 演化算法：bounding box 优化扫描，展开循环 8 邻居计数，交换缓冲区。活跃区域小时只扫描 bounding box + 1 格边距，超过 70% 网格时退化为全扫描
- 活细胞计数器：演化时维护，避免每帧遍历
- 历史状态：FNV-1a 64-bit 哈希摘要 + 30 代环形缓冲区（每代存 hash/generation/centerXY/aliveCount，共 1.2KB）

### 渲染

- InteractiveViewer（非 builder，constrained: false）+ 固定尺寸 SizedBox + CustomPainter
- minScale=0.5, maxScale=8.0, boundaryMargin 为屏幕尺寸的 50%
- 网格线：缩放后 cellSize > 8px 时显示，否则只画色块
- 同色细胞合并为 Path 一次 drawPath 提交，减少 draw call
- shouldRepaint：仅在状态变化或视口变换时触发，使用 ChangeNotifier 精确控制
- Ticker 驱动演化，根据速度档位累计时间步进

### 交互

- 画笔/移动模式切换按钮（底栏或工具栏）
- 画笔模式：InteractiveViewer panEnabled=false，单指 toggle 细胞，长按拖拽连续绘制/擦除（首格方向决定后续是画还是擦）
- 移动模式：InteractiveViewer 正常处理单指平移
- 双指缩放：两种模式下始终可用
- 运行中：允许编辑细胞（画笔模式生效）
- 图案放置：独立临时模式，显示旋转/确认/取消工具条，预览跟随手指吸附网格，确认后自动退出

### 配色

- 背景：#1A1A2E（深色）
- 网格线：#2A2A3E（微弱灰）
- 活细胞：#00FF88（亮绿，终端美学）
- 新生细胞：浅绿高亮
- 挑战锁定细胞：蓝色
- 图案预览：半透明绿

### 项目集成

- GameScaffold 包裹，GameModeCard 模式选择
- ScoreService 持久化：
  - 沙盒：`gameoflife/sandbox` 存最高代数
  - 挑战：`gameoflife/challenge_1` ~ `gameoflife/challenge_15` 存最少细胞数，`gameoflife/challenge_stars_1` ~ `gameoflife/challenge_stars_15` 存星级
- GameRegistry 注册（hasModePage: true），main.dart 添加路由
- GameScaffold 适配：沙盒 scoreLabel="Gen" bestLabel="Cells"；挑战 scoreLabel="Cells" bestLabel="Best"
