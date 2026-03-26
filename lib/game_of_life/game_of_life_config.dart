import 'package:flutter/foundation.dart' show kIsWeb;

class GameOfLifeConfig {
  static const int gridWidth = 300;
  static const int gridHeight = 300;
  static const int gridSize = gridWidth * gridHeight;

  // Speed levels (generations/second)
  static const List<int> speedLevels = [3, 10, 30];
  static const List<String> speedLabels = ['慢', '中', '快'];

  // Zoom
  static const double minScale = 0.5;
  static const double maxScale = 8.0;
  static const double gridLineThreshold = 8.0;

  // History
  static const int historyCapacity = 30;

  // Auto-pause threshold
  static const double pauseThreshold = 0.5;

  // Max evolution steps per frame
  static const int maxStepsPerFrameWeb = 3;
  static const int maxStepsPerFrameNative = 5;
  static int get maxStepsPerFrame =>
      kIsWeb ? maxStepsPerFrameWeb : maxStepsPerFrameNative;

  // Game name for ScoreService
  static const String gameName = 'gameoflife';
}

enum InteractionMode { draw, pan, placingPattern }

enum GameOfLifeMode { sandbox, challenge, encyclopedia }
