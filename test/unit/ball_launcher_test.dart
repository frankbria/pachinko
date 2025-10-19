import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:pachinko_game/models/ball_launcher.dart';
import 'package:pachinko_game/models/ball.dart';
import 'package:pachinko_game/utils/constants.dart';

void main() {
  group('BallLauncher - Velocity Transition Fix', () {
    late BallLauncher launcher;

    setUp(() {
      launcher = BallLauncher();
    });

    group('Release Velocity Calculation', () {
      test('release velocity should be tangent to final path segment', () {
        // Setup: Launch ball with 50% power
        launcher.startCharging();
        launcher.updateCharging(50.0);
        final ball = launcher.launch();

        expect(ball, isNotNull);

        // Simulate ball traveling through entire path
        const deltaTime = 1.0 / 60.0; // 60 FPS
        bool released = false;
        int maxIterations = 1000; // Safety limit
        int iterations = 0;

        while (!released && iterations < maxIterations) {
          released = launcher.updateBallPath(deltaTime);
          iterations++;
        }

        expect(released, true, reason: 'Ball should be released from path');
        expect(launcher.phase, LaunchPhase.released);

        // Get the final two points of the launch path to calculate expected tangent
        final launchPath = launcher.getLaunchPath();
        expect(launchPath.length, greaterThan(1));

        final secondToLast = launchPath[launchPath.length - 2];
        final last = launchPath[launchPath.length - 1];

        // Calculate expected tangent direction (normalized)
        final pathDirection = last - secondToLast;
        final expectedDirection = pathDirection.normalized();

        // Get actual release velocity
        final actualVelocity = ball!.velocity;
        final actualDirection = actualVelocity.normalized();

        // Verify velocity direction matches path tangent
        // Allow tolerance for curved path geometry and discrete sampling
        const tolerance = 0.10; // 10% tolerance for direction matching
        expect(
          (actualDirection - expectedDirection).length,
          lessThan(tolerance),
          reason:
              'Release velocity direction should match final path segment tangent\n'
              'Expected direction: (${expectedDirection.x.toStringAsFixed(3)}, ${expectedDirection.y.toStringAsFixed(3)})\n'
              'Actual direction: (${actualDirection.x.toStringAsFixed(3)}, ${actualDirection.y.toStringAsFixed(3)})\n'
              'Difference: ${(actualDirection - expectedDirection).length.toStringAsFixed(3)}',
        );
      });

      test('velocity transition should be smooth at various power levels', () {
        final powerLevels = [0.0, 25.0, 50.0, 75.0, 100.0];
        final results = <Map<String, dynamic>>[];

        for (final power in powerLevels) {
          launcher.reset();
          launcher.startCharging();
          launcher.updateCharging(power);
          final ball = launcher.launch();

          expect(ball, isNotNull);

          // Travel to release point
          const deltaTime = 1.0 / 60.0;
          bool released = false;
          int maxIterations = 1000;
          int iterations = 0;

          while (!released && iterations < maxIterations) {
            released = launcher.updateBallPath(deltaTime);
            iterations++;
          }

          expect(released, true);

          // Store results for analysis
          final velocity = ball!.velocity;
          final launchPath = launcher.getLaunchPath();
          final secondToLast = launchPath[launchPath.length - 2];
          final last = launchPath[launchPath.length - 1];
          final pathTangent = (last - secondToLast).normalized();

          results.add({
            'power': power,
            'velocity': velocity,
            'velocityMagnitude': velocity.length,
            'velocityDirection': velocity.normalized(),
            'pathTangent': pathTangent,
            'directionError': (velocity.normalized() - pathTangent).length,
          });
        }

        // Verify velocity magnitude scales with power
        for (int i = 1; i < results.length; i++) {
          final prev = results[i - 1];
          final curr = results[i];

          // Higher power should produce higher velocity magnitude
          expect(
            curr['velocityMagnitude'] as double,
            greaterThanOrEqualTo(prev['velocityMagnitude'] as double),
            reason:
                'Velocity magnitude at ${curr['power']}% power (${curr['velocityMagnitude']}) '
                'should be >= velocity at ${prev['power']}% power (${prev['velocityMagnitude']})',
          );
        }

        // Verify all directions remain tangent to path regardless of power
        const directionTolerance = 0.20; // 20% tolerance for curved path geometry at high speeds
        for (final result in results) {
          final power = result['power'] as double;
          final error = result['directionError'] as double;
          final velocityDir = result['velocityDirection'] as Vector2;
          final pathTangent = result['pathTangent'] as Vector2;

          expect(
            error,
            lessThan(directionTolerance),
            reason: 'At ${power}% power, velocity direction should match path tangent\n'
                'Path tangent: (${pathTangent.x.toStringAsFixed(3)}, ${pathTangent.y.toStringAsFixed(3)})\n'
                'Velocity dir: (${velocityDir.x.toStringAsFixed(3)}, ${velocityDir.y.toStringAsFixed(3)})\n'
                'Error: ${error.toStringAsFixed(3)}',
          );
        }
      });

      test('velocity should have no discontinuity at release point', () {
        // Test for velocity "snap" by checking velocity doesn't change abruptly
        launcher.startCharging();
        launcher.updateCharging(75.0);
        final ball = launcher.launch();

        expect(ball, isNotNull);

        const deltaTime = 1.0 / 60.0;
        bool released = false;
        int maxIterations = 1000;
        int iterations = 0;

        // Track position over last few frames before release
        final positions = <Vector2>[];
        final velocities = <Vector2>[];

        while (!released && iterations < maxIterations) {
          // Store current position
          positions.add(ball!.position.clone());

          // Calculate approximate velocity from position changes
          if (positions.length > 1) {
            final implicitVelocity =
                (positions.last - positions[positions.length - 2]) /
                    deltaTime;
            velocities.add(implicitVelocity);
          }

          released = launcher.updateBallPath(deltaTime);
          iterations++;
        }

        expect(released, true);
        expect(velocities.length, greaterThan(5),
            reason: 'Need multiple velocity samples');

        // Get the velocity calculated during guided path (last few frames)
        final preReleaseVelocities =
            velocities.sublist(math.max(0, velocities.length - 5));

        // Get the actual release velocity set by the launcher
        final releaseVelocity = ball!.velocity;

        // Calculate average pre-release velocity
        var avgPreReleaseVelocity = Vector2.zero();
        for (final v in preReleaseVelocities) {
          avgPreReleaseVelocity += v;
        }
        avgPreReleaseVelocity.scale(1.0 / preReleaseVelocities.length);

        // Verify release velocity is similar to the velocity during guided path
        // This ensures no "snap" occurs
        final velocityChange = (releaseVelocity - avgPreReleaseVelocity).length;
        final avgSpeed = avgPreReleaseVelocity.length;

        // Allow up to 50% velocity change (reasonable tolerance for curved paths)
        // This accounts for measurement noise from averaging discrete samples
        // Without the fix, this would be 700%+ (massive snap)
        const maxChangeRatio = 0.50;
        final changeRatio = velocityChange / avgSpeed;

        expect(
          changeRatio,
          lessThan(maxChangeRatio),
          reason: 'Velocity change at release should be smooth, not abrupt\n'
              'Pre-release velocity: (${avgPreReleaseVelocity.x.toStringAsFixed(1)}, ${avgPreReleaseVelocity.y.toStringAsFixed(1)})\n'
              'Release velocity: (${releaseVelocity.x.toStringAsFixed(1)}, ${releaseVelocity.y.toStringAsFixed(1)})\n'
              'Change magnitude: ${velocityChange.toStringAsFixed(1)}\n'
              'Change ratio: ${(changeRatio * 100).toStringAsFixed(1)}% (max allowed: ${(maxChangeRatio * 100).toStringAsFixed(0)}%)',
        );
      });

      test('velocity magnitude should scale appropriately with power', () {
        final testCases = [
          {'power': 0.0, 'minSpeed': 150.0, 'maxSpeed': 300.0},
          {'power': 50.0, 'minSpeed': 250.0, 'maxSpeed': 450.0},
          {'power': 100.0, 'minSpeed': 350.0, 'maxSpeed': 600.0},
        ];

        for (final testCase in testCases) {
          launcher.reset();
          launcher.startCharging();
          launcher.updateCharging(testCase['power'] as double);
          final ball = launcher.launch();

          // Travel to release
          const deltaTime = 1.0 / 60.0;
          bool released = false;
          int maxIterations = 1000;
          int iterations = 0;

          while (!released && iterations < maxIterations) {
            released = launcher.updateBallPath(deltaTime);
            iterations++;
          }

          expect(released, true);

          final speed = ball!.velocity.length;
          expect(
            speed,
            greaterThanOrEqualTo(testCase['minSpeed'] as double),
            reason:
                'At ${testCase['power']}% power, speed should be >= ${testCase['minSpeed']}',
          );
          expect(
            speed,
            lessThanOrEqualTo(testCase['maxSpeed'] as double),
            reason:
                'At ${testCase['power']}% power, speed should be <= ${testCase['maxSpeed']}',
          );
        }
      });
    });

    group('Path Geometry Validation', () {
      test('launch path should have correct structure', () {
        final path = launcher.getLaunchPath();

        // Path should have multiple segments
        expect(path.length, greaterThan(20));

        // Path should start at launch position
        expect(path.first.x, closeTo(GameConstants.ballLaunchX, 0.1));
        expect(path.first.y, closeTo(GameConstants.ballLaunchY, 0.1));

        // Path should have vertical segment (going up)
        bool hasVerticalSegment = false;
        for (int i = 1; i < path.length; i++) {
          if ((path[i].x - path[i - 1].x).abs() < 1.0 &&
              path[i].y < path[i - 1].y) {
            hasVerticalSegment = true;
            break;
          }
        }
        expect(hasVerticalSegment, true,
            reason: 'Path should have vertical upward segment');

        // Path should have curved segment (changing X and Y)
        bool hasCurvedSegment = false;
        for (int i = 1; i < path.length; i++) {
          if ((path[i].x - path[i - 1].x).abs() > 1.0 &&
              (path[i].y - path[i - 1].y).abs() > 0.1) {
            hasCurvedSegment = true;
            break;
          }
        }
        expect(hasCurvedSegment, true,
            reason: 'Path should have curved segment');

        // Final segment should point into the peg field
        final finalSegment = path.last - path[path.length - 2];
        expect(finalSegment.x, lessThan(0),
            reason: 'Final segment should point left (into peg field)');
      });

      test('final path segment should determine release direction', () {
        final path = launcher.getLaunchPath();
        final secondToLast = path[path.length - 2];
        final last = path[path.length - 1];
        final finalSegment = last - secondToLast;

        // The final segment defines the expected release direction
        // This is what the ball's velocity should be tangent to
        final expectedDirection = finalSegment.normalized();

        // Verify this direction makes sense for pachinko gameplay
        expect(expectedDirection.x, lessThan(0),
            reason: 'Ball should enter peg field moving left');

        // Direction can be slightly upward, downward, or horizontal
        // depending on the curve design, so we just verify it's reasonable
        expect(expectedDirection.length, closeTo(1.0, 0.01),
            reason: 'Direction should be normalized');
      });
    });

    group('Integration with Ball Physics', () {
      test('released ball should continue in path-tangent direction', () {
        launcher.startCharging();
        launcher.updateCharging(60.0);
        final ball = launcher.launch();

        // Travel to release
        const deltaTime = 1.0 / 60.0;
        bool released = false;
        while (!released) {
          released = launcher.updateBallPath(deltaTime);
        }

        // Get release velocity
        final releaseVelocity = ball!.velocity.clone();
        final releasePosition = ball.position.clone();

        // Simulate one physics frame
        ball.update(deltaTime);

        // Calculate actual movement direction
        final actualMovement = ball.position - releasePosition;
        final actualDirection = actualMovement.normalized();

        // This should match the release velocity direction
        // (before gravity significantly affects it)
        final velocityDirection = releaseVelocity.normalized();

        // Allow small deviation due to gravity during one frame
        const tolerance = 0.1;
        expect(
          (actualDirection - velocityDirection).length,
          lessThan(tolerance),
          reason: 'Ball should continue in release velocity direction\n'
              'Release velocity dir: (${velocityDirection.x.toStringAsFixed(3)}, ${velocityDirection.y.toStringAsFixed(3)})\n'
              'Actual movement dir: (${actualDirection.x.toStringAsFixed(3)}, ${actualDirection.y.toStringAsFixed(3)})',
        );
      });
    });

    group('Edge Cases', () {
      test('should handle zero power launch', () {
        launcher.startCharging();
        launcher.updateCharging(0.0);
        final ball = launcher.launch();

        const deltaTime = 1.0 / 60.0;
        bool released = false;
        int maxIterations = 1000;
        int iterations = 0;

        while (!released && iterations < maxIterations) {
          released = launcher.updateBallPath(deltaTime);
          iterations++;
        }

        expect(released, true);
        expect(ball!.velocity.length, greaterThan(0),
            reason: 'Even at 0 power, ball should have some velocity');
      });

      test('should handle maximum power launch', () {
        launcher.startCharging();
        launcher.updateCharging(100.0);
        final ball = launcher.launch();

        const deltaTime = 1.0 / 60.0;
        bool released = false;
        int maxIterations = 1000;
        int iterations = 0;

        while (!released && iterations < maxIterations) {
          released = launcher.updateBallPath(deltaTime);
          iterations++;
        }

        expect(released, true);
        expect(ball!.velocity.length, greaterThan(0));

        // At max power, velocity should be substantial
        expect(ball.velocity.length, greaterThan(300.0),
            reason: 'Max power should produce strong velocity');
      });

      test('should handle rapid power changes', () {
        launcher.startCharging();
        launcher.updateCharging(25.0);
        launcher.updateCharging(75.0);
        launcher.updateCharging(50.0);
        final ball = launcher.launch();

        expect(ball, isNotNull);
        expect(launcher.launchPower, closeTo(50.0, 0.1));
      });
    });
  });
}
