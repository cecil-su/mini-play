// lib/minesweeper/minesweeper_cell.dart

class MinesweeperCell {
  bool isMine;
  bool isRevealed;
  bool isFlagged;
  bool isWrongFlag; // shown on game over: flagged but not a mine
  int adjacentMines;

  MinesweeperCell({
    this.isMine = false,
    this.isRevealed = false,
    this.isFlagged = false,
    this.isWrongFlag = false,
    this.adjacentMines = 0,
  });
}

enum MinesweeperGameState { playing, won, lost }

class MinesweeperDifficulty {
  final String name;
  final int rows;
  final int cols;
  final int mines;
  final String scoreMode;

  const MinesweeperDifficulty({
    required this.name,
    required this.rows,
    required this.cols,
    required this.mines,
    required this.scoreMode,
  });

  static const beginner = MinesweeperDifficulty(
    name: 'Beginner',
    rows: 9,
    cols: 9,
    mines: 10,
    scoreMode: 'beginner',
  );

  static const intermediate = MinesweeperDifficulty(
    name: 'Intermediate',
    rows: 16,
    cols: 16,
    mines: 40,
    scoreMode: 'intermediate',
  );

  static const expert = MinesweeperDifficulty(
    name: 'Expert',
    rows: 16,
    cols: 30,
    mines: 99,
    scoreMode: 'expert',
  );
}
