# Data Model: Graphics Architecture Overhaul

**Phase**: 1 (Design & Contracts)
**Date**: 2025-10-18
**Status**: Complete

## Core Entities

### Particle

Represents an individual visual particle used for trails and collision effects.

**Attributes**:
- `position`: Vector2 - Current X,Y coordinates in game space
- `velocity`: Vector2 - Movement vector (pixels per second)
- `color`: Color - RGBA color value
- `lifetime`: double - Maximum lifetime in seconds
- `age`: double - Current age in seconds
- `size`: double - Radius in pixels
- `opacity`: double - Alpha value (0.0 to 1.0)
- `isActive`: bool - Whether particle is currently in use (for object pooling)

**Validation Rules**:
- lifetime must be > 0
- age must be >= 0 and <= lifetime
- size must be > 0 and <= 20 (performance constraint)
- opacity must be between 0.0 and 1.0

**State Transitions**:
1. **Inactive** → **Active**: When spawned from pool
2. **Active** → **Fading**: When age > (lifetime * 0.7)
3. **Fading** → **Inactive**: When age >= lifetime

**Relationships**:
- Many particles belong to one ParticlePool
- Particles reference Ball position for trail effects

---

### ParticlePool

Manages a fixed-size pool of reusable particles to avoid GC pressure.

**Attributes**:
- `particles`: List<Particle> - Fixed-size array of particle instances
- `maxCapacity`: int - Maximum particles (100 for trail, 50 for collisions)
- `activeCount`: int - Current number of active particles
- `poolType`: ParticlePoolType enum - Trail or Collision

**Validation Rules**:
- maxCapacity must be > 0 and <= 100 (NFR-001 performance constraint)
- activeCount must be >= 0 and <= maxCapacity

**Methods** (behavior, not implementation):
- `spawn(position, velocity, color, lifetime)`: Activates next inactive particle
- `update(deltaTime)`: Ages all active particles, deactivates expired ones
- `getActiveParticles()`: Returns list of currently active particles for rendering

**Relationships**:
- One ParticlePool contains many Particles
- Multiple ParticlePools managed by ParticleSystem

---

### ParticleSystem

Orchestrates all particle effects and manages multiple pools.

**Attributes**:
- `trailPool`: ParticlePool - Pool for ball trail particles
- `collisionPool`: ParticlePool - Pool for collision burst particles
- `enabled`: bool - Master enable/disable for all particle effects
- `qualityLevel`: ParticleQualityLevel enum - Current quality setting (High, Medium, Low)

**Validation Rules**:
- Pools must be initialized before system is enabled
- qualityLevel changes must trigger pool capacity adjustments

**Methods** (behavior, not implementation):
- `spawnTrailParticle(ball)`: Creates trail particle following ball
- `spawnCollisionBurst(position, pegType)`: Creates burst effect at collision point
- `update(deltaTime)`: Updates all pools
- `adjustQuality(newLevel)`: Adapts particle limits based on performance

**Relationships**:
- Owns multiple ParticlePools
- Receives Ball and Peg data from existing game state
- Provides particle data to RenderingLayer

---

### AnimationState

Tracks state for individual animation (glow, fade, etc.).

**Attributes**:
- `id`: String - Unique identifier for this animation
- `progress`: double - Current progress (0.0 to 1.0)
- `duration`: double - Total duration in seconds
- `elapsedTime`: double - Time since animation started
- `curve`: AnimationCurve enum - Easing function (Linear, EaseIn, EaseOut, etc.)
- `isRunning`: bool - Whether animation is actively progressing
- `loop`: bool - Whether animation repeats

**Validation Rules**:
- progress must be between 0.0 and 1.0
- duration must be > 0
- elapsedTime must be >= 0
- If not looping, progress stops at 1.0

**State Transitions**:
1. **Stopped** → **Running**: When animation starts
2. **Running** → **Completed**: When progress reaches 1.0 (if not looping)
3. **Completed** → **Running**: If loop is true
4. **Running** → **Stopped**: When manually stopped

**Relationships**:
- Multiple AnimationStates managed by AnimationController
- AnimationStates reference visual elements (Pegs for glow, UI elements for fade)

---

### AnimationController

Coordinates multiple concurrent animations with independent timelines.

**Attributes**:
- `animations`: Map<String, AnimationState> - Active animations keyed by ID
- `globalTimeScale`: double - Multiplier for all animation speeds (1.0 = normal)

**Validation Rules**:
- Animation IDs must be unique within controller
- globalTimeScale must be > 0

**Methods** (behavior, not implementation):
- `createAnimation(id, duration, curve, loop)`: Registers new animation
- `start(id)`: Begins animation progression
- `stop(id)`: Halts animation
- `update(deltaTime)`: Advances all running animations
- `getValue(id)`: Returns current progress for rendering

**Relationships**:
- Manages multiple AnimationStates
- Provides animation values to RenderingLayer for visual updates

---

### PerformanceMetrics

Tracks frame timing data for adaptive quality control.

**Attributes**:
- `frameTimes`: CircularBuffer<double> - Last N frame durations (N=60 for 1 second window)
- `currentFPS`: double - Calculated frames per second
- `averageFrameTime`: double - Moving average of frame durations (milliseconds)
- `targetFrameTime`: double - Target frame time (16.67ms for 60 FPS)
- `qualityLevel`: ParticleQualityLevel - Current adaptive quality setting

**Validation Rules**:
- frameTimes buffer size must be > 0
- currentFPS must be >= 0
- averageFrameTime must be >= 0
- targetFrameTime must be > 0

**State Transitions** (Quality Level):
1. **High** → **Medium**: When averageFrameTime > 18ms (55 FPS)
2. **Medium** → **Low**: When averageFrameTime > 20ms (50 FPS)
3. **Low** → **Medium**: When averageFrameTime < 17ms
4. **Medium** → **High**: When averageFrameTime < 16ms

**Relationships**:
- Provides quality recommendations to ParticleSystem
- Receives frame timing data from Flutter rendering callbacks

---

### RenderConfig

Centralized rendering configuration for anti-aliasing and visual quality.

**Attributes**:
- `antiAliasingEnabled`: bool - Master anti-aliasing toggle
- `particleAntiAliasing`: bool - Specific to particle rendering
- `glowBlurRadius`: double - Blur radius for glow effects (pixels)
- `defaultStrokeWidth`: double - Line width for UI elements
- `highDPIScale`: double - DPI scaling factor (auto-detected from device)

**Validation Rules**:
- Blur radius must be >= 0 and <= 20 (performance)
- Stroke width must be > 0
- DPI scale must be > 0

**Relationships**:
- Used by RenderingLayer for all Paint object configuration
- Updated based on device capabilities and PerformanceMetrics

---

## Entity Relationships Diagram

```
ParticleSystem
├── owns → TrailPool (ParticlePool)
│   └── contains → Particle[] (max 100)
└── owns → CollisionPool (ParticlePool)
    └── contains → Particle[] (max 50)

AnimationController
└── manages → AnimationState[] (multiple concurrent)

PerformanceMonitor
├── tracks → PerformanceMetrics
└── influences → ParticleSystem.qualityLevel

RenderingLayer
├── uses → RenderConfig
├── reads → ParticleSystem (for particle positions/colors)
└── reads → AnimationController (for animation progress values)

Existing Game State (Ball, Peg, Slot)
└── provides data to → ParticleSystem (positions for effects)
```

## Data Flow

### Particle Trail Generation
1. Game loop updates Ball position
2. ParticleSystem checks if ball moved > threshold distance
3. ParticleSystem.spawnTrailParticle() called with ball data
4. TrailPool activates next inactive Particle
5. RenderingLayer reads active particles from TrailPool
6. CustomPainter draws particles with configured Paint

### Collision Effect Generation
1. PhysicsEngine detects Ball-Peg collision
2. GameManager triggers ParticleSystem.spawnCollisionBurst()
3. CollisionPool spawns 5-10 particles radiating from collision point
4. Particles initialized with outward velocities and short lifetimes
5. RenderingLayer renders burst effect
6. Particles fade and deactivate after lifetime expires

### Glow Animation
1. Level loads with special Pegs
2. AnimationController creates glow AnimationState for each special peg
3. Animation loops with 2-second cycle using EaseInOut curve
4. RenderingLayer queries AnimationController for current glow intensity
5. Paint configured with glow color at current opacity
6. CustomPainter draws peg with animated glow effect

### Performance Adaptation
1. PerformanceMonitor records frame time after each render
2. Moving average calculated over last 60 frames (1 second window)
3. If average > 18ms threshold, quality downgrade triggered
4. ParticleSystem reduces pool capacities (100 → 50 → 25)
5. Fewer particles spawned, frame time improves
6. If average < 17ms for sustained period, quality restored

## Validation Summary

All entities have:
- Clear attribute types and constraints
- Defined validation rules
- State transition logic where applicable
- Relationships to other entities documented
- Data flow patterns specified

No ambiguous or implementation-specific details included. Model is technology-agnostic within Flutter/Dart constraints.
