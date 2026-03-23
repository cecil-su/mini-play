import 'package:flutter/material.dart';

import '../shared/game_mode_card.dart';

class SnakeModePage extends StatelessWidget {
  const SnakeModePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Snake'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GameModeCard(
            title: 'Classic',
            description: 'Fixed 20×20 grid, constant speed',
            icon: Icons.grid_on,
            accent: const Color(0xFF4ECCA3),
            gameName: 'snake',
            scoreKey: 'classic',
            route: '/snake/classic',
          ),
          GameModeCard(
            title: 'Adaptive',
            description: 'Grid adapts to screen size',
            icon: Icons.aspect_ratio,
            accent: const Color(0xFF3A86FF),
            gameName: 'snake',
            scoreKey: 'adaptive',
            route: '/snake/adaptive',
          ),
          GameModeCard(
            title: 'Free',
            description: 'Smooth movement, no grid limits',
            icon: Icons.all_inclusive,
            accent: const Color(0xFFE84545),
            gameName: 'snake',
            scoreKey: 'free',
            route: '/snake/free',
          ),
        ],
      ),
    );
  }
}
