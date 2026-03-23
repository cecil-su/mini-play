// lib/sudoku/sudoku_page.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../shared/format_time.dart';
import '../shared/game_over_data.dart';
import '../shared/game_over_page.dart';
import '../shared/game_scaffold.dart';
import '../shared/score_service.dart';
import 'sudoku_board.dart';
import 'sudoku_cell.dart';
import 'sudoku_cell_widget.dart';
import 'sudoku_colors.dart';
import 'sudoku_generator.dart';

class SudokuPage extends StatefulWidget {
  final SudokuDifficulty difficulty;
  const SudokuPage({super.key, required this.difficulty});

  @override
  State<SudokuPage> createState() => _SudokuPageState();
}

class _SudokuPageState extends State<SudokuPage> {
  SudokuBoard? _board;
  final _scoreNotifier = ValueNotifier<int>(0);
  int _bestScore = 0;
  int _errorCount = 0;
  int _elapsed = 0;
  Timer? _timer;
  Timer? _winDelayTimer;
  bool _timerStarted = false;
  bool _isPaused = false;
  bool _isNoteMode = false;
  bool _showErrors = true;
  int? _selectedRow;
  int? _selectedCol;
  Key _gameKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _loadBestScore();
    _generatePuzzle();
  }

  Future<void> _loadBestScore() async {
    _bestScore = await ScoreService().getHighScore('sudoku', widget.difficulty.scoreMode);
    if (mounted) setState(() {});
  }

  void _generatePuzzle() {
    // Synchronous generation — fast enough for 9x9 on native (<200ms).
    // TODO: For web (dart2js), consider chunked async via Future.delayed
    // to avoid UI jank on expert difficulty (see spec platform notes).
    final result = SudokuGenerator.generate(widget.difficulty);
    setState(() {
      _board = SudokuBoard.create(puzzle: result.puzzle, solution: result.solution);
    });
  }

  void _startTimerIfNeeded() {
    if (_timerStarted || _isPaused) return;
    _timerStarted = true;
    _restartTimer();
  }

  void _restartTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPaused) {
        setState(() => _elapsed++);
        _updateScore();
      }
    });
  }

  void _updateScore() {
    final d = widget.difficulty;
    final baseScore = _baseScore;
    final timeBonus = max(0, (baseScore - _elapsed * d.decayRate).round());
    final errorPenalty = _errorCount * d.errorPenalty;
    _scoreNotifier.value = max(0, baseScore + timeBonus - errorPenalty);
  }

  int get _baseScore {
    switch (widget.difficulty.scoreMode) {
      case 'easy': return 1000;
      case 'medium': return 2000;
      case 'hard': return 3000;
      case 'expert': return 5000;
      default: return 1000;
    }
  }

  void _onCellTap(int row, int col) {
    if (_board == null || _board!.gameState != SudokuGameState.playing) return;
    setState(() {
      _selectedRow = row;
      _selectedCol = col;
    });
  }

  void _onNumberTap(int digit) {
    if (_board == null || _selectedRow == null || _selectedCol == null) return;
    if (_board!.gameState != SudokuGameState.playing) return;
    final cell = _board!.grid[_selectedRow!][_selectedCol!];
    if (cell.isGiven) return;

    _startTimerIfNeeded();

    setState(() {
      if (_isNoteMode) {
        _board!.toggleNote(_selectedRow!, _selectedCol!, digit);
      } else {
        final wasError = _board!.setValue(_selectedRow!, _selectedCol!, digit);
        if (wasError) _errorCount++;
      }
      _updateScore();
    });

    if (_board!.gameState == SudokuGameState.won) {
      _onWin();
    }
  }

  void _onClear() {
    if (_board == null || _selectedRow == null || _selectedCol == null) return;
    if (_board!.gameState != SudokuGameState.playing) return;

    setState(() {
      _board!.clearCell(_selectedRow!, _selectedCol!);
    });
  }

  void _onUndo() {
    if (_board == null || _board!.gameState != SudokuGameState.playing) return;

    setState(() {
      _board!.undo();
      _updateScore();
    });
  }

  void _onWin() {
    _timer?.cancel();
    _updateScore();

    _winDelayTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      final score = _scoreNotifier.value;
      ScoreService().saveHighScore('sudoku', widget.difficulty.scoreMode, score);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GameOverPage(
            data: GameOverData(
              gameName: 'sudoku',
              mode: widget.difficulty.name,
              title: '恭喜通关',
              stats: {
                '难度': widget.difficulty.name,
                '用时': formatTime(_elapsed),
                '得分': '$score',
                '错误': '$_errorCount',
              },
              replayCallback: _replay,
              actions: [
                GameOverAction(
                  label: 'Play Again',
                  onPressed: _replay,
                  isPrimary: true,
                ),
                GameOverAction(
                  label: 'Choose Mode',
                  onPressed: () => Navigator.pop(context),
                ),
                GameOverAction(
                  label: 'Home',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  void _replay() {
    _timer?.cancel();
    _winDelayTimer?.cancel();
    setState(() {
      _board = null;
      _elapsed = 0;
      _errorCount = 0;
      _timerStarted = false;
      _isPaused = false;
      _isNoteMode = false;
      _selectedRow = null;
      _selectedCol = null;
      _scoreNotifier.value = 0;
      _gameKey = UniqueKey();
    });
    _loadBestScore();
    _generatePuzzle();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _winDelayTimer?.cancel();
    _scoreNotifier.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;

    // Arrow keys / WASD for navigation
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyW) {
      _moveSelection(-1, 0);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.keyS) {
      _moveSelection(1, 0);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) {
      _moveSelection(0, -1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.keyD) {
      _moveSelection(0, 1);
      return KeyEventResult.handled;
    }

    // Number keys
    final digitKeys = <LogicalKeyboardKey, int>{
      LogicalKeyboardKey.digit1: 1, LogicalKeyboardKey.digit2: 2,
      LogicalKeyboardKey.digit3: 3, LogicalKeyboardKey.digit4: 4,
      LogicalKeyboardKey.digit5: 5, LogicalKeyboardKey.digit6: 6,
      LogicalKeyboardKey.digit7: 7, LogicalKeyboardKey.digit8: 8,
      LogicalKeyboardKey.digit9: 9,
      LogicalKeyboardKey.numpad1: 1, LogicalKeyboardKey.numpad2: 2,
      LogicalKeyboardKey.numpad3: 3, LogicalKeyboardKey.numpad4: 4,
      LogicalKeyboardKey.numpad5: 5, LogicalKeyboardKey.numpad6: 6,
      LogicalKeyboardKey.numpad7: 7, LogicalKeyboardKey.numpad8: 8,
      LogicalKeyboardKey.numpad9: 9,
    };
    if (digitKeys.containsKey(key)) {
      _onNumberTap(digitKeys[key]!);
      return KeyEventResult.handled;
    }

    // Delete / Backspace / 0 to clear
    if (key == LogicalKeyboardKey.delete ||
        key == LogicalKeyboardKey.backspace ||
        key == LogicalKeyboardKey.digit0) {
      _onClear();
      return KeyEventResult.handled;
    }

    // N to toggle note mode
    if (key == LogicalKeyboardKey.keyN) {
      setState(() => _isNoteMode = !_isNoteMode);
      return KeyEventResult.handled;
    }

    // Z / Ctrl+Z to undo
    if (key == LogicalKeyboardKey.keyZ) {
      _onUndo();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _moveSelection(int dr, int dc) {
    setState(() {
      _selectedRow = ((_selectedRow ?? 4) + dr).clamp(0, 8);
      _selectedCol = ((_selectedCol ?? 4) + dc).clamp(0, 8);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      key: _gameKey,
      title: 'Sudoku - ${widget.difficulty.name}',
      scoreNotifier: _scoreNotifier,
      bestScore: _bestScore,
      scoreLabel: 'Score',
      bestLabel: 'Best',
      canPause: () => _board != null && _board!.gameState == SudokuGameState.playing,
      onPause: () {
        _isPaused = true;
        _timer?.cancel();
      },
      onResume: () {
        _isPaused = false;
        if (_timerStarted) _restartTimer();
      },
      child: Focus(
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: _board == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(child: _buildBoard()),
                  _buildActionBar(),
                  _buildNumberPad(),
                  const SizedBox(height: 8),
                ],
              ),
      ),
    );
  }

  Widget _buildBoard() {
    // Border widths: left(2) + 3 box borders(2×3) + 6 cell borders(0.5×6) = 11px per axis
    const borderOverhead = 2.0 + 3 * 2.0 + 6 * 0.5;

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = min(constraints.maxWidth, constraints.maxHeight);
        final cellSize = (available - borderOverhead) / 9;
        final actualBoardSize = cellSize * 9 + borderOverhead;

        return Center(
          child: SizedBox(
            width: actualBoardSize,
            height: actualBoardSize,
            child: _buildGrid(cellSize),
          ),
        );
      },
    );
  }

  Widget _buildGrid(double cellSize) {
    return Column(
      children: List.generate(9, (r) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(9, (c) {
            final cell = _board!.grid[r][c];
            final isSelected = r == _selectedRow && c == _selectedCol;
            final isRelated = _selectedRow != null && _selectedCol != null &&
                (r == _selectedRow ||
                    c == _selectedCol ||
                    (r ~/ 3 == _selectedRow! ~/ 3 && c ~/ 3 == _selectedCol! ~/ 3));
            final selectedValue = _selectedRow != null && _selectedCol != null
                ? _board!.grid[_selectedRow!][_selectedCol!].value
                : 0;
            final isSameNumber = cell.value != 0 && cell.value == selectedValue && !isSelected;
            final showError = _showErrors && _board!.errorCells.contains((r, c));

            return Container(
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: c == 2 || c == 5 || c == 8
                        ? SudokuColors.boxBorder
                        : SudokuColors.cellBorder,
                    width: c == 2 || c == 5 || c == 8 ? 2 : 0.5,
                  ),
                  bottom: BorderSide(
                    color: r == 2 || r == 5 || r == 8
                        ? SudokuColors.boxBorder
                        : SudokuColors.cellBorder,
                    width: r == 2 || r == 5 || r == 8 ? 2 : 0.5,
                  ),
                  left: c == 0
                      ? BorderSide(color: SudokuColors.boxBorder, width: 2)
                      : BorderSide.none,
                  top: r == 0
                      ? BorderSide(color: SudokuColors.boxBorder, width: 2)
                      : BorderSide.none,
                ),
              ),
              child: SudokuCellWidget(
                cell: cell,
                size: cellSize,
                isSelected: isSelected,
                isRelated: isRelated,
                isSameNumber: isSameNumber,
                showError: showError,
                onTap: () => _onCellTap(r, c),
              ),
            );
          }),
        );
      }),
    );
  }

  Widget _buildActionBar() {
    final won = _board!.gameState == SudokuGameState.won;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _actionButton(
            icon: Icons.edit,
            label: '填数',
            isActive: !_isNoteMode,
            onTap: won ? null : () => setState(() => _isNoteMode = false),
          ),
          _actionButton(
            icon: Icons.edit_note,
            label: '笔记',
            isActive: _isNoteMode,
            onTap: won ? null : () => setState(() => _isNoteMode = true),
          ),
          _actionButton(
            icon: Icons.undo,
            label: '撤销',
            isActive: false,
            enabled: _board!.canUndo && !won,
            onTap: won ? null : _onUndo,
          ),
          _actionButton(
            icon: Icons.clear,
            label: '清除',
            isActive: false,
            onTap: won ? null : _onClear,
          ),
          _actionButton(
            icon: _showErrors ? Icons.visibility : Icons.visibility_off,
            label: '检查',
            isActive: _showErrors,
            onTap: won ? null : () => setState(() => _showErrors = !_showErrors),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required bool isActive,
    bool enabled = true,
    VoidCallback? onTap,
  }) {
    final color = !enabled
        ? Colors.grey.withValues(alpha: 0.3)
        : isActive
            ? SudokuColors.activeButton
            : Colors.grey;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: color, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    final won = _board!.gameState == SudokuGameState.won;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final buttonWidth = (constraints.maxWidth - 8 * 4) / 9;
          final useWide = buttonWidth >= 44;

          if (useWide) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(9, (i) => _numButton(i + 1, won)),
            );
          } else {
            // 3x3 fallback for narrow screens
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [for (int d = 1; d <= 3; d++) _numButton(d, won)],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [for (int d = 4; d <= 6; d++) _numButton(d, won)],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [for (int d = 7; d <= 9; d++) _numButton(d, won)],
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _numButton(int digit, bool won) {
    final complete = _board!.isDigitComplete(digit);
    final disabled = won || complete;

    return GestureDetector(
      onTap: disabled ? null : () => _onNumberTap(digit),
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: disabled ? SudokuColors.disabledButton : SudokuColors.inactiveButton,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$digit',
          style: TextStyle(
            color: disabled ? Colors.grey.withValues(alpha: 0.3) : Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
