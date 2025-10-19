# Quickstart: Graphics Architecture Overhaul

**Purpose**: Get a developer up and running with the new graphics system in under 15 minutes

**Audience**: Developer with Flutter/Dart experience implementing this feature

**Prerequisites**:
- Flutter 3.24.5+ installed
- Dart 3.5.4+ installed
- Existing Pachinko game codebase cloned
- On feature branch `002-graphics-overhaul`

---

## Step 1: Verify Environment (2 minutes)

```bash
# Check Flutter version
flutter --version
# Should show Flutter 3.24.5 or higher

# Check you're on the correct branch
git branch
# Should show * 002-graphics-overhaul

# Run existing tests to ensure baseline works
flutter test
# Should show all existing tests passing
```

---

## Step 2: Understand Architecture (3 minutes)

**Key Concepts**:

1. **Particle System**: Manages all visual particle effects (trails, collisions)
   - Uses object pooling to avoid GC pressure
   - Two pools: TrailPool (100 particles) and CollisionPool (50 particles)

2. **Animation Controller**: Manages smooth animations (glow, fade)
   - Independent from physics loop
   - Supports multiple concurrent animations

3. **Performance Monitor**: Tracks FPS and adapts quality
   - Moving average over 60 frames
   - Automatically reduces particle count if FPS drops

4. **Rendering Layer**: Centralizes Paint configuration
   - Ensures anti-aliasing enabled
   - Batch rendering for performance

**Data Flow**:
```
Game Loop (60 FPS)
    ↓
ParticleSystem.update()
    ↓
RenderingLayer.renderParticles()
    ↓
CustomPainter.paint()
```

---

## Step 3: Core Implementation Pattern (5 minutes)

**Pattern 1: Adding a Particle Effect**

```dart
// 1. Get particle system from game manager
final particleSystem = gameManager.particleSystem;

// 2. Spawn particles at event location
particleSystem.spawnTrailParticle(
  position: ball.position,
  velocity: ball.velocity * 0.3,  // Trail follows at reduced speed
  color: GameConstants.ballColor,
  lifetime: 0.5,  // Half-second trail
);

// 3. Update in game loop
void update(double deltaTime) {
  particleSystem.update(deltaTime);
}

// 4. Render in CustomPainter
void paint(Canvas canvas, Size size) {
  renderingLayer.renderParticles(
    canvas: canvas,
    particles: particleSystem.getActiveParticles(),
  );
}
```

**Pattern 2: Adding an Animation**

```dart
// 1. Create animation in AnimationController
final glowAnimation = animationController.createAnimation(
  id: 'peg-glow-${peg.id}',
  duration: 2.0,  // 2-second cycle
  curve: AnimationCurve.easeInOut,
  loop: true,
);

// 2. Start animation
animationController.start('peg-glow-${peg.id}');

// 3. Get value in render loop
final glowIntensity = animationController.getValue('peg-glow-${peg.id}');

// 4. Apply to rendering
renderingLayer.renderGlowEffect(
  canvas: canvas,
  position: peg.position,
  radius: peg.radius + 5,
  color: GameConstants.specialPegColor,
  intensity: glowIntensity,
);
```

**Pattern 3: Performance Monitoring**

```dart
// 1. Record frame time after render
final frameTime = stopwatch.elapsedMilliseconds;
performanceMonitor.recordFrame(frameTime);

// 2. Check recommended quality
final quality = performanceMonitor.getRecommendedQuality();

// 3. Adjust particle system if needed
if (particleSystem.qualityLevel != quality) {
  particleSystem.adjustQuality(quality);
}
```

---

## Step 4: Testing Strategy (3 minutes)

**Test Types**:

1. **Unit Tests** (models, services):
```dart
test('Particle deactivates after lifetime expires', () {
  final particle = Particle(lifetime: 1.0);
  particle.update(1.5);  // Age past lifetime
  expect(particle.isActive, isFalse);
});
```

2. **Widget Tests** (visual components):
```dart
testWidgets('Glow effect renders with correct opacity', (tester) async {
  await tester.pumpWidget(MyApp());
  final glowPaint = find.byType(GlowEffect).evaluate().first.widget;
  expect(glowPaint.opacity, closeTo(0.5, 0.1));
});
```

3. **Integration Tests** (visual regression):
```dart
testWidgets('Particle trail matches golden file', (tester) async {
  await tester.pumpWidget(MyApp());
  await tester.pumpAndSettle();
  await expectLater(
    find.byType(PachinkoBoard),
    matchesGoldenFile('golden/particle_trail.png'),
  );
});
```

**Running Tests**:
```bash
# Unit tests only
flutter test test/unit/

# Widget tests only
flutter test test/widget/

# Integration tests (slower)
flutter test test/integration/

# Generate coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## Step 5: Common Workflows (2 minutes)

**Workflow 1: Verify Anti-Aliasing**
```bash
# Run visual regression test
flutter test test/integration/visual_regression_test.dart

# Check golden files
ls test/golden/
# Should see reference images

# If visuals changed intentionally
flutter test --update-goldens
```

**Workflow 2: Check Performance**
```bash
# Run with performance overlay
flutter run -d linux --enable-performance-overlay

# Watch FPS counter in top-right
# Should stay at 60 FPS during gameplay
```

**Workflow 3: Debug Particle System**
```bash
# Enable particle count display in constants
# GameConstants.showDebugParticleCount = true

# Run and observe console
flutter run -d linux

# Should log active particle count each frame
```

---

## Quick Reference

### Key Files
| File | Purpose |
|------|---------|
| `lib/services/graphics/particle_system.dart` | Main particle management |
| `lib/services/graphics/animation_controller.dart` | Animation coordination |
| `lib/services/graphics/performance_monitor.dart` | FPS tracking |
| `lib/services/graphics/rendering_layer.dart` | Paint configuration |
| `lib/models/particle.dart` | Particle data model |

### Key Constants
| Constant | Value | Purpose |
|----------|-------|---------|
| `GameConstants.maxTrailParticles` | 100 | Trail pool capacity |
| `GameConstants.maxCollisionParticles` | 50 | Collision pool capacity |
| `GameConstants.targetFPS` | 60 | Performance target |
| `GameConstants.fpsThresholdMedium` | 55 | Quality downgrade trigger |
| `GameConstants.particleTrailLifetime` | 0.5s | Trail duration |

### Common Issues

**Issue**: Particles not showing
- **Check**: Is ParticleSystem enabled?
- **Fix**: `particleSystem.enabled = true`

**Issue**: Low FPS
- **Check**: Too many particles active?
- **Fix**: PerformanceMonitor should auto-adjust, verify it's hooked up

**Issue**: Animations jerky
- **Check**: Is update() called each frame?
- **Fix**: Ensure AnimationController.update() in game loop

**Issue**: Visual regression tests failing
- **Check**: Did visuals change intentionally?
- **Fix**: Run `flutter test --update-goldens` to regenerate

---

## Next Steps

After quickstart, see:
- `data-model.md` for detailed entity specifications
- `contracts/graphics-api.md` for API contracts
- `tasks.md` (after `/speckit.tasks`) for implementation task list
- `CLAUDE.md` in repo root for project-wide standards

---

## Success Criteria

You're ready to implement when you can:
- ✅ Explain the four core components (Particle, Animation, Performance, Rendering)
- ✅ Describe object pooling rationale
- ✅ Write a basic particle spawn call
- ✅ Run and understand the three test types
- ✅ Know where to find key constants and files

**Estimated time to productive implementation**: 15 minutes
