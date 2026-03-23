// lib/sudoku/sudoku_colors.dart
import 'package:flutter/material.dart';

class SudokuColors {
  // Cell backgrounds
  static const Color cellBackground = Color(0xFF1A2744);
  static const Color regionHighlight = Color(0xFF243352);    // Layer 1: same row/col/box
  static const Color sameNumberHighlight = Color(0xFF2E4068); // Layer 2: same number
  static const Color errorHighlight = Color(0x33E84545);      // Layer 3: error tint
  static const Color selectedBorder = Color(0xFF4ECCA3);      // Layer 4: selection

  // Box/cell borders
  static const Color boxBorder = Color(0x804ECCA3);  // 2px, 50% opacity
  static const Color cellBorder = Color(0xFF2A3A5C); // 0.5px dim

  // Text
  static const Color givenText = Color(0xFF4ECCA3);
  static const Color userText = Color(0xFFF0C040);
  static const Color errorText = Color(0xFFE84545);
  static const Color notesText = Color(0xFF6688AA);

  // Controls
  static const Color activeButton = Color(0xFF4ECCA3);
  static const Color inactiveButton = Color(0xFF2A3A5C);
  static const Color disabledButton = Color(0xFF1A2744);
}
