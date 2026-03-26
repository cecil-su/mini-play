import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../shared/format_time.dart';
import '../shared/game_over_data.dart';
import '../shared/game_over_page.dart';
import '../shared/game_scaffold.dart';
import '../shared/score_service.dart';
import 'fruit_catcher_config.dart';
import 'fruit_catcher_game.dart';
import 'fruit_catcher_painter.dart';

class FruitCatcherPage extends StatefulWidget {
  final FruitCatcherMode mode;

  const FruitCatcherPage({super.key, required this.mode});

  @override
  State<FruitCatcherPage> createState() => _FruitCatcherPageState();
}

class _FruitCatcherPageState extends State<FruitCatcherPage>
    with TickerProviderStateMixin {
  Key _gameKey = UniqueKey();
  late FruitCatcherGame _game;
  final ValueNotifier<int> _scoreNotifier = ValueNotifier<int>(0);
  int _bestScore = 0;
  int _paintVersion = 0;
  bool _isPaused = false;
  bool _gameOverHandled = false;
  late Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  final Set<String> _keysPressed = {};
  Size _canvasSize = Size.zero;

  String get _modeName {
    switch (widget.mode) {
      case FruitCatcherMode.classic:
        return 'Classic';
      case FruitCatcherMode.timed:
        return 'Timed';
      case FruitCatcherMode.endless:
        return 'Endless';
    }
  }

  bool get _canPlay => !_isPaused && !_game.isGameOver;

  @override
  void initState() {
    super.initState();
    _createGame();
    _loadBestScore();
    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  void _createGame() {
    final config = FruitCatcherConfig.forMode(widget.mode);
    _game = FruitCatcherGame(config: config, mode: widget.mode);
    _isPaused = false;
    _scoreNotifier.value = 0;
    _lastElapsed = Duration.zero;
    _keysPressed.clear();
    _gameOverHandled = false;
  }

  Future<void> _loadBestScore() async {
    _bestScore =
        await ScoreService().getHighScore('fruit_catcher', widget.mode.name);
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

    _game.moveBasketByKeys(_keysPressed, dt);
    _game.update(dt);

    if (_game.fruitCaughtThisFrame > 0) {
      HapticFeedback.lightImpact();
    }
    if (_game.bombCaughtThisFrame) {
      HapticFeedback.heavyImpact();
    }

    _scoreNotifier.value = _game.score;
    _paintVersion++;
    setState(() {});

    if (_game.isGameOver && !_gameOverHandled) {
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

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_canPlay) return;
    if (_canvasSize.height == 0) return;
    final dx = details.delta.dx / _canvasSize.height;
    _game.moveBasketRelative(dx);
  }

  void _onPointerHover(PointerHoverEvent event) {
    if (!_canPlay) return;
    if (_canvasSize.height == 0) return;
    final x = event.localPosition.dx / _canvasSize.height;
    _game.moveBasketTo(x);
  }

  void _onPause() => _isPaused = true;
  void _onResume() => _isPaused = false;

  Future<void> _onGameOver() async {
    await ScoreService()
        .saveHighScore('fruit_catcher', widget.mode.name, _game.score);
    final best =
        await ScoreService().getHighScore('fruit_catcher', widget.mode.name);
    if (!mounted) return;

    final accuracy = _game.totalFruitSpawned > 0
        ? (_game.fruitsCaught / _game.totalFruitSpawned * 100).round()
        : 0;

    final stats = <String, String>{
      'Score': '${_game.score}',
      'Best': '$best',
      'Caught': '${_game.fruitsCaught}',
      'Max Combo': '${_game.maxCombo}',
      'Accuracy': '$accuracy%',
    };
    if (widget.mode == FruitCatcherMode.classic ||
        widget.mode == FruitCatcherMode.endless) {
      stats['Time'] = formatTime(_game.survivalTime.round());
    }
    if (widget.mode == FruitCatcherMode.endless) {
      stats['Wave'] = '${_game.wave}';
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameOverPage(
          data: GameOverData(
            gameName: 'fruit_catcher',
            mode: widget.mode.name,
            stats: stats,
            replayCallback: _replay,
            actions: [
              GameOverAction(
                label: 'Play Again',
                onPressed: _replay,
                isPrimary: true,
              ),
              GameOverAction(
                label: 'Choose Mode',
                onPressed: () {},
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
      title: 'Fruit Catcher - $_modeName',
      scoreNotifier: _scoreNotifier,
      bestScore: _bestScore,
      onPause: _onPause,
      onResume: _onResume,
      canPause: () => !_game.isGameOver,
      child: Focus(
        autofocus: true,
        onKeyEvent: _onKeyEvent,
        child: Center(
          child: AspectRatio(
            aspectRatio: FruitCatcherConfig.aspectRatio,
            child: LayoutBuilder(
              builder: (context, constraints) {
                _canvasSize =
                    Size(constraints.maxWidth, constraints.maxHeight);
                return Listener(
                  onPointerHover: _onPointerHover,
                  child: GestureDetector(
                    onPanUpdate: _onPanUpdate,
                    child: CustomPaint(
                      size: _canvasSize,
                      painter: FruitCatcherPainter(
                        game: _game,
                        paintVersion: _paintVersion,
                      ),
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
