import 'package:flutter/material.dart';

class GameOverAction {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  const GameOverAction({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
  });
}

class GameOverData {
  final String gameName;
  final String mode;
  final Map<String, String> stats;
  final VoidCallback replayCallback;
  final String? title;
  final List<GameOverAction>? actions;

  const GameOverData({
    required this.gameName,
    required this.mode,
    required this.stats,
    required this.replayCallback,
    this.title,
    this.actions,
  });
}
