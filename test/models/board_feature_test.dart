import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:pachinko_game/models/board_feature.dart';
import 'package:pachinko_game/models/peg.dart';
import 'package:pachinko_game/utils/constants.dart';

/// The state of the three board features (#114): a tulip's opening, catch
/// and closing, a windmill's angle and the centre gate's swing. Their
/// collisions are in test/services/board_feature_physics_test.dart.
void main() {
  group('Tulip', () {
    late Peg trigger;
    late Tulip tulip;

    setUp(() {
      trigger = Peg(position: Vector2(88, 208));
      tulip = Tulip(position: Vector2(110, 250), triggerPin: trigger);
    });

    test('given a new tulip, then it is closed and reaches as far as its body',
        () {
      expect(tulip.isOpen, isFalse);
      expect(tulip.openRemaining, 0.0);
      expect(tulip.centre, tulip.position);
      expect(tulip.reach, GameConstants.tulipRadius);
    });

    test('given its trigger pin struck, when updated, then it opens, once', () {
      trigger.timesStruck++;

      expect(tulip.triggered, isTrue);
      expect(tulip.update(0.01), isTrue);
      expect(tulip.isOpen, isTrue);
      expect(tulip.openRemaining, 1.0);
      expect(tulip.triggered, isFalse);
      expect(tulip.update(0.01), isFalse, reason: 'already open');
    });

    test(
        'given an open tulip, when its open time passes without a catch, then it closes',
        () {
      trigger.timesStruck++;
      tulip.update(0.0);

      tulip.update(GameConstants.tulipOpenSeconds / 2);
      expect(tulip.isOpen, isTrue);
      expect(tulip.openRemaining, closeTo(0.5, 1e-9));

      tulip.update(GameConstants.tulipOpenSeconds / 2);
      expect(tulip.isOpen, isFalse);
    });

    test(
        'given an open tulip, when its pin is struck again, then its open time starts again',
        () {
      trigger.timesStruck++;
      tulip.update(0.0);
      tulip.update(GameConstants.tulipOpenSeconds * 0.9);

      trigger.timesStruck++;
      expect(tulip.update(0.01), isFalse,
          reason: 'it did not open from closed');

      expect(tulip.openRemaining, 1.0);
    });

    test(
        'given an open tulip, then only a ball from above falls into its mouth',
        () {
      trigger.timesStruck++;
      tulip.update(0.0);

      expect(tulip.catchesAt(Vector2(0, -1)), isTrue);
      final edge = GameConstants.tulipMouthHalfAngle - 0.01;
      expect(tulip.catchesAt(Vector2(math.sin(edge), -math.cos(edge))), isTrue);
      final outside = GameConstants.tulipMouthHalfAngle + 0.01;
      expect(tulip.catchesAt(Vector2(math.sin(outside), -math.cos(outside))),
          isFalse);
      expect(tulip.catchesAt(Vector2(1, 0)), isFalse);
      expect(tulip.catchesAt(Vector2(0, 1)), isFalse);
    });

    test('given a closed tulip, then nothing falls into it', () {
      expect(tulip.catchesAt(Vector2(0, -1)), isFalse);
    });

    test(
        'given an open tulip, when it catches a ball, then it counts it and closes',
        () {
      trigger.timesStruck++;
      tulip.update(0.0);

      tulip.catchBall();

      expect(tulip.catches, 1);
      expect(tulip.isOpen, isFalse);
    });

    test(
        'given an open tulip, when closed, then it keeps its catches and a strike before does not reopen it',
        () {
      trigger.timesStruck++;
      tulip.update(0.0);
      tulip.catchBall();
      trigger.timesStruck++;
      tulip.update(0.0);
      trigger.timesStruck++;

      tulip.close();

      expect(tulip.isOpen, isFalse);
      expect(tulip.catches, 1);
      expect(tulip.update(0.01), isFalse);
    });

    test('given a tulip that has played, when reset, then it starts again', () {
      trigger.timesStruck++;
      tulip.update(0.0);
      tulip.catchBall();
      tulip.soundCooldown = 0.1;
      trigger.reset();

      tulip.reset();

      expect(tulip.isOpen, isFalse);
      expect(tulip.catches, 0);
      expect(tulip.soundCooldown, 0.0);
      trigger.timesStruck++;
      expect(tulip.update(0.0), isTrue);
    });
  });

  group('Windmill', () {
    late Windmill windmill;

    setUp(() => windmill = Windmill(pivot: Vector2(100, 320)));

    test('given a windmill, then its blades start from the hub, evenly spaced',
        () {
      final bars = windmill.bars;

      expect(bars, hasLength(GameConstants.windmillBlades));
      for (int i = 0; i < bars.length; i++) {
        expect(bars[i].start, windmill.pivot);
        expect((bars[i].end - bars[i].start).length,
            closeTo(GameConstants.windmillBladeLength, 1e-9));
      }
      // The first blade points right; with four, the next points down
      expect(bars[0].end.x, closeTo(124, 1e-9));
      expect(bars[1].end.y, closeTo(344, 1e-9));
    });

    test('given a windmill, then it reaches its blades and their thickness',
        () {
      expect(windmill.centre, windmill.pivot);
      expect(
          windmill.reach,
          GameConstants.windmillBladeLength +
              GameConstants.featureBarHalfThickness);
    });

    test('given play, then it turns at its steady spin and stays within a turn',
        () {
      windmill.advance(0.5);
      expect(windmill.angle,
          closeTo((GameConstants.windmillSpin * 0.5) % (2 * math.pi), 1e-9));
      expect(windmill.angularVelocity, GameConstants.windmillSpin);

      for (int i = 0; i < 100; i++) {
        windmill.advance(0.1);
      }
      expect(windmill.angle, inInclusiveRange(0.0, 2 * math.pi));
    });

    test('given a turned windmill, when reset, then it is back at the start',
        () {
      windmill.advance(1.3);
      windmill.reset();
      expect(windmill.angle, 0.0);
    });
  });

  group('Centre gate', () {
    late CentreGate gate;

    setUp(() => gate = CentreGate(pivot: Vector2(192.5, 530)));

    test('given a level starting, then the gate is level and swinging', () {
      final bar = gate.bars.single;

      expect(gate.angle, 0.0);
      expect(bar.start.y, closeTo(530, 1e-9));
      expect(bar.end.y, closeTo(530, 1e-9));
      expect(bar.end.x - bar.start.x,
          closeTo(2 * GameConstants.centreGateHalfLength, 1e-9));
      expect(gate.angularVelocity, greaterThan(0));
    });

    test(
        'given a quarter of its period, then it is at its steepest and still for a moment',
        () {
      gate.advance(GameConstants.centreGatePeriod / 4);

      expect(gate.angle, closeTo(GameConstants.centreGateSwing, 1e-9));
      expect(gate.angularVelocity, closeTo(0.0, 1e-9));
      final bar = gate.bars.single;
      expect((bar.end - bar.start).length,
          closeTo(2 * GameConstants.centreGateHalfLength, 1e-9));
      expect(bar.end.y, greaterThan(bar.start.y));
    });

    test('given three quarters of its period, then it leans the other way', () {
      gate.advance(GameConstants.centreGatePeriod * 3 / 4);
      expect(gate.angle, closeTo(-GameConstants.centreGateSwing, 1e-9));
    });

    test('given a gate, then it reaches its bar and the bar thickness', () {
      expect(gate.centre, gate.pivot);
      expect(
          gate.reach,
          GameConstants.centreGateHalfLength +
              GameConstants.featureBarHalfThickness);
    });

    test('given a gate that has swung, when reset, then it is level again', () {
      gate.advance(1.0);
      gate.soundCooldown = 0.1;
      gate.reset();
      expect(gate.time, 0.0);
      expect(gate.angle, 0.0);
      expect(gate.soundCooldown, 0.0);
    });
  });

  test('given a bounce sounded, when play passes, then its pause runs down',
      () {
    final windmill = Windmill(pivot: Vector2(100, 320));
    windmill.soundCooldown = BoardFeature.soundRepeatSeconds;
    windmill.advance(0.1);
    expect(windmill.soundCooldown,
        closeTo(BoardFeature.soundRepeatSeconds - 0.1, 1e-9));
    windmill.advance(1.0);
    expect(windmill.soundCooldown, 0.0);
  });
}
