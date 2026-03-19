import 'package:flutter/material.dart';
import '../shared/score_service.dart';

class SnakeModePage extends StatelessWidget {
  const SnakeModePage({super.key});

  static const _modes = [
    _ModeInfo(
      title: 'Classic',
      description: 'Fixed 20×20 grid, constant speed',
      icon: Icons.grid_on,
      accent: Color(0xFF4ECCA3),
      route: '/snake/classic',
      scoreMode: 'classic',
    ),
    _ModeInfo(
      title: 'Adaptive',
      description: 'Grid adapts to screen size',
      icon: Icons.aspect_ratio,
      accent: Color(0xFF3A86FF),
      route: '/snake/adaptive',
      scoreMode: 'adaptive',
    ),
    _ModeInfo(
      title: 'Free',
      description: 'Smooth movement, no grid limits',
      icon: Icons.all_inclusive,
      accent: Color(0xFFE84545),
      route: '/snake/free',
      scoreMode: 'free',
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
        title: const Text('Snake'),
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
  final String route;
  final String scoreMode;

  const _ModeInfo({
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    required this.route,
    required this.scoreMode,
  });
}

class _ModeCard extends StatelessWidget {
  final _ModeInfo mode;

  const _ModeCard({required this.mode});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, mode.route),
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
                child: Icon(
                  mode.icon,
                  color: mode.accent,
                  size: 28,
                ),
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
              FutureBuilder<int>(
                future:
                    ScoreService().getHighScore('snake', mode.scoreMode),
                builder: (context, snapshot) {
                  final score = snapshot.data ?? 0;
                  return Text(
                    'Best: $score',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF0C040),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
