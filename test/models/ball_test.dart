// Unit tests for Ball model
//
// This test suite validates all Ball model functionality including:
// - Initialization and default values
// - Physics simulation (gravity, velocity, position updates)
// - Impulse application
// - State reset
// - Bounds detection
//
// Tests follow Given-When-Then naming pattern for clarity:
// - Given: Initial state/context
// - When: Action performed
// - Then: Expected outcome

import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:pachinko_game/models/ball.dart';

void main() {
  group('Ball Initialization -', () {
    test('given a position, when ball is created, then it initializes with correct defaults', () {
      // Given
      final position = Vector2(100, 200);

      // When
      final ball = Ball(position: position);

      // Then
      expect(ball.position, equals(position));
      expect(ball.velocity, equals(Vector2.zero()));
      expect(ball.acceleration, equals(Vector2.zero()));
      expect(ball.radius, equals(8.0));
      expect(ball.isActive, isTrue);
      expect(ball.hasLanded, isFalse);
    });

    test('given custom parameters, when ball is created, then it uses provided values', () {
      // Given
      final position = Vector2(150, 250);
      final velocity = Vector2(10, 20);
      final acceleration = Vector2(5, 15);
      const customRadius = 12.0;

      // When
      final ball = Ball(
        position: position,
        velocity: velocity,
        acceleration: acceleration,
        radius: customRadius,
        isActive: false,
        hasLanded: true,
      );

      // Then
      expect(ball.position, equals(position));
      expect(ball.velocity, equals(velocity));
      expect(ball.acceleration, equals(acceleration));
      expect(ball.radius, equals(customRadius));
      expect(ball.isActive, isFalse);
      expect(ball.hasLanded, isTrue);
    });

    test('given no velocity, when ball is created, then velocity defaults to zero', () {
      // Given
      final position = Vector2(50, 75);

      // When
      final ball = Ball(position: position);

      // Then
      expect(ball.velocity.x, equals(0.0));
      expect(ball.velocity.y, equals(0.0));
    });

    test('given no acceleration, when ball is created, then acceleration defaults to zero', () {
      // Given
      final position = Vector2(50, 75);

      // When
      final ball = Ball(position: position);

      // Then
      expect(ball.acceleration.x, equals(0.0));
      expect(ball.acceleration.y, equals(0.0));
    });
  });

  group('Ball Physics Update -', () {
    test('given a ball at rest, when update is called, then gravity is applied to acceleration', () {
      // Given
      final ball = Ball(position: Vector2(100, 100));
      const deltaTime = 0.016; // ~60 FPS

      // When
      ball.update(deltaTime);

      // Then
      expect(ball.acceleration.x, equals(0.0));
      expect(ball.acceleration.y, equals(980.0)); // Gravity constant
    });

    /// Verifies that velocity integration follows the physics formula: v' = v + a*dt
    ///
    /// This test validates the core physics simulation where acceleration is integrated
    /// into velocity over a time step. The expected calculation is:
    /// - Initial velocity: (0, 0)
    /// - Gravity applied: a = (0, 980) pixels/s²
    /// - Time step: dt = 0.016s (60 FPS)
    /// - Raw velocity change: Δv = a*dt = 980 * 0.016 = 15.68
    /// - After air resistance: v = 15.68 * 0.999 ≈ 15.664
    test('given a ball with acceleration, when update is called, then velocity increases by acceleration * deltaTime', () {
      // Given
      final ball = Ball(position: Vector2(100, 100));
      const deltaTime = 0.016;

      // When
      ball.update(deltaTime); // Applies gravity (980 m/s²)

      // Then
      // velocity.y should increase by gravity * deltaTime = 980 * 0.016 = 15.68
      // But also scaled by air resistance (0.999), so approximately 15.664
      expect(ball.velocity.y, closeTo(15.664, 0.01));
    });

    /// Verifies position integration using Euler method: p' = p + v*dt
    ///
    /// This test validates the position update in the physics simulation.
    /// The position update occurs after velocity has been modified by both
    /// acceleration and air resistance, demonstrating the complete physics pipeline:
    /// 1. Acceleration applied to velocity
    /// 2. Position updated by current velocity
    /// 3. Air resistance applied to velocity
    test('given a ball with velocity, when update is called, then position updates by velocity * deltaTime', () {
      // Given
      final ball = Ball(
        position: Vector2(100, 100),
        velocity: Vector2(50, 100), // Initial velocity
      );
      const deltaTime = 0.016;
      final initialPosX = ball.position.x;
      final initialPosY = ball.position.y;

      // When
      ball.update(deltaTime);

      // Then
      // Position should change by velocity * deltaTime (approximately)
      // X: 100 + (50 * 0.999 * 0.016) ≈ 100.8
      // Y: 100 + ((100 + 980*0.016) * 0.999 * 0.016) ≈ 101.85
      expect(ball.position.x, greaterThan(initialPosX));
      expect(ball.position.y, greaterThan(initialPosY));
    });

    /// Verifies air resistance damping factor applied to velocity
    ///
    /// Air resistance is simulated by scaling velocity by 0.999 each frame,
    /// creating a gradual deceleration effect. This prevents balls from
    /// maintaining infinite horizontal velocity and adds realistic physics.
    /// The damping factor of 0.999 means velocity decreases by 0.1% per frame.
    test('given a ball with velocity, when update is called, then air resistance reduces velocity', () {
      // Given
      final ball = Ball(
        position: Vector2(100, 100),
        velocity: Vector2(100, 0), // Horizontal velocity only
      );
      const deltaTime = 0.016;

      // When
      ball.update(deltaTime);

      // Then
      // Velocity should be scaled by 0.999 (plus gravity on y)
      // X velocity: 100 * 0.999 = 99.9
      expect(ball.velocity.x, closeTo(99.9, 0.1));
    });

    /// Edge case: Verifies physics simulation is blocked for inactive balls
    ///
    /// When isActive=false, the ball should remain frozen in place regardless
    /// of its velocity or elapsed time. This allows the game to pause specific
    /// balls without affecting others in the simulation.
    test('given an inactive ball, when update is called, then physics is not applied', () {
      // Given
      final ball = Ball(
        position: Vector2(100, 100),
        velocity: Vector2(50, 50),
        isActive: false,
      );
      final initialPosition = ball.position.clone();
      final initialVelocity = ball.velocity.clone();
      const deltaTime = 0.016;

      // When
      ball.update(deltaTime);

      // Then
      expect(ball.position, equals(initialPosition));
      expect(ball.velocity, equals(initialVelocity));
      expect(ball.acceleration.y, equals(0.0)); // Gravity not applied
    });

    /// Edge case: Verifies physics simulation is blocked for landed balls
    ///
    /// When hasLanded=true, the ball should stop simulating physics to represent
    /// it coming to rest in a scoring slot. This prevents continued movement after
    /// the ball has reached its final destination.
    test('given a landed ball, when update is called, then physics is not applied', () {
      // Given
      final ball = Ball(
        position: Vector2(100, 100),
        velocity: Vector2(50, 50),
        hasLanded: true,
      );
      final initialPosition = ball.position.clone();
      final initialVelocity = ball.velocity.clone();
      const deltaTime = 0.016;

      // When
      ball.update(deltaTime);

      // Then
      expect(ball.position, equals(initialPosition));
      expect(ball.velocity, equals(initialVelocity));
      expect(ball.acceleration.y, equals(0.0)); // Gravity not applied
    });
  });

  group('Ball Impulse Application -', () {
    test('given a ball at rest, when impulse is applied, then velocity changes by impulse amount', () {
      // Given
      final ball = Ball(position: Vector2(100, 100));
      final impulse = Vector2(50, -30);

      // When
      ball.applyImpulse(impulse);

      // Then
      expect(ball.velocity.x, equals(50.0));
      expect(ball.velocity.y, equals(-30.0));
    });

    test('given a ball with velocity, when impulse is applied, then velocities are added together', () {
      // Given
      final ball = Ball(
        position: Vector2(100, 100),
        velocity: Vector2(20, 10),
      );
      final impulse = Vector2(30, 40);

      // When
      ball.applyImpulse(impulse);

      // Then
      expect(ball.velocity.x, equals(50.0)); // 20 + 30
      expect(ball.velocity.y, equals(50.0)); // 10 + 40
    });

    test('given a negative impulse, when applied, then velocity decreases', () {
      // Given
      final ball = Ball(
        position: Vector2(100, 100),
        velocity: Vector2(100, 50),
      );
      final impulse = Vector2(-30, -20);

      // When
      ball.applyImpulse(impulse);

      // Then
      expect(ball.velocity.x, equals(70.0)); // 100 - 30
      expect(ball.velocity.y, equals(30.0)); // 50 - 20
    });
  });

  group('Ball Reset -', () {
    /// Verifies position cloning prevents shared reference bugs
    ///
    /// The reset method must clone the new position vector to prevent
    /// unintended side effects. If the same reference were used, external
    /// modifications to the position vector would affect the ball's state.
    test('given a moving ball, when reset is called, then position updates to new position', () {
      // Given
      final ball = Ball(
        position: Vector2(100, 100),
        velocity: Vector2(50, 50),
      );
      final newPosition = Vector2(200, 300);

      // When
      ball.reset(newPosition);

      // Then
      expect(ball.position.x, equals(200.0));
      expect(ball.position.y, equals(300.0));
      // Verify it's a clone, not the same reference
      expect(ball.position, isNot(same(newPosition)));
    });

    test('given a moving ball, when reset is called, then velocity resets to zero', () {
      // Given
      final ball = Ball(
        position: Vector2(100, 100),
        velocity: Vector2(75, 85),
      );
      final newPosition = Vector2(200, 300);

      // When
      ball.reset(newPosition);

      // Then
      expect(ball.velocity.x, equals(0.0));
      expect(ball.velocity.y, equals(0.0));
    });

    test('given a moving ball, when reset is called, then acceleration resets to zero', () {
      // Given
      final ball = Ball(
        position: Vector2(100, 100),
        acceleration: Vector2(10, 20),
      );
      final newPosition = Vector2(200, 300);

      // When
      ball.reset(newPosition);

      // Then
      expect(ball.acceleration.x, equals(0.0));
      expect(ball.acceleration.y, equals(0.0));
    });

    test('given an inactive ball, when reset is called, then isActive becomes true', () {
      // Given
      final ball = Ball(
        position: Vector2(100, 100),
        isActive: false,
      );
      final newPosition = Vector2(200, 300);

      // When
      ball.reset(newPosition);

      // Then
      expect(ball.isActive, isTrue);
    });

    test('given a landed ball, when reset is called, then hasLanded becomes false', () {
      // Given
      final ball = Ball(
        position: Vector2(100, 100),
        hasLanded: true,
      );
      final newPosition = Vector2(200, 300);

      // When
      ball.reset(newPosition);

      // Then
      expect(ball.hasLanded, isFalse);
    });
  });

  group('Ball Bounds Detection -', () {
    test('given a ball above bounds threshold, when isOutOfBounds checked, then returns false', () {
      // Given
      final ball = Ball(position: Vector2(100, 500)); // y = 500, threshold = 1000

      // When
      final result = ball.isOutOfBounds;

      // Then
      expect(result, isFalse);
    });

    test('given a ball below bounds threshold, when isOutOfBounds checked, then returns true', () {
      // Given
      final ball = Ball(position: Vector2(100, 1500)); // y = 1500, threshold = 1000

      // When
      final result = ball.isOutOfBounds;

      // Then
      expect(result, isTrue);
    });

    /// Edge case: Verifies exact boundary value handling (off-by-one prevention)
    ///
    /// At the exact threshold (y = 1000), the ball should NOT be considered
    /// out of bounds. The condition is position.y > 1000, not >=, ensuring
    /// balls exactly at the boundary are still considered valid.
    test('given a ball exactly at bounds threshold, when isOutOfBounds checked, then returns false', () {
      // Given
      final ball = Ball(position: Vector2(100, 1000)); // y = 1000, threshold = 1000

      // When
      final result = ball.isOutOfBounds;

      // Then
      expect(result, isFalse);
    });
  });
}
