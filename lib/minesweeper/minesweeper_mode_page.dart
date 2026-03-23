// lib/minesweeper/minesweeper_mode_page.dart
import 'package:flutter/material.dart';

import '../shared/format_time.dart';
import '../shared/game_mode_card.dart';
import 'minesweeper_cell.dart';

class MinesweeperModePage extends StatelessWidget {
  const MinesweeperModePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Minesweeper'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GameModeCard(
            title: 'Beginner',
            description: '9×9, 10 mines',
            icon: Icons.sentiment_satisfied,
            accent: const Color(0xFF4ECCA3),
            gameName: 'minesweeper',
            scoreKey: MinesweeperDifficulty.beginner.scoreMode,
            route: '/minesweeper/play',
            arguments: MinesweeperDifficulty.beginner,
            bestFormatter: (v) =>
                v == 0 ? 'Best: --' : 'Best: ${formatTime(v)}',
          ),
          GameModeCard(
            title: 'Intermediate',
            description: '16×16, 40 mines',
            icon: Icons.sentiment_neutral,
            accent: const Color(0xFF3A86FF),
            gameName: 'minesweeper',
            scoreKey: MinesweeperDifficulty.intermediate.scoreMode,
            route: '/minesweeper/play',
            arguments: MinesweeperDifficulty.intermediate,
            bestFormatter: (v) =>
                v == 0 ? 'Best: --' : 'Best: ${formatTime(v)}',
          ),
          GameModeCard(
            title: 'Expert',
            description: '16×30, 99 mines',
            icon: Icons.sentiment_very_dissatisfied,
            accent: const Color(0xFFE84545),
            gameName: 'minesweeper',
            scoreKey: MinesweeperDifficulty.expert.scoreMode,
            route: '/minesweeper/play',
            arguments: MinesweeperDifficulty.expert,
            bestFormatter: (v) =>
                v == 0 ? 'Best: --' : 'Best: ${formatTime(v)}',
          ),
        ],
      ),
    );
  }
}
