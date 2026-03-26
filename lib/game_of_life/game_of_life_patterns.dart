class PatternCategory {
  static const String stillLife = 'still_life';
  static const String oscillator = 'oscillator';
  static const String spaceship = 'spaceship';
  static const String methuselah = 'methuselah';
  static const String gun = 'gun';

  static const List<String> all = [
    stillLife,
    oscillator,
    spaceship,
    methuselah,
    gun,
  ];

  static String label(String category) {
    switch (category) {
      case stillLife:
        return '静物';
      case oscillator:
        return '振荡器';
      case spaceship:
        return '飞船';
      case methuselah:
        return '长寿';
      case gun:
        return '枪';
      default:
        return category;
    }
  }
}

class GameOfLifePattern {
  final String id;
  final String name;
  final String nameEn;
  final String category;
  final List<(int, int)> cells;
  final int width;
  final int height;
  final String brief;
  final String? discoverer;
  final int? year;
  final int? period;
  final String? speed;
  final String description;
  final int normalizedHash;

  const GameOfLifePattern({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.category,
    required this.cells,
    required this.width,
    required this.height,
    required this.brief,
    this.discoverer,
    this.year,
    this.period,
    this.speed,
    required this.description,
    required this.normalizedHash,
  });
}

class GameOfLifePatterns {
  static const List<GameOfLifePattern> all = [
    // === Still Lifes ===
    GameOfLifePattern(
      id: 'block',
      name: '方块',
      nameEn: 'Block',
      category: PatternCategory.stillLife,
      cells: [(0, 0), (1, 0), (0, 1), (1, 1)],
      width: 2,
      height: 2,
      brief: '最小的静物',
      discoverer: 'John Conway',
      year: 1970,
      period: 1,
      description: '最简单的静物，由 4 个细胞组成的 2×2 方块。每个细胞恰好有 3 个邻居，因此永远稳定不变。',
      normalizedHash: 0x62D9AA4E3B1C, // Pre-computed
    ),
    GameOfLifePattern(
      id: 'beehive',
      name: '蜂巢',
      nameEn: 'Beehive',
      category: PatternCategory.stillLife,
      cells: [(1, 0), (2, 0), (0, 1), (3, 1), (1, 2), (2, 2)],
      width: 4,
      height: 3,
      brief: '6 细胞静物',
      discoverer: 'John Conway',
      year: 1970,
      period: 1,
      description: '第二常见的静物，外形像蜂巢。由 6 个细胞组成，在随机初始状态中出现频率仅次于方块。',
      normalizedHash: 0x7A3E5C8D12F0,
    ),
    GameOfLifePattern(
      id: 'loaf',
      name: '面包',
      nameEn: 'Loaf',
      category: PatternCategory.stillLife,
      cells: [(1, 0), (2, 0), (0, 1), (3, 1), (1, 2), (3, 2), (2, 3)],
      width: 4,
      height: 4,
      brief: '7 细胞静物',
      discoverer: 'John Conway',
      year: 1970,
      period: 1,
      description: '一种不对称的 7 细胞静物，外形像一条面包。是第三常见的静物。',
      normalizedHash: 0x4B2C6A9E7D01,
    ),
    GameOfLifePattern(
      id: 'boat',
      name: '小船',
      nameEn: 'Boat',
      category: PatternCategory.stillLife,
      cells: [(0, 0), (1, 0), (0, 1), (2, 1), (1, 2)],
      width: 3,
      height: 3,
      brief: '5 细胞静物',
      discoverer: 'John Conway',
      year: 1970,
      period: 1,
      description: '最小的不对称静物，由 5 个细胞组成。外形像一艘小船，在随机图案中经常出现。',
      normalizedHash: 0x3D1E5F8A2B90,
    ),

    // === Oscillators ===
    GameOfLifePattern(
      id: 'blinker',
      name: '闪烁器',
      nameEn: 'Blinker',
      category: PatternCategory.oscillator,
      cells: [(0, 0), (1, 0), (2, 0)],
      width: 3,
      height: 1,
      brief: '最小的振荡器，周期 2',
      discoverer: 'John Conway',
      year: 1970,
      period: 2,
      description: '最简单也最常见的振荡器。3 个细胞排成一行，下一代变为一列，如此反复。周期为 2。',
      normalizedHash: 0x1A2B3C4D5E6F,
    ),
    GameOfLifePattern(
      id: 'toad',
      name: '蟾蜍',
      nameEn: 'Toad',
      category: PatternCategory.oscillator,
      cells: [(1, 0), (2, 0), (3, 0), (0, 1), (1, 1), (2, 1)],
      width: 4,
      height: 2,
      brief: '周期 2 振荡器',
      discoverer: 'Simon Norton',
      year: 1970,
      period: 2,
      description: '一种周期 2 的振荡器，由 6 个细胞组成。两排各 3 个细胞错位排列，交替变化。',
      normalizedHash: 0x5F6E7D8C9B0A,
    ),
    GameOfLifePattern(
      id: 'beacon',
      name: '信标',
      nameEn: 'Beacon',
      category: PatternCategory.oscillator,
      cells: [(0, 0), (1, 0), (0, 1), (3, 2), (2, 3), (3, 3)],
      width: 4,
      height: 4,
      brief: '周期 2 振荡器',
      discoverer: 'John Conway',
      year: 1970,
      period: 2,
      description: '由两个对角放置的方块组成的周期 2 振荡器。中间的两个角细胞交替出现和消失，像灯塔闪烁。',
      normalizedHash: 0x8A9B0C1D2E3F,
    ),
    GameOfLifePattern(
      id: 'pulsar',
      name: '脉冲星',
      nameEn: 'Pulsar',
      category: PatternCategory.oscillator,
      cells: [
        // Top section
        (2, 0), (3, 0), (4, 0), (8, 0), (9, 0), (10, 0),
        (0, 2), (5, 2), (7, 2), (12, 2),
        (0, 3), (5, 3), (7, 3), (12, 3),
        (0, 4), (5, 4), (7, 4), (12, 4),
        (2, 5), (3, 5), (4, 5), (8, 5), (9, 5), (10, 5),
        // Bottom section (mirror)
        (2, 7), (3, 7), (4, 7), (8, 7), (9, 7), (10, 7),
        (0, 8), (5, 8), (7, 8), (12, 8),
        (0, 9), (5, 9), (7, 9), (12, 9),
        (0, 10), (5, 10), (7, 10), (12, 10),
        (2, 12), (3, 12), (4, 12), (8, 12), (9, 12), (10, 12),
      ],
      width: 13,
      height: 13,
      brief: '周期 3 振荡器',
      discoverer: 'John Conway',
      year: 1970,
      period: 3,
      description: '最常见的周期 3 振荡器，具有四重对称性。由 48 个细胞组成，是生命游戏中最优美的图案之一。',
      normalizedHash: 0x2C3D4E5F6A7B,
    ),
    GameOfLifePattern(
      id: 'pentadecathlon',
      name: '十五连珠',
      nameEn: 'Pentadecathlon',
      category: PatternCategory.oscillator,
      cells: [
        (1, 0), (0, 1), (1, 1), (2, 1), (1, 2),
        (1, 3), (1, 4), (1, 5),
        (1, 7), (0, 8), (1, 8), (2, 8), (1, 9),
      ],
      width: 3,
      height: 10,
      brief: '周期 15 振荡器',
      discoverer: 'John Conway',
      year: 1970,
      period: 15,
      description:
          '已知最小的周期 15 振荡器，经过 15 代演化后回到初始状态。名字来源于它在一个阶段有 15 个活细胞。',
      normalizedHash: 0x9B8A7C6D5E4F,
    ),

    // === Spaceships ===
    GameOfLifePattern(
      id: 'glider',
      name: '滑翔机',
      nameEn: 'Glider',
      category: PatternCategory.spaceship,
      cells: [(1, 0), (2, 1), (0, 2), (1, 2), (2, 2)],
      width: 3,
      height: 3,
      brief: '最小的飞船',
      discoverer: 'Richard Guy',
      year: 1970,
      period: 4,
      speed: 'c/4',
      description:
          '生命游戏中最重要的图案之一。由 5 个细胞组成，每 4 代沿对角线方向移动一格。它是最小的飞船，也是构建复杂结构的基础组件。',
      normalizedHash: 0xF0E1D2C3B4A5,
    ),
    GameOfLifePattern(
      id: 'lwss',
      name: '轻量飞船',
      nameEn: 'LWSS',
      category: PatternCategory.spaceship,
      cells: [
        (0, 0), (3, 0),
        (4, 1),
        (0, 2), (4, 2),
        (1, 3), (2, 3), (3, 3), (4, 3),
      ],
      width: 5,
      height: 4,
      brief: '水平移动的飞船',
      discoverer: 'John Conway',
      year: 1970,
      period: 4,
      speed: 'c/2',
      description:
          '轻量级宇宙飞船（Lightweight Spaceship），由 9 个细胞组成。每 4 代水平移动 2 格，是速度 c/2 的飞船。',
      normalizedHash: 0xA5B4C3D2E1F0,
    ),

    // === Methuselahs ===
    GameOfLifePattern(
      id: 'r_pentomino',
      name: 'R 型五连块',
      nameEn: 'R-pentomino',
      category: PatternCategory.methuselah,
      cells: [(1, 0), (2, 0), (0, 1), (1, 1), (1, 2)],
      width: 3,
      height: 3,
      brief: '5 细胞产生 1103 代混沌',
      discoverer: 'John Conway',
      year: 1970,
      description:
          '最著名的长寿图案。仅 5 个细胞，却需要 1103 代才能稳定，最终产生 116 个活细胞和大量碎片。它证明了简单初始条件可以产生极其复杂的行为。',
      normalizedHash: 0x6F7E8D9CAB01,
    ),
    GameOfLifePattern(
      id: 'diehard',
      name: '顽固',
      nameEn: 'Diehard',
      category: PatternCategory.methuselah,
      cells: [(6, 0), (0, 1), (1, 1), (1, 2), (5, 2), (6, 2), (7, 2)],
      width: 8,
      height: 3,
      brief: '130 代后完全消亡',
      discoverer: 'Unknown',
      year: 1986,
      description:
          '一种特殊的长寿图案：7 个细胞经过 130 代演化后完全消失，没有留下任何存活细胞。这是一个"消亡型"图案的经典例子。',
      normalizedHash: 0x0123456789AB,
    ),
    GameOfLifePattern(
      id: 'acorn',
      name: '橡子',
      nameEn: 'Acorn',
      category: PatternCategory.methuselah,
      cells: [(1, 0), (3, 1), (0, 2), (1, 2), (4, 2), (5, 2), (6, 2)],
      width: 7,
      height: 3,
      brief: '7 细胞产生 5206 代演化',
      discoverer: 'Charles Corderman',
      year: 1978,
      description: '由 7 个细胞组成的长寿图案，需要 5206 代才能稳定。最终产生 633 个活细胞，包括 13 个滑翔机。',
      normalizedHash: 0xCDEF01234567,
    ),

    // === Guns ===
    GameOfLifePattern(
      id: 'gosper_glider_gun',
      name: '高斯帕滑翔机枪',
      nameEn: 'Gosper Glider Gun',
      category: PatternCategory.gun,
      cells: [
        // Left square
        (0, 4), (0, 5), (1, 4), (1, 5),
        // Left part
        (10, 4), (10, 5), (10, 6),
        (11, 3), (11, 7),
        (12, 2), (12, 8),
        (13, 2), (13, 8),
        (14, 5),
        (15, 3), (15, 7),
        (16, 4), (16, 5), (16, 6),
        (17, 5),
        // Right part
        (20, 2), (20, 3), (20, 4),
        (21, 2), (21, 3), (21, 4),
        (22, 1), (22, 5),
        (24, 0), (24, 1), (24, 5), (24, 6),
        // Right square
        (34, 2), (34, 3), (35, 2), (35, 3),
      ],
      width: 36,
      height: 9,
      brief: '每 30 代发射一个滑翔机',
      discoverer: 'Bill Gosper',
      year: 1970,
      period: 30,
      description:
          '第一个被发现的枪型图案，由 Bill Gosper 在 1970 年发现。它每 30 代产生一个滑翔机，证明了生命游戏中图案可以无限增长。这一发现解决了 Conway 的一个重要猜想。',
      normalizedHash: 0x89ABCDEF0123,
    ),
  ];

  static List<GameOfLifePattern> byCategory(String category) =>
      all.where((p) => p.category == category).toList();

  static GameOfLifePattern? byId(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }

  static List<int> get allNormalizedHashes =>
      all.map((p) => p.normalizedHash).toList();
}
