// lib/klotski/klotski_page.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../shared/game_over_data.dart';
import '../shared/game_over_page.dart';
import '../shared/game_scaffold.dart';
import '../shared/score_service.dart';
import 'klotski_board.dart';
import 'klotski_block_widget.dart';
import 'klotski_colors.dart';
import 'klotski_config.dart';
import 'klotski_levels.dart';
import 'klotski_models.dart';
import 'klotski_solver.dart';

class KlotskiPage extends StatefulWidget {
  final int levelIndex;

  const KlotskiPage({super.key, required this.levelIndex});

  @override
  State<KlotskiPage> createState() => _KlotskiPageState();
}

class _KlotskiPageState extends State<KlotskiPage>
    with TickerProviderStateMixin {
  Key _gameKey = UniqueKey();
  late int _currentLevel;
  late KlotskiBoard _board;
  final ValueNotifier<int> _movesNotifier = ValueNotifier<int>(0);
  int _bestMoves = 0;
  bool _hasCompletedBefore = false;
  bool _isPaused = false;
  bool _isVictoryAnimating = false;
  final FocusNode _focusNode = FocusNode();
  int? _selectedBlockId;

  // 提示系统
  List<KlotskiMove>? _hintSolution;
  int _hintsRemaining = 0;

  // 胜利动画
  late AnimationController _victoryController;
  late Animation<double> _caoSlideOut;
  late Animation<double> _othersFade;

  // 计时
  final Stopwatch _stopwatch = Stopwatch();

  KlotskiLevel get _level => klotskiLevels[_currentLevel];

  @override
  void initState() {
    super.initState();
    _currentLevel = widget.levelIndex;
    _board = KlotskiBoard(_level.blocks);
    _hintsRemaining = _hintsForDifficulty(_level.difficulty);

    _victoryController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _caoSlideOut = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _victoryController,
        curve: const Interval(0.0, 0.625, curve: Curves.easeInCubic),
      ),
    );
    _othersFade = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _victoryController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _loadBest();
  }

  int _hintsForDifficulty(KlotskiDifficulty diff) {
    return switch (diff) {
      KlotskiDifficulty.beginner => 5,
      KlotskiDifficulty.advanced => 8,
      KlotskiDifficulty.master => 12,
    };
  }

  Future<void> _loadBest() async {
    final service = ScoreService();
    _hasCompletedBefore = await service.hasScore('klotski', 'level_$_currentLevel');
    if (_hasCompletedBefore) {
      _bestMoves = await service.getHighScore('klotski', 'level_$_currentLevel');
    } else {
      _bestMoves = 0;
    }
    if (mounted) setState(() {});
  }

  void _handleMove(int blockId, Direction dir, int distance) {
    if (_isPaused || _board.isWon || _isVictoryAnimating) return;

    if (!_stopwatch.isRunning) _stopwatch.start();

    _board.moveBlock(blockId, dir, distance);
    _hintSolution = null; // 缓存失效

    _movesNotifier.value = _board.moves;
    setState(() {});

    if (_board.isWon) {
      _onVictory();
    }
  }

  void _undo() {
    if (_isPaused || !_board.canUndo || _isVictoryAnimating) return;
    _board.undo();
    _hintSolution = null;

    _movesNotifier.value = _board.moves;
    setState(() {});
  }

  void _resetLevel() {
    if (_isVictoryAnimating) return;
    _board.reset();
    _movesNotifier.value = 0;
    _hintSolution = null;

    _hintsRemaining = _hintsForDifficulty(_level.difficulty);
    _stopwatch.reset();
    setState(() {});
  }

  void _useHint() {
    if (_isPaused || _board.isWon || _isVictoryAnimating) return;
    if (_hintsRemaining <= 0) return;

    // 求解或使用缓存
    _hintSolution ??= KlotskiSolver.solve(_board.blocks);
    if (_hintSolution == null || _hintSolution!.isEmpty) return;

    final nextMove = _hintSolution!.first;
    // 在当前棋盘中找到匹配方块
    final block = _board.blocks.where(
      (b) => b.type == nextMove.blockType && b.row == nextMove.fromRow && b.col == nextMove.fromCol,
    ).firstOrNull;

    if (block != null) {
      _hintsRemaining--;
      setState(() {});
      // TODO: 高亮 block + 方向箭头动画
    }
  }

  void _onVictory() async {
    _stopwatch.stop();
    _isVictoryAnimating = true;
    HapticFeedback.mediumImpact();

    await Future.delayed(const Duration(milliseconds: 300));

    void onComplete(AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        _victoryController.removeStatusListener(onComplete);
        _saveAndShowResult();
      }
    }
    _victoryController.addStatusListener(onComplete);
    _victoryController.forward();
  }

  Future<void> _saveAndShowResult() async {
    await ScoreService().saveHighScore(
      'klotski',
      'level_$_currentLevel',
      _board.moves,
      lowerIsBetter: true,
    );
    final best = await ScoreService().getHighScore('klotski', 'level_$_currentLevel');

    if (!mounted) return;

    final hasNext = _currentLevel + 1 < klotskiLevels.length;
    final level = _level;

    final stats = <String, String>{
      '关卡': level.name,
      '步数': '${_board.moves}',
      if (_hasCompletedBefore && level.minMoves > 0) '最优': '${level.minMoves}',
      '最佳': '$best',
      '用时': _formatTime(_stopwatch.elapsed),
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameOverPage(
          data: GameOverData(
            gameName: 'klotski',
            mode: 'level_$_currentLevel',
            title: '恭喜通关',
            stats: stats,
            replayCallback: _replayCurrent,
            actions: [
              if (hasNext)
                GameOverAction(
                  label: '下一关',
                  onPressed: _goNextLevel,
                  isPrimary: true,
                ),
              GameOverAction(
                label: '再试一次',
                onPressed: _replayCurrent,
              ),
              GameOverAction(
                label: '返回',
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m}m ${s}s';
  }

  void _replayCurrent() {
    setState(() {
      _gameKey = UniqueKey();
      _board = KlotskiBoard(_level.blocks);
      _movesNotifier.value = 0;
      _isVictoryAnimating = false;
      _victoryController.reset();
      _hintSolution = null;
  
      _hintsRemaining = _hintsForDifficulty(_level.difficulty);
      _stopwatch.reset();
    });
    _loadBest();
  }

  void _goNextLevel() {
    setState(() {
      _currentLevel++;
      _gameKey = UniqueKey();
      _board = KlotskiBoard(_level.blocks);
      _movesNotifier.value = 0;
      _isVictoryAnimating = false;
      _victoryController.reset();
      _hintSolution = null;
  
      _hintsRemaining = _hintsForDifficulty(_level.difficulty);
      _stopwatch.reset();
    });
    _loadBest();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (_isPaused || _isVictoryAnimating) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.keyZ) {
      _undo();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyR) {
      _resetLevel();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.tab) {
      _cycleSelectedBlock();
      return KeyEventResult.handled;
    }

    // 方向键移动选中方块
    Direction? dir;
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) dir = Direction.up;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) dir = Direction.down;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) dir = Direction.left;
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) dir = Direction.right;

    if (dir != null && _selectedBlockId != null) {
      final maxDist = _board.maxDistance(_selectedBlockId!, dir);
      if (maxDist > 0) {
        _handleMove(_selectedBlockId!, dir, 1);
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _cycleSelectedBlock() {
    final ids = _board.blocks.map((b) => b.id).toList();
    if (ids.isEmpty) return;
    if (_selectedBlockId == null) {
      _selectedBlockId = ids.first;
    } else {
      final idx = ids.indexOf(_selectedBlockId!);
      _selectedBlockId = ids[(idx + 1) % ids.length];
    }
    setState(() {});
  }

  void _onPause() {
    _isPaused = true;
    _stopwatch.stop();
  }

  void _onResume() {
    _isPaused = false;
    if (_board.moves > 0 && !_board.isWon) _stopwatch.start();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _victoryController.dispose();
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
        title: '${_level.name} (#${_currentLevel + 1})',
        scoreNotifier: _movesNotifier,
        bestScore: _bestMoves,
        scoreLabel: '步数',
        bestLabel: '最佳',
        bestFormatter: (v) => v == 0 ? '--' : '$v',
        onPause: _onPause,
        onResume: _onResume,
        canPause: () => !_board.isWon && !_isVictoryAnimating,
        child: Column(
          children: [
            // 操作栏
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
                    tooltip: '撤销 (Z)',
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.lightbulb_outline, size: 18),
                    label: Text('提示 ×$_hintsRemaining'),
                    onPressed: _hintsRemaining > 0 ? _useHint : null,
                    style: TextButton.styleFrom(
                      foregroundColor: _hintsRemaining > 0
                          ? const Color(0xFFF0C040)
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Color(0xFFF0C040)),
                    onPressed: _resetLevel,
                    tooltip: '重置 (R)',
                  ),
                ],
              ),
            ),

            // 棋盘
            Expanded(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cellSize = min(
                      constraints.maxWidth / boardCols,
                      (constraints.maxHeight - 8) / boardRows,
                    ).clamp(40.0, 90.0);
                    final boardWidth = cellSize * boardCols;
                    final boardHeight = cellSize * boardRows;

                    return SizedBox(
                      width: boardWidth,
                      height: boardHeight + 20, // extra for exit marker
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // 背景
                          _BoardBackground(
                            cellSize: cellSize,
                            boardWidth: boardWidth,
                            boardHeight: boardHeight,
                          ),

                          // 方块
                          ..._buildBlockWidgets(cellSize),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBlockWidgets(double cellSize) {
    return _board.blocks.map((block) {
      final isCao = block.type == BlockType.cao;

      // 胜利动画
      if (_isVictoryAnimating) {
        if (isCao) {
          return AnimatedBuilder(
            animation: _victoryController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  block.col * cellSize,
                  block.row * cellSize + _caoSlideOut.value * cellSize * 3,
                ),
                child: Opacity(
                  opacity: 1.0,
                  child: _staticBlock(block, cellSize),
                ),
              );
            },
          );
        } else {
          return AnimatedBuilder(
            animation: _victoryController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  block.col * cellSize,
                  block.row * cellSize,
                ),
                child: Opacity(
                  opacity: _othersFade.value,
                  child: _staticBlock(block, cellSize),
                ),
              );
            },
          );
        }
      }

      // 正常游戏
      return KlotskiBlockWidget(
        key: ValueKey(block.id),
        block: block,
        cellSize: cellSize,
        maxDistance: (dir) => _board.maxDistance(block.id, dir),
        onMoved: (dir, dist) => _handleMove(block.id, dir, dist),
        enabled: !_isPaused && !_board.isWon,
      );
    }).toList();
  }

  Widget _staticBlock(Block block, double cellSize) {
    final blockWidth = block.width * cellSize;
    final blockHeight = block.height * cellSize;
    return SizedBox(
      width: blockWidth,
      height: blockHeight,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Container(
          decoration: BoxDecoration(
            color: KlotskiColors.bgForType(block.type),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              block.label,
              style: TextStyle(
                color: KlotskiColors.blockText,
                fontSize: cellSize * 0.4,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BoardBackground extends StatelessWidget {
  final double cellSize;
  final double boardWidth;
  final double boardHeight;

  const _BoardBackground({
    required this.cellSize,
    required this.boardWidth,
    required this.boardHeight,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(boardWidth, boardHeight + 20),
      painter: _BoardPainter(cellSize: cellSize),
    );
  }
}

class _BoardPainter extends CustomPainter {
  final double cellSize;

  _BoardPainter({required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    final boardWidth = boardCols * cellSize;
    final boardHeight = boardRows * cellSize;

    // 棋盘背景
    final bgPaint = Paint()..color = KlotskiColors.boardBg;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, boardWidth, boardHeight),
        const Radius.circular(6),
      ),
      bgPaint,
    );

    // 格子
    final cellPaint = Paint()..color = KlotskiColors.cellBg;
    final borderPaint = Paint()
      ..color = KlotskiColors.cellBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int r = 0; r < boardRows; r++) {
      for (int c = 0; c < boardCols; c++) {
        final rect = Rect.fromLTWH(
          c * cellSize + 1,
          r * cellSize + 1,
          cellSize - 2,
          cellSize - 2,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(2)),
          cellPaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(2)),
          borderPaint,
        );
      }
    }

    // 出口标记（底部第 1-2 列）
    final exitPaint = Paint()
      ..color = KlotskiColors.exitGlow.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    final exitRect = Rect.fromLTWH(
      exitCol * cellSize,
      boardHeight,
      2 * cellSize,
      12,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(exitRect, const Radius.circular(4)),
      exitPaint,
    );

    // EXIT 文字
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'EXIT',
        style: TextStyle(
          color: KlotskiColors.exitGlow.withValues(alpha: 0.6),
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        exitCol * cellSize + cellSize - textPainter.width / 2,
        boardHeight + 1,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) =>
      cellSize != oldDelegate.cellSize;
}
