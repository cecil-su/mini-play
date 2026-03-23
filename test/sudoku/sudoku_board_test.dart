// test/sudoku/sudoku_board_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_play/sudoku/sudoku_board.dart';
import 'package:mini_play/sudoku/sudoku_cell.dart';

void main() {
  late SudokuBoard board;
  late List<List<int>> solution;

  setUp(() {
    // A valid solved 9x9 Sudoku
    solution = [
      [5, 3, 4, 6, 7, 8, 9, 1, 2],
      [6, 7, 2, 1, 9, 5, 3, 4, 8],
      [1, 9, 8, 3, 4, 2, 5, 6, 7],
      [8, 5, 9, 7, 6, 1, 4, 2, 3],
      [4, 2, 6, 8, 5, 3, 7, 9, 1],
      [7, 1, 3, 9, 2, 4, 8, 5, 6],
      [9, 6, 1, 5, 3, 7, 2, 8, 4],
      [2, 8, 7, 4, 1, 9, 6, 3, 5],
      [3, 4, 5, 2, 8, 6, 1, 7, 9],
    ];
    // Create board with cell (0,1) and (0,2) empty
    final grid = List.generate(9, (r) {
      return List.generate(9, (c) {
        if (r == 0 && (c == 1 || c == 2)) return SudokuCell();
        return SudokuCell.given(solution[r][c]);
      });
    });
    board = SudokuBoard.fromGrid(grid, solution);
  });

  test('initial state is playing', () {
    expect(board.gameState, SudokuGameState.playing);
  });

  test('setValue sets value and tracks errors', () {
    final result = board.setValue(0, 1, 9); // wrong value (should be 3)
    expect(board.grid[0][1].value, 9);
    expect(result, true); // was an error
  });

  test('setValue no-op on given cell', () {
    board.setValue(0, 0, 1); // cell (0,0) is given
    expect(board.grid[0][0].value, 5); // unchanged
  });

  test('setValue no-op for same value', () {
    board.setValue(0, 1, 3);
    final result = board.setValue(0, 1, 3); // same value
    expect(result, false); // no-op, not an error
  });

  test('setValue clears notes', () {
    board.toggleNote(0, 1, 3);
    board.toggleNote(0, 1, 5);
    expect(board.grid[0][1].notes, {3, 5});
    board.setValue(0, 1, 3);
    expect(board.grid[0][1].notes, isEmpty);
  });

  test('clearCell clears value and notes', () {
    board.setValue(0, 1, 3);
    board.clearCell(0, 1);
    expect(board.grid[0][1].value, 0);
  });

  test('clearCell no-op on empty cell', () {
    final undoCount = board.historyLength;
    board.clearCell(0, 1); // already empty
    expect(board.historyLength, undoCount); // no undo pushed
  });

  test('toggleNote adds and removes', () {
    board.toggleNote(0, 1, 5);
    expect(board.grid[0][1].notes, {5});
    board.toggleNote(0, 1, 5);
    expect(board.grid[0][1].notes, isEmpty);
  });

  test('undo restores previous state', () {
    board.setValue(0, 1, 9);
    board.undo();
    expect(board.grid[0][1].value, 0);
  });

  test('undo restores notes after setValue', () {
    board.toggleNote(0, 1, 3);
    board.toggleNote(0, 1, 5);
    board.setValue(0, 1, 7); // clears notes
    board.undo();
    expect(board.grid[0][1].value, 0);
    expect(board.grid[0][1].notes, {3, 5});
  });

  test('undo on empty stack is no-op', () {
    board.undo(); // should not throw
    expect(board.gameState, SudokuGameState.playing);
  });

  test('isComplete returns true when all cells match solution', () {
    board.setValue(0, 1, 3);
    board.setValue(0, 2, 4);
    expect(board.isComplete, true);
    expect(board.gameState, SudokuGameState.won);
  });

  test('hasConflict detects row conflict', () {
    board.setValue(0, 1, 5); // 5 already in row 0 at col 0
    expect(board.errorCells.contains((0, 1)), true);
  });

  test('isDigitComplete transitions from false to true', () {
    // Digit 3 is incomplete: (0,1) is empty and solution[0][1]=3
    expect(board.isDigitComplete(3), false);
    board.setValue(0, 1, 3);
    expect(board.isDigitComplete(3), true);
  });

  test('input disabled after won', () {
    board.setValue(0, 1, 3);
    board.setValue(0, 2, 4);
    expect(board.gameState, SudokuGameState.won);
    board.setValue(0, 1, 9); // should be no-op
    expect(board.grid[0][1].value, 3); // unchanged
  });

  test('clearCell on given cell is no-op', () {
    final undoCount = board.historyLength;
    board.clearCell(0, 0); // given cell
    expect(board.grid[0][0].value, 5); // unchanged
    expect(board.historyLength, undoCount);
  });

  test('toggleNote on given cell is no-op', () {
    board.toggleNote(0, 0, 3); // given cell
    expect(board.grid[0][0].notes, isEmpty);
  });

  test('toggleNote on cell with value is no-op', () {
    board.setValue(0, 1, 3);
    board.toggleNote(0, 1, 5); // cell has value
    expect(board.grid[0][1].notes, isEmpty);
  });

  test('hasConflict detects column conflict', () {
    // Col 1: _,7,9,5,2,1,6,8,4. Place 7 at (0,1) — conflicts with 7 at (1,1)
    board.setValue(0, 1, 7);
    expect(board.errorCells.contains((0, 1)), true);
  });

  test('hasConflict detects box conflict', () {
    // Box(0,0): 5,_,_,6,7,2,1,9,8. Place 8 at (0,1) — conflicts with 8 at (2,2)
    board.setValue(0, 1, 8);
    expect(board.errorCells.contains((0, 1)), true);
  });

  test('undo restores note state after toggleNote', () {
    board.toggleNote(0, 1, 3);
    board.toggleNote(0, 1, 5);
    expect(board.grid[0][1].notes, {3, 5});
    board.undo();
    expect(board.grid[0][1].notes, {3});
  });

  test('undo restores value after clearCell', () {
    board.setValue(0, 1, 3);
    board.clearCell(0, 1);
    expect(board.grid[0][1].value, 0);
    board.undo();
    expect(board.grid[0][1].value, 3);
  });

  test('multi-step undo restores in reverse order', () {
    board.setValue(0, 1, 9);
    board.setValue(0, 2, 7);
    board.undo();
    expect(board.grid[0][2].value, 0);
    expect(board.grid[0][1].value, 9);
    board.undo();
    expect(board.grid[0][1].value, 0);
  });

  test('clearCell on cell with only notes clears and pushes undo', () {
    board.toggleNote(0, 1, 3);
    board.toggleNote(0, 1, 7);
    final undoBefore = board.historyLength;
    board.clearCell(0, 1);
    expect(board.grid[0][1].notes, isEmpty);
    expect(board.historyLength, undoBefore + 1);
  });

  test('setValue overwriting existing value pushes undo with old value', () {
    board.setValue(0, 1, 9);
    board.setValue(0, 1, 3);
    expect(board.grid[0][1].value, 3);
    board.undo();
    expect(board.grid[0][1].value, 9);
  });

  test('undo is no-op after win', () {
    board.setValue(0, 1, 3);
    board.setValue(0, 2, 4);
    expect(board.gameState, SudokuGameState.won);
    board.undo();
    expect(board.grid[0][2].value, 4); // unchanged
  });
}
