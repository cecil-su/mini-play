# Snake Game Design

## Overview

First game in the mini-play collection. Classic snake game with three movement modes (Classic, Adaptive, Free), plus the shared infrastructure (home page, game scaffold, navigation, score system) that all future games will reuse.

## Scope

This spec covers two things:
1. **Shared infrastructure** — home page, game scaffold, score service, game over page
2. **Snake game** — three modes with distinct grid/movement mechanics

## Out of Scope (v1)

- Speed progression / difficulty ramping (v1 uses constant speed in all modes)
- Sound effects and haptic feedback
- Animations beyond death feedback

## Tech Stack

- Flutter 3.41.5 (FVM)
- Flame engine
- shared_preferences (view toggle, high scores)

### Dependencies to Add

```yaml
dependencies:
  flame: ^1.22.0
  shared_preferences: ^2.3.0
```

Exact versions to be verified against Flutter 3.41.5 compatibility at implementation time. If `flame: ^1.22.0` is incompatible, use the latest compatible version.

## Shared Infrastructure

### Routing

- Use hash-based routing (`/#/snake/classic`) for GitHub Pages compatibility
- Routes: `/` (home), `/snake` (mode selection), `/snake/classic`, `/snake/adaptive`, `/snake/free`
- Game Over is NOT a route — it is a full-screen overlay/page navigated to via `Navigator.push` with a `GameOverData` object (stats, game name, mode, replay callback). Direct browser access to `/#/game-over` is not possible since it doesn't exist as a route.

### Home Page

- **Grid view** (default): responsive column count (2 on mobile, 3-4 on web depending on width)
- **List view**: games grouped by phase, each entry shows name + description
- Toggle button in top toolbar (grid/list icons)
- View preference persisted via shared_preferences
- Implemented games: highlighted with accent border, tappable
- Unimplemented games: dimmed (opacity 0.4), not tappable
- Game metadata defined in a `GameRegistry` list (name, icon, description, phase, route, implemented flag, hasModePage flag)
- Games without modes: `route` points directly to game page, `hasModePage` = false
- Games with modes: `route` points to mode selection page, `hasModePage` = true

### Game Scaffold

Common wrapper used by all games:
- Top bar: back button (←), game title, pause button (⏸)
- Score bar: current score + best score
- Flame-to-Flutter score communication: FlameGame exposes a `ValueNotifier<int>` for score; GameScaffold listens to it for UI updates
- Provides callbacks: `onPause`, `onResume`, `onGameOver`
- Pause overlay: semi-transparent dark overlay with "Paused" text and "Resume" / "Quit" buttons
- Pause state ignores all game input (direction keys, swipes) — inputs are only processed when game is running
- Auto-pause: Web uses `visibilitychange` API (not focus), Android uses `AppLifecycleState`
- Android back button: triggers pause (shows pause overlay), not exit

### Game Over Page

Reusable result screen (navigated via `Navigator.push`, not a named route):
- Receives a `GameOverData` object: `{gameName, mode, stats: Map<String, String>, replayCallback}`
- Stats grid: renders stats from the map (e.g., {"Score": "12", "Best": "35", "Time": "1:23", "Length": "15"})
- Buttons: Play Again (calls replayCallback), Home (pops to root)
- Updates high score automatically via ScoreService

### Score Service

- Read/write high scores via shared_preferences
- Key format: `highscore_{game}_{mode}` (e.g., `highscore_snake_classic`)
- Games without modes use `default` as mode (e.g., `highscore_2048_default`)
- Methods: `getHighScore(game, mode)`, `saveHighScore(game, mode, score)`

### Navigation

```
HomePage → SnakeModePage → ClassicGame / AdaptiveGame / FreeGame
                                         ↓
                                    GameOverPage (push) → (Play Again) → Game
                                                        → (Home) → HomePage
```

## Snake Game

### Mode Selection Page

- Three mode cards, each showing: icon, mode name, description, best score
- Tapping a card enters that mode directly

### Three Modes

| Mode | Grid | Movement | Tick Rate | Description |
|------|------|----------|-----------|-------------|
| Classic | Fixed 20×20 | Grid-snapped, 4 directions | 200ms per tick | Traditional snake on a fixed board |
| Adaptive | Fixed cell size (20px), grid count varies by screen | Grid-snapped, 4 directions | 200ms per tick | Board adapts to screen — bigger screen = more space |
| Free | No grid | Smooth, angle-based turning | 16ms (60fps) | Snake moves freely, left/right to steer |

All modes use constant speed in v1 (no speed progression as snake grows).

### Controls

| Platform | Classic & Adaptive | Free |
|----------|-------------------|------|
| Web | Arrow keys / WASD (4 directions) | Left/Right arrow keys (hold to turn continuously) |
| Android | Swipe gesture (4 directions, min 20px swipe distance, detected on threshold exceeded) | Touch and hold left/right half of screen to turn continuously; release to go straight |

### Game Rules (all modes)

- Snake starts with length 3, positioned center of play area, **moving right**
- Free mode: initial heading is 0° (right)
- First food spawns in front of the snake head (right half of play area for initial rightward movement) to provide a good starting experience
- Subsequent food: random position, not on snake body
- Food spawn exclusion: grid modes — not on occupied cells; Free mode — min 32px (2 × (segment radius + food radius)) from any snake segment
- Eating food: snake grows by 1 segment, score +1, new food spawns randomly
- Collision with wall or self: death feedback (snake flashes red 3 times over 500ms), then game over screen
- No wrapping (hitting wall = death)
- Time tracking: gameplay time only (paused time excluded)

### Classic & Adaptive Mode Details

- Snake moves one cell per tick (200ms = 5 cells/second)
- Input buffer depth: 2 (allows queuing up to 2 direction changes per tick for quick corner turns)
- Cannot reverse direction (e.g., moving right, pressing left is ignored)
- Classic mode: 20×20 grid, cell size = floor(min(availableWidth, availableHeight) / 20) pixels, ensuring integer pixel alignment; remaining pixels become symmetric padding; play area is centered
- Adaptive mode: fixed 20px cell size, grid calculated once at game start, not recalculated on resize
- Adaptive mode: play area = screen minus top bar and score bar, cell count = floor(available width / 20px) × floor(available height / 20px), remaining pixels become symmetric padding
- Adaptive mode: maximum grid cap of 40×40 to prevent excessively large play areas
- Adaptive mode on Web resize: game area remains centered at initial grid size with clip (overflow hidden, no scrollbars); if window shrinks significantly, auto-pause and show "Window too small" message
- Grid background: subtle grid lines (#1e2a4a, 1px) to show cell boundaries, aligned to integer pixel cell boundaries

### Free Mode Details

- **Movement speed**: 120 pixels per second (delta-time based for frame-rate independence)
- **Turn rate**: 180°/second (hold left/right to turn continuously)
- **Segment radius**: 8px (circular segments)
- **Segment spacing**: 18px center-to-center along the movement path
- **Wall collision**: circle-line intersection — head center distance to wall edge < 8px triggers death
- **Self-collision**: check head circle against all body segment circles (skip first 5 segments to avoid immediate self-hit); circle-circle intersection (distance between centers < sum of radii)
- **Food radius**: 8px, collision when head center is within 16px of food center
- **Play area**: game area rectangle with 10px inset from edges
- **Boundary rendering**: 2px solid border (#4a4a6a) around the play area so players can see the death boundary
- **Path history**: store position trail, body segments sample positions at fixed intervals along the trail

### Visual Design

- **Background**: #1a1a2e (dark navy)
- **Game area**: #16213e (slightly lighter)
- **Snake head**: #4ecca3 (teal green)
- **Snake body**: gradient from #4ecca3 (head) to #0e8263 (tail)
- **Food**: #e84545 (red)
- **Score text**: #4ecca3 (current), #f0c040 (best)
- **Death flash**: snake turns #e84545 (red), flashes 3 times over 500ms
- Classic/Adaptive: square blocks with 2px border-radius
- Free mode: circular segments connected smoothly
- Free mode boundary: 2px solid #4a4a6a border

### Game Over Screen

Stats displayed:
- Score (food eaten count)
- Best score (per mode)
- Time elapsed (mm:ss, gameplay time only)
- Snake length (initial 3 + food eaten)

Actions:
- Play Again → restart same mode
- Home → return to home page

## File Structure

```
lib/
├── main.dart                          # App entry, hash-based route setup
├── home/
│   ├── home_page.dart                 # Home page with grid/list toggle
│   ├── game_card.dart                 # Game card widget
│   └── game_registry.dart             # Game metadata list (with hasModePage flag)
├── shared/
│   ├── game_scaffold.dart             # Common game wrapper (pause, back, score via ValueNotifier)
│   ├── game_over_page.dart            # Reusable game over screen (receives GameOverData)
│   ├── game_over_data.dart            # Data class for game over params
│   └── score_service.dart             # High score persistence
├── snake/
│   ├── snake_mode_page.dart           # Mode selection page
│   ├── classic/
│   │   ├── classic_game.dart          # Classic mode FlameGame
│   │   └── classic_snake.dart         # Grid-based snake component
│   ├── adaptive/
│   │   ├── adaptive_game.dart         # Adaptive mode FlameGame
│   │   └── adaptive_snake.dart        # Grid-based snake (reuses classic logic, different grid calc)
│   ├── free/
│   │   ├── free_game.dart             # Free mode FlameGame
│   │   └── free_snake.dart            # Path-based smooth snake component
│   └── components/
│       ├── food_component.dart        # Abstract base with GridFood and FreeFood subclasses
│       └── grid_background.dart       # Grid line rendering (Classic/Adaptive only, #1e2a4a 1px lines)
```

### Design principles

- `home/` and `shared/` are reused by all future games
- Each game gets its own directory (`lib/snake/`, later `lib/2048/`, etc.)
- Grid-based snake (Classic/Adaptive) and Free snake have separate component classes — fundamentally different data models (grid coords vs. path history)
- `adaptive_snake.dart` reuses classic grid logic but with different grid calculation
- `food_component.dart` uses abstract base + subclasses (`GridFood`, `FreeFood`) to avoid mixing collision/rendering logic
- Flame-to-Flutter communication via `ValueNotifier` (score, game state)
- Pause state blocks all game input processing
- Small, focused files — one responsibility per file
