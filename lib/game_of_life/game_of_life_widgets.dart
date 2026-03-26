import 'package:flutter/material.dart';

import 'game_of_life_colors.dart';
import 'game_of_life_config.dart';
import 'game_of_life_painter.dart';
import 'game_of_life_patterns.dart';

/// Top info bar showing generation count, alive cells, and speed.
class GameOfLifeInfoBar extends StatelessWidget {
  final int generation;
  final int aliveCells;
  final bool isRunning;
  final int speedIndex;

  const GameOfLifeInfoBar({
    super.key,
    required this.generation,
    required this.aliveCells,
    required this.isRunning,
    required this.speedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: GameOfLifeColors.background,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _InfoChip(
            label: 'Gen',
            value: '$generation',
            icon: Icons.timeline,
          ),
          _InfoChip(
            label: 'Cells',
            value: '$aliveCells',
            icon: Icons.grid_on,
          ),
          _InfoChip(
            label: isRunning ? GameOfLifeConfig.speedLabels[speedIndex] : '暂停',
            value: isRunning ? '${GameOfLifeConfig.speedLevels[speedIndex]}/s' : '',
            icon: isRunning ? Icons.play_arrow : Icons.pause,
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: GameOfLifeColors.cellAlive),
        const SizedBox(width: 4),
        Text(
          value.isNotEmpty ? '$label: $value' : label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

/// Bottom control bar with 5 buttons + draw mode toggle.
class GameOfLifeControlBar extends StatelessWidget {
  final bool isRunning;
  final int speedIndex;
  final InteractionMode interactionMode;
  final VoidCallback onTogglePlay;
  final VoidCallback onStep;
  final VoidCallback onSpeedChange;
  final VoidCallback onClear;
  final VoidCallback onPatternLibrary;
  final VoidCallback onToggleDrawMode;

  const GameOfLifeControlBar({
    super.key,
    required this.isRunning,
    required this.speedIndex,
    required this.interactionMode,
    required this.onTogglePlay,
    required this.onStep,
    required this.onSpeedChange,
    required this.onClear,
    required this.onPatternLibrary,
    required this.onToggleDrawMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: GameOfLifeColors.background,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ControlButton(
            icon: interactionMode == InteractionMode.draw
                ? Icons.edit
                : Icons.pan_tool,
            label: interactionMode == InteractionMode.draw ? '画笔' : '移动',
            onPressed: onToggleDrawMode,
            isActive: interactionMode == InteractionMode.draw,
          ),
          _ControlButton(
            icon: Icons.auto_stories,
            label: '图案',
            onPressed: onPatternLibrary,
          ),
          _ControlButton(
            icon: Icons.skip_next,
            label: '单步',
            onPressed: onStep,
          ),
          _ControlButton(
            icon: isRunning ? Icons.pause : Icons.play_arrow,
            label: isRunning ? '暂停' : '播放',
            onPressed: onTogglePlay,
            isActive: isRunning,
          ),
          _ControlButton(
            icon: Icons.speed,
            label: GameOfLifeConfig.speedLabels[speedIndex],
            onPressed: onSpeedChange,
          ),
          _ControlButton(
            icon: Icons.delete_outline,
            label: '清空',
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isActive;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: isActive ? GameOfLifeColors.cellAlive : Colors.white70,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? GameOfLifeColors.cellAlive : Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pattern placement toolbar (rotate / confirm / cancel).
class PatternPlacementBar extends StatelessWidget {
  final VoidCallback onRotate;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final int rotation;

  const PatternPlacementBar({
    super.key,
    required this.onRotate,
    required this.onConfirm,
    required this.onCancel,
    required this.rotation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: GameOfLifeColors.cellAlive.withValues(alpha: 0.15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.close, color: Colors.white70),
            label: const Text('取消', style: TextStyle(color: Colors.white70)),
          ),
          TextButton.icon(
            onPressed: onRotate,
            icon: const Icon(Icons.rotate_right, color: Colors.white),
            label: Text('旋转 ${rotation * 90}°',
                style: const TextStyle(color: Colors.white)),
          ),
          ElevatedButton.icon(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: GameOfLifeColors.cellAlive,
            ),
            icon: const Icon(Icons.check, color: Colors.black),
            label: const Text('放置', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}

/// Pattern library bottom sheet.
class PatternLibrarySheet extends StatefulWidget {
  final void Function(GameOfLifePattern) onSelect;

  const PatternLibrarySheet({super.key, required this.onSelect});

  @override
  State<PatternLibrarySheet> createState() => _PatternLibrarySheetState();
}

class _PatternLibrarySheetState extends State<PatternLibrarySheet> {
  String? _selectedCategory;

  List<GameOfLifePattern> get _filteredPatterns {
    if (_selectedCategory == null) return GameOfLifePatterns.all;
    return GameOfLifePatterns.byCategory(_selectedCategory!);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.1,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF16213E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Category filter chips
              SizedBox(
                height: 40,
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
              const SizedBox(height: 8),
              // Pattern grid
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _filteredPatterns.length,
                  itemBuilder: (context, index) {
                    final pattern = _filteredPatterns[index];
                    return _PatternCard(
                      pattern: pattern,
                      onTap: () => widget.onSelect(pattern),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChip(String? category, String label) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        selectedColor: GameOfLifeColors.cellAlive.withValues(alpha: 0.3),
        onSelected: (_) => setState(() => _selectedCategory = category),
      ),
    );
  }
}

class _PatternCard extends StatelessWidget {
  final GameOfLifePattern pattern;
  final VoidCallback onTap;

  const _PatternCard({required this.pattern, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CustomPaint(
                painter: PatternThumbnailPainter(
                  cells: pattern.cells,
                  patternWidth: pattern.width,
                  patternHeight: pattern.height,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              pattern.name,
              style: const TextStyle(fontSize: 11, color: Colors.white),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              pattern.brief,
              style: const TextStyle(fontSize: 9, color: Colors.white54),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
