import 'package:flutter/material.dart';

import 'score_service.dart';

class GameModeCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final String gameName;
  final String scoreKey;
  final String route;
  final Object? arguments;
  final String Function(int)? bestFormatter;

  const GameModeCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    required this.gameName,
    required this.scoreKey,
    required this.route,
    this.arguments,
    this.bestFormatter,
  });

  @override
  State<GameModeCard> createState() => _GameModeCardState();
}

class _GameModeCardState extends State<GameModeCard> {
  int _bestScore = 0;

  @override
  void initState() {
    super.initState();
    _loadScore();
  }

  Future<void> _loadScore() async {
    final score =
        await ScoreService().getHighScore(widget.gameName, widget.scoreKey);
    if (mounted) {
      setState(() => _bestScore = score);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bestText = widget.bestFormatter != null
        ? widget.bestFormatter!(_bestScore)
        : 'Best: $_bestScore';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(
            context,
            widget.route,
            arguments: widget.arguments,
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
                  color: widget.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, color: widget.accent, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: widget.accent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.description,
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
                bestText,
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
