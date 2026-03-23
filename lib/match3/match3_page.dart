// lib/match3/match3_page.dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../shared/game_over_data.dart';
import '../shared/game_over_page.dart';
import '../shared/game_scaffold.dart';
import '../shared/score_service.dart';
import 'match3_board.dart';
import 'match3_colors.dart';
import 'match3_gem.dart';

class Match3Page extends StatefulWidget {
  final Match3GameMode mode;

  const Match3Page({super.key, required this.mode});

  @override
  State<Match3Page> createState() => _Match3PageState();
}

class _Match3PageState extends State<Match3Page> with TickerProviderStateMixin {
  Key _gameKey = UniqueKey();
  late Match3Board _board;
  final ValueNotifier<int> _scoreNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> _boardTick = ValueNotifier<int>(0);
  int _bestScore = 0;
  int _movesLeft = 30;
  int _timeLeft = 60;
  Timer? _timer;
  bool _isPaused = false;
  bool _isAnimating = false;
  bool _gameOver = false;

  // Selection state
  (int, int)? _selectedCell;

  // Animation state
  final Map<int, _GemAnimation> _gemAnimations = {};
  final Set<int> _removingGemIds = {};

  AnimationController? _swapController;
  AnimationController? _fallController;
  AnimationController? _removeController;

  String get _modeKey => widget.mode.name;

  String get _modeTitle {
    switch (widget.mode) {
      case Match3GameMode.classic:
        return 'Classic';
      case Match3GameMode.timed:
        return 'Timed';
      case Match3GameMode.moves:
        return 'Moves';
    }
  }

  @override
  void initState() {
    super.initState();
    _createGame();
    _loadBestScore();
  }

  void _createGame() {
    _board = Match3Board();
    _scoreNotifier.value = 0;
    _movesLeft = 30;
    _timeLeft = 60;
    _isPaused = false;
    _isAnimating = false;
    _gameOver = false;
    _selectedCell = null;
    _gemAnimations.clear();
    _removingGemIds.clear();
    _timer?.cancel();
    _timer = null;

    if (widget.mode == Match3GameMode.timed) {
      _startTimer();
    }
  }

  Future<void> _loadBestScore() async {
    _bestScore = await ScoreService().getHighScore('match3', _modeKey);
    if (mounted) setState(() {});
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isPaused || _gameOver) return;
      setState(() {
        _timeLeft--;
        if (_timeLeft <= 0) {
          _timeLeft = 0;
          _endGame();
        }
      });
    });
  }

  void _onCellTap(int row, int col) {
    if (_isAnimating || _gameOver || _isPaused) return;
    if (_board.grid[row][col] == null) return;

    if (_selectedCell == null) {
      setState(() => _selectedCell = (row, col));
      return;
    }

    final (sr, sc) = _selectedCell!;
    if (sr == row && sc == col) {
      // Deselect
      setState(() => _selectedCell = null);
      return;
    }

    if (_board.isAdjacentSwap(sr, sc, row, col)) {
      _trySwap(sr, sc, row, col);
    } else {
      // Select new cell
      setState(() => _selectedCell = (row, col));
    }
  }

  Future<void> _trySwap(int r1, int c1, int r2, int c2) async {
    setState(() {
      _selectedCell = null;
      _isAnimating = true;
    });

    // Animate swap
    await _animateSwap(r1, c1, r2, c2);
    _board.swap(r1, c1, r2, c2);

    final matches = _board.findMatches();
    if (matches.isEmpty) {
      // Invalid swap — swap back
      await _animateSwap(r1, c1, r2, c2);
      _board.swap(r1, c1, r2, c2);
      setState(() => _isAnimating = false);
      return;
    }

    // Valid swap — consume a move in Moves mode
    if (widget.mode == Match3GameMode.moves) {
      _movesLeft--;
    }

    // Process cascade
    await _processCascade(matches);

    // Check game over conditions
    if (_gameOver) return;

    if (widget.mode == Match3GameMode.moves && _movesLeft <= 0) {
      _endGame();
      return;
    }

    if (!_board.hasValidMoves()) {
      if (widget.mode == Match3GameMode.classic) {
        _endGame();
      } else {
        // Shuffle for timed/moves modes
        setState(() => _board.shuffle());
      }
    }

    setState(() => _isAnimating = false);
  }

  Future<void> _processCascade(Set<(int, int)> initialMatches) async {
    var matches = initialMatches;
    int cascadeLevel = 1;

    while (matches.isNotEmpty) {
      // Score
      final points = Match3Board.calculateScore(matches.length, cascadeLevel);
      _scoreNotifier.value += points;

      // Animate removal
      await _animateRemoval(matches);
      _board.removeMatches(matches);

      // Animate gravity
      final gravityMoves = _board.applyGravity();
      final newGems = _board.fillEmpty();
      await _animateFall(gravityMoves, newGems);

      // Check for new matches
      matches = _board.findMatches();
      cascadeLevel++;
    }
  }

  Future<void> _animateSwap(int r1, int c1, int r2, int c2) async {
    final gem1 = _board.grid[r1][c1];
    final gem2 = _board.grid[r2][c2];
    if (gem1 == null || gem2 == null) return;

    _swapController?.dispose();
    _swapController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    final dr = (r2 - r1).toDouble();
    final dc = (c2 - c1).toDouble();

    _gemAnimations[gem1.id] = _GemAnimation(
      fromRow: r1.toDouble(),
      fromCol: c1.toDouble(),
      toRow: r1 + dr,
      toCol: c1 + dc,
      controller: _swapController!,
    );
    _gemAnimations[gem2.id] = _GemAnimation(
      fromRow: r2.toDouble(),
      fromCol: c2.toDouble(),
      toRow: r2 - dr,
      toCol: c2 - dc,
      controller: _swapController!,
    );

    _swapController!.addListener(() => _boardTick.value++);
    await _swapController!.forward();

    _gemAnimations.remove(gem1.id);
    _gemAnimations.remove(gem2.id);
  }

  Future<void> _animateRemoval(Set<(int, int)> matches) async {
    _removeController?.dispose();
    _removeController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    for (final (r, c) in matches) {
      final gem = _board.grid[r][c];
      if (gem != null) {
        _removingGemIds.add(gem.id);
      }
    }

    _removeController!.addListener(() => _boardTick.value++);
    await _removeController!.forward();

    _removingGemIds.clear();
  }

  Future<void> _animateFall(
    List<(int, int, int, int)> gravityMoves,
    List<(int, int, Gem)> newGems,
  ) async {
    _fallController?.dispose();
    _fallController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Existing gems falling
    for (final (fromR, fromC, toR, toC) in gravityMoves) {
      final gem = _board.grid[toR][toC];
      if (gem != null) {
        _gemAnimations[gem.id] = _GemAnimation(
          fromRow: fromR.toDouble(),
          fromCol: fromC.toDouble(),
          toRow: toR.toDouble(),
          toCol: toC.toDouble(),
          controller: _fallController!,
        );
      }
    }

    // New gems falling from above
    for (final (r, c, gem) in newGems) {
      _gemAnimations[gem.id] = _GemAnimation(
        fromRow: r.toDouble() - (rows - r).toDouble(),
        fromCol: c.toDouble(),
        toRow: r.toDouble(),
        toCol: c.toDouble(),
        controller: _fallController!,
      );
    }

    _fallController!.addListener(() => _boardTick.value++);
    await _fallController!.forward();

    _gemAnimations.clear();
  }

  int get rows => Match3Board.rows;
  int get cols => Match3Board.cols;

  void _endGame() {
    _gameOver = true;
    _timer?.cancel();
    _isAnimating = false;
    _onGameOver();
  }

  Future<void> _onGameOver() async {
    final score = _scoreNotifier.value;
    await ScoreService().saveHighScore('match3', _modeKey, score);
    final best = await ScoreService().getHighScore('match3', _modeKey);

    if (!mounted) return;

    final stats = <String, String>{
      'Score': '$score',
      'Best': '$best',
    };

    if (widget.mode == Match3GameMode.timed) {
      stats['Time'] = '60s';
    } else if (widget.mode == Match3GameMode.moves) {
      stats['Moves'] = '30';
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameOverPage(
          data: GameOverData(
            gameName: 'match3',
            mode: _modeKey,
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

  void _onPause() {
    if (_gameOver) return;
    _isPaused = true;
  }

  void _onResume() {
    _isPaused = false;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scoreNotifier.dispose();
    _boardTick.dispose();
    _swapController?.dispose();
    _fallController?.dispose();
    _removeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      key: _gameKey,
      title: 'Match-3 - $_modeTitle',
      scoreNotifier: _scoreNotifier,
      bestScore: _bestScore,
      onPause: _onPause,
      onResume: _onResume,
      canPause: () => !_gameOver,
      child: Column(
        children: [
          // Mode-specific info bar
          _buildInfoBar(),

          // Board — scoped rebuild via ValueListenableBuilder
          Expanded(
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cellSize = (constraints.maxWidth < constraints.maxHeight
                          ? constraints.maxWidth
                          : constraints.maxHeight) /
                      (cols + 0.5);
                  final boardWidth = cellSize * cols;
                  final boardHeight = cellSize * rows;

                  return Container(
                    width: boardWidth,
                    height: boardHeight,
                    decoration: BoxDecoration(
                      color: Match3Colors.boardBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ValueListenableBuilder<int>(
                      valueListenable: _boardTick,
                      builder: (context, _, __) => Stack(
                        children: [
                          // Cell backgrounds
                          for (int r = 0; r < rows; r++)
                            for (int c = 0; c < cols; c++)
                              Positioned(
                                left: c * cellSize,
                                top: r * cellSize,
                                child: Container(
                                  width: cellSize,
                                  height: cellSize,
                                  decoration: BoxDecoration(
                                    color: Match3Colors.cellBackground,
                                    border: Border.all(
                                      color: Match3Colors.boardBackground,
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),

                          // Gems
                          for (int r = 0; r < rows; r++)
                            for (int c = 0; c < cols; c++)
                              if (_board.grid[r][c] != null)
                                _buildGem(r, c, cellSize),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoBar() {
    switch (widget.mode) {
      case Match3GameMode.classic:
        return const SizedBox(height: 8);
      case Match3GameMode.timed:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer, color: Color(0xFF3A86FF), size: 20),
              const SizedBox(width: 8),
              Text(
                '$_timeLeft s',
                style: TextStyle(
                  color: _timeLeft <= 10
                      ? const Color(0xFFE84545)
                      : const Color(0xFF3A86FF),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      case Match3GameMode.moves:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.swipe, color: Color(0xFFE84545), size: 20),
              const SizedBox(width: 8),
              Text(
                '$_movesLeft moves',
                style: TextStyle(
                  color: _movesLeft <= 5
                      ? const Color(0xFFE84545)
                      : const Color(0xFFF0C040),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildGem(int row, int col, double cellSize) {
    final gem = _board.grid[row][col]!;
    final isSelected =
        _selectedCell != null && _selectedCell!.$1 == row && _selectedCell!.$2 == col;

    double displayRow = row.toDouble();
    double displayCol = col.toDouble();
    double scale = 1.0;
    double opacity = 1.0;

    // Check for animation
    final anim = _gemAnimations[gem.id];
    if (anim != null) {
      final t = anim.controller.value;
      displayRow = anim.fromRow + (anim.toRow - anim.fromRow) * t;
      displayCol = anim.fromCol + (anim.toCol - anim.fromCol) * t;
    }

    // Check for removal animation
    if (_removingGemIds.contains(gem.id) && _removeController != null) {
      final t = _removeController!.value;
      scale = 1.0 - t;
      opacity = 1.0 - t;
    }

    final color = Match3Colors.getColor(gem.type);
    final icon = Match3Colors.getIcon(gem.type);

    return Positioned(
      left: displayCol * cellSize,
      top: displayRow * cellSize,
      child: GestureDetector(
        onTap: () => _onCellTap(row, col),
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: scale.clamp(0.0, 1.0),
            child: Container(
              width: cellSize,
              height: cellSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(cellSize * 0.15),
                border: isSelected
                    ? Border.all(color: Match3Colors.selectedBorder, width: 3)
                    : null,
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: color,
                  size: cellSize * 0.6,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GemAnimation {
  final double fromRow;
  final double fromCol;
  final double toRow;
  final double toCol;
  final AnimationController controller;

  _GemAnimation({
    required this.fromRow,
    required this.fromCol,
    required this.toRow,
    required this.toCol,
    required this.controller,
  });
}
