import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../shared/game_scaffold.dart';
import '../../shared/score_service.dart';
import '../components/snake_game_helper.dart';
import 'classic_game.dart';

class ClassicGamePage extends StatefulWidget {
  const ClassicGamePage({super.key});

  @override
  State<ClassicGamePage> createState() => _ClassicGamePageState();
}

class _ClassicGamePageState extends State<ClassicGamePage> {
  Key _gameKey = UniqueKey();
  late ClassicGame _game;
  int _bestScore = 0;

  @override
  void initState() {
    super.initState();
    _createGame();
    _loadBestScore();
  }

  void _createGame() {
    _game = ClassicGame(
      onGameOver: buildSnakeGameOverCallback(
        context: context,
        scoreMode: 'classic',
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
    _bestScore = await ScoreService().getHighScore('snake', 'classic');
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Snake - Classic',
      scoreNotifier: _game.scoreNotifier,
      bestScore: _bestScore,
      onPause: () => _game.isPaused = true,
      onResume: () => _game.isPaused = false,
      child: GameWidget(key: _gameKey, game: _game),
    );
  }
}
