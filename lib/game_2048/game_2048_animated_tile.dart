// lib/game_2048/game_2048_animated_tile.dart
import 'package:flutter/material.dart';
import 'game_2048_tile.dart';
import 'game_2048_colors.dart';

const Duration kTileAnimationDuration = Duration(milliseconds: 200);

class AnimatedTileWidget extends StatefulWidget {
  final Tile tile;
  final double cellSize;
  final double spacing;
  final int gridSize;

  const AnimatedTileWidget({
    required this.tile,
    required this.cellSize,
    required this.spacing,
    required this.gridSize,
    super.key,
  });

  @override
  State<AnimatedTileWidget> createState() => _AnimatedTileWidgetState();
}

class _AnimatedTileWidgetState extends State<AnimatedTileWidget>
    with TickerProviderStateMixin {
  late AnimationController _moveController;
  late AnimationController _scaleController;
  late Animation<double> _moveRowAnimation;
  late Animation<double> _moveColAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _moveController = AnimationController(
      duration: kTileAnimationDuration,
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: kTileAnimationDuration,
      vsync: this,
    );

    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    final tile = widget.tile;
    final cellWithSpacing = widget.cellSize + widget.spacing;

    // Move animation
    _moveRowAnimation = Tween<double>(
      begin: tile.previousRow * cellWithSpacing,
      end: tile.row * cellWithSpacing,
    ).animate(CurvedAnimation(
      parent: _moveController,
      curve: Curves.easeInOut,
    ));

    _moveColAnimation = Tween<double>(
      begin: tile.previousCol * cellWithSpacing,
      end: tile.col * cellWithSpacing,
    ).animate(CurvedAnimation(
      parent: _moveController,
      curve: Curves.easeInOut,
    ));

    // Scale + opacity animation
    if (tile.isNew) {
      // New tile: scale from 0 to 1 + fade in
      _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
      );
      _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
      );
    } else if (tile.mergedFrom != null) {
      // Merged tile: pop effect 1.0 → 1.2 → 1.0
      _scaleAnimation = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 50),
        TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50),
      ]).animate(CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeInOut,
      ));
    } else {
      _scaleAnimation = AlwaysStoppedAnimation(1.0);
    }

    // Non-new tiles are fully opaque
    if (!tile.isNew) {
      _opacityAnimation = AlwaysStoppedAnimation(1.0);
    }
  }

  void _startAnimations() {
    final tile = widget.tile;
    final hasMoved = tile.previousRow != tile.row || tile.previousCol != tile.col;

    if (hasMoved || tile.mergedFrom != null) {
      _moveController.forward();
    } else {
      _moveController.value = 1.0;
    }

    if (tile.isNew || tile.mergedFrom != null) {
      _scaleController.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedTileWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tile.id != widget.tile.id ||
        oldWidget.tile.row != widget.tile.row ||
        oldWidget.tile.col != widget.tile.col) {
      _moveController.reset();
      _scaleController.reset();
      _setupAnimations();
      _startAnimations();
    }
  }

  @override
  void dispose() {
    _moveController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use AnimatedBuilder inside a bare widget — not Positioned — because
    // AnimatedBuilder is the direct child of the Stack, and Stack only
    // recognises Positioned children.  Instead we use Transform.translate
    // for positioning so it works as any Stack child.
    return AnimatedBuilder(
      animation: Listenable.merge([_moveController, _scaleController]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            _moveColAnimation.value + widget.spacing,
            _moveRowAnimation.value + widget.spacing,
          ),
          child: SizedBox(
            width: widget.cellSize,
            height: widget.cellSize,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            ),
          ),
        );
      },
      child: _TileContent(
        value: widget.tile.value,
        cellSize: widget.cellSize,
      ),
    );
  }
}

class _TileContent extends StatelessWidget {
  final int value;
  final double cellSize;

  const _TileContent({required this.value, required this.cellSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TileColors.getBackground(value),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Text(
              '$value',
              style: TextStyle(
                color: TileColors.getTextColor(value),
                fontSize: cellSize * 0.4,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
