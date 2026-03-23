// test/sudoku/sudoku_generator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_play/sudoku/sudoku_cell.dart';
import 'package:mini_play/sudoku/sudoku_generator.dart';

void main() {
  test('generates a valid solved board', () {
    final result = SudokuGenerator.generate(SudokuDifficulty.easy);
    final solution = result.solution;

    // Check all rows have digits 1-9
    for (int r = 0; r < 9; r++) {
      expect(solution[r].toSet(), {1, 2, 3, 4, 5, 6, 7, 8, 9});
    }

    // Check all columns have digits 1-9
    for (int c = 0; c < 9; c++) {
      final col = [for (int r = 0; r < 9; r++) solution[r][c]];
      expect(col.toSet(), {1, 2, 3, 4, 5, 6, 7, 8, 9});
    }

    // Check all 3x3 boxes have digits 1-9
    for (int br = 0; br < 3; br++) {
      for (int bc = 0; bc < 3; bc++) {
        final box = <int>[];
        for (int r = br * 3; r < br * 3 + 3; r++) {
          for (int c = bc * 3; c < bc * 3 + 3; c++) {
            box.add(solution[r][c]);
          }
        }
        expect(box.toSet(), {1, 2, 3, 4, 5, 6, 7, 8, 9});
      }
    }
  });

  test('puzzle has correct number of empty cells (within tolerance)', () {
    final difficulty = SudokuDifficulty.easy;
    final result = SudokuGenerator.generate(difficulty);
    int emptyCells = 0;
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (result.puzzle[r][c] == 0) emptyCells++;
      }
    }
    // Within tolerance of emptyCells - 3
    expect(emptyCells, greaterThanOrEqualTo(difficulty.emptyCells - 3));
    expect(emptyCells, lessThanOrEqualTo(difficulty.emptyCells));
  });

  test('puzzle has unique solution', () {
    final result = SudokuGenerator.generate(SudokuDifficulty.medium);
    final count = SudokuGenerator.countSolutions(result.puzzle);
    expect(count, 1);
  });

  test('countSolutions returns 0 for invalid board', () {
    final board = List.generate(9, (_) => List.filled(9, 0));
    board[0][0] = 1;
    board[0][1] = 1; // conflict
    expect(SudokuGenerator.countSolutions(board), 0);
  });

  test('expert difficulty generates valid puzzle', () {
    final result = SudokuGenerator.generate(SudokuDifficulty.expert);
    int emptyCells = 0;
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (result.puzzle[r][c] == 0) emptyCells++;
      }
    }
    expect(emptyCells, greaterThanOrEqualTo(SudokuDifficulty.expert.emptyCells - 3));
    expect(SudokuGenerator.countSolutions(result.puzzle), 1);
  });

  test('generates different puzzles each time', () {
    final a = SudokuGenerator.generate(SudokuDifficulty.easy);
    final b = SudokuGenerator.generate(SudokuDifficulty.easy);
    // Extremely unlikely to be identical
    bool different = false;
    for (int r = 0; r < 9 && !different; r++) {
      for (int c = 0; c < 9 && !different; c++) {
        if (a.puzzle[r][c] != b.puzzle[r][c]) different = true;
      }
    }
    expect(different, true);
  });
}
