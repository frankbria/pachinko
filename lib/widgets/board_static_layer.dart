import 'dart:math' as math;
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
///
/// On a [mirrored] board the sphere is reflected about its own centre as it
/// is drawn, so that, with the board's reflection, it is still lit from the
/// upper left.
void paintSphere(
  Canvas canvas,
  Offset centre,
  double radius,
  Color colour, {
  bool castsShadow = true,
  Color? glowColour,
  bool mirrored = false,
}) =>
    paintUnreflected(canvas,
        aboutX: centre.dx,
        mirrored: mirrored,
        paint: () => _paintSphere(canvas, centre, radius, colour,
            castsShadow: castsShadow, glowColour: glowColour));

void _paintSphere(
  Canvas canvas,
  Offset centre,
  double radius,
  Color colour, {
  required bool castsShadow,
  required Color? glowColour,
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
          [
            glowColour.withValues(alpha: 0.45),
            glowColour.withValues(alpha: 0.0)
          ],
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

/// Reflects the board about its middle, for a left-handed player: the
/// launch channel and the plunger are then on the left. Only the drawing is
/// reflected; the physics, the level and the scores are the same on either
/// side, so the same launches give the same results.
void mirrorBoard(Canvas canvas) {
  canvas.translate(GameConstants.boardWidth, 0);
  canvas.scale(-1, 1);
}

/// Where [x], in board coordinates, is drawn on a [mirrored] board, and
/// where a touch drawn at [x] lands on the board: the reflection is its own
/// inverse.
double boardXOnScreen(double x, {required bool mirrored}) =>
    mirrored ? GameConstants.boardWidth - x : x;

/// Runs [paint] reflected about the vertical line at [aboutX] when
/// [mirrored], and as it is otherwise.
///
/// On a board reflected by [mirrorBoard], whatever must not read reversed
/// (text, and the light and shadow of a sphere) is drawn through this:
/// reflected twice, it reads as on the right-handed board, in the reflected
/// place.
void paintUnreflected(Canvas canvas,
    {required double aboutX,
    required bool mirrored,
    required void Function() paint}) {
  if (!mirrored) return paint();
  canvas.save();
  canvas.translate(2 * aboutX, 0);
  canvas.scale(-1, 1);
  paint();
  canvas.restore();
}

/// Draws the parts of the board that do not change while a level is played:
/// the felt, the chrome rail, the brass pins and the unlit slots.
///
/// Prize pegs, ball counts and everything that moves are drawn by the board's
/// painter on top of this. On a [mirrored] board (see [mirrorBoard]) the
/// text and the pins' light are drawn so that they read the right way round.
void paintBoardStaticLayer(Canvas canvas, Level level,
    {bool mirrored = false}) {
  final band = GameConstants.bandForLevel(level.levelNumber);
  _paintFelt(canvas, band);
  _paintRail(canvas, band);
  _paintLevelSign(canvas, level.name.toUpperCase(), band, mirrored: mirrored);
  // Every glow before any slot, so that no slot is washed by its neighbour's
  for (final slot in level.slots) {
    _paintLightSpill(canvas, slot.bounds, slot.color);
  }
  for (final slot in level.slots) {
    _paintSlot(canvas, slot.bounds, slot.color, slot.pointValue,
        mirrored: mirrored);
  }
  for (final peg in level.pegs) {
    if (peg.type == PegType.special) continue;
    paintSphere(
        canvas, Offset(peg.position.x, peg.position.y), peg.radius, peg.color,
        mirrored: mirrored);
  }
}

/// Felt lit from the dome: brightest under it, falling off to the corners.
void _paintFelt(Canvas canvas, LevelBand band) {
  const domeCentre = Offset(
    (GameConstants.topCurveStartX + GameConstants.topCurveEndX) / 2,
    GameConstants.topCurveStartY,
  );
  canvas.drawRect(
    const Rect.fromLTWH(
        0, 0, GameConstants.boardWidth, GameConstants.boardHeight),
    Paint()
      ..shader = ui.Gradient.radial(
        domeCentre,
        GameConstants.boardHeight * 0.9,
        [band.felt, band.feltShade],
      ),
  );
}

/// The walls and the dome as one chrome rail over a soft glow.
void _paintRail(Canvas canvas, LevelBand band) {
  const channelRight =
      GameConstants.launchChannelStartX + GameConstants.launchChannelWidth;
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
  const innerWallBottom = Offset(
      GameConstants.launchChannelStartX, GameConstants.launchChannelStartY);
  const innerWallTop = Offset(GameConstants.launchChannelStartX,
      GameConstants.launchChannelInnerWallTopY);

  Paint stroke(double width) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  // The glow is two wide, faint strokes, not a blur
  final passes = [
    stroke(12)..color = band.rim.withValues(alpha: 0.08),
    stroke(7)..color = band.rim.withValues(alpha: 0.14),
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

/// The level's sign, under the top of the dome, reading [name]: LEVEL 4, or
/// DAILY on the daily board. Balls pass over it.
void _paintLevelSign(Canvas canvas, String name, LevelBand band,
    {required bool mirrored}) {
  final sign = TextPainter(
    text: TextSpan(
      text: name,
      style: TextStyle(
        color: band.rim,
        fontFamily: displayFontFamily,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 4,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  const domeCentreX =
      (GameConstants.topCurveStartX + GameConstants.topCurveEndX) / 2;
  paintUnreflected(canvas,
      aboutX: domeCentreX,
      mirrored: mirrored,
      paint: () =>
          sign.paint(canvas, Offset(domeCentreX - sign.width / 2, 46)));
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
void _paintSlot(Canvas canvas, Rect bounds, Color colour, int pointValue,
    {required bool mirrored}) {
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

  paintSlotValue(canvas, bounds, pointValue, colour,
      dispose: true, mirrored: mirrored);
}

/// Writes a slot's [pointValue] in the middle of its [bounds]: across, or
/// sideways (reading upwards) where the slot is narrower than the value is
/// long, as the two edge slots are.
///
/// With [dispose] the text is released once drawn; a caller whose drawing is
/// read back by a test leaves it. On a [mirrored] board it is drawn to read
/// the right way round.
void paintSlotValue(Canvas canvas, Rect bounds, int pointValue, Color colour,
    {bool dispose = false, bool mirrored = false}) {
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
  final middle = -Offset(value.width / 2, value.height / 2);
  paintUnreflected(canvas, aboutX: bounds.center.dx, mirrored: mirrored,
      paint: () {
    if (value.width <= bounds.width) {
      value.paint(canvas, bounds.center + middle);
    } else {
      canvas.save();
      canvas.translate(bounds.center.dx, bounds.center.dy);
      canvas.rotate(-math.pi / 2);
      value.paint(canvas, middle);
      canvas.restore();
    }
  });
  if (dispose) value.dispose();
}

/// Keeps the picture of a level's static layer, so that it is recorded once
/// per level and replayed on every repaint.
class BoardStaticLayer {
  Level? _level;
  bool _mirrored = false;
  ui.Picture? _picture;

  /// How many pictures have been recorded. Tests read it to see that a
  /// repaint does not record one.
  @visibleForTesting
  static int debugBuildCount = 0;

  /// The picture of [level]'s static layer, in board coordinates, for a
  /// board drawn [mirrored] or not.
  ///
  /// The same picture comes back until another level object, or the other
  /// side, is asked for: a level's pegs and slots do not move once it has
  /// been generated.
  ui.Picture pictureFor(Level level, {bool mirrored = false}) {
    final cached = _picture;
    if (cached != null && identical(level, _level) && mirrored == _mirrored) {
      return cached;
    }

    cached?.dispose();
    final recorder = ui.PictureRecorder();
    paintBoardStaticLayer(Canvas(recorder), level, mirrored: mirrored);
    debugBuildCount++;
    _level = level;
    _mirrored = mirrored;
    return _picture = recorder.endRecording();
  }

  /// Releases the picture. A later [pictureFor] records a new one.
  void dispose() {
    _picture?.dispose();
    _picture = null;
    _level = null;
  }
}
