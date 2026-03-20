import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../shared/game_scaffold.dart';
import '../../shared/score_service.dart';
import '../components/snake_game_helper.dart';
import 'adaptive_game.dart';

class AdaptiveGamePage extends StatefulWidget {
  const AdaptiveGamePage({super.key});

  @override
  State<AdaptiveGamePage> createState() => _AdaptiveGamePageState();
}

class _AdaptiveGamePageState extends State<AdaptiveGamePage> {
  Key _gameKey = UniqueKey();
  late AdaptiveGame _game;
  int _bestScore = 0;
  Size? _initialSize;
  bool _windowTooSmall = false;

  @override
  void initState() {
    super.initState();
    _createGame();
    _loadBestScore();
  }

  void _createGame() {
    _game = AdaptiveGame(
      onGameOver: buildSnakeGameOverCallback(
        context: context,
        scoreMode: 'adaptive',
        onReplay: () {
          setState(() {
            _gameKey = UniqueKey();
            _initialSize = null;
            _windowTooSmall = false;
            _createGame();
          });
          _loadBestScore();
        },
      ),
    );
  }

  Future<void> _loadBestScore() async {
    _bestScore = await ScoreService().getHighScore('snake', 'adaptive');
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Snake - Adaptive',
      scoreNotifier: _game.scoreNotifier,
      bestScore: _bestScore,
      onPause: () => _game.isPaused = true,
      onResume: () {
        if (!_windowTooSmall) {
          _game.isPaused = false;
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final currentSize =
              Size(constraints.maxWidth, constraints.maxHeight);

          // Capture initial size after first layout via post-frame callback
          // to avoid mutating state during build.
          if (_initialSize == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _initialSize = currentSize);
              }
            });
            return ClipRect(
              child: GameWidget(key: _gameKey, game: _game),
            );
          }

          // Check if window is too small compared to initial size
          final tooSmall = currentSize.width < _initialSize!.width ||
              currentSize.height < _initialSize!.height;

          // Schedule state update after build if needed
          if (tooSmall != _windowTooSmall) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                _windowTooSmall = tooSmall;
                if (tooSmall) {
                  _game.isPaused = true;
                }
              });
            });
          }

          return ClipRect(
            child: Stack(
              children: [
                GameWidget(key: _gameKey, game: _game),
                if (_windowTooSmall)
                  Container(
                    color: const Color(0xDD000000),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.zoom_out_map,
                            color: Colors.white,
                            size: 48,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Window too small',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Resize the window to its original size\nor larger to continue playing.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
