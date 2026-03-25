// lib/klotski/klotski_colors.dart

import 'package:flutter/material.dart';
import 'klotski_config.dart';

class KlotskiColors {
  KlotskiColors._();

  // 方块颜色
  static const caoBg = Color(0xFFC62828);
  static const guanyuBg = Color(0xFF2E7D32);
  static const generalBg = Color(0xFF1565C0);
  static const soldierBg = Color(0xFFF9A825);

  // 将军个体色调区分
  static const generalColors = [
    Color(0xFF1565C0), // 张
    Color(0xFF0D47A1), // 赵
    Color(0xFF1976D2), // 马
    Color(0xFF0277BD), // 黄
    Color(0xFF01579B), // 备用
  ];

  // 棋盘
  static const boardBg = Color(0xFF3E2723);
  static const cellBg = Color(0xFF5D4037);
  static const cellBorder = Color(0xFF4E342E);
  static const exitGlow = Color(0xFFF0C040);

  // 难度标题
  static const beginnerColor = Color(0xFF4ECCA3);
  static const advancedColor = Color(0xFF3A86FF);
  static const masterColor = Color(0xFFE84545);

  // 步数变色
  static const moveGreen = Color(0xFF4ECCA3);
  static const moveYellow = Color(0xFFF0C040);
  static const moveRed = Color(0xFFE84545);

  // 方块文字
  static const blockText = Colors.white;
  static const blockTextShadow = Color(0x66000000);

  static Color bgForType(BlockType type) {
    switch (type) {
      case BlockType.cao:
        return caoBg;
      case BlockType.guanyu:
        return guanyuBg;
      case BlockType.general:
        return generalBg;
      case BlockType.soldier:
        return soldierBg;
    }
  }

  static Color difficultyColor(KlotskiDifficulty diff) {
    switch (diff) {
      case KlotskiDifficulty.beginner:
        return beginnerColor;
      case KlotskiDifficulty.advanced:
        return advancedColor;
      case KlotskiDifficulty.master:
        return masterColor;
    }
  }
}
