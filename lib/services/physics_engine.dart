import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';
import '../models/ball.dart';
import '../models/peg.dart';
import '../models/slot.dart';
import '../utils/constants.dart';

class PhysicsEngine {
  static const double _gravity = GameConstants.gravity;
  static const double _damping = GameConstants.bounceDamping;
  static const double _airResistance = GameConstants.airResistance;
  
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
    
    // Right boundary
    if (ball.position.x + ball.radius >= GameConstants.boardWidth) {
      ball.position.x = GameConstants.boardWidth - ball.radius;
      ball.velocity.x = -ball.velocity.x * _damping;
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