// lib/sudoku/sudoku_mode_page.dart
import 'package:flutter/material.dart';
import '../shared/game_mode_card.dart';
import 'sudoku_cell.dart';

class SudokuModePage extends StatelessWidget {
  const SudokuModePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Sudoku'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _modeCard(SudokuDifficulty.easy, Icons.sentiment_satisfied,
              const Color(0xFF4ECCA3), '9×9, 32 空格'),
          _modeCard(SudokuDifficulty.medium, Icons.sentiment_neutral,
              const Color(0xFF3A86FF), '9×9, 40 空格'),
          _modeCard(SudokuDifficulty.hard, Icons.sentiment_dissatisfied,
              const Color(0xFFF0C040), '9×9, 48 空格'),
          _modeCard(SudokuDifficulty.expert, Icons.sentiment_very_dissatisfied,
              const Color(0xFFE84545), '9×9, 54 空格'),
        ],
      ),
    );
  }

  Widget _modeCard(SudokuDifficulty diff, IconData icon, Color accent, String desc) {
    return GameModeCard(
      title: diff.name,
      description: desc,
      icon: icon,
      accent: accent,
      gameName: 'sudoku',
      scoreKey: diff.scoreMode,
      route: '/sudoku/play',
      arguments: diff,
      bestFormatter: (v) => v == 0 ? 'Best: --' : 'Best: $v',
    );
  }
}
