import 'package:shared_preferences/shared_preferences.dart';

class ScoreService {
  static final ScoreService _instance = ScoreService._();
  factory ScoreService() => _instance;
  ScoreService._();

  String _key(String game, String mode) => 'highscore_${game}_$mode';

  Future<int> getHighScore(String game, String mode) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key(game, mode)) ?? 0;
  }

  Future<void> saveHighScore(String game, String mode, int score) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_key(game, mode)) ?? 0;
    if (score > current) {
      await prefs.setInt(_key(game, mode), score);
    }
  }
}
