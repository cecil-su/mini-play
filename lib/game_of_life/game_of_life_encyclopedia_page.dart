import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'game_of_life_colors.dart';
import 'game_of_life_config.dart';
import 'game_of_life_game.dart';
import 'game_of_life_painter.dart';
import 'game_of_life_patterns.dart';

class GameOfLifeEncyclopediaPage extends StatefulWidget {
  final String? initialPatternId;

  const GameOfLifeEncyclopediaPage({super.key, this.initialPatternId});

  @override
  State<GameOfLifeEncyclopediaPage> createState() =>
      _GameOfLifeEncyclopediaPageState();
}

class _GameOfLifeEncyclopediaPageState
    extends State<GameOfLifeEncyclopediaPage> {
  String? _selectedCategory;
  GameOfLifePattern? _selectedPattern;

  List<GameOfLifePattern> get _filteredPatterns {
    if (_selectedCategory == null) return GameOfLifePatterns.all;
    return GameOfLifePatterns.byCategory(_selectedCategory!);
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialPatternId != null) {
      _selectedPattern = GameOfLifePatterns.byId(widget.initialPatternId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedPattern != null) {
      return _PatternDetailView(
        pattern: _selectedPattern!,
        onBack: () => setState(() => _selectedPattern = null),
        onOpenInSandbox: () {
          Navigator.pushReplacementNamed(
            context,
            '/gameoflife/sandbox',
            arguments: _selectedPattern,
          );
        },
      );
    }
    return _buildListView();
  }

  Widget _buildListView() {
    return Scaffold(
      backgroundColor: GameOfLifeColors.background,
      appBar: AppBar(
        title: const Text('图鉴百科'),
        backgroundColor: GameOfLifeColors.background,
      ),
      body: Column(
        children: [
          // Category filter
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildChip(null, '全部'),
                ...PatternCategory.all
                    .map((c) => _buildChip(c, PatternCategory.label(c))),
              ],
            ),
          ),
          // Pattern grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.9,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _filteredPatterns.length,
              itemBuilder: (context, index) {
                final pattern = _filteredPatterns[index];
                return _EncyclopediaCard(
                  pattern: pattern,
                  onTap: () => setState(() => _selectedPattern = pattern),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String? category, String label) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: GameOfLifeColors.cellAlive.withValues(alpha: 0.3),
        onSelected: (_) => setState(() => _selectedCategory = category),
      ),
    );
  }
}

class _EncyclopediaCard extends StatelessWidget {
  final GameOfLifePattern pattern;
  final VoidCallback onTap;

  const _EncyclopediaCard({required this.pattern, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: CustomPaint(
                painter: PatternThumbnailPainter(
                  cells: pattern.cells,
                  patternWidth: pattern.width,
                  patternHeight: pattern.height,
                ),
                child: const SizedBox.expand(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${pattern.name} ${pattern.nameEn}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              pattern.brief,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _PatternDetailView extends StatefulWidget {
  final GameOfLifePattern pattern;
  final VoidCallback onBack;
  final VoidCallback onOpenInSandbox;

  const _PatternDetailView({
    required this.pattern,
    required this.onBack,
    required this.onOpenInSandbox,
  });

  @override
  State<_PatternDetailView> createState() => _PatternDetailViewState();
}

class _PatternDetailViewState extends State<_PatternDetailView>
    with SingleTickerProviderStateMixin {
  late GameOfLifeGame _game;
  late Ticker _ticker;
  int _paintVersion = 0;
  Duration _lastElapsed = Duration.zero;
  double _accumulator = 0;

  @override
  void initState() {
    super.initState();
    _game = GameOfLifeGame();
    _placePattern();
    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  void _placePattern() {
    _game.clear();
    // Center the pattern
    final cx = GameOfLifeConfig.gridWidth ~/ 2 - widget.pattern.width ~/ 2;
    final cy = GameOfLifeConfig.gridHeight ~/ 2 - widget.pattern.height ~/ 2;
    for (final (x, y) in widget.pattern.cells) {
      _game.setCell(cx + x, cy + y, 1);
    }
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    _accumulator += dt;

    if (_accumulator >= 0.15) {
      _game.evolve();
      _accumulator -= 0.15;
      setState(() => _paintVersion++);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameOfLifeColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: Text('${widget.pattern.name} ${widget.pattern.nameEn}'),
        backgroundColor: GameOfLifeColors.background,
      ),
      body: Column(
        children: [
          // Animation view (top 50%)
          Expanded(
            flex: 5,
            child: Container(
              color: GameOfLifeColors.background,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Show a region around the pattern
                  final pw = widget.pattern.width + 10;
                  final ph = widget.pattern.height + 10;
                  final regionSize = max(pw, ph).toDouble();
                  final cellSize =
                      min(constraints.maxWidth, constraints.maxHeight) /
                          regionSize;

                  final cx = GameOfLifeConfig.gridWidth ~/ 2;
                  final cy = GameOfLifeConfig.gridHeight ~/ 2;

                  return ClipRect(
                    child: CustomPaint(
                      painter: _DetailPainter(
                        game: _game,
                        cellSize: cellSize,
                        centerX: cx,
                        centerY: cy,
                        viewRadius: (regionSize / 2).ceil(),
                        paintVersion: _paintVersion,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  );
                },
              ),
            ),
          ),
          // Info section (bottom 50%)
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Metadata chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (widget.pattern.period != null)
                        _MetaChip(
                          label: '周期',
                          value: '${widget.pattern.period}',
                        ),
                      if (widget.pattern.speed != null)
                        _MetaChip(
                          label: '速度',
                          value: widget.pattern.speed!,
                        ),
                      _MetaChip(
                        label: '细胞数',
                        value: '${widget.pattern.cells.length}',
                      ),
                      if (widget.pattern.discoverer != null)
                        _MetaChip(
                          label: '发现者',
                          value: widget.pattern.discoverer!,
                        ),
                      if (widget.pattern.year != null)
                        _MetaChip(
                          label: '年份',
                          value: '${widget.pattern.year}',
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.pattern.description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: widget.onOpenInSandbox,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GameOfLifeColors.cellAlive,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon:
                          const Icon(Icons.open_in_new, color: Colors.black),
                      label: const Text(
                        '在沙盒中打开',
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final String value;

  const _MetaChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
    );
  }
}

/// Custom painter that renders a region around a center point.
class _DetailPainter extends CustomPainter {
  final GameOfLifeGame game;
  final double cellSize;
  final int centerX;
  final int centerY;
  final int viewRadius;
  final int paintVersion;

  _DetailPainter({
    required this.game,
    required this.cellSize,
    required this.centerX,
    required this.centerY,
    required this.viewRadius,
    required this.paintVersion,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final startX = centerX - viewRadius;
    final startY = centerY - viewRadius;
    final endX = centerX + viewRadius;
    final endY = centerY + viewRadius;

    for (int y = startY; y <= endY; y++) {
      for (int x = startX; x <= endX; x++) {
        final wx = ((x % GameOfLifeConfig.gridWidth) + GameOfLifeConfig.gridWidth) %
            GameOfLifeConfig.gridWidth;
        final wy = ((y % GameOfLifeConfig.gridHeight) + GameOfLifeConfig.gridHeight) %
            GameOfLifeConfig.gridHeight;
        if (game.current[wy * GameOfLifeConfig.gridWidth + wx] == 1) {
          path.addRect(Rect.fromLTWH(
            (x - startX) * cellSize,
            (y - startY) * cellSize,
            cellSize,
            cellSize,
          ));
        }
      }
    }

    canvas.drawPath(path, Paint()..color = GameOfLifeColors.cellAlive);

    // Grid lines
    if (cellSize >= 4) {
      final linePaint = Paint()
        ..color = GameOfLifeColors.gridLine
        ..strokeWidth = 0.5;
      final w = (endX - startX + 1) * cellSize;
      final h = (endY - startY + 1) * cellSize;
      for (int x = startX; x <= endX + 1; x++) {
        final dx = (x - startX) * cellSize;
        canvas.drawLine(Offset(dx, 0), Offset(dx, h), linePaint);
      }
      for (int y = startY; y <= endY + 1; y++) {
        final dy = (y - startY) * cellSize;
        canvas.drawLine(Offset(0, dy), Offset(w, dy), linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(_DetailPainter old) => old.paintVersion != paintVersion;
}
