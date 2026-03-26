import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../shared/game_scaffold.dart';
import '../shared/score_service.dart';
import 'game_of_life_colors.dart';
import 'game_of_life_config.dart';
import 'game_of_life_game.dart';
import 'game_of_life_painter.dart';
import 'game_of_life_patterns.dart';
import 'game_of_life_widgets.dart';

class GameOfLifePage extends StatefulWidget {
  final GameOfLifePattern? initialPattern;

  const GameOfLifePage({super.key, this.initialPattern});

  @override
  State<GameOfLifePage> createState() => _GameOfLifePageState();
}

class _GameOfLifePageState extends State<GameOfLifePage>
    with SingleTickerProviderStateMixin {
  late GameOfLifeGame _game;
  late Ticker _ticker;
  final _transformController = TransformationController();
  final _generationNotifier = ValueNotifier<int>(0);

  bool _isRunning = false;
  InteractionMode _interactionMode = InteractionMode.draw;
  int _speedIndex = 1;
  int _paintVersion = 0;
  Duration _lastElapsed = Duration.zero;
  double _accumulator = 0;

  // Drag state for continuous drawing
  bool? _dragIsDrawing;

  // Pattern placement state
  GameOfLifePattern? _placingPattern;
  int _patternRotation = 0;
  (int, int)? _patternPosition;

  // Pattern library sheet
  bool _showPatternLibrary = false;

  // Onboarding
  int _onboardingStep = -1; // -1 = not showing

  // Best generation for ScoreService
  int _bestGeneration = 0;

  // Pattern recognition: track already-notified patterns to avoid spam
  final Set<int> _notifiedPatternIndices = {};

  @override
  void initState() {
    super.initState();
    _game = GameOfLifeGame();
    _ticker = createTicker(_onTick);
    _ticker.start();
    _loadBestScore();
    _checkOnboarding();

    if (widget.initialPattern != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _startPatternPlacement(widget.initialPattern!);
      });
    }
  }

  Future<void> _loadBestScore() async {
    _bestGeneration = await ScoreService()
        .getHighScore(GameOfLifeConfig.gameName, 'sandbox');
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool('gameoflife_onboarding_shown') ?? false;
    if (!shown && mounted) {
      setState(() => _onboardingStep = 0);
    }
  }

  Future<void> _dismissOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('gameoflife_onboarding_shown', true);
    if (mounted) setState(() => _onboardingStep = -1);
  }

  @override
  void dispose() {
    _saveBestScore();
    _ticker.dispose();
    _transformController.dispose();
    _generationNotifier.dispose();
    super.dispose();
  }

  Future<void> _saveBestScore() async {
    if (_game.generation > 0) {
      await ScoreService().saveHighScore(
        GameOfLifeConfig.gameName,
        'sandbox',
        _game.generation,
      );
    }
  }

  // --- Ticker ---

  void _onTick(Duration elapsed) {
    if (!_isRunning) {
      _lastElapsed = elapsed;
      return;
    }

    final dt = (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    _accumulator += dt;

    final stepInterval =
        1.0 / GameOfLifeConfig.speedLevels[_speedIndex];
    final maxSteps = GameOfLifeConfig.maxStepsPerFrame;
    int steps = 0;

    while (_accumulator >= stepInterval && steps < maxSteps) {
      _game.evolve();
      _accumulator -= stepInterval;
      steps++;

      if (_game.aliveRatio >= GameOfLifeConfig.pauseThreshold) {
        _isRunning = false;
        _showAutoPauseSnackbar();
        break;
      }
    }

    if (steps > 0) {
      _generationNotifier.value = _game.generation;
      _incrementPaint();
      _checkPatternRecognition();
    }
  }

  void _showAutoPauseSnackbar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('活细胞过多，已自动暂停'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _checkPatternRecognition() {
    if (_game.isEmpty || _game.aliveCellCount > 100) return;
    // Only check when pattern might be stable (still life or oscillator)
    final period = _game.detectPeriod();
    if (period == 0) return;

    final idx = _game.matchKnownPattern(GameOfLifePatterns.allNormalizedHashes);
    if (idx != null && !_notifiedPatternIndices.contains(idx)) {
      _notifiedPatternIndices.add(idx);
      final pattern = GameOfLifePatterns.all[idx];
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('检测到图案: ${pattern.name} ${pattern.nameEn}'),
          action: SnackBarAction(
            label: '查看图鉴',
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/gameoflife/encyclopedia',
                arguments: pattern.id,
              );
            },
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // --- Controls ---

  void _togglePlay() {
    setState(() {
      _isRunning = !_isRunning;
      if (_isRunning) {
        _accumulator = 0;
      }
    });
  }

  void _step() {
    _game.evolve();
    _generationNotifier.value = _game.generation;
    _incrementPaint();
  }

  void _changeSpeed() {
    setState(() {
      _speedIndex = (_speedIndex + 1) % GameOfLifeConfig.speedLevels.length;
    });
  }

  void _confirmClear() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空画布'),
        content: const Text('确定要清空所有细胞吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _isRunning = false;
                _game.clear();
                _generationNotifier.value = 0;
                _incrementPaint();
              });
            },
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }

  void _toggleDrawMode() {
    setState(() {
      if (_interactionMode == InteractionMode.draw) {
        _interactionMode = InteractionMode.pan;
      } else {
        _interactionMode = InteractionMode.draw;
      }
    });
  }

  void _togglePatternLibrary() {
    setState(() => _showPatternLibrary = !_showPatternLibrary);
  }

  // --- Pattern placement ---

  void _startPatternPlacement(GameOfLifePattern pattern) {
    setState(() {
      _placingPattern = pattern;
      _patternRotation = 0;
      _patternPosition = null;
      _interactionMode = InteractionMode.placingPattern;
      _showPatternLibrary = false;
    });
  }

  void _rotatePattern() {
    setState(() {
      _patternRotation = (_patternRotation + 1) % 4;
      _updatePreview();
    });
  }

  void _confirmPatternPlacement() {
    if (_placingPattern == null || _patternPosition == null) return;
    final cells = _getRotatedCells(_placingPattern!, _patternRotation);
    final (ox, oy) = _patternPosition!;
    for (final (cx, cy) in cells) {
      _game.setCell(ox + cx, oy + cy, 1);
    }
    setState(() {
      _placingPattern = null;
      _patternPosition = null;
      _interactionMode = InteractionMode.draw;
      _incrementPaint();
    });
  }

  void _cancelPatternPlacement() {
    setState(() {
      _placingPattern = null;
      _patternPosition = null;
      _interactionMode = InteractionMode.draw;
      _incrementPaint();
    });
  }

  List<(int, int)> _getRotatedCells(GameOfLifePattern pattern, int rotation) {
    var cells = pattern.cells.toList();
    for (int r = 0; r < rotation; r++) {
      cells = cells.map(((int, int) c) => (c.$2, -c.$1)).toList();
    }
    // Normalize to positive coordinates
    if (cells.isEmpty) return cells;
    final minX = cells.map((c) => c.$1).reduce(min);
    final minY = cells.map((c) => c.$2).reduce(min);
    return cells.map((c) => (c.$1 - minX, c.$2 - minY)).toList();
  }

  Set<(int, int)> _getPreviewCells() {
    if (_placingPattern == null || _patternPosition == null) return {};
    final cells = _getRotatedCells(_placingPattern!, _patternRotation);
    final (ox, oy) = _patternPosition!;
    return cells.map((c) => (ox + c.$1, oy + c.$2)).toSet();
  }

  void _updatePreview() {
    if (_patternPosition != null) {
      _incrementPaint();
    }
  }

  // --- Pointer handling (Listener-based, no gesture arena conflict) ---

  void _onPointerDown(PointerDownEvent event, double cellSize) {
    if (_interactionMode == InteractionMode.placingPattern) {
      final (gx, gy) = _screenToGrid(event.localPosition, cellSize);
      setState(() {
        _patternPosition = (gx, gy);
        _incrementPaint();
      });
      return;
    }

    if (_interactionMode != InteractionMode.draw) return;

    final (gx, gy) = _screenToGrid(event.localPosition, cellSize);
    if (gx < 0 || gx >= GameOfLifeGame.gridWidth ||
        gy < 0 || gy >= GameOfLifeGame.gridHeight) {
      return;
    }

    final isAlive = _game.cellAt(gx, gy) == 1;
    _dragIsDrawing = !isAlive;
    _game.toggleCell(gx, gy);
    _incrementPaint();
  }

  void _onPointerMove(PointerMoveEvent event, double cellSize) {
    if (_interactionMode == InteractionMode.placingPattern) {
      final (gx, gy) = _screenToGrid(event.localPosition, cellSize);
      setState(() {
        _patternPosition = (gx, gy);
        _incrementPaint();
      });
      return;
    }

    if (_interactionMode != InteractionMode.draw || _dragIsDrawing == null) {
      return;
    }

    final (gx, gy) = _screenToGrid(event.localPosition, cellSize);
    if (gx < 0 || gx >= GameOfLifeGame.gridWidth ||
        gy < 0 || gy >= GameOfLifeGame.gridHeight) {
      return;
    }

    final isAlive = _game.cellAt(gx, gy) == 1;
    if (_dragIsDrawing! && !isAlive) {
      _game.toggleCell(gx, gy);
      _incrementPaint();
    } else if (!_dragIsDrawing! && isAlive) {
      _game.toggleCell(gx, gy);
      _incrementPaint();
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _dragIsDrawing = null;
  }

  (int, int) _screenToGrid(Offset localPosition, double cellSize) {
    final gx = (localPosition.dx / cellSize).floor();
    final gy = (localPosition.dy / cellSize).floor();
    return (gx, gy);
  }

  void _incrementPaint() {
    setState(() => _paintVersion++);
  }

  // --- Pause / Resume ---

  void _onPause() {
    _isRunning = false;
    _ticker.stop();
    _saveBestScore();
  }

  void _onResume() {
    _ticker.start();
    _lastElapsed = Duration.zero;
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Game of Life',
      scoreNotifier: _generationNotifier,
      bestScore: _bestGeneration,
      scoreLabel: 'Gen',
      bestLabel: 'Cells',
      bestFormatter: (_) => '${_game.aliveCellCount}',
      onPause: _onPause,
      onResume: _onResume,
      child: Stack(
        children: [
          Column(
            children: [
              GameOfLifeInfoBar(
                generation: _game.generation,
                aliveCells: _game.aliveCellCount,
                isRunning: _isRunning,
                speedIndex: _speedIndex,
              ),
              Expanded(
                child: Container(
                  color: GameOfLifeColors.background,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final cellSize = min(
                        constraints.maxWidth / GameOfLifeConfig.gridWidth,
                        constraints.maxHeight / GameOfLifeConfig.gridHeight,
                      );
                      final canvasW =
                          cellSize * GameOfLifeConfig.gridWidth;
                      final canvasH =
                          cellSize * GameOfLifeConfig.gridHeight;

                      return InteractiveViewer(
                        transformationController: _transformController,
                        constrained: false,
                        panEnabled:
                            _interactionMode != InteractionMode.draw,
                        scaleEnabled: true,
                        minScale: GameOfLifeConfig.minScale,
                        maxScale: GameOfLifeConfig.maxScale,
                        boundaryMargin: EdgeInsets.all(
                          max(constraints.maxWidth, constraints.maxHeight) *
                              0.5,
                        ),
                        child: Listener(
                          onPointerDown: (e) =>
                              _onPointerDown(e, cellSize),
                          onPointerMove: (e) =>
                              _onPointerMove(e, cellSize),
                          onPointerUp: _onPointerUp,
                          child: SizedBox(
                            width: canvasW,
                            height: canvasH,
                            child: CustomPaint(
                              painter: GameOfLifePainter(
                                game: _game,
                                cellSize: cellSize,
                                paintVersion: _paintVersion,
                                previewCells: _getPreviewCells(),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (_placingPattern != null)
                PatternPlacementBar(
                  onRotate: _rotatePattern,
                  onConfirm: _confirmPatternPlacement,
                  onCancel: _cancelPatternPlacement,
                  rotation: _patternRotation,
                )
              else
                GameOfLifeControlBar(
                  isRunning: _isRunning,
                  speedIndex: _speedIndex,
                  interactionMode: _interactionMode,
                  onTogglePlay: _togglePlay,
                  onStep: _step,
                  onSpeedChange: _changeSpeed,
                  onClear: _confirmClear,
                  onPatternLibrary: _togglePatternLibrary,
                  onToggleDrawMode: _toggleDrawMode,
                ),
            ],
          ),
          // Pattern library sheet
          if (_showPatternLibrary)
            PatternLibrarySheet(onSelect: _startPatternPlacement),
          // Onboarding overlay
          if (_onboardingStep >= 0) _buildOnboarding(),
        ],
      ),
    );
  }

  // --- Onboarding ---

  static const _onboardingTexts = [
    '点击格子创建或删除生命细胞',
    '按播放按钮，观察细胞按规则演化',
    '从图案库选择经典图案放到画布上',
    '切换移动模式来平移和缩放画布',
  ];

  Widget _buildOnboarding() {
    return GestureDetector(
      onTap: () {
        if (_onboardingStep < _onboardingTexts.length - 1) {
          setState(() => _onboardingStep++);
        } else {
          _dismissOnboarding();
        }
      },
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: GameOfLifeColors.cellAlive, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline,
                    color: GameOfLifeColors.cellAlive, size: 48),
                const SizedBox(height: 16),
                Text(
                  _onboardingTexts[_onboardingStep],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: _dismissOnboarding,
                      child: const Text('跳过',
                          style: TextStyle(color: Colors.white54)),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (_onboardingStep <
                            _onboardingTexts.length - 1) {
                          setState(() => _onboardingStep++);
                        } else {
                          _dismissOnboarding();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GameOfLifeColors.cellAlive,
                      ),
                      child: Text(
                        _onboardingStep < _onboardingTexts.length - 1
                            ? '下一步 (${_onboardingStep + 1}/${_onboardingTexts.length})'
                            : '知道了',
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
