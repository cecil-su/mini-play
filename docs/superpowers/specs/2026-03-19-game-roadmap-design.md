# Mini-Play Game Roadmap Design

## Overview

A Flutter mini-game collection app built with the Flame engine. 18 games organized in 6 phases of increasing complexity, designed to progressively explore AI-assisted game development capabilities.

## Goals

- Build a fun, playable collection of mini-games
- Explore the boundaries of AI-assisted game development
- Share with friends — games should be polished and enjoyable
- Progressively challenge AI capabilities from simple to complex

## Tech Stack

- **Flutter 3.41.5** (pinned via FVM)
- **Flame engine** — unified game engine for all games (added to pubspec.yaml when first game is implemented)
- **Forge2D** — physics engine (added when needed, e.g., Draw Physics, Breakout)
- **shared_preferences** — local persistence for view toggle preference and high scores

## Art Strategy

| Phase | Approach |
|-------|----------|
| Phase 1-2 | Geometric shapes + color schemes (zero art dependency) |
| Phase 3 | Geometric + simple sprites / Kenney free assets |
| Phase 4 | Geometric shapes (algorithm-focused games, no art needed) |
| Phase 5 | Geometric + particle effects + AI-generated art |
| Phase 6 | Kenney asset packs + AI-generated art |

Art sources:
- **Kenney.nl** — high-quality free assets, consistent style
- **itch.io** — free 2D game asset packs (CC0)
- **OpenGameArt.org** — open-source game assets
- **AI image generation** — for experimental/custom sprites

## Home Page Design

### Default: Grid View
- Card grid layout, each game is a card with icon + name
- Colored geometric icons as placeholders initially
- Responsive: adjusts column count for web vs mobile

### Alternative: List View
- Games grouped by phase/category
- Each entry shows name + brief description

### View Toggle
- Toggle button in top toolbar (grid icon / list icon)
- User preference persisted locally (shared_preferences)
- Default: grid mode

## Game Roadmap

### Phase 1: Flame Basics (Geometric Style)

| # | Game | Key Learning | Description |
|---|------|-------------|-------------|
| 1 | Snake | Game loop, collision, grid movement | Control a snake to eat food and grow longer. Hit yourself or the wall and it's game over. |
| 2 | 2048 | Gesture system, tile animation, merge algorithm | Slide tiles on a 4x4 grid to merge matching numbers. Goal: reach 2048. |
| 3 | Minesweeper | Recursive algorithm, long-press interaction, timer | Click to reveal cells, numbers hint at nearby mines. Flag all mines to win. |

### Phase 2: Deeper Mechanics (Geometric Style)

| # | Game | Key Learning | Description |
|---|------|-------------|-------------|
| 4 | Tetris | Rotation algorithm, line clear, speed progression | Falling blocks of various shapes. Rotate and place to fill complete rows. |
| 5 | Match-3 | Grid matching, chain combos, drop animation | Swap adjacent tiles to match 3+ of the same kind. Chain reactions for bonus points. |
| 6 | Sokoban | Level design, undo system, solution detection | Push boxes onto target positions in a confined space. Can push, not pull. |

### Phase 3: Physics & Real-time (Geometric + Simple Assets)

| # | Game | Key Learning | Description |
|---|------|-------------|-------------|
| 7 | Flappy Bird | Gravity simulation, infinite scroll, physics collision | Tap to fly a bird through gaps between pipes. Don't hit anything. |
| 8 | Breakout | Physics bounce, power-ups, level design | Move a paddle to bounce a ball and break bricks above. Power-ups drop from broken bricks. |
| 9 | Fruit Catcher | Random generation, difficulty curve, physics fall | Fruits fall from the sky — move your basket to catch them. Avoid bombs. |

### Phase 4: AI & Strategy (Geometric Style)

| # | Game | Key Learning | Description |
|---|------|-------------|-------------|
| 10 | Sudoku | Generation algorithm, difficulty control, hint system | Fill a 9x9 grid so every row, column, and box has digits 1-9 without repeating. |
| 11 | Reversi | AI opponent (Minimax), flip animation | Place pieces to flip opponent's pieces between yours. Most pieces wins. |
| 12 | Game of Life | Large-scale grid computation, pan & zoom | Cellular automaton simulation — set initial state and watch complex patterns emerge. Not a traditional game, but a fascinating interactive toy. |

### Phase 5: Creative Experiments (Mixed Assets)

| # | Game | Key Learning | Description |
|---|------|-------------|-------------|
| 13 | Doodle Jump | Infinite vertical scroll, gyroscope/keyboard, random platforms | A character bounces upward on platforms. Tilt device (Android) or arrow keys (Web) to move. Don't fall. |
| 14 | Draw Physics | Free drawing, Forge2D physics engine | Draw lines on screen that become physical objects. Guide a ball to the goal. |
| 15 | Rhythm Game | Audio sync, beat detection, chart system | Notes fall from above — tap in rhythm to score. Miss and your combo breaks. Note: web audio latency may affect precision; Android is the primary platform for this game. |

### Phase 6: Push the Limits (Kenney/AI Assets)

| # | Game | Key Learning | Description |
|---|------|-------------|-------------|
| 16 | Shoot 'em up | Mass entity management, bullet patterns, Boss AI | Pilot a ship, dodge bullet patterns, defeat waves of enemies and bosses. |
| 17 | Tower Defense | Pathfinding, economy system, wave design | Enemies march along a path. Place towers to stop them. Balance spending and upgrading. |
| 18 | Roguelike Dungeon | Random map generation, combat system, item system | Explore randomly generated dungeons, fight enemies, collect loot, descend deeper. |

## Ordering Rationale

- **Phase 1-2** (6 games): Zero art dependency, focus on learning Flame fundamentals
- **Phase 3** (3 games): Introduce physics and real-time interaction
- **Phase 4** (3 games): Explore algorithms and AI opponents
- **Phase 5** (3 games): Creative and experimental directions
- **Phase 6** (3 games): Full complexity, true test of AI-assisted development limits

## Shared Infrastructure

Each game is a separate page/route within the single Flutter app. Each game manages its own state internally; shared_preferences handles persistence (scores, settings).

Shared components:

- **Home page** — game list with grid/list toggle
- **Game scaffold** — common wrapper (back button, pause, score display)
- **Score system** — local high scores per game (shared_preferences)
- **Navigation** — route-based navigation from home to each game

## Per-Game Development Cycle

Each game follows its own spec → plan → implementation cycle:
1. Brainstorm and write game-specific design spec
2. Create implementation plan
3. Implement, test, commit
4. Tag and release when a meaningful batch is ready
