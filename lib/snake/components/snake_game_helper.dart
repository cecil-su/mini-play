import 'package:flutter/material.dart';

import '../../shared/game_over_data.dart';
import '../../shared/game_over_page.dart';
import '../../shared/score_service.dart';

/// Builds a standard game-over callback for snake modes.
/// Saves the score, loads the best, and navigates to GameOverPage.
void Function(Map<String, String>) buildSnakeGameOverCallback({
  required BuildContext context,
  required String scoreMode,
  required VoidCallback onReplay,
}) {
  return (stats) async {
    final score = int.tryParse(stats['Score'] ?? '0') ?? 0;
    await ScoreService().saveHighScore('snake', scoreMode, score);
    final best = await ScoreService().getHighScore('snake', scoreMode);
    stats['Best'] = '$best';
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameOverPage(
          data: GameOverData(
            gameName: 'snake',
            mode: scoreMode,
            stats: stats,
            replayCallback: onReplay,
          ),
        ),
      ),
    );
  };
}
