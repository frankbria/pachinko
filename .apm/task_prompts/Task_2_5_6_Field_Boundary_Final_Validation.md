---
task_id: "Task_2_5_6"
task_name: "Field Boundary Enhancements & Final Validation"
agent_type: "flutter-expert"
session_date: "2025-11-18"
status: "ready_to_assign"
priority: "high"
dependencies: ["Task_2_5_1", "Task_2_5_2", "Task_2_5_3", "Task_2_5_4", "Task_2_5_5"]
phase: "Phase 2.5 - Gameplay Polish & UX Refinement"
estimated_duration: "2-3 hours"
---

# Task 2.5.6: Field Boundary Enhancements & Final Validation

## Task Context

**Phase:** Phase 2.5 - Gameplay Polish & UX Refinement (FINAL TASK)
**Blocking Phase:** Phase 3 - Android Optimization
**User Request:** Test 2 Enhancement - Field Boundaries

**Objective:** Complete Phase 2.5 with field boundary improvements and comprehensive validation of all 15 manual tests.

---

## Primary Goals

1. **Field Boundary Enhancements:** Make right edge scoring more challenging
2. **Final Manual Validation:** Re-test all 15 tests, confirm no regressions
3. **Performance Validation:** 60 FPS maintained across all features
4. **Optional Enhancement:** Add player name/initials to high scores
5. **User Acceptance:** "Game ready for production" confirmation

---

## Problem 1: Field Boundary Improvements

### Current Behavior

**File:** `lib/services/physics_engine.dart` (lines 59-67)

```dart
// Right boundary - CONDITIONAL based on ball Y position
// When y <= 110 (above playfield): right boundary is at x=390 (board/launch tube right edge)
// When y > 110 (in playfield): right boundary is at x=360 (playfield right edge)
final rightBoundaryX = ball.position.y <= 110.0 ? 390.0 : GameConstants.launchChannelStartX;

if (ball.position.x + ball.radius >= rightBoundaryX) {
  ball.position.x = rightBoundaryX - ball.radius;
  ball.velocity.x = -ball.velocity.x * _damping;
}
```

### User Feedback

> **Test 2 Enhancement - Field Boundaries:**
> - Use **left line** of ball launcher as right field boundary (not launcher's right line)
> - Add explicit left boundary aligned with **left-most scoring bin**
> - Current: Uses full screen width (too easy to score on right edge)

### Problem Analysis

**Current boundaries:**
- **Left field boundary:** x = 30 (vertical field barrier)
- **Right field boundary:** x = 360 (launch channel start)
- **Launch channel start:** x = 360 (GameConstants.launchChannelStartX)

**Issue:** Right boundary at x=360 is the **right edge** of the playfield, but user wants **left edge** of the launch tube as the boundary (making the field narrower for more challenge).

**Proposed boundaries:**
- **Left field boundary:** Align with left-most slot position
- **Right field boundary:** Left edge of launch tube (current x=360 is correct if launch tube is centered at 360 with width 30, so left edge would be 360)

**Investigation needed:** Verify slot positions and adjust boundaries accordingly.

---

### Solution: Tighten Field Boundaries

**Step 1: Analyze slot positions**

**File:** Check slot generation to find left-most slot position

```dart
// lib/models/level.dart or similar
// Find how slots are positioned
```

**Expected slot layout:**
- Slots evenly spaced at bottom
- Left-most slot likely at x ~40-50
- Right-most slot likely at x ~350

**Step 2: Define explicit left boundary**

**File:** `lib/utils/constants.dart`

```dart
class GameConstants {
  // ... existing constants ...

  // Field boundaries (playfield area where balls interact with pegs)
  static const double fieldLeftBoundaryX = 40.0;  // Align with left-most slot
  static const double fieldRightBoundaryX = 350.0; // Left edge of launch tube

  // ... existing constants ...
}
```

**Step 3: Update physics boundary collision**

**File:** `lib/services/physics_engine.dart`

```dart
void _checkBoundaryCollisions(Ball ball) {
  // Left FIELD boundary (aligned with left-most slot)
  const leftFieldBoundaryX = GameConstants.fieldLeftBoundaryX;

  if (ball.position.x - ball.radius <= leftFieldBoundaryX) {
    ball.position.x = leftFieldBoundaryX + ball.radius;
    ball.velocity.x = -ball.velocity.x * _damping;
  }

  // Left vertical FIELD barrier collision at x=30 (playfield boundary)
  // REMOVE THIS - replace with leftFieldBoundaryX above
  // ... OLD CODE REMOVED ...

  // Right FIELD boundary (left edge of launch tube)
  // Make conditional: only apply when ball is in playfield (y > 110)
  const rightFieldBoundaryX = GameConstants.fieldRightBoundaryX;

  if (ball.position.y > 110.0 && // Only in playfield
      ball.position.x + ball.radius >= rightFieldBoundaryX) {
    ball.position.x = rightFieldBoundaryX - ball.radius;
    ball.velocity.x = -ball.velocity.x * _damping;
  }

  // When y <= 110 (in launch area), right boundary is board edge (x=390)
  if (ball.position.y <= 110.0 &&
      ball.position.x + ball.radius >= 390.0) {
    ball.position.x = 390.0 - ball.radius;
    ball.velocity.x = -ball.velocity.x * _damping;
  }

  // ... rest of boundary logic ...
}
```

**Step 4: Update visual rendering**

**File:** `lib/widgets/pachinko_board.dart`

```dart
void _drawLaunchChannel(Canvas canvas, level) {
  // ... existing code ...

  // Draw LEFT FIELD boundary (vertical line at left edge)
  final leftBoundaryPaint = Paint()
    ..color = Colors.white.withOpacity(0.6)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;

  canvas.drawLine(
    Offset(GameConstants.fieldLeftBoundaryX, GameConstants.launchChannelStartY),
    Offset(GameConstants.fieldLeftBoundaryX, 110.0), // Top curve height
    leftBoundaryPaint,
  );

  // Draw RIGHT FIELD boundary (left edge of launch tube)
  canvas.drawLine(
    Offset(GameConstants.fieldRightBoundaryX, GameConstants.launchChannelStartY),
    Offset(GameConstants.fieldRightBoundaryX, 110.0),
    leftBoundaryPaint,
  );

  // ... existing launch tube rendering ...
}
```

---

## Problem 2: Optional - Player Name for High Scores

### Current High Score Format

**File:** `lib/models/high_score.dart` (likely structure)

```dart
class HighScore {
  final int score;
  final int level;
  final DateTime timestamp;

  // NO PLAYER NAME
}
```

### Enhancement

**Add player name field:**

```dart
class HighScore {
  final int score;
  final int level;
  final DateTime timestamp;
  final String playerName; // NEW

  HighScore({
    required this.score,
    required this.level,
    required this.timestamp,
    this.playerName = 'Player', // Default
  });
}
```

**Create name entry dialog:**

**New file:** `lib/widgets/player_name_dialog.dart`

```dart
import 'package:flutter/material.dart';

class PlayerNameDialog extends StatefulWidget {
  final String? initialName;

  const PlayerNameDialog({super.key, this.initialName});

  @override
  State<PlayerNameDialog> createState() => _PlayerNameDialogState();
}

class _PlayerNameDialogState extends State<PlayerNameDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? 'AAA');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New High Score!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Enter your initials:'),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLength: 3,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              hintText: 'AAA',
              counterText: '',
            ),
            style: const TextStyle(fontSize: 24, letterSpacing: 4),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.toUpperCase()),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
```

**Trigger dialog on new high score:**

**File:** `lib/services/game_manager.dart`

```dart
void _saveHighScore() async {
  final storageService = _storageService;
  final level = _gameState.currentLevel?.levelNumber ?? 1;
  final score = _gameState.score;

  if (storageService != null) {
    // Check if this is a new high score
    final currentHighScore = await storageService.getHighScore(level);
    final isNewHighScore = currentHighScore == null || score > currentHighScore.score;

    if (isNewHighScore) {
      // TODO: Show player name dialog
      // For now, use default name
      final playerName = 'Player'; // Replace with dialog result

      storageService.saveHighScore(level, score, playerName: playerName);
    }
  }

  _achievementService?.trackLevelComplete(level);
  _achievementService?.trackLevelScore(level, score);
}
```

**Note:** Showing dialog requires context from widget tree - implement in GameScreen, not GameManager.

---

## Final Validation Checklist

### Test Plan: All 15 Manual Tests

Run comprehensive manual testing to verify Phase 2.5 completion:

**✅ PASSING (Target: 15/15 tests):**

| Test | Description | Status | Notes |
|------|-------------|--------|-------|
| Test 1 | Ball Launch Trajectory & Motion | 🔄 RETEST | After Task 2.5.1 fixes |
| Test 2 | Physics Simulation | 🔄 RETEST | After boundary changes |
| Test 3 | Peg Animations | 🔄 RETEST | After Task 2.5.2 fixes |
| Test 4 | Score Updates | ✅ PASS | No changes |
| Test 5 | Launch Sound Timing | 🔄 RETEST | After Task 2.5.3 fixes |
| Test 6 | Peg Hit Sound | ✅ PASS | No changes |
| Test 7 | Bonus Screen Behavior | 🔄 RETEST | After Task 2.5.3 fixes |
| Test 8 | Slot Score Sound | ✅ PASS | No changes |
| Test 9 | Visual Bonus Feedback | 🔄 RETEST | After Task 2.5.4 fixes |
| Test 10 | High Score Save (session) | ✅ PASS | No changes |
| Test 11 | High Score Persistence (restart) | ✅ PASS | No changes |
| Test 12 | Achievement Progress Tracking | ✅ PASS | Toast enhancement added |
| Test 13 | Achievement Persistence (restart) | ✅ PASS | No changes |
| Test 14 | Achievement Unlock Triggers | ✅ PASS | No changes |
| Test 15 | No Visual Glitches | 🔄 RETEST | Comprehensive check |

**Testing Protocol:**

1. **Fresh Install Testing:**
   - Delete SharedPreferences data
   - Restart app
   - Verify first-run experience

2. **Regression Testing:**
   - Test previously passing tests
   - Ensure no new issues introduced

3. **Performance Testing:**
   - Monitor FPS during gameplay
   - Check with 10+ active balls
   - Verify all visual effects active simultaneously

4. **User Experience Testing:**
   - Play through full level cycle
   - Trigger all bonus events
   - Unlock multiple achievements
   - Verify overall polish and feel

---

## Performance Validation Requirements

### Target: 60 FPS Sustained

**Test Scenarios:**

1. **Baseline (idle):**
   - Game paused, no balls active
   - Expected: Solid 60 FPS

2. **Normal gameplay:**
   - 3-5 balls active
   - Pegs animating (pulse + shimmer)
   - Expected: 60 FPS ±2

3. **Heavy load:**
   - 10 balls active
   - Multiple floating texts
   - Peg animations active
   - Expected: 58-60 FPS

4. **Bonus event:**
   - Special bonus triggered
   - 50 confetti particles
   - Bonus overlay displayed
   - Achievement toast showing
   - Expected: 55-60 FPS (temporary spike ok)

**Monitoring Tools:**

```bash
# Run with performance overlay
flutter run --profile -d linux

# OR in code (for testing only):
# MaterialApp(
#   showPerformanceOverlay: true,
#   ...
# )
```

**Acceptance:**
- Average FPS: 58-60
- Frame drops: < 5 frames per minute
- No sustained FPS drops below 55

---

## Testing Requirements

### Unit Tests

**File:** `test/services/physics_engine_test.dart` (add to existing tests)

```dart
group('Field Boundary Enforcement', () {
  test('given ball at left boundary, when collision checked, then ball bounces', () {
    final physicsEngine = PhysicsEngine();
    final ball = Ball(
      position: Vector2(GameConstants.fieldLeftBoundaryX - 5, 200),
      velocity: Vector2(-50, 0), // Moving left
    );

    physicsEngine.updateBalls([ball], 1/60);

    // Ball should bounce right
    expect(ball.velocity.x, greaterThan(0));
    expect(ball.position.x, greaterThanOrEqualTo(GameConstants.fieldLeftBoundaryX));
  });

  test('given ball at right field boundary in playfield, when collision checked, then ball bounces', () {
    final physicsEngine = PhysicsEngine();
    final ball = Ball(
      position: Vector2(GameConstants.fieldRightBoundaryX + 5, 200), // y > 110 (in field)
      velocity: Vector2(50, 0), // Moving right
    );

    physicsEngine.updateBalls([ball], 1/60);

    // Ball should bounce left
    expect(ball.velocity.x, lessThan(0));
    expect(ball.position.x, lessThanOrEqualTo(GameConstants.fieldRightBoundaryX));
  });

  test('given ball at right edge in launch area, when y <= 110, then board edge used', () {
    final physicsEngine = PhysicsEngine();
    final ball = Ball(
      position: Vector2(391, 100), // y <= 110 (in launch area)
      velocity: Vector2(50, 0),
    );

    physicsEngine.updateBalls([ball], 1/60);

    // Ball should bounce at board edge (390)
    expect(ball.position.x, lessThanOrEqualTo(390.0));
  });
});
```

### Manual Test Execution

**Create test log:** `.apm/Memory/Phase_02_5_Critical_Gameplay_Fixes/Phase_2_5_Final_Validation.md`

```markdown
# Phase 2.5 - Final Validation Results

**Date:** 2025-11-18
**Tester:** [User/Agent]
**Build:** Phase 2.5 Complete

---

## Test Results

### Test 1 - Ball Launch Trajectory & Motion
- ✅/❌ Ball motion smooth (no stuttering)
- ✅/❌ Trajectory line hidden
- ✅/❌ Natural motion at section transitions
- ✅/❌ Curved top boundary implemented
- **Status:** PASS / PARTIAL / FAIL
- **Notes:** [Any observations]

### Test 2 - Physics Simulation
- ✅/❌ Ball physics realistic
- ✅/❌ Peg collisions accurate
- ✅/❌ Field boundaries enforced correctly
- ✅/❌ Right edge scoring challenging
- **Status:** PASS / PARTIAL / FAIL
- **Notes:** [Any observations]

### Test 3 - Peg Animations
- ✅/❌ Pegs flash on hit
- ✅/❌ Pegs fade back to normal after 0.8s
- ✅/❌ Special pegs lose shimmer after hit
- ✅/❌ Animation timing natural
- **Status:** PASS / PARTIAL / FAIL
- **Notes:** [Any observations]

[... continue for all 15 tests ...]

---

## Performance Results

**FPS Monitoring:**
- Baseline (idle): ___ FPS
- Normal gameplay (3-5 balls): ___ FPS
- Heavy load (10 balls): ___ FPS
- Bonus event (confetti): ___ FPS

**Frame Drops:** ___ frames per minute
**Sustained Low FPS:** Yes / No

**Performance Status:** PASS / FAIL

---

## User Experience Assessment

**Overall Polish:** 1-10 rating
**Visual Quality:** 1-10 rating
**Audio Sync:** 1-10 rating
**Gameplay Feel:** 1-10 rating

**Game Ready for Production:** YES / NO

**Comments:** [User feedback]
```

---

## Success Criteria

### Functional Requirements
- ✅ Field boundaries tightened (harder to score on edges)
- ✅ Left boundary aligned with left-most slot
- ✅ Right boundary at left edge of launch tube
- ✅ Boundary visuals rendered clearly
- ✅ All 15 manual tests achieve FULL PASS
- ✅ No regressions from previous tasks

### Code Quality Requirements
- ✅ All existing tests still passing
- ✅ New boundary tests added (3+ tests)
- ✅ Code coverage maintained above 85%
- ✅ No linter warnings
- ✅ Constants properly defined

### Performance Requirements
- ✅ 60 FPS sustained during normal gameplay
- ✅ 55+ FPS during heavy load
- ✅ No memory leaks
- ✅ Smooth animations across all features

### User Acceptance
- ✅ All Phase 2.5 issues resolved
- ✅ Game feels polished and production-ready
- ✅ User confirms: "Game ready for production"

---

## Files to Modify

1. **`/home/frankbria/projects/pachinko/lib/utils/constants.dart`**
   - Add fieldLeftBoundaryX and fieldRightBoundaryX constants

2. **`/home/frankbria/projects/pachinko/lib/services/physics_engine.dart`**
   - Update _checkBoundaryCollisions() with new field boundaries
   - Remove old left barrier logic
   - Add conditional right boundary (field vs launch area)

3. **`/home/frankbria/projects/pachinko/lib/widgets/pachinko_board.dart`**
   - Draw left field boundary line
   - Draw right field boundary line
   - Update visual clarity

4. **`/home/frankbria/projects/pachinko/test/services/physics_engine_test.dart`**
   - Add field boundary tests (3 tests)

5. **`/home/frankbria/projects/pachinko/.apm/Memory/Phase_02_5_Critical_Gameplay_Fixes/Phase_2_5_Final_Validation.md`** (NEW)
   - Create comprehensive test log

6. **OPTIONAL - Player Name Enhancement:**
   - `/home/frankbria/projects/pachinko/lib/models/high_score.dart`
   - `/home/frankbria/projects/pachinko/lib/widgets/player_name_dialog.dart` (NEW)
   - `/home/frankbria/projects/pachinko/lib/screens/game_screen.dart`

---

## Acceptance Testing

Before marking this task complete, verify:

1. **Run All Tests:**
   ```bash
   flutter test
   ```
   - All 440+ tests pass
   - All new boundary tests pass
   - Code coverage ≥ 85%

2. **Run Analyzer:**
   ```bash
   flutter analyze
   ```
   - Zero issues reported

3. **Manual Validation:**
   - Execute all 15 manual tests
   - Record results in Phase_2_5_Final_Validation.md
   - Confirm 15/15 FULL PASS

4. **Performance Validation:**
   - Run with Flutter DevTools
   - Monitor FPS across all scenarios
   - Confirm 60 FPS sustained

5. **User Acceptance:**
   - User plays complete game session
   - User confirms "Game ready for production"
   - No major issues identified

---

## Commit Message

```
feat(ux): tighten field boundaries and complete Phase 2.5 validation

Field Boundary Enhancements:
- Add explicit left field boundary (aligned with left-most slot)
- Add explicit right field boundary (left edge of launch tube)
- Conditional right boundary (field vs launch area)
- Render boundary lines for visual clarity
- Makes right edge scoring more challenging

Validation Results:
- All 15 manual tests achieve FULL PASS
- No regressions from Phase 2.5 tasks
- 60 FPS sustained across all scenarios
- All 440+ unit tests passing
- Code coverage maintained at 85%+

Phase 2.5 Summary:
- Task 2.5.1: Ball launch physics polished ✅
- Task 2.5.2: Peg animation lifecycle ✅
- Task 2.5.3: Audio timing & bonus screen ✅
- Task 2.5.4: Visual feedback & confetti ✅
- Task 2.5.5: Achievement toast notifications ✅
- Task 2.5.6: Field boundaries & validation ✅

Performance: 60 FPS sustained, no memory leaks

Status: Phase 2.5 COMPLETE - Ready for Phase 3

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

---

## Phase 2.5 Completion Report

**Phase Status:** ✅ COMPLETE

**Quality Gate Results:**
- ✅ All 15 manual tests FULL PASS
- ✅ No visual artifacts or debug overlays
- ✅ All audio perfectly synchronized
- ✅ All animations smooth and complete
- ✅ 60 FPS performance maintained
- ✅ All 440+ unit tests passing
- ✅ Code coverage 85%+
- ✅ User acceptance: "Game ready for production"

**Phase 2.5 Achievements:**
- Polished ball launch physics
- Implemented peg animation lifecycle
- Fixed audio timing issues
- Added visual bonus feedback system
- Implemented achievement notifications
- Tightened field boundaries for better gameplay

**Ready for Phase 3:** ✅ YES

**Next Phase:** Phase 3 - Android Optimization (Task 3.4)

---

## Next Steps After Completion

1. **User confirms Phase 2.5 completion:** "Game ready for production"
2. **Create Phase 2.5 completion log:** Document lessons learned
3. **Resume Phase 3:** Start at Task 3.4 (Android build optimization)
4. **Update implementation plan:** Mark Phase 2.5 complete in master plan
