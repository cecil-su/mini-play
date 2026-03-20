// lib/minesweeper/minesweeper_colors.dart
import 'package:flutter/material.dart';

class MinesweeperColors {
  // Cell backgrounds
  static const Color unrevealedSurface = Color(0xFF8E8E8E);
  static const Color unrevealedHighlight = Color(0xFFBDBDBD);
  static const Color revealedSurface = Color(0xFFD0D0D0);
  static const Color mineSurface = Color(0xFFE84545);

  // Number colors (WCAG AA contrast on #D0D0D0)
  static const Map<int, Color> numberColors = {
    1: Color(0xFF0000FF), // blue
    2: Color(0xFF006400), // dark green
    3: Color(0xFFFF0000), // red
    4: Color(0xFF000080), // dark blue
    5: Color(0xFF800000), // brown/maroon
    6: Color(0xFF008080), // cyan/teal
    7: Color(0xFF303030), // dark gray
    8: Color(0xFF606060), // dark gray
  };

  static Color getNumberColor(int number) {
    return numberColors[number] ?? Colors.black;
  }
}
