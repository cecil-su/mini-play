// lib/klotski/klotski_block_widget.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'klotski_config.dart';
import 'klotski_models.dart';
import 'klotski_colors.dart';

class KlotskiBlockWidget extends StatefulWidget {
  final Block block;
  final double cellSize;
  final int Function(Direction dir) maxDistance;
  final void Function(Direction dir, int distance) onMoved;
  final bool enabled;
  final bool isSelected;
  final bool isHinted;
  final Direction? hintDirection;

  const KlotskiBlockWidget({
    required this.block,
    required this.cellSize,
    required this.maxDistance,
    required this.onMoved,
    this.enabled = true,
    this.isSelected = false,
    this.isHinted = false,
    this.hintDirection,
    super.key,
  });

  @override
  State<KlotskiBlockWidget> createState() => _KlotskiBlockWidgetState();
}

class _KlotskiBlockWidgetState extends State<KlotskiBlockWidget>
    with TickerProviderStateMixin {
  late AnimationController _snapController;
  late Animation<Offset> _snapAnimation;

  // Hint pulse animation
  late AnimationController _hintController;
  late Animation<double> _hintPulse;

  Offset _dragOffset = Offset.zero;
  Axis? _lockedAxis;
  bool _isDragging = false;
  Map<Direction, int> _maxDistances = {};

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _snapAnimation = const AlwaysStoppedAnimation(Offset.zero);

    _hintController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _hintPulse = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _hintController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(KlotskiBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHinted && !oldWidget.isHinted) {
      _hintController.repeat(reverse: true);
    } else if (!widget.isHinted && oldWidget.isHinted) {
      _hintController.stop();
      _hintController.reset();
    }
  }

  @override
  void dispose() {
    _snapController.dispose();
    _hintController.dispose();
    super.dispose();
  }

  Offset get _baseOffset => Offset(
    widget.block.col * widget.cellSize,
    widget.block.row * widget.cellSize,
  );

  Offset get _currentOffset {
    if (_isDragging) return _baseOffset + _dragOffset;
    return _baseOffset + _snapAnimation.value;
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.enabled) return;
    _snapController.stop();
    _isDragging = true;
    _dragOffset = Offset.zero;
    _lockedAxis = null;
    _maxDistances = {
      for (final dir in Direction.values) dir: widget.maxDistance(dir),
    };
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    final delta = details.delta;
    var newOffset = _dragOffset + delta;

    // Axis lock after >8px
    if (_lockedAxis == null) {
      if (newOffset.dx.abs() > 8 || newOffset.dy.abs() > 8) {
        _lockedAxis = newOffset.dx.abs() >= newOffset.dy.abs()
            ? Axis.horizontal
            : Axis.vertical;
      }
    }

    if (_lockedAxis == Axis.horizontal) {
      newOffset = Offset(newOffset.dx, 0);
    } else if (_lockedAxis == Axis.vertical) {
      newOffset = Offset(0, newOffset.dy);
    }

    // Clamp to maxDistance
    final cs = widget.cellSize;
    if (_lockedAxis == Axis.horizontal) {
      final maxRight = (_maxDistances[Direction.right] ?? 0) * cs;
      final maxLeft = (_maxDistances[Direction.left] ?? 0) * cs;
      newOffset = Offset(newOffset.dx.clamp(-maxLeft, maxRight), 0);
    } else if (_lockedAxis == Axis.vertical) {
      final maxDown = (_maxDistances[Direction.down] ?? 0) * cs;
      final maxUp = (_maxDistances[Direction.up] ?? 0) * cs;
      newOffset = Offset(0, newOffset.dy.clamp(-maxUp, maxDown));
    }

    setState(() => _dragOffset = newOffset);
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;

    final cs = widget.cellSize;
    final threshold = cs * 0.4;

    Direction? dir;
    int distance = 0;

    if (_lockedAxis == Axis.horizontal) {
      if (_dragOffset.dx > threshold) {
        dir = Direction.right;
        distance = (_dragOffset.dx / cs).round().clamp(1, _maxDistances[Direction.right] ?? 0);
      } else if (_dragOffset.dx < -threshold) {
        dir = Direction.left;
        distance = (-_dragOffset.dx / cs).round().clamp(1, _maxDistances[Direction.left] ?? 0);
      }
    } else if (_lockedAxis == Axis.vertical) {
      if (_dragOffset.dy > threshold) {
        dir = Direction.down;
        distance = (_dragOffset.dy / cs).round().clamp(1, _maxDistances[Direction.down] ?? 0);
      } else if (_dragOffset.dy < -threshold) {
        dir = Direction.up;
        distance = (-_dragOffset.dy / cs).round().clamp(1, _maxDistances[Direction.up] ?? 0);
      }
    }

    if (dir != null && distance > 0) {
      final targetOffset = Offset(
        dir.dx * distance * cs,
        dir.dy * distance * cs,
      );
      _animateSnap(_dragOffset, targetOffset, Curves.easeOutCubic, () {
        widget.onMoved(dir!, distance);
      });
    } else {
      _animateSnap(_dragOffset, Offset.zero, Curves.easeOut, null);
    }
  }

  void _animateSnap(Offset from, Offset to, Curve curve, VoidCallback? onDone) {
    _snapAnimation = Tween<Offset>(begin: from, end: to).animate(
      CurvedAnimation(parent: _snapController, curve: curve),
    );
    _snapController.reset();
    _snapController.duration = Duration(milliseconds: to == Offset.zero ? 100 : 150);

    void listener(AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        _snapController.removeStatusListener(listener);
        if (onDone != null) onDone();
        setState(() {
          _snapAnimation = const AlwaysStoppedAnimation(Offset.zero);
        });
      }
    }
    _snapController.addStatusListener(listener);
    _snapController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.cellSize;
    final block = widget.block;
    final blockWidth = block.width * cs;
    final blockHeight = block.height * cs;
    const inset = 2.0;

    return AnimatedBuilder(
      animation: Listenable.merge([_snapController, _hintController]),
      builder: (context, child) {
        return Transform.translate(
          offset: _currentOffset,
          child: GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: SizedBox(
              width: blockWidth,
              height: blockHeight,
              child: Padding(
                padding: const EdgeInsets.all(inset),
                child: Stack(
                  children: [
                    // Main block body
                    Container(
                      decoration: BoxDecoration(
                        color: KlotskiColors.bgForType(block.type),
                        borderRadius: BorderRadius.circular(4),
                        border: _buildBorder(),
                        boxShadow: _buildShadow(),
                      ),
                      child: Center(
                        child: Text(
                          block.label,
                          style: TextStyle(
                            color: KlotskiColors.blockText,
                            fontSize: cs * 0.4,
                            fontWeight: FontWeight.bold,
                            shadows: const [
                              Shadow(
                                color: KlotskiColors.blockTextShadow,
                                blurRadius: 2,
                                offset: Offset(1, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Hint direction arrow overlay
                    if (widget.isHinted && widget.hintDirection != null)
                      Positioned.fill(
                        child: _HintArrow(
                          direction: widget.hintDirection!,
                          pulse: _hintPulse.value,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Border? _buildBorder() {
    if (widget.isHinted) {
      final alpha = 0.5 + 0.5 * _hintPulse.value;
      return Border.all(
        color: const Color(0xFFF0C040).withValues(alpha: alpha),
        width: 2.5,
      );
    }
    if (widget.isSelected) {
      return Border.all(
        color: const Color(0xFF4ECCA3),
        width: 2,
      );
    }
    return null;
  }

  List<BoxShadow> _buildShadow() {
    if (widget.isHinted) {
      final alpha = 0.2 + 0.3 * _hintPulse.value;
      return [
        BoxShadow(
          color: const Color(0xFFF0C040).withValues(alpha: alpha),
          blurRadius: 12,
          spreadRadius: 2,
        ),
      ];
    }
    if (_isDragging) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 8,
          offset: const Offset(2, 4),
        ),
      ];
    }
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.2),
        blurRadius: 2,
        offset: const Offset(1, 2),
      ),
    ];
  }
}

/// Direction arrow overlay for hint system
class _HintArrow extends StatelessWidget {
  final Direction direction;
  final double pulse;

  const _HintArrow({required this.direction, required this.pulse});

  @override
  Widget build(BuildContext context) {
    final angle = switch (direction) {
      Direction.up => -math.pi / 2,
      Direction.down => math.pi / 2,
      Direction.left => math.pi,
      Direction.right => 0.0,
    };

    // Arrow slides in the hint direction
    final offset = Offset(
      direction.dx * pulse * 6,
      direction.dy * pulse * 6,
    );

    return Transform.translate(
      offset: offset,
      child: Center(
        child: Transform.rotate(
          angle: angle,
          child: Icon(
            Icons.arrow_forward_rounded,
            color: Colors.white.withValues(alpha: 0.6 + 0.4 * pulse),
            size: 24,
          ),
        ),
      ),
    );
  }
}
