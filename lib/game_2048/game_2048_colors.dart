import 'package:flutter/material.dart';

class TileColors {
  static const Color boardBackground = Color(0xFFBBADA0);
  static const Color emptyCell = Color(0xFFCDC1B4);

  static const Map<int, Color> tileBackground = {
    2: Color(0xFFEEE4DA),
    4: Color(0xFFEDE0C8),
    8: Color(0xFFF2B179),
    16: Color(0xFFF59563),
    32: Color(0xFFF67C5F),
    64: Color(0xFFF65E3B),
    128: Color(0xFFEDCF72),
    256: Color(0xFFEDCC61),
    512: Color(0xFFEDC850),
    1024: Color(0xFFEDC53F),
    2048: Color(0xFFEDC22E),
  };

  static const Color superTileBackground = Color(0xFF3C3A32);
  static const Color darkText = Color(0xFF776E65);
  static const Color lightText = Color(0xFFFFFFFF);

  static Color getBackground(int value) {
    return tileBackground[value] ?? superTileBackground;
  }

  static Color getTextColor(int value) {
    return value <= 4 ? darkText : lightText;
  }

  /// Cell spacing adapts to grid size.
  static double getCellSpacing(int gridSize) {
    switch (gridSize) {
      case 3: return 10.0;
      case 4: return 8.0;
      case 5: return 6.0;
      case 6: return 4.0;
      default: return 8.0;
    }
  }
}
