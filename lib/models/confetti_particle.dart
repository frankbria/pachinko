import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

/// Confetti particle for celebration effects
///
/// Spawned when special bonus triggers. Particles spread outward,
/// fall with gravity, rotate, and fade out over time.
///
/// Physics behavior:
/// - Initial velocity: Radial spread outward with upward bias
/// - Gravity: 300 px/s² downward acceleration
/// - Rotation: Random spin speed
/// - Lifetime: 2 seconds, fade out in last 0.5s
class ConfettiParticle {
  Vector2 position;
  Vector2 velocity;
  final Color color;
  final double size;
  double rotation = 0.0;
  double rotationSpeed;
  double lifetime = 0.0;
  static const double maxLifetime = 2.0; // 2 seconds

  ConfettiParticle({
    required this.position,
    required this.velocity,
    required this.color,
    this.size = 8.0,
  }) : rotationSpeed = (math.Random().nextDouble() - 0.5) * 10.0;

  /// Update particle physics
  /// Returns true if particle expired
  bool update(double deltaTime) {
    lifetime += deltaTime;

    if (lifetime >= maxLifetime) {
      return true; // Particle expired
    }

    // Gravity
    velocity.y += 300.0 * deltaTime; // pixels/s²

    // Update position
    position.add(velocity * deltaTime);

    // Rotation
    rotation += rotationSpeed * deltaTime;

    return false;
  }

  double get opacity {
    // Fade out in last 0.5 seconds
    if (lifetime >= maxLifetime - 0.5) {
      return (maxLifetime - lifetime) / 0.5;
    }
    return 1.0;
  }
}
