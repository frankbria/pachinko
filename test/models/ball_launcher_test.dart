import 'package:flutter_test/flutter_test.dart';
import 'package:pachinko_game/models/ball.dart';
import 'package:pachinko_game/models/ball_launcher.dart';
import 'package:pachinko_game/utils/constants.dart';
import 'dart:math' as math;

void main() {
  group('BallLauncher Initialization -', () {
    test('given new launcher, when created, then initializes in ready phase',
        () {
      // Given / When
      final launcher = BallLauncher();

      // Then
      expect(launcher.phase, equals(LaunchPhase.ready));
    });

    test('given new launcher, when created, then initializes with zero power',
        () {
      // Given / When
      final launcher = BallLauncher();

      // Then
      expect(launcher.launchPower, equals(0.0));
    });

    test(
        'given new launcher, when created, then generates launch path automatically',
        () {
      // Given / When
      final launcher = BallLauncher();
      final path = launcher.getLaunchPath();

      // Then
      expect(path, isNotEmpty);
      expect(path.length, greaterThan(0));
    });

    test('given new launcher, when created, then currentBall is null', () {
      // Given / When
      final launcher = BallLauncher();

      // Then
      expect(launcher.currentBall, isNull);
    });
  });

  group('Launch Path Generation -', () {
    /// The launcher carries the ball up the channel and nowhere else. It used
    /// to carry it on round a quarter circle that was not the dome, which
    /// took the ball outside the boundary (#96). From the top of the channel
    /// the physics has the ball.
    test(
        'given launcher, when path generated, then it runs straight up the channel from the launch position to the channel top',
        () {
      final path = BallLauncher().getLaunchPath();

      expect(path.first.x, GameConstants.ballLaunchX);
      expect(path.first.y, GameConstants.ballLaunchY);
      expect(path.last.x, GameConstants.ballLaunchX);
      expect(path.last.y, GameConstants.launchChannelEndY);
      for (int i = 1; i < path.length; i++) {
        expect(path[i].x, GameConstants.ballLaunchX, reason: 'point $i');
        expect(path[i].y, lessThan(path[i - 1].y), reason: 'point $i');
      }
    });
  });

  group('Power Calculation -', () {
    test(
        'given charging launcher, when power updated, then stays within 0-100 range',
        () {
      // Given
      final launcher = BallLauncher();
      launcher.startCharging();

      // When - try to set power beyond max
      launcher.updateCharging(150.0);

      // Then - should be clamped to maxPower
      expect(launcher.launchPower, equals(100.0));
    });

    test('given charging launcher, when negative power set, then clamps to 0',
        () {
      // Given
      final launcher = BallLauncher();
      launcher.startCharging();

      // When
      launcher.updateCharging(-50.0);

      // Then
      expect(launcher.launchPower, equals(0.0));
    });

    test(
        'given charging launcher, when power updated multiple times, then uses latest value',
        () {
      // Given
      final launcher = BallLauncher();
      launcher.startCharging();

      // When
      launcher.updateCharging(30.0);
      launcher.updateCharging(70.0);
      launcher.updateCharging(50.0);

      // Then
      expect(launcher.launchPower, equals(50.0));
    });

    test(
        'given ready launcher, when power updated without charging, then power unchanged',
        () {
      // Given
      final launcher = BallLauncher();
      expect(launcher.phase, equals(LaunchPhase.ready));

      // When - try to update power without starting charging
      launcher.updateCharging(75.0);

      // Then - power should remain 0
      expect(launcher.launchPower, equals(0.0));
    });
  });

  group('Phase Transitions -', () {
    /// Tests phase state machine transitions.
    ///
    /// State machine flow:
    /// ready → charging (startCharging)
    /// charging → launching (launch) → traveling (automatic)
    /// traveling → released (on path completion)
    /// any → ready (reset)
    test(
        'given ready launcher, when startCharging called, then transitions to charging phase',
        () {
      // Given
      final launcher = BallLauncher();
      expect(launcher.phase, equals(LaunchPhase.ready));

      // When
      launcher.startCharging();

      // Then
      expect(launcher.phase, equals(LaunchPhase.charging));
    });

    test(
        'given charging launcher, when launch called, then transitions to traveling phase',
        () {
      // Given
      final launcher = BallLauncher();
      launcher.startCharging();
      launcher.updateCharging(50.0);

      // When
      final ball = launcher.launch();

      // Then
      expect(launcher.phase, equals(LaunchPhase.traveling));
      expect(ball, isNotNull);
    });

    test(
        'given ready launcher, when launch called without charging, then returns null',
        () {
      // Given
      final launcher = BallLauncher();
      expect(launcher.phase, equals(LaunchPhase.ready));

      // When
      final ball = launcher.launch();

      // Then
      expect(ball, isNull);
      expect(launcher.phase, equals(LaunchPhase.ready)); // Phase unchanged
    });

    test(
        'given traveling launcher, when path completes, then transitions to released phase',
        () {
      // Given
      final launcher = BallLauncher();
      launcher.startCharging();
      launcher.updateCharging(100.0);
      launcher.launch();
      expect(launcher.phase, equals(LaunchPhase.traveling));

      // When - simulate path completion with large deltaTime
      bool isReleased = false;
      for (int i = 0; i < 100; i++) {
        isReleased = launcher.updateBallPath(0.1);
        if (isReleased) break;
      }

      // Then
      expect(isReleased, isTrue);
      expect(launcher.phase, equals(LaunchPhase.released));
    });

    test(
        'given non-ready launcher, when startCharging called, then phase unchanged',
        () {
      // Given
      final launcher = BallLauncher();
      launcher.startCharging();
      expect(launcher.phase, equals(LaunchPhase.charging));

      // When - try to start charging again
      launcher.startCharging();

      // Then - should remain in charging
      expect(launcher.phase, equals(LaunchPhase.charging));
    });

    test('given any launcher, when reset called, then returns to ready phase',
        () {
      // Given
      final launcher = BallLauncher();
      launcher.startCharging();
      launcher.updateCharging(80.0);
      launcher.launch();

      // When
      launcher.reset();

      // Then
      expect(launcher.phase, equals(LaunchPhase.ready));
    });
  });

  group('Release -', () {
    /// At the top of the channel the ball is let go moving straight up, at a
    /// speed set by the launch power. Where it comes down is then a matter of
    /// how far that speed carries it along the dome.
    Ball released(double power, {double step = 1 / 60}) {
      final launcher = BallLauncher()
        ..startCharging()
        ..updateCharging(power);
      final ball = launcher.launch()!;
      for (int i = 0; i < 10000 && !launcher.updateBallPath(step); i++) {}
      expect(launcher.phase, LaunchPhase.released);
      return ball;
    }

    test(
        'given any power, when the ball is released, then it is at the top of the channel moving straight up',
        () {
      for (final power in [0.0, 37.0, 100.0]) {
        final ball = released(power);

        expect(ball.position.x, GameConstants.ballLaunchX,
            reason: 'power $power');
        expect(ball.position.y, GameConstants.launchChannelEndY,
            reason: 'power $power');
        expect(ball.velocity.x, 0.0, reason: 'power $power');
        expect(ball.velocity.y, lessThan(0), reason: 'power $power');
      }
    });

    test(
        'given no power, half power and full power, when released, then the speed runs from the least to the most in proportion',
        () {
      expect(released(0).velocity.length, GameConstants.launchSpeedMin);
      expect(released(100).velocity.length, GameConstants.launchSpeedMax);
      expect(
          released(50).velocity.length,
          closeTo(
              (GameConstants.launchSpeedMin + GameConstants.launchSpeedMax) / 2,
              0.001));
    });

    test(
        'given a ball in the channel, when it travels, then it moves at the speed it will be released with',
        () {
      final launcher = BallLauncher()
        ..startCharging()
        ..updateCharging(100);
      final ball = launcher.launch()!;
      launcher.updateBallPath(1 / 60);
      final before = ball.position.clone();

      launcher.updateBallPath(1 / 60);

      expect((ball.position - before).length * 60,
          closeTo(GameConstants.launchSpeedMax, 0.01));
    });

    test(
        'given the least launch speed, then it is enough to leave the channel, and the most is enough to ride the dome over its top',
        () {
      // The dome is close to a parabola 105 high over a half-width of 180. A
      // ball rides it while its sideways speed exceeds that of a projectile
      // following the same curve; it loses a little under a third of its
      // speed turning onto the dome, and height takes more on the way up
      const sag = GameConstants.topCurveStartY -
          (GameConstants.topCurveStartY + GameConstants.topCurveControlY) / 2;
      const halfWidth =
          (GameConstants.topCurveEndX - GameConstants.topCurveStartX) / 2;
      final rideSpeed =
          math.sqrt(GameConstants.gravity * halfWidth * halfWidth / (2 * sag));

      expect(
          GameConstants.launchSpeedMax * 0.72,
          greaterThan(math
              .sqrt(rideSpeed * rideSpeed + 2 * GameConstants.gravity * sag)));
      expect(GameConstants.launchSpeedMin, greaterThan(300));
      expect(GameConstants.launchSpeedMin, lessThan(rideSpeed));
    });
  });

  group('Ball Path Interpolation -', () {
    /// Tests ball position interpolation along launch path.
    ///
    /// Path progress tracking:
    /// - speed = 200 + (power/maxPower) * 300  // Range: 200-500 px/s
    /// - pathProgress += speed * deltaTime
    /// - Advance pathIndex every 20px of progress
    /// - Interpolate between current and next path segment
    test(
        'given traveling ball, when updateBallPath called, then ball position interpolates along path',
        () {
      // Given
      final launcher = BallLauncher();
      launcher.startCharging();
      launcher.updateCharging(50.0);
      launcher.launch();
      final initialPosition = launcher.currentBall!.position.clone();

      // When
      launcher.updateBallPath(0.1); // 0.1 second

      // Then - ball should have moved from initial position
      final newPosition = launcher.currentBall!.position;
      final distanceMoved = (newPosition - initialPosition).length;
      expect(distanceMoved, greaterThan(0));
    });

    test(
        'given traveling ball with high power, when updated, then moves faster than low power',
        () {
      // Given - high power launch
      final launcher1 = BallLauncher();
      launcher1.startCharging();
      launcher1.updateCharging(100.0);
      launcher1.launch();
      final initialPos1 = launcher1.currentBall!.position.clone();
      launcher1.updateBallPath(0.1);
      final highPowerDistance =
          (launcher1.currentBall!.position - initialPos1).length;

      // Given - low power launch
      final launcher2 = BallLauncher();
      launcher2.startCharging();
      launcher2.updateCharging(0.0);
      launcher2.launch();
      final initialPos2 = launcher2.currentBall!.position.clone();
      launcher2.updateBallPath(0.1);
      final lowPowerDistance =
          (launcher2.currentBall!.position - initialPos2).length;

      // Then
      expect(highPowerDistance, greaterThan(lowPowerDistance));
    });

    test(
        'given traveling ball, when path not complete, then updateBallPath returns false',
        () {
      // Given
      final launcher = BallLauncher();
      launcher.startCharging();
      launcher.updateCharging(50.0);
      launcher.launch();

      // When - single small update
      final isReleased = launcher.updateBallPath(0.01);

      // Then
      expect(isReleased, isFalse);
      expect(launcher.phase, equals(LaunchPhase.traveling));
    });

    test(
        'given traveling ball, when path completes, then updateBallPath returns true',
        () {
      // Given
      final launcher = BallLauncher();
      launcher.startCharging();
      launcher.updateCharging(100.0);
      launcher.launch();

      // When - complete entire path
      bool isReleased = false;
      for (int i = 0; i < 100; i++) {
        isReleased = launcher.updateBallPath(0.1);
        if (isReleased) break;
      }

      // Then
      expect(isReleased, isTrue);
      expect(launcher.phase, equals(LaunchPhase.released));
    });

    test('given released ball, when updateBallPath called, then returns false',
        () {
      // Given - ball already released
      final launcher = BallLauncher();
      launcher.startCharging();
      launcher.updateCharging(50.0);
      launcher.launch();
      for (int i = 0; i < 100; i++) {
        if (launcher.updateBallPath(0.1)) break;
      }
      expect(launcher.phase, equals(LaunchPhase.released));

      // When
      final result = launcher.updateBallPath(0.1);

      // Then
      expect(result, isFalse); // No longer tracking
    });

    test('given ready launcher, when updateBallPath called, then returns false',
        () {
      // Given
      final launcher = BallLauncher();
      expect(launcher.phase, equals(LaunchPhase.ready));

      // When
      final result = launcher.updateBallPath(0.1);

      // Then
      expect(result, isFalse);
    });
  });

  group('Launched Ball -', () {
    test('given a launch, then the ball takes the ball role colour', () {
      final launcher = BallLauncher();
      launcher.startCharging();

      final ball = launcher.launch();

      expect(ball!.color, GameConstants.ballColor);
    });
  });

  group('Reset Functionality -', () {
    test(
        'given launcher with power, when reset called, then power returns to zero',
        () {
      // Given
      final launcher = BallLauncher();
      launcher.startCharging();
      launcher.updateCharging(75.0);
      expect(launcher.launchPower, equals(75.0));

      // When
      launcher.reset();

      // Then
      expect(launcher.launchPower, equals(0.0));
    });

    test(
        'given launcher with ball, when reset called, then currentBall becomes null',
        () {
      // Given
      final launcher = BallLauncher();
      launcher.startCharging();
      launcher.updateCharging(50.0);
      launcher.launch();
      expect(launcher.currentBall, isNotNull);

      // When
      launcher.reset();

      // Then
      expect(launcher.currentBall, isNull);
    });

    test('given traveling ball, when reset called, then phase returns to ready',
        () {
      // Given
      final launcher = BallLauncher();
      launcher.startCharging();
      launcher.updateCharging(50.0);
      launcher.launch();
      launcher.updateBallPath(0.1);
      expect(launcher.phase, equals(LaunchPhase.traveling));

      // When
      launcher.reset();

      // Then
      expect(launcher.phase, equals(LaunchPhase.ready));
    });
  });
}
