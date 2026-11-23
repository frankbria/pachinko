import 'dart:ui';
import '../models/board_feature.dart';
import '../utils/constants.dart';
import 'board_static_layer.dart';

/// Draws the level's tulips, windmill and centre gate where they are now.
///
/// They move or change while a level is played, so the board's painter draws
/// them on every repaint, over the static layer. The tulip pays balls, so it
/// is gold; the windmill and the gate are brass, like the pins, and do not
/// glow. Every sphere is drawn through [paintSphere] with [mirrored], so it is
/// lit from the upper left on a left-handed board too; the rest is symmetric
/// or is the feature's own shape, which the board's reflection reflects.
void paintBoardFeatures(Canvas canvas, List<BoardFeature> features,
    {bool mirrored = false}) {
  for (final feature in features) {
    switch (feature) {
      case Tulip():
        paintTulip(canvas, feature, mirrored: mirrored);
      case Windmill():
        paintWindmill(canvas, feature, mirrored: mirrored);
      case CentreGate():
        paintCentreGate(canvas, feature, mirrored: mirrored);
    }
  }
}

/// How far each petal of a tulip leans out from upright, in radians, closed
/// and open.
const double _petalLeanClosed = 0.2;
const double _petalLeanOpen = 0.95;

/// The tulip's petals: its gold, a shade darker so they stand apart from the
/// body.
final Color _petalColour =
    Color.lerp(GameConstants.goldColor, GameConstants.cabinetColor, 0.25)!;

/// A tulip: a gold body with two small petals, which reach only a few
/// pixels past the body that balls meet, upright while it is closed and
/// spread wide, over a gold glow, while it is open. A thin gold ring marks
/// the pin that opens it, brighter while it is open.
void paintTulip(Canvas canvas, Tulip tulip, {bool mirrored = false}) {
  final centre = Offset(tulip.position.x, tulip.position.y);
  const radius = GameConstants.tulipRadius;
  final trigger = tulip.triggerPin;
  canvas.drawCircle(
    Offset(trigger.position.x, trigger.position.y),
    trigger.radius + 3,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color =
          GameConstants.goldColor.withValues(alpha: tulip.isOpen ? 0.8 : 0.35),
  );

  final lean = tulip.isOpen ? _petalLeanOpen : _petalLeanClosed;
  final petal = Paint()..color = _petalColour;
  for (final side in const [-1.0, 1.0]) {
    canvas.save();
    canvas.translate(
        centre.dx + side * radius * 0.45, centre.dy - radius * 0.5);
    canvas.rotate(side * lean);
    canvas.drawOval(
        Rect.fromCenter(
            center: const Offset(0, -radius * 0.35),
            width: radius * 0.5,
            height: radius * 0.9),
        petal);
    canvas.restore();
  }

  // Open, it is a light: a glow and no shadow, like a prize peg still to win
  paintSphere(canvas, centre, radius, GameConstants.goldColor,
      castsShadow: !tulip.isOpen,
      glowColour: tulip.isOpen ? GameConstants.goldColor : null,
      mirrored: mirrored);
}

/// A windmill: brass blades out from a brass hub, at their present angle.
void paintWindmill(Canvas canvas, Windmill windmill, {bool mirrored = false}) {
  _paintBars(canvas, windmill);
  paintSphere(canvas, Offset(windmill.pivot.x, windmill.pivot.y), 5,
      GameConstants.brassColor,
      mirrored: mirrored);
}

/// The centre gate: a brass bar on a brass pivot, at its present angle.
void paintCentreGate(Canvas canvas, CentreGate gate, {bool mirrored = false}) {
  _paintBars(canvas, gate);
  paintSphere(
      canvas, Offset(gate.pivot.x, gate.pivot.y), 3.5, GameConstants.brassColor,
      mirrored: mirrored);
}

/// The bars of [feature], as thick as the physics makes them, with round
/// ends, and a thin line of light along each.
void _paintBars(Canvas canvas, TurningFeature feature) {
  final body = Paint()
    ..color = GameConstants.brassColor
    ..strokeWidth = GameConstants.featureBarHalfThickness * 2
    ..strokeCap = StrokeCap.round;
  final shine = Paint()
    ..color = GameConstants.chromeColor.withValues(alpha: 0.45)
    ..strokeWidth = 1
    ..strokeCap = StrokeCap.round;
  for (final bar in feature.bars) {
    final start = Offset(bar.start.x, bar.start.y);
    final end = Offset(bar.end.x, bar.end.y);
    canvas.drawLine(start, end, body);
    canvas.drawLine(start, end, shine);
  }
}
