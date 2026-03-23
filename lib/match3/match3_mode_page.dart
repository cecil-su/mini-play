// lib/match3/match3_mode_page.dart
import 'package:flutter/material.dart';

import '../shared/game_mode_card.dart';
import 'match3_gem.dart';

class Match3ModePage extends StatelessWidget {
  const Match3ModePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Match-3'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GameModeCard(
            title: 'Classic',
            description: 'Endless mode, game over when no moves left',
            icon: Icons.all_inclusive,
            accent: const Color(0xFF4ECCA3),
            gameName: 'match3',
            scoreKey: Match3GameMode.classic.name,
            route: '/match3/play',
            arguments: Match3GameMode.classic,
            bestFormatter: (v) => v == 0 ? 'Best: --' : 'Best: $v',
          ),
          GameModeCard(
            title: 'Timed',
            description: '60 seconds, score as much as you can',
            icon: Icons.timer,
            accent: const Color(0xFF3A86FF),
            gameName: 'match3',
            scoreKey: Match3GameMode.timed.name,
            route: '/match3/play',
            arguments: Match3GameMode.timed,
            bestFormatter: (v) => v == 0 ? 'Best: --' : 'Best: $v',
          ),
          GameModeCard(
            title: 'Moves',
            description: '30 moves, make them count',
            icon: Icons.swipe,
            accent: const Color(0xFFE84545),
            gameName: 'match3',
            scoreKey: Match3GameMode.moves.name,
            route: '/match3/play',
            arguments: Match3GameMode.moves,
            bestFormatter: (v) => v == 0 ? 'Best: --' : 'Best: $v',
          ),
        ],
      ),
    );
  }
}
