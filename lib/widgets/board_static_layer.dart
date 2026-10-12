import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import '../models/level.dart';
import '../models/peg.dart';
import '../utils/constants.dart';
import '../utils/game_theme.dart';

/// Draws a sphere of [colour] lit from the upper left, with a soft shadow down
/// and to the right.
///
/// Every sphere on the board is drawn with this, so they share one light.
/// The shadow is a gradient and not a blur, so it costs little to rasterize.
/// With [glowColour] the sphere draws a soft glow, twice its width, over its
/// shadow and under its body: a lit object that still sits on the board, as
/// the ball does. A sphere that is itself a light, such as a prize peg still
/// to win, also passes [castsShadow] as false: a shadow showing through its
/// halo reads as a dark ring.
///
/// The body is two passes, each a two-colour gradient: from the highlight to
/// [colour], then a shade that darkens towards the far edge. One gradient
/// with three colours draws the same thing, but it makes the software
/// rendered emulator that the integration tests run on abort, and so does a
/// gradient whose last stop is below 1.0 (found on PR #65).
void paintSphere(
  Canvas canvas,
  Offset centre,
  double radius,
  Color colour, {
  bool castsShadow = true,
  Color? glowColour,
}) {
  if (castsShadow) {
    final shadowCentre = centre + Offset(radius * 0.3, radius * 0.4);
    final shadowRadius = radius * 1.3;
    canvas.drawCircle(
      shadowCentre,
      shadowRadius,
      Paint()
        ..shader = ui.Gradient.radial(
          shadowCentre,
          shadowRadius,
          [
            GameConstants.cabinetColor.withValues(alpha: 0.6),
            GameConstants.cabinetColor.withValues(alpha: 0.0),
          ],
          [0.55, 1.0],
        ),
    );
  }

  if (glowColour != null) {
    final glowRadius = radius * 2;
    canvas.drawCircle(
      centre,
      glowRadius,
      Paint()
        ..shader = ui.Gradient.radial(
          centre,
          glowRadius,
          [glowColour.withValues(alpha: 0.45), glowColour.withValues(alpha: 0.0)],
        ),
    );
  }

  final light = centre - Offset(radius * 0.35, radius * 0.35);
  final reach = radius * 1.35;
  canvas.drawCircle(
    centre,
    radius,
    Paint()
      ..shader = ui.Gradient.radial(
        light,
        reach * 0.45,
        [Color.lerp(colour, GameConstants.inkColor, 0.8)!, colour],
      ),
  );
  canvas.drawCircle(
    centre,
    radius,
    Paint()
      ..shader = ui.Gradient.radial(
        light,
        reach,
        [
          GameConstants.cabinetColor.withValues(alpha: 0.0),
          GameConstants.cabinetColor.withValues(alpha: 0.6),
        ],
        [0.45, 1.0],
      ),
  );
}

/// Draws the parts of the board that do not change while a level is played:
/// the felt, the chrome rail, the brass pins and the unlit slots.
///
/// Prize pegs, ball counts and everything that moves are drawn by the board's
/// painter on top of this.
void paintBoardStaticLayer(Canvas canvas, Level level) {
  _paintFelt(canvas);
  _paintRail(canvas);
  _paintLevelSign(canvas, level.levelNumber);
  // Every glow before any slot, so that no slot is washed by its neighbour's.
  // Clipped to the board: the edge slots' glows are wider than the space
  // beside them, and nothing the board draws may cross its sides
  canvas.save();
  canvas.clipRect(const Rect.fromLTWH(0, 0, GameConstants.boardWidth, GameConstants.boardHeight));
  for (final slot in level.slots) {
    _paintLightSpill(canvas, slot.bounds, slot.color);
  }
  canvas.restore();
  for (final slot in level.slots) {
    _paintSlot(canvas, slot.bounds, slot.color, slot.pointValue);
  }
  for (final peg in level.pegs) {
    if (peg.type == PegType.special) continue;
    paintSphere(canvas, Offset(peg.position.x, peg.position.y), peg.radius, peg.color);
  }
}

/// Felt lit from the dome: brightest under it, falling off to the corners.
void _paintFelt(Canvas canvas) {
  const domeCentre = Offset(
    (GameConstants.topCurveStartX + GameConstants.topCurveEndX) / 2,
    GameConstants.topCurveStartY,
  );
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, GameConstants.boardWidth, GameConstants.boardHeight),
    Paint()
      ..shader = ui.Gradient.radial(
        domeCentre,
        GameConstants.boardHeight * 0.9,
        [GameConstants.feltColor, GameConstants.feltShadeColor],
      ),
  );
}

/// The walls and the dome as one chrome rail over a soft glow.
void _paintRail(Canvas canvas) {
  const channelRight = GameConstants.launchChannelStartX + GameConstants.launchChannelWidth;
  final outline = Path()
    ..moveTo(GameConstants.topCurveStartX, GameConstants.launchChannelStartY)
    ..lineTo(GameConstants.topCurveStartX, GameConstants.topCurveStartY)
    ..quadraticBezierTo(
      GameConstants.topCurveControlX,
      GameConstants.topCurveControlY,
      GameConstants.topCurveEndX,
      GameConstants.topCurveEndY,
    )
    ..lineTo(channelRight, GameConstants.launchChannelEndY)
    ..lineTo(channelRight, GameConstants.launchChannelStartY);
  const innerWallBottom = Offset(GameConstants.launchChannelStartX, GameConstants.launchChannelStartY);
  const innerWallTop =
      Offset(GameConstants.launchChannelStartX, GameConstants.launchChannelInnerWallTopY);

  Paint stroke(double width) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  // The glow is two wide, faint strokes, not a blur
  final passes = [
    stroke(12)..color = GameConstants.primaryColor.withValues(alpha: 0.08),
    stroke(7)..color = GameConstants.primaryColor.withValues(alpha: 0.14),
    stroke(4)
      ..shader = ui.Gradient.linear(
        const Offset(GameConstants.topCurveStartX, 0),
        const Offset(channelRight, GameConstants.launchChannelStartY),
        [GameConstants.chromeColor, GameConstants.slateColor],
      ),
  ];
  for (final paint in passes) {
    canvas.drawPath(outline, paint);
    canvas.drawLine(innerWallBottom, innerWallTop, paint);
  }
}

/// The level's sign, under the top of the dome. Balls pass over it.
void _paintLevelSign(Canvas canvas, int levelNumber) {
  final sign = TextPainter(
    text: TextSpan(
      text: 'LEVEL $levelNumber',
      style: TextStyle(
        color: GameConstants.inkColor.withValues(alpha: 0.9),
        fontFamily: displayFontFamily,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 4,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  const domeCentreX = (GameConstants.topCurveStartX + GameConstants.topCurveEndX) / 2;
  sign.paint(canvas, Offset(domeCentreX - sign.width / 2, 46));
}

/// Light in the slot's tier [colour] rising from its mouth. Round and soft
/// edged on purpose: nothing collides in the band above the slots, so
/// nothing drawn there may look like a wall or a divider.
void _paintLightSpill(Canvas canvas, Rect bounds, Color colour) {
  final radius = bounds.width * 0.75;
  canvas.drawCircle(
    bounds.topCenter,
    radius,
    Paint()
      ..shader = ui.Gradient.radial(
        bounds.topCenter,
        radius,
        [colour.withValues(alpha: 0.28), colour.withValues(alpha: 0.0)],
      ),
  );
}

/// A dark glass pocket with a neon rim and its value in the tier [colour].
void _paintSlot(Canvas canvas, Rect bounds, Color colour, int pointValue) {
  final pocket = RRect.fromRectAndRadius(bounds, const Radius.circular(4));
  canvas.drawRRect(
    pocket,
    Paint()
      ..shader = ui.Gradient.linear(
        bounds.topCenter,
        bounds.bottomCenter,
        [
          GameConstants.cabinetColor.withValues(alpha: 0.92),
          Color.lerp(GameConstants.cabinetColor, colour, 0.28)!,
        ],
      ),
  );
  canvas.drawRRect(
    pocket,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = colour.withValues(alpha: 0.22),
  );
  canvas.drawRRect(
    pocket,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = colour,
  );

  final value = TextPainter(
    text: TextSpan(
      text: pointValue.toString(),
      style: TextStyle(
        color: colour,
        fontFamily: displayFontFamily,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  value.paint(canvas, bounds.center - Offset(value.width / 2, value.height / 2));
  value.dispose();
}

/// Keeps the picture of a level's static layer, so that it is recorded once
/// per level and replayed on every repaint.
class BoardStaticLayer {
  Level? _level;
  ui.Picture? _picture;

  /// How many pictures have been recorded. Tests read it to see that a
  /// repaint does not record one.
  @visibleForTesting
  static int debugBuildCount = 0;

  /// The picture of [level]'s static layer, in board coordinates.
  ///
  /// The same picture comes back until another level object is passed: a
  /// level's pegs and slots do not move once it has been generated.
  ui.Picture pictureFor(Level level) {
    final cached = _picture;
    if (cached != null && identical(level, _level)) return cached;

    cached?.dispose();
    final recorder = ui.PictureRecorder();
    paintBoardStaticLayer(Canvas(recorder), level);
    debugBuildCount++;
    _level = level;
    return _picture = recorder.endRecording();
  }

  /// Releases the picture. A later [pictureFor] records a new one.
  void dispose() {
    _picture?.dispose();
    _picture = null;
    _level = null;
  }
}
