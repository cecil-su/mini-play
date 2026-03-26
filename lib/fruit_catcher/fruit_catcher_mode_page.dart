import 'package:flutter/material.dart';
import '../shared/game_mode_card.dart';
import 'fruit_catcher_config.dart';

class FruitCatcherModePage extends StatelessWidget {
  const FruitCatcherModePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Fruit Catcher'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GameModeCard(
            title: 'Timed',
            description:
                '60s countdown. Catch fruits, dodge bombs. Combo streaks add time!',
            icon: Icons.timer,
            accent: const Color(0xFF4ECCA3),
            gameName: 'fruit_catcher',
            scoreKey: 'timed',
            route: '/fruit_catcher/play',
            arguments: FruitCatcherMode.timed,
          ),
          GameModeCard(
            title: 'Classic',
            description:
                '5 lives. Miss a fruit or catch a bomb to lose a life.',
            icon: Icons.favorite,
            accent: const Color(0xFFE84545),
            gameName: 'fruit_catcher',
            scoreKey: 'classic',
            route: '/fruit_catcher/play',
            arguments: FruitCatcherMode.classic,
          ),
          GameModeCard(
            title: 'Endless',
            description:
                'One bomb ends it all. Survive waves of increasing difficulty.',
            icon: Icons.all_inclusive,
            accent: const Color(0xFFF0C040),
            gameName: 'fruit_catcher',
            scoreKey: 'endless',
            route: '/fruit_catcher/play',
            arguments: FruitCatcherMode.endless,
          ),
        ],
      ),
    );
  }
}
