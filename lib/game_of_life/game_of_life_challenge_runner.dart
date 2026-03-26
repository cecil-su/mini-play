import 'game_of_life_challenges.dart';
import 'game_of_life_game.dart';

enum ChallengeState { editing, running, success, failed }

class ChallengeRunner {
  final ChallengeLevel level;
  final GameOfLifeGame game;

  ChallengeState state = ChallengeState.editing;
  int userCellCount = 0;
  int stars = 0;
  String? failReason;

  final int _initialCellCount;

  ChallengeRunner({required this.level, required this.game})
      : _initialCellCount = level.initialCells.length {
    // Place initial cells
    for (final (x, y) in level.initialCells) {
      game.setCell(x, y, 1);
    }
  }

  bool get isFinished =>
      state == ChallengeState.success || state == ChallengeState.failed;

  /// Check if a cell can be edited (not locked).
  bool canEditCell(int x, int y) {
    if (state != ChallengeState.editing) return false;
    if (level.lockedCells.contains((x, y))) return false;
    if (level.editableArea != null && !level.editableArea!.contains((x, y))) {
      return false;
    }
    return true;
  }

  /// Toggle a cell during editing. Returns true if toggled.
  bool toggleCell(int x, int y) {
    if (!canEditCell(x, y)) return false;
    final wasAlive = game.cellAt(x, y) == 1;
    game.toggleCell(x, y);
    if (wasAlive) {
      userCellCount--;
    } else {
      userCellCount++;
    }
    return true;
  }

  /// Transition from editing to running.
  void start() {
    if (state != ChallengeState.editing) return;
    state = ChallengeState.running;
  }

  /// Reset to editing state.
  void reset() {
    game.clear();
    for (final (x, y) in level.initialCells) {
      game.setCell(x, y, 1);
    }
    state = ChallengeState.editing;
    userCellCount = 0;
    stars = 0;
    failReason = null;
  }

  /// Advance one generation and check goals. Call each frame while running.
  void tick() {
    if (state != ChallengeState.running) return;

    game.evolve();

    if (_checkGoal()) {
      stars = level.calcStars(userCellCount);
      state = ChallengeState.success;
      return;
    }

    if (_checkTimeout()) {
      failReason = '已超过 ${level.maxGenerations} 代，目标未达成';
      state = ChallengeState.failed;
      return;
    }

    // Early failure for extinction/survive goals
    if (level.goalType == ChallengeGoalType.survive && game.isEmpty) {
      failReason = '所有细胞已消亡';
      state = ChallengeState.failed;
      return;
    }
  }

  /// Skip to result by running all remaining generations.
  Future<void> skipToResult(void Function() onProgress) async {
    while (state == ChallengeState.running) {
      for (int i = 0; i < 50 && state == ChallengeState.running; i++) {
        tick();
      }
      onProgress();
      await Future.delayed(Duration.zero);
    }
  }

  bool _checkGoal() {
    switch (level.goalType) {
      case ChallengeGoalType.stillLife:
        return game.isStillLife();
      case ChallengeGoalType.oscillator:
        return game.isOscillator();
      case ChallengeGoalType.spaceship:
        return game.isSpaceship();
      case ChallengeGoalType.survive:
        return game.generation >= level.goalParam;
      case ChallengeGoalType.extinct:
        return game.isEmpty;
      case ChallengeGoalType.population:
        if (game.generation >= level.goalParam) {
          if (level.goalMultiplier != null) {
            return game.aliveCellCount >=
                (_initialCellCount + userCellCount) * level.goalMultiplier!;
          }
          return game.aliveCellCount >= level.goalParam;
        }
        return false;
      case ChallengeGoalType.oscillatorMinPeriod:
        final period = game.detectPeriod();
        return period >= level.goalParam && game.isOscillator();
    }
  }

  bool _checkTimeout() => game.generation >= level.maxGenerations;
}
