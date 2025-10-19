/// Performance monitoring for graphics rendering and FPS tracking.
///
/// This class tracks frame timing metrics and calculates FPS to enable
/// adaptive quality adjustments. Maintains a circular buffer of recent
/// frame times for accurate moving averages.
library;

import '../../utils/graphics_config.dart';

/// Tracks performance metrics for graphics rendering.
///
/// Monitors frame times and calculates FPS to inform quality level
/// decisions. Uses a circular buffer to maintain recent history while
/// avoiding unbounded memory growth.
class PerformanceMetrics {
  /// Circular buffer of recent frame times in milliseconds.
  ///
  /// Maintains the last 60 frame time measurements (1 second at 60 FPS)
  /// for calculating moving averages and current FPS. Older entries are
  /// overwritten when the buffer is full.
  final List<double> frameTimes;

  /// Current frames per second calculated from recent frame times.
  ///
  /// Updated each frame based on the moving average of frame times.
  /// Used to determine appropriate graphics quality level.
  double currentFPS;

  /// Moving average of frame times in milliseconds.
  ///
  /// Calculated from the [frameTimes] buffer to smooth out temporary
  /// performance spikes and provide stable quality adjustment decisions.
  double averageFrameTime;

  /// Target frame time in milliseconds for 60 FPS.
  ///
  /// Set to 16.67ms (1000ms / 60fps). Used as a reference to measure
  /// whether the game is meeting performance targets.
  final double targetFrameTime;

  /// Current graphics quality level based on performance.
  ///
  /// Automatically adjusted based on [currentFPS] to maintain smooth
  /// gameplay. Higher quality uses more particles and effects, while
  /// lower quality prioritizes performance.
  GraphicsQuality qualityLevel;

  /// Creates a new performance metrics tracker.
  ///
  /// Initializes with default values:
  /// - Empty frame times buffer (capacity 60)
  /// - 60 FPS starting point
  /// - Target frame time of 16.67ms
  /// - High quality level (will adjust based on actual performance)
  PerformanceMetrics()
      : frameTimes = [],
        currentFPS = 60.0,
        averageFrameTime = GraphicsConfig.targetFrameTime,
        targetFrameTime = GraphicsConfig.targetFrameTime,
        qualityLevel = GraphicsQuality.high;

  /// Creates a performance metrics tracker with custom initial values.
  ///
  /// Used primarily for testing or custom initialization scenarios.
  PerformanceMetrics.custom({
    List<double>? frameTimes,
    this.currentFPS = 60.0,
    this.averageFrameTime = GraphicsConfig.targetFrameTime,
    this.targetFrameTime = GraphicsConfig.targetFrameTime,
    this.qualityLevel = GraphicsQuality.high,
  }) : frameTimes = frameTimes ?? [];

  /// Maximum capacity of the frame times circular buffer.
  ///
  /// Set to 60 to track one second of frame history at 60 FPS.
  static const int frameTimeBufferCapacity = 60;

  // Methods will be added in tasks T033-T035:
  // - recordFrameTime(double deltaTime)
  // - updateQualityLevel()
  // - reset()
}
