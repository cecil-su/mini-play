// lib/match3/match3_colors.dart
import 'package:flutter/material.dart';

import 'match3_gem.dart';

class Match3Colors {
  static const Color boardBackground = Color(0xFF16213E);
  static const Color cellBackground = Color(0xFF0F1729);
  static const Color selectedBorder = Color(0xFFF0C040);

  static const Map<GemType, Color> gemColors = {
    GemType.red: Color(0xFFE84545),
    GemType.orange: Color(0xFFF0A040),
    GemType.yellow: Color(0xFFF0E040),
    GemType.green: Color(0xFF4ECCA3),
    GemType.blue: Color(0xFF3A86FF),
    GemType.purple: Color(0xFFAA66CC),
  };

  static const Map<GemType, IconData> gemIcons = {
    GemType.red: Icons.favorite,
    GemType.orange: Icons.hexagon,
    GemType.yellow: Icons.star,
    GemType.green: Icons.eco,
    GemType.blue: Icons.diamond,
    GemType.purple: Icons.auto_awesome,
  };

  static Color getColor(GemType type) => gemColors[type] ?? Colors.white;
  static IconData getIcon(GemType type) => gemIcons[type] ?? Icons.circle;
}
