// lib/tetris/tetris_mode_page.dart
import 'package:flutter/material.dart';

import '../shared/format_time.dart';
import '../shared/game_mode_card.dart';
import 'tetris_board.dart';

class TetrisModePage extends StatelessWidget {
  const TetrisModePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Tetris'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GameModeCard(
            title: 'Classic',
            description: '标准模式，速度逐渐加快',
            icon: Icons.play_arrow,
            accent: const Color(0xFF4ECCA3),
            gameName: 'tetris',
            scoreKey: 'classic',
            route: '/tetris/play',
            arguments: TetrisGameMode.classic,
          ),
          GameModeCard(
            title: 'Sprint',
            description: '40行竞速，越快越好',
            icon: Icons.timer,
            accent: const Color(0xFF3A86FF),
            gameName: 'tetris',
            scoreKey: 'sprint',
            route: '/tetris/play',
            arguments: TetrisGameMode.sprint,
            bestFormatter: (v) =>
                v == 0 ? 'Best: --' : 'Best: ${formatTime(v)}',
          ),
          GameModeCard(
            title: 'Marathon',
            description: '无尽模式，15级封顶',
            icon: Icons.all_inclusive,
            accent: const Color(0xFFE84545),
            gameName: 'tetris',
            scoreKey: 'marathon',
            route: '/tetris/play',
            arguments: TetrisGameMode.marathon,
          ),
        ],
      ),
    );
  }
}
