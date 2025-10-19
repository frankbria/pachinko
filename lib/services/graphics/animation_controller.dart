/// Animation state tracking and curve definitions for game animations
library;

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
