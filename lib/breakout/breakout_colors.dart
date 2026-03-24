// lib/breakout/breakout_colors.dart
import 'package:flutter/material.dart';
import 'breakout_models.dart';

class BreakoutColors {
  static const Color background = Color(0xFF1A1A2E);
  static const Color paddle = Color(0xFF4ECCA3);
  static const Color paddleWiden = Color(0xFF3A86FF);
  static const Color paddleShrink = Color(0xFFE84545);
  static const Color ball = Colors.white;
  static const Color ballPenetrating = Color(0xFFBB86FC);
  static const Color hudText = Colors.white70;
  static const Color lifeIcon = Color(0xFFE84545);

  // Brick colors by HP state
  static Color forBrick(int hp, int maxHp) {
    if (maxHp == 1) return const Color(0xFF4ECCA3); // green
    // maxHp == 2
    if (hp == 2) return const Color(0xFFF0A040); // orange (full)
    return const Color(0xFFF0C040); // yellow (damaged)
  }

  // Power-up colors
  static Color forPowerUp(PowerUpType type) {
    switch (type) {
      case PowerUpType.widen: return const Color(0xFF3A86FF);
      case PowerUpType.multiBall: return const Color(0xFF4ECCA3);
      case PowerUpType.penetrate: return const Color(0xFFBB86FC);
      case PowerUpType.extraLife: return const Color(0xFFE84545);
      case PowerUpType.shrink: return const Color(0xFF888888);
    }
  }

  // Power-up icon text
  static String powerUpIcon(PowerUpType type) {
    switch (type) {
      case PowerUpType.widen: return '↔';
      case PowerUpType.multiBall: return '×3';
      case PowerUpType.penetrate: return '↓';
      case PowerUpType.extraLife: return '♥';
      case PowerUpType.shrink: return '↕';
    }
  }
}
