# Breakout Game Design

## Overview

A classic Breakout game for the mini-play project. The player controls a paddle at the bottom of the screen to bounce a ball upward, breaking bricks arranged in rows. Bricks have varying durability, and power-ups drop from destroyed bricks to add variety.

**Tech stack:** Pure Flutter + Timer.periodic + CustomPaint (same pattern as Tetris).

## Game Modes

Three modes, consistent with the existing mode pattern:

| Parameter | Classic | Hard | Endless |
|-----------|---------|------|---------|
| Lives | 3 | 1 | 3 |
| Ball speed | 0.6 | 0.9 | 0.6 (+ 0.05/round) |
| Paddle width | 0.15 | 0.105 (0.7x) | 0.15 |
| Brick rows | 5 | 6 | 4 |
| Brick cols | 8 | 8 | 8 |
| Max brick HP | 2 | 3 | 2 |
| Power-up drop rate | 20% | 15% | 25% |
| Score multiplier | 1.0x | 1.5x | 1.0x (x round number) |
| End condition | Clear all bricks | Clear all bricks | All lives lost |
| Negative power-ups | Yes | No | Yes |

### Brick HP Distribution Per Round

- **Classic:** 70% HP 1, 30% HP 2
- **Hard:** 40% HP 1, 40% HP 2, 20% HP 3
- **Endless:** 70% HP 1, 30% HP 2

## Architecture and File Structure

```
lib/breakout/
  breakout_mode_page.dart       # Mode selection (classic/hard/endless)
  breakout_page.dart            # Game page (StatefulWidget, Timer-driven)
  breakout_game.dart            # Core game logic (state, physics, collisions)
  breakout_painter.dart         # CustomPainter for unified rendering
  breakout_config.dart          # Mode parameter configurations
  breakout_models.dart          # Data models (Ball, Paddle, Brick, PowerUp)
  breakout_collision.dart       # Collision detection (circle-rect, boundaries)
  breakout_colors.dart          # Brick/power-up color definitions
```

### Data Flow

```
Timer.periodic(16ms ~ 60fps)
  -> BreakoutGame.update(dt)
      -> Move balls (position += velocity x dt)
      -> Move power-ups (fall downward)
      -> Collision detection (walls, paddle, bricks)
      -> Handle brick destruction, power-up generation
      -> Check lives / level clear / game over
  -> setState() -> CustomPaint repaint
  -> scoreNotifier updates top bar score
```

### Integration with Shared Infrastructure

- `GameScaffold`: wraps game UI, provides top bar (score, pause)
- `ScoreService`: stores high scores, key format `highscore_breakout_{mode}`
- `GameOverPage`: shows results with stats
- `GameModeCard`: used on mode selection page
- Routes: `/breakout` -> mode page, `/breakout/play` -> game page (receives mode enum)
- `game_registry.dart`: add Breakout entry

## Data Models

```dart
enum BreakoutMode { classic, hard, endless }

class Ball {
  double x, y;          // Center position (normalized 0-1)
  double vx, vy;        // Velocity vector
  double radius;        // Radius
  bool isPenetrating;   // Penetration state
}

class Paddle {
  double x, y;          // Center position
  double width, height; // Dimensions
}

class Brick {
  int row, col;         // Grid position
  int hp;               // Current durability (0 = destroyed)
  int maxHp;            // Max durability (1-3)
}

enum PowerUpType { widen, multiBall, penetrate, extraLife, shrink }

class PowerUp {
  double x, y;          // Position
  PowerUpType type;     // Type
  double fallSpeed;     // Fall speed
}
```

### Coordinate System

- Normalized coordinates (0-1), multiplied by actual canvas size when rendering
- Benefits: adapts to any screen ratio, physics calculations are resolution-independent
- Bricks use row/col grid positioning, converted to pixel positions at render time

### Brick Durability and Color Mapping

| HP | Color | Score |
|----|-------|-------|
| 1 (full) | Green | 10 |
| 2 (full) | Orange | 20 |
| 2 (damaged) | Yellow | - |
| 3 (full) | Red | 30 |
| 3 (damaged 1) | Orange | - |
| 3 (damaged 2) | Yellow | - |

Score per brick = full-HP base score value.

## Physics and Collision

### Ball Movement

- Per frame: `x += vx * dt`, `y += vy * dt`
- Initial launch angle: random -30 to +30 degrees (upward)
- Ball speed is scalar `speed`, vx/vy maintain direction vector, `vx^2 + vy^2 = speed^2`

### Collision Detection (per frame, in priority order)

1. **Left/right walls:** `x - radius <= 0` or `x + radius >= 1` -> `vx = -vx`
2. **Top wall:** `y - radius <= 0` -> `vy = -vy`
3. **Bottom out-of-bounds:** `y + radius >= 1` -> lose life, reset ball above paddle
4. **Paddle collision:** circle-rect detection -> adjust bounce angle based on hit position
   - Hit paddle center: near-vertical bounce
   - Hit paddle edge: wide-angle bounce (max 60 degrees)
   - Formula: `bounce angle = (hitX - paddleCenter) / (paddleWidth/2) * 60 degrees`
5. **Brick collision:** circle-rect detection -> determine which face was hit, flip corresponding velocity component
   - Penetrating ball: do not flip velocity, just reduce HP and continue

### Paddle Movement

- Touch/mouse: paddle center X = input point X (clamped within boundaries)
- Keyboard: left/right arrows move paddle at fixed speed, also A/D keys

### Power-Up Falling

- Spawns at center of destroyed brick
- Falls downward at constant speed
- Paddle collision (rect-rect) -> activate effect
- Falls past bottom boundary -> removed

### Multi-Ball

- `List<Ball>` manages all active balls
- Multi-ball power-up: duplicate current ball x2, offset angles by +/-20 degrees
- All balls move and collide independently
- Last ball out of bounds -> lose life

## Power-Up System

### Generation Rules

- Generated when a brick is destroyed (HP reaches 0), based on drop chance
- Max 3 power-ups on screen simultaneously
- Type is random, positive/negative weight ratio 4:1

### Power-Up Details

| Power-Up | Color | Effect | Duration |
|----------|-------|--------|----------|
| Widen paddle | Blue | Paddle width x2 | 10 seconds |
| Multi-ball | Green | Current ball splits into 3 | Permanent (until balls exit) |
| Penetrating ball | Purple | Ball passes through bricks without bouncing | 5 seconds |
| Extra life | Red | +1 life | Instant |
| Shrink paddle | Gray | Paddle width x0.5 | 8 seconds |

### Conflict Resolution

- Widen + Shrink: later one overrides, timer resets
- Same power-up repeated: refresh duration, no stacking
- Penetrating ball applies to all active balls

### Power-Up Visuals

- Rendered as small rounded rectangles with corresponding color
- Center displays simple icon symbol drawn via Canvas

## Scoring

- Base score = brick full-HP value (10/20/30) x scoreMultiplier
- Endless mode: current round x base score (round 1 x1, round 2 x2 ...)

### GameOver Stats

- Final score
- Bricks destroyed count
- Survival time
- Endless mode additionally shows: rounds completed

## Input Handling

### Touch/Mouse

- `GestureDetector` wraps game area
- `onPanUpdate` / `onPanStart`: take touch X coordinate, convert to normalized coordinate, assign to `paddle.x`
- Clamp paddle within left/right boundaries

### Keyboard

- `RawKeyboardListener` listens for left/right arrows + A/D keys
- Hold to move paddle each frame, speed matches ball speed

### Ball Launch

- After game start or losing a life, ball rests on top of paddle, follows paddle movement
- Tap screen / press Space -> launch ball (random offset angle)
- Gives player buffer time before ball is in play

### Pause

- `GameScaffold` provides pause button, sets `isPaused` flag
- When `isPaused`, Timer callback skips `update()`
- App background auto-pauses (built into `GameScaffold`)
- All input ignored during pause

## Rendering (CustomPainter)

### Draw Order (bottom to top)

1. **Background** - dark solid color (#1a1a2e)
2. **Bricks** - rounded rectangles, color mapped by HP, 2px spacing between bricks
3. **Power-ups** - small rounded rectangles + center symbol text, with corresponding color
4. **Balls** - filled circles, white; purple with slight glow when penetrating
5. **Paddle** - rounded rectangle, light blue; color changes when widened/shrunk
6. **HUD overlay** - bottom-left shows remaining lives (heart icons), active power-up timers

### Visual Feedback

- Brick hit: no animation (keep it simple), immediate color change or disappear
- Power-up activated: paddle color briefly flashes
- Life lost: brief 0.5s pause to let player register what happened
- Penetrating ball: ball color turns purple

### Adaptive Layout

- Game area maintains fixed aspect ratio (3:4), centered on screen
- Normalized coordinates -> multiply by actual canvas size
- Works in both landscape and portrait, portrait is optimal

## Mode Configuration

```dart
class BreakoutConfig {
  final int lives;
  final double ballSpeed;        // Normalized speed (canvas proportion per second)
  final double paddleWidth;      // Normalized width
  final int brickRows;
  final int brickCols = 8;      // Fixed 8 columns
  final int maxBrickHp;         // Max brick durability
  final double powerUpChance;   // Drop probability
  final double speedIncrement;  // Endless mode speed increase per round
  final double scoreMultiplier; // Score multiplier
}
```
