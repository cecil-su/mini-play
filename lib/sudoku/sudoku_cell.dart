// lib/sudoku/sudoku_cell.dart

enum SudokuGameState { playing, won }

enum UndoType { setValue, toggleNote, clearCell }

class SudokuCell {
  int value;
  bool isGiven;
  Set<int> notes;

  SudokuCell({this.value = 0, this.isGiven = false, Set<int>? notes})
      : notes = notes ?? <int>{};

  SudokuCell.given(this.value)
      : isGiven = true,
        notes = <int>{};
}

class UndoAction {
  final int row;
  final int col;
  final int oldValue;
  final Set<int> oldNotes;
  final UndoType type;

  UndoAction({
    required this.row,
    required this.col,
    required this.oldValue,
    required this.oldNotes,
    required this.type,
  });
}

class SudokuDifficulty {
  final String name;
  final int emptyCells;
  final double decayRate;
  final int errorPenalty;
  final String scoreMode;

  const SudokuDifficulty({
    required this.name,
    required this.emptyCells,
    required this.decayRate,
    required this.errorPenalty,
    required this.scoreMode,
  });

  static const easy = SudokuDifficulty(
    name: '简单', emptyCells: 32, decayRate: 3, errorPenalty: 25, scoreMode: 'easy',
  );
  static const medium = SudokuDifficulty(
    name: '中等', emptyCells: 40, decayRate: 2, errorPenalty: 50, scoreMode: 'medium',
  );
  static const hard = SudokuDifficulty(
    name: '困难', emptyCells: 48, decayRate: 1.5, errorPenalty: 75, scoreMode: 'hard',
  );
  static const expert = SudokuDifficulty(
    name: '专家', emptyCells: 54, decayRate: 1, errorPenalty: 100, scoreMode: 'expert',
  );

  static const values = [easy, medium, hard, expert];
}
