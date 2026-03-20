import 'package:flutter_test/flutter_test.dart';
import 'package:mini_play/game_2048/game_2048_tile.dart';

void main() {
  group('Tile', () {
    test('creates with auto-incremented id', () {
      Tile.resetIdCounter();
      final t1 = Tile(value: 2, row: 0, col: 0);
      final t2 = Tile(value: 4, row: 1, col: 1);
      expect(t1.id, 0);
      expect(t2.id, 1);
    });

    test('initializes with isNew true and no mergedFrom', () {
      Tile.resetIdCounter();
      final t = Tile(value: 2, row: 0, col: 0);
      expect(t.isNew, true);
      expect(t.mergedFrom, isNull);
    });

    test('previousRow/Col default to current position', () {
      Tile.resetIdCounter();
      final t = Tile(value: 2, row: 2, col: 3);
      expect(t.previousRow, 2);
      expect(t.previousCol, 3);
    });

    test('copy creates deep copy with new id', () {
      Tile.resetIdCounter();
      final t = Tile(value: 8, row: 1, col: 2);
      final c = t.copy();
      expect(c.value, 8);
      expect(c.row, 1);
      expect(c.col, 2);
      expect(c.id, isNot(t.id));
    });
  });
}
