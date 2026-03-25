// lib/flappybird/flappybird_painter.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'flappybird_colors.dart';
import 'flappybird_config.dart';
import 'flappybird_game.dart';
import 'flappybird_models.dart';

class FlappybirdPainter extends CustomPainter {
  final FlappybirdGame game;
  final int paintVersion;

  FlappybirdPainter({required this.game, required this.paintVersion});

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;

    // 1. Sky gradient background
    final skyRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(
      skyRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [FlappybirdColors.skyTop, FlappybirdColors.skyBottom],
        ).createShader(skyRect),
    );

    // 2. Clouds (parallax layer)
    for (final cloud in game.clouds) {
      final cx = cloud.x * h;
      final cy = cloud.y * h;
      final rx = cloud.radius * h;
      final ry = rx * 0.6;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2),
        Paint()..color = FlappybirdColors.cloud,
      );
    }

    // 3. Pipes
    final halfGap = game.config.gapSize / 2;
    const capHeight = 0.02;
    const capExtra = 0.005;

    for (final pipe in game.pipes) {
      final px = pipe.x * h;
      final pw = pipe.width * h;
      final capH = capHeight * h;
      final capW = pw + capExtra * 2 * h;
      final capX = px - capExtra * h;

      // Upper pipe
      final upperBottom = (pipe.gapCenterY - halfGap) * h;
      if (upperBottom > 0) {
        // Pipe body
        canvas.drawRect(
          Rect.fromLTWH(px, 0, pw, upperBottom - capH),
          Paint()
            ..shader = LinearGradient(
              colors: [FlappybirdColors.pipeBodyDark, FlappybirdColors.pipeBody],
            ).createShader(Rect.fromLTWH(px, 0, pw, upperBottom)),
        );
        // Pipe cap
        final capRect = Rect.fromLTWH(capX, upperBottom - capH, capW, capH);
        canvas.drawRRect(
          RRect.fromRectAndRadius(capRect, Radius.circular(0.005 * h)),
          Paint()
            ..shader = LinearGradient(
              colors: [FlappybirdColors.pipeCapDark, FlappybirdColors.pipeCap],
            ).createShader(capRect),
        );
      }

      // Lower pipe
      final lowerTop = (pipe.gapCenterY + halfGap) * h;
      final groundTop = (1.0 - game.ground.height) * h;
      if (lowerTop < groundTop) {
        // Pipe cap
        final capRect = Rect.fromLTWH(capX, lowerTop, capW, capH);
        canvas.drawRRect(
          RRect.fromRectAndRadius(capRect, Radius.circular(0.005 * h)),
          Paint()
            ..shader = LinearGradient(
              colors: [FlappybirdColors.pipeCapDark, FlappybirdColors.pipeCap],
            ).createShader(capRect),
        );
        // Pipe body
        canvas.drawRect(
          Rect.fromLTWH(px, lowerTop + capH, pw, groundTop - lowerTop - capH),
          Paint()
            ..shader = LinearGradient(
              colors: [FlappybirdColors.pipeBodyDark, FlappybirdColors.pipeBody],
            ).createShader(Rect.fromLTWH(px, lowerTop, pw, groundTop - lowerTop)),
        );
      }
    }

    // 4. Ground (scrolling stripes)
    final groundTop = (1.0 - game.ground.height) * h;
    final groundH = game.ground.height * h;
    // Grass strip
    canvas.drawRect(
      Rect.fromLTWH(0, groundTop, size.width, groundH * 0.3),
      Paint()..color = FlappybirdColors.groundTop,
    );
    // Earth
    canvas.drawRect(
      Rect.fromLTWH(0, groundTop + groundH * 0.3, size.width, groundH * 0.7),
      Paint()..color = FlappybirdColors.groundBottom,
    );
    // Scrolling tick marks on grass
    final tickSpacing = 0.03 * h;
    final offset = ((game.ground.offsetX * h) % tickSpacing + tickSpacing) % tickSpacing;
    final tickPaint = Paint()
      ..color = FlappybirdColors.groundBottom.withValues(alpha: 0.3)
      ..strokeWidth = 2;
    for (double tx = offset; tx < size.width; tx += tickSpacing) {
      canvas.drawLine(
        Offset(tx, groundTop),
        Offset(tx, groundTop + groundH * 0.3),
        tickPaint,
      );
    }

    // 5. Bird
    _drawBird(canvas, h);

    // 6. Overlay (ready state)
    if (game.state == GameState.ready) {
      final fontSize = 0.04 * h;
      final tp = TextPainter(
        text: TextSpan(
          text: 'Tap to Start',
          style: TextStyle(
            color: FlappybirdColors.overlayText,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(color: FlappybirdColors.overlayTextShadow, blurRadius: 4),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset((size.width - tp.width) / 2, h * 0.6));
      tp.dispose();
    }
  }

  void _drawBird(Canvas canvas, double h) {
    final bx = game.bird.x * h;
    final by = game.bird.y * h;
    final r = game.bird.radius * h;

    canvas.save();
    canvas.translate(bx, by);
    canvas.rotate(game.bird.rotation);

    // Body (circle)
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()..color = FlappybirdColors.birdBody,
    );

    // Wing (triangle, oscillating)
    final wingOffset = sin(game.bird.wingPhase) * 0.01 * h;
    final wingPath = Path()
      ..moveTo(-r * 0.3, wingOffset)
      ..lineTo(-r * 1.2, wingOffset + r * 0.5)
      ..lineTo(-r * 0.3, wingOffset + r * 0.3)
      ..close();
    canvas.drawPath(wingPath, Paint()..color = FlappybirdColors.birdWing);

    // Eye
    canvas.drawCircle(
      Offset(r * 0.3, -r * 0.2),
      r * 0.25,
      Paint()..color = FlappybirdColors.birdEye,
    );
    canvas.drawCircle(
      Offset(r * 0.4, -r * 0.2),
      r * 0.12,
      Paint()..color = FlappybirdColors.birdPupil,
    );

    // Beak (small triangle)
    final beakPath = Path()
      ..moveTo(r * 0.7, 0)
      ..lineTo(r * 1.2, r * 0.1)
      ..lineTo(r * 0.7, r * 0.25)
      ..close();
    canvas.drawPath(beakPath, Paint()..color = const Color(0xFFE84545));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant FlappybirdPainter old) =>
      paintVersion != old.paintVersion;
}
