// lib/breakout/breakout_mode_page.dart
import 'package:flutter/material.dart';
import '../shared/game_mode_card.dart';
import 'breakout_config.dart';

class BreakoutModePage extends StatelessWidget {
  const BreakoutModePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Breakout'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GameModeCard(
            title: 'Classic',
            description: '3 lives, standard speed. Clear all bricks to win.',
            icon: Icons.play_arrow,
            accent: const Color(0xFF4ECCA3),
            gameName: 'breakout',
            scoreKey: 'classic',
            route: '/breakout/play',
            arguments: BreakoutMode.classic,
          ),
          GameModeCard(
            title: 'Hard',
            description: '1 life, 1.5x ball speed. One mistake and it\'s over.',
            icon: Icons.local_fire_department,
            accent: const Color(0xFFE84545),
            gameName: 'breakout',
            scoreKey: 'hard',
            route: '/breakout/play',
            arguments: BreakoutMode.hard,
          ),
          GameModeCard(
            title: 'Endless',
            description: 'Survive as long as you can. Speed increases each round.',
            icon: Icons.all_inclusive,
            accent: const Color(0xFF3A86FF),
            gameName: 'breakout',
            scoreKey: 'endless',
            route: '/breakout/play',
            arguments: BreakoutMode.endless,
          ),
        ],
      ),
    );
  }
}
