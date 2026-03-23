import 'package:flutter/material.dart';
import 'tetris_piece.dart';

class TetrisColors {
  static const Color boardBackground = Color(0xFF0A0A1A);
  static const Color gridLine = Color(0xFF1A1A30);
  static const Color ghost = Color(0x33FFFFFF);

  static Color forPiece(PieceType type) {
    switch (type) {
      case PieceType.I:
        return const Color(0xFF00E5FF); // Cyan
      case PieceType.O:
        return const Color(0xFFF0C040); // Yellow
      case PieceType.T:
        return const Color(0xFFAA44FF); // Purple
      case PieceType.S:
        return const Color(0xFF4ECCA3); // Green
      case PieceType.Z:
        return const Color(0xFFE84545); // Red
      case PieceType.J:
        return const Color(0xFF3A86FF); // Blue
      case PieceType.L:
        return const Color(0xFFFF8C00); // Orange
    }
  }
}
