import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart';

/// Represents a visual particle effect in the game.
///
/// Particles are used for visual feedback effects like peg hits, special peg
/// activations, and ball launches. They support pooling through the [isActive]
/// flag to reduce garbage collection overhead.
///
/// Particles update their position based on velocity and fade out based on
/// their age relative to lifetime.
class Particle {
  /// Current X,Y coordinates of the particle.
  Vector2 position;

  /// Movement vector in pixels per second.
  Vector2 velocity;

  /// RGBA color value for rendering.
  Color color;

  /// Maximum lifetime in seconds.
  ///
  /// Must be greater than 0.
  final double lifetime;

  /// Current age in seconds.
  ///
  /// Must be >= 0 and <= [lifetime].
  double age;

  /// Radius of the particle in pixels.
  ///
  /// Must be > 0 and <= 20.
  final double size;

  /// Alpha transparency value (0.0 = fully transparent, 1.0 = fully opaque).
  ///
  /// Must be between 0.0 and 1.0.
  double opacity;

  /// Whether this particle is currently active in the game.
  ///
  /// Used for object pooling to reduce garbage collection pressure.
  /// Inactive particles can be recycled instead of creating new instances.
  bool isActive;

  /// Creates a new particle with the specified properties.
  ///
  /// Throws [ArgumentError] if validation rules are violated:
  /// - [lifetime] must be > 0
  /// - [age] must be >= 0 and <= [lifetime]
  /// - [size] must be > 0 and <= 20
  /// - [opacity] must be between 0.0 and 1.0
  Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.lifetime,
    this.age = 0.0,
    required this.size,
    this.opacity = 1.0,
    this.isActive = true,
  }) {
    // Validate lifetime
    if (lifetime <= 0) {
      throw ArgumentError('Lifetime must be greater than 0, got: $lifetime');
    }

    // Validate age
    if (age < 0 || age > lifetime) {
      throw ArgumentError(
          'Age must be >= 0 and <= lifetime ($lifetime), got: $age');
    }

    // Validate size
    if (size <= 0 || size > 20) {
      throw ArgumentError('Size must be > 0 and <= 20, got: $size');
    }

    // Validate opacity
    if (opacity < 0.0 || opacity > 1.0) {
      throw ArgumentError('Opacity must be between 0.0 and 1.0, got: $opacity');
    }
  }

  /// Updates the particle's state based on elapsed time.
  ///
  /// Updates position, age, opacity, and activity status.
  /// Particles automatically deactivate when their age exceeds lifetime.
  ///
  /// [deltaTime] - Time elapsed since last update in seconds.
  void update(double deltaTime) {
    if (!isActive) return;

    // Update age
    age += deltaTime;

    // Update position based on velocity
    position.x += velocity.x * deltaTime;
    position.y += velocity.y * deltaTime;

    // Update opacity (fade out in last 30% of lifetime)
    final fadeStartAge = lifetime * 0.7;
    if (age > fadeStartAge) {
      final fadeProgress = (age - fadeStartAge) / (lifetime - fadeStartAge);
      opacity = 1.0 - fadeProgress.clamp(0.0, 1.0);
    }

    // Deactivate if expired
    if (age >= lifetime) {
      isActive = false;
      opacity = 0.0;
    }
  }
}
