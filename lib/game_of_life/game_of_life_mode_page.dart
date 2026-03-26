import 'package:flutter/material.dart';

import '../shared/game_mode_card.dart';
import 'game_of_life_colors.dart';
import 'game_of_life_config.dart';

class GameOfLifeModePage extends StatelessWidget {
  const GameOfLifeModePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameOfLifeColors.background,
      appBar: AppBar(
        title: const Text('Game of Life'),
        backgroundColor: GameOfLifeColors.background,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GameModeCard(
            title: '沙盒',
            description: '自由创作，探索生命演化',
            icon: Icons.brush,
            accent: GameOfLifeColors.cellAlive,
            gameName: GameOfLifeConfig.gameName,
            scoreKey: 'sandbox',
            route: '/gameoflife/sandbox',
            bestFormatter: (gen) => gen > 0 ? 'Gen $gen' : '',
          ),
          const SizedBox(height: 12),
          GameModeCard(
            title: '挑战',
            description: '15 关目标挑战',
            icon: Icons.emoji_events,
            accent: Colors.amber,
            gameName: GameOfLifeConfig.gameName,
            scoreKey: 'challenge_total',
            route: '/gameoflife/challenge',
            bestFormatter: (stars) => stars > 0 ? '$stars ⭐' : '',
          ),
          const SizedBox(height: 12),
          GameModeCard(
            title: '图鉴百科',
            description: '探索经典图案',
            icon: Icons.auto_stories,
            accent: Colors.blueAccent,
            gameName: GameOfLifeConfig.gameName,
            scoreKey: 'encyclopedia',
            route: '/gameoflife/encyclopedia',
            bestFormatter: (_) => '',
          ),
        ],
      ),
    );
  }
}
