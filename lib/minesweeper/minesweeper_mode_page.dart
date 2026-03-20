// lib/minesweeper/minesweeper_mode_page.dart
import 'package:flutter/material.dart';
import '../shared/score_service.dart';
import 'minesweeper_cell.dart';
import 'minesweeper_page.dart';

class MinesweeperModePage extends StatelessWidget {
  const MinesweeperModePage({super.key});

  static const _modes = [
    _ModeInfo(
      title: 'Beginner',
      description: '9×9, 10 mines',
      icon: Icons.sentiment_satisfied,
      accent: Color(0xFF4ECCA3),
      difficulty: MinesweeperDifficulty.beginner,
    ),
    _ModeInfo(
      title: 'Intermediate',
      description: '16×16, 40 mines',
      icon: Icons.sentiment_neutral,
      accent: Color(0xFF3A86FF),
      difficulty: MinesweeperDifficulty.intermediate,
    ),
    _ModeInfo(
      title: 'Expert',
      description: '16×30, 99 mines',
      icon: Icons.sentiment_very_dissatisfied,
      accent: Color(0xFFE84545),
      difficulty: MinesweeperDifficulty.expert,
    ),
  ];

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
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _modes.length,
        itemBuilder: (context, index) {
          final mode = _modes[index];
          return _ModeCard(mode: mode);
        },
      ),
    );
  }
}

class _ModeInfo {
  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final MinesweeperDifficulty difficulty;

  const _ModeInfo({
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    required this.difficulty,
  });
}

class _ModeCard extends StatefulWidget {
  final _ModeInfo mode;

  const _ModeCard({required this.mode});

  @override
  State<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<_ModeCard> {
  int _bestTime = 0;

  @override
  void initState() {
    super.initState();
    _loadScore();
  }

  Future<void> _loadScore() async {
    final score = await ScoreService()
        .getHighScore('minesweeper', widget.mode.difficulty.scoreMode);
    if (mounted) {
      setState(() => _bestTime = score);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.mode;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/minesweeper/play',
            arguments: mode.difficulty,
          ).then((_) => _loadScore());
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF16213E),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: mode.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(mode.icon, color: mode.accent, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: mode.accent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mode.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _bestTime == 0 ? 'Best: --' : 'Best: ${formatTime(_bestTime)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF0C040),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
