// lib/breakout/breakout_models.dart
import 'dart:math';

enum PowerUpType { widen, multiBall, penetrate, extraLife, shrink }

class Ball {
  double x, y;
  double vx, vy;
  double radius;
  bool isPenetrating;
  int penetrateHits;
  bool collidedThisFrame;

  Ball({
    required this.x,
    required this.y,
    this.vx = 0,
    this.vy = 0,
    this.radius = 0.012,
    this.isPenetrating = false,
    this.penetrateHits = 0,
    this.collidedThisFrame = false,
  });

  Ball copy() => Ball(
        x: x, y: y, vx: vx, vy: vy,
        radius: radius,
        isPenetrating: isPenetrating,
        penetrateHits: penetrateHits,
      );

  double get speed => sqrt(vx * vx + vy * vy);

}

class Paddle {
  double x, y;
  double baseWidth;
  double width;
  double height;

  Paddle({
    required this.x,
    required this.y,
    required this.baseWidth,
    double? width,
    this.height = 0.015,
  }) : width = width ?? baseWidth;
}

class Brick {
  final int row;
  final int col;
  int hp;
  final int maxHp;
  bool hitThisFrame;
  int flashFrames;
  int fadeFrames;

  Brick({
    required this.row,
    required this.col,
    required this.hp,
    required this.maxHp,
    this.hitThisFrame = false,
    this.flashFrames = 0,
    this.fadeFrames = 0,
  });

  bool get isActive => hp > 0;

  int get score {
    switch (maxHp) {
      case 1: return 10;
      case 2: return 20;
      default: return 10;
    }
  }
}

class PowerUp {
  double x, y;
  final PowerUpType type;
  final double fallSpeed;

  PowerUp({
    required this.x,
    required this.y,
    required this.type,
    this.fallSpeed = 0.3,
  });
}
