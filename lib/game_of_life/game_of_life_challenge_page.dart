import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../shared/score_service.dart';
import 'game_of_life_challenges.dart';
import 'game_of_life_challenge_runner.dart';
import 'game_of_life_colors.dart';
import 'game_of_life_config.dart';
import 'game_of_life_game.dart';
import 'game_of_life_painter.dart';

class GameOfLifeChallengePage extends StatefulWidget {
  const GameOfLifeChallengePage({super.key});

  @override
  State<GameOfLifeChallengePage> createState() =>
      _GameOfLifeChallengePageState();
}

class _GameOfLifeChallengePageState extends State<GameOfLifeChallengePage> {
  ChallengeLevel? _currentLevel;
  final Map<int, int> _bestCells = {}; // levelId -> best cell count

  @override
  void initState() {
    super.initState();
    _loadScores();
  }

  Future<void> _loadScores() async {
    final service = ScoreService();
    for (final level in ChallengeLevels.all) {
      final score = await service.getHighScore(
          GameOfLifeConfig.gameName, 'challenge_${level.id}');
      if (score > 0) _bestCells[level.id] = score;
    }
    if (mounted) setState(() {});
  }

  int _starsForLevel(ChallengeLevel level) {
    final best = _bestCells[level.id];
    if (best == null) return 0;
    return level.calcStars(best);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentLevel != null) {
      return _ChallengePlayView(
        level: _currentLevel!,
        onBack: () {
          _loadScores();
          setState(() => _currentLevel = null);
        },
        onViewPattern: (patternId) {
          Navigator.pushNamed(
            context,
            '/gameoflife/encyclopedia',
            arguments: patternId,
          );
        },
      );
    }
    return _buildLevelList();
  }

  Widget _buildLevelList() {
    return Scaffold(
      backgroundColor: GameOfLifeColors.background,
      appBar: AppBar(
        title: const Text('挑战模式'),
        backgroundColor: GameOfLifeColors.background,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: ChallengeLevels.all.length,
        itemBuilder: (context, index) {
          final level = ChallengeLevels.all[index];
          final stars = _starsForLevel(level);
          final best = _bestCells[level.id];

          return Card(
            color: const Color(0xFF16213E),
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: stars > 0
                    ? GameOfLifeColors.cellAlive.withValues(alpha: 0.2)
                    : Colors.white10,
                child: Text(
                  '${level.id}',
                  style: TextStyle(
                    color: stars > 0 ? GameOfLifeColors.cellAlive : Colors.white54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(level.title,
                  style: const TextStyle(color: Colors.white)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(level.description,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      ...List.generate(3, (i) => Icon(
                        Icons.star,
                        size: 16,
                        color: i < stars ? Colors.amber : Colors.white24,
                      )),
                      if (best != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '最少 $best 个细胞',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.white24),
              onTap: () => setState(() => _currentLevel = level),
            ),
          );
        },
      ),
    );
  }
}

class _ChallengePlayView extends StatefulWidget {
  final ChallengeLevel level;
  final VoidCallback onBack;
  final void Function(String) onViewPattern;

  const _ChallengePlayView({
    required this.level,
    required this.onBack,
    required this.onViewPattern,
  });

  @override
  State<_ChallengePlayView> createState() => _ChallengePlayViewState();
}

class _ChallengePlayViewState extends State<_ChallengePlayView>
    with SingleTickerProviderStateMixin {
  late GameOfLifeGame _game;
  late ChallengeRunner _runner;
  late Ticker _ticker;
  final _transformController = TransformationController();

  int _paintVersion = 0;
  Duration _lastElapsed = Duration.zero;
  double _accumulator = 0;
  int _tutorialStep = 0;
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    _game = GameOfLifeGame();
    _runner = ChallengeRunner(level: widget.level, game: _game);
    _ticker = createTicker(_onTick);
    _ticker.start();

    if (widget.level.tutorialSteps != null &&
        widget.level.tutorialSteps!.isNotEmpty) {
      _showTutorial = true;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_runner.state != ChallengeState.running) {
      _lastElapsed = elapsed;
      return;
    }

    final dt = (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    _accumulator += dt;

    if (_accumulator >= 0.1) {
      _runner.tick();
      _accumulator -= 0.1;
      setState(() => _paintVersion++);

      if (_runner.isFinished) {
        _onFinished();
      }
    }
  }

  void _onFinished() {
    _ticker.stop();
    if (_runner.state == ChallengeState.success) {
      _saveScore();
    }
  }

  Future<void> _saveScore() async {
    await ScoreService().saveHighScore(
      GameOfLifeConfig.gameName,
      'challenge_${widget.level.id}',
      _runner.userCellCount,
      lowerIsBetter: true,
    );
    // Update total stars
    int totalStars = 0;
    for (final level in ChallengeLevels.all) {
      final best = await ScoreService()
          .getHighScore(GameOfLifeConfig.gameName, 'challenge_${level.id}');
      if (best > 0) totalStars += level.calcStars(best);
    }
    await ScoreService().saveHighScore(
      GameOfLifeConfig.gameName,
      'challenge_total',
      totalStars,
    );
  }

  void _startRun() {
    _runner.start();
    _accumulator = 0;
    if (!_ticker.isActive) _ticker.start();
    setState(() {});
  }

  void _reset() {
    _runner.reset();
    if (!_ticker.isActive) _ticker.start();
    setState(() => _paintVersion++);
  }

  Future<void> _skipToResult() async {
    await _runner.skipToResult(() {
      if (mounted) setState(() => _paintVersion++);
    });
    if (_runner.isFinished) _onFinished();
    if (mounted) setState(() {});
  }

  void _onPointerDown(PointerDownEvent event, double cellSize) {
    if (_runner.state != ChallengeState.editing) return;
    final gx = (event.localPosition.dx / cellSize).floor();
    final gy = (event.localPosition.dy / cellSize).floor();
    if (_runner.toggleCell(gx, gy)) {
      setState(() => _paintVersion++);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameOfLifeColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: Text(widget.level.title),
        backgroundColor: GameOfLifeColors.background,
        actions: [
          if (widget.level.hintPatternId != null)
            IconButton(
              icon: const Icon(Icons.help_outline),
              tooltip: '查看目标图案',
              onPressed: () =>
                  widget.onViewPattern(widget.level.hintPatternId!),
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Goal description + progress
              _buildGoalBar(),
              // Game canvas
              Expanded(
                child: Container(
                  color: GameOfLifeColors.background,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Focus on a relevant area
                      final regionSize = 30.0;
                      final cellSize = min(
                            constraints.maxWidth,
                            constraints.maxHeight,
                          ) /
                          regionSize;
                      final canvasW = cellSize * GameOfLifeConfig.gridWidth;
                      final canvasH = cellSize * GameOfLifeConfig.gridHeight;

                      return InteractiveViewer(
                        transformationController: _transformController,
                        constrained: false,
                        minScale: 0.3,
                        maxScale: 10.0,
                        boundaryMargin: EdgeInsets.all(
                            max(constraints.maxWidth, constraints.maxHeight)),
                        child: Listener(
                          onPointerDown: (e) => _onPointerDown(e, cellSize),
                          child: SizedBox(
                            width: canvasW,
                            height: canvasH,
                            child: CustomPaint(
                              painter: GameOfLifePainter(
                                game: _game,
                                cellSize: cellSize,
                                paintVersion: _paintVersion,
                                lockedCells: widget.level.lockedCells,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Bottom action bar
              _buildBottomBar(),
            ],
          ),
          // Tutorial overlay
          if (_showTutorial) _buildTutorial(),
          // Success overlay
          if (_runner.state == ChallengeState.success) _buildSuccessOverlay(),
          // Failure overlay
          if (_runner.state == ChallengeState.failed) _buildFailureOverlay(),
        ],
      ),
    );
  }

  Widget _buildGoalBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0xFF16213E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.level.description,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          if (_runner.state == ChallengeState.running) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _game.generation / widget.level.maxGenerations,
              backgroundColor: Colors.white12,
              valueColor:
                  const AlwaysStoppedAnimation(GameOfLifeColors.cellAlive),
            ),
            const SizedBox(height: 4),
            Text(
              '第 ${_game.generation} / ${widget.level.maxGenerations} 代  |  活细胞: ${_game.aliveCellCount}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
          if (_runner.state == ChallengeState.editing)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '已放置: ${_runner.userCellCount} 个细胞',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: GameOfLifeColors.background,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (_runner.state == ChallengeState.editing) ...[
            TextButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh, color: Colors.white70),
              label:
                  const Text('重置', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton.icon(
              onPressed:
                  _runner.userCellCount > 0 ? _startRun : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: GameOfLifeColors.cellAlive,
              ),
              icon: const Icon(Icons.play_arrow, color: Colors.black),
              label:
                  const Text('确认运行', style: TextStyle(color: Colors.black)),
            ),
          ],
          if (_runner.state == ChallengeState.running)
            ElevatedButton.icon(
              onPressed: _skipToResult,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white24,
              ),
              icon: const Icon(Icons.fast_forward, color: Colors.white),
              label:
                  const Text('跳过', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _buildTutorial() {
    final steps = widget.level.tutorialSteps!;
    return GestureDetector(
      onTap: () {
        if (_tutorialStep < steps.length - 1) {
          setState(() => _tutorialStep++);
        } else {
          setState(() => _showTutorial = false);
        }
      },
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.school, color: Colors.amber, size: 36),
                const SizedBox(height: 12),
                Text(
                  steps[_tutorialStep],
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (_tutorialStep < steps.length - 1) {
                      setState(() => _tutorialStep++);
                    } else {
                      setState(() => _showTutorial = false);
                    }
                  },
                  child: Text(_tutorialStep < steps.length - 1 ? '下一步' : '开始'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF16213E),
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: GameOfLifeColors.cellAlive, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  3,
                  (i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.star,
                      size: 40,
                      color: i < _runner.stars
                          ? Colors.amber
                          : Colors.white24,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '挑战成功！',
                style: TextStyle(
                  color: GameOfLifeColors.cellAlive,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '使用了 ${_runner.userCellCount} 个细胞',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: _reset,
                    child: const Text('重试',
                        style: TextStyle(color: Colors.white54)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: widget.onBack,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GameOfLifeColors.cellAlive,
                    ),
                    child: const Text('返回',
                        style: TextStyle(color: Colors.black)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFailureOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF16213E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.redAccent, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.close, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              const Text(
                '挑战失败',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_runner.failReason != null) ...[
                const SizedBox(height: 8),
                Text(
                  _runner.failReason!,
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _reset,
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
