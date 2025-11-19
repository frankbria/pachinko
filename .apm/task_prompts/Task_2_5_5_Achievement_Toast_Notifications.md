---
task_id: "Task_2_5_5"
task_name: "Achievement Toast Notifications"
agent_type: "flutter-expert"
session_date: "2025-11-18"
status: "ready_to_assign"
priority: "medium"
dependencies: ["Task_2_5_1", "Task_2_5_2", "Task_2_5_3", "Task_2_5_4"]
phase: "Phase 2.5 - Gameplay Polish & UX Refinement"
estimated_duration: "2-3 hours"
---

# Task 2.5.5: Achievement Toast Notifications

## Task Context

**Phase:** Phase 2.5 - Gameplay Polish & UX Refinement
**Blocking Phase:** Phase 3 - Android Optimization
**User Request:** Test 12 Enhancement - Achievement Notifications

**Problem:** Achievement unlocks are silent. Users must manually navigate to achievements screen to discover unlocked achievements. No immediate feedback reduces sense of accomplishment.

---

## Objective

Implement in-game toast notifications that appear when achievements unlock, providing immediate visual feedback without interrupting gameplay.

---

## Current Behavior Analysis

### File: `lib/services/achievement_service.dart`

**Achievement unlock logic:**
```dart
class AchievementService {
  final List<Achievement> _achievements = [];

  void checkAchievements() {
    for (final achievement in _achievements) {
      if (!achievement.isUnlocked && achievement.progress >= achievement.requiredCount) {
        achievement.unlock(); // Silent unlock
        // NO NOTIFICATION TRIGGERED
      }
    }
  }
}
```

**User Feedback:**
> "Achievement unlocks currently silent. User must manually check achievements screen. Toast notification provides immediate feedback."

### Desired Behavior

**When achievement unlocks:**
1. Toast notification slides in from top
2. Shows achievement icon, name, and point value
3. Displays for 3-4 seconds
4. Fades out automatically
5. Multiple toasts queue properly (no overlap)

---

## Implementation Requirements

### 1. Create Achievement Toast Widget

**New file:** `lib/widgets/achievement_toast.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/achievement.dart';

/// Animated toast notification for achievement unlocks
class AchievementToast extends StatefulWidget {
  final Achievement achievement;
  final VoidCallback? onDismissed;

  const AchievementToast({
    super.key,
    required this.achievement,
    this.onDismissed,
  });

  @override
  State<AchievementToast> createState() => _AchievementToastState();
}

class _AchievementToastState extends State<AchievementToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      reverseDuration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Slide in from top
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ));

    // Fade animation
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
      reverseCurve: Curves.easeOut,
    ));

    // Start animation
    _controller.forward();

    // Auto-dismiss after 3.5 seconds
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        _dismiss();
      }
    });

    // Haptic feedback
    HapticFeedback.mediumImpact();
  }

  void _dismiss() async {
    await _controller.reverse();
    if (mounted) {
      widget.onDismissed?.call();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: GestureDetector(
          onTap: _dismiss,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF2C3E50),
                  const Color(0xFF34495E),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: const Color(0xFFFFD700), // Gold border
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Achievement Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getAchievementIcon(widget.achievement),
                    color: const Color(0xFFFFD700),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                // Achievement Info
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Achievement Unlocked!',
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.achievement.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.achievement.points} points',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Trophy Icon
                const Icon(
                  Icons.emoji_events,
                  color: Color(0xFFFFD700),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getAchievementIcon(Achievement achievement) {
    // Map achievement types to icons
    final name = achievement.name.toLowerCase();
    if (name.contains('first') || name.contains('beginner')) {
      return Icons.rocket_launch;
    } else if (name.contains('master') || name.contains('expert')) {
      return Icons.star;
    } else if (name.contains('edge') || name.contains('slot')) {
      return Icons.gps_fixed;
    } else if (name.contains('ball') || name.contains('launch')) {
      return Icons.sports_baseball;
    } else if (name.contains('special') || name.contains('bonus')) {
      return Icons.auto_awesome;
    } else if (name.contains('level') || name.contains('complete')) {
      return Icons.flag;
    } else if (name.contains('score') || name.contains('points')) {
      return Icons.trending_up;
    } else {
      return Icons.emoji_events;
    }
  }
}
```

---

### 2. Create Toast Overlay Manager

**New file:** `lib/widgets/achievement_toast_overlay.dart`

```dart
import 'package:flutter/material.dart';
import '../models/achievement.dart';
import 'achievement_toast.dart';

/// Manages achievement toast queue and display
class AchievementToastOverlay extends StatefulWidget {
  final Widget child;

  const AchievementToastOverlay({
    super.key,
    required this.child,
  });

  static AchievementToastOverlayState? of(BuildContext context) {
    return context.findAncestorStateOfType<AchievementToastOverlayState>();
  }

  @override
  State<AchievementToastOverlay> createState() =>
      AchievementToastOverlayState();
}

class AchievementToastOverlayState extends State<AchievementToastOverlay> {
  final List<Achievement> _toastQueue = [];
  Achievement? _currentToast;

  /// Show achievement toast notification
  void showAchievementToast(Achievement achievement) {
    setState(() {
      if (_currentToast == null) {
        _currentToast = achievement;
      } else {
        // Queue toast if one is already showing
        _toastQueue.add(achievement);
      }
    });
  }

  void _onToastDismissed() {
    setState(() {
      if (_toastQueue.isNotEmpty) {
        // Show next toast from queue
        _currentToast = _toastQueue.removeAt(0);
      } else {
        _currentToast = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_currentToast != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 0,
            right: 0,
            child: AchievementToast(
              achievement: _currentToast!,
              onDismissed: _onToastDismissed,
            ),
          ),
      ],
    );
  }
}
```

---

### 3. Integrate Toast Overlay in App

**File:** `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'widgets/achievement_toast_overlay.dart';
import 'screens/menu_screen.dart';

class PachinkoApp extends StatefulWidget {
  // ... existing code ...
}

class _PachinkoAppState extends State<PachinkoApp> {
  // ... existing fields ...

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pachinko',
      theme: ThemeData.dark(),
      // WRAP with AchievementToastOverlay
      home: AchievementToastOverlay(
        child: MenuScreen(gameManager: _gameManager),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
```

---

### 4. Trigger Toast on Achievement Unlock

**File:** `lib/services/achievement_service.dart`

```dart
import 'package:flutter/foundation.dart';
import '../models/achievement.dart';

class AchievementService extends ChangeNotifier {
  final List<Achievement> _achievements = [];

  // ADD: Callback for achievement unlocks
  final void Function(Achievement)? onAchievementUnlocked;

  AchievementService({
    this.onAchievementUnlocked,
  }) {
    _initializeAchievements();
  }

  void checkAchievements() {
    for (final achievement in _achievements) {
      if (!achievement.isUnlocked &&
          achievement.progress >= achievement.requiredCount) {
        achievement.unlock();

        // TRIGGER TOAST NOTIFICATION
        onAchievementUnlocked?.call(achievement);

        notifyListeners();
      }
    }
  }

  // ... rest of implementation ...
}
```

**File:** `lib/main.dart`

```dart
class _PachinkoAppState extends State<PachinkoApp> {
  late GameManager _gameManager;
  late AudioService _audioService;
  late StorageService _storageService;
  late AchievementService _achievementService;

  @override
  void initState() {
    super.initState();
    _audioService = widget.audioService;
    _storageService = StorageService();

    // CREATE achievement service with toast callback
    _achievementService = AchievementService(
      onAchievementUnlocked: _onAchievementUnlocked, // ADD CALLBACK
    );

    _gameManager = GameManager(
      audioService: _audioService,
      storageService: _storageService,
      achievementService: _achievementService,
    );
  }

  // HANDLE ACHIEVEMENT UNLOCKS
  void _onAchievementUnlocked(Achievement achievement) {
    // Find the toast overlay and show notification
    final overlay = AchievementToastOverlay.of(context);
    overlay?.showAchievementToast(achievement);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pachinko',
      theme: ThemeData.dark(),
      home: AchievementToastOverlay(
        child: MenuScreen(gameManager: _gameManager),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
```

---

## Testing Requirements

### Unit Tests

**File:** `test/widgets/achievement_toast_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pachinko/widgets/achievement_toast.dart';
import 'package:pachinko/models/achievement.dart';

void main() {
  group('AchievementToast', () {
    testWidgets('given achievement toast, when rendered, then shows achievement name',
        (tester) async {
      final achievement = Achievement(
        id: 'test',
        name: 'Test Achievement',
        description: 'Test description',
        points: 100,
        requiredCount: 1,
      );
      achievement.unlock();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AchievementToast(achievement: achievement),
          ),
        ),
      );

      expect(find.text('Test Achievement'), findsOneWidget);
      expect(find.text('100 points'), findsOneWidget);
    });

    testWidgets('given achievement toast, when tapped, then dismisses',
        (tester) async {
      bool dismissed = false;
      final achievement = Achievement(
        id: 'test',
        name: 'Test Achievement',
        description: 'Test',
        points: 100,
        requiredCount: 1,
      );
      achievement.unlock();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AchievementToast(
              achievement: achievement,
              onDismissed: () => dismissed = true,
            ),
          ),
        ),
      );

      await tester.pump(); // Complete initial animation

      // Tap toast
      await tester.tap(find.byType(AchievementToast));
      await tester.pumpAndSettle();

      expect(dismissed, true);
    });

    testWidgets('given achievement toast, when 3.5s elapsed, then auto-dismisses',
        (tester) async {
      bool dismissed = false;
      final achievement = Achievement(
        id: 'test',
        name: 'Test Achievement',
        description: 'Test',
        points: 100,
        requiredCount: 1,
      );
      achievement.unlock();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AchievementToast(
              achievement: achievement,
              onDismissed: () => dismissed = true,
            ),
          ),
        ),
      );

      // Wait for auto-dismiss (3.5 seconds + animation)
      await tester.pump(const Duration(milliseconds: 3500));
      await tester.pumpAndSettle();

      expect(dismissed, true);
    });
  });
}
```

**File:** `test/widgets/achievement_toast_overlay_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pachinko/widgets/achievement_toast_overlay.dart';
import 'package:pachinko/models/achievement.dart';

void main() {
  group('AchievementToastOverlay', () {
    testWidgets('given toast overlay, when showAchievementToast called, then toast appears',
        (tester) async {
      late AchievementToastOverlayState overlayState;

      await tester.pumpWidget(
        MaterialApp(
          home: AchievementToastOverlay(
            child: Builder(
              builder: (context) {
                overlayState = AchievementToastOverlay.of(context)!;
                return const Scaffold(body: Text('Test'));
              },
            ),
          ),
        ),
      );

      final achievement = Achievement(
        id: 'test',
        name: 'Test Achievement',
        description: 'Test',
        points: 100,
        requiredCount: 1,
      );
      achievement.unlock();

      overlayState.showAchievementToast(achievement);
      await tester.pump();

      expect(find.text('Test Achievement'), findsOneWidget);
    });

    testWidgets('given two achievements, when shown sequentially, then queue works',
        (tester) async {
      late AchievementToastOverlayState overlayState;

      await tester.pumpWidget(
        MaterialApp(
          home: AchievementToastOverlay(
            child: Builder(
              builder: (context) {
                overlayState = AchievementToastOverlay.of(context)!;
                return const Scaffold(body: Text('Test'));
              },
            ),
          ),
        ),
      );

      final achievement1 = Achievement(
        id: 'test1',
        name: 'First Achievement',
        description: 'Test',
        points: 100,
        requiredCount: 1,
      );
      achievement1.unlock();

      final achievement2 = Achievement(
        id: 'test2',
        name: 'Second Achievement',
        description: 'Test',
        points: 200,
        requiredCount: 1,
      );
      achievement2.unlock();

      // Show first toast
      overlayState.showAchievementToast(achievement1);
      await tester.pump();

      expect(find.text('First Achievement'), findsOneWidget);

      // Show second toast (should queue)
      overlayState.showAchievementToast(achievement2);
      await tester.pump();

      // First toast still showing
      expect(find.text('First Achievement'), findsOneWidget);
      expect(find.text('Second Achievement'), findsNothing);

      // Dismiss first toast
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      // Second toast now showing
      expect(find.text('Second Achievement'), findsOneWidget);
    });
  });
}
```

**File:** `test/services/achievement_service_test.dart` (add to existing tests)

```dart
group('Achievement Unlock Callback', () {
  test('given achievement unlocked, when checkAchievements called, then callback triggered', () {
    Achievement? unlockedAchievement;

    final achievementService = AchievementService(
      onAchievementUnlocked: (achievement) {
        unlockedAchievement = achievement;
      },
    );

    // Simulate unlocking first achievement
    achievementService.trackBallLaunched();

    expect(unlockedAchievement, isNotNull);
    expect(unlockedAchievement?.id, 'first_launch');
  });

  test('given multiple achievements unlock, when checked, then callback fires for each', () {
    final unlockedAchievements = <Achievement>[];

    final achievementService = AchievementService(
      onAchievementUnlocked: (achievement) {
        unlockedAchievements.add(achievement);
      },
    );

    // Trigger multiple achievements
    for (int i = 0; i < 10; i++) {
      achievementService.trackBallLaunched();
    }

    expect(unlockedAchievements.length, greaterThan(0));
  });
});
```

### Manual Testing Scenarios

**Test 12 Enhancement - Achievement Toast Notifications:**

1. **First Achievement Unlock:**
   - Start new game
   - Launch first ball
   - Verify "First Launch" achievement toast appears
   - Confirm toast shows achievement name, icon, and points
   - Verify toast auto-dismisses after ~3.5 seconds

2. **Multiple Achievements:**
   - Play game to unlock 2-3 achievements in quick succession
   - Verify toasts appear sequentially (no overlap)
   - Confirm queue system works (second toast waits for first)

3. **Manual Dismiss:**
   - Trigger achievement unlock
   - Tap toast notification
   - Verify toast dismisses immediately

4. **Visual Polish:**
   - Check slide-in animation is smooth
   - Verify gold border and trophy icon present
   - Confirm text is readable and well-formatted
   - Check shadow and gradient styling

5. **Haptic Feedback:**
   - Unlock achievement on physical device
   - Verify medium haptic feedback triggers on toast appearance

---

## Success Criteria

### Functional Requirements
- ✅ Toast appears immediately on achievement unlock
- ✅ Toast shows achievement icon, name, and point value
- ✅ Toast slides in from top smoothly
- ✅ Toast auto-dismisses after 3.5 seconds
- ✅ Toast can be manually dismissed by tapping
- ✅ Multiple toasts queue properly (no overlap)
- ✅ Haptic feedback on toast appearance

### Code Quality Requirements
- ✅ All existing tests still passing
- ✅ New toast widget tests added (5+ tests)
- ✅ Code coverage maintained above 85%
- ✅ No memory leaks (proper animation disposal)
- ✅ Toast doesn't block gameplay

### User Experience Requirements
- ✅ Test 12 Enhancement (Achievement Notifications) implemented
- ✅ Immediate feedback on achievement unlocks
- ✅ Non-intrusive positioning (top center)
- ✅ Professional visual design with gold accents
- ✅ Smooth animations (no jank)

---

## Files to Modify

1. **`/home/frankbria/projects/pachinko/lib/widgets/achievement_toast.dart`** (NEW)
   - Create animated toast widget

2. **`/home/frankbria/projects/pachinko/lib/widgets/achievement_toast_overlay.dart`** (NEW)
   - Create toast queue manager

3. **`/home/frankbria/projects/pachinko/lib/services/achievement_service.dart`**
   - Add `onAchievementUnlocked` callback
   - Trigger callback in `checkAchievements()`

4. **`/home/frankbria/projects/pachinko/lib/main.dart`**
   - Wrap app with `AchievementToastOverlay`
   - Initialize `AchievementService` with callback
   - Implement `_onAchievementUnlocked()` handler

5. **`/home/frankbria/projects/pachinko/test/widgets/achievement_toast_test.dart`** (NEW)
   - Test toast rendering and animations

6. **`/home/frankbria/projects/pachinko/test/widgets/achievement_toast_overlay_test.dart`** (NEW)
   - Test toast queue management

7. **`/home/frankbria/projects/pachinko/test/services/achievement_service_test.dart`**
   - Add callback tests (2 tests)

---

## Performance Considerations

**Animation Performance:**
- Single AnimationController per toast (lightweight)
- No texture loading (pure Flutter widgets)
- Smooth 60 FPS slide + fade animations

**Memory:**
- Toast dismissed → widget disposed → controller disposed
- Queue stores Achievement references only (minimal memory)
- No persistent overhead

**Verdict:** Negligible performance impact

---

## Alternative Approaches Considered

**Approach 1: SnackBar**
- Pros: Built-in Flutter widget
- Cons: Bottom positioning, less customizable, no queue
- **Decision:** Custom toast provides better UX and control

**Approach 2: Overlay Entry**
- Pros: More flexible positioning
- Cons: Complex lifecycle management
- **Decision:** Stack-based overlay simpler and cleaner

**Approach 3: Show All Toasts Simultaneously**
- Pros: Faster feedback for multiple achievements
- Cons: Visual clutter, overlap issues
- **Decision:** Queue ensures clean, sequential display

---

## Acceptance Testing

Before marking this task complete, verify:

1. **Run All Tests:**
   ```bash
   flutter test
   ```
   - All existing tests pass
   - All new toast tests pass (7+ tests)

2. **Manual Visual Validation:**
   - Play game and unlock achievements
   - Verify toast appearance and animations
   - Test queue behavior with multiple achievements
   - Confirm manual dismiss works

3. **Performance Check:**
   - No frame drops during toast animations
   - Gameplay continues smoothly with toast visible

4. **Code Review:**
   - AnimationController properly disposed
   - Callback pattern clean and testable
   - Toast positioning works on different screen sizes

---

## Commit Message

```
feat(ux): add achievement unlock toast notifications

Adds immediate visual feedback for achievement unlocks.

Toast Notification System:
- Animated toast slides in from top
- Shows achievement icon, name, and point value
- Gold-themed design with trophy icon
- Auto-dismisses after 3.5 seconds
- Tap to dismiss manually
- Haptic feedback on appearance

Queue Management:
- Multiple toasts display sequentially
- No overlapping notifications
- Clean state management with proper disposal

Integration:
- AchievementService callback pattern
- AchievementToastOverlay wraps app
- Non-intrusive positioning at top center
- Doesn't block gameplay

Animations:
- Slide in from top (500ms)
- Fade out on dismiss (300ms)
- Smooth 60 FPS performance
- AnimationController lifecycle properly managed

Tests:
- 7 new tests for toast widget and overlay
- Test rendering, animations, queue, and callbacks
- All existing tests pass

Performance: Negligible impact, smooth animations

Implements: Test 12 Enhancement - Achievement Toast Notifications

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

---

## Next Steps After Completion

1. User validates toast notifications work correctly
2. Proceed to Task 2.5.6 (Field Boundary Enhancements & Final Validation)
3. Complete Phase 2.5 with final validation pass
