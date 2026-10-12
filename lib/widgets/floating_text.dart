import 'package:flutter/material.dart';

/// Animated floating text for score feedback
///
/// Displays "+X points!" text that floats upward and fades out.
/// Used to provide visual feedback when balls land in scoring slots.
///
/// Animation behavior:
/// - Floats upward at 50 pixels per second
/// - Duration: 1.5 seconds total
/// - Fades out in last 0.5 seconds
/// - Auto-expires after duration completes
class FloatingText {
  final String text;
  final Offset startPosition;
  final Color color;

  /// The size of the text. A larger score gets larger type: see [sizeFor].
  final double fontSize;
  double opacity = 1.0;
  double yOffset = 0.0;
  double timer = 0.0;
  static const double duration = 1.5; // seconds

  FloatingText({
    required this.text,
    required this.startPosition,
    this.color = Colors.yellow,
    this.fontSize = 20.0,
  });

  /// The type size for a popup worth [points]: a 50 is a small response and
  /// a 2000 a large one.
  static double sizeFor(int points) {
    if (points >= 2000) return 32.0;
    if (points >= 1000) return 26.0;
    if (points >= 100) return 20.0;
    return 16.0;
  }

  /// Update animation state (call every frame)
  /// Returns true if animation complete
  bool update(double deltaTime) {
    timer += deltaTime;

    if (timer >= duration) {
      return true; // Animation complete
    }

    // Float upward
    yOffset = timer * 50.0; // 50 pixels per second

    // Fade out in last 0.5 seconds
    if (timer >= duration - 0.5) {
      opacity = (duration - timer) / 0.5;
    }

    return false;
  }

  Offset get currentPosition => Offset(
        startPosition.dx,
        startPosition.dy - yOffset,
      );
}
