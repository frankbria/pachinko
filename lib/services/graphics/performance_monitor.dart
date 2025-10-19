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

  /// Records a frame time measurement and updates FPS.
  ///
  /// Maintains a circular buffer of frame times (limited to [frameTimeBufferCapacity])
  /// and recalculates [currentFPS] and [averageFrameTime] based on the buffer.
  ///
  /// [frameTime] - The time taken to render this frame in milliseconds.
  void recordFrameTime(double frameTime) {
    // Add frame time to buffer
    frameTimes.add(frameTime);

    // Maintain buffer size limit (circular buffer behavior)
    if (frameTimes.length > frameTimeBufferCapacity) {
      frameTimes.removeAt(0);
    }

    // Calculate average frame time from buffer
    if (frameTimes.isNotEmpty) {
      averageFrameTime = frameTimes.reduce((a, b) => a + b) / frameTimes.length;

      // Calculate FPS from average frame time (avoid division by zero)
      currentFPS = averageFrameTime > 0 ? 1000.0 / averageFrameTime : 60.0;
    }
  }

  /// Gets the current frames per second.
  ///
  /// Returns the FPS calculated from recent frame times. If no frame times
  /// have been recorded, returns the initial FPS value (60.0).
  double getCurrentFPS() {
    return currentFPS;
  }

  /// Recommends a graphics quality level based on current FPS with hysteresis.
  ///
  /// Uses a 5% buffer to prevent oscillation between quality levels when
  /// FPS fluctuates near threshold boundaries.
  ///
  /// Returns:
  /// - [GraphicsQuality.high] if FPS >= 60
  /// - [GraphicsQuality.medium] if FPS >= 55 and < 60
  /// - [GraphicsQuality.low] if FPS < 55
  ///
  /// Hysteresis prevents rapid quality changes: when downgrading, uses exact
  /// thresholds; when upgrading, requires 5% above threshold to switch.
  GraphicsQuality getRecommendedQuality() {
    // Get the basic quality level from FPS thresholds
    final basicQuality = GraphicsConfig.getQualityFromFPS(currentFPS);

    // Apply hysteresis to prevent oscillation
    // When upgrading quality, require FPS to be 5% above threshold
    if (basicQuality.index > qualityLevel.index) {
      // Trying to upgrade - check if we exceed threshold by hysteresis margin
      double hysteresisMargin = 1.05; // 5% buffer

      if (qualityLevel == GraphicsQuality.low &&
          currentFPS < GraphicsConfig.fpsThresholdMedium * hysteresisMargin) {
        return GraphicsQuality.low; // Stay low until clearly above medium threshold
      }

      if (qualityLevel == GraphicsQuality.medium &&
          currentFPS < GraphicsConfig.fpsThresholdHigh * hysteresisMargin) {
        return GraphicsQuality.medium; // Stay medium until clearly above high threshold
      }
    }

    // Update stored quality level
    qualityLevel = basicQuality;
    return qualityLevel;
  }

  /// Resets all performance metrics to initial values.
  ///
  /// Clears the frame time buffer and resets FPS to 60, quality to high.
  /// Useful when starting a new game session or after significant pauses.
  void reset() {
    frameTimes.clear();
    currentFPS = 60.0;
    averageFrameTime = targetFrameTime;
    qualityLevel = GraphicsQuality.high;
  }
}
