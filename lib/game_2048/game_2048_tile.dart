class Tile {
  static int _nextId = 0;

  /// Reset counter — only for tests.
  static void resetIdCounter() => _nextId = 0;

  final int id;
  int value;
  int row;
  int col;
  int previousRow;
  int previousCol;
  List<Tile>? mergedFrom;
  bool isNew;

  Tile({
    required this.value,
    required this.row,
    required this.col,
    this.mergedFrom,
    this.isNew = true,
  })  : id = _nextId++,
        previousRow = row,
        previousCol = col;

  Tile._withId({
    required this.id,
    required this.value,
    required this.row,
    required this.col,
    required this.previousRow,
    required this.previousCol,
    this.mergedFrom,
    this.isNew = false,
  });

  /// Deep copy with a new id (for undo snapshots).
  Tile copy() {
    return Tile._withId(
      id: _nextId++,
      value: value,
      row: row,
      col: col,
      previousRow: row,
      previousCol: col,
      isNew: false,
    );
  }

  /// Prepare for a move: save current position as previous.
  void savePreviousPosition() {
    previousRow = row;
    previousCol = col;
  }
}
