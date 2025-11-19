---
task_id: "Task_2_5_3"
task_name: "Audio Timing & Bonus Screen Behavior"
agent_type: "flutter-expert"
session_date: "2025-11-18"
status: "ready_to_assign"
priority: "high"
dependencies: ["Task_2_5_1", "Task_2_5_2"]
phase: "Phase 2.5 - Gameplay Polish & UX Refinement"
estimated_duration: "2-3 hours"
---

# Task 2.5.3: Audio Timing & Bonus Screen Behavior

## Task Context

**Phase:** Phase 2.5 - Gameplay Polish & UX Refinement
**Blocking Phase:** Phase 3 - Android Optimization
**User Reports:**
- Test 5 (Partial) - Launch Sound Timing: Sound delayed by few milliseconds
- Test 7 (Partial) - Bonus Screen Behavior: Screen stays visible for entire level

---

## Objective

1. Fix launch sound synchronization delay
2. Implement auto-dismiss for bonus screen overlay (2-3 second duration)
3. Improve bonus text to be less technical and more engaging

---

## Problem 1: Launch Sound Delayed

### Current Behavior

**File:** `lib/services/game_manager.dart` (lines ~140-150)

```dart
void launchBall() {
  if (!_gameState.canLaunchBall) return;

  final ball = _ballLauncher.launchBall();
  if (ball != null) {
    _gameState.activeBalls.add(ball);
    _gameState.ballsRemaining--;
    _gameState.notifyListeners();

    // Audio triggered AFTER ball launch logic
    _audioService?.playLaunch();  // <-- TOO LATE, causes delay
  }
}
```

### Root Cause Analysis

The audio playback happens AFTER:
1. Ball state is created and configured
2. Ball is added to active balls list
3. Game state is decremented and notified
4. Multiple notifyListeners() calls trigger UI rebuild

This sequential processing creates 5-15ms delay before audio plays.

### Solution: Move Audio to Start of Launch Sequence

**Updated Method:**
```dart
void launchBall() {
  if (!_gameState.canLaunchBall) return;

  // Play audio IMMEDIATELY - before any state changes
  _audioService?.playLaunch();

  final ball = _ballLauncher.launchBall();
  if (ball != null) {
    _gameState.activeBalls.add(ball);
    _gameState.ballsRemaining--;
    _gameState.notifyListeners();
  }
}
```

### Additional Investigation: AudioService Preloading

**File:** `lib/services/audio_service.dart`

**Check if assets are preloaded:**
```dart
class AudioService {
  late AudioPlayer _launchPlayer;

  Future<void> initialize() async {
    _launchPlayer = AudioPlayer();

    // Ensure launch sound is preloaded and ready
    await _launchPlayer.setAsset('assets/sounds/launch.mp3');
    await _launchPlayer.load();  // Preload to memory

    // Set to start position so first play is instant
    await _launchPlayer.seek(Duration.zero);
  }

  void playLaunch() {
    // Reset to start position for immediate playback
    _launchPlayer.seek(Duration.zero);
    _launchPlayer.play();
  }
}
```

**If AudioService doesn't preload, add initialization in main.dart:**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final audioService = AudioService();
  await audioService.initialize();  // Preload all sounds

  runApp(MyApp(audioService: audioService));
}
```

---

## Problem 2: Bonus Screen Stays Visible Forever

### Current Behavior

**File:** `lib/models/game_state.dart`

```dart
bool specialBonusTriggered = false;

void triggerSpecialBonus() {
  specialBonusTriggered = true;  // Set to true
  // NO AUTO-DISMISS LOGIC
  notifyListeners();
}
```

**File:** `lib/widgets/pachinko_board.dart`

```dart
if (gameState.specialBonusTriggered) {
  _drawSpecialBonusEffect(canvas, size, scale);
  // Drawn every frame until manually dismissed
}
```

### User Report
> "Bonus screen stays visible for entire level. Expected: Auto-dismiss after 2-3 seconds."

### Solution: Add Timer-Based Auto-Dismiss

**Approach 1: GameState Timer (Recommended)**

**File:** `lib/models/game_state.dart`

```dart
class GameState extends ChangeNotifier {
  bool specialBonusTriggered = false;
  Timer? _bonusDisplayTimer;

  void triggerSpecialBonus() {
    specialBonusTriggered = true;
    notifyListeners();

    // Auto-dismiss after 2.5 seconds
    _bonusDisplayTimer?.cancel();
    _bonusDisplayTimer = Timer(Duration(milliseconds: 2500), () {
      specialBonusTriggered = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _bonusDisplayTimer?.cancel();
    super.dispose();
  }
}
```

**Approach 2: Animation-Based (Alternative)**

If you want fade-out animation:

```dart
class GameState extends ChangeNotifier {
  bool specialBonusTriggered = false;
  double bonusOverlayOpacity = 0.0;
  Timer? _bonusDisplayTimer;
  Timer? _bonusFadeTimer;

  void triggerSpecialBonus() {
    specialBonusTriggered = true;
    bonusOverlayOpacity = 1.0;
    notifyListeners();

    // Hold at full opacity for 2 seconds
    _bonusDisplayTimer?.cancel();
    _bonusDisplayTimer = Timer(Duration(milliseconds: 2000), () {
      _startBonusFadeOut();
    });
  }

  void _startBonusFadeOut() {
    // Fade out over 0.5 seconds (500ms)
    const fadeSteps = 30;  // 30 frames at ~60 FPS
    const fadeDuration = Duration(milliseconds: 500);
    const stepDuration = Duration(milliseconds: fadeDuration.inMilliseconds ~/ fadeSteps);

    int currentStep = 0;
    _bonusFadeTimer?.cancel();
    _bonusFadeTimer = Timer.periodic(stepDuration, (timer) {
      currentStep++;
      bonusOverlayOpacity = 1.0 - (currentStep / fadeSteps);

      if (currentStep >= fadeSteps) {
        bonusOverlayOpacity = 0.0;
        specialBonusTriggered = false;
        timer.cancel();
      }

      notifyListeners();
    });
  }

  @override
  void dispose() {
    _bonusDisplayTimer?.cancel();
    _bonusFadeTimer?.cancel();
    super.dispose();
  }
}
```

Then update rendering:

**File:** `lib/widgets/pachinko_board.dart`

```dart
void _drawSpecialBonusEffect(Canvas canvas, Size size, double scale) {
  // Use gameState.bonusOverlayOpacity instead of hardcoded 0.3
  final paint = Paint()
    ..color = GameConstants.bonusBallColor.withOpacity(gameState.bonusOverlayOpacity * 0.3)
    ..style = PaintingStyle.fill;

  canvas.drawRect(
    Rect.fromLTWH(0, 0, GameConstants.boardWidth, GameConstants.boardHeight),
    paint,
  );

  // Bonus text also uses opacity
  final textPainter = TextPainter(
    text: TextSpan(
      text: 'BONUS!',  // Simplified text (see Problem 3)
      style: TextStyle(
        color: GameConstants.bonusBallColor.withOpacity(gameState.bonusOverlayOpacity),
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
    ),
    textDirection: TextDirection.ltr,
  );
  textPainter.layout();
  textPainter.paint(
    canvas,
    Offset(
      (GameConstants.boardWidth - textPainter.width) / 2,
      GameConstants.boardHeight / 2 - textPainter.height / 2,
    ),
  );
}
```

---

## Problem 3: Technical Bonus Text

### Current Text
```dart
text: 'SPECIAL BONUS!'  // or similar technical phrasing
```

### User Feedback
> "Less sterile bonus text ('BONUS!' instead of technical text)"

### Solution: Simplified, Engaging Text

**Options:**
1. **"BONUS!"** - Simple, clear, exciting
2. **"JACKPOT!"** - High-energy, arcade feel
3. **"MEGA BONUS!"** - Emphasizes magnitude
4. **"+X BALLS!"** - Shows actual reward (e.g., "+5 BALLS!")

**Recommended:**
```dart
// Show actual bonus amount for clarity
final bonusBalls = GameConstants.bonusBallsBase + (_gameState.currentLevel?.number ?? 0) ~/ 2;

text: '+$bonusBalls BALLS!',
style: TextStyle(
  color: GameConstants.bonusBallColor.withOpacity(gameState.bonusOverlayOpacity),
  fontSize: 36,
  fontWeight: FontWeight.bold,
  shadows: [
    Shadow(
      color: Colors.black.withOpacity(0.5),
      blurRadius: 8,
      offset: Offset(2, 2),
    ),
  ],
),
```

**Alternative (simpler):**
```dart
text: 'BONUS!',
```

---

## Testing Requirements

### Unit Tests

**File:** `test/models/game_state_test.dart`

```dart
group('Special Bonus Auto-Dismiss', () {
  test('given bonus triggered, when 2.5 seconds elapse, then bonus flag resets', () async {
    final gameState = GameState();
    gameState.triggerSpecialBonus();

    expect(gameState.specialBonusTriggered, true);

    // Wait 2.6 seconds
    await Future.delayed(Duration(milliseconds: 2600));

    expect(gameState.specialBonusTriggered, false);
  });

  test('given bonus triggered, when less than 2 seconds elapse, then bonus still visible', () async {
    final gameState = GameState();
    gameState.triggerSpecialBonus();

    // Wait 1 second
    await Future.delayed(Duration(milliseconds: 1000));

    expect(gameState.specialBonusTriggered, true);
  });

  test('given bonus triggered twice in quick succession, when timer runs, then only one dismissal occurs', () async {
    final gameState = GameState();

    gameState.triggerSpecialBonus();
    await Future.delayed(Duration(milliseconds: 500));
    gameState.triggerSpecialBonus();  // Trigger again (should cancel first timer)

    // Wait 2.6 seconds from SECOND trigger
    await Future.delayed(Duration(milliseconds: 2600));

    expect(gameState.specialBonusTriggered, false);
  });
});
```

### Manual Testing Scenarios

**Test 5 - Launch Sound Timing:**
1. Launch multiple balls in quick succession
2. Listen for audio delay relative to visual launch
3. Confirm audio plays IMMEDIATELY when ball launches
4. No perceptible gap between action and sound

**Test 7 - Bonus Screen Auto-Dismiss:**
1. Hit all special pegs to trigger bonus
2. Observe "BONUS!" (or "+X BALLS!") overlay appears
3. Count seconds - overlay should fade/dismiss after 2-3 seconds
4. Verify gameplay continues normally after dismissal
5. Trigger bonus multiple times - each should auto-dismiss independently

---

## Success Criteria

### Audio Timing (Test 5 FULL PASS)
- ✅ Launch sound plays within 5ms of launch action
- ✅ No perceptible delay between visual and audio
- ✅ Audio playback is crisp and immediate
- ✅ Preloading ensures first sound is instant

### Bonus Screen Auto-Dismiss (Test 7 FULL PASS)
- ✅ Bonus overlay appears when all special pegs hit
- ✅ Overlay auto-dismisses after 2-3 seconds
- ✅ Smooth fade-out animation (if implemented)
- ✅ Multiple bonus triggers work independently
- ✅ Timer cleanup on dispose (no memory leaks)

### Bonus Text Polish
- ✅ Text is engaging and non-technical
- ✅ Shows actual bonus amount (if "+X BALLS!" approach)
- ✅ Large, readable font size
- ✅ Good visual contrast (shadow/outline)

### Code Quality
- ✅ All existing tests pass
- ✅ New timer tests added and passing
- ✅ No timer leaks (proper disposal)
- ✅ Code coverage maintained above 85%
- ✅ 60 FPS maintained (no performance regression)

---

## Files to Modify

1. **`/home/frankbria/projects/pachinko/lib/services/game_manager.dart`**
   - Move `_audioService?.playLaunch()` to start of `launchBall()` method

2. **`/home/frankbria/projects/pachinko/lib/services/audio_service.dart`**
   - Add `initialize()` method with asset preloading
   - Ensure sounds are loaded into memory before first play

3. **`/home/frankbria/projects/pachinko/lib/models/game_state.dart`**
   - Add `Timer? _bonusDisplayTimer` field
   - Add `double bonusOverlayOpacity` field (if using fade)
   - Implement auto-dismiss in `triggerSpecialBonus()`
   - Add `_startBonusFadeOut()` method (if using fade)
   - Cancel timer in `dispose()`

4. **`/home/frankbria/projects/pachinko/lib/widgets/pachinko_board.dart`**
   - Update `_drawSpecialBonusEffect()` to use opacity from gameState
   - Change bonus text to "BONUS!" or "+X BALLS!"
   - Add text shadow for better readability

5. **`/home/frankbria/projects/pachinko/lib/main.dart`**
   - Add `await audioService.initialize()` before `runApp()`
   - Ensure audio is preloaded before game starts

6. **`/home/frankbria/projects/pachinko/test/models/game_state_test.dart`**
   - Add test group for bonus auto-dismiss
   - Test timer behavior with async/await

---

## Implementation Checklist

- [ ] Move audio playback to start of launch sequence
- [ ] Add AudioService preloading with initialization
- [ ] Implement bonus overlay timer in GameState
- [ ] Add opacity field for fade animation (optional but recommended)
- [ ] Update bonus text to simplified version
- [ ] Add text shadow for better contrast
- [ ] Write timer unit tests with async/await
- [ ] Run all tests and confirm passing
- [ ] Manual validation of audio timing
- [ ] Manual validation of bonus auto-dismiss
- [ ] Performance check (60 FPS maintained)
- [ ] Commit with conventional commit message

---

## Commit Message

```
feat(ux): fix audio timing and implement bonus screen auto-dismiss

Audio Improvements:
- Move launch sound playback to start of launch sequence
- Add AudioService preloading for instant first play
- Eliminate 5-15ms delay in sound synchronization

Bonus Screen Behavior:
- Implement 2.5-second auto-dismiss timer for bonus overlay
- Add smooth fade-out animation (opacity 1.0 -> 0.0 over 0.5s)
- Simplify bonus text to "BONUS!" or "+X BALLS!" (more engaging)
- Add text shadow for better readability
- Prevent timer leaks with proper disposal

Tests:
- Add async timer tests for bonus auto-dismiss
- Verify audio preloading behavior
- All existing tests pass

Fixes:
- Test 5 (Partial) -> FULL PASS - Audio perfectly synchronized
- Test 7 (Partial) -> FULL PASS - Bonus screen auto-dismisses after 2-3s

Performance: 60 FPS maintained, no regressions

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

---

## Next Steps After Completion

1. User validates Test 5 and Test 7 achieve FULL PASS
2. Proceed to Task 2.5.4 (Visual Bonus Feedback & Confetti)
3. Continue Phase 2.5 polish tasks
