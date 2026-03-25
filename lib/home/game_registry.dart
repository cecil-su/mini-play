import 'package:flutter/material.dart';

class GameInfo {
  final String name;
  final IconData icon;
  final String description;
  final int phase;
  final String route;
  final bool implemented;
  final bool hasModePage;

  const GameInfo({
    required this.name,
    required this.icon,
    required this.description,
    required this.phase,
    required this.route,
    this.implemented = false,
    this.hasModePage = false,
  });
}

class GameRegistry {
  static const List<GameInfo> games = [
    GameInfo(
      name: 'Snake',
      icon: Icons.pest_control,
      description: 'Classic snake game with 3 modes',
      phase: 1,
      route: '/snake',
      implemented: true,
      hasModePage: true,
    ),
    GameInfo(
      name: '2048',
      icon: Icons.grid_4x4,
      description: 'Slide and merge number tiles',
      phase: 1,
      route: '/2048',
      implemented: true,
      hasModePage: true,
    ),
    GameInfo(
      name: 'Minesweeper',
      icon: Icons.flag,
      description: 'Find all mines without detonating',
      phase: 1,
      route: '/minesweeper',
      implemented: true,
      hasModePage: true,
    ),
    GameInfo(
      name: 'Tetris',
      icon: Icons.view_comfy,
      description: 'Rotate and stack falling blocks',
      phase: 2,
      route: '/tetris',
      implemented: true,
      hasModePage: true,
    ),
    GameInfo(
      name: 'Match-3',
      icon: Icons.diamond,
      description: 'Swap tiles to match 3 or more',
      phase: 2,
      route: '/match3',
      implemented: true,
      hasModePage: true,
    ),
    GameInfo(
      name: 'Sokoban',
      icon: Icons.inventory_2,
      description: 'Push boxes onto target positions',
      phase: 2,
      route: '/sokoban',
      implemented: true,
      hasModePage: true,
    ),
    GameInfo(
      name: 'Sudoku',
      icon: Icons.grid_3x3,
      description: '填满9×9网格，每行列宫不重复',
      phase: 4,
      route: '/sudoku',
      implemented: true,
      hasModePage: true,
    ),
    GameInfo(
      name: 'Breakout',
      icon: Icons.sports_tennis,
      description: 'Break bricks with a ball and paddle',
      phase: 5,
      route: '/breakout',
      implemented: true,
      hasModePage: true,
    ),
    GameInfo(
      name: 'Flappy Bird',
      icon: Icons.flutter_dash,
      description: 'Tap to fly through gaps between pipes',
      phase: 3,
      route: '/flappybird',
      implemented: true,
      hasModePage: true,
    ),
    GameInfo(
      name: 'Klotski',
      icon: Icons.view_compact,
      description: '华容道 - 滑动方块，释放曹操',
      phase: 6,
      route: '/klotski',
      implemented: true,
      hasModePage: true,
    ),
  ];

  static List<GameInfo> byPhase(int phase) =>
      games.where((g) => g.phase == phase).toList();
}
