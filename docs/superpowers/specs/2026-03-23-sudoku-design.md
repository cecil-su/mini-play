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

### SudokuCell

```dart
class SudokuCell {
  int value;          // 0 = empty
  bool isGiven;       // preset by puzzle, not editable
  Set<int> notes;     // pencil marks (1-9)
  bool isError;       // conflict flag (when error checking enabled)
}
```

### SudokuDifficulty

| Level | Empty Cells | scoreMode |
|-------|------------|-----------|
| 简单  | ~36        | `easy`    |
| 中等  | ~45        | `medium`  |
| 困难  | ~52        | `hard`    |
| 专家  | ~58        | `expert`  |

```dart
class SudokuDifficulty {
  final String name;
  final int emptyCells;
  final String scoreMode;

  static const easy = SudokuDifficulty('简单', 36, 'easy');
  static const medium = SudokuDifficulty('中等', 45, 'medium');
  static const hard = SudokuDifficulty('困难', 52, 'hard');
  static const expert = SudokuDifficulty('专家', 58, 'expert');
}
```

### SudokuBoard

Game logic model encapsulating the 9x9 grid.

```dart
class SudokuBoard {
  List<List<SudokuCell>> grid;    // 9x9
  List<List<int>> solution;       // complete answer for validation

  void setValue(int row, int col, int value);
  void toggleNote(int row, int col, int value);
  void clearCell(int row, int col);
  bool hasConflict(int row, int col);
  bool isComplete();
  SudokuGameState get gameState;  // playing | won
}
```

## Puzzle Generation

### Algorithm: Backtracking Fill + Dig Holes

`SudokuGenerator` — static utility class.

**`generate(SudokuDifficulty difficulty)`:**

1. **`_fillBoard()`** — backtracking random fill
   - For each empty cell, shuffle 1-9 and try each
   - Check row, column, box constraints; recurse on valid placement
   - Backtrack on failure
2. Save completed grid as `solution`
3. **`_digHoles(count)`** — remove cells
   - Randomly select a filled cell, tentatively clear it
   - Call `_countSolutions()` to verify unique solution remains
   - If not unique, restore cell and try another
   - Repeat until target empty count reached

**`_countSolutions(grid)`** — backtracking solver
- Find first empty cell, try 1-9
- Early return once 2 solutions found (only need to confirm "not unique")

**Performance:** 9x9 generation + validation: easy <50ms, expert <200ms. Synchronous execution, no isolate needed.

## Scoring System

```
baseScore    = difficulty base (easy: 1000, medium: 2000, hard: 3000, expert: 5000)
timeBonus    = max(0, baseScore - elapsedSeconds * 2)
errorPenalty = errorCount * 50
finalScore   = baseScore + timeBonus - errorPenalty
```

- Higher difficulty = higher base score
- Speed bonus decays over time, floor at 0
- Each incorrect fill (value != solution) costs 50 points, regardless of error display toggle
- Notes do not count as errors
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

### Game Page Layout (top to bottom)

1. **GameScaffold top bar** — back, title, pause, score display
2. **9x9 board grid** — square, centered, with 3x3 box borders
3. **Action bar** — [填数] [笔记] [撤销] [清除]
4. **Number pad** — [1][2][3][4][5][6][7][8][9]
5. **Error toggle** — switch for error highlighting on/off

### Interaction Flow

1. Tap a cell → select it (highlight row, column, box, and same-number cells)
2. Tap number on pad → fill or toggle note based on current mode
3. "填数/笔记" toggles input mode
4. "撤销" reverts last action
5. "清除" clears selected cell's value and notes
6. Given cells can be selected (for highlighting) but not edited

### Cell Visual States

- **Given** — bold, primary color (#4ECCA3)
- **User input** — normal weight, gold (#F0C040)
- **Error** — red background tint when error display enabled
- **Selected** — bright highlight border
- **Related** — subtle highlight for same row/col/box
- **Same number** — medium highlight for cells with same value
- **Notes** — 3x3 mini-grid of small numbers inside cell
- **Empty** — dark background

### Undo System

```dart
class UndoAction {
  final int row, col;
  final int oldValue;
  final Set<int> oldNotes;
  final UndoType type; // setValue, toggleNote, clearCell
}
```

`_history: List<UndoAction>` — unlimited undo stack.

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
- `Timer` for elapsed time
- `UniqueKey()` for game reset
