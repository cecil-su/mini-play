# Breakout Game Design

## Overview

A classic Breakout game for the mini-play project. The player controls a paddle at the bottom of the screen to bounce a ball upward, breaking bricks arranged in rows. Bricks have varying durability, and power-ups drop from destroyed bricks to add variety.

**Tech stack:** Pure Flutter + Ticker (vsync-driven) + CustomPaint.

## Game Modes

Three modes, consistent with the existing mode pattern:

| Parameter | Classic | Hard | Endless |
|-----------|---------|------|---------|
| Lives | 3 | 1 | 3 |
| Ball speed | 0.6 | 0.9 | 0.6 (diminishing increment per round) |
| Paddle width | 0.15 | 0.15 | 0.15 |
| Brick rows | 5 | 6 | 4 |
| Brick cols | 8 | 8 | 8 |
| Max brick HP | 2 | 2 | 2 |
| Power-up drop rate | 20% | 15% | 25% |
| Score multiplier | 1.0x | 1.5x | 1.0x (capped round multiplier) |
| End condition | Clear all bricks | Clear all bricks | All lives lost |
| Negative power-ups | Yes | Yes | Yes |

**Hard mode design philosophy:** Two penalties only -- 1 life and 1.5x ball speed. Paddle width and brick HP stay at standard values. This makes the mode challenging but learnable: every miss is fatal, but the player has fair tools to avoid it. Negative power-ups remain in the pool to create tension.

### Brick HP Distribution Per Round (row-weighted)

Brick HP is weighted by row position -- higher-HP bricks tend to appear in upper rows where they are naturally harder to reach, creating a consistent difficulty curve:

- **Classic:**
  - Top 2 rows: 50% HP 1, 50% HP 2
  - Bottom 3 rows: 85% HP 1, 15% HP 2
- **Hard:**
  - Top 2 rows: 50% HP 1, 50% HP 2
  - Bottom 4 rows: 85% HP 1, 15% HP 2
- **Endless:**
  - Top 2 rows: 50% HP 1, 50% HP 2
  - Bottom 2 rows: 85% HP 1, 15% HP 2

### Endless Mode Round Transitions

When all bricks are cleared in Endless mode:
1. Ball is removed, new ball placed on paddle (waiting for launch)
2. Round counter increments, ball speed increases by diminishing increment: `increment = 0.05 / (1 + 0.1 * round)`, capped at max speed 1.2
3. New brick grid is generated
4. Active timed power-ups (widen, shrink, penetrate) are cleared; extra balls from multi-ball are removed
5. Lives and score carry over
6. Brief 1-second "Round X" text overlay showing previous round stats (bricks destroyed, score gained) before player launches ball

### Life Loss Behavior

When the last ball exits the bottom:
1. Life counter decrements
2. Brief 1.0-second pause with screen flash effect to let player register the loss
3. Active timed power-ups (widen, shrink, penetrate) **persist** through life loss (resetting would be double penalty)
4. New ball placed on paddle, waiting for launch
5. If lives reach 0: game over

### Win/Loss Titles

- Classic/Hard: clear all bricks -> `GameOverData(title: "You Win!")` (green victory text)
- Classic/Hard: lose all lives -> `GameOverData(title: null)` (default "Game Over")
- Endless: always `GameOverData(title: null)` (default "Game Over")

### GameOverData Construction

```dart
GameOverData(
  gameName: 'Breakout',
  mode: mode.name,          // 'classic', 'hard', 'endless'
  title: hasWon ? 'You Win!' : null,
  stats: {
    'Score': score,
    'Bricks': bricksDestroyed,
    'Time': formatTime(survivalSeconds),
    if (mode == BreakoutMode.endless) 'Rounds': roundsCompleted,
  },
  replayCallback: _replay,
  actions: [
    GameOverAction(label: 'Play Again', onPressed: _replay, isPrimary: true),
    GameOverAction(label: 'Choose Mode', onPressed: () => Navigator.pop(context)),
  ],
)
```

## Architecture and File Structure

```
lib/breakout/
  breakout_mode_page.dart       # Mode selection (classic/hard/endless)
  breakout_page.dart            # Game page (StatefulWidget, Ticker-driven)
  breakout_game.dart            # Core game logic (state, physics, collisions)
  breakout_painter.dart         # CustomPainter for unified rendering
  breakout_config.dart          # Mode parameter configurations + BreakoutMode enum
  breakout_models.dart          # Data models (Ball, Paddle, Brick, PowerUp)
  breakout_collision.dart       # Collision detection (circle-rect, boundaries, overlap resolution)
  breakout_colors.dart          # Brick/power-up color definitions
```

### Data Flow

```
Ticker (vsync-synced, provides actual elapsed Duration)
  -> _onTick(elapsed)
      -> dt = (elapsed - lastElapsed).inMicroseconds / 1e6
      -> dt = min(dt, 0.033)   // clamp to 2-frame max, prevents teleportation
      -> if (!isPaused) game.update(dt)
          -> Move balls (position += velocity x dt)
          -> Move power-ups (fall downward)
          -> Collision detection (walls, paddle, bricks) with overlap resolution
          -> Handle brick destruction, power-up generation
          -> Check lives / level clear / game over
      -> _paintVersion++
      -> setState() -> CustomPaint repaint (only when paintVersion changes)
      -> scoreNotifier updates top bar score
```

### Integration with Shared Infrastructure

- `GameScaffold`: wraps game UI, provides top bar (score, pause)
- `ScoreService`: stores high scores, key format `highscore_breakout_{mode.name}` (uses enum `.name` property)
- `GameOverPage`: shows results with stats and actions (see GameOverData Construction above)
- `GameModeCard`: used on mode selection page
- Routes: `/breakout` -> mode page, `/breakout/play` -> game page
  - In `onGenerateRoute`: `final mode = settings.arguments as BreakoutMode? ?? BreakoutMode.classic`
  - `main.dart` imports `BreakoutMode` from `breakout/breakout_config.dart`
- `game_registry.dart`: add Breakout entry (phase: 5)

## Data Models

```dart
enum BreakoutMode { classic, hard, endless }

class Ball {
  double x, y;          // Center position (height-normalized coordinates)
  double vx, vy;        // Velocity vector
  double radius;        // Radius (height-normalized)
  bool isPenetrating;   // Penetration state
  int penetrateHits;    // Remaining penetration hits (resets on activation)
}

class Paddle {
  double x, y;          // Center position
  double baseWidth;     // Original width (before power-ups)
  double width, height; // Current dimensions
}

class Brick {
  int row, col;         // Grid position
  int hp;               // Current durability (0 = destroyed)
  int maxHp;            // Max durability (1-2)
  bool hitThisFrame;    // Flag for batch damage processing (multi-ball)
}

enum PowerUpType { widen, multiBall, penetrate, extraLife, shrink }

class PowerUp {
  double x, y;          // Position
  PowerUpType type;     // Type
  double fallSpeed;     // Fall speed
}
```

### Coordinate System (Height-Normalized)

- **Single-axis normalization based on canvas height**: Y ranges from 0 (top) to 1 (bottom), X ranges from 0 to `aspectRatio` (0.75 for 3:4 canvas)
- This ensures physics are isotropic: circles render as circles, speed is uniform in all directions
- Ball radius, paddle width, brick dimensions -- all expressed in height-normalized units
- Walls: left at x=0, right at x=0.75, top at y=0, bottom at y=1
- Bricks use row/col grid positioning, converted to height-normalized coordinates
- At render time: multiply by canvas height to get pixel coordinates (both x and y use the same scale factor)

### Brick Durability and Color Mapping

| HP | Color | Score |
|----|-------|-------|
| 1 (full) | Green | 10 |
| 2 (full) | Orange | 20 |
| 2 (damaged) | Yellow | - |

Score per brick = full-HP base score value.

## Physics and Collision

### Ball Movement

- Per frame: `x += vx * dt`, `y += vy * dt`
- dt is clamped: `dt = min(wallClockDt, 0.033)` to prevent teleportation on frame spikes
- Initial launch angle: random -30 to +30 degrees (upward)
- Ball speed is scalar `speed` (magnitude of velocity vector, in canvas-height units per second), `vx^2 + vy^2 = speed^2`
- Example: speed 0.6 means the ball traverses 60% of the canvas height per second (~1.67s to cross vertically)
- **Max speed cap: 1.2** (prevents tunneling in Endless mode high rounds)
- **Tunneling prevention:** If per-frame displacement (`speed * dt`) exceeds ball radius, subdivide the frame into smaller steps where each step moves at most `radius` distance

### Collision Detection (per frame, per ball)

**Rule: process at most one collision per ball per frame, prioritized by time-of-impact.** After a collision response (velocity change + position correction), skip remaining checks for that ball this frame.

1. **Left/right walls:** `x - radius <= 0` or `x + radius >= 0.75` -> `vx = -vx`, **reposition ball to contact surface** (`x = radius` or `x = 0.75 - radius`)
2. **Top wall:** `y - radius <= 0` -> `vy = -vy`, **reposition** `y = radius`
3. **Bottom out-of-bounds:** `y + radius >= 1` -> lose life, reset ball above paddle
4. **Paddle collision:** circle-rect detection -> adjust bounce angle based on hit position, **reposition ball above paddle surface**
   - Hit paddle center: near-vertical bounce
   - Hit paddle edge: wide-angle bounce (max 60 degrees)
   - Formula: `ratio = clamp((hitX - paddleCenter) / (paddleWidth/2), -1, 1)`, `bounce angle = ratio * 60 degrees`
   - `hitX` is ball center X (not contact point) to prevent ratio exceeding [-1, 1]
   - **vy is always set negative (upward)** after paddle hit, regardless of incoming angle
5. **Brick collision:** circle-rect detection -> determine which face was hit, flip corresponding velocity component, **reposition ball to brick surface**
   - **Corner collision:** when nearest point on rect is a vertex, reflect velocity around the normal from corner to ball center
   - **Adjacent bricks:** after first brick collision, mark ball as "collided this frame" and skip further brick checks
   - Penetrating ball: do not flip velocity, just reduce HP and continue (up to penetrateHits limit)

### Multi-Ball Collision Batch Processing

To prevent multiple balls from double-damaging the same brick in one frame:
1. Each ball runs collision detection independently
2. On brick hit: set `brick.hitThisFrame = true` and record damage, but do not decrement HP yet
3. After all balls are processed: apply damage as a batch -- each brick with `hitThisFrame` loses 1 HP regardless of how many balls hit it
4. Power-up generation fires once per brick destruction (when HP transitions from 1 to 0)
5. Reset all `hitThisFrame` flags
6. **Max active balls: 12** (cap to prevent visual clutter; multi-ball power-up is ignored if at cap)

### Paddle Movement

- Touch/mouse: **relative drag mode** -- `onPanUpdate` moves paddle by `delta.dx` converted to normalized units, rather than snapping to absolute finger position. This prevents finger occlusion on mobile.
- Keyboard: left/right arrows + A/D keys, using `keysPressed` set pattern (see Input Handling)
- Keyboard paddle speed: fixed at 1.0 height-units/sec (independent of ball speed, allows crossing full width in ~0.75s)

### Power-Up Falling

- Spawns at center of destroyed brick
- Falls downward at constant speed
- Paddle collision (rect-rect) -> activate effect
- Falls past bottom boundary -> removed

## Power-Up System

### Generation Rules

- Generated when a brick is destroyed (HP reaches 0), based on drop chance
- Max 3 power-ups on screen simultaneously (drops are skipped if at cap)
- Type is random, positive/negative weight ratio 4:1
- Extra life has separate lower weight: positive pool weights are widen=3, multiBall=3, penetrate=3, extraLife=1; negative pool weight: shrink=1 (when enabled)
- **Max lives cap: 5** (extra life power-up is skipped if already at 5)

### Power-Up Details

| Power-Up | Color | Icon | Effect | Duration |
|----------|-------|------|--------|----------|
| Widen paddle | Blue | arrows-left-right | Paddle width x2 (base width) | 8 seconds |
| Multi-ball | Green | x3 | Current ball splits into 3 | Permanent (until balls exit) |
| Penetrating ball | Purple | down-arrow | Ball passes through bricks, up to 5 hits | 5 hits or 3 seconds (whichever first) |
| Extra life | Red | heart | +1 life (max 5) | Instant |
| Shrink paddle | Gray | arrows-inward | Paddle width x0.5 (base width) | 8 seconds |

### Conflict Resolution

- Widen + Shrink: later one overrides previous, timer resets. All width multipliers apply to the **original** base paddle width (not current width)
- Same power-up repeated: refresh duration, no stacking
- Penetrating ball applies to all active balls, resets hit counter to 5

## Scoring

- Base score = brick full-HP value (10/20) x scoreMultiplier
- Endless mode: `multiplier = 1 + 0.5 * (round - 1)`, capped at 5x (round 9+)
  - Example: round 1 = 1x, round 3 = 2x, round 5 = 3x, round 9+ = 5x
- **Round clear bonus (Endless):** +100 per round cleared, doubled (+200) if no lives lost that round

### GameOver Stats

- Final score
- Bricks destroyed count
- Survival time
- Endless mode additionally shows: rounds completed

## Input Handling

### Touch/Mouse

- `GestureDetector` wraps the `AspectRatio` widget (inside it, so `localPosition` maps directly to game area)
- **Relative drag mode:** `onPanUpdate` applies `delta.dx / canvasWidth` to `paddle.x` (moves paddle by drag distance, not snap to finger)
- `onPanStart`: records starting position (no paddle jump)
- Clamp paddle within left/right boundaries (0 + halfWidth to 0.75 - halfWidth)
- Canvas size obtained via `LayoutBuilder` wrapping the `CustomPaint`, stored for coordinate conversion

### Keyboard

- `Focus` widget with `onKeyEvent` callback (modern API, consistent with Tetris implementation)
- **Continuous movement via keysPressed set** (not KeyRepeatEvent, which has OS delay):
  - `KeyDownEvent`: add key to `_keysPressed` set
  - `KeyUpEvent`: remove key from `_keysPressed` set
  - Game loop each frame: if left/A in `_keysPressed`, move paddle left by `paddleSpeed * dt`; if right/D, move right
- Paddle speed: fixed at 1.0 height-units/sec

### Ball Launch

- After game start or losing a life, ball rests on top of paddle, follows paddle movement
- Tap screen / press Space -> launch ball (random offset angle)
- Gives player buffer time before ball is in play

### Pause

- `GameScaffold` provides pause button, sets `isPaused` flag
- `canPause` callback: returns `!game.isGameOver && !game.isWon` (prevents pausing a finished game)
- When `isPaused`, Ticker callback skips `update()` (no physics, no repaint)
- App background auto-pauses (built into `GameScaffold`)
- All input ignored during pause

## Rendering (CustomPainter)

### paintVersion Pattern

Use a `_paintVersion` integer counter (consistent with Tetris). Increment only when game state changes. `shouldRepaint` compares `paintVersion != oldDelegate.paintVersion`. This avoids unnecessary repaints when paused (saves battery on mobile).

### Draw Order (bottom to top)

1. **Background** - dark solid color (#1a1a2e)
2. **Bricks** - rounded rectangles, color mapped by HP, 2px spacing between bricks (collision rects match rendered rects exactly, accounting for spacing)
3. **Power-ups** - small rounded rectangles + center icon symbol, with corresponding color
4. **Balls** - filled circles, white; purple with slight glow when penetrating
5. **Paddle** - rounded rectangle, light blue; color changes when widened/shrunk
6. **HUD overlay** - bottom-left shows remaining lives (heart icons), active power-up timers; bottom-right shows round number (Endless mode)

### Visual Feedback

- Brick hit: brief color flash (2-3 frames bright white overlay) then color change or disappear
- Brick destroyed: brief fade-out effect (opacity 1 -> 0 over 3 frames)
- Power-up activated: paddle color briefly flashes
- Life lost: 1.0-second pause + brief screen flash overlay
- Penetrating ball: ball color turns purple
- Paddle bounce: paddle briefly compresses vertically (squash effect, 2-3 frames)
- **Haptic feedback (mobile):** `HapticFeedback.lightImpact()` on brick hit, `HapticFeedback.heavyImpact()` on life loss

### Adaptive Layout

- Game area uses `Center` + `AspectRatio(aspectRatio: 3/4)` widget wrapping a `LayoutBuilder` + `CustomPaint`
- `LayoutBuilder` captures actual canvas size for coordinate conversion (height-normalized coords x canvasHeight = pixels)
- This sits inside `GameScaffold`'s `Expanded` child area (below the top bar)
- HUD (lives, power-up timers) is drawn inside the CustomPainter, so it is covered by pause overlay (acceptable)
- Works in both landscape and portrait, portrait is optimal

### Widget Tree

```
GameScaffold
  Focus(onKeyEvent: ...)
    Center
      AspectRatio(3/4)
        LayoutBuilder              // captures canvas size
          GestureDetector          // inside AspectRatio so localPosition maps to game area
            CustomPaint(painter: BreakoutPainter(...))
```

## Mode Configuration

```dart
class BreakoutConfig {
  final int lives;
  final double ballSpeed;          // Height-normalized speed (canvas height per second)
  final double maxBallSpeed;       // Speed cap (default 1.2)
  final double paddleWidth;        // Height-normalized width
  final int brickRows;
  static const int brickCols = 8;  // Fixed 8 columns for all modes
  final int maxBrickHp;            // Max brick durability (1-2)
  final double powerUpChance;      // Drop probability (0.0-1.0)
  final bool hasNegativePowerUps;  // Whether shrink power-up is in the pool
  final double speedIncrement;     // Base speed increase per round (diminishing formula applied)
  final double scoreMultiplier;    // Score multiplier
  final int maxLives;              // Life cap (default 5)
}
```

## Future Enhancements (Out of Scope for MVP)

The following are acknowledged but deferred to post-MVP iterations:
- Sound effects (ball bounce, brick break, power-up collect, life loss, victory)
- Combo system (consecutive brick hits without paddle bounce = score bonus)
- Ball speed visual indicator in Endless mode (trail length or HUD element)
- Designed brick patterns (pyramid, checkerboard, fortress) as alternatives to random generation
- Screen shake on life loss
