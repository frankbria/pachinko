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
/// A sphere that glows passes [castsShadow] as false: a shadow drawn over its
/// own glow reads as a dark ring.
void paintSphere(Canvas canvas, Offset centre, double radius, Color colour, {bool castsShadow = true}) {
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

  canvas.drawCircle(
    centre,
    radius,
    Paint()
      ..shader = ui.Gradient.radial(
        centre - Offset(radius * 0.35, radius * 0.35),
        radius * 1.35,
        [
          Color.lerp(colour, GameConstants.inkColor, 0.8)!,
          colour,
          Color.lerp(colour, GameConstants.cabinetColor, 0.6)!,
        ],
        [0.0, 0.45, 1.0],
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
