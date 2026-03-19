# Snake Game Design

## Overview

First game in the mini-play collection. Classic snake game with three movement modes (Classic, Adaptive, Free), plus the shared infrastructure (home page, game scaffold, navigation, score system) that all future games will reuse.

## Scope

This spec covers two things:
1. **Shared infrastructure** — home page, game scaffold, score service, game over page
2. **Snake game** — three modes with distinct grid/movement mechanics

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

Exact versions may be adjusted for Flutter 3.41.5 compatibility at implementation time.

## Shared Infrastructure

### Home Page

- **Grid view** (default): responsive column count (2 on mobile, 3-4 on web depending on width)
- **List view**: games grouped by phase, each entry shows name + description
- Toggle button in top toolbar (grid/list icons)
- View preference persisted via shared_preferences
- Implemented games: highlighted with accent border, tappable
- Unimplemented games: dimmed (opacity 0.4), not tappable
- Game metadata defined in a `GameRegistry` list (name, icon, description, phase, route, implemented flag)

### Game Scaffold

Common wrapper used by all games:
- Top bar: back button (←), game title, pause button (⏸)
- Score bar: current score + best score
- Provides callbacks: `onPause`, `onResume`, `onGameOver`
- Pause overlay: semi-transparent dark overlay with "Paused" text and "Resume" / "Quit" buttons
- Auto-pause when app goes to background (Android) or tab loses focus (Web)

### Game Over Page

Reusable result screen:
- Stats grid: game-specific stats passed as key-value pairs (e.g., Score, Best, Time, Length)
- Buttons: Play Again, Home
- Updates high score automatically

### Score Service

- Read/write high scores via shared_preferences
- Key format: `highscore_{game}_{mode}` (e.g., `highscore_snake_classic`)
- Methods: `getHighScore(game, mode)`, `saveHighScore(game, mode, score)`

### Navigation

```
HomePage → SnakeModePage → ClassicGame / AdaptiveGame / FreeGame
                                         ↓
                                    GameOverPage → (Play Again) → Game
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

### Controls

| Platform | Classic & Adaptive | Free |
|----------|-------------------|------|
| Web | Arrow keys / WASD (4 directions) | Left/Right arrow keys (hold to turn continuously) |
| Android | Swipe gesture (4 directions, min 20px swipe distance, detected on threshold exceeded) | Tap left/right half of screen to steer |

### Game Rules (all modes)

- Snake starts with length 3, positioned center of play area, **moving right**
- Free mode: initial heading is 0° (right)
- Eating food: snake grows by 1 segment, score +1, new food spawns randomly
- Food never spawns on the snake body (grid modes: not on occupied cells; Free mode: min 2× segment radius distance from any snake segment)
- Collision with wall or self: game over
- No wrapping (hitting wall = death)
- Time tracking: gameplay time only (paused time excluded)

### Classic & Adaptive Mode Details

- Snake moves one cell per tick (200ms = 5 cells/second)
- Input is buffered: pressing a direction queues it for the next tick
- Cannot reverse direction (e.g., moving right, pressing left is ignored)
- Adaptive mode: grid calculated once at game start, not recalculated on resize
- Adaptive mode: play area = screen minus top bar and score bar, cell count = floor(available width / 20px) × floor(available height / 20px), remaining pixels become symmetric padding
- Adaptive mode: maximum grid cap of 40×40 to prevent excessively large play areas

### Free Mode Details

- **Movement speed**: 120 pixels per second
- **Turn rate**: 180°/second (hold left/right to turn continuously)
- **Segment radius**: 8px (circular segments)
- **Segment spacing**: 18px center-to-center along the movement path
- **Head collision radius**: 8px (circle-circle intersection with wall boundaries and other segments)
- **Food radius**: 8px, collision when head center is within 16px of food center
- **Play area**: game area rectangle with 10px inset from edges
- **Path history**: store position trail, body segments sample positions at fixed intervals along the trail
- **Self-collision**: check head circle against all body segment circles (skip first 5 segments to avoid immediate self-hit)

### Visual Design

- **Background**: #1a1a2e (dark navy)
- **Game area**: #16213e (slightly lighter)
- **Snake head**: #4ecca3 (teal green)
- **Snake body**: gradient from #4ecca3 (head) to #0e8263 (tail)
- **Food**: #e84545 (red)
- **Score text**: #4ecca3 (current), #f0c040 (best)
- Classic/Adaptive: square blocks with 2px border-radius
- Free mode: circular segments connected smoothly

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
├── main.dart                          # App entry, route setup
├── home/
│   ├── home_page.dart                 # Home page with grid/list toggle
│   ├── game_card.dart                 # Game card widget
│   └── game_registry.dart             # Game metadata list
├── shared/
│   ├── game_scaffold.dart             # Common game wrapper
│   ├── game_over_page.dart            # Reusable game over screen
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
│       ├── food_component.dart        # Food spawning and rendering
│       └── grid_background.dart       # Grid background rendering (Classic/Adaptive only)
```

### Design principles

- `home/` and `shared/` are reused by all future games
- Each game gets its own directory (`lib/snake/`, later `lib/2048/`, etc.)
- Grid-based snake (Classic/Adaptive) and Free snake have separate component classes — fundamentally different data models (grid coords vs. path history)
- `adaptive_snake.dart` reuses classic grid logic but with different grid calculation
- `components/` contains truly shared pieces (food, grid background)
- Small, focused files — one responsibility per file
