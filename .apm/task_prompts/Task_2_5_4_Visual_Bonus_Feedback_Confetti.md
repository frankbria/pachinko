---
task_id: "Task_2_5_4"
task_name: "Visual Bonus Feedback & Confetti Effect"
agent_type: "flutter-expert"
session_date: "2025-11-18"
status: "ready_to_assign"
priority: "high"
dependencies: ["Task_2_5_1", "Task_2_5_2", "Task_2_5_3"]
phase: "Phase 2.5 - Gameplay Polish & UX Refinement"
estimated_duration: "3-4 hours"
---

# Task 2.5.4: Visual Bonus Feedback & Confetti Effect

## Task Context

**Phase:** Phase 2.5 - Gameplay Polish & UX Refinement
**Blocking Phase:** Phase 3 - Android Optimization
**User Report:** Test 9 (Partial) - Visual Bonus Feedback

**Problem:** Bonus events (scoring points, earning bonus balls) have no eye-catching visual feedback. Users miss bonus events or don't feel rewarded. Confetti effect may have been accidentally removed.

---

## Objective

Add visual feedback for bonus events:
1. Floating "+X points!" text when balls land in scoring slots
2. Animated ball counter highlight when bonus balls are awarded
3. Confetti particle effect for special bonus triggers

---

## Problem Analysis

### Current Behavior

**File:** `lib/services/game_manager.dart` (lines 180-191)

```dart
void _handleSlotHits(List<Slot> hitSlots) {
  for (final slot in hitSlots) {
    _gameState.addScore(slot.pointValue);
    _audioService?.playSlotScore(slot.pointValue);

    if (slot.pointValue >= 2000) {
      _achievementService?.trackEdgeSlot();
    }
  }
  // NO VISUAL FEEDBACK - just silent score increase
}
```

**File:** `lib/models/game_state.dart` (lines 96-128)

```dart
void triggerSpecialBonus() {
  // ... spawns bonus balls ...
  for (int i = 0; i < _bonusBallsToAdd; i++) {
    final bonusBall = Ball(...);
    _activeBalls.add(bonusBall);  // NO VISUAL FEEDBACK on count change
  }
  // Shows "+X BALLS!" overlay (Task 2.5.3), but no highlight on counter
}
```

**File:** `lib/widgets/pachinko_board.dart`

```dart
// NO confetti system - search for "confetti" or "particle" returns nothing
// May have been present in earlier version and accidentally removed
```

### User Report

> **Test 9 (Partial) - Visual Bonus Feedback:**
> - ❌ No visual indicator for points bonus (text only)
> - ❌ No visual indicator for ball bonus (just count changes)
> - ❌ Confetti visual effect missing (was present previously?)
> - Expected: Eye-catching visual feedback for bonus events

---

## Implementation Requirements

### 1. Floating Points Text System

**Create new widget:** `lib/widgets/floating_text.dart`

```dart
import 'package:flutter/material.dart';

/// Animated floating text for score feedback
class FloatingText {
  final String text;
  final Offset startPosition;
  final Color color;
  double opacity = 1.0;
  double yOffset = 0.0;
  double timer = 0.0;
  static const double duration = 1.5; // seconds

  FloatingText({
    required this.text,
    required this.startPosition,
    this.color = Colors.yellow,
  });

  /// Update animation state (call every frame)
  /// Returns true if animation complete
  bool update(double deltaTime) {
    timer += deltaTime;

    if (timer >= duration) {
      return true; // Animation complete
    }

    // Float upward
    yOffset = timer * 50.0; // 50 pixels per second

    // Fade out in last 0.5 seconds
    if (timer >= duration - 0.5) {
      opacity = (duration - timer) / 0.5;
    }

    return false;
  }

  Offset get currentPosition => Offset(
    startPosition.dx,
    startPosition.dy - yOffset,
  );
}
```

**Add to GameState:** `lib/models/game_state.dart`

```dart
class GameState extends ChangeNotifier {
  // Existing fields...
  final List<FloatingText> _floatingTexts = [];
  List<FloatingText> get floatingTexts => List.unmodifiable(_floatingTexts);

  void addFloatingText(String text, Offset position, Color color) {
    _floatingTexts.add(FloatingText(
      text: text,
      startPosition: position,
      color: color,
    ));
    notifyListeners();
  }

  void updateFloatingTexts(double deltaTime) {
    _floatingTexts.removeWhere((text) => text.update(deltaTime));
  }
}
```

**Trigger on slot hit:** `lib/services/game_manager.dart`

```dart
void _handleSlotHits(List<Slot> hitSlots) {
  for (final slot in hitSlots) {
    _gameState.addScore(slot.pointValue);
    _audioService?.playSlotScore(slot.pointValue);

    // ADD: Floating text for visual feedback
    _gameState.addFloatingText(
      '+${slot.pointValue}',
      Offset(slot.position.x, slot.position.y - 20), // Above slot
      _getScoreColor(slot.pointValue),
    );

    if (slot.pointValue >= 2000) {
      _achievementService?.trackEdgeSlot();
    }
  }
}

Color _getScoreColor(int points) {
  if (points >= 2000) return const Color(0xFFFFD700); // Gold
  if (points >= 1000) return const Color(0xFFFFA500); // Orange
  if (points >= 500) return const Color(0xFFFFFF00); // Yellow
  return Colors.white;
}
```

**Render in board:** `lib/widgets/pachinko_board.dart`

```dart
void paint(Canvas canvas, Size size) {
  // ... existing rendering ...

  // Draw floating texts
  for (final floatingText in gameState.floatingTexts) {
    _drawFloatingText(canvas, floatingText);
  }

  canvas.restore();
}

void _drawFloatingText(Canvas canvas, FloatingText floatingText) {
  final textPainter = TextPainter(
    text: TextSpan(
      text: floatingText.text,
      style: TextStyle(
        color: floatingText.color.withOpacity(floatingText.opacity),
        fontSize: 20,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(floatingText.opacity * 0.5),
            blurRadius: 4,
            offset: const Offset(1, 1),
          ),
        ],
      ),
    ),
    textDirection: TextDirection.ltr,
  );
  textPainter.layout();
  textPainter.paint(
    canvas,
    Offset(
      floatingText.currentPosition.dx - textPainter.width / 2,
      floatingText.currentPosition.dy,
    ),
  );
}
```

**Update texts in game loop:** `lib/services/game_manager.dart`

```dart
void _updateGame(Timer timer) {
  final currentTime = DateTime.now();
  final deltaTime = currentTime.difference(_lastFrameTime).inMicroseconds / 1000000.0;
  _lastFrameTime = currentTime;

  final clampedDeltaTime = deltaTime.clamp(0.0, 1.0 / 30.0);

  _updatePhysics(clampedDeltaTime);

  // ADD: Update floating text animations
  _gameState.updateFloatingTexts(clampedDeltaTime);

  _checkGameState();
  notifyListeners();
}
```

---

### 2. Ball Counter Highlight Animation

**Extend GameState:** `lib/models/game_state.dart`

```dart
class GameState extends ChangeNotifier {
  // Existing fields...
  bool _ballCountHighlighted = false;
  double _ballCountHighlightTimer = 0.0;
  static const double _ballCountHighlightDuration = 1.0; // 1 second

  bool get ballCountHighlighted => _ballCountHighlighted;

  void triggerSpecialBonus() {
    if (_specialBonusTriggered) return;

    _specialBonusTriggered = true;
    _bonusOverlayOpacity = 1.0;
    _bonusBallsToAdd = 5 + (_currentLevelNumber ~/ 2);

    // Spawn bonus balls
    final level = _currentLevel;
    if (level != null) {
      for (int i = 0; i < _bonusBallsToAdd; i++) {
        final bonusBall = Ball(...);
        _activeBalls.add(bonusBall);
      }
      _bonusBallsToAdd = 0;

      // ADD: Trigger ball counter highlight
      _ballCountHighlighted = true;
      _ballCountHighlightTimer = _ballCountHighlightDuration;
    }

    // ... existing timer code ...
  }

  void updateBallCountHighlight(double deltaTime) {
    if (_ballCountHighlightTimer > 0) {
      _ballCountHighlightTimer -= deltaTime;
      if (_ballCountHighlightTimer <= 0) {
        _ballCountHighlighted = false;
        _ballCountHighlightTimer = 0;
      }
    }
  }
}
```

**Update in game loop:** `lib/services/game_manager.dart`

```dart
void _updateGame(Timer timer) {
  // ... existing code ...
  _gameState.updateFloatingTexts(clampedDeltaTime);
  _gameState.updateBallCountHighlight(clampedDeltaTime); // ADD
  _checkGameState();
  notifyListeners();
}
```

**Render highlight on HUD:** (Assuming HUD shows ball count in GameScreen)

```dart
// lib/screens/game_screen.dart or wherever ball count is displayed
Widget _buildBallCounter() {
  final highlighted = gameManager.gameState.ballCountHighlighted;

  return AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: highlighted
        ? const Color(0xFFFFD700).withOpacity(0.3) // Gold highlight
        : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: highlighted
          ? const Color(0xFFFFD700)
          : Colors.white.withOpacity(0.5),
        width: highlighted ? 3 : 1,
      ),
    ),
    child: Text(
      'Balls: ${gameManager.gameState.ballsRemaining}',
      style: TextStyle(
        color: highlighted ? const Color(0xFFFFD700) : Colors.white,
        fontSize: highlighted ? 20 : 16,
        fontWeight: highlighted ? FontWeight.bold : FontWeight.normal,
      ),
    ),
  );
}
```

---

### 3. Confetti Particle System

**Create confetti model:** `lib/models/confetti_particle.dart`

```dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

class ConfettiParticle {
  Vector2 position;
  Vector2 velocity;
  final Color color;
  final double size;
  double rotation = 0.0;
  double rotationSpeed;
  double lifetime = 0.0;
  static const double maxLifetime = 2.0; // 2 seconds

  ConfettiParticle({
    required this.position,
    required this.velocity,
    required this.color,
    this.size = 8.0,
  }) : rotationSpeed = (math.Random().nextDouble() - 0.5) * 10.0;

  /// Update particle physics
  /// Returns true if particle expired
  bool update(double deltaTime) {
    lifetime += deltaTime;

    if (lifetime >= maxLifetime) {
      return true; // Particle expired
    }

    // Gravity
    velocity.y += 300.0 * deltaTime; // pixels/s²

    // Update position
    position.add(velocity * deltaTime);

    // Rotation
    rotation += rotationSpeed * deltaTime;

    return false;
  }

  double get opacity {
    // Fade out in last 0.5 seconds
    if (lifetime >= maxLifetime - 0.5) {
      return (maxLifetime - lifetime) / 0.5;
    }
    return 1.0;
  }
}
```

**Add to GameState:** `lib/models/game_state.dart`

```dart
import 'dart:math' as math;
import '../models/confetti_particle.dart';

class GameState extends ChangeNotifier {
  final List<ConfettiParticle> _confettiParticles = [];
  List<ConfettiParticle> get confettiParticles => List.unmodifiable(_confettiParticles);

  void spawnConfetti(Vector2 position, int count) {
    final random = math.Random();

    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 2 * math.pi + random.nextDouble() * 0.5;
      final speed = 100.0 + random.nextDouble() * 150.0;

      final particle = ConfettiParticle(
        position: position.clone(),
        velocity: Vector2(
          math.cos(angle) * speed,
          math.sin(angle) * speed - 200.0, // Initial upward bias
        ),
        color: _randomConfettiColor(random),
        size: 6.0 + random.nextDouble() * 6.0,
      );

      _confettiParticles.add(particle);
    }

    notifyListeners();
  }

  Color _randomConfettiColor(math.Random random) {
    final colors = [
      const Color(0xFFFFD700), // Gold
      const Color(0xFFFF6B6B), // Red
      const Color(0xFF4ECDC4), // Cyan
      const Color(0xFFFFA500), // Orange
      const Color(0xFF95E1D3), // Mint
      const Color(0xFFF38181), // Pink
    ];
    return colors[random.nextInt(colors.length)];
  }

  void updateConfetti(double deltaTime) {
    _confettiParticles.removeWhere((particle) => particle.update(deltaTime));
  }
}
```

**Trigger confetti on special bonus:** `lib/services/game_manager.dart`

```dart
void _checkSpecialBonus() {
  final level = _gameState.currentLevel;
  if (level == null || _gameState.specialBonusTriggered) return;

  if (level.allSpecialPegsHit) {
    _gameState.triggerSpecialBonus();
    _audioService?.playBonusTrigger();

    // ADD: Spawn confetti at center of board
    _gameState.spawnConfetti(
      Vector2(GameConstants.boardWidth / 2, GameConstants.boardHeight / 2),
      50, // 50 confetti particles
    );

    _achievementService?.trackAllSpecialPegsHit();
    _achievementService?.trackSpecialBonus();
  }
}
```

**Update confetti in game loop:** `lib/services/game_manager.dart`

```dart
void _updateGame(Timer timer) {
  // ... existing code ...
  _gameState.updateFloatingTexts(clampedDeltaTime);
  _gameState.updateBallCountHighlight(clampedDeltaTime);
  _gameState.updateConfetti(clampedDeltaTime); // ADD
  _checkGameState();
  notifyListeners();
}
```

**Render confetti:** `lib/widgets/pachinko_board.dart`

```dart
void paint(Canvas canvas, Size size) {
  // ... existing rendering ...

  // Draw confetti (BEFORE floating texts so they appear on top)
  for (final particle in gameState.confettiParticles) {
    _drawConfettiParticle(canvas, particle);
  }

  // Draw floating texts
  for (final floatingText in gameState.floatingTexts) {
    _drawFloatingText(canvas, floatingText);
  }

  canvas.restore();
}

void _drawConfettiParticle(Canvas canvas, ConfettiParticle particle) {
  canvas.save();

  // Translate to particle position
  canvas.translate(particle.position.x, particle.position.y);

  // Rotate
  canvas.rotate(particle.rotation);

  // Draw rectangle (confetti piece)
  final paint = Paint()
    ..color = particle.color.withOpacity(particle.opacity)
    ..style = PaintingStyle.fill;

  canvas.drawRect(
    Rect.fromCenter(
      center: Offset.zero,
      width: particle.size,
      height: particle.size * 0.6,
    ),
    paint,
  );

  canvas.restore();
}
```

---

## Testing Requirements

### Unit Tests

**File:** `test/models/floating_text_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pachinko/widgets/floating_text.dart';
import 'package:flutter/material.dart';

void main() {
  group('FloatingText', () {
    test('given new floating text, when created, then opacity is 1.0', () {
      final text = FloatingText(
        text: '+500',
        startPosition: const Offset(100, 100),
      );

      expect(text.opacity, 1.0);
      expect(text.yOffset, 0.0);
    });

    test('given floating text, when update called for 0.5s, then yOffset increases', () {
      final text = FloatingText(
        text: '+500',
        startPosition: const Offset(100, 100),
      );

      text.update(0.5);

      expect(text.yOffset, closeTo(25.0, 1.0)); // 50 px/s * 0.5s
      expect(text.opacity, 1.0); // Not fading yet
    });

    test('given floating text, when 1.5s elapsed, then animation complete', () {
      final text = FloatingText(
        text: '+500',
        startPosition: const Offset(100, 100),
      );

      final complete = text.update(1.5);

      expect(complete, true);
    });

    test('given floating text at 1.2s, when updated, then opacity fading', () {
      final text = FloatingText(
        text: '+500',
        startPosition: const Offset(100, 100),
      );

      text.update(1.2);

      expect(text.opacity, lessThan(1.0));
      expect(text.opacity, greaterThan(0.0));
    });
  });
}
```

**File:** `test/models/confetti_particle_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pachinko/models/confetti_particle.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:flutter/material.dart';

void main() {
  group('ConfettiParticle', () {
    test('given new particle, when created, then lifetime is 0', () {
      final particle = ConfettiParticle(
        position: Vector2(100, 100),
        velocity: Vector2(50, -100),
        color: Colors.red,
      );

      expect(particle.lifetime, 0.0);
      expect(particle.opacity, 1.0);
    });

    test('given particle, when update called, then position changes', () {
      final particle = ConfettiParticle(
        position: Vector2(100, 100),
        velocity: Vector2(50, -100),
        color: Colors.red,
      );

      final initialY = particle.position.y;
      particle.update(1/60); // One frame

      expect(particle.position.y, isNot(initialY));
    });

    test('given particle, when gravity applied, then velocity.y increases', () {
      final particle = ConfettiParticle(
        position: Vector2(100, 100),
        velocity: Vector2(0, -100),
        color: Colors.red,
      );

      final initialVy = particle.velocity.y;
      particle.update(0.1);

      expect(particle.velocity.y, greaterThan(initialVy)); // Gravity effect
    });

    test('given particle alive for 2s, when updated, then expired', () {
      final particle = ConfettiParticle(
        position: Vector2(100, 100),
        velocity: Vector2(0, 0),
        color: Colors.red,
      );

      final expired = particle.update(2.0);

      expect(expired, true);
    });
  });
}
```

**File:** `test/models/game_state_test.dart` (add to existing tests)

```dart
group('Visual Feedback', () {
  test('given floating text added, when accessed, then text in list', () {
    final gameState = GameState();

    gameState.addFloatingText(
      '+500',
      const Offset(100, 100),
      Colors.yellow,
    );

    expect(gameState.floatingTexts.length, 1);
    expect(gameState.floatingTexts.first.text, '+500');
  });

  test('given confetti spawned, when accessed, then particles in list', () {
    final gameState = GameState();

    gameState.spawnConfetti(Vector2(200, 200), 10);

    expect(gameState.confettiParticles.length, 10);
  });

  test('given floating text, when 1.5s elapsed, then text removed', () async {
    final gameState = GameState();
    gameState.addFloatingText('+500', const Offset(100, 100), Colors.yellow);

    // Simulate 1.5 seconds of updates
    for (int i = 0; i < 90; i++) {
      gameState.updateFloatingTexts(1/60);
    }

    expect(gameState.floatingTexts.isEmpty, true);
  });

  test('given ball counter highlight triggered, when updated, then highlight active', () {
    final gameState = GameState();
    gameState.startNewGame(level: 1);

    gameState.triggerSpecialBonus();

    expect(gameState.ballCountHighlighted, true);
  });

  test('given ball counter highlight, when 1s elapsed, then highlight off', () {
    final gameState = GameState();
    gameState.startNewGame(level: 1);
    gameState.triggerSpecialBonus();

    // Simulate 1.1 seconds of updates
    for (int i = 0; i < 66; i++) {
      gameState.updateBallCountHighlight(1/60);
    }

    expect(gameState.ballCountHighlighted, false);
  });
});
```

### Manual Testing Scenarios

**Test 9 - Visual Bonus Feedback:**

1. **Points Bonus Visual:**
   - Launch balls and land in scoring slots
   - Verify floating "+X" text appears above each slot
   - Confirm text floats upward and fades out
   - Check color coding: Gold (2000+), Orange (1000+), Yellow (500+), White (50-200)

2. **Ball Bonus Visual:**
   - Trigger special bonus (hit all special pegs)
   - Verify ball counter highlights with gold border
   - Confirm highlight lasts ~1 second then fades
   - Check animated container transition is smooth

3. **Confetti Effect:**
   - Trigger special bonus
   - Verify 50 confetti particles spawn at center
   - Confirm particles spread outward and fall with gravity
   - Check particles rotate and fade out over 2 seconds
   - Verify multiple colors (gold, red, cyan, orange, mint, pink)

4. **Performance:**
   - Trigger bonus with many active balls
   - Spawn multiple floating texts simultaneously
   - Verify 60 FPS maintained with confetti + floating text + gameplay

---

## Success Criteria

### Functional Requirements
- ✅ Floating "+X points!" text appears on every slot hit
- ✅ Text floats upward 50px/s and fades out over 1.5s
- ✅ Text color matches score tier (gold/orange/yellow/white)
- ✅ Ball counter highlights for 1 second on bonus trigger
- ✅ 50 confetti particles spawn on special bonus
- ✅ Confetti spreads outward, falls with gravity, rotates
- ✅ Confetti fades out over 2 seconds
- ✅ 6 different confetti colors for variety

### Code Quality Requirements
- ✅ All existing tests still passing
- ✅ New visual feedback tests added (8+ tests)
- ✅ Code coverage maintained above 85%
- ✅ No memory leaks (particles/texts properly cleaned up)
- ✅ Performance: 60 FPS maintained with all effects active

### User Experience Requirements
- ✅ Test 9 (Visual Bonus Feedback) achieves FULL PASS
- ✅ Eye-catching visual feedback for all bonus events
- ✅ No visual clutter (effects auto-dismiss appropriately)
- ✅ Effects enhance excitement without distracting from gameplay

---

## Files to Modify

1. **`/home/frankbria/projects/pachinko/lib/widgets/floating_text.dart`** (NEW)
   - Create FloatingText class for score popups

2. **`/home/frankbria/projects/pachinko/lib/models/confetti_particle.dart`** (NEW)
   - Create ConfettiParticle physics model

3. **`/home/frankbria/projects/pachinko/lib/models/game_state.dart`**
   - Add floatingTexts list and management methods
   - Add confettiParticles list and spawnConfetti()
   - Add ballCountHighlighted flag and timer
   - Add update methods for all visual effects

4. **`/home/frankbria/projects/pachinko/lib/services/game_manager.dart`**
   - Add floating text on slot hits (_handleSlotHits)
   - Add confetti on special bonus (_checkSpecialBonus)
   - Update all visual effects in _updateGame()

5. **`/home/frankbria/projects/pachinko/lib/widgets/pachinko_board.dart`**
   - Add _drawFloatingText() method
   - Add _drawConfettiParticle() method
   - Render effects in paint()

6. **`/home/frankbria/projects/pachinko/lib/screens/game_screen.dart`** (or HUD widget)
   - Add animated ball counter highlight
   - Use AnimatedContainer for smooth transitions

7. **`/home/frankbria/projects/pachinko/test/widgets/floating_text_test.dart`** (NEW)
   - Test floating text animation lifecycle

8. **`/home/frankbria/projects/pachinko/test/models/confetti_particle_test.dart`** (NEW)
   - Test confetti particle physics and expiration

9. **`/home/frankbria/projects/pachinko/test/models/game_state_test.dart`**
   - Add visual feedback test group (6 tests)

---

## Performance Considerations

**Particle Budget:**
- Confetti: 50 particles max (2s lifetime) = short-lived spike
- Floating texts: ~5 concurrent max (1.5s lifetime each)
- Total objects: ~55 transient visual elements

**Frame Budget (60 FPS = 16.67ms):**
- Confetti update: 50 × 0.02ms = 1ms
- Confetti render: 50 × 0.05ms = 2.5ms
- Floating text: 5 × 0.1ms = 0.5ms
- **Total: ~4ms per frame (24% of budget)**

**Optimization:**
- Use simple shapes (rectangles) for confetti
- No textures or images (pure Canvas drawing)
- Automatic cleanup (no manual management needed)
- Pooling not required (effects are infrequent)

**Verdict:** Negligible performance impact, well within budget

---

## Alternative Approaches Considered

**Approach 1: Flutter Animation Controllers**
- Pros: Built-in animation system
- Cons: Requires AnimationController per particle (overhead)
- **Decision:** Custom delta-time approach simpler and more performant

**Approach 2: External Particle Library**
- Pros: Pre-built particle systems
- Cons: Adds dependency, overkill for simple confetti
- **Decision:** Custom implementation matches codebase patterns

**Approach 3: Texture-Based Confetti**
- Pros: More visually detailed
- Cons: Asset loading, memory overhead
- **Decision:** Simple colored rectangles sufficient for effect

---

## Acceptance Testing

Before marking this task complete, verify:

1. **Run All Tests:**
   ```bash
   flutter test
   ```
   - All existing tests pass
   - All new visual effect tests pass (8+ tests)

2. **Manual Visual Validation:**
   - Launch game and score in multiple slots
   - Confirm floating text appears with correct colors
   - Trigger special bonus and verify confetti
   - Check ball counter highlight animation

3. **Performance Check:**
   - Use Flutter DevTools performance overlay
   - Trigger bonus with 10 active balls
   - Spawn confetti + multiple floating texts simultaneously
   - Verify 60 FPS maintained

4. **Code Review:**
   - Visual effects properly cleaned up (no leaks)
   - Code follows existing codebase patterns
   - Delta-time updates for all animations
   - Color constants defined appropriately

---

## Commit Message

```
feat(ux): add visual feedback for bonus events with confetti

Adds eye-catching visual effects for scoring and bonus events.

Visual Feedback:
- Floating "+X points!" text on slot hits
- Color-coded by score tier (gold/orange/yellow/white)
- Text floats upward 50px/s and fades out over 1.5s
- Ball counter highlights with gold border on bonus trigger
- Highlight lasts 1 second with smooth AnimatedContainer transition

Confetti System:
- 50 particles spawn on special bonus trigger
- Particles spread outward with randomized velocities
- Gravity physics (300px/s²) for natural falling
- Rotation animation for visual variety
- 6 different colors (gold, red, cyan, orange, mint, pink)
- Auto-fade over 2 seconds

Implementation:
- Created FloatingText class for score popups
- Created ConfettiParticle physics model
- Extended GameState with visual effect management
- Added rendering in pachinko_board.dart
- Integrated updates in game loop (delta-time based)

Tests:
- 8 new tests for visual effects
- Test floating text lifecycle and animation
- Test confetti particle physics and expiration
- All existing tests pass

Performance:
- ~4ms per frame impact (24% of 60 FPS budget)
- Automatic cleanup prevents memory leaks
- 60 FPS maintained with all effects active

Fixes: Test 9 (Partial) - Visual Bonus Feedback → FULL PASS

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

---

## Next Steps After Completion

1. User validates Test 9 achieves FULL PASS
2. Proceed to Task 2.5.5 (Achievement Toast Notifications)
3. Continue Phase 2.5 polish tasks sequentially
