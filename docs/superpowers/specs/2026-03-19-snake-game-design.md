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

## Shared Infrastructure

### Home Page

- **Grid view** (default): 3-column card grid, each game is a card with icon + name
- **List view**: games grouped by phase, each entry shows name + description
- Toggle button in top toolbar (grid/list icons)
- View preference persisted via shared_preferences
- Implemented games: highlighted with accent border, tappable
- Unimplemented games: dimmed (opacity 0.4), not tappable

### Game Scaffold

Common wrapper used by all games:
- Top bar: back button (←), game title, pause button (⏸)
- Score bar: current score + best score
- Provides callbacks: `onPause`, `onResume`, `onGameOver`
- Manages pause overlay

### Game Over Page

Reusable result screen:
- Stats grid: Score, Best Score, Time, Food Eaten (game-specific stats passed as parameters)
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

| Mode | Grid | Movement | Speed | Description |
|------|------|----------|-------|-------------|
| Classic | Fixed 20×20 | Grid-snapped, 4 directions | Constant | Traditional snake on a fixed board |
| Adaptive | Fixed cell size (20px), grid count varies by screen | Grid-snapped, 4 directions | Constant | Board adapts to screen — bigger screen = more space |
| Free | No grid | Smooth, angle-based turning | Constant | Snake moves freely, left/right to steer |

### Controls

| Platform | Classic & Adaptive | Free |
|----------|-------------------|------|
| Web | Arrow keys / WASD (4 directions) | Left/Right arrow to steer angle |
| Android | Swipe gesture (4 directions) | Swipe left/right to steer angle |

### Game Rules (all modes)

- Snake starts with length 3, positioned center of play area
- Eating food: snake grows by 1 segment, score +1, new food spawns randomly
- Food never spawns on the snake body
- Collision with wall or self: game over
- No wrapping (hitting wall = death)

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
- Score (total food eaten)
- Best score (per mode)
- Time elapsed (mm:ss)
- Food eaten count

Actions:
- Play Again → restart same mode
- Home → return to home page

## File Structure

```
lib/
├── main.dart                          # App entry, route setup
├── home/
│   ├── home_page.dart                 # Home page with grid/list toggle
│   └── game_card.dart                 # Game card widget
├── shared/
│   ├── game_scaffold.dart             # Common game wrapper
│   ├── game_over_page.dart            # Reusable game over screen
│   └── score_service.dart             # High score persistence
├── snake/
│   ├── snake_mode_page.dart           # Mode selection page
│   ├── classic/
│   │   └── classic_game.dart          # Classic mode FlameGame
│   ├── adaptive/
│   │   └── adaptive_game.dart         # Adaptive mode FlameGame
│   ├── free/
│   │   └── free_game.dart             # Free mode FlameGame
│   └── components/
│       ├── snake_component.dart       # Snake rendering and movement
│       ├── food_component.dart        # Food spawning and rendering
│       └── grid_background.dart       # Grid background rendering
```

### Design principles

- `home/` and `shared/` are reused by all future games
- Each game gets its own directory (`lib/snake/`, later `lib/2048/`, etc.)
- Three modes share components but have independent FlameGame classes
- Small, focused files — one responsibility per file
