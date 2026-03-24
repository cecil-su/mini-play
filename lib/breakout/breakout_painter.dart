// lib/breakout/breakout_painter.dart
import 'package:flutter/material.dart';
import 'breakout_colors.dart';
import 'breakout_config.dart';
import 'breakout_game.dart';

class BreakoutPainter extends CustomPainter {
  final BreakoutGame game;
  final int paintVersion;

  BreakoutPainter({required this.game, required this.paintVersion});

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final s = h;

    // 1. Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = BreakoutColors.background,
    );

    // 2. Bricks (including fading-out destroyed bricks)
    for (final brick in game.bricks) {
      final bx = game.brickX(brick.col) * s;
      final by = game.brickY(brick.row) * s;
      final bw = game.brickWidth * s;
      final bh = game.brickHeight * s;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(bx, by, bw, bh),
        const Radius.circular(3),
      );

      double opacity = 1.0;
      if (brick.hp <= 0 && brick.fadeFrames > 0) {
        opacity = brick.fadeFrames / 3.0;
      }

      Color color;
      if (brick.flashFrames > 0) {
        color = Colors.white.withValues(alpha: opacity);
      } else {
        color = BreakoutColors.forBrick(brick.hp > 0 ? brick.hp : 1, brick.maxHp).withValues(alpha: opacity);
      }
      canvas.drawRRect(rect, Paint()..color = color);

      if (opacity > 0.5) {
        canvas.drawRRect(
          rect,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.15 * opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5,
        );
      }
    }

    // 3. Power-ups
    for (final pu in game.activePowerUps) {
      final px = pu.x * s - BreakoutGame.powerUpSize * s / 2;
      final py = pu.y * s - BreakoutGame.powerUpSize * s / 2;
      final ps = BreakoutGame.powerUpSize * s;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(px, py, ps, ps),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, Paint()..color = BreakoutColors.forPowerUp(pu.type));

      final tp = TextPainter(
        text: TextSpan(
          text: BreakoutColors.powerUpIcon(pu.type),
          style: TextStyle(color: Colors.white, fontSize: ps * 0.6, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(px + (ps - tp.width) / 2, py + (ps - tp.height) / 2));
    }

    // 4. Balls
    for (final ball in game.balls) {
      if (ball.y > BreakoutConfig.worldHeight) continue;
      final color = ball.isPenetrating ? BreakoutColors.ballPenetrating : BreakoutColors.ball;
      canvas.drawCircle(
        Offset(ball.x * s, ball.y * s),
        ball.radius * s,
        Paint()..color = color,
      );
      if (ball.isPenetrating) {
        canvas.drawCircle(
          Offset(ball.x * s, ball.y * s),
          ball.radius * s * 1.5,
          Paint()
            ..color = BreakoutColors.ballPenetrating.withValues(alpha: 0.2)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }
    }

    // 5. Paddle
    final Color paddleColor;
    if (game.paddleFlashFrames > 0) {
      paddleColor = Colors.white;
    } else if (game.widenTimer > 0) {
      paddleColor = BreakoutColors.paddleWiden;
    } else if (game.shrinkTimer > 0) {
      paddleColor = BreakoutColors.paddleShrink;
    } else {
      paddleColor = BreakoutColors.paddle;
    }
    final squash = game.paddleSquashFrames > 0 ? 0.7 : 1.0;
    final pw = game.paddle.width * s;
    final ph = game.paddle.height * s * squash;
    final ppx = game.paddle.x * s - pw / 2;
    final ppy = game.paddle.y * s - ph / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(ppx, ppy, pw, ph), const Radius.circular(4)),
      Paint()..color = paddleColor,
    );

    // 6. HUD - Lives
    const lifeRadius = 6.0;
    for (int i = 0; i < game.lives; i++) {
      canvas.drawCircle(
        Offset(lifeRadius + 2 + i * (lifeRadius * 2 + 4), size.height - lifeRadius - 4),
        lifeRadius,
        Paint()..color = BreakoutColors.lifeIcon,
      );
    }

    // HUD - Round (endless)
    if (game.mode == BreakoutMode.endless) {
      final tp = TextPainter(
        text: TextSpan(
          text: 'R${game.round}',
          style: const TextStyle(color: BreakoutColors.hudText, fontSize: 14),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(size.width - tp.width - 8, size.height - tp.height - 4));
    }

    // HUD - Active power-up timers
    double timerX = lifeRadius + 2 + game.lives * (lifeRadius * 2 + 4) + 8;
    if (game.widenTimer > 0) {
      _drawTimerBadge(canvas, timerX, size.height - 16, '\u2194 ${game.widenTimer.ceil()}s', BreakoutColors.paddleWiden);
      timerX += 50;
    }
    if (game.shrinkTimer > 0) {
      _drawTimerBadge(canvas, timerX, size.height - 16, '\u2195 ${game.shrinkTimer.ceil()}s', BreakoutColors.paddleShrink);
      timerX += 50;
    }
    if (game.penetrateTimer > 0) {
      _drawTimerBadge(canvas, timerX, size.height - 16, '\u2193 ${game.penetrateTimer.ceil()}s', BreakoutColors.ballPenetrating);
    }

    // Life loss flash overlay
    if (game.lifeLossPauseTimer > 0.7) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.white.withValues(alpha: 0.3),
      );
    }

    // Round overlay
    if (game.roundOverlayText != null) {
      final tp = TextPainter(
        text: TextSpan(
          text: game.roundOverlayText,
          style: const TextStyle(
            color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(
        (size.width - tp.width) / 2,
        (size.height - tp.height) / 2,
      ));
    }

    // "Tap to launch" hint
    if (game.waitingToLaunch && game.roundOverlayTimer <= 0) {
      final tp = TextPainter(
        text: const TextSpan(
          text: 'Tap to launch',
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(
        (size.width - tp.width) / 2,
        size.height * 0.7,
      ));
    }
  }

  void _drawTimerBadge(Canvas canvas, double x, double y, String text, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(covariant BreakoutPainter old) =>
      paintVersion != old.paintVersion;
}
