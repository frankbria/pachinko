import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import '../models/ball_launcher.dart';
import '../models/confetti_particle.dart';
import '../models/slot.dart';
import '../utils/constants.dart';
import '../utils/game_theme.dart';
import 'board_static_layer.dart';

/// Draws the bonus announcement over the board: a dark scrim so that the
/// board stays visible but recedes, a gold glow, and the number of balls won.
///
/// [opacity] runs from 1.0, fully shown, to 0.0 as the overlay fades.
void paintBonusOverlay(Canvas canvas,
    {required double opacity, required int bonusBalls}) {
  canvas.drawRect(
    const Rect.fromLTWH(
        0, 0, GameConstants.boardWidth, GameConstants.boardHeight),
    Paint()
      ..color = GameConstants.cabinetColor.withValues(alpha: 0.55 * opacity),
  );

  const centre =
      Offset(GameConstants.boardWidth / 2, GameConstants.boardHeight / 2);
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
  caption.paint(
      canvas,
      centre -
          Offset(caption.width / 2, amount.height / 2 + caption.height + 4));
  caption.dispose();
  amount.dispose();
}

/// Draws one piece of confetti in its own colour, fading with its opacity.
///
/// The shape goes by the piece's size, so a burst is a mix: small pieces are
/// discs, middling ones diamonds, and large ones streamers.
void paintConfettiPiece(Canvas canvas, ConfettiParticle particle) {
  final paint = Paint()
    ..color = particle.color.withValues(alpha: particle.opacity);
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
        Rect.fromCenter(
            center: Offset.zero, width: size * 1.3, height: size * 0.3),
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
void paintPrizeLamps(Canvas canvas,
    {required int total, required int collected}) {
  const centreX =
      (GameConstants.topCurveStartX + GameConstants.topCurveEndX) / 2;
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
        Rect.fromLTRB(slots.first.left, trayTop, slots.last.right,
            trayTop + slotTrayHeight),
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
    final top = inTray
        ? trayTop + (slotTrayHeight - count.height) / 2
        : slot.bottom - count.height - 3;
    count.paint(canvas, Offset(slot.position.x - count.width / 2, top));
  }
}

/// Draws each lit slot over its unlit picture: the pocket filled with its
/// tier colour, as strongly as the slot is lit, and its value in ink on top.
void paintSlotLights(Canvas canvas, List<Slot> slots) {
  for (final slot in slots) {
    if (slot.glow <= 0.0) continue;

    canvas.drawRRect(
      RRect.fromRectAndRadius(slot.bounds, const Radius.circular(4)),
      Paint()..color = slot.color.withValues(alpha: 0.75 * slot.glow),
    );
    paintSlotValue(canvas, slot.bounds, slot.pointValue,
        GameConstants.inkColor.withValues(alpha: slot.glow));
  }
}

/// Draws a score popup at [centreTop], in its own colour and size, kept
/// inside the board's width however near the edge its slot is.
void paintScorePopup(
  Canvas canvas, {
  required String text,
  required Offset centreTop,
  required Color colour,
  required double fontSize,
  required double opacity,
}) {
  final popup = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: colour.withValues(alpha: opacity),
        fontFamily: displayFontFamily,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            color: GameConstants.cabinetColor.withValues(alpha: opacity * 0.6),
            blurRadius: 4,
            offset: const Offset(1, 1),
          ),
        ],
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  const margin = 2.0;
  final left = (centreTop.dx - popup.width / 2)
      .clamp(margin, GameConstants.boardWidth - margin - popup.width);
  popup.paint(canvas, Offset(left, centreTop.dy));
}

/// The colour of launch power at [ratio] (0.0 to 1.0): cyan, rising through
/// violet to magenta at full power. Each half is a blend of two saturated
/// colours, so there is no muddy middle.
Color launchPowerColour(double ratio) {
  final power = ratio.clamp(0.0, 1.0);
  return power <= 0.5
      ? Color.lerp(
          GameConstants.cyanColor, GameConstants.violetColor, power * 2)!
      : Color.lerp(GameConstants.violetColor, GameConstants.magentaColor,
          power * 2 - 1)!;
}

/// What the launcher asks of the player in [phase].
String launchHintFor(LaunchPhase phase) => phase == LaunchPhase.charging
    ? GameStrings.launchHintCharging
    : GameStrings.launchHintReady;

/// Draws launch power as light in the launch channel, rising from the
/// plunger, with the percentage beside the channel's foot.
///
/// The channel is the meter, so nothing is drawn over the pegs. At full
/// power the light stops at the top of the channel's inner wall. The ramp is
/// two two-colour gradients, one above the other: a single three-colour
/// gradient aborts the CI emulator (see the board materials slice, #26).
void paintLaunchPower(Canvas canvas, double ratio) {
  final power = ratio.clamp(0.0, 1.0);
  const left = GameConstants.launchChannelStartX + 2;
  const right =
      GameConstants.launchChannelStartX + GameConstants.launchChannelWidth - 2;
  const bottom = GameConstants.launchChannelStartY - GameConstants.ballRadius;
  const top = GameConstants.launchChannelInnerWallTopY;
  const middle = (bottom + top) / 2;
  final lit = bottom - (bottom - top) * power;

  Paint ramp(double from, double to, Color lower, Color upper) => Paint()
    ..shader = ui.Gradient.linear(
      Offset(0, from),
      Offset(0, to),
      [lower.withValues(alpha: 0.6), upper.withValues(alpha: 0.6)],
    );

  if (power > 0) {
    canvas.drawRect(
      Rect.fromLTRB(left, lit > middle ? lit : middle, right, bottom),
      ramp(bottom, middle, GameConstants.cyanColor, GameConstants.violetColor),
    );
  }
  if (lit < middle) {
    canvas.drawRect(
      Rect.fromLTRB(left, lit, right, middle),
      ramp(middle, top, GameConstants.violetColor, GameConstants.magentaColor),
    );
  }

  // Below the lowest peg and left of the launch box: beside the channel's foot
  final label = TextPainter(
    text: TextSpan(
      text: '${(power * 100).round()}%',
      style: TextStyle(
        color: launchPowerColour(power),
        fontFamily: displayFontFamily,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  label.paint(
    canvas,
    Offset(
      GameConstants.launchChannelStartX - 20 - label.width,
      GameConstants.launchChannelStartY - label.height / 2,
    ),
  );
}

/// Draws the plunger the resting ball sits on: a cap under the ball and a
/// shaft below it, in chrome.
void paintPlunger(Canvas canvas) {
  const centreX = GameConstants.ballLaunchX;
  const capTop = GameConstants.launchChannelStartY + GameConstants.ballRadius;
  final chrome = Paint()..color = GameConstants.chromeColor;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(centreX - 10, capTop, 20, 4),
      const Radius.circular(2),
    ),
    chrome,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(centreX - 3, capTop + 4, 6, 7),
      const Radius.circular(1),
    ),
    Paint()..color = GameConstants.slateColor,
  );
}
