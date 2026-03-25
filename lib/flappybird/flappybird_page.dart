// lib/flappybird/flappybird_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../shared/game_over_data.dart';
import '../shared/game_over_page.dart';
import '../shared/game_scaffold.dart';
import '../shared/score_service.dart';
import 'flappybird_config.dart';
import 'flappybird_game.dart';
import 'flappybird_models.dart';
import 'flappybird_painter.dart';

class FlappybirdPage extends StatefulWidget {
  final FlappybirdMode mode;

  const FlappybirdPage({super.key, required this.mode});

  @override
  State<FlappybirdPage> createState() => _FlappybirdPageState();
}

class _FlappybirdPageState extends State<FlappybirdPage>
    with TickerProviderStateMixin {
  Key _gameKey = UniqueKey();
  late FlappybirdGame _game;
  final ValueNotifier<int> _scoreNotifier = ValueNotifier<int>(0);
  int _bestScore = 0;
  int _paintVersion = 0;
  bool _isPaused = false;
  bool _gameOverHandled = false;
  bool _deathHapticFired = false;
  int _lastPipesPassed = 0;
  late Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  String get _modeName {
    switch (widget.mode) {
      case FlappybirdMode.easy:
        return 'Easy';
      case FlappybirdMode.normal:
        return 'Normal';
      case FlappybirdMode.hard:
        return 'Hard';
    }
  }

  // Dead state still needs update (bird falling animation)
  bool get _canUpdate =>
      !_isPaused && _game.state != GameState.gameOver;

  @override
  void initState() {
    super.initState();
    _createGame();
    _loadBestScore();
    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  void _createGame() {
    final config = FlappybirdConfig.forMode(widget.mode);
    _game = FlappybirdGame(config: config);
    _isPaused = false;
    _scoreNotifier.value = 0;
    _lastElapsed = Duration.zero;
    _gameOverHandled = false;
    _deathHapticFired = false;
    _lastPipesPassed = 0;
  }

  Future<void> _loadBestScore() async {
    _bestScore =
        await ScoreService().getHighScore('flappybird', widget.mode.name);
    if (mounted) setState(() {});
  }

  void _onTick(Duration elapsed) {
    if (_lastElapsed == Duration.zero) {
      _lastElapsed = elapsed;
      return;
    }

    final dtRaw = (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    final dt = dtRaw.clamp(0.0, 0.033);

    if (!_canUpdate) return;

    _game.update(dt);
    _scoreNotifier.value = _game.score;
    _paintVersion++;
    setState(() {});

    // Haptic on pipe pass
    if (_game.pipesPassed > _lastPipesPassed) {
      HapticFeedback.lightImpact();
      _lastPipesPassed = _game.pipesPassed;
    }

    // Haptic on death (once)
    if (_game.state == GameState.dead && !_deathHapticFired) {
      _deathHapticFired = true;
      HapticFeedback.heavyImpact();
    }

    if (_game.state == GameState.gameOver && !_gameOverHandled) {
      _gameOverHandled = true;
      _ticker.stop();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _onGameOver();
      });
    }
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.space:
        case LogicalKeyboardKey.arrowUp:
          if (_canUpdate) _game.jump();
          return KeyEventResult.handled;
        case LogicalKeyboardKey.escape:
          Navigator.maybePop(context);
          return KeyEventResult.handled;
        default:
          return KeyEventResult.ignored;
      }
    }
    return KeyEventResult.ignored;
  }

  void _onTapDown(TapDownDetails details) {
    if (!_canUpdate) return;
    _game.jump();
  }

  void _onPause() => _isPaused = true;
  void _onResume() => _isPaused = false;

  Future<void> _onGameOver() async {
    await ScoreService()
        .saveHighScore('flappybird', widget.mode.name, _game.score);
    final best =
        await ScoreService().getHighScore('flappybird', widget.mode.name);
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameOverPage(
          data: GameOverData(
            gameName: 'flappybird',
            mode: widget.mode.name,
            stats: {
              'Score': '${_game.score}',
              'Best': '$best',
              'Pipes': '${_game.pipesPassed}',
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
                onPressed: () {}, // pop handled by game_over_page.dart
              ),
              GameOverAction(
                label: 'Home',
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _replay() {
    setState(() {
      _gameKey = UniqueKey();
      _createGame();
      if (!_ticker.isActive) {
        _ticker.stop();
        _ticker.dispose();
        _ticker = createTicker(_onTick);
        _ticker.start();
      }
    });
    _loadBestScore();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scoreNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      key: _gameKey,
      title: 'Flappy Bird - $_modeName',
      scoreNotifier: _scoreNotifier,
      bestScore: _bestScore,
      onPause: _onPause,
      onResume: _onResume,
      canPause: () => _game.state == GameState.ready || _game.state == GameState.playing,
      child: Focus(
        autofocus: true,
        onKeyEvent: _onKeyEvent,
        child: Center(
          child: AspectRatio(
            aspectRatio: FlappybirdConfig.aspectRatio,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onTapDown: _onTapDown,
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: FlappybirdPainter(
                      game: _game,
                      paintVersion: _paintVersion,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
