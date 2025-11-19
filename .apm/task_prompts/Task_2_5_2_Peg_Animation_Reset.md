---
task_id: "Task_2_5_2"
task_name: "Peg Animation Reset & Lifecycle"
agent_type: "dart-expert"  # or flutter-expert
session_date: "2025-11-18"
status: "ready_to_assign"
priority: "high"
dependencies: ["Task_2_5_1"]
phase: "Phase 2.5 - Gameplay Polish & UX Refinement"
estimated_duration: "2-3 hours"
---

# Task 2.5.2: Peg Animation Reset & Lifecycle

## Task Context

**Phase:** Phase 2.5 - Gameplay Polish & UX Refinement
**Blocking Phase:** Phase 3 - Android Optimization
**User Report:** Test 3 (Partial) - Peg Animations

**Problem:** Pegs remain highlighted after being hit, creating confusion about game objectives. Users think the goal is to hit ALL pegs (like a clear-the-board game), but that's not the mechanic.

**Expected Behavior:** Pegs should pulse/glow briefly when hit, then fade back to normal state after 0.5-1 second. Special pegs should maintain their shimmer effect when unhit, but should also reset after being hit.

---

## Objective

Implement peg hit animation lifecycle with automatic reset to prevent permanent highlighting state.

---

## Current Behavior Analysis

### File: `lib/models/peg.dart`

**Current Hit State Management:**
```dart
class Peg {
  bool hasBeenHit = false;
  bool isHighlighted = false;

  void onHit() {
    hasBeenHit = true;
    // No reset logic - stays highlighted forever
  }
}
```

**Current Rendering Logic:**
```dart
Color get renderColor {
  if (hasBeenHit) {
    return color.withOpacity(0.5); // Stays dimmed forever
  }
  if (isHighlighted && type == PegType.special) {
    return GameConstants.specialPegColor;
  }
  return color;
}
```

---

## Problems Identified

1. **No Animation Timer:** Hit state is permanent, no fade-back logic
2. **Permanent Opacity Change:** `withOpacity(0.5)` stays forever
3. **Special Peg Confusion:** Hit special pegs stay dimmed, lose shimmer
4. **Visual Clarity:** Can't distinguish "just hit" vs "hit 5 seconds ago"

---

## Implementation Requirements

### 1. Add Animation State to Peg Model

**File:** `lib/models/peg.dart`

**New Fields:**
```dart
class Peg {
  // Existing
  bool hasBeenHit = false;
  bool isHighlighted = false;

  // NEW: Animation state
  double _hitAnimationProgress = 0.0;  // 0.0 = not hit, 1.0 = fully hit
  double _hitAnimationDuration = 0.8;  // seconds
  double _hitAnimationTimer = 0.0;

  bool get isAnimatingHit => _hitAnimationProgress > 0.0;
}
```

### 2. Implement Animation Update Method

**File:** `lib/models/peg.dart`

**New Method:**
```dart
/// Update hit animation state
/// Call this every frame with deltaTime
void updateHitAnimation(double deltaTime) {
  if (_hitAnimationTimer > 0) {
    _hitAnimationTimer -= deltaTime;

    if (_hitAnimationTimer <= 0) {
      // Animation complete - reset to normal
      _hitAnimationTimer = 0.0;
      _hitAnimationProgress = 0.0;
    } else {
      // Calculate progress (1.0 -> 0.0 as timer counts down)
      _hitAnimationProgress = _hitAnimationTimer / _hitAnimationDuration;
    }
  }
}
```

### 3. Modify onHit() to Start Animation

**File:** `lib/models/peg.dart`

**Updated Method:**
```dart
void onHit() {
  if (!hasBeenHit) {
    hasBeenHit = true;
    _hitAnimationTimer = _hitAnimationDuration;
    _hitAnimationProgress = 1.0;

    // Special peg bonus logic remains unchanged
    if (type == PegType.special && isHighlighted) {
      isHighlighted = false;  // Deactivate special peg
    }
  }
}
```

### 4. Update renderColor to Use Animation Progress

**File:** `lib/models/peg.dart`

**Updated Getter:**
```dart
Color get renderColor {
  // Base color depends on peg type
  Color baseColor = color;

  if (type == PegType.special && isHighlighted) {
    baseColor = GameConstants.specialPegColor;
  }

  // Apply hit animation effect
  if (_hitAnimationProgress > 0.0) {
    // Fade to white during hit, then back to base color
    final hitColor = Color.lerp(baseColor, Colors.white, _hitAnimationProgress * 0.7);
    return hitColor ?? baseColor;
  }

  return baseColor;
}
```

### 5. Integrate Animation Update in Game Loop

**File:** `lib/widgets/pachinko_board.dart`

**In `_drawPegs()` method:**
```dart
void _drawPegs(Canvas canvas, level) {
  for (final peg in level.pegs) {
    // Update peg hit animation (assuming 60 FPS = 1/60 second per frame)
    peg.updateHitAnimation(1/60);

    // Existing pulse glow rendering
    if (peg.pulseGlowRadius > 0.0) {
      // ... existing code ...
    }

    // Existing shimmer rendering for special pegs
    if (peg.type == PegType.special && peg.isHighlighted && peg.shimmerIntensity > 0.0) {
      // ... existing code ...
    }

    // Draw peg body with updated renderColor
    final paint = Paint()
      ..color = peg.renderColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(peg.position.x, peg.position.y),
      peg.radius,
      paint,
    );
  }
}
```

---

## Animation Behavior Specification

### Hit Animation Timeline (0.8 seconds total)

**0.0s - 0.1s:** Flash to white (progress: 1.0 → 0.875)
- Peg color lerps from base to white (70% white blend)
- Instant visual feedback on collision

**0.1s - 0.4s:** Hold pulse (progress: 0.875 → 0.5)
- Maintains brightened appearance
- Clear indication peg was just hit

**0.4s - 0.8s:** Fade back to normal (progress: 0.5 → 0.0)
- Gradual return to base color
- Smooth transition completes

**0.8s+:** Return to normal state (progress: 0.0)
- Peg appears normal again
- Can be hit again (though hasBeenHit remains true for scoring)

### Special Peg Behavior

**Before Hit (isHighlighted = true):**
- Shimmer effect active
- Special peg color (orange)
- Stands out visually

**During Hit Animation (0-0.8s):**
- Hit animation takes priority
- Flashes white like normal pegs
- Shimmer disabled (isHighlighted = false after hit)

**After Hit Animation (0.8s+):**
- Returns to NORMAL peg color (green, not orange)
- No shimmer effect
- Looks like a regular peg that was hit

---

## Testing Requirements

### Unit Tests to Add

**File:** `test/models/peg_test.dart`

**New Test Cases:**
```dart
group('Peg Hit Animation', () {
  test('given unhit peg, when updateHitAnimation called, then no animation progress', () {
    final peg = Peg(/* ... */);
    peg.updateHitAnimation(1/60);
    expect(peg.isAnimatingHit, false);
  });

  test('given peg just hit, when onHit called, then animation starts', () {
    final peg = Peg(/* ... */);
    peg.onHit();
    expect(peg.isAnimatingHit, true);
    expect(peg._hitAnimationProgress, 1.0);
  });

  test('given peg animating, when updateHitAnimation called repeatedly, then progress decreases', () {
    final peg = Peg(/* ... */);
    peg.onHit();

    // Simulate 0.4 seconds (24 frames at 60 FPS)
    for (int i = 0; i < 24; i++) {
      peg.updateHitAnimation(1/60);
    }

    expect(peg.isAnimatingHit, true);
    expect(peg._hitAnimationProgress, closeTo(0.5, 0.1));
  });

  test('given peg animating, when full duration elapses, then animation resets', () {
    final peg = Peg(/* ... */);
    peg.onHit();

    // Simulate 0.9 seconds (54 frames at 60 FPS) - past 0.8s duration
    for (int i = 0; i < 54; i++) {
      peg.updateHitAnimation(1/60);
    }

    expect(peg.isAnimatingHit, false);
    expect(peg._hitAnimationProgress, 0.0);
  });

  test('given special peg hit, when animation completes, then renderColor returns to normal (not special)', () {
    final peg = Peg(
      position: Vector2(100, 100),
      radius: 10,
      type: PegType.special,
      isHighlighted: true,
    );

    peg.onHit();

    // Complete animation
    for (int i = 0; i < 60; i++) {
      peg.updateHitAnimation(1/60);
    }

    expect(peg.renderColor, equals(GameConstants.normalPegColor));
    expect(peg.isHighlighted, false);
  });
});
```

### Manual Testing Scenarios

1. **Normal Peg Hit:**
   - Launch ball, hit a normal peg
   - Observe peg flashes white briefly
   - Verify peg fades back to normal green after ~0.8 seconds
   - Peg should look completely normal after fade

2. **Special Peg Hit:**
   - Launch ball, hit an orange special peg
   - Observe peg flashes white (same as normal)
   - Verify peg fades to normal green (NOT orange) after animation
   - Shimmer effect should be gone permanently

3. **Multiple Pegs Hit in Sequence:**
   - Launch ball through dense peg area
   - Observe multiple pegs animate independently
   - Each peg should fade back at its own timing
   - No pegs should stay highlighted forever

4. **Peg Hit Twice (Edge Case):**
   - Hit a peg with first ball
   - After animation completes, hit same peg with second ball
   - Verify `onHit()` doesn't restart animation (hasBeenHit = true blocks)
   - Peg should stay in normal state

---

## Success Criteria

### Functional Requirements
- ✅ Pegs flash white when hit
- ✅ Pegs fade back to normal after 0.8 seconds
- ✅ Special pegs lose shimmer after being hit
- ✅ Special pegs return to normal color (not special color) after hit
- ✅ Animation timing is smooth and natural
- ✅ Multiple pegs animate independently
- ✅ Double-hit doesn't cause issues

### Code Quality Requirements
- ✅ All existing peg tests still pass
- ✅ New animation tests added and passing
- ✅ Code coverage maintained above 85% for peg.dart
- ✅ No performance degradation (60 FPS maintained)
- ✅ Animation update integrated into game loop cleanly

### User Experience Requirements
- ✅ Test 3 (Peg Animations) achieves FULL PASS
- ✅ Clear visual feedback on peg hits
- ✅ No confusion about game objectives
- ✅ Professional, polished feel

---

## Files to Modify

1. **`/home/frankbria/projects/pachinko/lib/models/peg.dart`**
   - Add animation state fields
   - Implement `updateHitAnimation()` method
   - Modify `onHit()` to start animation
   - Update `renderColor` getter to use animation progress

2. **`/home/frankbria/projects/pachinko/lib/widgets/pachinko_board.dart`**
   - Add `peg.updateHitAnimation(1/60)` call in `_drawPegs()` loop
   - Ensure animation updates every frame

3. **`/home/frankbria/projects/pachinko/test/models/peg_test.dart`**
   - Add new test group for hit animation
   - Test animation lifecycle (start, progress, complete)
   - Test special peg color transitions
   - Test edge cases (double hit, etc.)

---

## Implementation Notes

### Performance Considerations

**Frame Budget:**
- Animation update: O(n) where n = number of pegs
- Typical level: 30-50 pegs
- Update time per peg: ~0.01ms
- Total impact: < 1ms per frame
- **Verdict:** Negligible performance impact

**Memory:**
- 3 new doubles per peg: 24 bytes
- 50 pegs × 24 bytes = 1.2 KB
- **Verdict:** Trivial memory increase

### Alternative Approaches Considered

**Approach 1: Separate Animation Manager**
- Pros: Cleaner separation of concerns
- Cons: More complexity, harder to test
- **Decision:** Keep animation in Peg model for simplicity

**Approach 2: Tween Animations**
- Pros: Flutter-native animation system
- Cons: Requires AnimationController per peg, overkill for simple fade
- **Decision:** Custom lerp is simpler and more performant

**Approach 3: Timer-based Reset**
- Pros: Simpler logic (just set a timer)
- Cons: No smooth interpolation, abrupt color change
- **Decision:** Progress-based approach gives smooth fade

---

## Acceptance Testing

Before marking this task complete, verify:

1. **Run All Tests:**
   ```bash
   flutter test test/models/peg_test.dart
   ```
   - All existing tests pass
   - All new animation tests pass

2. **Manual Visual Validation:**
   - Launch game and hit various pegs
   - Confirm pegs flash and fade smoothly
   - No pegs stay highlighted permanently
   - Special pegs behave correctly

3. **Performance Check:**
   - Run game with Flutter DevTools performance overlay
   - Verify 60 FPS maintained with multiple pegs animating
   - No frame drops or stuttering

4. **Code Review:**
   - Animation logic is clear and documented
   - No magic numbers (use constants for durations)
   - Code follows Dart style guide

---

## Commit Message

```
feat(animations): implement peg hit animation with automatic reset

Adds 0.8-second fade animation for peg hits to improve visual clarity.

Changes:
- Add animation state tracking to Peg model
- Implement updateHitAnimation() lifecycle method
- Update renderColor to lerp based on animation progress
- Integrate animation updates into game loop render cycle

Behavior:
- Pegs flash white on hit, fade back to normal over 0.8s
- Special pegs return to normal color (not special) after hit
- Multiple pegs animate independently
- Smooth, professional visual feedback

Tests:
- Add 5 new unit tests for animation lifecycle
- All existing peg tests pass
- Code coverage maintained at 85%+

Fixes: Test 3 (Partial) - Peg Animations
Status: Ready for user validation

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

---

## Next Steps After Completion

1. User validates Test 3 achieves FULL PASS
2. Proceed to Task 2.5.3 (Audio Timing & Bonus Screen)
3. Continue Phase 2.5 polish tasks sequentially
