import 'dart:typed_data';

import 'game_of_life_config.dart';

class HistoryBuffer {
  static const int capacity = GameOfLifeConfig.historyCapacity;

  final List<int> _hashes = List.filled(capacity, 0);
  final List<int> _generations = List.filled(capacity, -1);
  final List<double> _centerXs = List.filled(capacity, 0);
  final List<double> _centerYs = List.filled(capacity, 0);
  final List<int> _aliveCounts = List.filled(capacity, 0);
  int _head = 0;
  int _size = 0;

  void push(int hash, int generation, double cx, double cy, int alive) {
    _hashes[_head] = hash;
    _generations[_head] = generation;
    _centerXs[_head] = cx;
    _centerYs[_head] = cy;
    _aliveCounts[_head] = alive;
    _head = (_head + 1) % capacity;
    if (_size < capacity) _size++;
  }

  /// Returns period length if current hash matches a history entry, 0 otherwise.
  /// Skips the most recent entry (i=0) since it's the current state itself.
  int detectPeriod(int currentHash) {
    for (int i = 1; i < _size; i++) {
      final idx = (_head - 1 - i + capacity) % capacity;
      if (_hashes[idx] == currentHash) {
        return i;
      }
    }
    return 0;
  }

  /// Check if center shifted during the given period (spaceship detection).
  bool hasCenterShift(int period) {
    if (period <= 0 || period > _size) return false;
    final currentIdx = (_head - 1 + capacity) % capacity;
    final pastIdx = (_head - 1 - period + capacity) % capacity;
    final dx = (_centerXs[currentIdx] - _centerXs[pastIdx]).abs();
    final dy = (_centerYs[currentIdx] - _centerYs[pastIdx]).abs();
    // Account for toroidal wrap: if shift > half grid, it wrapped
    final halfW = GameOfLifeConfig.gridWidth / 2;
    final halfH = GameOfLifeConfig.gridHeight / 2;
    final actualDx = dx > halfW ? GameOfLifeConfig.gridWidth - dx : dx;
    final actualDy = dy > halfH ? GameOfLifeConfig.gridHeight - dy : dy;
    return actualDx > 0.5 || actualDy > 0.5;
  }

  void clear() {
    _head = 0;
    _size = 0;
  }
}

class GameOfLifeGame {
  static const int gridWidth = GameOfLifeConfig.gridWidth;
  static const int gridHeight = GameOfLifeConfig.gridHeight;
  static const int gridSize = GameOfLifeConfig.gridSize;

  Uint8List _bufferA = Uint8List(gridSize);
  Uint8List _bufferB = Uint8List(gridSize);
  late Uint8List current = _bufferA;
  late Uint8List next = _bufferB;

  final HistoryBuffer _history = HistoryBuffer();

  int generation = 0;
  int aliveCellCount = 0;

  // Bounding box of alive cells (inclusive)
  int minX = gridWidth;
  int maxX = 0;
  int minY = gridHeight;
  int maxY = 0;

  // Cells born in the last evolve (for highlight rendering)
  Set<(int, int)> newBornCells = {};

  // --- Core methods ---

  int cellAt(int x, int y) {
    final wx = ((x % gridWidth) + gridWidth) % gridWidth;
    final wy = ((y % gridHeight) + gridHeight) % gridHeight;
    return current[wy * gridWidth + wx];
  }

  void toggleCell(int x, int y) {
    final wx = ((x % gridWidth) + gridWidth) % gridWidth;
    final wy = ((y % gridHeight) + gridHeight) % gridHeight;
    final idx = wy * gridWidth + wx;
    if (current[idx] == 1) {
      current[idx] = 0;
      aliveCellCount--;
    } else {
      current[idx] = 1;
      aliveCellCount++;
      _expandBoundingBox(wx, wy);
    }
  }

  void setCell(int x, int y, int value) {
    final wx = ((x % gridWidth) + gridWidth) % gridWidth;
    final wy = ((y % gridHeight) + gridHeight) % gridHeight;
    final idx = wy * gridWidth + wx;
    final old = current[idx];
    if (old == value) return;
    current[idx] = value;
    if (value == 1) {
      aliveCellCount++;
      _expandBoundingBox(wx, wy);
    } else {
      aliveCellCount--;
    }
  }

  void setCells(Iterable<(int, int)> cells) {
    for (final (x, y) in cells) {
      setCell(x, y, 1);
    }
  }

  void clear() {
    _bufferA = Uint8List(gridSize);
    _bufferB = Uint8List(gridSize);
    current = _bufferA;
    next = _bufferB;
    generation = 0;
    aliveCellCount = 0;
    minX = gridWidth;
    maxX = 0;
    minY = gridHeight;
    maxY = 0;
    newBornCells = {};
    _history.clear();
  }

  bool get isEmpty => aliveCellCount == 0;

  double get aliveRatio => aliveCellCount / gridSize;

  // --- Evolution ---

  void evolve() {
    if (isEmpty) {
      generation++;
      final hash = computeStateHash();
      _history.push(hash, generation, 0, 0, 0);
      return;
    }

    // Determine scan range (bounding box + 1, or full grid if near edges)
    // If bounding box touches any edge, fall back to full scan for that axis
    // to correctly handle toroidal wrapping.
    final bool scanAllX = (maxX - minX + 3) > gridWidth * 0.7 ||
        minX == 0 || maxX == gridWidth - 1;
    final bool scanAllY = (maxY - minY + 3) > gridHeight * 0.7 ||
        minY == 0 || maxY == gridHeight - 1;

    final sMinX = scanAllX ? 0 : minX - 1;
    final sMaxX = scanAllX ? gridWidth - 1 : maxX + 1;
    final sMinY = scanAllY ? 0 : minY - 1;
    final sMaxY = scanAllY ? gridHeight - 1 : maxY + 1;

    // Clear next buffer in scan range
    for (int y = sMinY; y <= sMaxY; y++) {
      final rowOff = y * gridWidth;
      for (int x = sMinX; x <= sMaxX; x++) {
        next[rowOff + x] = 0;
      }
    }

    int newAlive = 0;
    int newMinX = gridWidth, newMaxX = 0;
    int newMinY = gridHeight, newMaxY = 0;
    final born = <(int, int)>{};

    for (int y = sMinY; y <= sMaxY; y++) {
      final ym1 = y == 0 ? gridHeight - 1 : y - 1;
      final yp1 = y == gridHeight - 1 ? 0 : y + 1;
      final rowOff = y * gridWidth;
      final rowOffM1 = ym1 * gridWidth;
      final rowOffP1 = yp1 * gridWidth;

      for (int x = sMinX; x <= sMaxX; x++) {
        final xm1 = x == 0 ? gridWidth - 1 : x - 1;
        final xp1 = x == gridWidth - 1 ? 0 : x + 1;

        final neighbors = current[rowOffM1 + xm1] +
            current[rowOffM1 + x] +
            current[rowOffM1 + xp1] +
            current[rowOff + xm1] +
            current[rowOff + xp1] +
            current[rowOffP1 + xm1] +
            current[rowOffP1 + x] +
            current[rowOffP1 + xp1];

        final alive = current[rowOff + x];

        if (neighbors == 3 || (neighbors == 2 && alive == 1)) {
          next[rowOff + x] = 1;
          newAlive++;
          if (x < newMinX) newMinX = x;
          if (x > newMaxX) newMaxX = x;
          if (y < newMinY) newMinY = y;
          if (y > newMaxY) newMaxY = y;
          if (alive == 0) born.add((x, y));
        }
      }
    }

    // Swap buffers
    final temp = current;
    current = next;
    next = temp;

    aliveCellCount = newAlive;
    newBornCells = born;

    if (newAlive > 0) {
      minX = newMinX;
      maxX = newMaxX;
      minY = newMinY;
      maxY = newMaxY;
    } else {
      minX = gridWidth;
      maxX = 0;
      minY = gridHeight;
      maxY = 0;
    }

    generation++;

    // Push to history
    final (cx, cy) = _center();
    final hash = computeStateHash();
    _history.push(hash, generation, cx, cy, aliveCellCount);
  }

  // --- Hash & Detection ---

  /// FNV-1a normalized hash (coordinates relative to bounding box top-left).
  int computeStateHash() {
    if (isEmpty) return 0;
    int hash = 0x1CBFB28CE48422; // FNV offset basis truncated to 53-bit safe
    const int prime = 0x1000193; // FNV-1a 32-bit prime (JS-safe)

    for (int y = minY; y <= maxY; y++) {
      final rowOff = y * gridWidth;
      for (int x = minX; x <= maxX; x++) {
        if (current[rowOff + x] == 1) {
          hash ^= (x - minX);
          hash = (hash * prime) & 0x1FFFFFFFFFFFFF; // 53-bit safe for JS
          hash ^= (y - minY);
          hash = (hash * prime) & 0x1FFFFFFFFFFFFF;
        }
      }
    }
    return hash;
  }

  int detectPeriod() {
    final hash = computeStateHash();
    return _history.detectPeriod(hash);
  }

  bool isStillLife() => detectPeriod() == 1;

  bool isOscillator() {
    final period = detectPeriod();
    return period > 1 && !_history.hasCenterShift(period);
  }

  bool isSpaceship() {
    final period = detectPeriod();
    return period > 0 && _history.hasCenterShift(period);
  }

  /// Match current state hash against a list of known pattern hashes.
  /// Returns index if matched, null otherwise.
  int? matchKnownPattern(List<int> knownHashes) {
    if (isEmpty) return null;
    final hash = computeStateHash();
    for (int i = 0; i < knownHashes.length; i++) {
      if (knownHashes[i] == hash) return i;
    }
    return null;
  }

  // --- Helpers ---

  (double, double) _center() {
    if (isEmpty) return (0, 0);
    return ((minX + maxX) / 2.0, (minY + maxY) / 2.0);
  }

  void _expandBoundingBox(int x, int y) {
    if (x < minX) minX = x;
    if (x > maxX) maxX = x;
    if (y < minY) minY = y;
    if (y > maxY) maxY = y;
  }
}
