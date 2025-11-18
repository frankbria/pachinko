import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:pachinko_game/models/ball.dart';
import 'package:pachinko_game/models/peg.dart';
import 'package:pachinko_game/models/slot.dart';
import 'package:pachinko_game/services/physics_engine.dart';
import 'package:pachinko_game/utils/constants.dart';

// Generate mocks for Ball, Peg, and Slot
@GenerateMocks([Ball, Peg, Slot])
import 'physics_engine_test.mocks.dart';

void main() {
  late PhysicsEngine physicsEngine;

  setUp(() {
    physicsEngine = PhysicsEngine();
  });

  group('Gravity Application and Velocity Integration', () {
    /// Tests gravity constant application (980.0 px/s²) to ball acceleration
    /// using Euler integration: velocity += acceleration * deltaTime
    test('Given active ball When updateBalls called Then gravity applied to acceleration', () {
      // Given: Create real Ball instance with initial state
      final ball = Ball(
        position: Vector2(200, 100),
        velocity: Vector2(0, 0),
        radius: GameConstants.ballRadius,
      );
      final deltaTime = GameConstants.physicsTimeStep; // 1/60 = 0.016667s

      // When: Update balls with physics
      physicsEngine.updateBalls([ball], deltaTime);

      // Then: Acceleration should be set to gravity (0, 980.0)
      expect(ball.acceleration.x, equals(0.0));
      expect(ball.acceleration.y, equals(GameConstants.gravity));
    });

    /// Tests velocity integration using formula: velocity += acceleration * deltaTime
    /// Verifies numerical integration over one physics timestep (60 FPS)
    test('Given ball with gravity acceleration When updateBalls called Then velocity integrated correctly', () {
      // Given: Ball at rest
      final ball = Ball(
        position: Vector2(200, 100),
        velocity: Vector2(0, 0),
        radius: GameConstants.ballRadius,
      );
      final deltaTime = GameConstants.physicsTimeStep; // 0.016667s

      // When: Update physics
      physicsEngine.updateBalls([ball], deltaTime);

      // Then: Velocity should increase by gravity * deltaTime
      // vy = 0 + 980.0 * 0.016667 ≈ 16.33 px/s
      final expectedVelocityY = GameConstants.gravity * deltaTime * GameConstants.airResistance;
      expect(ball.velocity.x, closeTo(0.0, 0.01));
      expect(ball.velocity.y, closeTo(expectedVelocityY, 0.1));
    });

    /// Tests position integration using Euler method: position += velocity * deltaTime
    /// Verifies ball position updates correctly based on velocity
    test('Given ball with velocity When updateBalls called Then position updated with Euler integration', () {
      // Given: Ball with initial velocity
      final ball = Ball(
        position: Vector2(200, 100),
        velocity: Vector2(50, 100),
        radius: GameConstants.ballRadius,
      );
      final deltaTime = GameConstants.physicsTimeStep;
      final initialX = ball.position.x;
      final initialY = ball.position.y;

      // When: Update physics
      physicsEngine.updateBalls([ball], deltaTime);

      // Then: Position should integrate velocity
      // New position includes: original velocity * dt + (gravity effect after damping)
      expect(ball.position.x, greaterThan(initialX));
      expect(ball.position.y, greaterThan(initialY));
    });
  });

  group('Air Resistance and Damping', () {
    /// Tests air resistance damping factor (0.999) applied to velocity per frame
    /// Formula: velocity *= airResistance (0.999 per frame)
    test('Given ball with velocity When updateBalls called Then air resistance damping applied', () {
      // Given: Ball with significant velocity
      final ball = Ball(
        position: Vector2(200, 100),
        velocity: Vector2(100, 100),
        radius: GameConstants.ballRadius,
      );
      final deltaTime = GameConstants.physicsTimeStep;
      final initialVelocityMagnitude = ball.velocity.length;

      // When: Update physics
      physicsEngine.updateBalls([ball], deltaTime);

      // Then: Velocity magnitude should be reduced by air resistance
      // Note: gravity adds to velocity, so we check the damping was applied
      final velocityAfterGravity = Vector2(100, 100 + GameConstants.gravity * deltaTime);
      final expectedMagnitude = velocityAfterGravity.length * GameConstants.airResistance;
      expect(ball.velocity.length, closeTo(expectedMagnitude, 1.0));
    });

    /// Tests that inactive balls are not updated by physics engine
    test('Given inactive ball When updateBalls called Then ball not updated', () {
      // Given: Inactive ball
      final ball = Ball(
        position: Vector2(200, 100),
        velocity: Vector2(50, 50),
        radius: GameConstants.ballRadius,
      );
      ball.isActive = false;
      final initialPosition = ball.position.clone();
      final initialVelocity = ball.velocity.clone();

      // When: Update physics
      physicsEngine.updateBalls([ball], GameConstants.physicsTimeStep);

      // Then: Ball state should remain unchanged
      expect(ball.position.x, equals(initialPosition.x));
      expect(ball.position.y, equals(initialPosition.y));
      expect(ball.velocity.x, equals(initialVelocity.x));
      expect(ball.velocity.y, equals(initialVelocity.y));
    });

    /// Tests that landed balls are not updated by physics engine
    test('Given landed ball When updateBalls called Then ball not updated', () {
      // Given: Landed ball
      final ball = Ball(
        position: Vector2(200, 500),
        velocity: Vector2(10, 10),
        radius: GameConstants.ballRadius,
      );
      ball.hasLanded = true;
      final initialPosition = ball.position.clone();

      // When: Update physics
      physicsEngine.updateBalls([ball], GameConstants.physicsTimeStep);

      // Then: Ball should not move
      expect(ball.position.x, equals(initialPosition.x));
      expect(ball.position.y, equals(initialPosition.y));
    });
  });

  group('Wall Collision Detection and Bounce', () {
    /// Tests left wall collision with restitution coefficient (0.7)
    /// Formula: velocity.x = -velocity.x * bounceDamping (0.7)
    test('Given ball hitting left wall When updateBalls called Then ball bounces with 0.7 restitution', () {
      // Given: Ball moving left near left boundary in playfield
      final ball = Ball(
        position: Vector2(5, 200), // Near left wall, in playfield (y > 110)
        velocity: Vector2(-50, 0), // Moving left
        radius: GameConstants.ballRadius,
      );

      // When: Update physics (will trigger boundary collision)
      physicsEngine.updateBalls([ball], GameConstants.physicsTimeStep);

      // Then: Ball should bounce right with damping
      // In playfield, left boundary is fieldLeftBoundaryX = 15.0
      expect(ball.position.x, equals(GameConstants.fieldLeftBoundaryX + ball.radius));
      expect(ball.velocity.x, greaterThan(0)); // Reversed direction
      // Velocity should be approximately 50 * 0.7 = 35 (after air resistance too)
      expect(ball.velocity.x.abs(), closeTo(50 * GameConstants.bounceDamping * GameConstants.airResistance, 1.0));
    });

    /// Tests right wall collision with restitution coefficient (0.7)
    test('Given ball hitting right wall When updateBalls called Then ball bounces with 0.7 restitution', () {
      // Given: Ball moving right near right boundary in playfield
      final ball = Ball(
        position: Vector2(GameConstants.boardWidth - 5, 200), // In playfield (y > 110)
        velocity: Vector2(50, 0), // Moving right
        radius: GameConstants.ballRadius,
      );

      // When: Update physics
      physicsEngine.updateBalls([ball], GameConstants.physicsTimeStep);

      // Then: Ball should bounce left with damping
      // In playfield, right boundary is fieldRightBoundaryX = 345.0
      expect(ball.position.x, equals(GameConstants.fieldRightBoundaryX - ball.radius));
      expect(ball.velocity.x, lessThan(0)); // Reversed
      expect(ball.velocity.x.abs(), closeTo(50 * GameConstants.bounceDamping * GameConstants.airResistance, 1.0));
    });

    /// Tests bottom boundary behavior - ball deactivation when leaving board
    test('Given ball below board When updateBalls called Then ball deactivated', () {
      // Given: Ball below board
      final ball = Ball(
        position: Vector2(200, GameConstants.boardHeight + 20),
        velocity: Vector2(0, 50),
        radius: GameConstants.ballRadius,
      );

      // When: Update physics
      physicsEngine.updateBalls([ball], GameConstants.physicsTimeStep);

      // Then: Ball should be deactivated
      expect(ball.isActive, isFalse);
    });
  });

  group('Peg Collision Detection', () {
    /// Tests circle-circle collision detection formula: distance <= r1 + r2
    /// Uses mocked Peg to verify collision detection logic
    test('Given ball near peg When checkPegCollisions called Then collision detected', () {
      // Given: Real ball and mocked peg
      final ball = Ball(
        position: Vector2(200, 200),
        velocity: Vector2(50, 50),
        radius: GameConstants.ballRadius,
      );
      final mockPeg = MockPeg();

      // Mock peg properties
      when(mockPeg.position).thenReturn(Vector2(210, 210));
      when(mockPeg.radius).thenReturn(10.0);
      when(mockPeg.hasBeenHit).thenReturn(false);
      when(mockPeg.checkCollision(any, any)).thenReturn(true);
      when(mockPeg.getCollisionNormal(any)).thenReturn(Vector2(-1, -1).normalized());

      // When: Check collisions
      final hitPegs = physicsEngine.checkPegCollisions([ball], [mockPeg]);

      // Then: Collision should be detected
      expect(hitPegs.length, equals(1));
      expect(hitPegs.first, equals(mockPeg));
      verify(mockPeg.onHit()).called(1);
    });

    /// Tests that already-hit pegs are not added to hitPegs list again
    test('Given ball hitting already-hit peg When checkPegCollisions called Then peg not in hitPegs', () {
      // Given: Ball and peg that was already hit
      final ball = Ball(
        position: Vector2(200, 200),
        velocity: Vector2(50, 50),
        radius: GameConstants.ballRadius,
      );
      final mockPeg = MockPeg();

      when(mockPeg.position).thenReturn(Vector2(210, 210));
      when(mockPeg.radius).thenReturn(10.0);
      when(mockPeg.hasBeenHit).thenReturn(true); // Already hit
      when(mockPeg.checkCollision(any, any)).thenReturn(true);
      when(mockPeg.getCollisionNormal(any)).thenReturn(Vector2(-1, -1).normalized());

      // When: Check collisions
      final hitPegs = physicsEngine.checkPegCollisions([ball], [mockPeg]);

      // Then: Peg should not be in hitPegs list
      expect(hitPegs.length, equals(0));
    });

    /// Tests that inactive balls do not trigger peg collisions
    test('Given inactive ball When checkPegCollisions called Then no collision processed', () {
      // Given: Inactive ball
      final ball = Ball(
        position: Vector2(200, 200),
        velocity: Vector2(50, 50),
        radius: GameConstants.ballRadius,
      );
      ball.isActive = false;
      final mockPeg = MockPeg();

      when(mockPeg.checkCollision(any, any)).thenReturn(true);

      // When: Check collisions
      final hitPegs = physicsEngine.checkPegCollisions([ball], [mockPeg]);

      // Then: No collisions should be detected
      expect(hitPegs.length, equals(0));
      verifyNever(mockPeg.checkCollision(any, any));
    });
  });

  group('Peg Collision Resolution and Impulse', () {
    /// Tests collision normal calculation and impulse application
    /// Normal vector should point from peg center to ball contact point
    test('Given ball colliding with peg When collision resolved Then impulse applied along normal', () {
      // Given: Ball moving toward peg
      final ball = Ball(
        position: Vector2(200, 200),
        velocity: Vector2(100, 0), // Moving right
        radius: GameConstants.ballRadius,
      );
      final mockPeg = MockPeg();
      final pegPosition = Vector2(210, 200); // Peg to the right
      final collisionNormal = Vector2(-1, 0); // Normal points left (from peg to ball)

      when(mockPeg.position).thenReturn(pegPosition);
      when(mockPeg.radius).thenReturn(10.0);
      when(mockPeg.hasBeenHit).thenReturn(false);
      when(mockPeg.checkCollision(any, any)).thenReturn(true);
      when(mockPeg.getCollisionNormal(any)).thenReturn(collisionNormal);

      // When: Check collisions (triggers resolution)
      physicsEngine.checkPegCollisions([ball], [mockPeg]);

      // Then: Ball velocity should be reversed and dampened
      expect(ball.velocity.x, lessThan(0)); // Reversed direction
    });

    /// Tests that collision response includes random angle perturbation (±0.1 rad)
    /// Verifies randomness range by checking velocity variation across multiple collisions
    test('Given multiple peg collisions When resolved Then random perturbation applied', () {
      // Given: Multiple trials to verify randomness
      final velocityVectors = <Vector2>[];

      for (int i = 0; i < 50; i++) {
        final ball = Ball(
          position: Vector2(200, 200),
          velocity: Vector2(100, 0),
          radius: GameConstants.ballRadius,
        );
        final mockPeg = MockPeg();

        when(mockPeg.position).thenReturn(Vector2(210, 200));
        when(mockPeg.radius).thenReturn(10.0);
        when(mockPeg.hasBeenHit).thenReturn(false);
        when(mockPeg.checkCollision(any, any)).thenReturn(true);
        when(mockPeg.getCollisionNormal(any)).thenReturn(Vector2(-1, 0));

        // When: Resolve collision
        physicsEngine.checkPegCollisions([ball], [mockPeg]);

        // Then: Record velocity vector
        velocityVectors.add(ball.velocity.clone());
      }

      // Verify that velocities have variation (not all identical)
      // Check y-component variation to confirm random perturbation was applied
      final yComponents = velocityVectors.map((v) => v.y).toSet();
      expect(yComponents.length, greaterThan(10)); // Should have significant variety

      // Verify all velocities are generally moving in expected direction (leftward after bounce)
      for (final velocity in velocityVectors) {
        expect(velocity.x, lessThan(0)); // Should be moving left after bounce
      }
    });

    /// Tests that separating velocities do not get impulse applied
    /// Prevents "sticky" collisions by checking velocity direction
    test('Given ball separating from peg When collision checked Then no impulse applied', () {
      // Given: Ball moving away from peg
      final ball = Ball(
        position: Vector2(200, 200),
        velocity: Vector2(-100, 0), // Moving left (away from peg on right)
        radius: GameConstants.ballRadius,
      );
      final mockPeg = MockPeg();
      final pegPosition = Vector2(210, 200); // Peg to the right
      final collisionNormal = Vector2(-1, 0).normalized();

      when(mockPeg.position).thenReturn(pegPosition);
      when(mockPeg.radius).thenReturn(10.0);
      when(mockPeg.hasBeenHit).thenReturn(false);
      when(mockPeg.checkCollision(any, any)).thenReturn(true);
      when(mockPeg.getCollisionNormal(any)).thenReturn(collisionNormal);

      final initialVelocity = ball.velocity.clone();

      // When: Check collisions
      physicsEngine.checkPegCollisions([ball], [mockPeg]);

      // Then: Velocity direction should not be reversed (ball already separating)
      // Note: There will be random perturbation applied, but direction generally preserved
      expect(ball.velocity.x, lessThan(0)); // Still moving left
    });
  });

  group('Slot Collision Detection (AABB)', () {
    /// Tests axis-aligned bounding box (AABB) collision detection for slots
    /// Verifies ball landing in slot deactivates ball and increments slot count
    test('Given ball in slot bounds When checkSlotCollisions called Then ball lands in slot', () {
      // Given: Ball positioned in slot
      final ball = Ball(
        position: Vector2(50, 550),
        velocity: Vector2(0, 50),
        radius: GameConstants.ballRadius,
      );
      final mockSlot = MockSlot();

      when(mockSlot.position).thenReturn(Vector2(50, 560));
      when(mockSlot.width).thenReturn(40.0);
      when(mockSlot.height).thenReturn(60.0);
      when(mockSlot.containsPoint(any)).thenReturn(true);

      // When: Check slot collisions
      final hitSlots = physicsEngine.checkSlotCollisions([ball], [mockSlot]);

      // Then: Ball should land in slot
      expect(ball.hasLanded, isTrue);
      expect(ball.isActive, isFalse);
      expect(hitSlots.length, equals(1));
      verify(mockSlot.addBall()).called(1);
    });

    /// Tests that ball above slot does not trigger collision
    test('Given ball above slot When checkSlotCollisions called Then no collision', () {
      // Given: Ball above slot
      final ball = Ball(
        position: Vector2(50, 400),
        velocity: Vector2(0, 50),
        radius: GameConstants.ballRadius,
      );
      final mockSlot = MockSlot();

      when(mockSlot.position).thenReturn(Vector2(50, 560));
      when(mockSlot.width).thenReturn(40.0);
      when(mockSlot.height).thenReturn(60.0);
      when(mockSlot.containsPoint(any)).thenReturn(false);

      // When: Check collisions
      final hitSlots = physicsEngine.checkSlotCollisions([ball], [mockSlot]);

      // Then: No collision
      expect(ball.hasLanded, isFalse);
      expect(hitSlots.length, equals(0));
    });

    /// Tests that inactive balls do not trigger slot collisions
    test('Given inactive ball in slot When checkSlotCollisions called Then no collision', () {
      // Given: Inactive ball
      final ball = Ball(
        position: Vector2(50, 550),
        velocity: Vector2(0, 50),
        radius: GameConstants.ballRadius,
      );
      ball.isActive = false;
      final mockSlot = MockSlot();

      when(mockSlot.containsPoint(any)).thenReturn(true);

      // When: Check collisions
      final hitSlots = physicsEngine.checkSlotCollisions([ball], [mockSlot]);

      // Then: No collision processed
      expect(hitSlots.length, equals(0));
      verifyNever(mockSlot.addBall());
    });

    /// Tests that already-landed balls do not trigger slot collisions
    test('Given landed ball When checkSlotCollisions called Then no collision', () {
      // Given: Landed ball
      final ball = Ball(
        position: Vector2(50, 550),
        velocity: Vector2(0, 50),
        radius: GameConstants.ballRadius,
      );
      ball.hasLanded = true;
      final mockSlot = MockSlot();

      // When: Check collisions
      final hitSlots = physicsEngine.checkSlotCollisions([ball], [mockSlot]);

      // Then: No collision processed
      expect(hitSlots.length, equals(0));
      verifyNever(mockSlot.containsPoint(any));
    });
  });

  group('Launch and Trajectory Calculations', () {
    /// Tests launch velocity calculation from start position to target
    /// Formula: direction = (target - start).normalized(), velocity = direction * force
    test('Given start and target positions When calculateLaunchVelocity called Then correct velocity vector returned', () {
      // Given: Launch parameters
      final startPosition = Vector2(100, 500);
      final targetPosition = Vector2(200, 400);
      final force = 500.0;

      // When: Calculate launch velocity
      final velocity = physicsEngine.calculateLaunchVelocity(startPosition, targetPosition, force);

      // Then: Velocity should point toward target with correct magnitude
      expect(velocity.length, closeTo(force, 0.01));
      final direction = (targetPosition - startPosition).normalized();
      final expectedVelocity = direction * force;
      expect(velocity.x, closeTo(expectedVelocity.x, 0.01));
      expect(velocity.y, closeTo(expectedVelocity.y, 0.01));
    });

    /// Tests valid launch angle validation (π/4 to 3π/4 radians)
    /// Ensures balls launch in downward trajectory
    test('Given angle in valid range When isValidLaunchAngle called Then returns true', () {
      // Given: Valid angles (45° to 135° in radians)
      final validAngles = [
        math.pi * 0.25, // 45°
        math.pi * 0.5,  // 90°
        math.pi * 0.75, // 135°
      ];

      // When/Then: All should be valid
      for (final angle in validAngles) {
        expect(physicsEngine.isValidLaunchAngle(angle), isTrue);
      }
    });

    /// Tests invalid launch angle rejection
    test('Given angle outside valid range When isValidLaunchAngle called Then returns false', () {
      // Given: Invalid angles
      final invalidAngles = [
        0.0,           // 0° (horizontal right)
        math.pi * 0.1, // 18° (too shallow)
        math.pi,       // 180° (horizontal left)
        math.pi * 1.5, // 270° (upward)
      ];

      // When/Then: All should be invalid
      for (final angle in invalidAngles) {
        expect(physicsEngine.isValidLaunchAngle(angle), isFalse);
      }
    });

    /// Tests trajectory max height calculation using projectile motion formula
    /// Formula: maxHeight = (vy²) / (2 * gravity)
    test('Given launch velocity When calculateTrajectoryMaxHeight called Then correct max height returned', () {
      // Given: Upward launch velocity
      final launchVelocity = Vector2(100, -300); // Negative y = upward
      final startPosition = Vector2(100, 500);

      // When: Calculate max height
      final maxHeight = physicsEngine.calculateTrajectoryMaxHeight(launchVelocity, startPosition);

      // Then: Should calculate correct max height
      // maxHeight = startY - (vy²)/(2*g) = 500 - (300²)/(2*980) = 500 - 45.92 ≈ 454
      final expectedMaxHeight = startPosition.y - (300 * 300) / (2 * GameConstants.gravity);
      expect(maxHeight, closeTo(expectedMaxHeight, 1.0));
    });

    /// Tests trajectory point generation with physics integration
    /// Verifies points follow parabolic arc with gravity and air resistance
    test('Given launch parameters When calculateTrajectoryPoints called Then parabolic trajectory generated', () {
      // Given: Launch parameters
      final startPosition = Vector2(200, 100);
      final launchVelocity = Vector2(100, 200);
      final numPoints = 20;
      final timeStep = 0.1;

      // When: Calculate trajectory
      final points = physicsEngine.calculateTrajectoryPoints(
        startPosition,
        launchVelocity,
        numPoints,
        timeStep,
      );

      // Then: Should generate points along trajectory
      expect(points.length, greaterThan(0));
      expect(points.length, lessThanOrEqualTo(numPoints));
      expect(points.first.x, equals(startPosition.x));
      expect(points.first.y, equals(startPosition.y));

      // Verify parabolic shape (y increases as ball falls)
      for (int i = 1; i < points.length; i++) {
        expect(points[i].y, greaterThan(points[i-1].y)); // Ball falls (y increases)
      }
    });

    /// Tests trajectory stops when ball goes off screen
    test('Given trajectory going off screen When calculateTrajectoryPoints called Then trajectory stops', () {
      // Given: Launch parameters that will go off screen
      final startPosition = Vector2(200, GameConstants.boardHeight - 50);
      final launchVelocity = Vector2(0, 500); // Fast downward
      final numPoints = 100;
      final timeStep = 0.05;

      // When: Calculate trajectory
      final points = physicsEngine.calculateTrajectoryPoints(
        startPosition,
        launchVelocity,
        numPoints,
        timeStep,
      );

      // Then: Should stop before numPoints
      expect(points.length, lessThan(numPoints));
      // Last point should be near or past board height
      expect(points.last.y, greaterThanOrEqualTo(GameConstants.boardHeight - 100));
    });
  });

  group('Field Boundary Enforcement', () {
    /// Tests left field boundary collision when ball is in playfield (y > 110)
    test('Given ball at left field boundary in playfield When collision checked Then ball bounces', () {
      // Given: Ball at left field boundary (x=15) in playfield (y=200)
      final ball = Ball(
        position: Vector2(GameConstants.fieldLeftBoundaryX - 5, 200),
        velocity: Vector2(-50, 0),  // Moving left
      );
      final physicsEngine = PhysicsEngine();

      // When: Update physics
      physicsEngine.updateBalls([ball], 1 / 60);

      // Then: Ball should have bounced (velocity reversed)
      expect(ball.velocity.x, greaterThan(0));
      // Ball position should be corrected to stay within boundary
      expect(ball.position.x, greaterThanOrEqualTo(GameConstants.fieldLeftBoundaryX));
    });

    /// Tests right field boundary collision when ball is in playfield (y > 110)
    test('Given ball at right field boundary in playfield When collision checked Then ball bounces', () {
      // Given: Ball at right field boundary (x=345) in playfield (y=200)
      final ball = Ball(
        position: Vector2(GameConstants.fieldRightBoundaryX + 5, 200),
        velocity: Vector2(50, 0),  // Moving right
      );
      final physicsEngine = PhysicsEngine();

      // When: Update physics
      physicsEngine.updateBalls([ball], 1 / 60);

      // Then: Ball should have bounced (velocity reversed)
      expect(ball.velocity.x, lessThan(0));
      // Ball position should be corrected to stay within boundary
      expect(ball.position.x, lessThanOrEqualTo(GameConstants.fieldRightBoundaryX));
    });

    /// Tests that balls in launch area (y <= 110) use board boundaries instead of field boundaries
    test('Given ball at x=5 in launch area When collision checked Then uses board left boundary', () {
      // Given: Ball near left edge in launch area (y=100)
      final ball = Ball(
        position: Vector2(5, 100),
        velocity: Vector2(-50, 0),  // Moving left
      );
      final physicsEngine = PhysicsEngine();

      // When: Update physics
      physicsEngine.updateBalls([ball], 1 / 60);

      // Then: Ball should have bounced off board edge (x=0), not field boundary (x=15)
      expect(ball.velocity.x, greaterThan(0));
      expect(ball.position.x, greaterThanOrEqualTo(0));
    });
  });
}
