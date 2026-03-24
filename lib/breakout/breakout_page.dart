// lib/breakout/breakout_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../shared/format_time.dart';
import '../shared/game_over_data.dart';
import '../shared/game_over_page.dart';
import '../shared/game_scaffold.dart';
import '../shared/score_service.dart';
import 'breakout_config.dart';
import 'breakout_game.dart';
import 'breakout_painter.dart';

class BreakoutPage extends StatefulWidget {
  final BreakoutMode mode;

  const BreakoutPage({super.key, required this.mode});

  @override
  State<BreakoutPage> createState() => _BreakoutPageState();
}

class _BreakoutPageState extends State<BreakoutPage>
    with TickerProviderStateMixin {
  Key _gameKey = UniqueKey();
  late BreakoutGame _game;
  final ValueNotifier<int> _scoreNotifier = ValueNotifier<int>(0);
  int _bestScore = 0;
  int _paintVersion = 0;
  bool _isPaused = false;
  bool _gameOverHandled = false;
  late Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  int _elapsedSeconds = 0;
  double _elapsedAccumulator = 0;
  final Set<String> _keysPressed = {};
  Size _canvasSize = Size.zero;

  String get _modeName {
    switch (widget.mode) {
      case BreakoutMode.classic: return 'Classic';
      case BreakoutMode.hard: return 'Hard';
      case BreakoutMode.endless: return 'Endless';
    }
  }

  bool get _canPlay => !_isPaused && !_game.isGameOver && !_game.isWon;

  @override
  void initState() {
    super.initState();
    _createGame();
    _loadBestScore();
    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  void _createGame() {
    final config = BreakoutConfig.forMode(widget.mode);
    _game = BreakoutGame(config: config, mode: widget.mode);
    _elapsedSeconds = 0;
    _elapsedAccumulator = 0;
    _isPaused = false;
    _scoreNotifier.value = 0;
    _lastElapsed = Duration.zero;
    _keysPressed.clear();
    _gameOverHandled = false;
  }

  Future<void> _loadBestScore() async {
    _bestScore = await ScoreService().getHighScore('breakout', widget.mode.name);
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

    if (!_canPlay) return;

    _game.movePaddleByKeys(_keysPressed, dt);
    _game.update(dt);

    if (_game.lifeLossPauseTimer <= 0 && _game.roundOverlayTimer <= 0 && !_game.waitingToLaunch) {
      _elapsedAccumulator += dt;
      if (_elapsedAccumulator >= 1.0) {
        _elapsedSeconds += _elapsedAccumulator.floor();
        _elapsedAccumulator %= 1.0;
      }
    }

    _scoreNotifier.value = _game.score;
    _paintVersion++;
    setState(() {});

    if ((_game.isGameOver || _game.isWon) && !_gameOverHandled) {
      _gameOverHandled = true;
      _ticker.stop();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _onGameOver();
      });
    }
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowLeft:
        case LogicalKeyboardKey.keyA:
          _keysPressed.add('left');
          return KeyEventResult.handled;
        case LogicalKeyboardKey.arrowRight:
        case LogicalKeyboardKey.keyD:
          _keysPressed.add('right');
          return KeyEventResult.handled;
        case LogicalKeyboardKey.space:
          _game.launchBall();
          return KeyEventResult.handled;
        case LogicalKeyboardKey.escape:
          Navigator.maybePop(context);
          return KeyEventResult.handled;
        default:
          return KeyEventResult.ignored;
      }
    } else if (event is KeyUpEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowLeft:
        case LogicalKeyboardKey.keyA:
          _keysPressed.remove('left');
          return KeyEventResult.handled;
        case LogicalKeyboardKey.arrowRight:
        case LogicalKeyboardKey.keyD:
          _keysPressed.remove('right');
          return KeyEventResult.handled;
        default:
          return KeyEventResult.ignored;
      }
    }
    return KeyEventResult.ignored;
  }

  void _onTapDown(TapDownDetails details) {
    if (!_canPlay) return;
    if (_game.waitingToLaunch) {
      _game.launchBall();
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_canPlay) return;
    if (_canvasSize.height == 0) return;
    final dx = details.delta.dx / _canvasSize.height;
    _game.movePaddleRelative(dx);
  }

  void _onPause() => _isPaused = true;
  void _onResume() => _isPaused = false;

  Future<void> _onGameOver() async {
    await ScoreService().saveHighScore('breakout', widget.mode.name, _game.score);
    final best = await ScoreService().getHighScore('breakout', widget.mode.name);
    if (!mounted) return;

    final stats = <String, String>{
      'Score': '${_game.score}',
      'Best': '$best',
      'Bricks': '${_game.bricksDestroyed}',
      'Time': formatTime(_elapsedSeconds),
    };
    if (widget.mode == BreakoutMode.endless) {
      stats['Rounds'] = '${_game.round}';
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameOverPage(
          data: GameOverData(
            gameName: 'breakout',
            mode: widget.mode.name,
            stats: stats,
            replayCallback: _replay,
            title: _game.isWon ? 'You Win!' : null,
            actions: [
              GameOverAction(
                label: 'Play Again',
                onPressed: () {
                  Navigator.pop(context);
                  _replay();
                },
                isPrimary: true,
              ),
              GameOverAction(
                label: 'Choose Mode',
                onPressed: () => Navigator.pop(context),
              ),
              GameOverAction(
                label: 'Home',
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
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
      title: 'Breakout - $_modeName',
      scoreNotifier: _scoreNotifier,
      bestScore: _bestScore,
      onPause: _onPause,
      onResume: _onResume,
      canPause: () => !_game.isGameOver && !_game.isWon,
      child: Focus(
        autofocus: true,
        onKeyEvent: _onKeyEvent,
        child: Center(
          child: AspectRatio(
            aspectRatio: BreakoutConfig.aspectRatio,
            child: LayoutBuilder(
              builder: (context, constraints) {
                _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
                return GestureDetector(
                  onTapDown: _onTapDown,
                  onPanUpdate: _onPanUpdate,
                  child: CustomPaint(
                    size: _canvasSize,
                    painter: BreakoutPainter(
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
