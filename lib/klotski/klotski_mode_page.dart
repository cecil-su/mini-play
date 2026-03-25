// lib/klotski/klotski_mode_page.dart

import 'package:flutter/material.dart';
import '../shared/score_service.dart';
import 'klotski_config.dart';
import 'klotski_colors.dart';
import 'klotski_levels.dart';

class KlotskiModePage extends StatefulWidget {
  const KlotskiModePage({super.key});

  @override
  State<KlotskiModePage> createState() => _KlotskiModePageState();
}

class _KlotskiModePageState extends State<KlotskiModePage> {
  final Map<int, int> _bestMoves = {};

  @override
  void initState() {
    super.initState();
    _loadScores();
  }

  Future<void> _loadScores() async {
    final service = ScoreService();
    for (int i = 0; i < klotskiLevels.length; i++) {
      if (await service.hasScore('klotski', 'level_$i')) {
        _bestMoves[i] = await service.getHighScore('klotski', 'level_$i');
      }
    }
    if (mounted) setState(() {});
  }

  int _totalStars() {
    int stars = 0;
    for (int i = 0; i < klotskiLevels.length; i++) {
      stars += _starsForLevel(i);
    }
    return stars;
  }


  int _starsForLevel(int index) {
    final best = _bestMoves[index];
    if (best == null) return 0;
    final level = klotskiLevels[index];
    if (level.minMoves <= 0) return 1; // 未验证的关卡只计 1 星
    return _calcStars(best, level.minMoves, level.difficulty);
  }

  static int _calcStars(int moves, int minMoves, KlotskiDifficulty diff) {
    // 混合公式: threshold = minMoves + max(baseMargin, minMoves * ratio)
    final (bm3, r3, bm2, r2) = switch (diff) {
      KlotskiDifficulty.beginner => (8, 0.15, 16, 0.40),
      KlotskiDifficulty.advanced => (10, 0.20, 20, 0.50),
      KlotskiDifficulty.master => (12, 0.25, 24, 0.60),
    };
    final star3 = minMoves + _max(bm3, (minMoves * r3).round());
    final star2 = minMoves + _max(bm2, (minMoves * r2).round());
    if (moves <= star3) return 3;
    if (moves <= star2) return 2;
    return 1;
  }

  static int _max(int a, int b) => a > b ? a : b;

  bool _isDifficultyUnlocked(KlotskiDifficulty diff) {
    switch (diff) {
      case KlotskiDifficulty.beginner:
        return true;
      case KlotskiDifficulty.advanced:
        return _totalStars() >= 8 || _clearedInDifficulty(KlotskiDifficulty.beginner) >= 6;
      case KlotskiDifficulty.master:
        return _totalStars() >= 30 || _clearedInDifficulty(KlotskiDifficulty.advanced) >= 10;
    }
  }

  int _clearedInDifficulty(KlotskiDifficulty diff) {
    int count = 0;
    for (int i = diff.startIndex; i < diff.startIndex + diff.count && i < klotskiLevels.length; i++) {
      if (_bestMoves.containsKey(i)) count++;
    }
    return count;
  }

  int _starsInDifficulty(KlotskiDifficulty diff) {
    int stars = 0;
    for (int i = diff.startIndex; i < diff.startIndex + diff.count && i < klotskiLevels.length; i++) {
      stars += _starsForLevel(i);
    }
    return stars;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('华容道'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final diff in KlotskiDifficulty.values) ...[
            if (_hasLevelsInDifficulty(diff)) ...[
              _DifficultyHeader(
                difficulty: diff,
                stars: _starsInDifficulty(diff),
                maxStars: _levelCountInDifficulty(diff) * 3,
                unlocked: _isDifficultyUnlocked(diff),
              ),
              const SizedBox(height: 8),
              if (_isDifficultyUnlocked(diff))
                _LevelGrid(
                  difficulty: diff,
                  bestMoves: _bestMoves,
                  starsForLevel: _starsForLevel,
                  onRefresh: _loadScores,
                )
              else
                _LockedMessage(difficulty: diff, totalStars: _totalStars()),
              const SizedBox(height: 20),
            ],
          ],
        ],
      ),
    );
  }

  bool _hasLevelsInDifficulty(KlotskiDifficulty diff) {
    return diff.startIndex < klotskiLevels.length;
  }

  int _levelCountInDifficulty(KlotskiDifficulty diff) {
    final end = diff.startIndex + diff.count;
    if (diff.startIndex >= klotskiLevels.length) return 0;
    return (end > klotskiLevels.length ? klotskiLevels.length : end) - diff.startIndex;
  }
}

class _DifficultyHeader extends StatelessWidget {
  final KlotskiDifficulty difficulty;
  final int stars;
  final int maxStars;
  final bool unlocked;

  const _DifficultyHeader({
    required this.difficulty,
    required this.stars,
    required this.maxStars,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    final color = KlotskiColors.difficultyColor(difficulty);
    return Row(
      children: [
        Text(
          difficulty.label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: unlocked ? color : Colors.grey,
          ),
        ),
        const SizedBox(width: 8),
        if (unlocked && maxStars > 0)
          Text(
            '$stars/$maxStars \u2b50',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        if (!unlocked)
          Icon(Icons.lock, size: 16, color: Colors.grey[600]),
      ],
    );
  }
}

class _LevelGrid extends StatelessWidget {
  final KlotskiDifficulty difficulty;
  final Map<int, int> bestMoves;
  final int Function(int) starsForLevel;
  final VoidCallback onRefresh;

  const _LevelGrid({
    required this.difficulty,
    required this.bestMoves,
    required this.starsForLevel,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final count = difficulty.count;
    final actualCount = (difficulty.startIndex + count > klotskiLevels.length)
        ? klotskiLevels.length - difficulty.startIndex
        : count;
    if (actualCount <= 0) return const SizedBox.shrink();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(actualCount, (i) {
        final levelIndex = difficulty.startIndex + i;
        final level = klotskiLevels[levelIndex];
        final best = bestMoves[levelIndex];
        final stars = starsForLevel(levelIndex);
        return _LevelTile(
          levelNumber: levelIndex + 1,
          levelIndex: levelIndex,
          name: level.name,
          bestMoves: best,
          stars: stars,
          onRefresh: onRefresh,
        );
      }),
    );
  }
}

class _LevelTile extends StatelessWidget {
  final int levelNumber;
  final int levelIndex;
  final String name;
  final int? bestMoves;
  final int stars;
  final VoidCallback onRefresh;

  const _LevelTile({
    required this.levelNumber,
    required this.levelIndex,
    required this.name,
    required this.bestMoves,
    required this.stars,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final cleared = bestMoves != null;
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/klotski/play',
          arguments: levelIndex,
        ).then((_) => onRefresh());
      },
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(10),
          border: cleared
              ? Border.all(color: const Color(0xFF4ECCA3), width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (stars > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) => Icon(
                  i < stars ? Icons.star : Icons.star_border,
                  color: const Color(0xFFF0C040),
                  size: 14,
                )),
              ),
            Text(
              '$levelNumber',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              name,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 9,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            if (bestMoves != null)
              Text(
                '$bestMoves 步',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 9,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LockedMessage extends StatelessWidget {
  final KlotskiDifficulty difficulty;
  final int totalStars;

  const _LockedMessage({
    required this.difficulty,
    required this.totalStars,
  });

  @override
  Widget build(BuildContext context) {
    final (starsNeeded, altCondition) = switch (difficulty) {
      KlotskiDifficulty.beginner => (0, ''),
      KlotskiDifficulty.advanced => (8, '或 初学通关6关'),
      KlotskiDifficulty.master => (30, '或 进阶通关10关'),
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '需要累计 $starsNeeded 星 $altCondition\n当前: $totalStars 星',
        style: TextStyle(color: Colors.grey[500], fontSize: 13),
        textAlign: TextAlign.center,
      ),
    );
  }
}
