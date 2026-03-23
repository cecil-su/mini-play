// lib/match3/match3_mode_page.dart
import 'package:flutter/material.dart';

import '../shared/score_service.dart';
import 'match3_gem.dart';

class Match3ModePage extends StatelessWidget {
  const Match3ModePage({super.key});

  static const _modes = [
    _ModeInfo(
      title: 'Classic',
      description: 'Endless mode, game over when no moves left',
      icon: Icons.all_inclusive,
      accent: Color(0xFF4ECCA3),
      mode: Match3GameMode.classic,
    ),
    _ModeInfo(
      title: 'Timed',
      description: '60 seconds, score as much as you can',
      icon: Icons.timer,
      accent: Color(0xFF3A86FF),
      mode: Match3GameMode.timed,
    ),
    _ModeInfo(
      title: 'Moves',
      description: '30 moves, make them count',
      icon: Icons.swipe,
      accent: Color(0xFFE84545),
      mode: Match3GameMode.moves,
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
        title: const Text('Match-3'),
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
  final Match3GameMode mode;

  const _ModeInfo({
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    required this.mode,
  });

  String get scoreKey => title.toLowerCase();
}

class _ModeCard extends StatefulWidget {
  final _ModeInfo mode;

  const _ModeCard({required this.mode});

  @override
  State<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<_ModeCard> {
  int _bestScore = 0;

  @override
  void initState() {
    super.initState();
    _loadScore();
  }

  Future<void> _loadScore() async {
    final score =
        await ScoreService().getHighScore('match3', widget.mode.scoreKey);
    if (mounted) {
      setState(() => _bestScore = score);
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
            '/match3/play',
            arguments: mode.mode,
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
                _bestScore == 0 ? 'Best: --' : 'Best: $_bestScore',
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
