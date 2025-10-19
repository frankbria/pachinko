import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Renders a pulsing glow effect at a specified position
///
/// Used for special peg animations, bonus effects, and visual feedback.
/// Supports animated intensity for smooth pulsing effects driven by AnimationController.
///
/// Example usage:
/// ```dart
/// GlowEffect(
///   position: Offset(100, 100),
///   radius: 25.0,
///   color: Colors.yellow,
///   intensity: 0.8, // 0.0 = invisible, 1.0 = full glow
/// )
/// ```
class GlowEffect extends StatelessWidget {
  /// Center position of the glow effect
  final Offset position;

  /// Base radius of the glow in pixels
  final double radius;

  /// Base color of the glow effect
  final Color color;

  /// Glow intensity from 0.0 (invisible) to 1.0 (full strength)
  ///
  /// This value is typically driven by an AnimationController for smooth pulsing.
  /// Values outside 0.0-1.0 are clamped automatically.
  final double intensity;

  const GlowEffect({
    super.key,
    required this.position,
    required this.radius,
    required this.color,
    required this.intensity,
  });

  @override
  Widget build(BuildContext context) {
    // Clamp intensity to valid range
    final clampedIntensity = intensity.clamp(0.0, 1.0);

    // Don't render if intensity is effectively zero
    if (clampedIntensity < 0.01) {
      return const SizedBox.shrink();
    }

    return CustomPaint(
      painter: _GlowEffectPainter(
        position: position,
        radius: radius,
        color: color,
        intensity: clampedIntensity,
      ),
    );
  }
}

/// Custom painter for rendering glow effects with radial gradients
///
/// Creates a soft, blurred glow using radial gradients with multiple color stops
/// for smooth falloff from bright center to transparent edges.
class _GlowEffectPainter extends CustomPainter {
  final Offset position;
  final double radius;
  final Color color;
  final double intensity;

  _GlowEffectPainter({
    required this.position,
    required this.radius,
    required this.color,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate effective radius based on intensity
    // Glow expands slightly at higher intensity for more dramatic effect
    final effectiveRadius = radius * (1.0 + intensity * 0.3);

    // Create radial gradient for glow effect
    // Multiple color stops create smooth falloff
    final gradient = ui.Gradient.radial(
      position,
      effectiveRadius,
      [
        // Bright center (full opacity modulated by intensity)
        color.withOpacity(intensity * 0.9),
        // Mid-range (50% opacity modulated by intensity)
        color.withOpacity(intensity * 0.5),
        // Edge transition (25% opacity)
        color.withOpacity(intensity * 0.25),
        // Outer edge (fade to transparent)
        color.withOpacity(0.0),
      ],
      [
        0.0, // Center
        0.4, // Inner glow region
        0.7, // Mid glow region
        1.0, // Outer edge
      ],
    );

    // Create paint with gradient and blur
    final paint = Paint()
      ..shader = gradient
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        radius * 0.5 * intensity, // Blur scales with intensity
      );

    // Draw glow circle
    canvas.drawCircle(position, effectiveRadius, paint);
  }

  @override
  bool shouldRepaint(_GlowEffectPainter oldDelegate) {
    // Repaint when any property changes
    return oldDelegate.position != position ||
        oldDelegate.radius != radius ||
        oldDelegate.color != color ||
        oldDelegate.intensity != intensity;
  }
}
