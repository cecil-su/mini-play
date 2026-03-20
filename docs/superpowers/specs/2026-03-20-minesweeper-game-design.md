# Minesweeper Game Design Spec

## Overview

Minesweeper is the third game in the mini-play collection. A classic grid-based puzzle where players reveal cells to find all non-mine cells without detonating any mines.

## Difficulty Levels

Three classic difficulty presets, selectable from a mode page:

| Difficulty | Rows | Cols | Mines | Color |
|------------|------|------|-------|-------|
| Beginner | 9 | 9 | 10 | #4ECCA3 (green) |
| Intermediate | 16 | 16 | 40 | #3A86FF (blue) |
| Expert | 16 | 30 | 99 | #E84545 (red) |

Expert is 16 rows × 30 columns (landscape orientation), matching classic Windows Minesweeper.

## Architecture

### No Flame Engine

Minesweeper is a turn-based grid game with no real-time physics or continuous rendering. Pure Flutter Widgets provide simpler, more appropriate code than Flame.

### File Structure

```
lib/minesweeper/
├── minesweeper_mode_page.dart     # Difficulty selection (Beginner/Intermediate/Expert)
├── minesweeper_page.dart          # Game page (timer, mine count, board, mode toggle)
├── minesweeper_board.dart         # Board logic (mine placement, reveal, flag, win/loss)
├── minesweeper_cell.dart          # Cell data model + difficulty config
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
- `rows`: int — number of rows
- `cols`: int — number of columns
- `mines`: int — total mine count
- `scoreMode`: String — key for ScoreService (e.g., "beginner")

### Board State (MinesweeperBoard)

- `grid`: `List<List<MinesweeperCell>>` — 2D grid of cells, outer list is rows.
- `rows`, `cols`, `totalMines` — board configuration.
- `flagCount`: int — number of flags currently placed.
- `isFirstMove`: bool — true until the first cell is revealed.
- `gameState`: enum `MinesweeperGameState { playing, won, lost }`.

### Mine Placement Algorithm

Mines are placed lazily — only after the first click:

1. Collect all cell positions except the clicked cell and its neighbors within the board bounds (the safe zone is the intersection of the 3×3 area centered on the clicked cell and the board boundaries — corner clicks have 4 safe cells, edge clicks have 6, interior clicks have 9).
2. Randomly select `totalMines` positions from the remaining cells.
3. Place mines and compute `adjacentMines` for every cell.

This guarantees the first click and its surrounding area are always safe.

### Reveal Logic

`reveal(row, col)`:
1. If cell is flagged or already revealed → ignore.
2. If `isFirstMove` → place mines (with safe zone around clicked cell), set `isFirstMove = false`.
3. If cell is a mine → `gameState = lost`, reveal all mines, mark incorrectly flagged cells.
4. If `adjacentMines == 0` → BFS/flood fill: recursively reveal all connected cells with `adjacentMines == 0` and their boundary cells (first ring of non-zero numbers).
5. After reveal, check win condition.

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

### GameScaffold Modification

`GameScaffold` currently hardcodes `'Score: $score'` and `'Best: ${widget.bestScore}'`. To support Minesweeper's timer display, add optional label/format parameters:

```dart
class GameScaffold extends StatefulWidget {
  // ... existing fields ...
  final String scoreLabel;    // default: 'Score'
  final String bestLabel;     // default: 'Best'
  final String Function(int)? scoreFormatter;  // default: null (uses '$value')
  final String Function(int)? bestFormatter;   // default: null (uses '$value')
```

Minesweeper uses: `scoreLabel: 'Time'`, `bestLabel: 'Best'`, `scoreFormatter: formatTime`, `bestFormatter: (v) => v == 0 ? '--' : formatTime(v)`.

Where `formatTime(int seconds)` returns `'$seconds s'` for < 60, `'${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}'` for >= 60.

### Mine Counter

Inside `GameScaffold.child`, the `MinesweeperPage` renders a `Column`:
1. **Mine counter row** — centered text showing remaining mines: `totalMines - flagCount`. Styled with mine icon + count, using the app's gold color (`#F0C040`).
2. **Board** (expanded) — the grid wrapped in InteractiveViewer.
3. **Mode toggle button** — dig/flag switch.

### Timer

- Starts on first click (not on page load).
- Increments every second via `Timer.periodic`.
- Stops on game end (win or loss).
- Pauses when game is paused (via GameScaffold), resumes on unpause.
- Updates `scoreNotifier.value` each tick.

### Board Rendering

- `GridView.builder` for the grid (regular grid layout, not Stack).
- Wrapped in `InteractiveViewer` for pinch-to-zoom and pan on all difficulty levels. Config: `minScale: 1.0`, `maxScale: 3.0`. For Beginner, the board fits on screen so zoom is available but not needed. For Expert, the initial view fits the full board width.
- Cell size: `min(availableWidth / cols, availableHeight / rows)`, with a minimum of 28px. If the computed size is below 28px, the board overflows and InteractiveViewer handles scrolling.

### Cell Widget States

Revealed cells use a flat light background `#D0D0D0` to ensure all number colors are readable.

| State | Display |
|-------|---------|
| Unrevealed | Raised gray block (`#8E8E8E` surface, `#BDBDBD` highlight) |
| Flagged | Flag icon on raised gray block |
| Revealed - number | Colored number on `#D0D0D0` flat surface |
| Revealed - empty (0) | `#D0D0D0` flat surface, no content |
| Revealed - mine | Mine icon on `#E84545` red background |
| Wrong flag (game over) | X mark over flag on `#E84545` background |

### Number Colors

All verified for sufficient contrast against `#D0D0D0` background:

| Number | Color |
|--------|-------|
| 1 | #0000FF (blue) |
| 2 | #008000 (green) |
| 3 | #FF0000 (red) |
| 4 | #000080 (dark blue) |
| 5 | #800000 (brown/maroon) |
| 6 | #008080 (cyan/teal) |
| 7 | #303030 (dark gray — adjusted from black for readability) |
| 8 | #808080 (gray) |

## Input Handling

### Dual Mode System

Two interaction modes, toggled via a button below the board:

- **Dig mode** (default): tap = reveal, long press = flag.
- **Flag mode**: tap = flag, long press = reveal.

The toggle button displays: dig mode icon (pickaxe ⛏️) or flag mode icon (flag 🚩), with the active mode highlighted in the primary green color (`#4ECCA3`). Inactive mode shown in gray.

### Platform-Specific

- **Web/Desktop**: right-click always flags (regardless of current mode). Handled via `Listener` widget's `onPointerDown` checking for `kSecondaryButton`.
- **Touch**: tap + long press behavior depends on current mode.

### Input Locking

- Input disabled when `gameState != playing`.
- Input disabled when game is paused.

## Game Over Flow

### Loss

1. Mine detonated → reveal all mines, mark wrong flags, set `gameState = lost`.
2. Wait 2 seconds (let player see the board). During this delay, input is already locked by `gameState != playing`. If the user navigates away (back button → pause overlay), the delay timer is cancelled.
3. Navigate to `GameOverPage` with stats:
   - Time (formatted)
   - Difficulty name
   - Mines: total count

### Win

1. All non-mine cells revealed, set `gameState = won`.
2. Save best time via `ScoreService` (only if faster than current record).
3. Navigate to `GameOverPage` with stats:
   - Time (formatted)
   - Difficulty name
   - Mines: total count
   - Best Time

`GameOverPage` provides "Play Again" and "Home" buttons (reused from shared).
"Play Again" pops `GameOverPage`, then the underlying `MinesweeperPage` does `setState` with a new `UniqueKey()` to recreate (same pattern as 2048).

## ScoreService Modification

Current `ScoreService.saveHighScore` only saves when `score > current`. Minesweeper needs the opposite (lower time = better).

Add a `lowerIsBetter` parameter:

```dart
Future<void> saveHighScore(String game, String mode, int score, {bool lowerIsBetter = false}) async {
  final prefs = await SharedPreferences.getInstance();
  final current = prefs.getInt(_key(game, mode)) ?? 0;
  if (lowerIsBetter) {
    // 0 means no previous record (sentinel). A real time is always > 0.
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

**Display logic for best time**: `getHighScore` returns `0` for no record. The mode page and GameScaffold display `0` as `'--'` (no record) since a time of 0 seconds is impossible in gameplay.

## Mode Selection Page

Follows `snake_mode_page.dart` / `game_2048_mode_page.dart` pattern:

- Three difficulty cards with icon + name + description + best time.
- Best time: `0` → display `'Best: --'`, otherwise `'Best: 42s'` (or `'Best: 1:30'` for >= 60s).
- Tap navigates to `/minesweeper/play` with `MinesweeperDifficulty` as argument.

## Shared Infrastructure Reuse

- `GameScaffold`: top bar (with customizable labels for timer), pause overlay.
- `ScoreService`: best time persistence (with `lowerIsBetter` flag).
- `GameOverPage`: game over screen with stats and replay.
