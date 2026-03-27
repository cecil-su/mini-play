// test/klotski/klotski_levels_test.dart
//
// BFS verification test for all defined Klotski levels.
// Run: fvm flutter test test/klotski/klotski_levels_test.dart
//
// This test verifies:
// 1. Each level layout is valid (pieces fit on 4×5 board, exactly 2 empty cells)
// 2. BFS solver can find a solution for each level
// 3. The solution replays to victory
// 4. minMoves matches the BFS optimal solution length

import 'package:flutter_test/flutter_test.dart';
import 'package:mini_play/klotski/klotski_config.dart';
import 'package:mini_play/klotski/klotski_models.dart';
import 'package:mini_play/klotski/klotski_board.dart';
import 'package:mini_play/klotski/klotski_solver.dart';
import 'package:mini_play/klotski/klotski_levels.dart';

/// Replay a solution sequence on a fresh board, return true if reaches victory.
bool _replaySolution(List<BlockDef> defs, List<KlotskiMove> solution) {
  final board = KlotskiBoard(defs);
  for (final move in solution) {
    final block = board.blocks.firstWhere(
      (b) =>
          b.type == move.blockType &&
          b.row == move.fromRow &&
          b.col == move.fromCol,
      orElse: () => throw StateError(
        'No block found: ${move.blockType} at (${move.fromRow},${move.fromCol})',
      ),
    );
    final maxDist = board.maxDistance(block.id, move.direction);
    if (move.distance > maxDist) {
      throw StateError(
        'Invalid move: distance ${move.distance} > maxDistance $maxDist',
      );
    }
    board.moveBlock(block.id, move.direction, move.distance);
  }
  return board.isWon;
}

void main() {
  group('Level layout validation', () {
    for (int i = 0; i < klotskiLevels.length; i++) {
      final level = klotskiLevels[i];
      test('#${i + 1} ${level.name}: layout is valid', () {
        // Must have exactly one cao
        final caoCount =
            level.blocks.where((b) => b.type == BlockType.cao).length;
        expect(caoCount, 1, reason: 'Must have exactly 1 cao block');

        // All blocks must fit within 4×5 grid
        for (final b in level.blocks) {
          expect(b.row >= 0, true,
              reason: '${b.label} row ${b.row} < 0');
          expect(b.col >= 0, true,
              reason: '${b.label} col ${b.col} < 0');
          expect(b.row + b.type.height <= boardRows, true,
              reason: '${b.label} overflows bottom');
          expect(b.col + b.type.width <= boardCols, true,
              reason: '${b.label} overflows right');
        }

        // Check no overlapping blocks and exactly 2 empty cells
        final grid =
            List.generate(boardRows, (_) => List.filled(boardCols, false));
        int filledCells = 0;
        for (final b in level.blocks) {
          for (int r = 0; r < b.type.height; r++) {
            for (int c = 0; c < b.type.width; c++) {
              final gr = b.row + r;
              final gc = b.col + c;
              expect(grid[gr][gc], false,
                  reason: 'Overlap at ($gr,$gc) by ${b.label}');
              grid[gr][gc] = true;
              filledCells++;
            }
          }
        }
        final emptyCells = boardRows * boardCols - filledCells;
        expect(emptyCells, 2,
            reason: 'Expected 2 empty cells, got $emptyCells');
      });
    }
  });

  group('BFS solver verification', () {
    for (int i = 0; i < klotskiLevels.length; i++) {
      final level = klotskiLevels[i];
      test('#${i + 1} ${level.name}: BFS finds solution, minMoves=${level.minMoves}',
          () {
        final board = KlotskiBoard(level.blocks);
        final solution = KlotskiSolver.solve(board.blocks);

        expect(solution, isNotNull, reason: 'Should be solvable');
        expect(solution!.isNotEmpty, true, reason: 'Should not already be won');

        // Replay to verify
        expect(_replaySolution(level.blocks, solution), true,
            reason: 'Solution must replay to victory');

        // Verify minMoves matches BFS
        if (level.minMoves > 0) {
          expect(solution.length, level.minMoves,
              reason:
                  'BFS found ${solution.length} steps but minMoves says ${level.minMoves}');
        } else {
          // Print for unverified levels
          // ignore: avoid_print
          print(
              '  #${i + 1} ${level.name}: BFS optimal = ${solution.length} steps (minMoves not set)');
        }
      }, timeout: const Timeout(Duration(seconds: 120)));
    }
  });
}
