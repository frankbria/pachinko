/// Animation state tracking and curve definitions for game animations
library;

import 'dart:math' show pow;

/// Defines the interpolation curve for animation progression
enum AnimationCurve {
  /// Linear progression (constant speed)
  linear,

  /// Slow start, fast end
  easeIn,

  /// Fast start, slow end
  easeOut,

  /// Slow start and end, fast middle
  easeInOut,
}

/// Represents the state of an active animation
///
/// Tracks progress, timing, and configuration for individual animations.
/// Does not handle update logic - that will be added in T046.
class AnimationState {
  /// Unique identifier for this animation instance
  final String id;

  /// Total duration of the animation in seconds
  final double duration;

  /// Interpolation curve to apply to progress
  final AnimationCurve curve;

  /// Whether the animation should loop continuously
  final bool loop;

  /// Current progress through the animation (0.0 to 1.0)
  double progress;

  /// Time elapsed since animation started in seconds
  double elapsedTime;

  /// Whether the animation is currently progressing
  bool isRunning;

  /// Creates a new animation state
  ///
  /// [id] - Unique identifier for tracking this animation
  /// [duration] - Total duration in seconds (must be > 0)
  /// [curve] - Interpolation curve to apply (defaults to linear)
  /// [loop] - Whether to restart when reaching 1.0 progress (defaults to false)
  /// [progress] - Initial progress value (defaults to 0.0)
  /// [elapsedTime] - Initial elapsed time (defaults to 0.0)
  /// [isRunning] - Initial running state (defaults to true)
  AnimationState({
    required this.id,
    required this.duration,
    this.curve = AnimationCurve.linear,
    this.loop = false,
    this.progress = 0.0,
    this.elapsedTime = 0.0,
    this.isRunning = true,
  }) : assert(duration > 0, 'Animation duration must be greater than 0');

  /// Creates a copy of this animation state with optional field updates
  AnimationState copyWith({
    String? id,
    double? duration,
    AnimationCurve? curve,
    bool? loop,
    double? progress,
    double? elapsedTime,
    bool? isRunning,
  }) {
    return AnimationState(
      id: id ?? this.id,
      duration: duration ?? this.duration,
      curve: curve ?? this.curve,
      loop: loop ?? this.loop,
      progress: progress ?? this.progress,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      isRunning: isRunning ?? this.isRunning,
    );
  }

  @override
  String toString() {
    return 'AnimationState(id: $id, progress: ${progress.toStringAsFixed(2)}, '
        'duration: $duration, elapsed: ${elapsedTime.toStringAsFixed(2)}, '
        'curve: $curve, isRunning: $isRunning, loop: $loop)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AnimationState &&
        other.id == id &&
        other.duration == duration &&
        other.curve == curve &&
        other.loop == loop &&
        other.progress == progress &&
        other.elapsedTime == elapsedTime &&
        other.isRunning == isRunning;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      duration,
      curve,
      loop,
      progress,
      elapsedTime,
      isRunning,
    );
  }
}

/// Manages multiple concurrent animations with different curves and durations
///
/// Coordinates animation lifecycle, progress tracking, and value interpolation
/// for game effects like glowing pegs, fading UI elements, and particle trails.
class AnimationController {
  /// Map of animation ID to animation state
  final Map<String, AnimationState> _animations = {};

  /// Creates a new animation and registers it with the controller
  ///
  /// [id] - Unique identifier for this animation
  /// [duration] - Total duration in seconds (must be > 0)
  /// [curve] - Interpolation curve to apply (defaults to linear)
  /// [loop] - Whether to restart when reaching 1.0 progress (defaults to false)
  ///
  /// Returns the created animation state
  AnimationState createAnimation({
    required String id,
    required double duration,
    AnimationCurve curve = AnimationCurve.linear,
    bool loop = false,
  }) {
    final animation = AnimationState(
      id: id,
      duration: duration,
      curve: curve,
      loop: loop,
      isRunning: false, // Start paused until start() is called
    );
    _animations[id] = animation;
    return animation;
  }

  /// Starts or resumes an animation by ID
  ///
  /// If the animation is already running, this has no effect.
  /// If the animation doesn't exist, returns false.
  bool start(String id) {
    final animation = _animations[id];
    if (animation == null) return false;

    if (!animation.isRunning) {
      _animations[id] = animation.copyWith(isRunning: true);
    }
    return true;
  }

  /// Stops an animation by ID
  ///
  /// The animation's progress is preserved but it will not advance.
  bool stop(String id) {
    final animation = _animations[id];
    if (animation == null) return false;

    if (animation.isRunning) {
      _animations[id] = animation.copyWith(isRunning: false);
    }
    return true;
  }

  /// Gets the current interpolated value for an animation (0.0 to 1.0)
  ///
  /// Applies the animation's curve to the linear progress to produce
  /// an eased value suitable for rendering.
  ///
  /// Returns null if the animation doesn't exist.
  double? getValue(String id) {
    final animation = _animations[id];
    if (animation == null) return null;

    return _applyCurve(animation.progress, animation.curve);
  }

  /// Updates all running animations by the given time delta
  ///
  /// Advances elapsed time, recalculates progress, and handles looping.
  /// Non-running animations are not updated.
  ///
  /// [deltaTime] - Time elapsed since last update in seconds
  void update(double deltaTime) {
    final updatedAnimations = <String, AnimationState>{};

    for (final entry in _animations.entries) {
      final id = entry.key;
      final animation = entry.value;

      if (!animation.isRunning) {
        updatedAnimations[id] = animation;
        continue;
      }

      // Advance elapsed time
      var newElapsedTime = animation.elapsedTime + deltaTime;

      // Handle looping by wrapping elapsed time
      if (animation.loop && newElapsedTime >= animation.duration) {
        newElapsedTime = newElapsedTime % animation.duration;
      }

      // Calculate linear progress
      final linearProgress = (newElapsedTime / animation.duration).clamp(0.0, 1.0);

      // Handle non-looping stop condition
      if (!animation.loop && linearProgress >= 1.0) {
        // Stop at end
        updatedAnimations[id] = animation.copyWith(
          elapsedTime: animation.duration,
          progress: 1.0,
          isRunning: false,
        );
      } else {
        // Continue progressing (or looping)
        updatedAnimations[id] = animation.copyWith(
          elapsedTime: newElapsedTime,
          progress: linearProgress,
        );
      }
    }

    _animations.clear();
    _animations.addAll(updatedAnimations);
  }

  /// Applies an easing curve to a linear progress value
  ///
  /// [t] - Linear progress from 0.0 to 1.0
  /// [curve] - The curve type to apply
  ///
  /// Returns the eased progress value from 0.0 to 1.0
  double _applyCurve(double t, AnimationCurve curve) {
    switch (curve) {
      case AnimationCurve.linear:
        return t;
      case AnimationCurve.easeIn:
        return pow(t, 2.0).toDouble();
      case AnimationCurve.easeOut:
        return 1.0 - pow(1.0 - t, 2.0).toDouble();
      case AnimationCurve.easeInOut:
        if (t < 0.5) {
          return 2.0 * pow(t, 2.0).toDouble();
        } else {
          return 1.0 - 2.0 * pow(1.0 - t, 2.0).toDouble();
        }
    }
  }

  /// Removes an animation from the controller
  ///
  /// Returns true if the animation existed and was removed.
  bool removeAnimation(String id) {
    return _animations.remove(id) != null;
  }

  /// Gets all registered animation IDs
  List<String> get animationIds => _animations.keys.toList();

  /// Gets the count of registered animations
  int get animationCount => _animations.length;

  /// Checks if an animation exists
  bool hasAnimation(String id) => _animations.containsKey(id);
}