// lib/sokoban/sokoban_mode_page.dart
import 'package:flutter/material.dart';
import '../shared/score_service.dart';
import 'sokoban_levels.dart';

class SokobanModePage extends StatefulWidget {
  const SokobanModePage({super.key});

  @override
  State<SokobanModePage> createState() => _SokobanModePageState();
}

class _SokobanModePageState extends State<SokobanModePage> {
  final Map<int, int> _bestMoves = {};

  @override
  void initState() {
    super.initState();
    _loadScores();
  }

  Future<void> _loadScores() async {
    final service = ScoreService();
    for (int i = 0; i < sokobanLevels.length; i++) {
      final score = await service.getHighScore('sokoban', 'level_$i');
      if (score > 0) {
        _bestMoves[i] = score;
      }
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Sokoban'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final diff in SokobanDifficulty.values) ...[
            _DifficultyHeader(difficulty: diff),
            const SizedBox(height: 8),
            _LevelGrid(
              difficulty: diff,
              bestMoves: _bestMoves,
              onRefresh: _loadScores,
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}

class _DifficultyHeader extends StatelessWidget {
  final SokobanDifficulty difficulty;

  const _DifficultyHeader({required this.difficulty});

  Color get _color {
    switch (difficulty) {
      case SokobanDifficulty.easy:
        return const Color(0xFF4ECCA3);
      case SokobanDifficulty.medium:
        return const Color(0xFF3A86FF);
      case SokobanDifficulty.hard:
        return const Color(0xFFF0C040);
      case SokobanDifficulty.expert:
        return const Color(0xFFE84545);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      difficulty.label,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: _color,
      ),
    );
  }
}

class _LevelGrid extends StatelessWidget {
  final SokobanDifficulty difficulty;
  final Map<int, int> bestMoves;
  final VoidCallback onRefresh;

  const _LevelGrid({
    required this.difficulty,
    required this.bestMoves,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(difficulty.count, (i) {
        final levelIndex = difficulty.startIndex + i;
        final best = bestMoves[levelIndex];
        final cleared = best != null;
        return _LevelTile(
          levelNumber: levelIndex + 1,
          levelIndex: levelIndex,
          bestMoves: best,
          cleared: cleared,
          onRefresh: onRefresh,
        );
      }),
    );
  }
}

class _LevelTile extends StatelessWidget {
  final int levelNumber;
  final int levelIndex;
  final int? bestMoves;
  final bool cleared;
  final VoidCallback onRefresh;

  const _LevelTile({
    required this.levelNumber,
    required this.levelIndex,
    required this.bestMoves,
    required this.cleared,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/sokoban/play',
          arguments: levelIndex,
        ).then((_) => onRefresh());
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(10),
          border: cleared
              ? Border.all(color: const Color(0xFF4ECCA3), width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (cleared)
              const Icon(Icons.check_circle, color: Color(0xFF4ECCA3), size: 20),
            Text(
              '$levelNumber',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (bestMoves != null)
              Text(
                '$bestMoves steps',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 10,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
