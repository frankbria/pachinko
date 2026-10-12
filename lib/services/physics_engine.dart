import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';
import '../models/ball.dart';
import '../models/peg.dart';
import '../models/slot.dart';
import '../utils/constants.dart';
import 'audio_service.dart';

class PhysicsEngine {
  final AudioService? _audioService;
  final math.Random _random;

  static const double _gravity = GameConstants.gravity;
  static const double _damping = GameConstants.bounceDamping;
  static const double _airResistance = GameConstants.airResistance;

  /// Creates a PhysicsEngine with optional AudioService for sound effects.
  ///
  /// [random] drives the small deflection added to each peg bounce; pass a
  /// seeded one for a repeatable simulation.
  PhysicsEngine({AudioService? audioService, math.Random? random})
      : _audioService = audioService,
        _random = random ?? math.Random();

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
    // Left boundary - CONDITIONAL based on ball Y position
    // When y <= 110 (in top/launch area): left boundary at x=0 (board left edge)
    // When y > 110 (in playfield): tighter left boundary to align with leftmost slot
    final leftBoundaryX =
        ball.position.y <= 110.0 ? 0.0 : GameConstants.fieldLeftBoundaryX;

    if (ball.position.x - ball.radius <= leftBoundaryX) {
      ball.position.x = leftBoundaryX + ball.radius;
      ball.velocity.x = -ball.velocity.x * _damping;
    }

    // Right field boundary - CONDITIONAL based on ball Y position
    // When y <= 110 (in top/launch area): right boundary at x=390 (board right edge)
    // When y > 110 (in playfield): tighter right boundary to make edge scoring harder
    final rightBoundaryX =
        ball.position.y <= 110.0 ? 390.0 : GameConstants.fieldRightBoundaryX;

    if (ball.position.x + ball.radius >= rightBoundaryX) {
      ball.position.x = rightBoundaryX - ball.radius;
      ball.velocity.x = -ball.velocity.x * _damping;
    }

    // The dome: a quadratic bezier over the top of the field. A ball that
    // reaches it is guided along its underside, not thrown back: the dome
    // takes away the part of the ball's velocity that points into it and
    // leaves the rest, so a fast ball rides the curve and a slow one drops
    // away where gravity outweighs its speed
    const startX = GameConstants.topCurveStartX;
    const startY = GameConstants.topCurveStartY;
    const controlX = GameConstants.topCurveControlX;
    const controlY = GameConstants.topCurveControlY;
    const endX = GameConstants.topCurveEndX;
    const endY = GameConstants.topCurveEndY;

    if (ball.position.x >= startX && ball.position.x <= endX) {
      final t = (ball.position.x - startX) / (endX - startX);
      // B(t) = (1-t)²P₀ + 2(1-t)tP₁ + t²P₂, and its derivative
      final curveY = (1 - t) * (1 - t) * startY +
          2 * (1 - t) * t * controlY +
          t * t * endY;
      final tangentX =
          2 * (1 - t) * (controlX - startX) + 2 * t * (endX - controlX);
      final tangentY =
          2 * (1 - t) * (controlY - startY) + 2 * t * (endY - controlY);
      final tangentLength =
          math.sqrt(tangentX * tangentX + tangentY * tangentY);
      // The normal that points down into the field
      final normalX = -tangentY / tangentLength;
      final normalY = tangentX / tangentLength;

      // How far the ball's centre is below the curve, measured across it
      // and not straight down: at the dome's steep ends the two differ
      final clearance = (ball.position.y - curveY) * normalY;
      final overlap = ball.radius - clearance;
      if (overlap > 0) {
        ball.position.x += normalX * overlap;
        ball.position.y += normalY * overlap;

        final into = ball.velocity.x * normalX + ball.velocity.y * normalY;
        if (into < 0) {
          ball.velocity.x -= into * normalX;
          ball.velocity.y -= into * normalY;
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

          // Every bounce flashes and sounds. Only a peg's first hit is
          // reported: that is what collects a prize peg
          final firstHit = !peg.hasBeenHit;
          if (firstHit || peg.canFireAgain) {
            if (firstHit) {
              if (peg.type == PegType.special) ball.prizePegsCollected++;
              hitPegs.add(peg);
            }
            peg.onHit();
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
    final overlap =
        (peg.radius + ball.radius) - (ball.position - peg.position).length;
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
    final randomAngle = (_random.nextDouble() - 0.5) * 0.2;
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

  Vector2 calculateLaunchVelocity(
      Vector2 startPosition, Vector2 targetPosition, double force) {
    final direction = (targetPosition - startPosition).normalized();
    return direction * force;
  }

  bool isValidLaunchAngle(double angle) {
    // Restrict launch angle to reasonable range (downward trajectory)
    return angle >= math.pi * 0.25 && angle <= math.pi * 0.75;
  }

  double calculateTrajectoryMaxHeight(
      Vector2 launchVelocity, Vector2 startPosition) {
    // Calculate maximum height of projectile motion
    final verticalVelocity = launchVelocity.y.abs();
    final maxHeight = (verticalVelocity * verticalVelocity) / (2 * _gravity);
    return startPosition.y - maxHeight;
  }

  List<Vector2> calculateTrajectoryPoints(Vector2 startPosition,
      Vector2 launchVelocity, int numPoints, double timeStep) {
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
