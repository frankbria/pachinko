import 'dart:ui';
import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';
import '../utils/constants.dart';

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
  double _shimmerTime = 0.0; // Seconds of shimmer shown so far
  double _hitAnimationTimer = 0.0; // Timer for hit animation (in seconds)
  static const double _hitAnimationDuration = 0.8; // 800ms

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
        return GameConstants.normalPegColor;
      case PegType.special:
        return GameConstants.specialPegColor;
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

  /// How soon after a hit a peg answers another one. Every bounce flashes
  /// and sounds; the pause keeps a ball that rests or rolls on a peg from
  /// firing it on every frame.
  static const double refireDelay = 0.15;

  /// Whether a peg that has been hit is ready to flash and sound again.
  bool get canFireAgain =>
      hasBeenHit && _hitAnimationTimer <= _hitAnimationDuration - refireDelay;

  /// A ball has bounced off the peg: its flash starts, afresh if one was
  /// running. The first hit is what collects a prize peg. A hit that comes
  /// inside the pause after the last one changes nothing.
  void onHit() {
    if (hasBeenHit && !canFireAgain) return;

    hasBeenHit = true;
    isAnimating = true;
    pulseProgress = 0.0;
    _hitAnimationTimer = _hitAnimationDuration; // Start timer at full duration

    if (type == PegType.special && isHighlighted) {
      isHighlighted = false;
    }
  }

  void reset() {
    hasBeenHit = false;
    isAnimating = false;
    pulseProgress = 0.0;
    shimmerIntensity = 0.0;
    _shimmerTime = 0.0;
    _hitAnimationTimer = 0.0;

    if (type == PegType.special) {
      isHighlighted = true;
      isAnimating = true; // Restart shimmer
    }
  }

  /// Update animation state based on time
  void updateAnimation(double deltaTime) {
    // Handle pulse animation (on hit) - 800ms fade-back duration
    if (_hitAnimationTimer > 0.0) {
      _hitAnimationTimer -= deltaTime;

      if (_hitAnimationTimer <= 0.0) {
        // Animation complete - reset to normal
        _hitAnimationTimer = 0.0;
        pulseProgress = 1.0;
        isAnimating = false;
      } else {
        // Calculate progress (0.0 -> 1.0 as timer counts down)
        pulseProgress = 1.0 - (_hitAnimationTimer / _hitAnimationDuration);
      }
    }

    // Handle shimmer animation (special pegs)
    if (type == PegType.special && isHighlighted && !hasBeenHit) {
      // Sine wave shimmer effect, timed by the frames drawn rather than the
      // wall clock so that a rendered frame can be reproduced
      _shimmerTime += deltaTime;
      shimmerIntensity = 0.3 + 0.3 * math.sin(_shimmerTime * 2.0);
    } else {
      shimmerIntensity = 0.0;
    }
  }

  /// What a prize peg looks like once it has been collected: its gold dimmed
  /// towards the cabinet, so that the pegs still to win stand out.
  static final Color collectedPrizeColor = Color.lerp(
      GameConstants.specialPegColor, GameConstants.cabinetColor, 0.55)!;

  /// Whether this is a prize peg that has been hit on this level.
  bool get isCollected => type == PegType.special && hasBeenHit;

  /// The colour to draw the peg in: its own, or the dimmed gold of a
  /// collected prize, brightened towards the ink colour while its hit flash
  /// runs. A prize peg's shimmer is not in its colour; the board shows it in
  /// the halo and rings around the peg.
  Color get renderColor {
    final baseColor = isCollected ? collectedPrizeColor : color;

    // pulseProgress: 0.0 at the hit, 1.0 when the flash is over
    if (hasBeenHit && isAnimating && pulseProgress < 1.0) {
      return Color.lerp(
          baseColor, GameConstants.inkColor, (1.0 - pulseProgress) * 0.7)!;
    }
    return baseColor;
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
