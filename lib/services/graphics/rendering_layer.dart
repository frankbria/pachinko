import 'dart:ui';

/// Graphics rendering utility layer for Pachinko game.
///
/// Provides optimized Paint configurations and rendering utilities
/// for consistent visual quality across the game board.
///
/// Features:
/// - Anti-aliasing enabled by default for smooth graphics
/// - Pre-configured Paint objects for common use cases
/// - Flexible Paint factory method for custom configurations
class RenderingLayer {
  /// Creates a configured Paint object with specified parameters.
  ///
  /// This is the primary factory method for creating Paint objects
  /// with consistent settings across the game.
  ///
  /// Parameters:
  /// - [style]: The paint style (fill or stroke)
  /// - [color]: Optional color override (null uses default color)
  /// - [strokeWidth]: Width for stroke style (ignored if style is fill)
  /// - [antiAlias]: Enable anti-aliasing for smooth edges (default: true)
  ///
  /// Returns: A configured Paint object ready for rendering
  static Paint getPaint({
    required PaintingStyle style,
    Color? color,
    double? strokeWidth,
    bool antiAlias = true,
  }) {
    return Paint()
      ..style = style
      ..color = color ?? const Color(0xFF000000)
      ..strokeWidth = strokeWidth ?? 1.0
      ..isAntiAlias = antiAlias;
  }

  // ============================================================================
  // Pre-configured Paint Objects
  // ============================================================================

  /// Standard fill paint for solid shapes.
  ///
  /// Use this for pegs, balls, and other filled objects.
  /// Color should be set per-object for flexibility.
  static Paint get fillPaint => getPaint(
        style: PaintingStyle.fill,
        color: const Color(0xFF000000),
      );

  /// Standard stroke paint for outlines and borders.
  ///
  /// Use this for peg outlines, slot borders, and UI elements.
  /// Customize strokeWidth as needed for different line thicknesses.
  static Paint get strokePaint => getPaint(
        style: PaintingStyle.stroke,
        strokeWidth: 2.0,
      );

  /// Thin stroke paint for subtle outlines and grid lines.
  ///
  /// Use this for less prominent visual elements that need definition
  /// without overwhelming the design.
  static Paint get thinStrokePaint => getPaint(
        style: PaintingStyle.stroke,
        strokeWidth: 1.0,
      );

  /// Thick stroke paint for bold outlines and emphasis.
  ///
  /// Use this for important UI elements, selected states, or
  /// visual elements that need strong emphasis.
  static Paint get thickStrokePaint => getPaint(
        style: PaintingStyle.stroke,
        strokeWidth: 3.0,
      );

  /// Semi-transparent fill paint for overlays and effects.
  ///
  /// Use this for highlight effects, shadows, or UI overlays
  /// that need to blend with background elements.
  static Paint get overlayPaint => getPaint(
        style: PaintingStyle.fill,
        color: const Color(0x80000000), // 50% opacity black
      );

  /// No anti-aliasing fill paint for pixel-perfect rendering.
  ///
  /// Use this sparingly for cases where crisp pixel boundaries
  /// are required (e.g., pixel art style elements, debugging grids).
  static Paint get pixelPerfectPaint => getPaint(
        style: PaintingStyle.fill,
        antiAlias: false,
      );

  // ============================================================================
  // Rendering Methods
  // ============================================================================

  /// Renders a glow effect at the specified position with intensity modulation.
  ///
  /// Creates a radial gradient glow using multiple color stops for smooth falloff.
  /// The glow intensity can be animated for pulsing effects on special pegs.
  ///
  /// Parameters:
  /// - [canvas]: The canvas to draw on
  /// - [center]: Center position of the glow effect
  /// - [radius]: Base radius of the glow in pixels
  /// - [color]: Base color of the glow
  /// - [intensity]: Glow intensity from 0.0 (invisible) to 1.0 (full strength)
  ///
  /// Usage:
  /// ```dart
  /// RenderingLayer.renderGlowEffect(
  ///   canvas,
  ///   center: Offset(100, 100),
  ///   radius: 25.0,
  ///   color: Colors.yellow,
  ///   intensity: animationValue, // From AnimationController
  /// );
  /// ```
  static void renderGlowEffect(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Color color,
    required double intensity,
  }) {
    // Clamp intensity to valid range
    final clampedIntensity = intensity.clamp(0.0, 1.0);

    // Early exit if intensity is effectively zero (performance optimization)
    if (clampedIntensity < 0.01) {
      return;
    }

    // Calculate effective radius based on intensity
    // Glow expands slightly at higher intensity for more dramatic effect
    final effectiveRadius = radius * (1.0 + clampedIntensity * 0.3);

    // Create radial gradient for glow effect
    // Multiple color stops create smooth falloff from center to edge
    final gradient = Gradient.radial(
      center,
      effectiveRadius,
      [
        // Bright center (full opacity modulated by intensity)
        color.withOpacity(clampedIntensity * 0.9),
        // Mid-range (50% opacity modulated by intensity)
        color.withOpacity(clampedIntensity * 0.5),
        // Edge transition (25% opacity)
        color.withOpacity(clampedIntensity * 0.25),
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
        radius * 0.5 * clampedIntensity, // Blur scales with intensity
      );

    // Draw glow circle
    canvas.drawCircle(center, effectiveRadius, paint);
  }
}