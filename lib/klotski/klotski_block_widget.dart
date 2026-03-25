// lib/klotski/klotski_block_widget.dart

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

  const KlotskiBlockWidget({
    required this.block,
    required this.cellSize,
    required this.maxDistance,
    required this.onMoved,
    this.enabled = true,
    super.key,
  });

  @override
  State<KlotskiBlockWidget> createState() => _KlotskiBlockWidgetState();
}

class _KlotskiBlockWidgetState extends State<KlotskiBlockWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _snapAnimation;

  Offset _dragOffset = Offset.zero;
  Axis? _lockedAxis;
  bool _isDragging = false;
  Map<Direction, int> _maxDistances = {};

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _snapAnimation = const AlwaysStoppedAnimation(Offset.zero);
  }

  @override
  void dispose() {
    _controller.dispose();
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
    _controller.stop();
    _isDragging = true;
    _dragOffset = Offset.zero;
    _lockedAxis = null;
    // 缓存四方向最大距离
    _maxDistances = {
      for (final dir in Direction.values) dir: widget.maxDistance(dir),
    };
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    final delta = details.delta;
    var newOffset = _dragOffset + delta;

    // 轴锁定：>8px 后锁定
    if (_lockedAxis == null) {
      if (newOffset.dx.abs() > 8 || newOffset.dy.abs() > 8) {
        _lockedAxis = newOffset.dx.abs() >= newOffset.dy.abs()
            ? Axis.horizontal
            : Axis.vertical;
      }
    }

    // 约束到锁定轴
    if (_lockedAxis == Axis.horizontal) {
      newOffset = Offset(newOffset.dx, 0);
    } else if (_lockedAxis == Axis.vertical) {
      newOffset = Offset(0, newOffset.dy);
    }

    // 夹紧到 maxDistance 范围
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
      // 吸附动画到目标格
      final targetOffset = Offset(
        dir.dx * distance * cs,
        dir.dy * distance * cs,
      );
      _animateSnap(_dragOffset, targetOffset, Curves.easeOutCubic, () {
        widget.onMoved(dir!, distance);
      });
    } else {
      // 弹回原位
      _animateSnap(_dragOffset, Offset.zero, Curves.easeOut, null);
    }
  }

  void _animateSnap(Offset from, Offset to, Curve curve, VoidCallback? onDone) {
    _snapAnimation = Tween<Offset>(begin: from, end: to).animate(
      CurvedAnimation(parent: _controller, curve: curve),
    );
    _controller.reset();
    _controller.duration = Duration(milliseconds: to == Offset.zero ? 100 : 150);

    void listener(AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        _controller.removeStatusListener(listener);
        if (onDone != null) {
          onDone();
        }
        setState(() {
          _snapAnimation = const AlwaysStoppedAnimation(Offset.zero);
        });
      }
    }
    _controller.addStatusListener(listener);
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.cellSize;
    final block = widget.block;
    final blockWidth = block.width * cs;
    final blockHeight = block.height * cs;
    final inset = 2.0;

    return AnimatedBuilder(
      animation: _controller,
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
                padding: EdgeInsets.all(inset),
                child: Container(
                  decoration: BoxDecoration(
                    color: KlotskiColors.bgForType(block.type),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: _isDragging
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(2, 4),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 2,
                              offset: const Offset(1, 2),
                            ),
                          ],
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
              ),
            ),
          ),
        );
      },
    );
  }
}
