import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mini_play/shared/score_service.dart';

void main() {
  group('ScoreService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('returns 0 for no saved score', () async {
      final service = ScoreService();
      expect(await service.getHighScore('snake', 'classic'), 0);
    });

    test('saves and retrieves high score', () async {
      final service = ScoreService();
      await service.saveHighScore('snake', 'classic', 10);
      expect(await service.getHighScore('snake', 'classic'), 10);
    });

    test('only saves higher score', () async {
      final service = ScoreService();
      await service.saveHighScore('snake', 'classic', 10);
      await service.saveHighScore('snake', 'classic', 5);
      expect(await service.getHighScore('snake', 'classic'), 10);
    });

    test('uses default mode for modeless games', () async {
      final service = ScoreService();
      await service.saveHighScore('2048', 'default', 2048);
      expect(await service.getHighScore('2048', 'default'), 2048);
    });

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
  });
}
