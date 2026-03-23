# Sudoku Game Design

## Overview

9x9 经典数独游戏，内置谜题生成器，4 个难度级别，积分制计分。

## Core Requirements

- 9x9 标准数独，宫格 3x3
- 4 个难度级别：简单 / 中等 / 困难 / 专家
- 运行时随机生成谜题，保证唯一解
- 积分制计分（基础分 + 时间加成 - 错误惩罚）
- 笔记模式（候选数标记）
- 多步撤销
- 可切换的错误提示（填入冲突数字时标红）
- 不做提示系统

## Data Model

### SudokuGameState

```dart
enum SudokuGameState { playing, won }
```

### SudokuCell

```dart
class SudokuCell {
  int value;          // 0 = empty
  bool isGiven;       // preset by puzzle, not editable
  Set<int> notes;     // pencil marks (1-9)
}
```

Note: error state is computed by `SudokuBoard._updateErrors()` after each mutation, not stored on the cell. The board maintains a `Set<(int, int)> errorCells` for UI binding.

### SudokuDifficulty

| Level | Empty Cells | scoreMode |
|-------|------------|-----------|
| 简单  | ~36        | `easy`    |
| 中等  | ~45        | `medium`  |
| 困难  | ~50        | `hard`    |
| 专家  | ~54        | `expert`  |

```dart
class SudokuDifficulty {
  final String name;
  final int emptyCells;
  final String scoreMode;

  const SudokuDifficulty({
    required this.name,
    required this.emptyCells,
    required this.scoreMode,
  });

  static const easy = SudokuDifficulty(name: '简单', emptyCells: 36, scoreMode: 'easy');
  static const medium = SudokuDifficulty(name: '中等', emptyCells: 45, scoreMode: 'medium');
  static const hard = SudokuDifficulty(name: '困难', emptyCells: 50, scoreMode: 'hard');
  static const expert = SudokuDifficulty(name: '专家', emptyCells: 54, scoreMode: 'expert');
}
```

### SudokuBoard

Game logic model encapsulating the 9x9 grid.

```dart
class SudokuBoard {
  List<List<SudokuCell>> grid;    // 9x9
  List<List<int>> solution;       // complete answer for validation
  Set<(int, int)> errorCells;     // computed by _updateErrors()

  void setValue(int row, int col, int value);
  void toggleNote(int row, int col, int value);
  void clearCell(int row, int col);
  bool hasConflict(int row, int col);
  bool isComplete();
  bool isDigitComplete(int digit); // true if all 9 instances placed
  SudokuGameState get gameState;  // playing | won

  // Test constructor for unit tests
  SudokuBoard.fromGrid(this.grid, this.solution);
}
```

Note: `_updateErrors()` is called internally at the end of every public mutation method (`setValue`, `toggleNote`, `clearCell`). The page never calls it directly.

## Puzzle Generation

### Algorithm: Backtracking Fill + Dig Holes

`SudokuGenerator` — static utility class.

**`generate(SudokuDifficulty difficulty)`:**

1. **`_fillBoard()`** — backtracking random fill
   - For each empty cell, shuffle 1-9 and try each
   - Check row, column, box constraints; recurse on valid placement
   - Backtrack on failure
2. Save completed grid as `solution`
3. **`_digHoles(count)`** — remove cells with retry logic
   - Shuffle all 81 cell positions, iterate in order (avoids retrying same cell)
   - For each cell: tentatively clear it, call `_countSolutions()` to verify unique solution
   - If not unique, restore and skip to next cell
   - If all remaining cells exhausted without reaching target: accept current count if within `emptyCells - 3` of target, otherwise restart from step 1
   - `maxRestarts = 5` — if exceeded, use best result so far

**`_countSolutions(grid)`** — backtracking solver
- Find first empty cell, try 1-9
- Early return once 2 solutions found (only need to confirm "not unique")
- Implementation note: pass a mutable counter (`List<int>`) and check `count[0] >= 2` before each recursive call for clean early exit

**Performance:** 9x9 generation + validation: easy <50ms, expert <200ms on modern native devices. Web (dart2js) may be 3-10x slower due to JS compilation overhead.

**Platform notes:**
- `Isolate.spawn` is NOT available on web. Use `compute()` from `package:flutter/foundation.dart` which maps to isolates on native and runs synchronously on web.
- If web expert generation blocks UI noticeably, consider breaking generation into chunks with `Future.delayed(Duration.zero)` between iterations to yield to the event loop.

## Scoring System

```
baseScore    = difficulty base (easy: 1000, medium: 2000, hard: 3000, expert: 5000)
timeBonus    = max(0, baseScore - elapsedSeconds * 2)
errorPenalty = errorCount * 50
finalScore   = baseScore + timeBonus - errorPenalty
```

- Higher difficulty = higher base score
- Speed bonus decays over time, floor at 0
- `errorCount` increments by 1 each time `setValue` is called with a value that does not match `solution[row][col]`. Undo does not decrement errorCount. Erasing and re-entering a wrong value counts as an additional error.
- Notes do not count as errors
- `finalScore = max(0, finalScore)` — scores are clamped to zero minimum
- Storage: existing `ScoreService` with `lowerIsBetter: false`

### GameOver Stats

```dart
stats: {
  '难度': difficulty.name,
  '用时': formatTime(elapsed),
  '得分': finalScore,
  '错误': errorCount,
}
```

## UI Design

### Page Flow

Home → SudokuModePage → SudokuPage → GameOverPage

Note: Sudoku has no lose condition — the player always completes the puzzle. Extend `GameOverData` with an optional `String? title` field (default: `'Game Over'`). `GameOverPage` uses `data.title ?? 'Game Over'` so all existing callers are unaffected. Sudoku passes `title: '恭喜通关'`. This is a shared improvement that also benefits Sokoban and other win-only games.

### Game Page Layout (top to bottom)

1. **GameScaffold top bar** — back, title, pause, score display (~96px)
2. **9x9 board grid** — square, centered, with 3x3 box borders (2px bright `#4ECCA3` at 0.5 opacity for box borders, 0.5px dim for cell borders). Use `LayoutBuilder` to size the board within available vertical space. Minimum cell size: 36px. Notes font minimum: 8px.
3. **Action bar** — [填数] [笔记] [撤销] [清除] [错误提示 icon toggle] (~48px). Error toggle is an eye/eye-off icon button merged into this row to save vertical space.
4. **Number pad** — [1][2][3][4][5][6][7][8][9] (gray out numbers with all 9 instances placed). Minimum button size: 44px. On narrow screens (<360px), fall back to 3x3 grid layout (~100px). On normal screens, single row (~48px).

**Vertical space budget:** ~96px (scaffold) + board + ~48px (action bar) + ~48-100px (numpad) = controls take ~192-244px. On a 640px screen, board gets ~396-448px → cell size ~44-50px. On a 568px screen (iPhone SE), board gets ~324-376px → cell size ~36-42px. Minimum cell size of 36px is maintained.

### Interaction Flow

1. Tap a cell → select it (highlight row, column, box, and same-number cells)
2. Tap number on pad → fill or toggle note based on current mode
3. "填数/笔记" toggles input mode (use active/inactive styling consistent with minesweeper's dig/flag toggle pattern)
4. "撤销" reverts last action
5. "清除" clears selected cell's value and notes
6. Given cells can be selected (for highlighting) but not edited

### Cell Visual States (layered, bottom to top)

```
Layer 0 (base):    Empty dark background
Layer 1 (region):  Related highlight — subtle tint for same row/col/box
Layer 2 (number):  Same-number highlight — medium tint (overrides Layer 1)
Layer 3 (error):   Red background tint when error display enabled (overrides Layer 1-2)
Layer 4 (select):  Selected cell — bright highlight border (additive, on top of any bg)
```

**Text colors:**
- **Given** — bold, primary color (#4ECCA3)
- **User input** — normal weight, gold (#F0C040)
- **Error text** — red (#E84545) when error display enabled
- **Notes** — 3x3 mini-grid of small numbers, only shown in empty cells, color #6688AA

### Undo System

```dart
class UndoAction {
  final int row, col;
  final int oldValue;
  final Set<int> oldNotes; // MUST deep-copy: Set<int>.of(cell.notes)
  final UndoType type; // setValue, toggleNote, clearCell
}
```

`_history: List<UndoAction>` — unlimited undo stack.

**Semantics:**
- `setValue`: when placing a value on a cell that has notes, the notes are cleared. `UndoAction` must capture both `oldValue` and `oldNotes` (deep-copied). On undo, restore both.
- `clearCell`: clears value AND notes. `UndoAction` must capture both `oldValue` and `oldNotes`. On undo, restore both.
- `toggleNote`: captures the note set before toggling. On undo, restore the previous note set.
- Error display toggle is a display preference, not a game action — it is not undoable.
- `oldNotes` must always be deep-copied via `Set<int>.of(cell.notes)` to avoid reference sharing bugs.

## File Structure

```
lib/sudoku/
├── sudoku_board.dart          # Board logic + game state
├── sudoku_cell.dart           # Cell data class + Difficulty config
├── sudoku_generator.dart      # Generator + solver
├── sudoku_page.dart           # Game page (StatefulWidget)
├── sudoku_cell_widget.dart    # Individual cell UI widget
├── sudoku_colors.dart         # Color constants
└── sudoku_mode_page.dart      # Difficulty selection page
```

## Integration

### Game Registry

```dart
GameInfo(
  name: 'Sudoku',
  icon: Icons.grid_3x3,
  description: '填满9×9网格，每行列宫不重复',
  phase: 4,
  route: '/sudoku',
  implemented: true,
  hasModePage: true,
)
```

### Routing (main.dart)

```dart
case '/sudoku':
  return MaterialPageRoute(builder: (_) => const SudokuModePage());
case '/sudoku/play':
  final difficulty = settings.arguments as SudokuDifficulty? ?? SudokuDifficulty.easy;
  return MaterialPageRoute(builder: (_) => SudokuPage(difficulty: difficulty));
```

## Shared Utilities Used

- `GameScaffold` — top bar, pause/resume, score display
- `ScoreService` — high score persistence
- `GameModeCard` — difficulty selection cards
- `GameOverPage` — results display
- `formatTime()` — time formatting

## State Management

StatefulWidget + ValueNotifier (consistent with all existing games):
- `ValueNotifier<int>` for score updates
- `setState()` for board changes
- `Timer` for elapsed time — starts on first `setValue` or `toggleNote` action (not on cell selection), so browsing the puzzle before starting is free
- `UniqueKey()` for game reset
