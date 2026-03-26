import 'dart:ui';

import 'fruit_catcher_models.dart';

class FruitCatcherColors {
  static const Color background = Color(0xFF1A1A2E);

  // Basket
  static const Color basketBase = Color(0xFF8B5E3C);
  static const Color basketHighlight = Color(0xFFD4A574);

  // Fruit colors by type
  static Color forFruit(FruitType type) {
    switch (type) {
      case FruitType.red:
        return const Color(0xFFE84545);
      case FruitType.orange:
        return const Color(0xFFF0A040);
      case FruitType.yellow:
        return const Color(0xFFF0D040);
      case FruitType.green:
        return const Color(0xFF4ECCA3);
      case FruitType.purple:
        return const Color(0xFFBB86FC);
    }
  }

  // Bomb
  static const Color bomb = Color(0xFF2A2A2A);
  static const Color bombGlow = Color(0xFFE84545);

  // HUD & effects
  static const Color comboText = Color(0xFFF0C040);
  static const Color scoreFloat = Color(0xFF4ECCA3);
  static const Color penaltyFloat = Color(0xFFE84545);
  static const Color hudText = Color(0xB3FFFFFF); // white70
}
