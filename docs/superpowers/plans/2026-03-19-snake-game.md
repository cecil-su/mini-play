# Snake Game Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the shared game infrastructure (home page, game scaffold, score service) and the first game (Snake) with three modes (Classic, Adaptive, Free) using Flame engine.

**Architecture:** Single Flutter app with hash-based routing. Shared infrastructure in `lib/shared/` and `lib/home/`, Snake game in `lib/snake/`. Each game mode is an independent FlameGame class. Flame communicates with Flutter widgets via ValueNotifier. Game Over is a pushed page, not a named route.

**Tech Stack:** Flutter 3.41.5, Flame ^1.22.0, shared_preferences ^2.3.0

**Spec:** `docs/superpowers/specs/2026-03-19-snake-game-design.md`

---

## File Structure

| File | Action | Responsibility |
|------|--------|---------------|
| `pubspec.yaml` | Modify | Add flame, shared_preferences dependencies |
| `lib/main.dart` | Modify | Hash-based routing, dark theme, app entry |
| `lib/shared/score_service.dart` | Create | High score read/write via shared_preferences |
| `lib/shared/game_over_data.dart` | Create | Data class for game over params |
| `lib/shared/game_scaffold.dart` | Create | Common game wrapper with pause, score bar |
| `lib/shared/game_over_page.dart` | Create | Reusable game over result screen |
| `lib/home/game_registry.dart` | Create | Game metadata list |
| `lib/home/game_card.dart` | Create | Game card widget for grid/list views |
| `lib/home/home_page.dart` | Create | Home page with grid/list toggle |
| `lib/snake/snake_mode_page.dart` | Create | Mode selection page |
| `lib/snake/components/grid_background.dart` | Create | Grid line rendering |
| `lib/snake/components/food_component.dart` | Create | Abstract food base + GridFood + FreeFood |
| `lib/snake/classic/classic_snake.dart` | Create | Grid-based snake component |
| `lib/snake/classic/classic_game.dart` | Create | Classic mode FlameGame |
| `lib/snake/classic/classic_game_page.dart` | Create | Classic mode page wrapper (StatefulWidget) |
| `lib/snake/adaptive/adaptive_snake.dart` | Skip | Not needed — reuses ClassicSnake with different grid params |
| `lib/snake/adaptive/adaptive_game.dart` | Create | Adaptive mode FlameGame |
| `lib/snake/adaptive/adaptive_game_page.dart` | Create | Adaptive mode page wrapper |
| `lib/snake/free/free_snake.dart` | Create | Path-based smooth snake component |
| `lib/snake/free/free_game.dart` | Create | Free mode FlameGame |
| `lib/snake/free/free_game_page.dart` | Create | Free mode page wrapper |
| `test/shared/score_service_test.dart` | Create | Score service unit tests |
| `test/snake/classic/classic_snake_test.dart` | Create | Classic snake logic tests |

---

### Task 1: Add Dependencies & App Setup

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/main.dart`

- [ ] **Step 1: Add dependencies to pubspec.yaml**

Add `flame` and `shared_preferences` under dependencies:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  flame: ^1.22.0
  shared_preferences: ^2.3.0
```

- [ ] **Step 2: Run pub get to verify compatibility**

```bash
fvm flutter pub get
```

Expected: Resolves successfully. If `flame: ^1.22.0` fails, use `flutter pub add flame shared_preferences` to get latest compatible versions.

- [ ] **Step 3: Remove default counter app boilerplate**

Delete `test/widget_test.dart` (references old MyApp/MyHomePage classes that no longer exist).

- [ ] **Step 4: Replace main.dart with hash-based routing and dark theme**

Replace `lib/main.dart` with the app setup. Flutter Web uses hash-based URLs (`/#/...`) by default, which is what we need for GitHub Pages.

**Important:** Do NOT use both `home:` and `initialRoute:`/`onGenerateRoute:` — use only `onGenerateRoute`. All routes point to `Placeholder()` initially; they will be replaced as pages are built.

```dart
import 'package:flutter/material.dart';

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
        // All routes point to Placeholder() initially
        // Will be replaced as pages are built in subsequent tasks
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const Scaffold(
            body: Center(child: Text('Mini Play - Coming Soon')),
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 5: Verify the app builds**

```bash
fvm flutter build web --release --base-href "/mini-play/"
```

Expected: Build succeeds.

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/main.dart
git rm test/widget_test.dart 2>/dev/null; git add -u
git commit -m "feat: add Flame and shared_preferences, set up dark theme and routing"
```

---

### Task 2: Score Service

**Files:**
- Create: `lib/shared/score_service.dart`
- Create: `test/shared/score_service_test.dart`

- [ ] **Step 1: Create score_service.dart**

```dart
import 'package:shared_preferences/shared_preferences.dart';

class ScoreService {
  static final ScoreService _instance = ScoreService._();
  factory ScoreService() => _instance;
  ScoreService._();

  String _key(String game, String mode) => 'highscore_${game}_$mode';

  Future<int> getHighScore(String game, String mode) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key(game, mode)) ?? 0;
  }

  Future<void> saveHighScore(String game, String mode, int score) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_key(game, mode)) ?? 0;
    if (score > current) {
      await prefs.setInt(_key(game, mode), score);
    }
  }
}
```

- [ ] **Step 2: Create score_service_test.dart**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mini_play/shared/score_service.dart';

void main() {
  group('ScoreService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('returns 0 for no saved score', () async {
      final service = ScoreService();
      expect(await service.getHighScore('snake', 'classic'), 0);
    });

    test('saves and retrieves high score', () async {
      final service = ScoreService();
      await service.saveHighScore('snake', 'classic', 10);
      expect(await service.getHighScore('snake', 'classic'), 10);
    });

    test('only saves higher score', () async {
      final service = ScoreService();
      await service.saveHighScore('snake', 'classic', 10);
      await service.saveHighScore('snake', 'classic', 5);
      expect(await service.getHighScore('snake', 'classic'), 10);
    });

    test('uses default mode for modeless games', () async {
      final service = ScoreService();
      await service.saveHighScore('2048', 'default', 2048);
      expect(await service.getHighScore('2048', 'default'), 2048);
    });
  });
}
```

- [ ] **Step 3: Run tests**

```bash
fvm flutter test test/shared/score_service_test.dart
```

Expected: All 4 tests pass.

- [ ] **Step 4: Commit**

```bash
git add lib/shared/score_service.dart test/shared/score_service_test.dart
git commit -m "feat: add ScoreService with high score persistence"
```

---

### Task 3: Game Over Data & Game Registry

**Files:**
- Create: `lib/shared/game_over_data.dart`
- Create: `lib/home/game_registry.dart`

- [ ] **Step 1: Create game_over_data.dart**

```dart
import 'package:flutter/material.dart';

class GameOverData {
  final String gameName;
  final String mode;
  final Map<String, String> stats;
  final VoidCallback replayCallback;

  const GameOverData({
    required this.gameName,
    required this.mode,
    required this.stats,
    required this.replayCallback,
  });
}
```

- [ ] **Step 2: Create game_registry.dart**

```dart
import 'package:flutter/material.dart';

class GameInfo {
  final String name;
  final IconData icon;
  final String description;
  final int phase;
  final String route;
  final bool implemented;
  final bool hasModePage;

  const GameInfo({
    required this.name,
    required this.icon,
    required this.description,
    required this.phase,
    required this.route,
    this.implemented = false,
    this.hasModePage = false,
  });
}

class GameRegistry {
  static const List<GameInfo> games = [
    GameInfo(
      name: 'Snake',
      icon: Icons.pest_control,
      description: 'Classic snake game with 3 modes',
      phase: 1,
      route: '/snake',
      implemented: true,
      hasModePage: true,
    ),
    GameInfo(
      name: '2048',
      icon: Icons.grid_4x4,
      description: 'Slide and merge number tiles',
      phase: 1,
      route: '/2048',
    ),
    GameInfo(
      name: 'Minesweeper',
      icon: Icons.flag,
      description: 'Find all mines without detonating',
      phase: 1,
      route: '/minesweeper',
    ),
    GameInfo(
      name: 'Tetris',
      icon: Icons.view_comfy,
      description: 'Rotate and stack falling blocks',
      phase: 2,
      route: '/tetris',
    ),
    GameInfo(
      name: 'Match-3',
      icon: Icons.diamond,
      description: 'Swap tiles to match 3 or more',
      phase: 2,
      route: '/match3',
    ),
    GameInfo(
      name: 'Sokoban',
      icon: Icons.inventory_2,
      description: 'Push boxes onto target positions',
      phase: 2,
      route: '/sokoban',
    ),
  ];

  static List<GameInfo> byPhase(int phase) =>
      games.where((g) => g.phase == phase).toList();
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/shared/game_over_data.dart lib/home/game_registry.dart
git commit -m "feat: add GameOverData model and GameRegistry"
```

---

### Task 4: Home Page

**Files:**
- Create: `lib/home/game_card.dart`
- Create: `lib/home/home_page.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: Create game_card.dart**

A card widget that displays a game's icon, name, and handles tap for implemented games. Used in both grid and list views.

- Grid mode: square card with centered icon and name below
- List mode: horizontal row with icon, name, description
- Implemented games: accent border (#4ECCA3), full opacity
- Unimplemented: no border, opacity 0.4

- [ ] **Step 2: Create home_page.dart**

Home page with:
- AppBar: "Mini Play" title, grid/list toggle icons on the right
- Grid view (default): `GridView.builder` with responsive `crossAxisCount` (use `LayoutBuilder`, 2 cols if width < 600, 3 if < 900, 4 otherwise)
- List view: `ListView.builder` with phase group headers ("Phase 1: Flame Basics", etc.)
- View toggle persisted via shared_preferences key `home_view_mode`
- Tap on implemented game → `Navigator.pushNamed(context, game.route)`

- [ ] **Step 3: Update main.dart with routes**

Add hash-based routing with `onGenerateRoute`:

```dart
MaterialApp(
  // ... theme stays the same
  initialRoute: '/',
  onGenerateRoute: (settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const HomePage());
      case '/snake':
        return MaterialPageRoute(builder: (_) => const SnakeModePage());
      case '/snake/classic':
        return MaterialPageRoute(builder: (_) => const ClassicGamePage());
      case '/snake/adaptive':
        return MaterialPageRoute(builder: (_) => const AdaptiveGamePage());
      case '/snake/free':
        return MaterialPageRoute(builder: (_) => const FreeGamePage());
      default:
        return MaterialPageRoute(builder: (_) => const HomePage());
    }
  },
);
```

For now, snake routes can point to `Placeholder()` widgets until those pages are built.

- [ ] **Step 4: Verify home page renders**

```bash
fvm flutter run -d chrome
```

Expected: Home page shows with grid of game cards, Snake highlighted, others dimmed. Toggle switches between grid and list views.

- [ ] **Step 5: Commit**

```bash
git add lib/home/game_card.dart lib/home/home_page.dart lib/main.dart
git commit -m "feat: add home page with grid/list toggle and game registry"
```

---

### Task 5: Game Scaffold & Game Over Page

**Files:**
- Create: `lib/shared/game_scaffold.dart`
- Create: `lib/shared/game_over_page.dart`

- [ ] **Step 1: Create game_scaffold.dart**

A StatefulWidget that wraps any game:
- Accepts: `title` (String), `scoreNotifier` (ValueNotifier<int>), `bestScore` (int), `child` (Widget — the GameWidget), `onPause`/`onResume` callbacks
- Top bar: Row with back button (IconButton ←), title (centered), pause button (IconButton ⏸)
- Score bar: Row with "Score: {current}" in #4ECCA3 and "Best: {best}" in #F0C040
- Pause overlay: Visibility controlled by `_isPaused` state. Stack overlay with semi-transparent black (#000000AA), "Paused" text, Resume and Quit buttons
- Resume → calls `onResume`, hides overlay
- Quit → `Navigator.popUntil(context, ModalRoute.withName('/'))`
- Android back button: `WillPopScope` / `PopScope` → triggers pause
- Auto-pause: `WidgetsBindingObserver` with `didChangeAppLifecycleState` — handles both Android (paused/resumed) and Web (hidden/resumed via visibilitychange, supported in Flutter 3.13+). No conditional imports needed.
- Pause state: exposes `isPaused` that the game checks before processing input
- `ValueListenableBuilder` to reactively display score from the FlameGame's ValueNotifier

- [ ] **Step 2: Create game_over_page.dart**

A StatelessWidget page:
- Receives `GameOverData` via constructor (passed through `Navigator.push`)
- Dark background (#1A1A2E)
- "Game Over" title in red (#E84545)
- Stats grid: 2x2 grid of stat cards, each with label (grey) and value (white/colored)
- "Play Again" button (#4ECCA3) → calls `Navigator.pop(context)` to return to the game page, then invokes `data.replayCallback`. The `replayCallback` is a closure created by the game page (e.g., `ClassicGamePage`) before pushing GameOverPage: `replayCallback: () { setState(() { _gameKey = UniqueKey(); }); }`. The game page holds a `_gameKey` used as the `key` parameter on `GameWidget` — changing the key forces Flutter to dispose and recreate the widget, creating a fresh FlameGame instance.
- "Home" button (#333) → `Navigator.popUntil(context, ModalRoute.withName('/'))`
- High score is already saved by the game page before pushing GameOverPage — GameOverPage is pure display, no save logic

- [ ] **Step 3: Verify scaffold renders with a test game**

Temporarily wire up a simple colored box as the child of GameScaffold on one of the snake routes to verify the scaffold, pause overlay, and back button all work.

- [ ] **Step 4: Commit**

```bash
git add lib/shared/game_scaffold.dart lib/shared/game_over_page.dart
git commit -m "feat: add GameScaffold with pause system and GameOverPage"
```

---

### Task 6: Snake Mode Selection Page

**Files:**
- Create: `lib/snake/snake_mode_page.dart`

- [ ] **Step 1: Create snake_mode_page.dart**

A StatelessWidget:
- AppBar with back button and "Snake" title
- Three mode cards in a ListView:
  - **Classic** (icon: 🎮, color: #4ECCA3): "Fixed 20×20 grid, constant speed"
  - **Adaptive** (icon: 📐, color: #3A86FF): "Grid adapts to screen size"
  - **Free** (icon: 🌀, color: #E84545): "Smooth movement, no grid limits"
- Each card shows best score via `FutureBuilder` + `ScoreService().getHighScore('snake', mode)`
- Tap → `Navigator.pushNamed(context, '/snake/$mode')`
- Card design: dark card (#16213E), rounded corners (10px), padding 16px, icon + title + description + best score

- [ ] **Step 2: Verify navigation flow**

```bash
fvm flutter run -d chrome
```

Expected: Home → tap Snake → mode selection page shows 3 cards → tap any card navigates (currently to placeholder).

- [ ] **Step 3: Commit**

```bash
git add lib/snake/snake_mode_page.dart
git commit -m "feat: add Snake mode selection page"
```

---

### Task 7: Snake Shared Components

**Files:**
- Create: `lib/snake/components/grid_background.dart`
- Create: `lib/snake/components/food_component.dart`

- [ ] **Step 1: Create grid_background.dart**

A Flame `Component` that renders grid lines:

```dart
import 'package:flame/components.dart';
import 'dart:ui';

class GridBackground extends Component {
  final int columns;
  final int rows;
  final double cellSize;
  final Vector2 offset;

  GridBackground({
    required this.columns,
    required this.rows,
    required this.cellSize,
    required this.offset,
  });

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = const Color(0xFF1E2A4A)
      ..strokeWidth = 1;

    // Draw vertical lines
    for (int i = 0; i <= columns; i++) {
      final x = offset.x + i * cellSize;
      canvas.drawLine(
        Offset(x, offset.y),
        Offset(x, offset.y + rows * cellSize),
        paint,
      );
    }

    // Draw horizontal lines
    for (int i = 0; i <= rows; i++) {
      final y = offset.y + i * cellSize;
      canvas.drawLine(
        Offset(offset.x, y),
        Offset(offset.x + columns * cellSize, y),
        paint,
      );
    }
  }
}
```

- [ ] **Step 2: Create food_component.dart**

Abstract base class with two subclasses:

```dart
import 'package:flame/components.dart';
import 'dart:ui';
import 'dart:math';

// Abstract base — uses generics for type-safe occupied positions
abstract class FoodComponent<T> extends PositionComponent {
  static const Color foodColor = Color(0xFFE84545);
  static const int _maxSpawnAttempts = 1000;

  void respawn(List<T> occupied, Vector2 areaSize);
}

// Grid-based food for Classic/Adaptive modes
class GridFood extends FoodComponent<Point<int>> {
  final int columns;
  final int rows;
  final double cellSize;
  final Vector2 gridOffset;
  int gridX = 0;
  int gridY = 0;

  GridFood({
    required this.columns,
    required this.rows,
    required this.cellSize,
    required this.gridOffset,
  }) {
    size = Vector2.all(cellSize); // Set size once, not in render
  }

  void spawnInitial(List<Point<int>> occupiedCells) {
    // First food spawns in front of snake (right half of grid)
    final random = Random();
    int attempts = 0;
    do {
      gridX = (columns ~/ 2) + random.nextInt(columns ~/ 2);
      gridY = random.nextInt(rows);
      attempts++;
    } while (occupiedCells.any((c) => c.x == gridX && c.y == gridY)
             && attempts < FoodComponent._maxSpawnAttempts);
    // Fallback: if random fails, find first free cell
    if (attempts >= FoodComponent._maxSpawnAttempts) {
      _fallbackSpawn(occupiedCells);
    }
    _updatePosition();
  }

  @override
  void respawn(List<Point<int>> occupiedCells, Vector2 areaSize) {
    final random = Random();
    int attempts = 0;
    do {
      gridX = random.nextInt(columns);
      gridY = random.nextInt(rows);
      attempts++;
    } while (occupiedCells.any((c) => c.x == gridX && c.y == gridY)
             && attempts < FoodComponent._maxSpawnAttempts);
    if (attempts >= FoodComponent._maxSpawnAttempts) {
      _fallbackSpawn(occupiedCells);
    }
    _updatePosition();
  }

  void _fallbackSpawn(List<Point<int>> occupied) {
    for (int x = 0; x < columns; x++) {
      for (int y = 0; y < rows; y++) {
        if (!occupied.any((c) => c.x == x && c.y == y)) {
          gridX = x;
          gridY = y;
          return;
        }
      }
    }
  }

  void _updatePosition() {
    position = Vector2(
      gridOffset.x + gridX * cellSize,
      gridOffset.y + gridY * cellSize,
    );
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(size.toRect(), const Radius.circular(2)),
      Paint()..color = FoodComponent.foodColor,
    );
  }
}

// Radius-based food for Free mode
class FreeFood extends FoodComponent<Vector2> {
  static const double radius = 8.0;
  final Vector2 areaMin;
  final Vector2 areaMax;

  FreeFood({required this.areaMin, required this.areaMax}) {
    size = Vector2.all(radius * 2); // Set size once in constructor
  }

  void spawnInitial(Vector2 snakeHeadPos) {
    // Spawn in front (to the right) of snake head
    final random = Random();
    position = Vector2(
      snakeHeadPos.x + 50 + random.nextDouble() * 100,
      areaMin.y + random.nextDouble() * (areaMax.y - areaMin.y),
    );
    // Clamp to play area (Vector2 has no clamp for two vectors, do it per axis)
    position.x = position.x.clamp(areaMin.x + radius, areaMax.x - radius);
    position.y = position.y.clamp(areaMin.y + radius, areaMax.y - radius);
  }

  @override
  void respawn(List<Vector2> segments, Vector2 areaSize) {
    final random = Random();
    bool tooClose;
    int attempts = 0;
    do {
      position = Vector2(
        areaMin.x + radius + random.nextDouble() * (areaMax.x - areaMin.x - 2 * radius),
        areaMin.y + radius + random.nextDouble() * (areaMax.y - areaMin.y - 2 * radius),
      );
      tooClose = segments.any((seg) => position.distanceTo(seg) < 32);
      attempts++;
    } while (tooClose && attempts < FoodComponent._maxSpawnAttempts);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(
      Offset(radius, radius),
      radius,
      Paint()..color = FoodComponent.foodColor,
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/snake/components/
git commit -m "feat: add grid background and food components for snake"
```

---

### Task 8: Classic Snake Game

**Files:**
- Create: `lib/snake/classic/classic_snake.dart`
- Create: `lib/snake/classic/classic_game.dart`
- Modify: `lib/main.dart` (wire up route)
- Create: `test/snake/classic/classic_snake_test.dart`

- [ ] **Step 1: Create classic_snake.dart**

Grid-based snake component with:

Core data:
- `List<Point<int>> body` — grid positions, index 0 = head
- `Direction currentDirection` — enum: up, down, left, right
- `List<Direction> inputBuffer` — max depth 2
- `double tickTimer` — accumulates dt, moves on >= 0.2s
- `bool isDead` — death state

Key methods:
- `void changeDirection(Direction dir)` — validates not reverse, adds to buffer (max 2)
- `void update(double dt)` — accumulates tick timer, on tick: dequeue direction from buffer, move (add new head, remove tail unless growing), check wall/self collision
- `void grow()` — flag to skip tail removal next tick
- `List<Point<int>> get occupiedCells` — returns body list
- `void render(Canvas canvas)` — render each segment as rounded rect with gradient color from head (#4ECCA3) to tail (#0E8263)

Death animation:
- When collision detected, set `isDead = true`, start flash timer
- 3 flashes over 500ms: each flash cycle is ~167ms (83ms red #E84545, 83ms normal color)
- Track with `deathTimer` accumulator in `update(dt)`, toggle `isFlashRed` every 83ms
- After 500ms total: trigger `onGameOver` callback
- During death flash, `isDead = true` so normal game logic is skipped

- [ ] **Step 2: Create classic_game.dart**

FlameGame subclass:

```dart
class ClassicGame extends FlameGame with KeyboardEvents {
  final ValueNotifier<int> scoreNotifier = ValueNotifier(0);
  final void Function(Map<String, String> stats) onGameOver;
  bool isPaused = false;

  // Grid config
  static const int gridSize = 20;
  late double cellSize;
  late Vector2 gridOffset;

  late ClassicSnake snake;
  late GridFood food;
  late GridBackground background;

  double gameTime = 0;

  ClassicGame({required this.onGameOver});

  // Note: `size` here is the FlameGame canvas size, which equals the
  // GameWidget's layout size inside GameScaffold's Expanded child.
  // This already excludes the top bar and score bar.

  @override
  Color backgroundColor() => const Color(0xFF16213E); // Game area background

  @override
  Future<void> onLoad() async {
    // Calculate cell size: floor(min(width, height) / 20) for integer pixels
    cellSize = (size.x < size.y ? size.x : size.y) / gridSize;
    cellSize = cellSize.floorToDouble();
    gridOffset = Vector2(
      (size.x - cellSize * gridSize) / 2,
      (size.y - cellSize * gridSize) / 2,
    );

    // Add components
    background = GridBackground(columns: gridSize, rows: gridSize, cellSize: cellSize, offset: gridOffset);
    snake = ClassicSnake(gridSize: gridSize, cellSize: cellSize, gridOffset: gridOffset, onDeath: _handleDeath);
    food = GridFood(columns: gridSize, rows: gridSize, cellSize: cellSize, gridOffset: gridOffset);

    await add(background);
    await add(food);
    await add(snake);

    food.spawnInitial(snake.occupiedCells);
  }

  @override
  void update(double dt) {
    if (isPaused) return;          // Paused: don't update anything
    super.update(dt);              // Propagate to snake (handles death flash animation)
    if (snake.isDead) return;      // Dead: only run death animation in super, skip game logic
    gameTime += dt;
    // Check if snake head is on food
    if (snake.body.first.x == food.gridX && snake.body.first.y == food.gridY) {
      snake.grow();
      scoreNotifier.value++;
      food.respawn(snake.occupiedCells, Vector2.zero());
    }
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (isPaused || snake.isDead) return KeyEventResult.ignored;
    // Map arrow keys and WASD to directions
    // Call snake.changeDirection(dir)
    return KeyEventResult.handled;
  }

  void _handleDeath() {
    // Format stats for game over screen
    final minutes = (gameTime ~/ 60).toString().padLeft(2, '0');
    final seconds = (gameTime.toInt() % 60).toString().padLeft(2, '0');
    onGameOver({
      'Score': '${scoreNotifier.value}',
      'Time': '$minutes:$seconds',
      'Length': '${3 + scoreNotifier.value}',
    });
  }
}
```

- [ ] **Step 3: Create `lib/snake/classic/classic_game_page.dart`**

A StatefulWidget that connects ClassicGame to GameScaffold. **This is a separate file, NOT in main.dart.**

```dart
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
    _game = ClassicGame(onGameOver: (stats) async {
      final score = int.tryParse(stats['Score'] ?? '0') ?? 0;
      await ScoreService().saveHighScore('snake', 'classic', score);
      final best = await ScoreService().getHighScore('snake', 'classic');
      stats['Best'] = '$best';
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => GameOverPage(
            data: GameOverData(
              gameName: 'snake',
              mode: 'classic',
              stats: stats,
              replayCallback: () {
                setState(() { _gameKey = UniqueKey(); _createGame(); });
              },
            ),
          ),
        ));
      }
    });
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
```

Update `lib/main.dart` route for `/snake/classic` to import and use `ClassicGamePage`.

- [ ] **Step 4: Create classic_snake_test.dart**

Test core snake logic:
- Snake starts at center moving right
- `changeDirection` ignores reverse direction
- Input buffer depth is 2 (third input discarded)
- Snake grows when `grow()` is called
- Wall collision detected correctly
- Self collision detected correctly

- [ ] **Step 5: Run tests**

```bash
fvm flutter test test/snake/classic/classic_snake_test.dart
```

Expected: All tests pass.

- [ ] **Step 6: Manual test in browser**

```bash
fvm flutter run -d chrome
```

Expected: Home → Snake → Classic → game plays correctly. Arrow keys control snake. Eating food increases score. Wall/self collision triggers death flash → game over screen. Play Again and Home buttons work.

- [ ] **Step 7: Commit**

```bash
git add lib/snake/classic/ lib/main.dart test/snake/classic/
git commit -m "feat: implement Classic Snake mode with grid-based movement"
```

---

### Task 9: Adaptive Snake Game

**Files:**
- Create: `lib/snake/adaptive/adaptive_snake.dart`
- Create: `lib/snake/adaptive/adaptive_game.dart`

- [ ] **Step 1: Create adaptive_snake.dart**

Reuses ClassicSnake via a mixin architecture:
- Extract the grid-based snake logic (movement, input buffer, collision, rendering) from `classic_snake.dart` into a mixin `GridSnakeMixin` (or simply make `ClassicSnake` accept `columns`/`rows` as constructor params instead of hardcoding `gridSize = 20`)
- **Recommended approach:** Refactor `ClassicSnake` to accept `columns` and `rows` in the constructor. Classic mode passes `(20, 20)`. Adaptive mode passes the calculated grid dimensions. `AdaptiveSnake` then simply instantiates the same class with different grid params — no separate file needed, just import `ClassicSnake` in `adaptive_game.dart`.
- If the logic diverges later, extract to a separate class at that point.

- [ ] **Step 2: Create adaptive_game.dart**

Similar to ClassicGame but with adaptive grid calculation:

```dart
@override
Future<void> onLoad() async {
  const double cellSize = 20.0;
  int columns = (size.x / cellSize).floor().clamp(10, 40);
  int rows = (size.y / cellSize).floor().clamp(10, 40);
  final gridOffset = Vector2(
    (size.x - columns * cellSize) / 2,
    (size.y - rows * cellSize) / 2,
  );
  // ... create components with columns, rows, cellSize, gridOffset
}
```

Handle Web resize:
- Wrap `GameWidget` in `ClipRect` (overflow hidden, no scrollbars)
- Use `LayoutBuilder` to detect size changes; if new size < initial grid pixel size, auto-pause and show centered "Window too small — please resize" overlay text
- On resize back to sufficient size, overlay disappears but game stays paused (user must press Resume)

- [ ] **Step 3: Create AdaptiveGamePage wrapper**

Wire up in `lib/main.dart` route `/snake/adaptive`. Same pattern as ClassicGamePage but uses AdaptiveGame.

- [ ] **Step 4: Manual test**

```bash
fvm flutter run -d chrome
```

Expected: Adaptive mode shows a grid that adapts to window size. Gameplay identical to Classic but with different grid dimensions.

- [ ] **Step 5: Commit**

```bash
git add lib/snake/adaptive/
git commit -m "feat: implement Adaptive Snake mode with dynamic grid sizing"
```

---

### Task 10: Free Snake Game

**Files:**
- Create: `lib/snake/free/free_snake.dart`
- Create: `lib/snake/free/free_game.dart`

- [ ] **Step 1: Create free_snake.dart**

Path-based smooth snake component:

Core data:
- `Vector2 headPosition` — current head position in pixels
- `double heading` — current angle in radians (0 = right)
- `int steerDirection` — -1 (left), 0 (straight), 1 (right)
- `List<Vector2> pathHistory` — trail of head positions
- `List<Vector2> segments` — body segment positions sampled from path
- `bool isDead`

Constants:
- `speed = 120.0` (pixels/second)
- `turnRate = pi` (180°/second)
- `segmentRadius = 8.0`
- `segmentSpacing = 18.0`

Key methods:
- `void steer(int direction)` — sets steerDirection (-1, 0, 1)
- `void update(double dt)` — if not dead/paused:
  - Update heading: `heading += steerDirection * turnRate * dt`
  - Move head: `headPosition += Vector2(cos(heading), sin(heading)) * speed * dt`
  - Add headPosition to pathHistory
  - Recalculate segment positions from pathHistory at segmentSpacing intervals
  - Check wall collision: circle-line (head center distance to wall < segmentRadius)
  - Check self-collision: head circle vs body circles (skip first 5)
- `void grow()` — increase segment count by 1
- `void render(Canvas canvas)` — draw each segment as a filled circle with gradient color

- [ ] **Step 2: Create free_game.dart**

FlameGame with:
- `HasKeyboardHandlerComponents` or `KeyboardEvents` mixin
- Key handling: Left/Right arrow → `snake.steer(-1/1)`, key up → `snake.steer(0)`
- Touch handling for Android: detect touch position relative to screen center, left half → steer(-1), right half → steer(1), touch end → steer(0)
- Boundary rendering: draw 2px #4A4A6A border rectangle (play area with 10px inset)
- Food collision: head center distance to food center < 16px (food center = food.position + Vector2(radius, radius))
- FreeFood component: `areaMin = Vector2(10, 10)`, `areaMax = Vector2(size.x - 10, size.y - 10)` (10px inset from edges)
- Track `gameTime` (gameplay time excluding paused time) same as Classic mode — `gameTime += dt` inside the `if (!isPaused && !isDead)` guard
- Pass formatted stats to `onGameOver` callback (same pattern as ClassicGame._handleDeath)

- [ ] **Step 3: Create FreeGamePage wrapper**

Wire up in `lib/main.dart` route `/snake/free`. Same GameScaffold pattern.

- [ ] **Step 4: Manual test**

```bash
fvm flutter run -d chrome
```

Expected: Free mode shows smooth snake movement. Hold left/right arrows to steer continuously. Eating food grows snake. Wall and self collision work. Death flash triggers game over.

- [ ] **Step 5: Commit**

```bash
git add lib/snake/free/
git commit -m "feat: implement Free Snake mode with smooth angle-based movement"
```

---

### Task 11: Android Input (Swipe & Touch)

**Files:**
- Modify: `lib/snake/classic/classic_game.dart`
- Modify: `lib/snake/adaptive/adaptive_game.dart`
- Modify: `lib/snake/free/free_game.dart`

- [ ] **Step 1: Add swipe detection to Classic and Adaptive games**

Use Flame's `PanDetector` or `DragCallbacks` mixin:
- Track `dragStartPosition` on pan start
- On pan update: if drag distance > 20px, calculate direction (compare dx vs dy magnitude)
- Call `snake.changeDirection(direction)`
- Only fire once per swipe (reset on pan end)

- [ ] **Step 2: Add touch-hold detection to Free game**

Use `TapCallbacks` or raw gesture detection:
- On touch down: check if touch.x < screenWidth/2 → steer(-1), else → steer(1)
- On touch up: steer(0)

- [ ] **Step 3: Test on Android emulator or device**

```bash
fvm flutter run
```

Expected: Swipe controls work for Classic/Adaptive. Touch-hold left/right works for Free mode.

- [ ] **Step 4: Commit**

```bash
git add lib/snake/
git commit -m "feat: add swipe and touch controls for Android"
```

---

### Task 12: Polish & Integration Test

**Files:**
- Various fixes across all files

- [ ] **Step 1: Verify complete navigation flow**

Test the full flow: Home → Snake → Mode Select → each mode → play → die → Game Over → Play Again → play again → die → Home

- [ ] **Step 2: Verify high scores persist**

Play Classic mode, score some points, die. Go back, re-enter Classic. Verify best score shows on mode selection page and in-game score bar.

- [ ] **Step 3: Test pause behavior**

- Press pause button → overlay appears
- Press Resume → game continues
- Press Quit → returns to home
- Switch browser tab → auto-pauses
- Press Android back → pauses (not exits)
- While paused, keyboard input is ignored

- [ ] **Step 4: Test grid/list toggle on home page**

Toggle between views, close browser, reopen → view preference persists.

- [ ] **Step 5: Build for web and verify**

```bash
fvm flutter build web --release --base-href "/mini-play/"
```

Expected: Build succeeds. Can serve locally and play all three modes.

- [ ] **Step 6: Commit any fixes**

```bash
git add -A
git commit -m "fix: polish and integration fixes for snake game"
```

- [ ] **Step 7: Push and tag release**

```bash
git push origin main
git tag v0.1.0
git push origin v0.1.0
```

Expected: CI builds Web + APK, deploys to GitHub Pages, creates GitHub Release with APK.
