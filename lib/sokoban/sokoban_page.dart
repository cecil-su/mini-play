// lib/sokoban/sokoban_page.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../shared/game_over_data.dart';
import '../shared/game_over_page.dart';
import '../shared/game_scaffold.dart';
import '../shared/score_service.dart';
import 'sokoban_board.dart';
import 'sokoban_levels.dart';

class SokobanPage extends StatefulWidget {
  final int levelIndex;

  const SokobanPage({super.key, required this.levelIndex});

  @override
  State<SokobanPage> createState() => _SokobanPageState();
}

class _SokobanPageState extends State<SokobanPage> {
  Key _gameKey = UniqueKey();
  late int _currentLevel;
  late SokobanBoard _board;
  final ValueNotifier<int> _movesNotifier = ValueNotifier<int>(0);
  int _bestMoves = 0;
  int _paintVersion = 0;
  bool _isPaused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentLevel = widget.levelIndex;
    _board = SokobanBoard(sokobanLevels[_currentLevel]);
    _loadBest();
  }

  Future<void> _loadBest() async {
    _bestMoves =
        await ScoreService().getHighScore('sokoban', 'level_$_currentLevel');
    if (mounted) setState(() {});
  }

  void _resetLevel() {
    _paintVersion++;
    setState(() {
      _board.reset(sokobanLevels[_currentLevel]);
      _movesNotifier.value = 0;
    });
  }

  void _handleMove(Direction dir) {
    if (_isPaused || _board.isWon) return;
    final moved = _board.tryMove(dir);
    if (moved) {
      _paintVersion++;
      setState(() {
        _movesNotifier.value = _board.moves;
      });
      if (_board.isWon) {
        _onLevelComplete();
      }
    }
  }

  void _undo() {
    if (_isPaused || !_board.canUndo) return;
    _paintVersion++;
    setState(() {
      _board.undo();
      _movesNotifier.value = _board.moves;
    });
  }

  Future<void> _onLevelComplete() async {
    await ScoreService().saveHighScore(
      'sokoban',
      'level_$_currentLevel',
      _board.moves,
      lowerIsBetter: true,
    );
    final best =
        await ScoreService().getHighScore('sokoban', 'level_$_currentLevel');

    if (!mounted) return;

    final hasNext = _currentLevel + 1 < sokobanLevels.length;

    final stats = <String, String>{
      'Level': '${_currentLevel + 1}',
      'Moves': '${_board.moves}',
      'Best': '$best',
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameOverPage(
          data: GameOverData(
            gameName: 'sokoban',
            mode: 'level_$_currentLevel',
            stats: stats,
            replayCallback: hasNext ? _goNextLevel : _replayCurrent,
          ),
        ),
      ),
    );
  }

  void _replayCurrent() {
    setState(() {
      _gameKey = UniqueKey();
      _board = SokobanBoard(sokobanLevels[_currentLevel]);
      _movesNotifier.value = 0;
    });
    _loadBest();
  }

  void _goNextLevel() {
    setState(() {
      _currentLevel++;
      _gameKey = UniqueKey();
      _board = SokobanBoard(sokobanLevels[_currentLevel]);
      _movesNotifier.value = 0;
    });
    _loadBest();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    Direction? dir;
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      dir = Direction.up;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      dir = Direction.down;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      dir = Direction.left;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      dir = Direction.right;
    } else if (event.logicalKey == LogicalKeyboardKey.keyZ) {
      _undo();
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.keyR) {
      _resetLevel();
      return KeyEventResult.handled;
    }
    if (dir != null) {
      _handleMove(dir);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _onPause() {
    _isPaused = true;
  }

  void _onResume() {
    _isPaused = false;
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _movesNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: GameScaffold(
        key: _gameKey,
        title: 'Sokoban - Level ${_currentLevel + 1}',
        scoreNotifier: _movesNotifier,
        bestScore: _bestMoves,
        scoreLabel: 'Moves',
        bestLabel: 'Best',
        bestFormatter: (v) => v == 0 ? '--' : '$v',
        onPause: _onPause,
        onResume: _onResume,
        canPause: () => !_board.isWon,
        child: Column(
          children: [
            // Action bar: undo & reset
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.undo,
                      color: _board.canUndo
                          ? const Color(0xFF4ECCA3)
                          : Colors.grey,
                    ),
                    onPressed: _board.canUndo ? _undo : null,
                    tooltip: 'Undo (Z)',
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Color(0xFFF0C040)),
                    onPressed: _resetLevel,
                    tooltip: 'Reset (R)',
                  ),
                ],
              ),
            ),

            // Board
            Expanded(
              child: GestureDetector(
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity == null) return;
                  if (details.primaryVelocity! < -50) {
                    _handleMove(Direction.up);
                  } else if (details.primaryVelocity! > 50) {
                    _handleMove(Direction.down);
                  }
                },
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity == null) return;
                  if (details.primaryVelocity! < -50) {
                    _handleMove(Direction.left);
                  } else if (details.primaryVelocity! > 50) {
                    _handleMove(Direction.right);
                  }
                },
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final cellSize = min(
                        constraints.maxWidth / _board.cols,
                        constraints.maxHeight / _board.rows,
                      ).clamp(20.0, 48.0);
                      final boardWidth = cellSize * _board.cols;
                      final boardHeight = cellSize * _board.rows;

                      return SizedBox(
                        width: boardWidth,
                        height: boardHeight,
                        child: CustomPaint(
                          painter: _SokobanPainter(
                            board: _board,
                            cellSize: cellSize,
                            paintVersion: _paintVersion,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SokobanPainter extends CustomPainter {
  final SokobanBoard board;
  final double cellSize;
  final int paintVersion;

  _SokobanPainter({
    required this.board,
    required this.cellSize,
    required this.paintVersion,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final wallPaint = Paint()..color = const Color(0xFF3D3D5C);
    final floorPaint = Paint()..color = const Color(0xFF1A1A2E);
    final goalPaint = Paint()..color = const Color(0xFF2A2A4A);
    final boxPaint = Paint()..color = const Color(0xFFF0C040);
    final boxOnGoalPaint = Paint()..color = const Color(0xFF4ECCA3);
    final playerPaint = Paint()..color = const Color(0xFF3A86FF);
    final goalMarkerPaint = Paint()
      ..color = const Color(0xFFE84545)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final wallBorderPaint = Paint()
      ..color = const Color(0xFF2A2A45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final boxBorderPaint = Paint()
      ..color = boxPaint.color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final boxOnGoalBorderPaint = Paint()
      ..color = boxOnGoalPaint.color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final innerPaint = Paint()..color = const Color(0xFFFFFFFF);

    for (int r = 0; r < board.rows; r++) {
      for (int c = 0; c < board.cols; c++) {
        final rect = Rect.fromLTWH(
          c * cellSize,
          r * cellSize,
          cellSize,
          cellSize,
        );

        final cell = board.grid[r][c];
        final pos = Position(r, c);
        final isBox = board.boxes.contains(pos);
        final isGoal = cell == CellType.goal;
        final isPlayer = board.player == pos;

        // Draw floor/wall/goal background
        if (cell == CellType.wall) {
          canvas.drawRect(rect, wallPaint);
          canvas.drawRect(rect, wallBorderPaint);
        } else {
          canvas.drawRect(rect, isGoal ? goalPaint : floorPaint);
        }

        // Draw goal marker
        if (isGoal && !isBox) {
          canvas.drawCircle(rect.center, cellSize * 0.2, goalMarkerPaint);
        }

        // Draw box
        if (isBox) {
          final inset = cellSize * 0.1;
          final boxRect = rect.deflate(inset);
          final paint = isGoal ? boxOnGoalPaint : boxPaint;
          final rrect = RRect.fromRectAndRadius(
            boxRect,
            Radius.circular(cellSize * 0.12),
          );
          canvas.drawRRect(rrect, paint);
          canvas.drawRRect(
              rrect, isGoal ? boxOnGoalBorderPaint : boxBorderPaint);
        }

        // Draw player
        if (isPlayer) {
          final center = rect.center;
          canvas.drawCircle(center, cellSize * 0.35, playerPaint);
          canvas.drawCircle(center, cellSize * 0.12, innerPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SokobanPainter oldDelegate) =>
      paintVersion != oldDelegate.paintVersion ||
      cellSize != oldDelegate.cellSize;
}
