import 'package:flutter/material.dart';
import 'game_2048/game_2048_mode_page.dart';
import 'game_2048/game_2048_page.dart';
import 'home/home_page.dart';
import 'minesweeper/minesweeper_cell.dart';
import 'minesweeper/minesweeper_mode_page.dart';
import 'minesweeper/minesweeper_page.dart';
import 'snake/adaptive/adaptive_game_page.dart';
import 'snake/classic/classic_game_page.dart';
import 'snake/free/free_game_page.dart';
import 'snake/snake_mode_page.dart';
import 'match3/match3_gem.dart';
import 'match3/match3_mode_page.dart';
import 'match3/match3_page.dart';
import 'sokoban/sokoban_mode_page.dart';
import 'sokoban/sokoban_page.dart';
import 'sudoku/sudoku_cell.dart';
import 'sudoku/sudoku_mode_page.dart';
import 'sudoku/sudoku_page.dart';
import 'breakout/breakout_config.dart';
import 'breakout/breakout_mode_page.dart';
import 'breakout/breakout_page.dart';
import 'flappybird/flappybird_config.dart';
import 'flappybird/flappybird_mode_page.dart';
import 'flappybird/flappybird_page.dart';
import 'fruit_catcher/fruit_catcher_config.dart';
import 'fruit_catcher/fruit_catcher_mode_page.dart';
import 'fruit_catcher/fruit_catcher_page.dart';
import 'klotski/klotski_mode_page.dart';
import 'klotski/klotski_page.dart';
import 'tetris/tetris_board.dart';
import 'tetris/tetris_mode_page.dart';
import 'tetris/tetris_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MiniPlayApp());
}

class MiniPlayApp extends StatelessWidget {
  const MiniPlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mini Play',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A2E),
          elevation: 0,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4ECCA3),
          secondary: Color(0xFFF0C040),
          surface: Color(0xFF16213E),
          error: Color(0xFFE84545),
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const HomePage(),
            );
          case '/snake':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const SnakeModePage(),
            );
          case '/snake/classic':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const ClassicGamePage(),
            );
          case '/snake/adaptive':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const AdaptiveGamePage(),
            );
          case '/snake/free':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const FreeGamePage(),
            );
          case '/2048':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const Game2048ModePage(),
            );
          case '/2048/play':
            final gridSize = settings.arguments as int? ?? 4;
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => Game2048Page(gridSize: gridSize),
            );
          case '/minesweeper':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const MinesweeperModePage(),
            );
          case '/minesweeper/play':
            final difficulty = settings.arguments as MinesweeperDifficulty? ?? MinesweeperDifficulty.beginner;
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => MinesweeperPage(difficulty: difficulty),
            );
          case '/sokoban':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const SokobanModePage(),
            );
          case '/sokoban/play':
            final levelIndex = settings.arguments as int? ?? 0;
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => SokobanPage(levelIndex: levelIndex),
            );
          case '/match3':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const Match3ModePage(),
            );
          case '/match3/play':
            final mode = settings.arguments as Match3GameMode? ?? Match3GameMode.classic;
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => Match3Page(mode: mode),
            );
          case '/tetris':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const TetrisModePage(),
            );
          case '/tetris/play':
            final mode = settings.arguments as TetrisGameMode? ?? TetrisGameMode.classic;
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => TetrisPage(mode: mode),
            );
          case '/sudoku':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const SudokuModePage(),
            );
          case '/sudoku/play':
            final difficulty = settings.arguments as SudokuDifficulty? ?? SudokuDifficulty.easy;
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => SudokuPage(difficulty: difficulty),
            );
          case '/breakout':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const BreakoutModePage(),
            );
          case '/breakout/play':
            final mode = settings.arguments as BreakoutMode? ?? BreakoutMode.classic;
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => BreakoutPage(mode: mode),
            );
          case '/flappybird':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const FlappybirdModePage(),
            );
          case '/flappybird/play':
            final mode = settings.arguments as FlappybirdMode? ?? FlappybirdMode.normal;
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => FlappybirdPage(mode: mode),
            );
          case '/fruit_catcher':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const FruitCatcherModePage(),
            );
          case '/fruit_catcher/play':
            final mode = settings.arguments as FruitCatcherMode? ??
                FruitCatcherMode.timed;
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => FruitCatcherPage(mode: mode),
            );
          case '/klotski':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const KlotskiModePage(),
            );
          case '/klotski/play':
            final levelIndex = settings.arguments as int? ?? 0;
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => KlotskiPage(levelIndex: levelIndex),
            );
          default:
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const HomePage(),
            );
        }
      },
    );
  }
}
