import 'package:flutter/material.dart';
import 'game_registry.dart';

class GameCard extends StatelessWidget {
  final GameInfo game;
  final bool isGridMode;

  const GameCard({
    super.key,
    required this.game,
    required this.isGridMode,
  });

  @override
  Widget build(BuildContext context) {
    return isGridMode ? _buildGridCard(context) : _buildListCard(context);
  }

  Widget _buildGridCard(BuildContext context) {
    return Opacity(
      opacity: game.implemented ? 1.0 : 0.4,
      child: GestureDetector(
        onTap: game.implemented
            ? () => Navigator.pushNamed(context, game.route)
            : null,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF16213E),
            borderRadius: BorderRadius.circular(12),
            border: game.implemented
                ? Border.all(color: const Color(0xFF4ECCA3), width: 1)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF4ECCA3).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  game.icon,
                  size: 28,
                  color: const Color(0xFF4ECCA3),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                game.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListCard(BuildContext context) {
    return Opacity(
      opacity: game.implemented ? 1.0 : 0.4,
      child: ListTile(
        leading: Icon(
          game.icon,
          size: 40,
          color: const Color(0xFF4ECCA3),
        ),
        title: Text(game.name),
        subtitle: Text(
          game.description,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
        shape: game.implemented
            ? RoundedRectangleBorder(
                side: const BorderSide(color: Color(0xFF4ECCA3), width: 1),
                borderRadius: BorderRadius.circular(8),
              )
            : null,
        onTap: game.implemented
            ? () => Navigator.pushNamed(context, game.route)
            : null,
      ),
    );
  }
}
