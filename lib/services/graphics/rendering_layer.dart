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
}
