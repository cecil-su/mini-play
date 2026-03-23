// lib/game_2048/game_2048_mode_page.dart
import 'package:flutter/material.dart';

import '../shared/game_mode_card.dart';

class Game2048ModePage extends StatelessWidget {
  const Game2048ModePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('2048'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GameModeCard(
            title: '3×3',
            description: '快速挑战',
            icon: Icons.grid_3x3,
            accent: const Color(0xFFE84545),
            gameName: '2048',
            scoreKey: '3x3',
            route: '/2048/play',
            arguments: 3,
          ),
          GameModeCard(
            title: '4×4',
            description: '经典模式',
            icon: Icons.grid_4x4,
            accent: const Color(0xFF4ECCA3),
            gameName: '2048',
            scoreKey: '4x4',
            route: '/2048/play',
            arguments: 4,
          ),
          GameModeCard(
            title: '5×5',
            description: '扩展棋盘',
            icon: Icons.grid_on,
            accent: const Color(0xFF3A86FF),
            gameName: '2048',
            scoreKey: '5x5',
            route: '/2048/play',
            arguments: 5,
          ),
          GameModeCard(
            title: '6×6',
            description: '终极挑战',
            icon: Icons.apps,
            accent: const Color(0xFFF0C040),
            gameName: '2048',
            scoreKey: '6x6',
            route: '/2048/play',
            arguments: 6,
          ),
        ],
      ),
    );
  }
}
