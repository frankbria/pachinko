import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';
import '../models/ball.dart';
import '../models/peg.dart';
import '../models/slot.dart';
import '../utils/constants.dart';
import 'audio_service.dart';

class PhysicsEngine {
  final AudioService? _audioService;

  static const double _gravity = GameConstants.gravity;
  static const double _damping = GameConstants.bounceDamping;
  static const double _airResistance = GameConstants.airResistance;

  /// Creates a PhysicsEngine with optional AudioService for sound effects
  PhysicsEngine({AudioService? audioService}) : _audioService = audioService;
  
  void updateBalls(List<Ball> balls, double deltaTime) {
    for (final ball in balls) {
      if (!ball.isActive || ball.hasLanded) continue;
      
      // Apply gravity
      ball.acceleration.setValues(0, _gravity);
      
      // Update velocity with acceleration
      ball.velocity.add(ball.acceleration * deltaTime);
      
      // Apply air resistance
      ball.velocity.scale(_airResistance);
      
      // Update position
      ball.position.add(ball.velocity * deltaTime);
      
      // Check boundaries
      _checkBoundaryCollisions(ball);
    }
  }

  void _checkBoundaryCollisions(Ball ball) {
    // Left boundary
    if (ball.position.x - ball.radius <= 0) {
      ball.position.x = ball.radius;
      ball.velocity.x = -ball.velocity.x * _damping;
    }
    
    // Left vertical FIELD barrier collision at x=30 (playfield boundary)
    const leftFieldBarrierX = 30.0;
    const leftFieldBarrierTopY = 110.0;  // Ends at y=110 where top boundary starts
    final leftFieldBarrierBottomY = GameConstants.launchChannelStartY;
    
    if (ball.position.x - ball.radius <= leftFieldBarrierX && 
        ball.position.y >= leftFieldBarrierTopY && 
        ball.position.y <= leftFieldBarrierBottomY) {
      ball.position.x = leftFieldBarrierX + ball.radius;
      ball.velocity.x = -ball.velocity.x * _damping;
    }
    
    // Right boundary - CONDITIONAL based on ball Y position
    // When y <= 110 (above playfield): right boundary is at x=390 (board/launch tube right edge)
    // When y > 110 (in playfield): right boundary is at x=360 (playfield right edge, blocks launch tube entry)
    final rightBoundaryX = ball.position.y <= 110.0 ? 390.0 : GameConstants.launchChannelStartX;
    
    if (ball.position.x + ball.radius >= rightBoundaryX) {
      ball.position.x = rightBoundaryX - ball.radius;
      ball.velocity.x = -ball.velocity.x * _damping;
    }
    
    // Top curved boundary collision - user's exact specification
    // Quadratic bezier from (30, 110) -> control (210, -100) -> (390, 110)
    const topBoundaryStartX = 30.0;
    const topBoundaryStartY = 110.0;  // Matches left field barrier top
    const topBoundaryControlX = 210.0;
    const topBoundaryControlY = -100.0;
    const topBoundaryEndX = 390.0;
    const topBoundaryEndY = 110.0;

    // Check if ball is in the region of the curved boundary
    if (ball.position.x >= topBoundaryStartX && ball.position.x <= topBoundaryEndX) {
      // Calculate t parameter for the bezier curve based on x position
      final t = (ball.position.x - topBoundaryStartX) / (topBoundaryEndX - topBoundaryStartX);

      // Quadratic bezier formula: B(t) = (1-t)²P₀ + 2(1-t)tP₁ + t²P₂
      final curveY = (1 - t) * (1 - t) * topBoundaryStartY +
                     2 * (1 - t) * t * topBoundaryControlY +
                     t * t * topBoundaryEndY;

      // Distance from BOTTOM of ball to the curve (not center)
      final distanceToCurve = (ball.position.y - ball.radius) - curveY;

      // Only apply collision if ball has penetrated the curve
      if (distanceToCurve < 0) {
        // Calculate the derivative for the normal vector
        // Derivative: B'(t) = 2(1-t)(P₁-P₀) + 2t(P₂-P₁)
        final derivativeX = 2 * (1 - t) * (topBoundaryControlX - topBoundaryStartX) +
                           2 * t * (topBoundaryEndX - topBoundaryControlX);
        final derivativeY = 2 * (1 - t) * (topBoundaryControlY - topBoundaryStartY) +
                           2 * t * (topBoundaryEndY - topBoundaryControlY);

        // Calculate the normal (perpendicular to derivative, pointing down)
        final normalLength = math.sqrt(derivativeX * derivativeX + derivativeY * derivativeY);
        final normalX = derivativeY / normalLength;  // Perpendicular
        final normalY = -derivativeX / normalLength;

        // Ensure normal points downward (away from curve)
        final normalYFinal = normalY > 0 ? normalY : -normalY;
        final normalXFinal = normalY > 0 ? normalX : -normalX;

        // Push ball below the curve
        final overlap = -distanceToCurve;  // distanceToCurve is negative, so overlap is positive
        ball.position.x += normalXFinal * overlap;
        ball.position.y += normalYFinal * overlap;

        // Reflect velocity along the normal
        final dotProduct = ball.velocity.x * normalXFinal + ball.velocity.y * normalYFinal;
        if (dotProduct < 0) {  // Only bounce if moving toward the curve
          ball.velocity.x = (ball.velocity.x - 2 * dotProduct * normalXFinal) * _damping;
          ball.velocity.y = (ball.velocity.y - 2 * dotProduct * normalYFinal) * _damping;
        }
      }
    }
    
    // Bottom boundary (ball has left the board)
    if (ball.position.y > GameConstants.boardHeight + ball.radius) {
      ball.isActive = false;
    }
  }

  List<Peg> checkPegCollisions(List<Ball> balls, List<Peg> pegs) {
    final hitPegs = <Peg>[];

    for (final ball in balls) {
      if (!ball.isActive) continue;

      for (final peg in pegs) {
        if (peg.checkCollision(ball.position, ball.radius)) {
          _resolvePegCollision(ball, peg);

          if (!peg.hasBeenHit) {
            peg.onHit();
            hitPegs.add(peg);
            // Play peg hit sound (for all peg types)
            _audioService?.playPegHit();
          }
        }
      }
    }

    return hitPegs;
  }

  void _resolvePegCollision(Ball ball, Peg peg) {
    // Calculate collision normal
    final collisionNormal = peg.getCollisionNormal(ball.position);
    
    // Separate the ball from the peg
    final overlap = (peg.radius + ball.radius) - (ball.position - peg.position).length;
    if (overlap > 0) {
      ball.position.add(collisionNormal * overlap);
    }
    
    // Calculate relative velocity
    final relativeVelocity = ball.velocity.clone();
    
    // Calculate relative velocity in collision normal direction
    final velocityAlongNormal = relativeVelocity.dot(collisionNormal);
    
    // Do not resolve if velocities are separating
    if (velocityAlongNormal > 0) return;
    
    // Calculate restitution (bounciness)
    const restitution = 0.8;
    
    // Calculate impulse scalar
    final impulseScalar = -(1 + restitution) * velocityAlongNormal;
    
    // Apply impulse
    final impulse = collisionNormal * impulseScalar;
    ball.velocity.add(impulse);
    
    // Add some randomness to prevent perfect patterns
    final randomAngle = (math.Random().nextDouble() - 0.5) * 0.2;
    final rotationMatrix = Matrix2.rotation(randomAngle);
    ball.velocity = rotationMatrix * ball.velocity;
  }

  List<Slot> checkSlotCollisions(List<Ball> balls, List<Slot> slots) {
    final hitSlots = <Slot>[];
    
    for (final ball in balls) {
      if (!ball.isActive || ball.hasLanded) continue;
      
      for (final slot in slots) {
        if (slot.containsPoint(ball.position) && 
            ball.position.y >= slot.position.y - slot.height / 2) {
          ball.hasLanded = true;
          ball.isActive = false;
          slot.addBall();
          hitSlots.add(slot);
          break;
        }
      }
    }
    
    return hitSlots;
  }

  Vector2 calculateLaunchVelocity(Vector2 startPosition, Vector2 targetPosition, double force) {
    final direction = (targetPosition - startPosition).normalized();
    return direction * force;
  }

  bool isValidLaunchAngle(double angle) {
    // Restrict launch angle to reasonable range (downward trajectory)
    return angle >= math.pi * 0.25 && angle <= math.pi * 0.75;
  }

  double calculateTrajectoryMaxHeight(Vector2 launchVelocity, Vector2 startPosition) {
    // Calculate maximum height of projectile motion
    final verticalVelocity = launchVelocity.y.abs();
    final maxHeight = (verticalVelocity * verticalVelocity) / (2 * _gravity);
    return startPosition.y - maxHeight;
  }

  List<Vector2> calculateTrajectoryPoints(Vector2 startPosition, Vector2 launchVelocity, 
                                         int numPoints, double timeStep) {
    final points = <Vector2>[];
    var position = startPosition.clone();
    var velocity = launchVelocity.clone();
    
    for (int i = 0; i < numPoints; i++) {
      points.add(position.clone());
      
      // Update position and velocity for next point
      position.add(velocity * timeStep);
      velocity.y += _gravity * timeStep;
      velocity.scale(_airResistance);
      
      // Stop if ball goes off screen
      if (position.y > GameConstants.boardHeight) break;
    }
    
    return points;
  }
}