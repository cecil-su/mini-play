// lib/game_2048/game_2048_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../shared/game_over_data.dart';
import '../shared/game_over_page.dart';
import '../shared/game_scaffold.dart';
import '../shared/score_service.dart';
import 'game_2048_animated_tile.dart';
import 'game_2048_board.dart';
import 'game_2048_colors.dart';

class Game2048Page extends StatefulWidget {
  final int gridSize;

  const Game2048Page({super.key, required this.gridSize});

  @override
  State<Game2048Page> createState() => _Game2048PageState();
}

class _Game2048PageState extends State<Game2048Page> {
  Key _gameKey = UniqueKey();
  late GameBoard _board;
  late ValueNotifier<int> _scoreNotifier;
  int _bestScore = 0;
  bool _isPaused = false;
  bool _isAnimating = false;
  bool _show2048Overlay = false;
  bool _has2048BeenShown = false;

  String get _mode => '${widget.gridSize}x${widget.gridSize}';

  @override
  void initState() {
    super.initState();
    _createGame();
    _loadBestScore();
  }

  void _createGame() {
    _board = GameBoard(gridSize: widget.gridSize);
    _scoreNotifier = ValueNotifier<int>(0);
    _isPaused = false;
    _isAnimating = false;
    _show2048Overlay = false;
    _has2048BeenShown = false;
  }

  Future<void> _loadBestScore() async {
    _bestScore = await ScoreService().getHighScore('2048', _mode);
    if (mounted) setState(() {});
  }

  void _onMove(Direction direction) {
    if (_isPaused || _isAnimating || _show2048Overlay) return;

    final moved = _board.slide(direction);
    if (moved) {
      _scoreNotifier.value = _board.score;
    }

    setState(() {
      _isAnimating = true;
    });

    // Wait for animation to finish
    Future.delayed(kTileAnimationDuration, () {
      if (!mounted) return;
      setState(() {
        _isAnimating = false;
      });

      if (moved && _board.hasReached2048 && !_has2048BeenShown) {
        _has2048BeenShown = true;
        setState(() {
          _show2048Overlay = true;
        });
        return;
      }

      if (_board.isGameOver) {
        _onGameOver();
      }
    });
  }

  void _onUndo() {
    if (_isPaused || _isAnimating || _show2048Overlay) return;
    if (_board.undo()) {
      _scoreNotifier.value = _board.score;
      setState(() {});
    }
  }

  void _continue2048() {
    setState(() {
      _show2048Overlay = false;
    });
  }

  void _viewScore() {
    setState(() {
      _show2048Overlay = false;
    });
    _onGameOver();
  }

  Future<void> _onGameOver() async {
    final score = _board.score;
    await ScoreService().saveHighScore('2048', _mode, score);
    final best = await ScoreService().getHighScore('2048', _mode);
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameOverPage(
          data: GameOverData(
            gameName: '2048',
            mode: _mode,
            stats: {
              'Score': '$score',
              'Best': '$best',
              'Max Tile': '${_board.maxTileValue}',
              'Moves': '${_board.moveCount}',
            },
            replayCallback: () {
              setState(() {
                _gameKey = UniqueKey();
                _createGame();
              });
              _loadBestScore();
            },
          ),
        ),
      ),
    );
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    Direction? direction;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
      case LogicalKeyboardKey.keyW:
        direction = Direction.up;
      case LogicalKeyboardKey.arrowDown:
      case LogicalKeyboardKey.keyS:
        direction = Direction.down;
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.keyA:
        direction = Direction.left;
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.keyD:
        direction = Direction.right;
      case LogicalKeyboardKey.escape:
        // Trigger pause by simulating a back-button press,
        // which GameScaffold's PopScope intercepts to show the pause overlay.
        Navigator.maybePop(context);
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }

    _onMove(direction);
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    _scoreNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      key: _gameKey,
      title: '2048 - $_mode',
      scoreNotifier: _scoreNotifier,
      bestScore: _bestScore,
      onPause: () => setState(() => _isPaused = true),
      onResume: () => setState(() => _isPaused = false),
      child: Focus(
        autofocus: true,
        onKeyEvent: _onKeyEvent,
        child: GestureDetector(
          onPanEnd: (details) {
            final velocity = details.velocity.pixelsPerSecond;
            if (velocity.dx.abs() > velocity.dy.abs()) {
              _onMove(velocity.dx > 0 ? Direction.right : Direction.left);
            } else {
              _onMove(velocity.dy > 0 ? Direction.down : Direction.up);
            }
          },
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Stack(
                        children: [
                          // Board + tiles
                          _BoardWidget(
                            board: _board,
                            gridSize: widget.gridSize,
                          ),
                          // 2048 congratulations overlay (Positioned.fill so it
                          // covers the entire board, not just its content size)
                          if (_show2048Overlay)
                            Positioned.fill(
                              child: _CongratulationsOverlay(
                                onContinue: _continue2048,
                                onViewScore: _viewScore,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Undo button
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextButton.icon(
                  onPressed: _board.undoRemaining > 0 && _board.moveCount > 0 ? _onUndo : null,
                  icon: const Icon(Icons.undo),
                  label: Text('Undo (${_board.undoRemaining})'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF4ECCA3),
                    disabledForegroundColor: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoardWidget extends StatelessWidget {
  final GameBoard board;
  final int gridSize;

  const _BoardWidget({required this.board, required this.gridSize});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = constraints.maxWidth;
        final spacing = TileColors.getCellSpacing(gridSize);
        final totalSpacing = spacing * (gridSize + 1);
        final cellSize = (boardSize - totalSpacing) / gridSize;

        return Container(
          decoration: BoxDecoration(
            color: TileColors.boardBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              // Empty cell backgrounds
              for (int r = 0; r < gridSize; r++)
                for (int c = 0; c < gridSize; c++)
                  Positioned(
                    left: spacing + c * (cellSize + spacing),
                    top: spacing + r * (cellSize + spacing),
                    width: cellSize,
                    height: cellSize,
                    child: Container(
                      decoration: BoxDecoration(
                        color: TileColors.emptyCell,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
              // Animated tiles
              for (final tile in board.tiles)
                AnimatedTileWidget(
                  key: ValueKey(tile.id),
                  tile: tile,
                  cellSize: cellSize,
                  spacing: spacing,
                  gridSize: gridSize,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CongratulationsOverlay extends StatelessWidget {
  final VoidCallback onContinue;
  final VoidCallback onViewScore;

  const _CongratulationsOverlay({
    required this.onContinue,
    required this.onViewScore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xCC000000),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '\u{1F389}',
              style: TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 8),
            const Text(
              'You reached 2048!',
              style: TextStyle(
                color: Color(0xFFF0C040),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4ECCA3),
                foregroundColor: const Color(0xFF1A1A2E),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              onPressed: onContinue,
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onViewScore,
              child: const Text(
                'View Score',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
