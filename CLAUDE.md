# Pachinko Game - Development Reference

## Project Overview
A modern graphical Pachinko idle game for Android. Features authentic pachinko machine mechanics with realistic ball launching, physics simulation, and strategic scoring.

## Current Status: ✅ PLAYABLE PROTOTYPE
- ✅ Authentic ball launching system (bottom-right launch channel)
- ✅ Advanced physics engine with collision detection
- ✅ Organized peg patterns with proper spacing
- ✅ Complete UI with power meter and visual feedback
- ✅ Level progression system with varying patterns
- ✅ Special peg bonus mechanics
- ✅ Cross-platform (Linux desktop, Android-ready)

## Technology Stack
- **Framework:** Flutter 3.38.1
- **Language:** Dart 3.10.0
- **Physics:** Custom physics engine (60 FPS)
- **State Management:** Provider pattern
- **Storage:** Shared Preferences (ready)
- **Graphics:** Custom Canvas painting
- **Platform:** Linux (current), Android (configured)

## Project Structure
```
lib/
├── main.dart                    # App entry point with Provider setup
├── models/
│   ├── ball.dart               # Ball physics and properties
│   ├── ball_launcher.dart      # ✨ NEW: Authentic launch system
│   ├── peg.dart                # Peg collision and types
│   ├── slot.dart               # Scoring slots at bottom
│   ├── level.dart              # Level generation and management
│   └── game_state.dart         # Global game state management
├── services/
│   ├── physics_engine.dart     # Ball physics and collision detection
│   └── game_manager.dart       # Main game loop and coordination
├── screens/
│   ├── game_screen.dart        # Main gameplay screen
│   └── menu_screen.dart        # Main menu with level selection
├── widgets/
│   └── pachinko_board.dart     # Custom Canvas game board renderer
└── utils/
    ├── constants.dart          # Game configuration and styling
    ├── game_theme.dart         # App theme built from the colour roles
    └── peg_patterns.dart       # ✨ NEW: Organized peg layouts
```

## Key Commands
- `export PATH="/home/frankbria/projects/pachinko/tools/flutter/bin:$PATH"` - Set Flutter path
- `flutter run` - Run the game
- `flutter build apk` - Build Android APK
- `flutter test --exclude-tags golden` - Run tests (the main CI gate)
- `flutter test --tags golden` - Run the golden image tests (also gated in CI). The baselines in `test/widgets/goldens/` were generated on Linux and are only expected to match there. After an intended visual change or a Flutter upgrade, regenerate them with `flutter test --tags golden --update-goldens`, look at the images, and commit them. A golden that draws a prize peg captures its shimmer after however many frames the test pumps, so the picture depends on the frame count
- `dart run build_runner build --delete-conflicting-outputs` - Regenerate test mocks after changing the public API of a mocked class, and commit the result. CI regenerates them and fails if they differ from the committed ones
- `flutter analyze --no-fatal-infos` - Check code quality (a CI gate: warnings and errors fail it, info-level lints are only reported). `analysis_options.yaml` excludes `tools/flutter/**`, so the SDK checkout there is not analyzed
- `flutter doctor` - Check Flutter installation

## Current Implementation Status

### ✅ COMPLETED (Phases 1-3)
1. **✅ Setup & Core Structure** - Complete Flutter project with clean architecture
2. **✅ Physics Engine** - Advanced ball physics with realistic collision detection
3. **✅ Authentic Launch System** - Real pachinko-style launch channel with power meter
4. **✅ Game Board Rendering** - Custom Canvas painting with organized peg patterns
5. **✅ Basic Game Logic** - Level system, scoring, special peg mechanics implemented

### 🚧 READY FOR DEVELOPMENT (Phases 4-6)
6. **UI/UX Enhancements** - Animations, sound effects, particle effects
7. **Advanced Features** - High scores, achievements, more level types
8. **Polish & Testing** - Performance optimization, Android deployment
9. **Release Preparation** - App store assets, final testing

## Key Game Mechanics (IMPLEMENTED)
- **Authentic Launch**: Ball starts bottom-right, travels up channel, curves into peg field
- **Peg Spacing**: no gap between two pegs, or between a peg and a field wall, is narrower than `GameConstants.minPegGap` (the ball's diameter plus 2 px). A narrower gap is a pocket: the ball comes to rest in it, never leaves play, and the session soft-locks. Every generator places pegs through `PegPatterns.leavesRoomForBall`, and a new generator must too. `test/models/level_test.dart` checks the rule on levels 1 to 100 and `test/services/stuck_ball_simulation_test.dart` plays seeded balls through levels 1 to 30
- **Pattern Variety**: Hexagonal, Triangle, and Random patterns cycle through levels
- **Physics Simulation**: 60 FPS with gravity, air resistance, realistic bouncing
- **Special Pegs**: 2-4 highlighted pegs per level trigger 5+ bonus balls, which drop from the top of the playfield. They are placed after the regular pegs; when a dense field has no free spot, `Level.generate` removes the regular pegs around the least crowded candidate, so no level is left without its bonus
- **Inverse Scoring**: Edge slots = 2000pts, center = 1000pts, sides = 50-200pts
- **Power System**: Drag-to-charge launcher with visual power meter
- **Achievement Toasts**: `AchievementToastOverlay` is installed through `MaterialApp.builder` (above the Navigator) and reached with a `GlobalKey`, so toasts show over every screen; anything else that must appear above every route belongs in that builder, not in `home:`. A toast sits at the top of the screen unless a screen anchors it lower: `GameScreen` measures its score header and calls `anchorToasts(this, height)` on the overlay, re-anchors when the header's size changes, and calls `releaseToasts(this)` after it is disposed, so the score, ball count and level stay readable at any text size. A new screen with something at its top edge that must stay readable does the same; `test/widgets/achievement_toast_position_test.dart` measures the real screens
- **Colour Roles**: the palette in `GameConstants` (`lib/utils/constants.dart`) is the source for colours, and each has one job. The theme, pegs, slots, ball and the game header read from it today; the achievements and high scores screens, score popups, confetti and the power meter still carry their own colours until their slices under #22 move them. Gold is score, prize pegs and bonus balls only. Brass is ordinary pins and never glows, so a glowing peg is always a prize. Slot tiers run cool to hot: slate (50), blue (200), violet (1000), magenta (2000). Cyan is the primary action, and anything drawn on it uses `onPrimaryColor`. New code takes colours from these roles or from `Theme.of(context)`, never from `Colors.*` swatches or new hex literals
- **Type**: `buildGameTheme()` (`lib/utils/game_theme.dart`) gives display, headline, title and label styles the bundled Oxanium face and leaves body styles on Roboto. Oxanium ships as static regular and bold files in `assets/fonts/` because `FontWeight` does not drive a variable font's weight axis; add another static weight there if one is needed
- **Game Loop**: the 16 ms loop in `GameManager` runs only while something it drives is changing: a ball in play, a score popup, confetti or the ball count highlight. It stops itself after a tick in which none of those is left, and a launch starts it again; after game over it runs until the last popup has finished. Anything new that the loop animates must be added to `_isIdle`, or it will freeze when the loop stops. The board does not rebuild on the manager's notifications: its painter repaints from a listenable (the manager, the game state and a frame counter that the board's ticker advances), and peg animation (the prize peg shimmer and the hit pulse) runs on that ticker, which stops when no peg is animating. The level result (game-over phase, high score, achievements) is recorded once per level, guarded by `_levelResultSaved`. `GameScreen` calls `GameManager.stopLoop()` from `dispose`, which is what stops play when the player presses Back; any other screen that hosts the board must do the same, and any route into `GameScreen` must call `startGame()` first. `stopLoop()` must not notify listeners, because it runs during dispose. `GameScreen` also pauses a ball in play when the app is hidden (an `AppLifecycleListener` with `onHide`), and does not resume it when the app returns: the player presses Resume
- **Launch Rule**: `GameState.canLaunchBall` is the one gate for launching; `GameManager` and the board both read it. With `GameState.singleBallLaunch` on (the default) it is false while any ball is in play. Pause is the `ready` phase with a ball in play, so this is what stops a launch while paused. No screen changes the setting yet (#39). A test that needs overlapping launched balls turns it off
- **Game Transitions**: `GameManager.startGame`, `resetGame`, `nextLevel` and `selectLevel` each call `_ballLauncher.reset()` first, because cancelling the loop strands a launcher that is mid-`traveling`, and each clears `_levelResultSaved`, because a transition that left it set would never record the next game over; any new method that restarts play or changes level must do the same. `GameState.loadLevel()` clears the balls in play, as `resetLevel()` does, so no ball is carried onto another level by `nextLevel`, `selectLevel` or `startNewGame`. `GameState.resetLevel()` and `loadLevel()` call `_clearEffects()`; any new transient visual effect must be cleared there
- **Score Accounting**: `GameState.score` is the running total across levels and is what the header shows. `GameState.levelScore` is the points won on the current level, and anything that records or rewards one level's result (the high score saved at game over, `AchievementService.trackLevelScore`) uses it. `loadLevel()` records the score at the start of the level and `resetLevel()` returns the score to it, so Restart gives back the balls and takes back the level's points. `StorageService.saveHighScore` keeps the top `maxScoresPerLevel` (10) scores per level

## Feature Development Quality Standards

**CRITICAL**: All new features MUST meet the following mandatory requirements before being considered complete.

### Testing Requirements

- **Minimum Coverage**: 85% code coverage ratio required for all new code
- **Test Pass Rate**: 100% - all tests must pass, no exceptions
- **Test Types Required**:
  - Unit tests for all business logic and services
  - Widget tests for UI components
  - Integration tests for complete game flows
- **Coverage Validation**: Run coverage reports before marking features complete:
  ```bash
  # Flutter
  flutter test --coverage --exclude-tags golden
  genhtml coverage/lcov.info -o coverage/html

  # Coverage of the lines this branch changed, which is what CI gates at 85%
  uvx diff-cover coverage/lcov.info --compare-branch=origin/master --fail-under=85
  ```
- **CI Gates** (`.github/workflows/ci.yml`, in order): analyzer, generated mocks up to date, tests, coverage of changed lines at least 85% (pull requests only), golden tests. `flutter test --coverage` only records libraries that a test loads, so `test/all_libraries_loaded_test.dart` imports every file under `lib/` and fails when one is missing from its list; add new files there, or an untested file would be skipped by the coverage check instead of failing it. A failed golden step uploads the difference images as the `golden-failures` artifact. The integration tests in `integration_test/` are analyzed but not run: they need a device
- **Test Quality**: Tests must validate behavior, not just achieve coverage metrics
- **Test Documentation**: Complex test scenarios must include comments explaining the test strategy

### Git Workflow Requirements

Before moving to the next feature, ALL changes must be:

1. **Committed with Clear Messages**:
   ```bash
   git add .
   git commit -m "feat(module): descriptive message following conventional commits"
   ```
   - Use conventional commit format: `feat:`, `fix:`, `docs:`, `test:`, `refactor:`, etc.
   - Include scope when applicable: `feat(game):`, `fix(physics):`, `test(ui):`
   - Write descriptive messages that explain WHAT changed and WHY

2. **Pushed to Remote Repository**:
   ```bash
   git push origin <branch-name>
   ```
   - Never leave completed features uncommitted
   - Push regularly to maintain backup and enable collaboration
   - Ensure CI/CD pipelines pass before considering feature complete

3. **Branch Hygiene**:
   - Work on feature branches, never directly on `main`
   - Branch naming convention: `feature/<feature-name>`, `fix/<issue-name>`, `docs/<doc-update>`
   - Create pull requests for all significant changes

### Documentation Requirements

**ALL implementation documentation MUST remain synchronized with the codebase**:

1. **Code Documentation**:
   - Dart: Doc comments for all public functions, classes, and widgets
   - Update inline comments when implementation changes
   - Remove outdated comments immediately

2. **Implementation Documentation**:
   - Update relevant sections in this CLAUDE.md file
   - Keep architecture diagrams current
   - Update configuration examples when defaults change
   - Document breaking changes prominently

3. **README Updates**:
   - Keep feature lists current
   - Update setup instructions when dependencies change
   - Maintain accurate command examples
   - Update version compatibility information

4. **CLAUDE.md Maintenance**:
   - Add new patterns to relevant sections
   - Update "Key Game Mechanics" when gameplay changes
   - Keep command examples accurate and tested
   - Document new testing patterns or quality gates

### Feature Completion Checklist

Before marking ANY feature as complete, verify:

- [ ] All tests pass (`flutter test --exclude-tags golden` and `flutter test --tags golden`)
- [ ] Code coverage meets 85% minimum threshold
- [ ] Coverage report reviewed for meaningful test quality
- [ ] Code formatted and analyzed (`dart format`, `flutter analyze --no-fatal-infos`)
- [ ] All changes committed with conventional commit messages
- [ ] All commits pushed to remote repository
- [ ] Implementation documentation updated
- [ ] Inline code comments updated or added
- [ ] CLAUDE.md updated (if new patterns introduced)
- [ ] Breaking changes documented
- [ ] Game functionality manually tested on target platforms

### Rationale

These standards ensure:
- **Quality**: High test coverage and pass rates prevent regressions
- **Traceability**: Git commits provide clear history of changes
- **Maintainability**: Current documentation reduces onboarding time and prevents knowledge loss
- **Collaboration**: Pushed changes enable team visibility and code review
- **Reliability**: Consistent quality gates maintain production stability

**Enforcement**: AI agents should automatically apply these standards to all feature development tasks without requiring explicit instruction for each task.
