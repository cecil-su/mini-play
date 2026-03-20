import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../shared/game_scaffold.dart';
import '../../shared/score_service.dart';
import '../components/snake_game_helper.dart';
import 'free_game.dart';

class FreeGamePage extends StatefulWidget {
  const FreeGamePage({super.key});

  @override
  State<FreeGamePage> createState() => _FreeGamePageState();
}

class _FreeGamePageState extends State<FreeGamePage> {
  Key _gameKey = UniqueKey();
  late FreeGame _game;
  int _bestScore = 0;

  @override
  void initState() {
    super.initState();
    _createGame();
    _loadBestScore();
  }

  void _createGame() {
    _game = FreeGame(
      onGameOver: buildSnakeGameOverCallback(
        context: context,
        scoreMode: 'free',
        onReplay: () {
          setState(() {
            _gameKey = UniqueKey();
            _createGame();
          });
          _loadBestScore();
        },
      ),
    );
  }

  Future<void> _loadBestScore() async {
    _bestScore = await ScoreService().getHighScore('snake', 'free');
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Snake - Free',
      scoreNotifier: _game.scoreNotifier,
      bestScore: _bestScore,
      onPause: () => _game.isPaused = true,
      onResume: () => _game.isPaused = false,
      child: GameWidget(key: _gameKey, game: _game),
    );
  }
}
