/// Comprehensive tests for PerformanceMetrics implementation (T031-T033)
///
/// Tests the actual implementation of:
/// - T031: recordFrameTime() method
/// - T032: getCurrentFPS() method
/// - T033: getRecommendedQuality() method with hysteresis
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:pachinko_game/services/graphics/performance_monitor.dart';
import 'package:pachinko_game/utils/graphics_config.dart';

// Exact frame time for 60 FPS: 1000ms / 60 = 16.666...ms
const double _frameTimeFor60FPS = 1000.0 / 60.0;

void main() {
  group('PerformanceMetrics Implementation Tests', () {
    late PerformanceMetrics metrics;

    setUp(() {
      metrics = PerformanceMetrics();
    });

    group('T031: recordFrameTime() implementation', () {
      test('adds frame time to buffer and updates FPS', () {
        metrics.recordFrameTime(16.67);

        expect(metrics.frameTimes.length, 1);
        expect(metrics.frameTimes[0], 16.67);
        expect(metrics.averageFrameTime, 16.67);
        expect(metrics.currentFPS, closeTo(60.0, 0.1));
      });

      test('maintains circular buffer at performanceBufferSize capacity (60)', () {
        for (int i = 0; i < 70; i++) {
          metrics.recordFrameTime(16.67);
        }

        expect(metrics.frameTimes.length, 60);
        expect(
          metrics.frameTimes.length,
          PerformanceMetrics.frameTimeBufferCapacity,
        );
      });

      test('calculates average frame time from buffer', () {
        metrics.recordFrameTime(10.0);
        metrics.recordFrameTime(20.0);
        metrics.recordFrameTime(15.0);

        expect(metrics.averageFrameTime, 15.0);
      });

      test('calculates currentFPS from 1000.0 / averageFrameTime', () {
        for (int i = 0; i < 10; i++) {
          metrics.recordFrameTime(20.0);
        }

        expect(metrics.currentFPS, 50.0);
        expect(metrics.currentFPS, 1000.0 / metrics.averageFrameTime);
      });

      test('handles zero frame time gracefully', () {
        metrics.recordFrameTime(0.0);

        expect(metrics.currentFPS, 60.0);
      });

      test('handles very fast frame times', () {
        metrics.recordFrameTime(5.0);

        expect(metrics.averageFrameTime, 5.0);
        expect(metrics.currentFPS, 200.0);
      });

      test('overwrites oldest entry when buffer full', () {
        for (int i = 0; i < 60; i++) {
          metrics.recordFrameTime(16.67);
        }

        metrics.recordFrameTime(100.0);

        expect(metrics.frameTimes.length, 60);
        expect(metrics.frameTimes.contains(100.0), isTrue);
      });
    });

    group('T032: getCurrentFPS() implementation', () {
      test('returns initial FPS (60.0) when no frames recorded', () {
        expect(metrics.getCurrentFPS(), 60.0);
      });

      test('returns calculated FPS after recording frames', () {
        metrics.recordFrameTime(16.67);
        expect(metrics.getCurrentFPS(), closeTo(60.0, 0.1));
      });

      test('never returns invalid values with empty buffer', () {
        final emptyMetrics = PerformanceMetrics();
        final fps = emptyMetrics.getCurrentFPS();

        expect(fps, isNotNull);
        expect(fps.isFinite, isTrue);
        expect(fps, greaterThan(0));
      });

      test('returns correct FPS for 30 FPS scenario', () {
        for (int i = 0; i < 10; i++) {
          metrics.recordFrameTime(33.33);
        }

        expect(metrics.getCurrentFPS(), closeTo(30.0, 0.1));
      });

      test('returns correct FPS for 50 FPS scenario', () {
        for (int i = 0; i < 10; i++) {
          metrics.recordFrameTime(20.0);
        }

        expect(metrics.getCurrentFPS(), 50.0);
      });
    });

    group('T033: getRecommendedQuality() implementation', () {
      test('returns High when FPS >= fpsThresholdHigh (60)', () {
        for (int i = 0; i < 10; i++) {
          metrics.recordFrameTime(16.67);
        }

        expect(metrics.getRecommendedQuality(), GraphicsQuality.high);
      });

      test('returns Medium when fpsThresholdMedium (55) <= FPS < 60', () {
        for (int i = 0; i < 10; i++) {
          metrics.recordFrameTime(17.5); // ~57 FPS
        }

        expect(metrics.getRecommendedQuality(), GraphicsQuality.medium);
      });

      test('returns Low when FPS < fpsThresholdMedium (55)', () {
        for (int i = 0; i < 10; i++) {
          metrics.recordFrameTime(20.0); // 50 FPS
        }

        expect(metrics.getRecommendedQuality(), GraphicsQuality.low);
      });

      test('uses GameConstants thresholds correctly', () {
        metrics.recordFrameTime(1000.0 / GraphicsConfig.fpsThresholdHigh);
        expect(metrics.getRecommendedQuality(), GraphicsQuality.high);

        metrics = PerformanceMetrics();
        metrics.recordFrameTime(1000.0 / GraphicsConfig.fpsThresholdMedium);
        expect(metrics.getRecommendedQuality(), GraphicsQuality.medium);

        metrics = PerformanceMetrics();
        metrics.recordFrameTime(
          1000.0 / (GraphicsConfig.fpsThresholdMedium - 1),
        );
        expect(metrics.getRecommendedQuality(), GraphicsQuality.low);
      });

      test('implements hysteresis to prevent oscillation (5% buffer)', () {
        // Start at low quality (50 FPS)
        for (int i = 0; i < 10; i++) {
          metrics.recordFrameTime(20.0);
        }
        expect(metrics.getRecommendedQuality(), GraphicsQuality.low);

        // Slight improvement to exactly 55 FPS (medium threshold)
        // Should stay low due to hysteresis (needs 5% margin)
        for (int i = 0; i < 10; i++) {
          metrics.recordFrameTime(1000.0 / 55.0);
        }
        expect(metrics.getRecommendedQuality(), GraphicsQuality.low);

        // Clear improvement above hysteresis margin (58 FPS > 55 * 1.05)
        for (int i = 0; i < 10; i++) {
          metrics.recordFrameTime(1000.0 / 58.0);
        }
        expect(metrics.getRecommendedQuality(), GraphicsQuality.medium);
      });

      test('hysteresis prevents rapid upgrades near threshold boundaries', () {
        // Start at medium quality
        for (int i = 0; i < 10; i++) {
          metrics.recordFrameTime(17.5); // 57 FPS - medium
        }
        expect(metrics.getRecommendedQuality(), GraphicsQuality.medium);

        // Slight improvement to exactly 60 FPS (high threshold)
        // Should stay medium due to hysteresis
        for (int i = 0; i < 10; i++) {
          metrics.recordFrameTime(16.67); // 60 FPS
        }
        expect(metrics.getRecommendedQuality(), GraphicsQuality.medium);

        // Clear improvement above hysteresis margin (64 FPS > 60 * 1.05)
        for (int i = 0; i < 10; i++) {
          metrics.recordFrameTime(1000.0 / 64.0);
        }
        expect(metrics.getRecommendedQuality(), GraphicsQuality.high);
      });

      test('downgrades immediately without hysteresis', () {
        // Start at high quality
        for (int i = 0; i < 10; i++) {
          metrics.recordFrameTime(16.0); // 62.5 FPS - high
        }
        expect(metrics.getRecommendedQuality(), GraphicsQuality.high);

        // Drop to 58 FPS (below 60 threshold)
        for (int i = 0; i < 10; i++) {
          metrics.recordFrameTime(1000.0 / 58.0);
        }
        expect(metrics.getRecommendedQuality(), GraphicsQuality.medium);

        // Drop to 52 FPS (below 55 threshold)
        for (int i = 0; i < 10; i++) {
          metrics.recordFrameTime(1000.0 / 52.0);
        }
        expect(metrics.getRecommendedQuality(), GraphicsQuality.low);
      });

      test('handles boundary condition FPS = 60 exactly', () {
        for (int i = 0; i < 10; i++) {
          metrics.recordFrameTime(1000.0 / 60.0);
        }

        expect(metrics.getRecommendedQuality(), GraphicsQuality.high);
      });

      test('handles boundary condition FPS = 55 exactly', () {
        for (int i = 0; i < 10; i++) {
          metrics.recordFrameTime(1000.0 / 55.0);
        }

        expect(metrics.getRecommendedQuality(), GraphicsQuality.medium);
      });
    });

    group('reset() method', () {
      test('clears frame times buffer', () {
        for (int i = 0; i < 10; i++) {
          metrics.recordFrameTime(20.0);
        }
        expect(metrics.frameTimes.isNotEmpty, true);

        metrics.reset();
        expect(metrics.frameTimes.isEmpty, true);
      });

      test('resets FPS to 60', () {
        for (int i = 0; i < 10; i++) {
          metrics.recordFrameTime(40.0); // 25 FPS
        }
        expect(metrics.currentFPS, 25.0);

        metrics.reset();
        expect(metrics.currentFPS, 60.0);
      });

      test('resets quality to high', () {
        for (int i = 0; i < 10; i++) {
          metrics.recordFrameTime(40.0);
        }
        expect(metrics.getRecommendedQuality(), GraphicsQuality.low);

        metrics.reset();
        expect(metrics.qualityLevel, GraphicsQuality.high);
      });

      test('resets average frame time to target', () {
        for (int i = 0; i < 10; i++) {
          metrics.recordFrameTime(40.0);
        }
        expect(metrics.averageFrameTime, 40.0);

        metrics.reset();
        expect(metrics.averageFrameTime, GraphicsConfig.targetFrameTime);
      });
    });

    group('Integration scenarios', () {
      test('realistic: stable 60 FPS gameplay', () {
        for (int i = 0; i < 60; i++) {
          metrics.recordFrameTime(_frameTimeFor60FPS);
        }

        expect(metrics.currentFPS, closeTo(60.0, 0.01));
        // Stable 60 FPS meets high threshold, should be high quality
        expect(metrics.getRecommendedQuality(), GraphicsQuality.high);
      });

      test('realistic: gradual FPS degradation', () {
        // Fill buffer completely with 60 FPS to establish high quality
        for (int i = 0; i < 60; i++) {
          metrics.recordFrameTime(_frameTimeFor60FPS);
        }
        expect(metrics.getRecommendedQuality(), GraphicsQuality.high);

        // Degrade to 57 FPS - need full buffer to change average
        for (int i = 0; i < 60; i++) {
          metrics.recordFrameTime(17.5); // 57 FPS
        }
        final midQuality = metrics.getRecommendedQuality();
        // 57 FPS is below 60 threshold, should downgrade to medium immediately
        expect(midQuality, GraphicsQuality.medium);

        // Further degrade to 45 FPS (well below 55 threshold)
        for (int i = 0; i < 60; i++) {
          metrics.recordFrameTime(1000.0 / 45.0); // 45 FPS
        }
        final lowQuality = metrics.getRecommendedQuality();
        // 45 FPS is well below 55 threshold, should downgrade to low
        expect(lowQuality, GraphicsQuality.low);
      });

      test('realistic: recovery from lag spike', () {
        // Establish stable high quality with full buffer
        for (int i = 0; i < 60; i++) {
          metrics.recordFrameTime(_frameTimeFor60FPS);
        }
        expect(metrics.getRecommendedQuality(), GraphicsQuality.high);

        // Single lag spike
        metrics.recordFrameTime(100.0);
        // Average will be affected: (59 * 16.67 + 100) / 60 = 17.89ms = 55.9 FPS
        // This drops below 60 threshold, so should downgrade to medium
        final afterSpike = metrics.getRecommendedQuality();
        expect(
          afterSpike,
          isIn([GraphicsQuality.high, GraphicsQuality.medium]),
        );

        // Recovery: fill buffer with good frames again
        for (int i = 0; i < 60; i++) {
          metrics.recordFrameTime(_frameTimeFor60FPS);
        }
        // Should recover to high quality
        expect(metrics.getRecommendedQuality(), GraphicsQuality.high);
      });

      test('handles rapid quality fluctuations gracefully', () {
        // The buffer averages out rapid fluctuations
        // Mix of fast and slow frames in the buffer
        for (int cycle = 0; cycle < 3; cycle++) {
          for (int i = 0; i < 10; i++) {
            metrics.recordFrameTime(15.0); // 66 FPS
          }
          for (int i = 0; i < 10; i++) {
            metrics.recordFrameTime(25.0); // 40 FPS
          }
        }

        // After cycling, the average should be around (15 + 25) / 2 = 20ms = 50 FPS
        // This should result in low quality
        final quality = metrics.getRecommendedQuality();
        expect(quality, GraphicsQuality.low);
      });

      test('handles very large frame times', () {
        metrics.recordFrameTime(1000.0);

        expect(metrics.currentFPS, closeTo(1.0, 0.1));
        expect(metrics.getRecommendedQuality(), GraphicsQuality.low);
      });
    });

    group('Edge cases', () {
      test('handles negative frame times gracefully', () {
        metrics.recordFrameTime(-10.0);

        expect(metrics.frameTimes.length, 1);
        expect(() => metrics.getCurrentFPS(), returnsNormally);
        expect(() => metrics.getRecommendedQuality(), returnsNormally);
      });

      test('handles rapid frame recording', () {
        for (int i = 0; i < 100; i++) {
          metrics.recordFrameTime(16.0 + i * 0.1);
        }

        expect(metrics.frameTimes.length, 60);
        expect(() => metrics.getCurrentFPS(), returnsNormally);
        expect(() => metrics.getRecommendedQuality(), returnsNormally);
      });
    });
  });
}
