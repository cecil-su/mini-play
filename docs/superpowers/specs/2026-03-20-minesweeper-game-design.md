# Minesweeper Game Design Spec

## Overview

Minesweeper is the third game in the mini-play collection. A classic grid-based puzzle where players reveal cells to find all non-mine cells without detonating any mines.

## Difficulty Levels

Three classic difficulty presets, selectable from a mode page:

| Difficulty | Grid | Mines | Color |
|------------|------|-------|-------|
| Beginner | 9×9 | 10 | #4ECCA3 (green) |
| Intermediate | 16×16 | 40 | #3A86FF (blue) |
| Expert | 30×16 | 99 | #E84545 (red) |

## Architecture

### No Flame Engine

Minesweeper is a turn-based grid game with no real-time physics or continuous rendering. Pure Flutter Widgets provide simpler, more appropriate code than Flame.

### File Structure

```
lib/minesweeper/
├── minesweeper_mode_page.dart     # Difficulty selection (Beginner/Intermediate/Expert)
├── minesweeper_page.dart          # Game page (timer, mine count, board, mode toggle)
├── minesweeper_board.dart         # Board logic (mine placement, reveal, flag, win/loss)
├── minesweeper_cell.dart          # Cell data model
├── minesweeper_colors.dart        # Number color mapping (1=blue, 2=green, 3=red, etc.)
└── minesweeper_cell_widget.dart   # Cell rendering Widget
```

### Routing

- `/minesweeper` → `MinesweeperModePage`
- `/minesweeper/play` → `MinesweeperPage` (receives difficulty config via route arguments)

This follows the same argument-passing pattern as 2048. Route argument extraction in `main.dart`:

```dart
case '/minesweeper/play':
  final difficulty = settings.arguments as MinesweeperDifficulty;
  return MaterialPageRoute(builder: (_) => MinesweeperPage(difficulty: difficulty));
```

### Registry Updates

In `game_registry.dart`: set `implemented: true`, `hasModePage: true` for the Minesweeper entry.

## Core Game Logic

### Cell Data Model (MinesweeperCell)

- `isMine`: bool — whether this cell contains a mine.
- `isRevealed`: bool — whether this cell has been revealed.
- `isFlagged`: bool — whether the player has placed a flag on this cell.
- `adjacentMines`: int (0-8) — count of mines in the 8 surrounding cells.

### Difficulty Config (MinesweeperDifficulty)

- `name`: String — display name (e.g., "Beginner")
- `rows`: int
- `cols`: int
- `mines`: int
- `scoreMode`: String — key for ScoreService (e.g., "beginner")

### Board State (MinesweeperBoard)

- `grid`: `List<List<MinesweeperCell>>` — 2D grid of cells.
- `rows`, `cols`, `totalMines` — board configuration.
- `flagCount`: int — number of flags currently placed.
- `isFirstMove`: bool — true until the first cell is revealed.
- `gameState`: enum `GameState { playing, won, lost }`.

### Mine Placement Algorithm

Mines are placed lazily — only after the first click:

1. Collect all cell positions except the clicked cell and its 8 neighbors (safe zone).
2. Randomly select `totalMines` positions from the remaining cells.
3. Place mines and compute `adjacentMines` for every cell.

This guarantees the first click and its surrounding area are always safe.

### Reveal Logic

`reveal(row, col)`:
1. If cell is flagged or already revealed → ignore.
2. If cell is a mine → `gameState = lost`, reveal all mines, mark incorrectly flagged cells.
3. If `adjacentMines == 0` → BFS/flood fill: recursively reveal all connected cells with `adjacentMines == 0` and their boundary cells (first ring of non-zero numbers).
4. After reveal, check win condition.

### Flag Logic

`toggleFlag(row, col)`:
1. Only works on unrevealed cells.
2. Toggle `isFlagged`. Update `flagCount` (+1 or -1).

### Win Condition

All non-mine cells are revealed. Flagging all mines is NOT required.

### Game Over (Loss)

When a mine is revealed:
1. Set `gameState = lost`.
2. Reveal all mine positions.
3. Mark any flagged cells that are NOT mines as "wrong flags".

## UI Layout

### GameScaffold Adaptation

- `scoreNotifier` drives the timer display (seconds elapsed).
- `bestScore` shows the best time for this difficulty.
- Remaining mine count (`totalMines - flagCount`) displayed in a row above the board.

### Timer

- Starts on first click (not on page load).
- Increments every second via `Timer.periodic`.
- Stops on game end (win or loss).
- Pauses when game is paused (via GameScaffold), resumes on unpause.
- Updates `scoreNotifier.value` each tick.

### Board Rendering

- `GridView.builder` for the grid (regular grid layout, not Stack).
- Wrapped in `InteractiveViewer` for pinch-to-zoom and pan (Expert mode 30×16 needs scrolling on small screens).
- Cell size adapts: computed from available width / cols, with a minimum cell size of 28px.

### Cell Widget States

| State | Display |
|-------|---------|
| Unrevealed | Raised gray block (`#8E8E8E` surface, `#BDBDBD` highlight) |
| Flagged | Flag icon on gray block |
| Revealed - number | Colored number on flat light surface (1=blue, 2=green, 3=red, 4=dark blue, 5=brown, 6=cyan, 7=black, 8=gray) |
| Revealed - empty (0) | Flat light surface, no content |
| Revealed - mine | Mine icon on red background |
| Wrong flag (game over) | X mark over flag |

### Number Colors

| Number | Color |
|--------|-------|
| 1 | #0000FF (blue) |
| 2 | #008000 (green) |
| 3 | #FF0000 (red) |
| 4 | #000080 (dark blue) |
| 5 | #800000 (brown/maroon) |
| 6 | #008080 (cyan/teal) |
| 7 | #000000 (black) |
| 8 | #808080 (gray) |

## Input Handling

### Dual Mode System

Two interaction modes, toggled via a button below the board:

- **Dig mode** (default): tap = reveal, long press = flag.
- **Flag mode**: tap = flag, long press = reveal.

### Platform-Specific

- **Web/Desktop**: right-click always flags (regardless of current mode).
- **Touch**: tap + long press behavior depends on current mode.

### Input Locking

- Input disabled when `gameState != playing`.
- Input disabled when game is paused.

## Game Over Flow

### Loss

1. Mine detonated → reveal all mines, mark wrong flags.
2. Wait 2 seconds (let player see the board).
3. Navigate to `GameOverPage` with stats:
   - Time (seconds)
   - Difficulty name
   - Mines: total count

### Win

1. All non-mine cells revealed.
2. Save best time via `ScoreService` (only if faster than current record).
3. Navigate to `GameOverPage` with stats:
   - Time (seconds)
   - Difficulty name
   - Mines: total count
   - Best Time

`GameOverPage` provides "Play Again" and "Home" buttons (reused from shared).
"Play Again" recreates the game page with `UniqueKey()`.

## ScoreService Modification

Current `ScoreService.saveHighScore` only saves when `score > current`. Minesweeper needs the opposite (lower time = better).

Add a `lowerIsBetter` parameter:

```dart
Future<void> saveHighScore(String game, String mode, int score, {bool lowerIsBetter = false}) async {
  final prefs = await SharedPreferences.getInstance();
  final current = prefs.getInt(_key(game, mode)) ?? 0;
  if (lowerIsBetter) {
    if (current == 0 || score < current) {
      await prefs.setInt(_key(game, mode), score);
    }
  } else {
    if (score > current) {
      await prefs.setInt(_key(game, mode), score);
    }
  }
}
```

Existing callers (Snake, 2048) are unaffected since `lowerIsBetter` defaults to `false`.

## Mode Selection Page

Follows `snake_mode_page.dart` / `game_2048_mode_page.dart` pattern:

- Three difficulty cards with icon + name + description + best time.
- Best time displayed as "Best: --" if no record, otherwise "Best: 42s".
- Tap navigates to `/minesweeper/play` with difficulty config as argument.

## Shared Infrastructure Reuse

- `GameScaffold`: top bar (timer as score), pause overlay.
- `ScoreService`: best time persistence (with `lowerIsBetter` flag).
- `GameOverPage`: game over screen with stats and replay.
