import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:pachinko_game/models/board_feature.dart';
import 'package:pachinko_game/models/peg.dart';
import 'package:pachinko_game/utils/constants.dart';
import 'package:pachinko_game/widgets/board_features.dart';
import 'package:pachinko_game/widgets/board_static_layer.dart';

/// The drawing of the board features (#114): each in its states, as goldens,
/// and the rule that their colours come from the palette's roles.
void main() {
  const patchKey = ValueKey('features');

  /// Paints [features] on a patch of felt [width] board pixels wide, three
  /// times life size, with the trigger pins as the static layer draws them.
  Widget patch(List<BoardFeature> features, {double width = 220}) => Center(
        child: RepaintBoundary(
          key: patchKey,
          child: CustomPaint(
            size: Size(width * _zoom, 110 * _zoom),
            painter: _FeaturePainter(features),
          ),
        ),
      );

  Tulip tulipAt(double x) => Tulip(
      position: Vector2(x, 70),
      triggerPin: Peg(
          position: Vector2(x - GameConstants.tulipTriggerOffsetX,
              70 - GameConstants.tulipTriggerRise),
          radius: GameConstants.tulipTriggerRadius));

  testWidgets('a tulip closed, and open', (tester) async {
    final closed = tulipAt(60);
    final open = tulipAt(170);
    open.triggerPin.timesStruck++;
    open.update(0.0);

    await tester.pumpWidget(patch([closed, open]));

    await expectLater(
        find.byKey(patchKey), matchesGoldenFile('goldens/feature_tulip.png'));
  }, tags: ['golden']);

  testWidgets('a windmill, turned a little', (tester) async {
    final windmill = Windmill(pivot: Vector2(60, 55))..advance(0.1);

    await tester.pumpWidget(patch([windmill], width: 120));

    await expectLater(find.byKey(patchKey),
        matchesGoldenFile('goldens/feature_windmill.png'));
  }, tags: ['golden']);

  testWidgets('the centre gate level, and steep', (tester) async {
    final level = CentreGate(pivot: Vector2(60, 60));
    final steep = CentreGate(pivot: Vector2(160, 60))
      ..advance(GameConstants.centreGatePeriod / 4);

    await tester.pumpWidget(patch([level, steep]));

    await expectLater(find.byKey(patchKey),
        matchesGoldenFile('goldens/feature_centre_gate.png'));
  }, tags: ['golden']);

  test('the features draw an open tulip lit and a closed one not', () {
    final closed = tulipAt(60);
    final open = tulipAt(170);
    open.triggerPin.timesStruck++;
    open.update(0.0);

    bool glows(Tulip tulip) {
      final canvas = TestRecordingCanvas();
      paintTulip(canvas, tulip);
      // The glow is the one pass that reaches twice the body's radius
      return canvas.invocations
          .map((recorded) => recorded.invocation)
          .where((call) => call.memberName == #drawCircle)
          .any((call) =>
              (call.positionalArguments[1] as double) >=
              GameConstants.tulipRadius * 2 - 1e-9);
    }

    expect(glows(open), isTrue);
    expect(glows(closed), isFalse);
  });

  test('the features name no colour of their own: every one is a role', () {
    final source = File('lib/widgets/board_features.dart').readAsStringSync();
    expect(source, isNot(contains('Colors.')));
    expect(source, isNot(contains(RegExp(r'Color(\.from\w+)?\('))));
  });
}

/// How much larger than life the goldens draw the features.
const double _zoom = 3;

class _FeaturePainter extends CustomPainter {
  _FeaturePainter(this.features);

  final List<BoardFeature> features;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(_zoom);
    canvas.drawRect(
        Offset.zero & size / _zoom, Paint()..color = GameConstants.feltColor);
    for (final tulip in features.whereType<Tulip>()) {
      final pin = tulip.triggerPin;
      paintSphere(canvas, Offset(pin.position.x, pin.position.y), pin.radius,
          pin.color);
    }
    paintBoardFeatures(canvas, features);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
