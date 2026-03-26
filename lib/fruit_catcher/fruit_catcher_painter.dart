import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'fruit_catcher_colors.dart';
import 'fruit_catcher_config.dart';
import 'fruit_catcher_game.dart';
import 'fruit_catcher_models.dart';

class FruitCatcherPainter extends CustomPainter {
  final FruitCatcherGame game;
  final int paintVersion;

  FruitCatcherPainter({required this.game, required this.paintVersion});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.height;

    // Screen shake: save canvas state, translate for game elements only
    final hasShake = game.shakeTimer > 0;
    if (hasShake) {
      canvas.save();
      final rng = Random(game.elapsed.hashCode);
      final intensity = game.shakeTimer * 8.0;
      canvas.translate(
        (rng.nextDouble() - 0.5) * intensity,
        (rng.nextDouble() - 0.5) * intensity,
      );
    }

    // 1. Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = FruitCatcherColors.background,
    );

    // 2. Falling items
    for (final item in game.items) {
      if (item.isBomb) {
        _drawBomb(canvas, item, s);
      } else {
        _drawFruit(canvas, item, s);
      }
    }

    // 3. Basket
    _drawBasket(canvas, s);

    // 4. Floating texts
    for (final ft in game.floatingTexts) {
      _drawFloatingText(canvas, ft, s);
    }

    // Restore canvas before HUD and overlays (not affected by shake)
    if (hasShake) {
      canvas.restore();
    }

    // 5. HUD
    _drawHUD(canvas, size);

    // 6. Red flash overlay
    if (game.redFlashTimer > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()
          ..color = Colors.red.withValues(alpha: game.redFlashTimer * 0.3),
      );
    }

    // 7. Wave pause overlay (endless mode)
    if (game.wavePauseTimer > 0) {
      _drawWavePauseOverlay(canvas, size);
    }
  }

  void _drawFruit(Canvas canvas, FruitItem item, double s) {
    final color = FruitCatcherColors.forFruit(item.fruitType!);
    final cx = item.x * s;
    final cy = item.y * s;
    final r = item.radius * s;

    // Main circle
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = color);

    // Highlight shine (top-left)
    canvas.drawCircle(
      Offset(cx - r * 0.25, cy - r * 0.25),
      r * 0.35,
      Paint()..color = Colors.white.withValues(alpha: 0.3),
    );
  }

  void _drawBomb(Canvas canvas, FruitItem item, double s) {
    final cx = item.x * s;
    final cy = item.y * s;
    final r = item.radius * s;

    // Pulsing alpha via sin
    final alpha = 0.8 + 0.2 * sin(game.elapsed * 8.0);

    // Red glow
    canvas.drawCircle(
      Offset(cx, cy),
      r * 1.4,
      Paint()
        ..color = FruitCatcherColors.bombGlow.withValues(alpha: 0.15 * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Main bomb body
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()..color = FruitCatcherColors.bomb.withValues(alpha: alpha),
    );

    // Fuse spark (small bright circle on top)
    final sparkAlpha = (0.5 + 0.5 * sin(game.elapsed * 12.0)).clamp(0.0, 1.0);
    canvas.drawCircle(
      Offset(cx, cy - r * 0.8),
      r * 0.2,
      Paint()
        ..color = FruitCatcherColors.bombGlow.withValues(alpha: sparkAlpha),
    );
  }

  void _drawBasket(Canvas canvas, double s) {
    final bx = game.basket.x * s;
    final by = game.basket.y * s;
    final hw = game.basket.width * s / 2;
    final squash = game.basketSquash > 0 ? 0.8 : 1.0;
    final hh = game.basket.height * s * squash / 2;

    // Trapezoid path (wider at top)
    final path = Path()
      ..moveTo(bx - hw, by - hh)
      ..lineTo(bx + hw, by - hh)
      ..lineTo(bx + hw * 0.7, by + hh)
      ..lineTo(bx - hw * 0.7, by + hh)
      ..close();

    canvas.drawPath(path, Paint()..color = FruitCatcherColors.basketBase);

    // Highlight edge
    canvas.drawPath(
      path,
      Paint()
        ..color = FruitCatcherColors.basketHighlight
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _drawFloatingText(Canvas canvas, FloatingText ft, double s) {
    final tp = TextPainter(
      text: TextSpan(
        text: ft.text,
        style: TextStyle(
          color: ft.color.withValues(alpha: ft.alpha),
          fontSize: s * 0.025,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(ft.x * s - tp.width / 2, ft.y * s - tp.height / 2),
    );
    tp.dispose();
  }

  void _drawHUD(Canvas canvas, Size size) {
    final s = size.height;
    final fontSize = s * 0.022;

    // Combo display (above basket, center)
    if (game.combo >= 3) {
      final tp = TextPainter(
        text: TextSpan(
          text: 'Combo x${game.combo}',
          style: TextStyle(
            color: FruitCatcherColors.comboText,
            fontSize: fontSize * 1.2,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(
          (size.width - tp.width) / 2,
          game.basket.y * s - game.basket.height * s - tp.height - s * 0.03,
        ),
      );
      tp.dispose();
    }

    // Mode-specific HUD at bottom
    switch (game.mode) {
      case FruitCatcherMode.classic:
        _drawLives(canvas, size, fontSize);
      case FruitCatcherMode.timed:
        _drawTimer(canvas, size, fontSize);
      case FruitCatcherMode.endless:
        _drawWaveInfo(canvas, size, fontSize);
    }
  }

  void _drawLives(Canvas canvas, Size size, double fontSize) {
    // Hearts in bottom-left
    const heartSize = 8.0;
    for (int i = 0; i < game.lives; i++) {
      final x = heartSize + 4 + i * (heartSize * 2 + 6);
      final y = size.height - heartSize - 6;
      canvas.drawCircle(
        Offset(x, y),
        heartSize,
        Paint()..color = const Color(0xFFE84545),
      );
    }
  }

  void _drawTimer(Canvas canvas, Size size, double fontSize) {
    // Countdown centered at bottom
    final seconds = game.timeRemaining.ceil();
    final color =
        seconds <= 10 ? const Color(0xFFE84545) : FruitCatcherColors.hudText;
    final tp = TextPainter(
      text: TextSpan(
        text: '${seconds}s',
        style: TextStyle(
          color: color,
          fontSize: fontSize * 1.3,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset((size.width - tp.width) / 2, size.height - tp.height - 6),
    );
    tp.dispose();
  }

  void _drawWaveInfo(Canvas canvas, Size size, double fontSize) {
    // Wave number in bottom-right
    final tp = TextPainter(
      text: TextSpan(
        text: 'Wave ${game.wave}',
        style: TextStyle(
          color: FruitCatcherColors.hudText,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(size.width - tp.width - 8, size.height - tp.height - 6),
    );
    tp.dispose();
  }

  void _drawWavePauseOverlay(Canvas canvas, Size size) {
    // Semi-transparent background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.black.withValues(alpha: 0.5),
    );

    final tp = TextPainter(
      text: TextSpan(
        text: 'Wave ${game.wave}',
        style: TextStyle(
          color: Colors.white,
          fontSize: size.height * 0.04,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2),
    );
    tp.dispose();
  }

  @override
  bool shouldRepaint(covariant FruitCatcherPainter old) =>
      paintVersion != old.paintVersion;
}
