import 'dart:ui';
import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';

enum PegType {
  normal,
  special,
  bonus,
}

class Peg {
  Vector2 position;
  double radius;
  PegType type;
  Color color;
  bool isHighlighted;
  bool hasBeenHit;

  // Animation state
  bool isAnimating = false;
  double pulseProgress = 0.0; // 0.0 to 1.0 for pulse animation
  double shimmerIntensity = 0.0; // 0.0 to 1.0 for special peg shimmer
  int _lastHitTime = 0;

  Peg({
    required this.position,
    this.radius = 12.0,
    this.type = PegType.normal,
    Color? color,
    this.isHighlighted = false,
    this.hasBeenHit = false,
  }) : color = color ?? _getDefaultColor(type) {
    // Special pegs start with shimmer
    if (type == PegType.special) {
      isHighlighted = true;
      isAnimating = true;
    }
  }

  static Color _getDefaultColor(PegType type) {
    switch (type) {
      case PegType.normal:
        return const Color(0xFF4CAF50); // Green
      case PegType.special:
        return const Color(0xFFFF9800); // Orange
      case PegType.bonus:
        return const Color(0xFFE91E63); // Pink
    }
  }

  bool checkCollision(Vector2 ballPosition, double ballRadius) {
    final distance = (position - ballPosition).length;
    return distance <= (radius + ballRadius);
  }

  Vector2 getCollisionNormal(Vector2 ballPosition) {
    final direction = ballPosition - position;
    return direction.normalized();
  }

  void onHit() {
    hasBeenHit = true;
    isAnimating = true;
    pulseProgress = 0.0;
    _lastHitTime = DateTime.now().millisecondsSinceEpoch;

    if (type == PegType.special) {
      isHighlighted = false;
    }
  }

  void reset() {
    hasBeenHit = false;
    isAnimating = false;
    pulseProgress = 0.0;
    shimmerIntensity = 0.0;

    if (type == PegType.special) {
      isHighlighted = true;
      isAnimating = true; // Restart shimmer
    }
  }

  /// Update animation state based on time
  void updateAnimation(double deltaTime) {
    // Handle pulse animation (on hit)
    if (pulseProgress < 1.0 && _lastHitTime > 0) {
      final elapsed = DateTime.now().millisecondsSinceEpoch - _lastHitTime;
      pulseProgress = (elapsed / 250.0).clamp(0.0, 1.0); // 250ms pulse duration

      if (pulseProgress >= 1.0) {
        isAnimating = false; // Pulse complete
      }
    }

    // Handle shimmer animation (special pegs)
    if (type == PegType.special && isHighlighted && !hasBeenHit) {
      // Sine wave shimmer effect
      shimmerIntensity = 0.3 + 0.3 * math.sin(DateTime.now().millisecondsSinceEpoch / 500.0);
    } else {
      shimmerIntensity = 0.0;
    }
  }

  Color get renderColor {
    if (type == PegType.special && isHighlighted) {
      // Apply shimmer intensity to yellow glow
      return Color.lerp(color, const Color(0xFFFFFF00), 0.5 + shimmerIntensity)!;
    }
    return hasBeenHit ? color.withOpacity(0.6) : color;
  }

  /// Get pulse glow radius for rendering
  double get pulseGlowRadius {
    if (pulseProgress > 0.0 && pulseProgress < 1.0) {
      // Expand then fade out
      return radius + (10.0 * pulseProgress);
    }
    return 0.0;
  }

  /// Get pulse glow opacity for rendering
  double get pulseGlowOpacity {
    if (pulseProgress > 0.0 && pulseProgress < 1.0) {
      // Fade out as pulse expands
      return 0.6 * (1.0 - pulseProgress);
    }
    return 0.0;
  }
}