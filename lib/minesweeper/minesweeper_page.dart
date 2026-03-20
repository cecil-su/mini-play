// lib/minesweeper/minesweeper_page.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import '../shared/game_over_data.dart';
import '../shared/game_over_page.dart';
import '../shared/game_scaffold.dart';
import '../shared/score_service.dart';
import 'minesweeper_board.dart';
import 'minesweeper_cell.dart';
import 'minesweeper_cell_widget.dart';

String formatTime(int seconds) {
  if (seconds < 60) return '$seconds s';
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}

class MinesweeperPage extends StatefulWidget {
  final MinesweeperDifficulty difficulty;

  const MinesweeperPage({super.key, required this.difficulty});

  @override
  State<MinesweeperPage> createState() => _MinesweeperPageState();
}

class _MinesweeperPageState extends State<MinesweeperPage> {
  Key _gameKey = UniqueKey();
  late MinesweeperBoard _board;
  late ValueNotifier<int> _timerNotifier;
  int _bestTime = 0;
  bool _isPaused = false;
  bool _isDigMode = true; // true = dig, false = flag
  Timer? _timer;
  int _elapsedSeconds = 0;
  Timer? _gameOverDelayTimer;

  MinesweeperDifficulty get _diff => widget.difficulty;

  @override
  void initState() {
    super.initState();
    _createGame();
    _loadBestTime();
  }

  void _createGame() {
    _board = MinesweeperBoard(
      rows: _diff.rows,
      cols: _diff.cols,
      totalMines: _diff.mines,
    );
    _timerNotifier = ValueNotifier<int>(0);
    _isPaused = false;
    _isDigMode = true;
    _elapsedSeconds = 0;
    _timer?.cancel();
    _timer = null;
    _gameOverDelayTimer?.cancel();
    _gameOverDelayTimer = null;
  }

  Future<void> _loadBestTime() async {
    _bestTime = await ScoreService().getHighScore('minesweeper', _diff.scoreMode);
    if (mounted) setState(() {});
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPaused && _board.gameState == MinesweeperGameState.playing) {
        _elapsedSeconds++;
        _timerNotifier.value = _elapsedSeconds;
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _onCellTap(int row, int col) {
    if (_board.gameState != MinesweeperGameState.playing || _isPaused) return;

    setState(() {
      if (_isDigMode) {
        // Dig mode: tap revealed number = chord, tap unrevealed = reveal
        if (_board.grid[row][col].isRevealed) {
          _board.chordReveal(row, col);
        } else {
          _board.reveal(row, col);
        }
      } else {
        // Flag mode: tap = flag
        _board.toggleFlag(row, col);
      }
    });

    // Start timer only after first reveal (not on flag-only actions)
    if (_timer == null && !_board.isFirstMove && _board.gameState == MinesweeperGameState.playing) {
      _startTimer();
    }

    _handleGameState();
  }

  void _onCellLongPress(int row, int col) {
    if (_board.gameState != MinesweeperGameState.playing || _isPaused) return;

    setState(() {
      if (_isDigMode) {
        // Dig mode: long press = flag
        _board.toggleFlag(row, col);
      } else {
        // Flag mode: long press = reveal
        if (_board.grid[row][col].isRevealed) {
          _board.chordReveal(row, col);
        } else {
          _board.reveal(row, col);
        }
      }
    });

    // Start timer only after first reveal (not on flag-only actions)
    if (_timer == null && !_board.isFirstMove && _board.gameState == MinesweeperGameState.playing) {
      _startTimer();
    }

    _handleGameState();
  }

  void _onCellSecondaryTap(int row, int col) {
    if (_board.gameState != MinesweeperGameState.playing || _isPaused) return;

    setState(() {
      _board.toggleFlag(row, col);
    });
  }

  void _handleGameState() {
    if (_board.gameState == MinesweeperGameState.won) {
      _stopTimer();
      _onWin();
    } else if (_board.gameState == MinesweeperGameState.lost) {
      _stopTimer();
      setState(() {}); // Show revealed mines
      _gameOverDelayTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) _onLoss();
      });
    }
  }

  Future<void> _onWin() async {
    await ScoreService().saveHighScore(
      'minesweeper', _diff.scoreMode, _elapsedSeconds,
      lowerIsBetter: true,
    );
    final best = await ScoreService().getHighScore('minesweeper', _diff.scoreMode);
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameOverPage(
          data: GameOverData(
            gameName: 'minesweeper',
            mode: _diff.scoreMode,
            stats: {
              'Time': formatTime(_elapsedSeconds),
              'Difficulty': _diff.name,
              'Mines': '${_diff.mines}',
              'Best': best == 0 ? '--' : formatTime(best),
            },
            replayCallback: () {
              setState(() {
                _gameKey = UniqueKey();
                _createGame();
              });
              _loadBestTime();
            },
          ),
        ),
      ),
    );
  }

  void _onLoss() {
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameOverPage(
          data: GameOverData(
            gameName: 'minesweeper',
            mode: _diff.scoreMode,
            stats: {
              'Time': formatTime(_elapsedSeconds),
              'Difficulty': _diff.name,
              'Mines': '${_diff.mines}',
            },
            replayCallback: () {
              setState(() {
                _gameKey = UniqueKey();
                _createGame();
              });
              _loadBestTime();
            },
          ),
        ),
      ),
    );
  }

  void _onPause() {
    _isPaused = true;
    _gameOverDelayTimer?.cancel();
  }

  void _onResume() {
    _isPaused = false;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _gameOverDelayTimer?.cancel();
    _timerNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      key: _gameKey,
      title: 'Minesweeper - ${_diff.name}',
      scoreNotifier: _timerNotifier,
      bestScore: _bestTime,
      scoreLabel: 'Time',
      bestLabel: 'Best',
      scoreFormatter: formatTime,
      bestFormatter: (v) => v == 0 ? '--' : formatTime(v),
      onPause: _onPause,
      onResume: _onResume,
      canPause: () => _board.gameState == MinesweeperGameState.playing,
      child: Column(
        children: [
          // Mine counter
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.brightness_7, color: Color(0xFFF0C040), size: 20),
                const SizedBox(width: 8),
                Text(
                  '${_board.remainingMines}',
                  style: TextStyle(
                    color: _board.remainingMines >= 0
                        ? const Color(0xFFF0C040)
                        : const Color(0xFFE84545),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Board
          Expanded(
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cellSize = min(
                    constraints.maxWidth / _diff.cols,
                    constraints.maxHeight / _diff.rows,
                  ).clamp(28.0, double.infinity);
                  final boardWidth = cellSize * _diff.cols;
                  final boardHeight = cellSize * _diff.rows;

                  return InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 3.0,
                    constrained: false,
                    child: SizedBox(
                      width: boardWidth,
                      height: boardHeight,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _diff.cols,
                        ),
                        itemCount: _diff.rows * _diff.cols,
                        itemBuilder: (context, index) {
                          final row = index ~/ _diff.cols;
                          final col = index % _diff.cols;
                          return MinesweeperCellWidget(
                            cell: _board.grid[row][col],
                            size: cellSize,
                            onTap: () => _onCellTap(row, col),
                            onLongPress: () => _onCellLongPress(row, col),
                            onSecondaryTap: () => _onCellSecondaryTap(row, col),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Mode toggle
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ModeButton(
                  icon: Icons.search,
                  label: 'Dig',
                  isActive: _isDigMode,
                  onTap: () => setState(() => _isDigMode = true),
                ),
                const SizedBox(width: 16),
                _ModeButton(
                  icon: Icons.flag,
                  label: 'Flag',
                  isActive: !_isDigMode,
                  onTap: () => setState(() => _isDigMode = false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF4ECCA3).withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? const Color(0xFF4ECCA3) : Colors.grey,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFF4ECCA3) : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? const Color(0xFF4ECCA3) : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
