import 'package:flutter/material.dart';

class GameOverData {
  final String gameName;
  final String mode;
  final Map<String, String> stats;
  final VoidCallback replayCallback;

  const GameOverData({
    required this.gameName,
    required this.mode,
    required this.stats,
    required this.replayCallback,
  });
}
