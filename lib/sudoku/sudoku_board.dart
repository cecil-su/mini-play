// lib/sudoku/sudoku_board.dart
import 'sudoku_cell.dart';

class SudokuBoard {
  final List<List<SudokuCell>> _grid;
  final List<List<int>> _solution;
  final Set<(int, int)> _errorCells = {};
  final List<UndoAction> _history = [];
  SudokuGameState _gameState = SudokuGameState.playing;

  List<List<SudokuCell>> get grid => _grid;
  List<List<int>> get solution => _solution;
  Set<(int, int)> get errorCells => _errorCells;
  SudokuGameState get gameState => _gameState;
  int get historyLength => _history.length;
  bool get canUndo => _history.isNotEmpty;

  SudokuBoard._(this._grid, this._solution);

  /// Test constructor
  SudokuBoard.fromGrid(List<List<SudokuCell>> grid, List<List<int>> solution)
      : _grid = grid,
        _solution = solution {
    _updateErrors();
  }

  /// Factory from generator output
  factory SudokuBoard.create({
    required List<List<int>> puzzle,
    required List<List<int>> solution,
  }) {
    final grid = List.generate(9, (r) {
      return List.generate(9, (c) {
        final v = puzzle[r][c];
        return v != 0 ? SudokuCell.given(v) : SudokuCell();
      });
    });
    return SudokuBoard._(grid, solution).._updateErrors();
  }

  /// Returns true if the placed value was wrong (for error counting).
  bool setValue(int row, int col, int value) {
    if (_gameState != SudokuGameState.playing) return false;
    final cell = _grid[row][col];
    if (cell.isGiven) return false;
    if (cell.value == value) return false; // no-op

    _history.add(UndoAction(
      row: row,
      col: col,
      oldValue: cell.value,
      oldNotes: Set<int>.of(cell.notes),
      type: UndoType.setValue,
    ));

    cell.value = value;
    cell.notes.clear();
    _updateErrors();
    _checkWin();

    return value != _solution[row][col];
  }

  void toggleNote(int row, int col, int value) {
    if (_gameState != SudokuGameState.playing) return;
    final cell = _grid[row][col];
    if (cell.isGiven || cell.value != 0) return;

    _history.add(UndoAction(
      row: row,
      col: col,
      oldValue: cell.value,
      oldNotes: Set<int>.of(cell.notes),
      type: UndoType.toggleNote,
    ));

    if (cell.notes.contains(value)) {
      cell.notes.remove(value);
    } else {
      cell.notes.add(value);
    }
  }

  void clearCell(int row, int col) {
    if (_gameState != SudokuGameState.playing) return;
    final cell = _grid[row][col];
    if (cell.isGiven) return;
    if (cell.value == 0 && cell.notes.isEmpty) return; // no-op

    _history.add(UndoAction(
      row: row,
      col: col,
      oldValue: cell.value,
      oldNotes: Set<int>.of(cell.notes),
      type: UndoType.clearCell,
    ));

    cell.value = 0;
    cell.notes.clear();
    _updateErrors();
  }

  void undo() {
    if (_gameState != SudokuGameState.playing) return;
    if (_history.isEmpty) return;

    final action = _history.removeLast();
    final cell = _grid[action.row][action.col];
    cell.value = action.oldValue;
    cell.notes = Set<int>.of(action.oldNotes);
    _updateErrors();
  }

  bool get isComplete {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (_grid[r][c].value != _solution[r][c]) return false;
      }
    }
    return true;
  }

  bool isDigitComplete(int digit) {
    int count = 0;
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (_grid[r][c].value == digit) count++;
      }
    }
    return count >= 9;
  }

  bool hasConflict(int row, int col) => _errorCells.contains((row, col));

  void _updateErrors() {
    _errorCells.clear();
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final v = _grid[r][c].value;
        if (v == 0) continue;
        // Check row
        for (int c2 = 0; c2 < 9; c2++) {
          if (c2 != c && _grid[r][c2].value == v) {
            _errorCells.add((r, c));
            _errorCells.add((r, c2));
          }
        }
        // Check column
        for (int r2 = 0; r2 < 9; r2++) {
          if (r2 != r && _grid[r2][c].value == v) {
            _errorCells.add((r, c));
            _errorCells.add((r2, c));
          }
        }
        // Check box
        final br = (r ~/ 3) * 3, bc = (c ~/ 3) * 3;
        for (int r2 = br; r2 < br + 3; r2++) {
          for (int c2 = bc; c2 < bc + 3; c2++) {
            if (r2 != r || c2 != c) {
              if (_grid[r2][c2].value == v) {
                _errorCells.add((r, c));
                _errorCells.add((r2, c2));
              }
            }
          }
        }
      }
    }
  }

  void _checkWin() {
    if (isComplete) {
      _gameState = SudokuGameState.won;
    }
  }
}
