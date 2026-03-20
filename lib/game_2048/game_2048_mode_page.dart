// lib/game_2048/game_2048_mode_page.dart
import 'package:flutter/material.dart';
import '../shared/score_service.dart';

class Game2048ModePage extends StatelessWidget {
  const Game2048ModePage({super.key});

  static const _modes = [
    _ModeInfo(
      title: '3\u00D73',
      description: '\u5FEB\u901F\u6311\u6218',
      icon: Icons.grid_3x3,
      accent: Color(0xFFE84545),
      gridSize: 3,
      scoreMode: '3x3',
    ),
    _ModeInfo(
      title: '4\u00D74',
      description: '\u7ECF\u5178\u6A21\u5F0F',
      icon: Icons.grid_4x4,
      accent: Color(0xFF4ECCA3),
      gridSize: 4,
      scoreMode: '4x4',
    ),
    _ModeInfo(
      title: '5\u00D75',
      description: '\u6269\u5C55\u68CB\u76D8',
      icon: Icons.grid_on,
      accent: Color(0xFF3A86FF),
      gridSize: 5,
      scoreMode: '5x5',
    ),
    _ModeInfo(
      title: '6\u00D76',
      description: '\u7EC8\u6781\u6311\u6218',
      icon: Icons.apps,
      accent: Color(0xFFF0C040),
      gridSize: 6,
      scoreMode: '6x6',
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
        title: const Text('2048'),
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
  final int gridSize;
  final String scoreMode;

  const _ModeInfo({
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    required this.gridSize,
    required this.scoreMode,
  });
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
        await ScoreService().getHighScore('2048', widget.mode.scoreMode);
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
            '/2048/play',
            arguments: mode.gridSize,
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
                'Best: $_bestScore',
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
