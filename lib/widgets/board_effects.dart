import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import '../models/confetti_particle.dart';
import '../models/slot.dart';
import '../utils/constants.dart';
import '../utils/game_theme.dart';
import 'board_static_layer.dart';

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

/// The height, in board coordinates, of the row of prize lamps in the dome.
const double prizeLampRowY = 88.0;
const double _prizeLampRadius = 5.0;
const double _prizeLampSpacing = 20.0;

/// Draws one lamp per prize peg in the dome, centred under the level sign.
/// The first [collected] of the [total] are lit, so the row shows at a glance
/// how many prizes are left to win.
void paintPrizeLamps(Canvas canvas, {required int total, required int collected}) {
  const centreX = (GameConstants.topCurveStartX + GameConstants.topCurveEndX) / 2;
  final firstX = centreX - _prizeLampSpacing * (total - 1) / 2;

  for (int i = 0; i < total; i++) {
    final centre = Offset(firstX + _prizeLampSpacing * i, prizeLampRowY);
    if (i < collected) {
      paintSphere(
        canvas,
        centre,
        _prizeLampRadius,
        GameConstants.specialPegColor,
        castsShadow: false,
        glowColour: GameConstants.specialPegColor,
      );
    } else {
      canvas.drawCircle(
        centre,
        _prizeLampRadius,
        Paint()..color = GameConstants.cabinetColor.withValues(alpha: 0.8),
      );
      canvas.drawCircle(
        centre,
        _prizeLampRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = GameConstants.specialPegColor.withValues(alpha: 0.45),
      );
    }
  }
}

/// The height of the tray under the slots, in board coordinates.
const double slotTrayHeight = 26.0;
const double _slotTrayGap = 4.0;

/// Draws how many balls each slot has caught.
///
/// With [inTray] the counts go in a glass tray under the slots, below the
/// board's own height: a phone's screen is taller than the board, and that
/// strip is otherwise empty. Without it (a window as wide as it is tall)
/// they are drawn inside the slots, under the values.
void paintSlotCounts(Canvas canvas, List<Slot> slots, {required bool inTray}) {
  if (slots.isEmpty) return;

  const trayTop = GameConstants.boardHeight + _slotTrayGap;
  if (inTray) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(slots.first.left, trayTop, slots.last.right, trayTop + slotTrayHeight),
        const Radius.circular(6),
      ),
      Paint()..color = GameConstants.cabinetColor.withValues(alpha: 0.7),
    );
  }

  for (final slot in slots) {
    if (slot.ballCount == 0) continue;

    final count = TextPainter(
      text: TextSpan(
        text: '×${slot.ballCount}',
        style: TextStyle(
          color: inTray ? slot.color : GameConstants.inkColor,
          fontFamily: displayFontFamily,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final top = inTray ? trayTop + (slotTrayHeight - count.height) / 2 : slot.bottom - count.height - 3;
    count.paint(canvas, Offset(slot.position.x - count.width / 2, top));
  }
}
