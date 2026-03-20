# Minesweeper Game Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a fully playable Minesweeper game with 3 difficulty levels (Beginner/Intermediate/Expert), timer, flag system, chord reveal, and best-time tracking.

**Architecture:** Pure Flutter widgets (no Flame engine). Board logic separated from rendering. Shared infrastructure (ScoreService, GameScaffold) modified to support timer-based scoring. Cell widget handles 6 visual states.

**Tech Stack:** Flutter, shared_preferences (via ScoreService), Timer.periodic

**Spec:** `docs/superpowers/specs/2026-03-20-minesweeper-game-design.md`

---

## File Structure

```
lib/minesweeper/
├── minesweeper_cell.dart          # Cell data model + MinesweeperDifficulty config
├── minesweeper_colors.dart        # Number color mapping (1-8)
├── minesweeper_board.dart         # Board logic: mine placement, reveal, flag, chord, win/loss
├── minesweeper_cell_widget.dart   # Cell rendering widget (6 states)
├── minesweeper_page.dart          # Game page: timer, mine counter, board, mode toggle, game over
├── minesweeper_mode_page.dart     # Difficulty selection page

test/minesweeper/
├── minesweeper_board_test.dart    # Board logic unit tests
```

Modify:
- `lib/shared/score_service.dart` — add `lowerIsBetter` parameter
- `test/shared/score_service_test.dart` — add tests for `lowerIsBetter`
- `lib/shared/game_scaffold.dart` — add `scoreLabel`, `bestLabel`, `scoreFormatter`, `bestFormatter`
- `lib/main.dart` — add routes `/minesweeper` and `/minesweeper/play`
- `lib/home/game_registry.dart` — set minesweeper as implemented

---

### Task 1: ScoreService — Add `lowerIsBetter` Parameter

**Files:**
- Modify: `lib/shared/score_service.dart`
- Modify: `test/shared/score_service_test.dart`

- [ ] **Step 1: Write tests for `lowerIsBetter`**

Add to `test/shared/score_service_test.dart`:

```dart
    test('lowerIsBetter saves lower score', () async {
      final service = ScoreService();
      await service.saveHighScore('minesweeper', 'beginner', 100, lowerIsBetter: true);
      await service.saveHighScore('minesweeper', 'beginner', 50, lowerIsBetter: true);
      expect(await service.getHighScore('minesweeper', 'beginner'), 50);
    });

    test('lowerIsBetter does not save higher score', () async {
      final service = ScoreService();
      await service.saveHighScore('minesweeper', 'beginner', 50, lowerIsBetter: true);
      await service.saveHighScore('minesweeper', 'beginner', 100, lowerIsBetter: true);
      expect(await service.getHighScore('minesweeper', 'beginner'), 50);
    });

    test('lowerIsBetter saves first score when no record exists', () async {
      final service = ScoreService();
      await service.saveHighScore('minesweeper', 'beginner', 42, lowerIsBetter: true);
      expect(await service.getHighScore('minesweeper', 'beginner'), 42);
    });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `fvm flutter test test/shared/score_service_test.dart`
Expected: FAIL — `lowerIsBetter` parameter not found

- [ ] **Step 3: Implement `lowerIsBetter`**

In `lib/shared/score_service.dart`, change `saveHighScore`:

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

- [ ] **Step 4: Run all tests**

Run: `fvm flutter test`
Expected: ALL PASS (existing tests unaffected, new tests pass)

- [ ] **Step 5: Commit**

```bash
git add lib/shared/score_service.dart test/shared/score_service_test.dart
git commit -m "feat(shared): add lowerIsBetter parameter to ScoreService"
```

---

### Task 2: GameScaffold — Add Label/Format Customization

**Files:**
- Modify: `lib/shared/game_scaffold.dart`

- [ ] **Step 1: Add optional parameters to GameScaffold**

Add five optional fields to `GameScaffold`:

```dart
class GameScaffold extends StatefulWidget {
  final String title;
  final ValueNotifier<int> scoreNotifier;
  final int bestScore;
  final Widget child;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final String scoreLabel;
  final String bestLabel;
  final String Function(int)? scoreFormatter;
  final String Function(int)? bestFormatter;
  final bool Function()? canPause; // return false to suppress pause overlay

  const GameScaffold({
    super.key,
    required this.title,
    required this.scoreNotifier,
    required this.bestScore,
    required this.child,
    required this.onPause,
    required this.onResume,
    this.scoreLabel = 'Score',
    this.bestLabel = 'Best',
    this.scoreFormatter,
    this.bestFormatter,
    this.canPause,
  });
```

- [ ] **Step 2: Update score bar rendering**

In the `ValueListenableBuilder` builder, change the hardcoded strings:

```dart
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${widget.scoreLabel}: ${widget.scoreFormatter?.call(score) ?? '$score'}',
                          style: const TextStyle(
                            color: Color(0xFF4ECCA3),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${widget.bestLabel}: ${widget.bestFormatter?.call(widget.bestScore) ?? '${widget.bestScore}'}',
                          style: const TextStyle(
                            color: Color(0xFFF0C040),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    );
```

- [ ] **Step 3: Add `canPause` guard to `_pause` method and update lifecycle**

In `_GameScaffoldState`, update `didChangeAppLifecycleState` to pass `fromLifecycle: true`:

```dart
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      _pause(fromLifecycle: true);
    }
  }
```

Then replace the `_pause()` method:

```dart
  void _pause({bool fromLifecycle = false}) {
    // canPause guards user-initiated pause (back/pause button), not lifecycle.
    // On lifecycle (app background), always call onPause so the game can stop its timer,
    // but don't show the overlay if canPause returns false.
    if (!fromLifecycle && widget.canPause != null && !widget.canPause!()) {
      _quit();
      return;
    }
    if (!_isPaused) {
      final showOverlay = widget.canPause?.call() ?? true;
      if (showOverlay) {
        setState(() => _isPaused = true);
      }
      widget.onPause();
    }
  }
```

When `canPause` returns `false`, pressing back/pause navigates home instead of showing the overlay. Existing callers don't set `canPause`, so the default `null` preserves current behavior.

- [ ] **Step 4: Verify existing games still work**

Run: `fvm flutter analyze lib/shared/game_scaffold.dart`
Expected: No errors. Existing callers (Snake, 2048) use defaults, so no changes needed.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/game_scaffold.dart
git commit -m "feat(shared): add label and format customization to GameScaffold"
```

---

### Task 3: Cell Model + Difficulty Config + Colors

**Files:**
- Create: `lib/minesweeper/minesweeper_cell.dart`
- Create: `lib/minesweeper/minesweeper_colors.dart`

- [ ] **Step 1: Implement cell model and difficulty config**

```dart
// lib/minesweeper/minesweeper_cell.dart

class MinesweeperCell {
  bool isMine;
  bool isRevealed;
  bool isFlagged;
  bool isWrongFlag; // shown on game over: flagged but not a mine
  int adjacentMines;

  MinesweeperCell({
    this.isMine = false,
    this.isRevealed = false,
    this.isFlagged = false,
    this.isWrongFlag = false,
    this.adjacentMines = 0,
  });
}

enum MinesweeperGameState { playing, won, lost }

class MinesweeperDifficulty {
  final String name;
  final int rows;
  final int cols;
  final int mines;
  final String scoreMode;

  const MinesweeperDifficulty({
    required this.name,
    required this.rows,
    required this.cols,
    required this.mines,
    required this.scoreMode,
  });

  static const beginner = MinesweeperDifficulty(
    name: 'Beginner',
    rows: 9,
    cols: 9,
    mines: 10,
    scoreMode: 'beginner',
  );

  static const intermediate = MinesweeperDifficulty(
    name: 'Intermediate',
    rows: 16,
    cols: 16,
    mines: 40,
    scoreMode: 'intermediate',
  );

  static const expert = MinesweeperDifficulty(
    name: 'Expert',
    rows: 16,
    cols: 30,
    mines: 99,
    scoreMode: 'expert',
  );
}
```

- [ ] **Step 2: Implement color mapping**

```dart
// lib/minesweeper/minesweeper_colors.dart
import 'package:flutter/material.dart';

class MinesweeperColors {
  // Cell backgrounds
  static const Color unrevealedSurface = Color(0xFF8E8E8E);
  static const Color unrevealedHighlight = Color(0xFFBDBDBD);
  static const Color revealedSurface = Color(0xFFD0D0D0);
  static const Color mineSurface = Color(0xFFE84545);

  // Number colors (WCAG AA contrast on #D0D0D0)
  static const Map<int, Color> numberColors = {
    1: Color(0xFF0000FF), // blue
    2: Color(0xFF006400), // dark green
    3: Color(0xFFFF0000), // red
    4: Color(0xFF000080), // dark blue
    5: Color(0xFF800000), // brown/maroon
    6: Color(0xFF008080), // cyan/teal
    7: Color(0xFF303030), // dark gray
    8: Color(0xFF606060), // dark gray
  };

  static Color getNumberColor(int number) {
    return numberColors[number] ?? Colors.black;
  }
}
```

- [ ] **Step 3: Verify it compiles**

Run: `fvm flutter analyze lib/minesweeper/`
Expected: No errors

- [ ] **Step 4: Commit**

```bash
git add lib/minesweeper/minesweeper_cell.dart lib/minesweeper/minesweeper_colors.dart
git commit -m "feat(minesweeper): add cell model, difficulty config, and color mapping"
```

---

### Task 4: Board Logic

**Files:**
- Create: `lib/minesweeper/minesweeper_board.dart`
- Create: `test/minesweeper/minesweeper_board_test.dart`

- [ ] **Step 1: Write board logic tests**

```dart
// test/minesweeper/minesweeper_board_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_play/minesweeper/minesweeper_board.dart';
import 'package:mini_play/minesweeper/minesweeper_cell.dart';

void main() {
  group('MinesweeperBoard initialization', () {
    test('creates grid with correct dimensions', () {
      final board = MinesweeperBoard(rows: 9, cols: 9, totalMines: 10);
      expect(board.grid.length, 9);
      expect(board.grid[0].length, 9);
    });

    test('starts with no mines placed', () {
      final board = MinesweeperBoard(rows: 9, cols: 9, totalMines: 10);
      final mineCount = board.grid.expand((row) => row).where((c) => c.isMine).length;
      expect(mineCount, 0);
      expect(board.isFirstMove, true);
    });

    test('starts in playing state', () {
      final board = MinesweeperBoard(rows: 9, cols: 9, totalMines: 10);
      expect(board.gameState, MinesweeperGameState.playing);
    });
  });

  group('Mine placement', () {
    test('places correct number of mines after first reveal', () {
      final board = MinesweeperBoard(rows: 9, cols: 9, totalMines: 10);
      board.reveal(4, 4);
      final mineCount = board.grid.expand((row) => row).where((c) => c.isMine).length;
      expect(mineCount, 10);
      expect(board.isFirstMove, false);
    });

    test('first click and neighbors are safe', () {
      final board = MinesweeperBoard(rows: 9, cols: 9, totalMines: 10);
      board.reveal(4, 4);
      // Check 3x3 area around (4,4) is mine-free
      for (int dr = -1; dr <= 1; dr++) {
        for (int dc = -1; dc <= 1; dc++) {
          expect(board.grid[4 + dr][4 + dc].isMine, false,
              reason: 'Cell (${4 + dr}, ${4 + dc}) should be safe');
        }
      }
    });

    test('corner click has smaller safe zone', () {
      final board = MinesweeperBoard(rows: 9, cols: 9, totalMines: 10);
      board.reveal(0, 0);
      // Corner: only 4 cells in safe zone
      expect(board.grid[0][0].isMine, false);
      expect(board.grid[0][1].isMine, false);
      expect(board.grid[1][0].isMine, false);
      expect(board.grid[1][1].isMine, false);
    });
  });

  group('Reveal logic', () {
    test('reveals a number cell', () {
      final board = MinesweeperBoard(rows: 9, cols: 9, totalMines: 10);
      board.reveal(0, 0); // triggers mine placement
      // After first reveal, the clicked cell should be revealed
      expect(board.grid[0][0].isRevealed, true);
    });

    test('flood fill reveals connected empty cells', () {
      final board = MinesweeperBoard.fromGrid([
        [0, 0, 1, -1],
        [0, 0, 1, 1],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      board.reveal(3, 0);
      // All 0-cells and their number-cell borders should be revealed
      // Row 3: all empty, row 2: all empty, row 1: [0,0] empty
      // The flood fill should reveal everything except the mine and its immediate numbers
      expect(board.grid[3][0].isRevealed, true);
      expect(board.grid[2][0].isRevealed, true);
      expect(board.grid[0][0].isRevealed, true);
      expect(board.grid[0][2].isRevealed, true); // number 1, boundary of flood
      expect(board.grid[0][3].isRevealed, false); // mine, not revealed
    });

    test('revealing a mine triggers loss', () {
      final board = MinesweeperBoard.fromGrid([
        [-1, 1, 0],
        [1, 1, 0],
        [0, 0, 0],
      ]);
      board.reveal(0, 0);
      expect(board.gameState, MinesweeperGameState.lost);
    });

    test('loss reveals all mines', () {
      final board = MinesweeperBoard.fromGrid([
        [-1, 1, 0],
        [1, 1, 0],
        [0, 0, -1],
      ]);
      board.reveal(0, 0);
      expect(board.grid[0][0].isRevealed, true); // detonated mine
      expect(board.grid[2][2].isRevealed, true); // other mine revealed
    });

    test('loss marks wrong flags', () {
      final board = MinesweeperBoard.fromGrid([
        [-1, 1, 0],
        [1, 1, 0],
        [0, 0, 0],
      ]);
      board.toggleFlag(1, 1); // flag a non-mine cell
      board.reveal(0, 0); // trigger loss
      expect(board.grid[1][1].isWrongFlag, true);
    });

    test('ignores reveal on flagged cell', () {
      final board = MinesweeperBoard.fromGrid([
        [0, 1, -1],
        [0, 1, 1],
        [0, 0, 0],
      ]);
      board.toggleFlag(0, 2); // flag the mine
      board.reveal(0, 2); // should be ignored
      expect(board.gameState, MinesweeperGameState.playing);
    });

    test('ignores reveal on already revealed cell', () {
      final board = MinesweeperBoard.fromGrid([
        [0, 1, -1],
        [0, 1, 1],
        [0, 0, 0],
      ]);
      board.reveal(2, 0); // reveals via flood fill
      final revealedBefore = board.grid.expand((r) => r).where((c) => c.isRevealed).length;
      board.reveal(2, 0); // reveal again — no-op
      final revealedAfter = board.grid.expand((r) => r).where((c) => c.isRevealed).length;
      expect(revealedAfter, revealedBefore);
    });
  });

  group('Win condition', () {
    test('wins when all non-mine cells are revealed', () {
      final board = MinesweeperBoard.fromGrid([
        [0, 1, -1],
        [0, 1, 1],
        [0, 0, 0],
      ]);
      // Reveal all non-mine cells
      board.reveal(0, 0); // flood fill reveals most cells
      // Check which cells are not yet revealed
      for (int r = 0; r < 3; r++) {
        for (int c = 0; c < 3; c++) {
          if (!board.grid[r][c].isMine && !board.grid[r][c].isRevealed) {
            board.reveal(r, c);
          }
        }
      }
      expect(board.gameState, MinesweeperGameState.won);
    });
  });

  group('Flag logic', () {
    test('toggleFlag places and removes flag', () {
      final board = MinesweeperBoard(rows: 9, cols: 9, totalMines: 10);
      board.toggleFlag(0, 0);
      expect(board.grid[0][0].isFlagged, true);
      expect(board.flagCount, 1);

      board.toggleFlag(0, 0);
      expect(board.grid[0][0].isFlagged, false);
      expect(board.flagCount, 0);
    });

    test('cannot flag revealed cell', () {
      final board = MinesweeperBoard.fromGrid([
        [0, 1, -1],
        [0, 1, 1],
        [0, 0, 0],
      ]);
      board.reveal(2, 0);
      board.toggleFlag(2, 0); // should be ignored
      expect(board.grid[2][0].isFlagged, false);
    });
  });

  group('Chord reveal', () {
    test('chord reveals unflagged neighbors when flags match count', () {
      final board = MinesweeperBoard.fromGrid([
        [-1, 1, 0],
        [1, 1, 0],
        [0, 0, 0],
      ]);
      board.reveal(1, 1); // reveal the "1" cell
      board.toggleFlag(0, 0); // flag the mine
      board.chordReveal(1, 1); // should reveal all unflagged neighbors
      expect(board.grid[0][1].isRevealed, true);
      expect(board.grid[1][0].isRevealed, true);
    });

    test('chord does nothing when flags dont match count', () {
      final board = MinesweeperBoard.fromGrid([
        [-1, 1, 0],
        [1, 1, 0],
        [0, 0, 0],
      ]);
      board.reveal(1, 1);
      // No flags placed, adjacentMines is 1
      board.chordReveal(1, 1); // should do nothing
      expect(board.grid[0][1].isRevealed, false);
    });

    test('chord on wrong flag triggers loss', () {
      final board = MinesweeperBoard.fromGrid([
        [-1, 2, -1],
        [1, 2, 1],
        [0, 0, 0],
      ]);
      board.reveal(1, 0); // reveal "1"
      board.toggleFlag(0, 1); // flag a non-mine cell (wrong!)
      board.chordReveal(1, 0); // adjacentFlags(1) == adjacentMines(1), reveals (0,0) which is a mine
      expect(board.gameState, MinesweeperGameState.lost);
    });

    test('chord ignores unrevealed cells', () {
      final board = MinesweeperBoard.fromGrid([
        [-1, 1, 0],
        [1, 1, 0],
        [0, 0, 0],
      ]);
      board.chordReveal(1, 1); // cell not revealed — should do nothing
      expect(board.grid[0][1].isRevealed, false);
    });
  });

  group('Remaining mines', () {
    test('remainingMines is totalMines minus flagCount', () {
      final board = MinesweeperBoard(rows: 9, cols: 9, totalMines: 10);
      expect(board.remainingMines, 10);
      board.toggleFlag(0, 0);
      expect(board.remainingMines, 9);
      board.toggleFlag(0, 1);
      expect(board.remainingMines, 8);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `fvm flutter test test/minesweeper/minesweeper_board_test.dart`
Expected: FAIL — MinesweeperBoard not found

- [ ] **Step 3: Implement MinesweeperBoard**

```dart
// lib/minesweeper/minesweeper_board.dart
import 'dart:collection';
import 'dart:math';
import 'minesweeper_cell.dart';

class MinesweeperBoard {
  final int rows;
  final int cols;
  final int totalMines;
  final Random _random = Random();

  late List<List<MinesweeperCell>> grid;
  int flagCount = 0;
  bool isFirstMove = true;
  MinesweeperGameState gameState = MinesweeperGameState.playing;

  MinesweeperBoard({
    required this.rows,
    required this.cols,
    required this.totalMines,
  }) {
    grid = List.generate(
      rows,
      (_) => List.generate(cols, (_) => MinesweeperCell()),
    );
  }

  /// Test constructor: create board from a 2D int grid.
  /// -1 = mine, any other value = non-mine cell.
  /// Non-negative values in the input are ignored — adjacentMines is
  /// auto-computed from mine positions. The values (0, 1, 2, ...) are
  /// for human readability only.
  /// Skips first-move mine placement.
  MinesweeperBoard.fromGrid(List<List<int>> values)
      : rows = values.length,
        cols = values[0].length,
        totalMines = values.expand((r) => r).where((v) => v == -1).length {
    isFirstMove = false;
    grid = List.generate(rows, (r) {
      return List.generate(cols, (c) {
        return MinesweeperCell(isMine: values[r][c] == -1);
      });
    });
    _computeAdjacentMines();
  }

  int get remainingMines => totalMines - flagCount;

  /// Reveal a cell. Triggers mine placement on first move.
  void reveal(int row, int col) {
    if (gameState != MinesweeperGameState.playing) return;
    final cell = grid[row][col];
    if (cell.isFlagged || cell.isRevealed) return;

    if (isFirstMove) {
      _placeMines(row, col);
      isFirstMove = false;
    }

    if (cell.isMine) {
      _triggerLoss();
      return;
    }

    cell.isRevealed = true;

    if (cell.adjacentMines == 0) {
      _floodFill(row, col);
    }

    _checkWin();
  }

  /// Chord reveal: if a revealed number cell has exactly enough adjacent flags,
  /// reveal all unflagged, unrevealed neighbors.
  void chordReveal(int row, int col) {
    if (gameState != MinesweeperGameState.playing) return;
    final cell = grid[row][col];
    if (!cell.isRevealed || cell.adjacentMines == 0) return;

    int adjacentFlags = 0;
    for (final (nr, nc) in _neighbors(row, col)) {
      if (grid[nr][nc].isFlagged) adjacentFlags++;
    }

    if (adjacentFlags != cell.adjacentMines) return;

    for (final (nr, nc) in _neighbors(row, col)) {
      final neighbor = grid[nr][nc];
      if (!neighbor.isRevealed && !neighbor.isFlagged) {
        if (neighbor.isMine) {
          _triggerLoss();
          return;
        }
        neighbor.isRevealed = true;
        if (neighbor.adjacentMines == 0) {
          _floodFill(nr, nc);
        }
      }
    }

    _checkWin();
  }

  /// Toggle flag on an unrevealed cell.
  void toggleFlag(int row, int col) {
    if (gameState != MinesweeperGameState.playing) return;
    final cell = grid[row][col];
    if (cell.isRevealed) return;

    cell.isFlagged = !cell.isFlagged;
    flagCount += cell.isFlagged ? 1 : -1;
  }

  /// Place mines randomly, avoiding the safe zone around (safeRow, safeCol).
  void _placeMines(int safeRow, int safeCol) {
    final candidates = <(int, int)>[];
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        // Exclude the safe zone (3x3 area centered on click, clamped to bounds)
        if ((r - safeRow).abs() <= 1 && (c - safeCol).abs() <= 1) continue;
        candidates.add((r, c));
      }
    }

    candidates.shuffle(_random);
    for (int i = 0; i < totalMines && i < candidates.length; i++) {
      final (r, c) = candidates[i];
      grid[r][c].isMine = true;
    }

    _computeAdjacentMines();
  }

  /// Compute adjacentMines for every cell.
  void _computeAdjacentMines() {
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (grid[r][c].isMine) continue;
        int count = 0;
        for (final (nr, nc) in _neighbors(r, c)) {
          if (grid[nr][nc].isMine) count++;
        }
        grid[r][c].adjacentMines = count;
      }
    }
  }

  /// BFS flood fill from an empty (adjacentMines == 0) cell.
  void _floodFill(int startRow, int startCol) {
    final queue = Queue<(int, int)>();
    queue.add((startRow, startCol));

    while (queue.isNotEmpty) {
      final (r, c) = queue.removeFirst();
      for (final (nr, nc) in _neighbors(r, c)) {
        final neighbor = grid[nr][nc];
        if (neighbor.isRevealed || neighbor.isFlagged || neighbor.isMine) continue;
        neighbor.isRevealed = true;
        if (neighbor.adjacentMines == 0) {
          queue.add((nr, nc));
        }
      }
    }
  }

  /// Trigger loss: reveal all mines, mark wrong flags.
  void _triggerLoss() {
    gameState = MinesweeperGameState.lost;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final cell = grid[r][c];
        if (cell.isMine) {
          cell.isRevealed = true;
        } else if (cell.isFlagged) {
          cell.isWrongFlag = true;
        }
      }
    }
  }

  /// Check if all non-mine cells are revealed.
  void _checkWin() {
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final cell = grid[r][c];
        if (!cell.isMine && !cell.isRevealed) return;
      }
    }
    gameState = MinesweeperGameState.won;
  }

  /// Get valid neighbor coordinates.
  List<(int, int)> _neighbors(int row, int col) {
    final result = <(int, int)>[];
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final nr = row + dr;
        final nc = col + dc;
        if (nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
          result.add((nr, nc));
        }
      }
    }
    return result;
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `fvm flutter test test/minesweeper/minesweeper_board_test.dart`
Expected: ALL PASS

- [ ] **Step 5: Commit**

```bash
git add lib/minesweeper/minesweeper_board.dart test/minesweeper/minesweeper_board_test.dart
git commit -m "feat(minesweeper): implement board logic with reveal, flag, chord, win/loss"
```

---

### Task 5: Cell Widget

**Files:**
- Create: `lib/minesweeper/minesweeper_cell_widget.dart`

- [ ] **Step 1: Implement cell rendering widget**

```dart
// lib/minesweeper/minesweeper_cell_widget.dart
import 'package:flutter/material.dart';
import 'minesweeper_cell.dart';
import 'minesweeper_colors.dart';

class MinesweeperCellWidget extends StatelessWidget {
  final MinesweeperCell cell;
  final double size;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onSecondaryTap;

  const MinesweeperCellWidget({
    super.key,
    required this.cell,
    required this.size,
    required this.onTap,
    required this.onLongPress,
    required this.onSecondaryTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      onSecondaryTap: onSecondaryTap,
      child: SizedBox(
        width: size,
        height: size,
        child: _buildCellContent(),
      ),
    );
  }

  Widget _buildCellContent() {
    if (!cell.isRevealed && !cell.isWrongFlag) {
      // Unrevealed cell (possibly flagged)
      return Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: MinesweeperColors.unrevealedSurface,
          border: Border(
            top: BorderSide(color: MinesweeperColors.unrevealedHighlight, width: 2),
            left: BorderSide(color: MinesweeperColors.unrevealedHighlight, width: 2),
            bottom: BorderSide(color: const Color(0xFF606060), width: 2),
            right: BorderSide(color: const Color(0xFF606060), width: 2),
          ),
        ),
        child: cell.isFlagged
            ? const Center(
                child: Icon(Icons.flag, color: Color(0xFFE84545), size: 18),
              )
            : null,
      );
    }

    if (cell.isWrongFlag) {
      // Wrong flag (game over)
      return Container(
        margin: const EdgeInsets.all(1),
        color: MinesweeperColors.mineSurface,
        child: const Center(
          child: Icon(Icons.close, color: Colors.white, size: 18),
        ),
      );
    }

    if (cell.isMine) {
      // Revealed mine
      return Container(
        margin: const EdgeInsets.all(1),
        color: MinesweeperColors.mineSurface,
        child: const Center(
          child: Icon(Icons.brightness_7, color: Colors.black, size: 18),
        ),
      );
    }

    // Revealed number or empty
    return Container(
      margin: const EdgeInsets.all(1),
      color: MinesweeperColors.revealedSurface,
      child: cell.adjacentMines > 0
          ? Center(
              child: Text(
                '${cell.adjacentMines}',
                style: TextStyle(
                  color: MinesweeperColors.getNumberColor(cell.adjacentMines),
                  fontWeight: FontWeight.bold,
                  fontSize: size * 0.5,
                ),
              ),
            )
          : null,
    );
  }
}
```

- [ ] **Step 2: Verify it compiles**

Run: `fvm flutter analyze lib/minesweeper/minesweeper_cell_widget.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/minesweeper/minesweeper_cell_widget.dart
git commit -m "feat(minesweeper): add cell widget with 6 visual states"
```

---

### Task 6: Game Page

**Files:**
- Create: `lib/minesweeper/minesweeper_page.dart`

- [ ] **Step 1: Implement the game page**

```dart
// lib/minesweeper/minesweeper_page.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import '../shared/game_over_data.dart';
import '../shared/game_over_page.dart';
import '../shared/game_scaffold.dart';
import '../shared/score_service.dart';
import 'minesweeper_board.dart';
import 'minesweeper_cell.dart';
import 'minesweeper_cell_widget.dart';

String formatTime(int seconds) {
  if (seconds < 60) return '$seconds s';
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}

class MinesweeperPage extends StatefulWidget {
  final MinesweeperDifficulty difficulty;

  const MinesweeperPage({super.key, required this.difficulty});

  @override
  State<MinesweeperPage> createState() => _MinesweeperPageState();
}

class _MinesweeperPageState extends State<MinesweeperPage> {
  Key _gameKey = UniqueKey();
  late MinesweeperBoard _board;
  late ValueNotifier<int> _timerNotifier;
  int _bestTime = 0;
  bool _isPaused = false;
  bool _isDigMode = true; // true = dig, false = flag
  Timer? _timer;
  int _elapsedSeconds = 0;
  Timer? _gameOverDelayTimer;

  MinesweeperDifficulty get _diff => widget.difficulty;

  @override
  void initState() {
    super.initState();
    _createGame();
    _loadBestTime();
  }

  void _createGame() {
    _board = MinesweeperBoard(
      rows: _diff.rows,
      cols: _diff.cols,
      totalMines: _diff.mines,
    );
    _timerNotifier = ValueNotifier<int>(0);
    _isPaused = false;
    _isDigMode = true;
    _elapsedSeconds = 0;
    _timer?.cancel();
    _timer = null;
    _gameOverDelayTimer?.cancel();
    _gameOverDelayTimer = null;
  }

  Future<void> _loadBestTime() async {
    _bestTime = await ScoreService().getHighScore('minesweeper', _diff.scoreMode);
    if (mounted) setState(() {});
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPaused && _board.gameState == MinesweeperGameState.playing) {
        _elapsedSeconds++;
        _timerNotifier.value = _elapsedSeconds;
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _onCellTap(int row, int col) {
    if (_board.gameState != MinesweeperGameState.playing || _isPaused) return;

    setState(() {
      if (_isDigMode) {
        // Dig mode: tap revealed number = chord, tap unrevealed = reveal
        if (_board.grid[row][col].isRevealed) {
          _board.chordReveal(row, col);
        } else {
          _board.reveal(row, col);
        }
      } else {
        // Flag mode: tap = flag
        _board.toggleFlag(row, col);
      }
    });

    // Start timer only after first reveal (not on flag-only actions)
    if (_timer == null && !_board.isFirstMove && _board.gameState == MinesweeperGameState.playing) {
      _startTimer();
    }

    _handleGameState();
  }

  void _onCellLongPress(int row, int col) {
    if (_board.gameState != MinesweeperGameState.playing || _isPaused) return;

    setState(() {
      if (_isDigMode) {
        // Dig mode: long press = flag
        _board.toggleFlag(row, col);
      } else {
        // Flag mode: long press = reveal
        if (_board.grid[row][col].isRevealed) {
          _board.chordReveal(row, col);
        } else {
          _board.reveal(row, col);
        }
      }
    });

    // Start timer only after first reveal (not on flag-only actions)
    if (_timer == null && !_board.isFirstMove && _board.gameState == MinesweeperGameState.playing) {
      _startTimer();
    }

    _handleGameState();
  }

  void _onCellSecondaryTap(int row, int col) {
    if (_board.gameState != MinesweeperGameState.playing || _isPaused) return;

    setState(() {
      _board.toggleFlag(row, col);
    });
  }

  void _handleGameState() {
    if (_board.gameState == MinesweeperGameState.won) {
      _stopTimer();
      _onWin();
    } else if (_board.gameState == MinesweeperGameState.lost) {
      _stopTimer();
      setState(() {}); // Show revealed mines
      _gameOverDelayTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) _onLoss();
      });
    }
  }

  Future<void> _onWin() async {
    await ScoreService().saveHighScore(
      'minesweeper', _diff.scoreMode, _elapsedSeconds,
      lowerIsBetter: true,
    );
    final best = await ScoreService().getHighScore('minesweeper', _diff.scoreMode);
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameOverPage(
          data: GameOverData(
            gameName: 'minesweeper',
            mode: _diff.scoreMode,
            stats: {
              'Time': formatTime(_elapsedSeconds),
              'Difficulty': _diff.name,
              'Mines': '${_diff.mines}',
              'Best': best == 0 ? '--' : formatTime(best),
            },
            replayCallback: () {
              setState(() {
                _gameKey = UniqueKey();
                _createGame();
              });
              _loadBestTime();
            },
          ),
        ),
      ),
    );
  }

  void _onLoss() {
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameOverPage(
          data: GameOverData(
            gameName: 'minesweeper',
            mode: _diff.scoreMode,
            stats: {
              'Time': formatTime(_elapsedSeconds),
              'Difficulty': _diff.name,
              'Mines': '${_diff.mines}',
            },
            replayCallback: () {
              setState(() {
                _gameKey = UniqueKey();
                _createGame();
              });
              _loadBestTime();
            },
          ),
        ),
      ),
    );
  }

  void _onPause() {
    _isPaused = true;
    _gameOverDelayTimer?.cancel();
  }

  void _onResume() {
    _isPaused = false;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _gameOverDelayTimer?.cancel();
    _timerNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      key: _gameKey,
      title: 'Minesweeper - ${_diff.name}',
      scoreNotifier: _timerNotifier,
      bestScore: _bestTime,
      scoreLabel: 'Time',
      bestLabel: 'Best',
      scoreFormatter: formatTime,
      bestFormatter: (v) => v == 0 ? '--' : formatTime(v),
      onPause: _onPause,
      onResume: _onResume,
      canPause: () => _board.gameState == MinesweeperGameState.playing,
      child: Column(
        children: [
          // Mine counter
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.brightness_7, color: Color(0xFFF0C040), size: 20),
                const SizedBox(width: 8),
                Text(
                  '${_board.remainingMines}',
                  style: TextStyle(
                    color: _board.remainingMines >= 0
                        ? const Color(0xFFF0C040)
                        : const Color(0xFFE84545),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Board
          Expanded(
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cellSize = min(
                    constraints.maxWidth / _diff.cols,
                    constraints.maxHeight / _diff.rows,
                  ).clamp(28.0, double.infinity);
                  final boardWidth = cellSize * _diff.cols;
                  final boardHeight = cellSize * _diff.rows;

                  return InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 3.0,
                    constrained: false,
                    child: SizedBox(
                      width: boardWidth,
                      height: boardHeight,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _diff.cols,
                        ),
                        itemCount: _diff.rows * _diff.cols,
                        itemBuilder: (context, index) {
                          final row = index ~/ _diff.cols;
                          final col = index % _diff.cols;
                          return MinesweeperCellWidget(
                            cell: _board.grid[row][col],
                            size: cellSize,
                            onTap: () => _onCellTap(row, col),
                            onLongPress: () => _onCellLongPress(row, col),
                            onSecondaryTap: () => _onCellSecondaryTap(row, col),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Mode toggle
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ModeButton(
                  icon: Icons.search,
                  label: 'Dig',
                  isActive: _isDigMode,
                  onTap: () => setState(() => _isDigMode = true),
                ),
                const SizedBox(width: 16),
                _ModeButton(
                  icon: Icons.flag,
                  label: 'Flag',
                  isActive: !_isDigMode,
                  onTap: () => setState(() => _isDigMode = false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF4ECCA3).withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? const Color(0xFF4ECCA3) : Colors.grey,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFF4ECCA3) : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? const Color(0xFF4ECCA3) : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify it compiles**

Run: `fvm flutter analyze lib/minesweeper/minesweeper_page.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/minesweeper/minesweeper_page.dart
git commit -m "feat(minesweeper): implement game page with timer, input, mode toggle, game over"
```

---

### Task 7: Mode Selection Page

**Files:**
- Create: `lib/minesweeper/minesweeper_mode_page.dart`

- [ ] **Step 1: Implement mode selection page**

```dart
// lib/minesweeper/minesweeper_mode_page.dart
import 'package:flutter/material.dart';
import '../shared/score_service.dart';
import 'minesweeper_cell.dart';
import 'minesweeper_page.dart';

class MinesweeperModePage extends StatelessWidget {
  const MinesweeperModePage({super.key});

  static const _modes = [
    _ModeInfo(
      title: 'Beginner',
      description: '9×9, 10 mines',
      icon: Icons.sentiment_satisfied,
      accent: Color(0xFF4ECCA3),
      difficulty: MinesweeperDifficulty.beginner,
    ),
    _ModeInfo(
      title: 'Intermediate',
      description: '16×16, 40 mines',
      icon: Icons.sentiment_neutral,
      accent: Color(0xFF3A86FF),
      difficulty: MinesweeperDifficulty.intermediate,
    ),
    _ModeInfo(
      title: 'Expert',
      description: '16×30, 99 mines',
      icon: Icons.sentiment_very_dissatisfied,
      accent: Color(0xFFE84545),
      difficulty: MinesweeperDifficulty.expert,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Minesweeper'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _modes.length,
        itemBuilder: (context, index) {
          final mode = _modes[index];
          return _ModeCard(mode: mode);
        },
      ),
    );
  }
}

class _ModeInfo {
  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final MinesweeperDifficulty difficulty;

  const _ModeInfo({
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    required this.difficulty,
  });
}

class _ModeCard extends StatefulWidget {
  final _ModeInfo mode;

  const _ModeCard({required this.mode});

  @override
  State<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<_ModeCard> {
  int _bestTime = 0;

  @override
  void initState() {
    super.initState();
    _loadScore();
  }

  Future<void> _loadScore() async {
    final score = await ScoreService()
        .getHighScore('minesweeper', widget.mode.difficulty.scoreMode);
    if (mounted) {
      setState(() => _bestTime = score);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.mode;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/minesweeper/play',
            arguments: mode.difficulty,
          ).then((_) => _loadScore());
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF16213E),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: mode.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(mode.icon, color: mode.accent, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: mode.accent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mode.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _bestTime == 0 ? 'Best: --' : 'Best: ${formatTime(_bestTime)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF0C040),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify it compiles**

Run: `fvm flutter analyze lib/minesweeper/minesweeper_mode_page.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/minesweeper/minesweeper_mode_page.dart
git commit -m "feat(minesweeper): add mode selection page with 3 difficulty levels"
```

---

### Task 8: Routing + Registry Integration

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/home/game_registry.dart`

- [ ] **Step 1: Update game_registry.dart**

In `lib/home/game_registry.dart`, change the Minesweeper entry from:
```dart
    GameInfo(
      name: 'Minesweeper',
      icon: Icons.flag,
      description: 'Find all mines without detonating',
      phase: 1,
      route: '/minesweeper',
    ),
```
to:
```dart
    GameInfo(
      name: 'Minesweeper',
      icon: Icons.flag,
      description: 'Find all mines without detonating',
      phase: 1,
      route: '/minesweeper',
      implemented: true,
      hasModePage: true,
    ),
```

- [ ] **Step 2: Update main.dart routing**

Add imports at top of `lib/main.dart`:
```dart
import 'minesweeper/minesweeper_cell.dart';
import 'minesweeper/minesweeper_mode_page.dart';
import 'minesweeper/minesweeper_page.dart';
```

Add cases in `onGenerateRoute` switch, before `default:`:
```dart
          case '/minesweeper':
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const MinesweeperModePage(),
            );
          case '/minesweeper/play':
            final difficulty = settings.arguments as MinesweeperDifficulty? ?? MinesweeperDifficulty.beginner;
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => MinesweeperPage(difficulty: difficulty),
            );
```

- [ ] **Step 3: Run all tests**

Run: `fvm flutter test`
Expected: ALL PASS

- [ ] **Step 4: Verify web build**

Run: `MSYS_NO_PATHCONV=1 fvm flutter build web --release --base-href "/mini-play/"`
Expected: Build succeeds

- [ ] **Step 5: Commit**

```bash
git add lib/main.dart lib/home/game_registry.dart
git commit -m "feat(minesweeper): wire up routing and enable in game registry"
```

---

### Task 9: Polish + Bug Fixes

Buffer task for fixing issues found during manual testing.

- [ ] **Step 1: Run the app and verify basic gameplay**

Run: `fvm flutter run -d chrome`
Verify:
1. Home page shows Minesweeper card as enabled
2. Tap Minesweeper → mode selection page with 3 difficulties
3. Tap Beginner → game starts, timer at 0, mine counter shows 10
4. Click a cell → mines placed, cell revealed, timer starts
5. Empty cell click → flood fill works
6. Long press → flag placed, mine counter decreases

- [ ] **Step 2: Verify game over flows**

- Win: reveal all non-mine cells → GameOverPage with time and best time
- Loss: click a mine → all mines revealed, 2s delay → GameOverPage
- Back button during loss delay → navigates home
- Play Again → fresh game

- [ ] **Step 3: Verify all difficulties**

- Beginner 9×9: board fits on screen
- Intermediate 16×16: board fits or scrollable
- Expert 30×16: InteractiveViewer panning works

- [ ] **Step 4: Verify input modes**

- Dig mode: tap reveals, long press flags
- Flag mode: tap flags, long press reveals
- Right-click (web): always flags
- Mode toggle button visual state

- [ ] **Step 5: Verify chord reveal**

- Place correct number of flags around a number
- Tap the number → remaining neighbors revealed
- Wrong flag + chord → loss

- [ ] **Step 6: Commit any fixes**

```bash
git add lib/minesweeper/
git commit -m "fix(minesweeper): polish gameplay and fix edge cases"
```
