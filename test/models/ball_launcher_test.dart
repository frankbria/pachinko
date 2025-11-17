import 'package:flutter_test/flutter_test.dart';
import 'package:pachinko_game/models/ball_launcher.dart';
import 'package:pachinko_game/utils/constants.dart';
import 'package:vector_math/vector_math_64.dart';
import 'dart:math' as math;

void main() {
  group('BallLauncher Initialization -', () {
    test('given new launcher, when created, then initializes in ready phase', () {
      // Given / When
      final launcher = BallLauncher();

      // Then
      expect(launcher.phase, equals(LaunchPhase.ready));
    });

    test('given new launcher, when created, then initializes with zero power', () {
      // Given / When
      final launcher = BallLauncher();

      // Then
      expect(launcher.launchPower, equals(0.0));
    });

    test('given new launcher, when created, then generates launch path automatically', () {
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
    /// Tests launch path structure and segment count.
    ///
    /// Path consists of 3 sections:
    /// - Straight path up channel: 21 points (pathSegments=20, i from 0 to 20)
    /// - Quarter-circle curve: 15 points (curveSegments=15, i from 1 to 15)
    /// - Entry point to peg field: 1 point
    /// Total: 37 points (21 + 15 + 1)
    test('given launcher, when path generated, then contains exactly 37 points', () {
      // Given
      final launcher = BallLauncher();

      // When
      final path = launcher.getLaunchPath();

      // Then
      expect(path.length, equals(37)); // 21 straight + 15 curve + 1 entry
    });

    test('given launcher, when path generated, then starts at bottom-right launch position', () {
      // Given
      final launcher = BallLauncher();

      // When
      final path = launcher.getLaunchPath();
      final startPoint = path.first;

      // Then
      expect(startPoint.x, equals(GameConstants.ballLaunchX));
      expect(startPoint.y, equals(GameConstants.ballLaunchY));
    });

    /// Tests path end point calculation.
    ///
    /// Final point is entry to peg field after quarter-circle curve.
    /// Position: (curveStartX - curveRadius, curveEndY - curveRadius)
    /// With curveRadius = 40px
    test('given launcher, when path generated, then ends at peg field entry point', () {
      // Given
      final launcher = BallLauncher();
      const curveRadius = 40.0;

      // When
      final path = launcher.getLaunchPath();
      final endPoint = path.last;

      // Then
      final expectedX = GameConstants.ballLaunchX - curveRadius;
      final expectedY = GameConstants.launchChannelEndY - curveRadius;
      expect(endPoint.x, closeTo(expectedX, 0.01));
      expect(endPoint.y, closeTo(expectedY, 0.01));
    });

    test('given launcher, when getLaunchPath called, then returns immutable copy', () {
      // Given
      final launcher = BallLauncher();

      // When
      final path1 = launcher.getLaunchPath();
      final path2 = launcher.getLaunchPath();

      // Then
      expect(path1, isNot(same(path2))); // Different list instances
      expect(path1.length, equals(path2.length)); // Same content
    });

    /// Tests vertical progression of straight path section.
    ///
    /// First 21 points should form straight vertical line from bottom to top.
    /// All x-coordinates should equal ballLaunchX (constant).
    /// Y-coordinates should decrease monotonically (moving upward).
    test('given launcher, when path generated, then first 21 points form straight vertical path', () {
      // Given
      final launcher = BallLauncher();

      // When
      final path = launcher.getLaunchPath();
      final straightPathPoints = path.sublist(0, 21);

      // Then - all x coordinates should be constant
      for (final point in straightPathPoints) {
        expect(point.x, equals(GameConstants.ballLaunchX));
      }

      // Then - y coordinates should decrease monotonically (moving up)
      for (int i = 0; i < straightPathPoints.length - 1; i++) {
        expect(straightPathPoints[i].y, greaterThan(straightPathPoints[i + 1].y));
      }
    });
  });

  group('Curve Mathematics Validation -', () {
    /// Tests quarter-circle curve geometry validation.
    ///
    /// Curve section (points 21-35, indices 21-35 inclusive, 15 points) forms quarter-circle:
    /// - Radius: 40px
    /// - Center: (ballLaunchX - 40, launchChannelEndY)
    /// - Angle range: 0 to π/2 radians (90 degrees)
    /// - Direction: right to left (x decreases), top to bottom (y decreases)
    ///
    /// Parametric formula:
    /// x = curveStartX - curveRadius * (1 - cos(angle))
    /// y = curveEndY - curveRadius * sin(angle)
    ///
    /// All curve points must satisfy circle equation:
    /// (x - cx)² + (y - cy)² = r²
    /// Tolerance: ±1.0px for floating-point precision
    test('given launcher, when path generated, then curve points satisfy circle equation', () {
      // Given
      final launcher = BallLauncher();
      const curveRadius = 40.0;
      final curveStartX = GameConstants.ballLaunchX;
      final curveEndY = GameConstants.launchChannelEndY;
      final centerX = curveStartX - curveRadius;
      final centerY = curveEndY;

      // When
      final path = launcher.getLaunchPath();
      final curvePoints = path.sublist(21, 36); // Points 21-35 (15 points)

      // Then - all curve points should satisfy circle equation: (x-cx)² + (y-cy)² = r²
      for (final point in curvePoints) {
        final dx = point.x - centerX;
        final dy = point.y - centerY;
        final distanceSquared = dx * dx + dy * dy;
        final radiusSquared = curveRadius * curveRadius;

        expect(distanceSquared, closeTo(radiusSquared, 1.0)); // ±1.0px tolerance
      }
    });

    /// Tests curve radius consistency.
    ///
    /// All curve points should be exactly 40px from curve center.
    /// This validates the parametric circle formula implementation.
    test('given launcher, when path generated, then all curve points are 40px from curve center', () {
      // Given
      final launcher = BallLauncher();
      const curveRadius = 40.0;
      final curveStartX = GameConstants.ballLaunchX;
      final curveEndY = GameConstants.launchChannelEndY;
      final centerX = curveStartX - curveRadius;
      final centerY = curveEndY;

      // When
      final path = launcher.getLaunchPath();
      final curvePoints = path.sublist(21, 36);

      // Then
      for (final point in curvePoints) {
        final distance = math.sqrt(
          math.pow(point.x - centerX, 2) + math.pow(point.y - centerY, 2)
        );
        expect(distance, closeTo(curveRadius, 0.5)); // ±0.5px tolerance
      }
    });

    /// Tests curve angle progression.
    ///
    /// Curve should progress through quarter-circle (π/2 radians = 90°).
    /// First curve point should start at small angle, last near 90° (pointing down).
    test('given launcher, when path generated, then curve spans quarter-circle angle', () {
      // Given
      final launcher = BallLauncher();
      const curveRadius = 40.0;
      final curveStartX = GameConstants.ballLaunchX;
      final curveEndY = GameConstants.launchChannelEndY;
      final centerX = curveStartX - curveRadius;
      final centerY = curveEndY;

      // When
      final path = launcher.getLaunchPath();
      final firstCurvePoint = path[21]; // First curve point
      final lastCurvePoint = path[35]; // Last curve point

      // Then - first point should be near 0° (small negative angle in screen coords)
      final firstAngle = math.atan2(
        firstCurvePoint.y - centerY,
        firstCurvePoint.x - centerX
      ).abs();
      expect(firstAngle, lessThan(0.3)); // Near 0 radians (small angle)

      // Then - last point should be near 90° (angle ≈ -π/2 due to screen coords)
      final lastAngle = math.atan2(
        lastCurvePoint.y - centerY,
        lastCurvePoint.x - centerX
      ).abs();
      expect(lastAngle, closeTo(math.pi / 2, 0.2)); // Near π/2 radians magnitude
    });

    /// Tests curve direction (right to left, top to bottom).
    ///
    /// X-coordinates should decrease (moving left).
    /// Y-coordinates should decrease (moving down, as y-axis increases downward).
    test('given launcher, when path generated, then curve moves right-to-left and top-to-bottom', () {
      // Given
      final launcher = BallLauncher();

      // When
      final path = launcher.getLaunchPath();
      final curvePoints = path.sublist(21, 36);

      // Then - x should decrease (moving left)
      final firstX = curvePoints.first.x;
      final lastX = curvePoints.last.x;
      expect(lastX, lessThan(firstX));

      // Then - y should decrease (moving down/toward more negative)
      final firstY = curvePoints.first.y;
      final lastY = curvePoints.last.y;
      expect(lastY, lessThan(firstY));
    });

    /// Tests curve smoothness by checking segment spacing.
    ///
    /// Consecutive curve points should be roughly equidistant.
    /// This validates uniform angle distribution across curve.
    test('given launcher, when path generated, then curve segments have roughly uniform spacing', () {
      // Given
      final launcher = BallLauncher();

      // When
      final path = launcher.getLaunchPath();
      final curvePoints = path.sublist(21, 36);

      // Calculate distances between consecutive curve points
      final distances = <double>[];
      for (int i = 0; i < curvePoints.length - 1; i++) {
        final distance = (curvePoints[i] - curvePoints[i + 1]).length;
        distances.add(distance);
      }

      // Then - calculate mean and check all distances are within 50% of mean
      final meanDistance = distances.reduce((a, b) => a + b) / distances.length;
      for (final distance in distances) {
        expect(distance, closeTo(meanDistance, meanDistance * 0.5));
      }
    });

    /// Tests curve connection to straight path.
    ///
    /// Point at index 20 (last straight path point) should be near point at index 21 (first curve point).
    /// This validates smooth transition from straight path to curve.
    test('given launcher, when path generated, then straight path connects smoothly to curve', () {
      // Given
      final launcher = BallLauncher();

      // When
      final path = launcher.getLaunchPath();
      final lastStraightPoint = path[20];
      final firstCurvePoint = path[21];

      // Then - points should be close (smooth transition)
      final distance = (lastStraightPoint - firstCurvePoint).length;
      expect(distance, lessThan(20.0)); // Should be reasonable segment length
    });
  });

  group('Power Calculation -', () {
    test('given charging launcher, when power updated, then stays within 0-100 range', () {
      // Given
      final launcher = BallLauncher();
      launcher.startCharging();

      // When - try to set power beyond max
      launcher.updateCharging(150.0);

      // Then - should be clamped to maxPower
      expect(launcher.launchPower, equals(100.0));
    });

    test('given charging launcher, when negative power set, then clamps to 0', () {
      // Given
      final launcher = BallLauncher();
      launcher.startCharging();

      // When
      launcher.updateCharging(-50.0);

      // Then
      expect(launcher.launchPower, equals(0.0));
    });

    test('given charging launcher, when power updated multiple times, then uses latest value', () {
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

    test('given ready launcher, when power updated without charging, then power unchanged', () {
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
    test('given ready launcher, when startCharging called, then transitions to charging phase', () {
      // Given
      final launcher = BallLauncher();
      expect(launcher.phase, equals(LaunchPhase.ready));

      // When
      launcher.startCharging();

      // Then
      expect(launcher.phase, equals(LaunchPhase.charging));
    });

    test('given charging launcher, when launch called, then transitions to traveling phase', () {
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

    test('given ready launcher, when launch called without charging, then returns null', () {
      // Given
      final launcher = BallLauncher();
      expect(launcher.phase, equals(LaunchPhase.ready));

      // When
      final ball = launcher.launch();

      // Then
      expect(ball, isNull);
      expect(launcher.phase, equals(LaunchPhase.ready)); // Phase unchanged
    });

    test('given traveling launcher, when path completes, then transitions to released phase', () {
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

    test('given non-ready launcher, when startCharging called, then phase unchanged', () {
      // Given
      final launcher = BallLauncher();
      launcher.startCharging();
      expect(launcher.phase, equals(LaunchPhase.charging));

      // When - try to start charging again
      launcher.startCharging();

      // Then - should remain in charging
      expect(launcher.phase, equals(LaunchPhase.charging));
    });

    test('given any launcher, when reset called, then returns to ready phase', () {
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

  group('Release Velocity Calculation -', () {
    /// Tests release velocity calculation formula.
    ///
    /// Formula:
    /// powerMultiplier = 0.3 + (power / maxPower) * 0.7  // Range: 0.3 to 1.0
    /// horizontalSpread = (power / maxPower - 0.5) * 100  // Range: -50 to +50
    /// baseVelocity = Vector2(horizontalSpread, 150)
    /// finalVelocity = baseVelocity * powerMultiplier
    test('given zero power launch, when ball released, then uses minimum velocity multiplier 0.3', () {
      // Given
      final launcher = BallLauncher();
      launcher.startCharging();
      launcher.updateCharging(0.0);
      launcher.launch();

      // When - complete path to trigger release
      bool isReleased = false;
      for (int i = 0; i < 100; i++) {
        isReleased = launcher.updateBallPath(0.1);
        if (isReleased) break;
      }

      // Then
      expect(isReleased, isTrue);
      final ball = launcher.currentBall;
      expect(ball, isNotNull);

      // Velocity should be baseVelocity * 0.3
      // horizontalSpread = (0/100 - 0.5) * 100 = -50
      // baseVelocity = Vector2(-50, 150)
      // finalVelocity = Vector2(-50, 150) * 0.3 = Vector2(-15, 45)
      expect(ball!.velocity.x, closeTo(-15.0, 0.1));
      expect(ball.velocity.y, closeTo(45.0, 0.1));
    });

    test('given full power launch, when ball released, then uses maximum velocity multiplier 1.0', () {
      // Given
      final launcher = BallLauncher();
      launcher.startCharging();
      launcher.updateCharging(100.0);
      launcher.launch();

      // When
      bool isReleased = false;
      for (int i = 0; i < 100; i++) {
        isReleased = launcher.updateBallPath(0.1);
        if (isReleased) break;
      }

      // Then
      expect(isReleased, isTrue);
      final ball = launcher.currentBall;
      expect(ball, isNotNull);

      // Velocity should be baseVelocity * 1.0
      // horizontalSpread = (100/100 - 0.5) * 100 = 50
      // baseVelocity = Vector2(50, 150)
      // finalVelocity = Vector2(50, 150) * 1.0 = Vector2(50, 150)
      expect(ball!.velocity.x, closeTo(50.0, 0.1));
      expect(ball.velocity.y, closeTo(150.0, 0.1));
    });

    test('given mid power launch, when ball released, then horizontal spread is zero', () {
      // Given
      final launcher = BallLauncher();
      launcher.startCharging();
      launcher.updateCharging(50.0);
      launcher.launch();

      // When
      bool isReleased = false;
      for (int i = 0; i < 100; i++) {
        isReleased = launcher.updateBallPath(0.1);
        if (isReleased) break;
      }

      // Then
      final ball = launcher.currentBall;
      expect(ball, isNotNull);

      // horizontalSpread = (50/100 - 0.5) * 100 = 0
      // powerMultiplier = 0.3 + 0.5 * 0.7 = 0.65
      // finalVelocity.x = 0 * 0.65 = 0
      expect(ball!.velocity.x, closeTo(0.0, 0.1));
    });

    test('given different power levels, when ball released, then velocity magnitude increases with power', () {
      // Given - launch with low power
      final launcher1 = BallLauncher();
      launcher1.startCharging();
      launcher1.updateCharging(25.0);
      launcher1.launch();
      for (int i = 0; i < 100; i++) {
        if (launcher1.updateBallPath(0.1)) break;
      }
      final lowPowerVelocity = launcher1.currentBall!.velocity.length;

      // Given - launch with high power
      final launcher2 = BallLauncher();
      launcher2.startCharging();
      launcher2.updateCharging(75.0);
      launcher2.launch();
      for (int i = 0; i < 100; i++) {
        if (launcher2.updateBallPath(0.1)) break;
      }
      final highPowerVelocity = launcher2.currentBall!.velocity.length;

      // Then - higher power should result in higher velocity magnitude
      expect(highPowerVelocity, greaterThan(lowPowerVelocity));
    });

    test('given low power, when ball released, then horizontal velocity is negative', () {
      // Given
      final launcher = BallLauncher();
      launcher.startCharging();
      launcher.updateCharging(25.0); // Below 50, so horizontal should be negative

      launcher.launch();

      // When
      for (int i = 0; i < 100; i++) {
        if (launcher.updateBallPath(0.1)) break;
      }

      // Then
      final ball = launcher.currentBall;
      expect(ball, isNotNull);
      expect(ball!.velocity.x, lessThan(0)); // Negative horizontal spread
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
    test('given traveling ball, when updateBallPath called, then ball position interpolates along path', () {
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

    test('given traveling ball with high power, when updated, then moves faster than low power', () {
      // Given - high power launch
      final launcher1 = BallLauncher();
      launcher1.startCharging();
      launcher1.updateCharging(100.0);
      launcher1.launch();
      final initialPos1 = launcher1.currentBall!.position.clone();
      launcher1.updateBallPath(0.1);
      final highPowerDistance = (launcher1.currentBall!.position - initialPos1).length;

      // Given - low power launch
      final launcher2 = BallLauncher();
      launcher2.startCharging();
      launcher2.updateCharging(0.0);
      launcher2.launch();
      final initialPos2 = launcher2.currentBall!.position.clone();
      launcher2.updateBallPath(0.1);
      final lowPowerDistance = (launcher2.currentBall!.position - initialPos2).length;

      // Then
      expect(highPowerDistance, greaterThan(lowPowerDistance));
    });

    test('given traveling ball, when path not complete, then updateBallPath returns false', () {
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

    test('given traveling ball, when path completes, then updateBallPath returns true', () {
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

    test('given released ball, when updateBallPath called, then returns false', () {
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

    test('given ready launcher, when updateBallPath called, then returns false', () {
      // Given
      final launcher = BallLauncher();
      expect(launcher.phase, equals(LaunchPhase.ready));

      // When
      final result = launcher.updateBallPath(0.1);

      // Then
      expect(result, isFalse);
    });
  });

  group('Reset Functionality -', () {
    test('given launcher with power, when reset called, then power returns to zero', () {
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

    test('given launcher with ball, when reset called, then currentBall becomes null', () {
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

    test('given traveling ball, when reset called, then phase returns to ready', () {
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
