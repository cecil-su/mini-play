import 'dart:ui';

import 'fruit_catcher_config.dart';

enum FruitType { red, orange, yellow, green, purple }

class FruitItem {
  double x;
  double y;
  double speed;
  final bool isBomb;
  final FruitType? fruitType;

  FruitItem({
    required this.x,
    required this.y,
    required this.speed,
    required this.isBomb,
    this.fruitType,
  });

  bool get isOffScreen =>
      y > FruitCatcherConfig.worldHeight + radius;

  double get radius =>
      isBomb ? FruitCatcherConfig.bombRadius : FruitCatcherConfig.fruitRadius;
}

class Basket {
  double x;
  double targetX;

  Basket({required this.x, required this.targetX});

  double get y => FruitCatcherConfig.basketY;
  double get width => FruitCatcherConfig.basketWidth;
  double get height => FruitCatcherConfig.basketHeight;
}

class FloatingText {
  double x;
  double y;
  double age;
  final String text;
  final Color color;

  static const double duration = 0.8;
  static const double riseSpeed = 0.15;

  FloatingText({
    required this.x,
    required this.y,
    required this.text,
    required this.color,
    this.age = 0,
  });

  double get alpha => (1.0 - age / duration).clamp(0.0, 1.0);
  bool get isDead => age >= duration;
}
