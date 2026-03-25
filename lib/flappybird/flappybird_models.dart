// lib/flappybird/flappybird_models.dart

enum GameState { ready, playing, dead, gameOver }

class Bird {
  double x;
  double y;
  double velocity;
  double rotation;
  final double radius;
  double wingPhase;

  Bird({
    required this.x,
    required this.y,
    this.velocity = 0,
    this.rotation = 0,
    this.radius = 0.025,
    this.wingPhase = 0,
  });
}

class Pipe {
  double x;
  final double gapCenterY;
  final double width;
  bool passed;

  Pipe({
    required this.x,
    required this.gapCenterY,
    required this.width,
    this.passed = false,
  });
}

class Cloud {
  double x;
  final double y;
  final double radius;
  final double speed;

  Cloud({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
  });
}

class Ground {
  double offsetX;
  final double height;

  Ground({this.offsetX = 0, this.height = 0.1});
}
