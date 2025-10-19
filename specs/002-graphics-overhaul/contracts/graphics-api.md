# Graphics System API Contracts

**Phase**: 1 (Design & Contracts)
**Date**: 2025-10-18
**Type**: Internal API (Dart interfaces, not REST/GraphQL)

## Overview

This document defines the contracts (interfaces) for the graphics system components. These are Dart abstract classes that define the behavior contracts without implementation details.

---

## ParticleSystemContract

**Purpose**: Defines interface for managing all particle effects

**Methods**:

### spawnTrailParticle
```dart
void spawnTrailParticle({
  required Vector2 position,
  required Vector2 velocity,
  required Color color,
  double lifetime = 0.5,
})
```
**Preconditions**:
- System must be enabled
- Position must be within board bounds
- Lifetime must be > 0

**Postconditions**:
- One particle activated from trail pool
- Particle positioned at specified location
- If pool full, oldest particle replaced

**Error Handling**:
- No error thrown if pool full (graceful replacement)

---

### spawnCollisionBurst
```dart
void spawnCollisionBurst({
  required Vector2 position,
  required PegType pegType,
  int particleCount = 8,
})
```
**Preconditions**:
- System must be enabled
- Particle count must be 1-20

**Postconditions**:
- `particleCount` particles spawned radiating outward from position
- Particle colors match peg type (normal vs special)
- Velocities distributed in circular pattern

**Error Handling**:
- Caps particle count at available pool capacity

---

### update
```dart
void update(double deltaTime)
```
**Preconditions**:
- deltaTime must be > 0 and < 1.0 (reasonable frame time)

**Postconditions**:
- All active particles aged by deltaTime
- Expired particles deactivated
- Particle positions updated based on velocities

**Error Handling**:
- Skips update if deltaTime invalid

---

### adjustQuality
```dart
void adjustQuality(ParticleQualityLevel level)
```
**Preconditions**:
- Valid quality level enum value

**Postconditions**:
- Pool capacities adjusted (High=100, Medium=50, Low=25)
- Excess particles deactivated if downgrading

**Error Handling**:
- No error on invalid enum (validated at compile time)

---

## AnimationControllerContract

**Purpose**: Defines interface for managing concurrent animations

**Methods**:

### createAnimation
```dart
AnimationState createAnimation({
  required String id,
  required double duration,
  AnimationCurve curve = AnimationCurve.linear,
  bool loop = false,
})
```
**Preconditions**:
- ID must be unique (not already in use)
- Duration must be > 0

**Postconditions**:
- New AnimationState created and registered
- Animation in stopped state
- Returns reference to created animation

**Error Handling**:
- Throws `ArgumentError` if ID already exists

---

### start
```dart
void start(String id)
```
**Preconditions**:
- Animation with ID must exist
- Animation must not already be running

**Postconditions**:
- Animation state changed to running
- Elapsed time reset to 0
- Progress starts advancing on next update

**Error Handling**:
- Throws `StateError` if animation doesn't exist
- No-op if already running

---

### getValue
```dart
double getValue(String id)
```
**Preconditions**:
- Animation with ID must exist

**Postconditions**:
- Returns current progress (0.0 to 1.0)
- Does not modify animation state

**Error Handling**:
- Throws `StateError` if animation doesn't exist

---

### update
```dart
void update(double deltaTime)
```
**Preconditions**:
- deltaTime must be > 0

**Postconditions**:
- All running animations advanced by deltaTime
- Completed non-looping animations stopped
- Looping animations wrapped to 0.0 progress

**Error Handling**:
- Skips update if deltaTime invalid

---

## PerformanceMonitorContract

**Purpose**: Defines interface for tracking and reporting frame performance

**Methods**:

### recordFrame
```dart
void recordFrame(double frameTime)
```
**Preconditions**:
- frameTime must be > 0 (milliseconds)

**Postconditions**:
- Frame time added to circular buffer
- FPS calculated from moving average
- Quality recommendation updated if thresholds crossed

**Error Handling**:
- Ignores invalid frame times (< 0)

---

### getCurrentFPS
```dart
double getCurrentFPS()
```
**Preconditions**: None

**Postconditions**:
- Returns current FPS calculated from buffer
- Does not modify state

**Error Handling**: None (always returns valid double)

---

### getRecommendedQuality
```dart
ParticleQualityLevel getRecommendedQuality()
```
**Preconditions**: None

**Postconditions**:
- Returns quality level based on current performance
- Hysteresis applied to prevent oscillation

**Error Handling**: None (always returns valid enum)

---

## RenderingLayerContract

**Purpose**: Defines interface for rendering visual elements with proper configuration

**Methods**:

### getPaint
```dart
Paint getPaint({
  required PaintStyle style,
  Color? color,
  double? strokeWidth,
  bool antiAlias = true,
})
```
**Preconditions**:
- Valid PaintStyle enum
- If strokeWidth provided, must be > 0

**Postconditions**:
- Returns configured Paint object
- Anti-aliasing set according to config
- Color and stroke width applied

**Error Handling**:
- Uses default color if null
- Uses default stroke width if null or invalid

---

### renderParticles
```dart
void renderParticles({
  required Canvas canvas,
  required List<Particle> particles,
  Paint? customPaint,
})
```
**Preconditions**:
- Canvas must be valid
- Particles list must not be null (can be empty)

**Postconditions**:
- All active particles drawn to canvas
- Batch rendering used for performance
- Opacity applied per particle

**Error Handling**:
- Skips rendering if particles list empty

---

### renderGlowEffect
```dart
void renderGlowEffect({
  required Canvas canvas,
  required Vector2 position,
  required double radius,
  required Color color,
  required double intensity,
})
```
**Preconditions**:
- Radius must be > 0
- Intensity must be 0.0 to 1.0

**Postconditions**:
- Glow effect rendered at position
- Blur applied based on config
- Alpha modulated by intensity

**Error Handling**:
- Clamps intensity to valid range
- Uses minimum radius if invalid

---

## Contract Testing

All contracts will be verified through:

1. **Unit Tests**: Mock implementations verifying preconditions/postconditions
2. **Integration Tests**: Real implementations testing error handling
3. **Widget Tests**: Rendering contracts tested with golden files

**Example Test Pattern**:
```dart
test('spawnTrailParticle respects pool capacity', () {
  // Precondition: Pool at max capacity
  final system = ParticleSystemImpl(maxCapacity: 2);
  system.spawnTrailParticle(...); // Fill slot 1
  system.spawnTrailParticle(...); // Fill slot 2

  // Action: Attempt to spawn beyond capacity
  system.spawnTrailParticle(...);

  // Postcondition: Oldest particle replaced, count still 2
  expect(system.activeCount, equals(2));
});
```

## Dependency Graph

```
GameManager (existing)
    ↓
ParticleSystem ← PerformanceMonitor
    ↓
ParticlePool → RenderingLayer
    ↓              ↓
Particle      AnimationController
```

## Notes

- All contracts are technology-agnostic within Dart/Flutter
- Implementation classes will have `Impl` suffix (e.g., `ParticleSystemImpl`)
- Contracts enable dependency injection for testing
- No UI framework dependencies in contracts (pure Dart)
