// lib/match3/match3_gem_widget.dart
import 'package:flutter/material.dart';

import 'match3_colors.dart';
import 'match3_gem.dart';

class Match3GemWidget extends StatelessWidget {
  final Gem gem;
  final double size;
  final bool selected;

  const Match3GemWidget({
    super.key,
    required this.gem,
    required this.size,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = Match3Colors.getColor(gem.type);
    final icon = Match3Colors.getIcon(gem.type);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.15),
        border: selected
            ? Border.all(color: Match3Colors.selectedBorder, width: 3)
            : null,
      ),
      child: Center(
        child: Icon(
          icon,
          color: color,
          size: size * 0.6,
        ),
      ),
    );
  }
}
