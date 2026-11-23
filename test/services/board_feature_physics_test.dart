import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:pachinko_game/models/ball.dart';
import 'package:pachinko_game/models/board_feature.dart';
import 'package:pachinko_game/models/peg.dart';
import 'package:pachinko_game/services/audio_service.dart';
import 'package:pachinko_game/services/haptics_service.dart';
import 'package:pachinko_game/services/physics_engine.dart';
import 'package:pachinko_game/utils/constants.dart';

/// The collision shapes of the three board features (#114), through the
/// real `PhysicsEngine`: a tulip catches from above only while open and is a
/// solid body otherwise, and a windmill's blades and the centre gate's bar
/// throw a ball with the speed of the part that meets it.
void main() {
  late _RecordingAudio audio;
  late _RecordingHaptics haptics;
  late PhysicsEngine engine;

  setUp(() {
    audio = _RecordingAudio();
    haptics = _RecordingHaptics();
    engine = PhysicsEngine(
        audioService: audio, haptics: haptics, random: math.Random(1));
  });

  Tulip tulipAt(double x, double y) => Tulip(
      position: Vector2(x, y),
      triggerPin: Peg(position: Vector2(x - 22, y - 42)));

  void open(Tulip tulip) {
    tulip.triggerPin.timesStruck++;
    engine.updateFeatures([tulip], 0.0);
  }

  group('Tulip', () {
    test(
        'given its trigger pin struck, when the features step, then it opens and is heard',
        () {
      final tulip = tulipAt(110, 250);

      open(tulip);

      expect(tulip.isOpen, isTrue);
      expect(audio.played, ['tulipOpen']);
    });

    test(
        'given an open tulip, when a ball falls onto its mouth, then the ball is caught and leaves play',
        () {
      final tulip = tulipAt(110, 250);
      open(tulip);
      final ball = Ball(position: Vector2(110, 232), velocity: Vector2(0, 200));

      final hits = engine.checkFeatureCollisions([ball], [tulip]);

      expect(hits, hasLength(1));
      expect(hits.single.caught, isTrue);
      expect(hits.single.feature, same(tulip));
      expect(ball.isActive, isFalse);
      expect(ball.hasLanded, isFalse);
      expect(tulip.catches, 1);
      expect(tulip.isOpen, isFalse);
    });

    test('given a closed tulip, when a ball falls onto it, then it bounces off',
        () {
      final tulip = tulipAt(110, 250);
      final ball = Ball(position: Vector2(110, 232), velocity: Vector2(0, 200));

      final hits = engine.checkFeatureCollisions([ball], [tulip]);

      expect(hits.single.caught, isFalse);
      expect(ball.isActive, isTrue);
      expect(ball.velocity.y, lessThan(0));
      expect((ball.position - tulip.position).length,
          closeTo(GameConstants.tulipRadius + ball.radius, 1e-6));
      expect(audio.played, ['pegHit']);
      expect(haptics.felt, ['pin']);
    });

    test(
        'given an open tulip, when a ball meets it from the side, then it bounces off',
        () {
      final tulip = tulipAt(110, 250);
      open(tulip);
      final ball = Ball(position: Vector2(91, 250), velocity: Vector2(150, 0));

      final hits = engine.checkFeatureCollisions([ball], [tulip]);

      expect(hits.single.caught, isFalse);
      expect(ball.isActive, isTrue);
      expect(ball.velocity.x, lessThan(0));
      expect(tulip.isOpen, isTrue);
    });

    test('given a ball clear of the tulip, then nothing happens', () {
      final tulip = tulipAt(110, 250);
      final ball = Ball(position: Vector2(110, 200));

      expect(engine.checkFeatureCollisions([ball], [tulip]), isEmpty);
    });
  });

  group('Turning bars', () {
    test(
        'given a ball resting on a windmill blade, when the blade turns up into it, then it is thrown up',
        () {
      // The first blade points right at the start; the windmill turns
      // anticlockwise on screen, so that blade's far end is rising
      final windmill = Windmill(pivot: Vector2(100, 320));
      final ball = Ball(position: Vector2(120, 311), velocity: Vector2.zero());

      final hits = engine.checkFeatureCollisions([ball], [windmill]);

      expect(hits.single.feature, same(windmill));
      expect(hits.single.caught, isFalse);
      expect(ball.velocity.y, lessThan(0));
      expect(
          ball.position.y,
          closeTo(
              320 - ball.radius - GameConstants.featureBarHalfThickness, 1e-6));
      expect(audio.played.single, startsWith('windmill'));
    });

    test(
        'given the gate level, when a ball falls onto it, then it is turned back up',
        () {
      final gate = CentreGate(pivot: Vector2(192.5, 530));
      final ball =
          Ball(position: Vector2(192.5, 521), velocity: Vector2(0, 300));

      final hits = engine.checkFeatureCollisions([ball], [gate]);

      expect(hits.single.feature, same(gate));
      expect(ball.velocity.y, lessThan(0));
      expect(audio.played.single, startsWith('gate'));
    });

    test(
        'given the gate steep, when a ball falls onto it, then it is guided down the bar',
        () {
      final gate = CentreGate(pivot: Vector2(192.5, 530));
      engine.updateFeatures([gate], GameConstants.centreGatePeriod / 4);
      final bar = gate.bars.single;
      // Resting on the bar a quarter of the way down it, falling
      final along = bar.end - bar.start;
      final upwards = Vector2(along.y, -along.x).normalized();
      final ball = Ball(
          position: bar.start +
              along * 0.25 +
              upwards *
                  (GameConstants.ballRadius +
                      GameConstants.featureBarHalfThickness -
                      1),
          velocity: Vector2(0, 200));

      engine.checkFeatureCollisions([ball], [gate]);

      // The bar runs down to the right: the ball keeps falling and moves right
      expect(ball.velocity.x, greaterThan(0));
      expect(ball.velocity.y, greaterThan(0));
    });

    test(
        'given a ball already moving away from a bar, then it is moved clear and not slowed',
        () {
      final gate = CentreGate(pivot: Vector2(192.5, 530));
      final ball =
          Ball(position: Vector2(192.5, 522), velocity: Vector2(0, -300));

      engine.checkFeatureCollisions([ball], [gate]);

      expect(ball.velocity.y, -300);
      expect(
          ball.position.y,
          closeTo(
              530 - ball.radius - GameConstants.featureBarHalfThickness, 1e-6));
    });
  });

  test(
      'given a ball riding a feature, then its bounces sound only after a pause',
      () {
    final gate = CentreGate(pivot: Vector2(192.5, 530));
    Ball falling() =>
        Ball(position: Vector2(192.5, 521), velocity: Vector2(0, 300));

    engine.checkFeatureCollisions([falling()], [gate]);
    engine.updateFeatures([gate], BoardFeature.soundRepeatSeconds / 2);
    engine.checkFeatureCollisions([falling()], [gate]);
    expect(audio.played, hasLength(1));

    engine.updateFeatures([gate], BoardFeature.soundRepeatSeconds);
    engine.checkFeatureCollisions([falling()], [gate]);
    expect(audio.played, hasLength(2));
  });

  test('given a ball caught or landed, then no later feature meets it', () {
    final tulip = tulipAt(110, 250);
    open(tulip);
    final windmill = Windmill(pivot: Vector2(110, 250));
    final ball = Ball(position: Vector2(110, 232), velocity: Vector2(0, 200));

    final hits = engine.checkFeatureCollisions([ball], [tulip, windmill]);

    expect(hits, hasLength(1));
    final landed = Ball(position: Vector2(110, 232))..hasLanded = true;
    expect(engine.checkFeatureCollisions([landed], [windmill]), isEmpty);
  });

  group('Trigger pins', () {
    test('given a ball moving into a pin, then the pin counts the strike', () {
      final pin = Peg(position: Vector2(200, 200), radius: 10);
      final ball = Ball(position: Vector2(200, 183), velocity: Vector2(0, 100));

      engine.checkPegCollisions([ball], [pin]);

      expect(pin.timesStruck, 1);
    });

    test(
        'given a ball already moving away from a pin, then no strike is counted',
        () {
      final pin = Peg(position: Vector2(200, 200), radius: 10);
      final ball =
          Ball(position: Vector2(200, 183), velocity: Vector2(0, -100));

      engine.checkPegCollisions([ball], [pin]);

      expect(pin.timesStruck, 0);
    });
  });
}

/// Audio that plays nothing and records what it was asked for.
class _RecordingAudio extends AudioService {
  final List<String> played = [];

  @override
  Future<void> playPegHit(double impactSpeed) async => played.add('pegHit');

  @override
  Future<void> playTulipOpen() async => played.add('tulipOpen');

  @override
  Future<void> playWindmillHit(double impactSpeed) async =>
      played.add('windmill $impactSpeed');

  @override
  Future<void> playGateHit(double impactSpeed) async =>
      played.add('gate $impactSpeed');
}

/// Haptics that vibrate nothing and record what they were asked for.
class _RecordingHaptics extends HapticsService {
  final List<String> felt = [];

  @override
  void pin() => felt.add('pin');
}
