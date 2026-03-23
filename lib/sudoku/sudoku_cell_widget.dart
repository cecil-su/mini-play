// lib/sudoku/sudoku_cell_widget.dart
import 'package:flutter/material.dart';
import 'sudoku_cell.dart';
import 'sudoku_colors.dart';

class SudokuCellWidget extends StatelessWidget {
  final SudokuCell cell;
  final double size;
  final bool isSelected;
  final bool isRelated;     // same row/col/box
  final bool isSameNumber;  // same value as selected
  final bool showError;     // error display toggle on + cell in errorCells
  final VoidCallback onTap;

  const SudokuCellWidget({
    super.key,
    required this.cell,
    required this.size,
    required this.isSelected,
    required this.isRelated,
    required this.isSameNumber,
    required this.showError,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _backgroundColor,
          border: isSelected
              ? Border.all(color: SudokuColors.selectedBorder, width: 2)
              : null,
        ),
        child: cell.value != 0
            ? Center(
                child: Text(
                  '${cell.value}',
                  style: TextStyle(
                    color: _textColor,
                    fontSize: size * 0.5,
                    fontWeight: cell.isGiven ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              )
            : cell.notes.isNotEmpty
                ? _buildNotes()
                : null,
      ),
    );
  }

  Color get _backgroundColor {
    if (showError) return SudokuColors.errorHighlight;
    if (isSameNumber) return SudokuColors.sameNumberHighlight;
    if (isRelated) return SudokuColors.regionHighlight;
    return SudokuColors.cellBackground;
  }

  Color get _textColor {
    if (showError) return SudokuColors.errorText;
    if (cell.isGiven) return SudokuColors.givenText;
    return SudokuColors.userText;
  }

  Widget _buildNotes() {
    return Padding(
      padding: const EdgeInsets.all(1),
      child: GridView.count(
        crossAxisCount: 3,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(9, (i) {
          final digit = i + 1;
          return Center(
            child: Text(
              cell.notes.contains(digit) ? '$digit' : '',
              style: TextStyle(
                color: SudokuColors.notesText,
                fontSize: (size * 0.22).clamp(8.0, 12.0),
              ),
            ),
          );
        }),
      ),
    );
  }
}
