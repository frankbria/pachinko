# Research: Graphics Architecture Overhaul

**Phase**: 0 (Outline & Research)
**Date**: 2025-10-18
**Status**: Complete

## Research Questions

### Q1: Visual Testing for Flutter Desktop Applications

**Context**: Technical Context requires clarification on "Playwright adaptation for Flutter or alternative visual testing tool"

**Decision**: Use Flutter's built-in golden test framework with integration testing

**Rationale**:
- Playwright is designed for web browsers and doesn't support Flutter desktop directly
- Flutter provides `matchesGoldenFile()` for pixel-perfect screenshot comparison (visual regression testing)
- Flutter integration testing supports frame rate measurement via `binding.renderDuration` and `binding.drawDuration`
- No additional dependencies required beyond `flutter_test` (already in project)
- Maintains consistency with existing Flutter test infrastructure

**Alternatives Considered**:
1. **Playwright via WebView embedding**: Rejected - adds unnecessary complexity, doesn't test actual Flutter rendering
2. **Appium for Flutter**: Rejected - overkill for visual testing, primarily for mobile UI automation
3. **Custom screenshot comparison tool**: Rejected - reinventing golden test functionality

**Implementation Approach**:
- Golden tests for visual regression (`test/integration/visual_regression_test.dart`)
- Integration tests with performance measurement for frame rate validation
- Widget tests with animation timeline inspection for timing verification

---

### Q2: Particle System Architecture for 60 FPS Performance

**Context**: Need to determine optimal particle system design for Flutter Canvas rendering at 60 FPS

**Decision**: Object pooling with fixed-size particle arrays and spatial partitioning

**Rationale**:
- Object pooling eliminates GC pressure from particle creation/destruction
- Fixed-size arrays (max 100 particles as per NFR) prevent unbounded memory growth
- Spatial partitioning reduces collision detection overhead (though particles don't collide with each other)
- Flutter's `CustomPainter` supports efficient batch drawing when particles share paint properties

**Alternatives Considered**:
1. **Dynamic list with on-demand allocation**: Rejected - causes GC pauses affecting frame rate
2. **GPU-accelerated particles via shaders**: Rejected - overkill for 2D game, adds complexity
3. **Sprite-based particles**: Rejected - Canvas drawing more flexible for effects like trails

**Implementation Approach**:
- `ParticlePool` class managing reusable particle instances
- `ParticleSystem` coordinating multiple pools (trail particles vs collision particles)
- Update loop integrated with existing 60 FPS physics tick
- Batch rendering in `CustomPainter.paint()` to minimize draw calls

---

### Q3: Animation System Integration with Existing Game Loop

**Context**: Need to integrate smooth animations without disrupting existing 60 FPS physics engine

**Decision**: Separate animation timeline using Flutter's Animation Controller integrated with existing Provider state management

**Rationale**:
- Existing game uses custom 60 FPS physics loop - don't disrupt working system
- Flutter's `AnimationController` provides built-in easing curves and frame callbacks
- Provider pattern already used for state management - extend for animation state
- Allows independent animation timing (e.g., 2-second glow pulse) from physics timestep

**Alternatives Considered**:
1. **Manual animation in physics loop**: Rejected - mixes concerns, hard to test animations independently
2. **ImplicitlyAnimatedWidget approach**: Rejected - less control for game-specific effects
3. **Rive or Lottie animations**: Rejected - overkill for simple glow/fade effects

**Implementation Approach**:
- `AnimationController` class managing multiple concurrent animations (glow, fade, etc.)
- Separate update callbacks for animations vs physics
- Animation state exposed via Provider for reactive UI updates
- Test animations in isolation using `WidgetTester.pumpAndSettle()`

---

### Q4: Anti-Aliasing Configuration in Flutter Canvas

**Context**: FR-001 requires anti-aliasing for all game elements; need to verify Flutter support

**Decision**: Use `Paint.isAntiAlias = true` for all rendering operations

**Rationale**:
- Flutter's Skia-based rendering engine supports anti-aliasing via Paint.isAntiAlias property
- Enabled by default in most cases, but explicit setting ensures consistency
- No performance penalty on modern hardware (GPU-accelerated)
- Applies to both strokes and fills

**Alternatives Considered**:
1. **Manual sub-pixel positioning**: Rejected - unnecessary, anti-aliasing handles this
2. **Higher resolution rendering with downsampling**: Rejected - wastes memory and GPU resources

**Implementation Approach**:
- Create `RenderingLayer` utility class with pre-configured Paint objects
- All drawing operations use centralized Paint configuration
- Verify anti-aliasing in widget tests by checking Paint properties

---

### Q5: Performance Monitoring and Adaptive Quality

**Context**: NFR requirements for graceful degradation below target FPS; need monitoring strategy

**Decision**: Use Flutter DevTools performance overlay for development, custom performance monitor for runtime adaptation

**Rationale**:
- Flutter provides `PerformanceOverlay` widget showing FPS in real-time during development
- `WidgetsBinding.instance.drawFrame` duration indicates render performance
- Can implement simple moving average of frame times for smooth adaptation decisions
- Adaptation strategy: reduce particle count when frame time > 18ms (55 FPS threshold)

**Alternatives Considered**:
1. **Third-party performance monitoring SDK**: Rejected - adds dependency, overkill for single metric
2. **No runtime adaptation**: Rejected - violates NFR-001 graceful degradation requirement

**Implementation Approach**:
- `PerformanceMonitor` class tracking last N frame durations
- Moving average calculation to avoid jitter in quality decisions
- Adaptive particle cap: 100 particles @ 60 FPS, scale down to 50 @ 55 FPS, 25 @ 50 FPS
- Expose performance metrics via Provider for debugging UI

---

## Technology Stack Summary

Based on research, final technical context:

**Language/Version**: Dart 3.5.4+
**Primary Dependencies**:
  - Flutter 3.24.5+ (framework)
  - vector_math 2.1.4+ (existing, for particle velocity calculations)
  - provider 6.1.0+ (existing state management)
  - flutter_test (built-in, for golden tests and integration testing)

**Testing Tools**:
  - Golden tests for visual regression (matchesGoldenFile)
  - Integration tests with performance measurement (binding.renderDuration)
  - Widget tests for animation timing (WidgetTester)
  - No additional testing dependencies required

**Graphics Rendering**:
  - CustomPainter for Canvas-based rendering
  - Paint.isAntiAlias for anti-aliasing
  - AnimationController for smooth transitions
  - Object pooling for particle lifecycle management

**Performance Monitoring**:
  - PerformanceOverlay for development debugging
  - Custom PerformanceMonitor for runtime frame time tracking
  - Adaptive quality control based on moving average of frame durations

## Next Steps

All research questions resolved. Ready to proceed to Phase 1: Design & Contracts.
