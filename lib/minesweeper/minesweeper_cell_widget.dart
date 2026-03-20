// lib/minesweeper/minesweeper_cell_widget.dart
import 'package:flutter/material.dart';
import 'minesweeper_cell.dart';
import 'minesweeper_colors.dart';

class MinesweeperCellWidget extends StatelessWidget {
  final MinesweeperCell cell;
  final double size;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onSecondaryTap;

  const MinesweeperCellWidget({
    super.key,
    required this.cell,
    required this.size,
    required this.onTap,
    required this.onLongPress,
    required this.onSecondaryTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      onSecondaryTap: onSecondaryTap,
      child: SizedBox(
        width: size,
        height: size,
        child: _buildCellContent(),
      ),
    );
  }

  Widget _buildCellContent() {
    if (!cell.isRevealed && !cell.isWrongFlag) {
      // Unrevealed cell (possibly flagged)
      return Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: MinesweeperColors.unrevealedSurface,
          border: Border(
            top: BorderSide(color: MinesweeperColors.unrevealedHighlight, width: 2),
            left: BorderSide(color: MinesweeperColors.unrevealedHighlight, width: 2),
            bottom: BorderSide(color: const Color(0xFF606060), width: 2),
            right: BorderSide(color: const Color(0xFF606060), width: 2),
          ),
        ),
        child: cell.isFlagged
            ? const Center(
                child: Icon(Icons.flag, color: Color(0xFFE84545), size: 18),
              )
            : null,
      );
    }

    if (cell.isWrongFlag) {
      // Wrong flag (game over)
      return Container(
        margin: const EdgeInsets.all(1),
        color: MinesweeperColors.mineSurface,
        child: const Center(
          child: Icon(Icons.close, color: Colors.white, size: 18),
        ),
      );
    }

    if (cell.isMine) {
      // Revealed mine
      return Container(
        margin: const EdgeInsets.all(1),
        color: MinesweeperColors.mineSurface,
        child: const Center(
          child: Icon(Icons.brightness_7, color: Colors.black, size: 18),
        ),
      );
    }

    // Revealed number or empty
    return Container(
      margin: const EdgeInsets.all(1),
      color: MinesweeperColors.revealedSurface,
      child: cell.adjacentMines > 0
          ? Center(
              child: Text(
                '${cell.adjacentMines}',
                style: TextStyle(
                  color: MinesweeperColors.getNumberColor(cell.adjacentMines),
                  fontWeight: FontWeight.bold,
                  fontSize: size * 0.5,
                ),
              ),
            )
          : null,
    );
  }
}
