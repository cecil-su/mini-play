// lib/flappybird/flappybird_mode_page.dart
import 'package:flutter/material.dart';
import '../shared/game_mode_card.dart';
import 'flappybird_config.dart';

class FlappybirdModePage extends StatelessWidget {
  const FlappybirdModePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Flappy Bird'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GameModeCard(
            title: 'Easy',
            description: 'Slow speed, wide gaps. Great for practice.',
            icon: Icons.sentiment_satisfied,
            accent: const Color(0xFF4ECCA3),
            gameName: 'flappybird',
            scoreKey: 'easy',
            route: '/flappybird/play',
            arguments: FlappybirdMode.easy,
          ),
          GameModeCard(
            title: 'Normal',
            description: 'Standard speed and gaps. The classic experience.',
            icon: Icons.flutter_dash,
            accent: const Color(0xFF3A86FF),
            gameName: 'flappybird',
            scoreKey: 'normal',
            route: '/flappybird/play',
            arguments: FlappybirdMode.normal,
          ),
          GameModeCard(
            title: 'Hard',
            description: 'Fast speed, tight gaps. Only for the brave.',
            icon: Icons.local_fire_department,
            accent: const Color(0xFFE84545),
            gameName: 'flappybird',
            scoreKey: 'hard',
            route: '/flappybird/play',
            arguments: FlappybirdMode.hard,
          ),
        ],
      ),
    );
  }
}
