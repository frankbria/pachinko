/// Graphics configuration constants for particle effects, animations, and performance.
///
/// This file defines limits, thresholds, and quality settings to maintain
/// smooth gameplay at 60 FPS while providing visual feedback through particle
/// effects and animations.
library;

/// Quality levels for graphics rendering.
///
/// Used to dynamically adjust particle effects and visual fidelity based on
/// current FPS performance.
enum GraphicsQuality {
  /// High quality with all effects enabled and maximum particle counts.
  high,

  /// Medium quality with reduced particle counts and simplified effects.
  medium,

  /// Low quality with minimal particles and basic visual feedback only.
  low,
}

/// Graphics configuration constants.
class GraphicsConfig {
  // Prevent instantiation
  GraphicsConfig._();

  // Particle Limits
  // ---------------

  /// Maximum number of trail particles that can be active simultaneously.
  ///
  /// Trail particles follow balls as they move through the board, creating
  /// motion blur effects. This limit prevents performance degradation when
  /// many balls are active.
  static const int maxTrailParticles = 100;

  /// Maximum number of collision particles that can be active simultaneously.
  ///
  /// Collision particles appear when balls hit pegs, providing visual feedback
  /// for impacts. This limit ensures smooth performance during high collision
  /// scenarios.
  static const int maxCollisionParticles = 50;

  // Performance Targets
  // ------------------

  /// Target frames per second for smooth gameplay.
  ///
  /// The game engine aims to maintain this FPS through adaptive quality
  /// adjustments and performance monitoring.
  static const int targetFPS = 60;

  /// Target frame time in milliseconds for 60 FPS.
  ///
  /// Calculated as 1000ms / 60fps = 16.67ms per frame. Used to measure
  /// whether the game is meeting performance targets.
  static const double targetFrameTime = 16.67;

  // Quality Thresholds
  // -----------------

  /// Minimum FPS threshold to maintain High quality graphics.
  ///
  /// If FPS drops below this value, quality will be reduced to Medium.
  static const int fpsThresholdHigh = 60;

  /// Minimum FPS threshold to maintain Medium quality graphics.
  ///
  /// If FPS drops below this value, quality will be reduced to Low.
  /// If FPS rises above [fpsThresholdHigh], quality increases to High.
  static const int fpsThresholdMedium = 55;

  /// Minimum FPS threshold to maintain Low quality graphics.
  ///
  /// If FPS drops below this value, additional performance optimizations
  /// may be needed. If FPS rises above [fpsThresholdMedium], quality
  /// increases to Medium.
  static const int fpsThresholdLow = 50;

  // Animation Durations
  // ------------------

  /// Lifetime of trail particles in seconds.
  ///
  /// Trail particles fade out over this duration, creating a smooth
  /// motion blur effect behind moving balls.
  static const double particleTrailLifetime = 0.5;

  /// Lifetime of collision particles in seconds.
  ///
  /// Collision particles expand and fade out over this duration when
  /// balls impact pegs, providing brief visual feedback.
  static const double particleCollisionLifetime = 0.3;

  /// Duration of glow animation cycles in seconds.
  ///
  /// Special pegs and highlighted elements pulse with a glow effect
  /// over this duration, drawing player attention to important game
  /// elements.
  static const double glowAnimationDuration = 2.0;

  // Quality-Based Multipliers
  // -------------------------

  /// Get the particle count multiplier for a given quality level.
  ///
  /// Returns a value between 0.0 and 1.0 that should be multiplied with
  /// max particle counts to adjust for the current quality setting.
  static double getParticleMultiplier(GraphicsQuality quality) {
    switch (quality) {
      case GraphicsQuality.high:
        return 1.0; // 100% of max particles
      case GraphicsQuality.medium:
        return 0.6; // 60% of max particles
      case GraphicsQuality.low:
        return 0.3; // 30% of max particles
    }
  }

  /// Get the quality level based on current FPS.
  ///
  /// Automatically determines the appropriate quality level by comparing
  /// the current FPS against defined thresholds.
  static GraphicsQuality getQualityFromFPS(double currentFPS) {
    if (currentFPS >= fpsThresholdHigh) {
      return GraphicsQuality.high;
    } else if (currentFPS >= fpsThresholdMedium) {
      return GraphicsQuality.medium;
    } else {
      return GraphicsQuality.low;
    }
  }

  /// Get the effective maximum trail particles for a quality level.
  ///
  /// Applies the quality multiplier to [maxTrailParticles] to return
  /// the actual limit that should be enforced.
  static int getEffectiveTrailParticles(GraphicsQuality quality) {
    return (maxTrailParticles * getParticleMultiplier(quality)).round();
  }

  /// Get the effective maximum collision particles for a quality level.
  ///
  /// Applies the quality multiplier to [maxCollisionParticles] to return
  /// the actual limit that should be enforced.
  static int getEffectiveCollisionParticles(GraphicsQuality quality) {
    return (maxCollisionParticles * getParticleMultiplier(quality)).round();
  }
}
