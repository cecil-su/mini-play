enum ChallengeGoalType {
  stillLife,
  oscillator,
  spaceship,
  survive,
  extinct,
  population,
  oscillatorMinPeriod,
}

class ChallengeLevel {
  final int id;
  final String title;
  final String description;
  final Set<(int, int)> initialCells;
  final Set<(int, int)> lockedCells;
  final Set<(int, int)>? editableArea;
  final ChallengeGoalType goalType;
  final int goalParam;
  final int maxGenerations;
  final List<int> starThresholds; // [3-star max, 2-star max, 1-star max]
  final String? hintPatternId;
  final List<String>? tutorialSteps;

  const ChallengeLevel({
    required this.id,
    required this.title,
    required this.description,
    required this.initialCells,
    required this.lockedCells,
    this.editableArea,
    required this.goalType,
    required this.goalParam,
    required this.maxGenerations,
    required this.starThresholds,
    this.hintPatternId,
    this.tutorialSteps,
  });

  int calcStars(int userCellCount) {
    if (userCellCount <= starThresholds[0]) return 3;
    if (userCellCount <= starThresholds[1]) return 2;
    if (userCellCount <= starThresholds[2]) return 1;
    return 0;
  }
}

class ChallengeLevels {
  static const List<ChallengeLevel> all = [
    // === Beginner (Tutorial) ===
    ChallengeLevel(
      id: 1,
      title: '稳定方块',
      description: '放置 4 个细胞，让它们稳定成方块形状（不再变化）',
      initialCells: {},
      lockedCells: {},
      goalType: ChallengeGoalType.stillLife,
      goalParam: 1,
      maxGenerations: 50,
      starThresholds: [4, 5, 8],
      hintPatternId: 'block',
      tutorialSteps: [
        '提示：静物是指不再变化的图案',
        '试试在相邻位置放置 4 个细胞，组成 2×2 方块',
      ],
    ),
    ChallengeLevel(
      id: 2,
      title: '闪烁之光',
      description: '放置 3 个细胞，让它们在两种形态间反复切换',
      initialCells: {},
      lockedCells: {},
      goalType: ChallengeGoalType.oscillator,
      goalParam: 1,
      maxGenerations: 50,
      starThresholds: [3, 4, 6],
      hintPatternId: 'blinker',
      tutorialSteps: [
        '提示：振荡器是会在固定形态间循环的图案',
        '试试把 3 个细胞排成一行',
      ],
    ),
    ChallengeLevel(
      id: 3,
      title: '会飞的图案',
      description: '放置 5 个细胞，组成一个会移动的图案',
      initialCells: {},
      lockedCells: {},
      goalType: ChallengeGoalType.spaceship,
      goalParam: 1,
      maxGenerations: 100,
      starThresholds: [5, 6, 8],
      hintPatternId: 'glider',
    ),
    ChallengeLevel(
      id: 4,
      title: '走向消亡',
      description: '在已有细胞旁放置新细胞，让所有细胞在 5 代内全部消失',
      initialCells: {(5, 5), (6, 5)},
      lockedCells: {(5, 5), (6, 5)},
      goalType: ChallengeGoalType.extinct,
      goalParam: 5,
      maxGenerations: 5,
      starThresholds: [1, 2, 3],
    ),
    ChallengeLevel(
      id: 5,
      title: '顽强存活',
      description: '放置细胞，让图案持续存活超过 10 代',
      initialCells: {},
      lockedCells: {},
      goalType: ChallengeGoalType.survive,
      goalParam: 10,
      maxGenerations: 50,
      starThresholds: [3, 4, 6],
    ),

    // === Intermediate ===
    ChallengeLevel(
      id: 6,
      title: '蜂巢建造',
      description: '放置细胞，让它们演化成蜂巢形态（6 细胞静物）',
      initialCells: {},
      lockedCells: {},
      goalType: ChallengeGoalType.stillLife,
      goalParam: 1,
      maxGenerations: 100,
      starThresholds: [4, 6, 8],
      hintPatternId: 'beehive',
    ),
    ChallengeLevel(
      id: 7,
      title: '人口爆发',
      description: '用最少细胞让 20 代后活细胞数超过 20',
      initialCells: {},
      lockedCells: {},
      goalType: ChallengeGoalType.population,
      goalParam: 20,
      maxGenerations: 20,
      starThresholds: [5, 7, 10],
    ),
    ChallengeLevel(
      id: 8,
      title: '精准消亡',
      description: '让所有细胞在 10 代内消失',
      initialCells: {(10, 10), (11, 10), (12, 10), (10, 11)},
      lockedCells: {(10, 10), (11, 10), (12, 10), (10, 11)},
      goalType: ChallengeGoalType.extinct,
      goalParam: 10,
      maxGenerations: 10,
      starThresholds: [1, 2, 4],
    ),
    ChallengeLevel(
      id: 9,
      title: '稳定防线',
      description: '在给定细胞周围构建稳定结构，使其成为静物',
      initialCells: {(10, 10), (11, 10)},
      lockedCells: {(10, 10), (11, 10)},
      goalType: ChallengeGoalType.stillLife,
      goalParam: 1,
      maxGenerations: 50,
      starThresholds: [2, 4, 6],
    ),
    ChallengeLevel(
      id: 10,
      title: '持久战',
      description: '用最少细胞让图案存活超过 50 代',
      initialCells: {},
      lockedCells: {},
      goalType: ChallengeGoalType.survive,
      goalParam: 50,
      maxGenerations: 100,
      starThresholds: [5, 7, 10],
    ),

    // === Advanced ===
    ChallengeLevel(
      id: 11,
      title: '高周期振荡',
      description: '制造一个周期大于 2 的振荡器',
      initialCells: {},
      lockedCells: {},
      goalType: ChallengeGoalType.oscillatorMinPeriod,
      goalParam: 3,
      maxGenerations: 200,
      starThresholds: [12, 20, 30],
      hintPatternId: 'pulsar',
    ),
    ChallengeLevel(
      id: 12,
      title: '人口膨胀',
      description: '用最少细胞让 50 代后活细胞数超过初始的 3 倍',
      initialCells: {},
      lockedCells: {},
      goalType: ChallengeGoalType.population,
      goalParam: 50, // checked at gen 50, need 3x initial
      maxGenerations: 50,
      starThresholds: [5, 7, 10],
    ),
    ChallengeLevel(
      id: 13,
      title: '飞船编队',
      description: '同时制造两个飞船',
      initialCells: {},
      lockedCells: {},
      goalType: ChallengeGoalType.spaceship,
      goalParam: 1,
      maxGenerations: 100,
      starThresholds: [10, 12, 15],
    ),
    ChallengeLevel(
      id: 14,
      title: '长寿之星',
      description: '用最少细胞让图案存活超过 200 代',
      initialCells: {},
      lockedCells: {},
      goalType: ChallengeGoalType.survive,
      goalParam: 200,
      maxGenerations: 300,
      starThresholds: [5, 7, 10],
      hintPatternId: 'r_pentomino',
    ),
    ChallengeLevel(
      id: 15,
      title: '终极挑战',
      description: '用最少细胞让 100 代后活细胞数超过 100',
      initialCells: {},
      lockedCells: {},
      goalType: ChallengeGoalType.population,
      goalParam: 100,
      maxGenerations: 100,
      starThresholds: [5, 7, 10],
    ),
  ];
}
