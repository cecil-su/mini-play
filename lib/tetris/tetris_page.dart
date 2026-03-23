// lib/tetris/tetris_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../shared/format_time.dart';
import '../shared/game_over_data.dart';
import '../shared/game_over_page.dart';
import '../shared/game_scaffold.dart';
import '../shared/score_service.dart';
import 'tetris_board.dart';
import 'tetris_colors.dart';
import 'tetris_piece.dart';

class TetrisPage extends StatefulWidget {
  final TetrisGameMode mode;

  const TetrisPage({super.key, required this.mode});

  @override
  State<TetrisPage> createState() => _TetrisPageState();
}

class _TetrisPageState extends State<TetrisPage> {
  Key _gameKey = UniqueKey();
  late TetrisBoard _board;
  final ValueNotifier<int> _scoreNotifier = ValueNotifier<int>(0);
  int _bestScore = 0;
  int _paintVersion = 0;
  bool _isPaused = false;
  Timer? _dropTimer;
  Timer? _sprintTimer;
  int _elapsedSeconds = 0;

  String get _modeName {
    switch (widget.mode) {
      case TetrisGameMode.classic:
        return 'Classic';
      case TetrisGameMode.sprint:
        return 'Sprint';
      case TetrisGameMode.marathon:
        return 'Marathon';
    }
  }

  String get _scoreMode => widget.mode.name;

  bool get _isSprint => widget.mode == TetrisGameMode.sprint;

  bool get _canPlay => !_isPaused && !_board.isGameOver && !_board.isWon;

  @override
  void initState() {
    super.initState();
    _createGame();
    _loadBestScore();
  }

  void _createGame() {
    _board = TetrisBoard(mode: widget.mode);
    _elapsedSeconds = 0;
    _isPaused = false;
    _scoreNotifier.value = 0;
    _startDropTimer();
    if (_isSprint) {
      _startSprintTimer();
    }
  }

  Future<void> _loadBestScore() async {
    _bestScore = await ScoreService().getHighScore('tetris', _scoreMode);
    if (mounted) setState(() {});
  }

  void _startDropTimer() {
    _dropTimer?.cancel();
    _dropTimer = Timer.periodic(
      Duration(milliseconds: _board.dropInterval),
      (_) => _onTick(),
    );
  }

  void _startSprintTimer() {
    _sprintTimer?.cancel();
    _sprintTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPaused && !_board.isGameOver && !_board.isWon) {
        _elapsedSeconds++;
        _scoreNotifier.value = _elapsedSeconds;
      }
    });
  }

  void _onTick() {
    if (!_canPlay) return;

    final locked = _board.tick();
    if (!_isSprint) {
      _scoreNotifier.value = _board.score;
    }
    _paintVersion++;
    setState(() {});

    if (locked) {
      _startDropTimer();
    }

    _checkGameOver();
  }

  void _checkGameOver() {
    if (!_board.isGameOver && !_board.isWon) return;
    _dropTimer?.cancel();
    _sprintTimer?.cancel();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _onGameOver();
    });
  }

  void _moveLeft() {
    if (!_canPlay) return;
    if (_board.moveLeft()) { _paintVersion++; setState(() {}); }
  }

  void _moveRight() {
    if (!_canPlay) return;
    if (_board.moveRight()) { _paintVersion++; setState(() {}); }
  }

  void _rotate() {
    if (!_canPlay) return;
    if (_board.rotate()) { _paintVersion++; setState(() {}); }
  }

  void _softDrop() {
    if (!_canPlay) return;
    if (_board.softDrop()) {
      if (!_isSprint) _scoreNotifier.value = _board.score;
      _paintVersion++;
      setState(() {});
    }
  }

  void _hardDrop() {
    if (!_canPlay) return;
    _board.hardDrop();
    if (!_isSprint) {
      _scoreNotifier.value = _board.score;
    }
    _paintVersion++;
    setState(() {});
    _startDropTimer();
    _checkGameOver();
  }

  Future<void> _onGameOver() async {
    Map<String, String> stats;

    if (_isSprint) {
      if (_board.isWon) {
        await ScoreService().saveHighScore(
          'tetris',
          _scoreMode,
          _elapsedSeconds,
          lowerIsBetter: true,
        );
        final best =
            await ScoreService().getHighScore('tetris', _scoreMode);
        if (!mounted) return;
        stats = {
          'Time': formatTime(_elapsedSeconds),
          'Best': best == 0 ? '--' : formatTime(best),
          'Lines': '${_board.linesCleared}',
          'Score': '${_board.score}',
        };
      } else {
        if (!mounted) return;
        stats = {
          'Time': formatTime(_elapsedSeconds),
          'Lines': '${_board.linesCleared}/40',
          'Score': '${_board.score}',
        };
      }
    } else {
      await ScoreService().saveHighScore('tetris', _scoreMode, _board.score);
      final best = await ScoreService().getHighScore('tetris', _scoreMode);
      if (!mounted) return;
      stats = {
        'Score': '${_board.score}',
        'Best': '$best',
        'Lines': '${_board.linesCleared}',
        'Level': '${_board.level}',
      };
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameOverPage(
          data: GameOverData(
            gameName: 'tetris',
            mode: _scoreMode,
            stats: stats,
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
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.keyA:
        _moveLeft();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.keyD:
        _moveRight();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
      case LogicalKeyboardKey.keyW:
        _rotate();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
      case LogicalKeyboardKey.keyS:
        _softDrop();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.space:
        _hardDrop();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.escape:
        Navigator.maybePop(context);
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  void _onPause() {
    _isPaused = true;
  }

  void _onResume() {
    _isPaused = false;
  }

  @override
  void dispose() {
    _dropTimer?.cancel();
    _sprintTimer?.cancel();
    _scoreNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      key: _gameKey,
      title: 'Tetris - $_modeName',
      scoreNotifier: _scoreNotifier,
      bestScore: _bestScore,
      scoreLabel: _isSprint ? 'Time' : 'Score',
      bestLabel: 'Best',
      scoreFormatter: _isSprint ? formatTime : null,
      bestFormatter: _isSprint
          ? (v) => v == 0 ? '--' : formatTime(v)
          : null,
      onPause: _onPause,
      onResume: _onResume,
      canPause: () => !_board.isGameOver && !_board.isWon,
      child: Focus(
        autofocus: true,
        onKeyEvent: _onKeyEvent,
        child: _TetrisGameBody(
          board: _board,
          paintVersion: _paintVersion,
          onMoveLeft: _moveLeft,
          onMoveRight: _moveRight,
          onRotate: _rotate,
          onSoftDrop: _softDrop,
          onHardDrop: _hardDrop,
          isSprint: _isSprint,
        ),
      ),
    );
  }
}

class _TetrisGameBody extends StatelessWidget {
  final TetrisBoard board;
  final int paintVersion;
  final VoidCallback onMoveLeft;
  final VoidCallback onMoveRight;
  final VoidCallback onRotate;
  final VoidCallback onSoftDrop;
  final VoidCallback onHardDrop;
  final bool isSprint;

  const _TetrisGameBody({
    required this.board,
    required this.paintVersion,
    required this.onMoveLeft,
    required this.onMoveRight,
    required this.onRotate,
    required this.onSoftDrop,
    required this.onHardDrop,
    required this.isSprint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Info bar: level + lines + next piece
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lv.${board.level}',
                style: const TextStyle(
                  color: Color(0xFF4ECCA3),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                isSprint
                    ? 'Lines: ${board.linesCleared}/40'
                    : 'Lines: ${board.linesCleared}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              Row(
                children: [
                  const Text(
                    'Next: ',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  _NextPiecePreview(type: board.nextPieceType),
                ],
              ),
            ],
          ),
        ),

        // Board
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: TetrisBoard.cols / TetrisBoard.rows,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: _BoardWidget(board: board, paintVersion: paintVersion),
              ),
            ),
          ),
        ),

        // Touch controls
        _TouchControls(
          onMoveLeft: onMoveLeft,
          onMoveRight: onMoveRight,
          onRotate: onRotate,
          onSoftDrop: onSoftDrop,
          onHardDrop: onHardDrop,
        ),
      ],
    );
  }
}

class _NextPiecePreview extends StatelessWidget {
  final PieceType type;

  const _NextPiecePreview({required this.type});

  @override
  Widget build(BuildContext context) {
    final piece = Piece(type: type);
    final cells = piece.cells;
    final color = TetrisColors.forPiece(type);

    // Find bounding box
    int minR = 10, maxR = -1, minC = 10, maxC = -1;
    for (final (r, c) in cells) {
      if (r < minR) minR = r;
      if (r > maxR) maxR = r;
      if (c < minC) minC = c;
      if (c > maxC) maxC = c;
    }
    final previewRows = maxR - minR + 1;
    final previewCols = maxC - minC + 1;

    return SizedBox(
      width: previewCols * 12.0,
      height: previewRows * 12.0,
      child: CustomPaint(
        painter: _PreviewPainter(
          cells: cells.map((c) => (c.$1 - minR, c.$2 - minC)).toList(),
          rows: previewRows,
          cols: previewCols,
          color: color,
        ),
      ),
    );
  }
}

class _PreviewPainter extends CustomPainter {
  final List<(int, int)> cells;
  final int rows;
  final int cols;
  final Color color;

  _PreviewPainter({
    required this.cells,
    required this.rows,
    required this.cols,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / cols;
    final cellH = size.height / rows;
    final paint = Paint()..color = color;
    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (final (r, c) in cells) {
      final rect = Rect.fromLTWH(c * cellW + 0.5, r * cellH + 0.5, cellW - 1, cellH - 1);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(1)), paint);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(1)), borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PreviewPainter old) =>
      cells != old.cells || color != old.color;
}

class _BoardWidget extends StatelessWidget {
  final TetrisBoard board;
  final int paintVersion;

  const _BoardWidget({required this.board, required this.paintVersion});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _BoardPainter(board: board, paintVersion: paintVersion),
        );
      },
    );
  }
}

class _BoardPainter extends CustomPainter {
  final TetrisBoard board;
  final int paintVersion;

  _BoardPainter({required this.board, required this.paintVersion});

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / TetrisBoard.cols;
    final cellH = size.height / TetrisBoard.rows;

    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = TetrisColors.boardBackground,
    );

    // Grid lines
    final gridPaint = Paint()
      ..color = TetrisColors.gridLine
      ..strokeWidth = 0.5;
    for (int r = 1; r < TetrisBoard.rows; r++) {
      canvas.drawLine(
        Offset(0, r * cellH),
        Offset(size.width, r * cellH),
        gridPaint,
      );
    }
    for (int c = 1; c < TetrisBoard.cols; c++) {
      canvas.drawLine(
        Offset(c * cellW, 0),
        Offset(c * cellW, size.height),
        gridPaint,
      );
    }

    // Locked cells
    for (int r = 0; r < TetrisBoard.rows; r++) {
      for (int c = 0; c < TetrisBoard.cols; c++) {
        final type = board.grid[r][c];
        if (type != null) {
          _drawCell(canvas, r, c, cellW, cellH, TetrisColors.forPiece(type));
        }
      }
    }

    if (!board.isGameOver && !board.isWon) {
      // Ghost piece
      final ghost = board.ghostPiece;
      for (final (r, c) in ghost.cells) {
        if (r >= 0 && r < TetrisBoard.rows) {
          _drawCell(canvas, r, c, cellW, cellH, TetrisColors.ghost);
        }
      }

      // Current piece
      final color = TetrisColors.forPiece(board.currentPiece.type);
      for (final (r, c) in board.currentPiece.cells) {
        if (r >= 0 && r < TetrisBoard.rows) {
          _drawCell(canvas, r, c, cellW, cellH, color);
        }
      }
    }

    // Board border
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..color = const Color(0xFF333355)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _drawCell(
      Canvas canvas, int r, int c, double cellW, double cellH, Color color) {
    final rect = Rect.fromLTWH(
      c * cellW + 1,
      r * cellH + 1,
      cellW - 2,
      cellH - 2,
    );
    final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(2));
    canvas.drawRRect(rRect, Paint()..color = color);
    // Highlight edge
    canvas.drawRRect(
      rRect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );
  }

  @override
  bool shouldRepaint(covariant _BoardPainter old) =>
      paintVersion != old.paintVersion;
}

class _TouchControls extends StatelessWidget {
  final VoidCallback onMoveLeft;
  final VoidCallback onMoveRight;
  final VoidCallback onRotate;
  final VoidCallback onSoftDrop;
  final VoidCallback onHardDrop;

  const _TouchControls({
    required this.onMoveLeft,
    required this.onMoveRight,
    required this.onRotate,
    required this.onSoftDrop,
    required this.onHardDrop,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ControlButton(
            icon: Icons.arrow_left,
            onPressed: onMoveLeft,
            label: '',
          ),
          _ControlButton(
            icon: Icons.arrow_drop_down,
            onPressed: onSoftDrop,
            label: '',
          ),
          _ControlButton(
            icon: Icons.arrow_right,
            onPressed: onMoveRight,
            label: '',
          ),
          _ControlButton(
            icon: Icons.rotate_right,
            onPressed: onRotate,
            label: '',
          ),
          _ControlButton(
            icon: Icons.vertical_align_bottom,
            onPressed: onHardDrop,
            label: 'Drop',
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String label;

  const _ControlButton({
    required this.icon,
    required this.onPressed,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF333355)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white70, size: 28),
            if (label.isNotEmpty)
              Text(
                label,
                style: const TextStyle(color: Colors.white54, fontSize: 9),
              ),
          ],
        ),
      ),
    );
  }
}
