// lib/tetris/tetris_mode_page.dart
import 'package:flutter/material.dart';
import '../shared/score_service.dart';
import 'tetris_board.dart';

class TetrisModePage extends StatelessWidget {
  const TetrisModePage({super.key});

  static const _modes = [
    _ModeInfo(
      title: 'Classic',
      description: '\u6807\u51C6\u6A21\u5F0F\uFF0C\u901F\u5EA6\u9010\u6E10\u52A0\u5FEB',
      icon: Icons.play_arrow,
      accent: Color(0xFF4ECCA3),
      mode: TetrisGameMode.classic,
      scoreMode: 'classic',
    ),
    _ModeInfo(
      title: 'Sprint',
      description: '40\u884C\u7ADE\u901F\uFF0C\u8D8A\u5FEB\u8D8A\u597D',
      icon: Icons.timer,
      accent: Color(0xFF3A86FF),
      mode: TetrisGameMode.sprint,
      scoreMode: 'sprint',
    ),
    _ModeInfo(
      title: 'Marathon',
      description: '\u65E0\u5C3D\u6A21\u5F0F\uFF0C15\u7EA7\u5C01\u9876',
      icon: Icons.all_inclusive,
      accent: Color(0xFFE84545),
      mode: TetrisGameMode.marathon,
      scoreMode: 'marathon',
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
        title: const Text('Tetris'),
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
  final TetrisGameMode mode;
  final String scoreMode;

  const _ModeInfo({
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    required this.mode,
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
    final score = await ScoreService()
        .getHighScore('tetris', widget.mode.scoreMode);
    if (mounted) {
      setState(() => _bestScore = score);
    }
  }

  String _formatBest() {
    if (_bestScore == 0) return 'Best: --';
    if (widget.mode.mode == TetrisGameMode.sprint) {
      return 'Best: ${_formatTime(_bestScore)}';
    }
    return 'Best: $_bestScore';
  }

  String _formatTime(int seconds) {
    if (seconds < 60) return '$seconds s';
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
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
            '/tetris/play',
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
                _formatBest(),
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
