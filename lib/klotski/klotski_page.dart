// lib/klotski/klotski_page.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Hint system
  List<KlotskiMove>? _hintSolution;
  int _hintsRemaining = 0;
  int? _hintedBlockId;
  Direction? _hintDirection;
  bool _watchedSolution = false;
  bool _isPlayingSolution = false;

  // Victory animation
  late AnimationController _victoryController;
  late Animation<double> _caoSlideOut;
  late Animation<double> _othersFade;

  // Exit pulse animation
  late AnimationController _exitPulseController;

  // Confetti
  late AnimationController _confettiController;
  List<_ConfettiParticle>? _confettiParticles;

  // Tutorial
  int? _tutorialStep; // null = no tutorial, 0+ = current step

  // Timer
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

    _exitPulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _loadBest();
    _initTutorial();
  }

  Future<void> _initTutorial() async {
    if (_currentLevel > 2) return;
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('klotski_tutorial_$_currentLevel') ?? false;
    if (!seen && mounted) {
      setState(() => _tutorialStep = 0);
    }
  }

  void _advanceTutorial() {
    if (_tutorialStep == null) return;
    final maxSteps = _currentLevel == 0 ? 1 : 0; // level 0 has 2 steps, others 1
    if (_tutorialStep! < maxSteps) {
      setState(() => _tutorialStep = _tutorialStep! + 1);
    } else {
      _dismissTutorial();
    }
  }

  void _dismissTutorial() async {
    if (_tutorialStep == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('klotski_tutorial_$_currentLevel', true);
    if (mounted) setState(() => _tutorialStep = null);
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

  // ──────────────────── Star calculation ────────────────────

  static int calcStars(int moves, int minMoves, KlotskiDifficulty diff) {
    if (minMoves <= 0) return 1;
    final (bm3, r3, bm2, r2) = switch (diff) {
      KlotskiDifficulty.beginner => (8, 0.15, 16, 0.40),
      KlotskiDifficulty.advanced => (10, 0.20, 20, 0.50),
      KlotskiDifficulty.master => (12, 0.25, 24, 0.60),
    };
    final star3 = minMoves + _imax(bm3, (minMoves * r3).round());
    final star2 = minMoves + _imax(bm2, (minMoves * r2).round());
    if (moves <= star3) return 3;
    if (moves <= star2) return 2;
    return 1;
  }

  static int _imax(int a, int b) => a > b ? a : b;

  /// Star thresholds for move counter color
  (int star3, int star2) _starThresholds() {
    final m = _level.minMoves;
    if (m <= 0) return (0, 0);
    final diff = _level.difficulty;
    final (bm3, r3, bm2, r2) = switch (diff) {
      KlotskiDifficulty.beginner => (8, 0.15, 16, 0.40),
      KlotskiDifficulty.advanced => (10, 0.20, 20, 0.50),
      KlotskiDifficulty.master => (12, 0.25, 24, 0.60),
    };
    return (
      m + _imax(bm3, (m * r3).round()),
      m + _imax(bm2, (m * r2).round()),
    );
  }

  Color _moveCounterColor(int moves) {
    // Master: only enable color after first completion
    if (_level.difficulty == KlotskiDifficulty.master && !_hasCompletedBefore) {
      return KlotskiColors.moveGreen;
    }
    final (star3, star2) = _starThresholds();
    if (star3 == 0) return KlotskiColors.moveGreen;
    if (moves <= star3) return KlotskiColors.moveGreen;
    if (moves <= star2) return KlotskiColors.moveYellow;
    return KlotskiColors.moveRed;
  }

  // ──────────────────── Game actions ────────────────────

  void _handleMove(int blockId, Direction dir, int distance) {
    if (_isPaused || _board.isWon || _isVictoryAnimating || _isPlayingSolution) return;

    if (!_stopwatch.isRunning) _stopwatch.start();

    _board.moveBlock(blockId, dir, distance);
    _clearHint();

    // Advance tutorial on first move
    if (_board.moves == 1 && _tutorialStep == 0 && _currentLevel == 0) {
      _advanceTutorial();
    }

    _movesNotifier.value = _board.moves;
    setState(() {});

    if (_board.isWon) {
      _onVictory();
    }
  }

  void _undo() {
    if (_isPaused || !_board.canUndo || _isVictoryAnimating || _isPlayingSolution) return;
    _board.undo();
    _clearHint();

    _movesNotifier.value = _board.moves;
    setState(() {});
  }

  void _confirmReset() {
    if (_isVictoryAnimating || _isPlayingSolution) return;
    // Skip confirmation if no moves made
    if (_board.moves == 0) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('重置关卡', style: TextStyle(color: Colors.white)),
        content: const Text('确定要重置吗？当前进度将丢失。',
            style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resetLevel();
            },
            child: const Text('重置',
                style: TextStyle(color: Color(0xFFE84545))),
          ),
        ],
      ),
    );
  }

  void _resetLevel() {
    _board.reset();
    _movesNotifier.value = 0;
    _clearHint();
    _hintSolution = null;
    _hintsRemaining = _hintsForDifficulty(_level.difficulty);
    _watchedSolution = false;
    _stopwatch.reset();
    setState(() {});
  }

  void _clearHint() {
    _hintedBlockId = null;
    _hintDirection = null;
    _hintSolution = null;
  }

  // ──────────────────── Hint system ────────────────────

  void _useHint() {
    if (_isPaused || _board.isWon || _isVictoryAnimating || _isPlayingSolution) return;
    if (_hintsRemaining <= 0) return;

    // Solve or use cache
    _hintSolution ??= KlotskiSolver.solve(_board.blocks);
    if (_hintSolution == null || _hintSolution!.isEmpty) return;

    final nextMove = _hintSolution!.first;
    final block = _board.blocks.where(
      (b) => b.type == nextMove.blockType &&
          b.row == nextMove.fromRow &&
          b.col == nextMove.fromCol,
    ).firstOrNull;

    if (block != null) {
      _hintsRemaining--;
      setState(() {
        _hintedBlockId = block.id;
        _hintDirection = nextMove.direction;
      });
    }
  }

  // ──────────────────── Watch solution ────────────────────

  void _watchSolution() async {
    if (_isPlayingSolution || _isVictoryAnimating) return;

    // Reset to start
    _board.reset();
    _movesNotifier.value = 0;
    _stopwatch.reset();
    _watchedSolution = true;
    _isPlayingSolution = true;
    _clearHint();
    setState(() {});

    final solution = KlotskiSolver.solve(_board.blocks);
    if (solution == null || solution.isEmpty) {
      _isPlayingSolution = false;
      setState(() {});
      return;
    }

    for (final move in solution) {
      if (!mounted || !_isPlayingSolution) break;
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted || !_isPlayingSolution) break;

      final block = _board.blocks.where(
        (b) => b.type == move.blockType &&
            b.row == move.fromRow &&
            b.col == move.fromCol,
      ).firstOrNull;

      if (block == null) break;

      // Brief highlight before move
      setState(() {
        _hintedBlockId = block.id;
        _hintDirection = move.direction;
      });
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted || !_isPlayingSolution) break;

      _board.moveBlock(block.id, move.direction, move.distance);
      _movesNotifier.value = _board.moves;
      setState(() {
        _hintedBlockId = null;
        _hintDirection = null;
      });

      if (_board.isWon) {
        _isPlayingSolution = false;
        _onVictory();
        return;
      }
    }

    _isPlayingSolution = false;
    setState(() {});
  }

  void _stopSolutionPlayback() {
    _isPlayingSolution = false;
    _clearHint();
    setState(() {});
  }

  // ──────────────────── Victory ────────────────────

  void _onVictory() async {
    _stopwatch.stop();
    _isVictoryAnimating = true;
    HapticFeedback.mediumImpact();

    // Generate confetti particles
    final rng = Random();
    _confettiParticles = List.generate(30, (_) => _ConfettiParticle(rng));

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    void onComplete(AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        _victoryController.removeStatusListener(onComplete);
        _saveAndShowResult();
      }
    }
    _victoryController.addStatusListener(onComplete);
    _victoryController.forward();
    _confettiController.forward();
  }

  Future<void> _saveAndShowResult() async {
    final moves = _board.moves;
    final level = _level;

    // If watched solution, cap at 1 star by not saving (or save with high move count)
    if (!_watchedSolution) {
      await ScoreService().saveHighScore(
        'klotski', 'level_$_currentLevel', moves,
        lowerIsBetter: true,
      );
    }
    final best = _watchedSolution
        ? moves
        : await ScoreService().getHighScore('klotski', 'level_$_currentLevel');

    if (!mounted) return;

    final hasNext = _currentLevel + 1 < klotskiLevels.length;
    final stars = _watchedSolution ? 1 : calcStars(moves, level.minMoves, level.difficulty);
    final starStr = List.filled(stars, '\u2b50').join();

    final stats = <String, String>{
      '关卡': level.name,
      '步数': '$moves',
      if (level.minMoves > 0) '最优': '${level.minMoves}',
      '最佳': '$best',
      '用时': _formatTime(_stopwatch.elapsed),
      '评级': starStr,
    };

    if (_watchedSolution) {
      stats['提示'] = '已观看解法';
    }

    // Check if a new difficulty was just unlocked
    final unlockMsg = await _checkUnlock();

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameOverPage(
          data: GameOverData(
            gameName: 'klotski',
            mode: 'level_$_currentLevel',
            title: unlockMsg != null ? '恭喜通关\n$unlockMsg' : '恭喜通关',
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
                onPressed: () => Navigator.popUntil(
                    context, ModalRoute.withName('/klotski')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Check if completing this level just unlocked a new difficulty tier.
  Future<String?> _checkUnlock() async {
    final service = ScoreService();
    int totalStars = 0;
    final clearedCount = <KlotskiDifficulty, int>{};

    for (int i = 0; i < klotskiLevels.length; i++) {
      if (await service.hasScore('klotski', 'level_$i')) {
        final best = await service.getHighScore('klotski', 'level_$i');
        final lvl = klotskiLevels[i];
        totalStars += calcStars(best, lvl.minMoves, lvl.difficulty);
        clearedCount[lvl.difficulty] = (clearedCount[lvl.difficulty] ?? 0) + 1;
      }
    }

    // Check advanced unlock
    final advUnlocked = totalStars >= 8 ||
        (clearedCount[KlotskiDifficulty.beginner] ?? 0) >= 6;
    // Check master unlock
    final masUnlocked = totalStars >= 30 ||
        (clearedCount[KlotskiDifficulty.advanced] ?? 0) >= 10;

    // Only notify if the current level's difficulty is the prerequisite tier
    if (_level.difficulty == KlotskiDifficulty.beginner && advUnlocked) {
      // Check if this is the first time (was it already unlocked before this win?)
      // Simple heuristic: if cleared count just hit the threshold
      final begCleared = clearedCount[KlotskiDifficulty.beginner] ?? 0;
      if (begCleared == 6 || totalStars == 8) {
        return '进阶难度已解锁!';
      }
    }
    if (_level.difficulty == KlotskiDifficulty.advanced && masUnlocked) {
      final advCleared = clearedCount[KlotskiDifficulty.advanced] ?? 0;
      if (advCleared == 10 || totalStars == 30) {
        return '大师难度已解锁!';
      }
    }
    return null;
  }

  String _formatTime(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m}m ${s}s';
  }

  // ──────────────────── Level navigation (deduped) ────────────────────

  void _initLevel(int levelIndex) {
    setState(() {
      _currentLevel = levelIndex;
      _gameKey = UniqueKey();
      _board = KlotskiBoard(_level.blocks);
      _movesNotifier.value = 0;
      _isVictoryAnimating = false;
      _isPlayingSolution = false;
      _victoryController.reset();
      _confettiController.reset();
      _confettiParticles = null;
      _clearHint();
      _hintSolution = null;
      _hintsRemaining = _hintsForDifficulty(_level.difficulty);
      _watchedSolution = false;
      _stopwatch.reset();
      _selectedBlockId = null;
      _tutorialStep = null;
    });
    _loadBest();
    _initTutorial();
  }

  void _replayCurrent() => _initLevel(_currentLevel);
  void _goNextLevel() => _initLevel(_currentLevel + 1);

  // ──────────────────── Keyboard ────────────────────

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (_isPaused || _isVictoryAnimating || _isPlayingSolution) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.keyZ) {
      _undo();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyR) {
      _confirmReset();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.tab) {
      _cycleSelectedBlock();
      return KeyEventResult.handled;
    }

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
    _exitPulseController.dispose();
    _confettiController.dispose();
    _focusNode.dispose();
    _movesNotifier.dispose();
    super.dispose();
  }

  // ──────────────────── Build ────────────────────

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
        scoreFormatter: (v) => '$v',
        scoreColorBuilder: _moveCounterColor,
        onPause: _onPause,
        onResume: _onResume,
        canPause: () => !_board.isWon && !_isVictoryAnimating,
        child: Stack(
          children: [
            Column(
              children: [
                // Operation bar
                _buildOperationBar(),

                // Board
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
                          height: boardHeight + 20,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Background with pulsing exit
                              AnimatedBuilder(
                                animation: _exitPulseController,
                                builder: (context, _) => CustomPaint(
                                  size: Size(boardWidth, boardHeight + 20),
                                  painter: _BoardPainter(
                                    cellSize: cellSize,
                                    exitPulse: _exitPulseController.value,
                                  ),
                                ),
                              ),

                              // Blocks
                              ..._buildBlockWidgets(cellSize),

                              // Confetti overlay
                              if (_isVictoryAnimating &&
                                  _confettiParticles != null)
                                AnimatedBuilder(
                                  animation: _confettiController,
                                  builder: (context, _) => CustomPaint(
                                    size: Size(boardWidth, boardHeight + 20),
                                    painter: _ConfettiPainter(
                                      particles: _confettiParticles!,
                                      progress: _confettiController.value,
                                      exitX: exitCol * cellSize + cellSize,
                                      exitY: boardHeight,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            // Tutorial overlay
            if (_tutorialStep != null) _buildTutorialOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialOverlay() {
    final (message, icon) = _tutorialContent();
    return Positioned.fill(
      child: GestureDetector(
        onTap: _advanceTutorial,
        child: Container(
          color: Colors.black54,
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF4ECCA3).withValues(alpha: 0.5)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: const Color(0xFF4ECCA3), size: 36),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '点击继续',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  (String, IconData) _tutorialContent() {
    return switch ((_currentLevel, _tutorialStep)) {
      (0, 0) => ('拖动方块来移动\n将曹操移至底部出口', Icons.swipe),
      (0, _) => ('让曹操到达底部出口\n即可通关', Icons.exit_to_app),
      (1, _) => ('移开挡路的方块\n为曹操开辟道路', Icons.open_with),
      (2, _) => ('卡住了？试试「提示」功能\n走错了？用「撤销」重来', Icons.lightbulb_outline),
      _ => ('', Icons.info),
    };
  }

  Widget _buildOperationBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Undo
          IconButton(
            icon: Icon(
              Icons.undo,
              color: _board.canUndo && !_isPlayingSolution
                  ? const Color(0xFF4ECCA3)
                  : Colors.grey,
            ),
            onPressed: _board.canUndo && !_isPlayingSolution ? _undo : null,
            tooltip: '撤销 (Z)',
          ),
          const SizedBox(width: 8),

          // Hint or Watch Solution
          if (_isPlayingSolution)
            TextButton.icon(
              icon: const Icon(Icons.stop, size: 18),
              label: const Text('停止'),
              onPressed: _stopSolutionPlayback,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFE84545),
              ),
            )
          else if (_hintsRemaining > 0)
            TextButton.icon(
              icon: const Icon(Icons.lightbulb_outline, size: 18),
              label: Text('提示 \u00d7$_hintsRemaining'),
              onPressed: _useHint,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFF0C040),
              ),
            )
          else
            TextButton.icon(
              icon: const Icon(Icons.play_circle_outline, size: 18),
              label: const Text('观看解法'),
              onPressed: _watchSolution,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFF0C040).withValues(alpha: 0.7),
              ),
            ),

          const SizedBox(width: 8),

          // Reset
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: _isPlayingSolution
                  ? Colors.grey
                  : const Color(0xFFF0C040),
            ),
            onPressed: _isPlayingSolution ? null : _confirmReset,
            tooltip: '重置 (R)',
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBlockWidgets(double cellSize) {
    return _board.blocks.map((block) {
      final isCao = block.type == BlockType.cao;

      // Victory animation
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
                child: _staticBlock(block, cellSize),
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

      // Normal gameplay
      return KlotskiBlockWidget(
        key: ValueKey(block.id),
        block: block,
        cellSize: cellSize,
        maxDistance: (dir) => _board.maxDistance(block.id, dir),
        onMoved: (dir, dist) => _handleMove(block.id, dir, dist),
        enabled: !_isPaused && !_board.isWon && !_isPlayingSolution,
        isSelected: _selectedBlockId == block.id,
        isHinted: _hintedBlockId == block.id,
        hintDirection: _hintedBlockId == block.id ? _hintDirection : null,
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

// ──────────────────── Board background painter ────────────────────

class _BoardPainter extends CustomPainter {
  final double cellSize;
  final double exitPulse;

  _BoardPainter({required this.cellSize, required this.exitPulse});

  @override
  void paint(Canvas canvas, Size size) {
    final boardWidth = boardCols * cellSize;
    final boardHeight = boardRows * cellSize;

    // Board background
    final bgPaint = Paint()..color = KlotskiColors.boardBg;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, boardWidth, boardHeight),
        const Radius.circular(6),
      ),
      bgPaint,
    );

    // Cells
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

    // Exit marker with pulse glow
    final pulseAlpha = 0.3 + 0.3 * exitPulse;
    final exitPaint = Paint()
      ..color = KlotskiColors.exitGlow.withValues(alpha: pulseAlpha)
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

    // Glow effect
    final glowAlpha = 0.1 + 0.15 * exitPulse;
    final glowPaint = Paint()
      ..color = KlotskiColors.exitGlow.withValues(alpha: glowAlpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        exitRect.inflate(4),
        const Radius.circular(6),
      ),
      glowPaint,
    );

    // EXIT text
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'EXIT',
        style: TextStyle(
          color: KlotskiColors.exitGlow.withValues(alpha: 0.5 + 0.3 * exitPulse),
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
      cellSize != oldDelegate.cellSize || exitPulse != oldDelegate.exitPulse;
}

// ──────────────────── Confetti ────────────────────

class _ConfettiParticle {
  final double angle; // radians from center
  final double speed; // multiplier
  final double size;
  final Color color;
  final double rotationSpeed;

  _ConfettiParticle(Random rng)
      : angle = rng.nextDouble() * 2 * pi - pi,
        speed = 0.5 + rng.nextDouble() * 1.5,
        size = 3 + rng.nextDouble() * 5,
        color = [
          const Color(0xFFF0C040),
          const Color(0xFF4ECCA3),
          const Color(0xFF3A86FF),
          const Color(0xFFE84545),
          const Color(0xFFFF6B6B),
          Colors.white,
        ][rng.nextInt(6)],
        rotationSpeed = rng.nextDouble() * 4 - 2;
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;
  final double exitX;
  final double exitY;

  _ConfettiPainter({
    required this.particles,
    required this.progress,
    required this.exitX,
    required this.exitY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;

    for (final p in particles) {
      final dist = progress * p.speed * 120;
      final x = exitX + cos(p.angle) * dist;
      final y = exitY - sin(p.angle.abs()) * dist * 0.8 + progress * progress * 60;
      final alpha = (1.0 - progress).clamp(0.0, 1.0);

      final paint = Paint()..color = p.color.withValues(alpha: alpha);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotationSpeed * progress * pi);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      progress != oldDelegate.progress;
}
