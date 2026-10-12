import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import '../models/confetti_particle.dart';
import '../utils/constants.dart';
import '../utils/game_theme.dart';

/// Draws the bonus announcement over the board: a dark scrim so that the
/// board stays visible but recedes, a gold glow, and the number of balls won.
///
/// [opacity] runs from 1.0, fully shown, to 0.0 as the overlay fades.
void paintBonusOverlay(Canvas canvas, {required double opacity, required int bonusBalls}) {
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, GameConstants.boardWidth, GameConstants.boardHeight),
    Paint()..color = GameConstants.cabinetColor.withValues(alpha: 0.55 * opacity),
  );

  const centre = Offset(GameConstants.boardWidth / 2, GameConstants.boardHeight / 2);
  const glowRadius = 170.0;
  canvas.drawCircle(
    centre,
    glowRadius,
    Paint()
      ..shader = ui.Gradient.radial(
        centre,
        glowRadius,
        [
          GameConstants.bonusBallColor.withValues(alpha: 0.4 * opacity),
          GameConstants.bonusBallColor.withValues(alpha: 0.0),
        ],
      ),
  );

  final caption = TextPainter(
    text: TextSpan(
      text: 'BONUS',
      style: TextStyle(
        color: GameConstants.inkColor.withValues(alpha: opacity),
        fontFamily: displayFontFamily,
        fontSize: 14,
        letterSpacing: 6,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final amount = TextPainter(
    text: TextSpan(
      text: '+$bonusBalls BALLS!',
      style: TextStyle(
        color: GameConstants.bonusBallColor.withValues(alpha: opacity),
        fontFamily: displayFontFamily,
        fontSize: 36,
        fontWeight: FontWeight.bold,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  amount.paint(canvas, centre - Offset(amount.width / 2, amount.height / 2));
  caption.paint(canvas, centre - Offset(caption.width / 2, amount.height / 2 + caption.height + 4));
  caption.dispose();
  amount.dispose();
}

/// Draws one piece of confetti in its own colour, fading with its opacity.
///
/// The shape goes by the piece's size, so a burst is a mix: small pieces are
/// discs, middling ones diamonds, and large ones streamers.
void paintConfettiPiece(Canvas canvas, ConfettiParticle particle) {
  final paint = Paint()..color = particle.color.withValues(alpha: particle.opacity);
  final size = particle.size;

  canvas.save();
  canvas.translate(particle.position.x, particle.position.y);
  canvas.rotate(particle.rotation);
  if (size < 8) {
    canvas.drawCircle(Offset.zero, size * 0.45, paint);
  } else if (size < 10) {
    canvas.drawPath(
      Path()
        ..moveTo(0, -size * 0.6)
        ..lineTo(size * 0.4, 0)
        ..lineTo(0, size * 0.6)
        ..lineTo(-size * 0.4, 0)
        ..close(),
      paint,
    );
  } else {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: size * 1.3, height: size * 0.3),
        Radius.circular(size * 0.15),
      ),
      paint,
    );
  }
  canvas.restore();
}
