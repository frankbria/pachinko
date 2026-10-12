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
- ✅ Runs on Android, and in a browser for demos

## Technology Stack
- **Framework:** Flutter 3.38.1
- **Language:** Dart 3.10.0
- **Physics:** Custom physics engine (60 FPS)
- **State Management:** Provider pattern
- **Storage:** Shared Preferences (ready)
- **Graphics:** Custom Canvas painting
- **Platform:** Android. `web/` is kept for the demo build (`flutter build web`, served from `build/web`). The repository has no project files for iOS or the desktop platforms; `flutter create --platforms=<name> .` adds one

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
│   ├── round_summary.dart      # How a round went, read from the game state
│   └── game_state.dart         # Global game state management
├── services/
│   ├── physics_engine.dart     # Ball physics and collision detection
│   └── game_manager.dart       # Main game loop and coordination
├── screens/
│   ├── game_screen.dart        # Main gameplay screen
│   ├── menu_screen.dart        # Main menu with level selection
│   └── settings_screen.dart    # The player's settings
├── widgets/
│   ├── pachinko_board.dart     # Custom Canvas game board renderer
│   ├── board_effects.dart      # Bonus announcement, confetti, slot lights, popups, lamps
│   ├── round_summary_panel.dart # The summary shown when the last ball lands
│   └── board_static_layer.dart # Felt, rail, pins and slots, recorded once per level
└── utils/
    ├── constants.dart          # Game configuration and styling
    ├── game_theme.dart         # App theme built from the colour roles
    └── peg_patterns.dart       # ✨ NEW: Organized peg layouts
```

## Key Commands
- `export PATH="/home/frankbria/projects/pachinko/tools/flutter/bin:$PATH"` - Set Flutter path
- `flutter run` - Run the game
- `flutter build apk --profile` - Build the Android app as a release is built: ahead of time, with unused icons dropped from the font (a CI gate, the `build` job). Debug builds and tests do neither, so this is the build that finds a release-only failure. An icon must be an `Icons.*` constant: an `IconData` constructed at run time, for instance from a stored number, fails this build, and a test under `test/models/` fails first. `flutter build apk --release` also needs `android/key.properties` for signing, which is not in the repository
- `flutter test --exclude-tags golden` - Run tests (the main CI gate)
- `flutter test --tags golden` - Run the golden image tests (also gated in CI). The baselines in `test/widgets/goldens/` were generated on Linux and are only expected to match there. After an intended visual change or a Flutter upgrade, regenerate them with `flutter test --tags golden --update-goldens`, look at the images, and commit them. A golden that draws a prize peg captures its shimmer after however many frames the test pumps, so the picture depends on the frame count
- `flutter test integration_test -d emulator-5554 --timeout 120s` - Run the 20 integration tests on a running Android emulator (about three minutes; they refuse to start without a device). Boot one first: `~/Android/Sdk/emulator/emulator -accel-check`, then `~/Android/Sdk/emulator/emulator -avd reader36 -no-window -no-audio -no-boot-anim -no-snapshot-save -gpu swiftshader_indirect` from a session that can open `/dev/kvm`, and wait for `adb shell getprop sys.boot_completed` to print `1`. In these tests use `settle`, `dragLauncher` and `pumpUntil` from `integration_test/helpers.dart`: `pumpAndSettle` never returns on the game screen while a prize peg shimmers, and the launcher's board coordinates are not screen coordinates
- `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/screenshots.dart -d emulator-5554` - Take screenshots of the game on a running emulator: the menu, levels 1, 2, 3 and 9, and one full round. They are written to `build/screenshots/`. `.github/workflows/screenshots.yml` runs this on a pull request that changes the drawing code, and on demand, and uploads the images as the `screenshots` artifact (`gh run download <run> -n screenshots`). The script is not one of the integration tests: its name does not end in `_test`
- The pictures in `README.md` are in `docs/images/`; refresh them after a change to how the game looks. The stills are from the `Screenshots` workflow on `master` (`gh workflow run screenshots.yml --ref master`, then `gh run download <run> -n screenshots`), each scaled to 540 px wide (`ffmpeg -i in.png -vf scale=540:-1 out.png`). `gameplay.gif` is a recording of the web build (`flutter build web`, served from `build/web`) played in a headless browser at 412x915 with "One ball at a time" off, cut to about 17 seconds and converted with `ffmpeg` at 15 frames a second and 320 px wide through `palettegen` and `paletteuse`. Flutter web paints to a canvas, so the browser drives the game by coordinates read from a screenshot: a click on Play, and a drag down from the plunger of twice the power wanted, in pixels. Launch once before recording, or the First Launch toast is in the picture
- `flutter test tool/scoring_simulation_test.dart --dart-define=LEVELS=60 --dart-define=ROUNDS=20` - Measure the game's balance: plays whole rounds through the real generator, launcher and physics and prints, per peg pattern and per band of levels, where balls land, how often the bonus triggers, balls per round and scores (about fifteen seconds). It asserts nothing and is not part of the test suite. Run it before and after any change to level generation, scoring or the bonus
- `dart run build_runner build --delete-conflicting-outputs` - Regenerate test mocks after changing the public API of a mocked class, and commit the result. CI regenerates them and fails if they differ from the committed ones
- `dart format lib test integration_test tool test_driver` - Format the code (a CI gate, as `dart format --output=none --set-exit-if-changed` on the same directories: an unformatted file fails the job. The generated mocks are included; the generator already writes them this way). `dart fix --apply` afterwards if the wrapping left an `if` without braces. The commit that first formatted everything is listed in `.git-blame-ignore-revs`
- `flutter analyze` - Check code quality (a CI gate: anything it reports fails the job, info-level lints included, so the count stays at zero; `dart fix --apply` clears most style lints, and its changes to `pubspec.yaml` are not wanted). `analysis_options.yaml` excludes `tools/flutter/**`, so the SDK checkout there is not analyzed
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
- **Authentic Launch**: the launcher carries the ball straight up the channel and lets it go at the top, moving straight up at `GameConstants.launchSpeedMin` to `launchSpeedMax` by the launch power; from there only the physics moves it. It meets the dome, which guides and does not bounce: `PhysicsEngine` takes away the part of a ball's velocity that points into the dome and keeps the rest. The dome is close to a parabola, so a ball rides it while its sideways speed is more than a projectile on that curve would have (about 390 px/s) and otherwise flies free under it. A soft launch therefore comes down beside the channel and a full one rides over the top to the far side: power is how the player aims. Nothing scripts the ball's path after the channel; `test/services/launch_into_the_dome_test.dart` flies launches at every power and checks that no part of the ball is ever outside the dome. If the dome's three points or gravity change, the two speeds have to be set again (a test says what they must exceed)
- **Peg Spacing**: no gap between two pegs, or between a peg and a field wall or the curved top boundary, is narrower than `GameConstants.minPegGap` (the ball's diameter plus 2 px). The curve's three points are `GameConstants.topCurve*`, used by the physics, the painter and the generators. A narrower gap is a pocket: the ball comes to rest in it, never leaves play, and the session soft-locks. Every generator places pegs through `PegPatterns.leavesRoomForBall`, and a new generator must too. `test/models/level_test.dart` checks the rule on levels 1 to 100 and `test/services/stuck_ball_simulation_test.dart` plays seeded balls through levels 1 to 30
- **Pattern Variety**: Hexagonal, Triangle, and Random patterns cycle through levels
- **Physics Simulation**: 60 FPS with gravity, air resistance, realistic bouncing
- **Special Pegs**: 2-4 highlighted pegs per level trigger the bonus: `GameConstants.bonusBallsFor(level)` balls, which is 5 plus one for every two levels and never more than `bonusBallsMax` (15, reached at level 20, by the owner's decision in #72), so a round is at most 35 balls. The game state, the board's announcement and the round summary all take the number from that function. The balls drop from the top of the playfield. A prize peg still to win is a gold sphere in a halo with two rings that breathe with its shimmer; once hit it is `Peg.isCollected` and is drawn dim (`Peg.collectedPrizeColor`) with one thin ring, so the pegs that remain stand out. The shimmer is never in the peg's colour, and `Peg.renderColor` only flashes while a hit pulse runs. They are placed after the regular pegs; when a dense field has no free spot, `Level.generate` removes the regular pegs around the least crowded candidate, so no level is left without its bonus
- **Inverse Scoring**: Edge slots = 2000pts, center = 1000pts, sides = 50-200pts. The row of seven slots lies between the two field walls (`fieldLeftBoundaryX` to `fieldRightBoundaryX`), because the walls hold a ball in at every height, not only where they are drawn: a slot that reached past a wall would be drawn wider than it can be entered. The two edge slots are `GameConstants.edgeSlotWidth` (22) wide, just wider than the ball, which keeps them the hardest: about one ball in nine lands in one. That width was set by the owner from `tool/scoring_simulation_test.dart` (#92); widening it raises every score, and High Roller and Score Master were set for it. A value too long for its slot is written sideways (`paintSlotValue`)
- **Power System**: Drag-to-charge launcher. The launch channel is the power meter: `paintLaunchPower` fills it with light from the plunger upward, cyan rising through violet to magenta, stopping at the top of the inner wall at full power, with the percentage beside the channel's foot. Nothing about launch power is drawn over the pegs; a test checks every power against every level's pegs. The ramp is two two-colour gradients (see Board Rendering). The hint under the launch box reads "Drag the plunger to launch", and "Release to launch" while charging (`launchHintFor`)
- **Achievement Toasts**: `AchievementToastOverlay` is installed through `MaterialApp.builder` (above the Navigator) and reached with a `GlobalKey`, so toasts show over every screen; anything else that must appear above every route belongs in that builder, not in `home:`. A toast sits at the top of the screen unless a screen anchors it lower: `GameScreen` measures its score header and calls `anchorToasts(this, height)` on the overlay, re-anchors when the header's size changes, and calls `releaseToasts(this)` after it is disposed, so the score, ball count and level stay readable at any text size. A screen with an app bar (High Scores, Achievements, Settings) wraps its `Scaffold` in `ToastAnchor`, which anchors toasts below the app bar while the screen is open and releases them when it closes, so a toast never lies over the title or the Back button. A new screen with something at its top edge that must stay readable does one or the other; `test/widgets/achievement_toast_position_test.dart` measures the real screens
- **Colour Roles**: the palette in `GameConstants` (`lib/utils/constants.dart`) is the source for colours, and each has one job. The theme, the board and what is drawn on it, the game screen with its round summary, and the other screens (see Screens) all read from it. Gold is score, prize pegs and bonus balls only. Brass is ordinary pins and does not glow at rest, so a peg that glows steadily is always a prize; a pin that has just been hit flashes with a gold ring for under a second. Slot tiers run cool to hot: slate (50), blue (200), violet (1000), magenta (2000). Cyan is the primary action, and anything drawn on it uses `onPrimaryColor`. New code takes colours from these roles or from `Theme.of(context)`, never from `Colors.*` swatches or new hex literals
- **Board Rendering**: the board is drawn in two passes. `paintBoardStaticLayer` (`lib/widgets/board_static_layer.dart`) draws what does not change while a level is played: the felt, the chrome rail, the brass pins with their shadows, and the unlit slots with their values. `BoardStaticLayer` records that into a `Picture` once per level object and the painter replays it on every repaint. The painter then draws what changes: ball counts on slots, prize pegs, a pin in the middle of its hit pulse, balls, the launcher and effects. Something new that never changes during a level goes in the static layer; anything that can change must be drawn by the painter, or it will be stale until the next level. A level's pegs and slots must not move after it is generated, because the cache is keyed on the level object. The static layer uses no `MaskFilter` blur: shadows and glows are gradients and widened strokes. Every sphere is drawn with `paintSphere`, lit from the upper left, and a sphere that glows passes `castsShadow: false`. Gradients on the board have two colours, and stops, when given, end at 1.0: a three-colour gradient, or one whose last stop is lower, makes the software-rendered emulator that runs the integration tests abort with no message (PR #65). Build a richer gradient from two passes, as `paintSphere` does. A ball is a `paintSphere` with `glowColour` set (the glow goes between the shadow and the body) and a fading trail behind it. The trail is `Ball.trail`, at most `Ball.maxTrailLength` past positions: the game loop calls `recordTrail()` on every ball before each step moves it, so anything else that moves a ball outside the loop leaves no trail. The bonus announcement and the confetti are drawn by `lib/widgets/board_effects.dart`, which, like the static layer, may only name colours from `GameConstants` (a test checks it). The announcement dims the board and is drawn under the balls, the confetti and the score popups; a confetti piece's shape goes by its size. The static layer's source may only name colours from `GameConstants`, and a test checks it. The launch channel's inner wall stops at `GameConstants.launchChannelInnerWallTopY` (135), by the owner's decision in #22
- **Composition**: the game screen's header is one row of three stat tiles (`_HUDItem`: icon, label and value on a line; the score's value is gold), wrapped in the `SizeChangedLayoutNotifier` that the toast anchor measures. On a phone the board is as wide as the screen allows, so its drawn size is set by the width: a shorter header makes the panel taller, not the playfield larger, and the extra height is a strip under the board. `paintSlotCounts` puts the per-slot ball counts in a tray in that strip when there is room (`slotTrayHeight`), and inside the slots when there is not. The dome carries the level's sign (static layer) and one lamp per prize peg, lit as each is collected (`paintPrizeLamps`). Light rising from the slots is a round, soft-edged glow on purpose: nothing collides in that band, so nothing drawn there may look like a wall or a divider. Nothing the board draws crosses its left or right edge, and text painted on the board is at least 12 logical pixels; tests check both
- **Feedback**: every bounce off a pin answers with the gold flash and the peg sound, not only the first of the level; `Peg.canFireAgain` holds a pin back for `Peg.refireDelay` (0.15 s) after a hit, so that a ball resting or rolling on it does not fire it on every frame. `PhysicsEngine.checkPegCollisions` still returns only the pegs hit for the first time, which is what collects a prize peg and counts towards the bonus. A ball landing lights its slot (`Slot.glow`, set by `GameState.lightSlot` and faded by the game loop over `Slot.lightSeconds`, longer for a higher value) and raises a `+N` popup that starts above the slot's mouth, in the slot's tier colour, at `FloatingText.sizeFor(points)`; `paintScorePopup` keeps it inside the board's width, at `scorePopupBounds`. The launcher's hint is written where popups rise from the right-hand slots, so the board leaves the hint out for as long as a popup's bounds overlap it; anything else written near the slots does the same. Responses are sized by importance: a 50 is small and brief, a 2000 large and long. The header's score counts up. Slot lights are a transient effect: `Slot.reset()` puts them out, as it clears the ball count, and `GameManager._isIdle` waits for them. When the last ball lands, `GameScreen` shows `RoundSummaryPanel` over the board with a `RoundSummary` read from the game state at that moment (the level's own score, a tally per slot tier, prize pegs collected, bonus balls) and `GameManager.roundIsNewBest`, which is null until storage has answered. Its Menu button does what Back does; Replay and Next Level call `resetGame` and `nextLevel`
- **Audio**: nothing in the game awaits a sound, so `AudioService` never throws: a failing player is caught and logged. The app also disposes the service without waiting. `dispose()` therefore waits for loads that are in flight before it disposes the players, because a player disposed in the middle of a load makes `just_audio` raise an error that no caller can catch, and it ignores sounds asked for afterwards. Anything new that loads on a player (`setAsset` and what follows it) must go through `_tracked`
- **Screens**: the menu, level picker, How to Play, high scores, achievements, settings and the achievement toast sit on the cabinet background and take every colour from the theme or `GameConstants`. Rows and cards use `GameCard` (`lib/widgets/game_card.dart`): dark glass with a hairline rim, rimmed gold when it is something won. `test/screens/screens_on_tokens_test.dart` holds them to it: it reads their sources for colours of their own, and walks every text and icon on each screen, in each state, checking a contrast of at least 4.5 to 1 against whatever is painted behind it. A new screen is added to both lists there. The level picker gets each level's best score from `GameManager.bestScoresByLevel()`; `groupedThousands` writes 12500 as 12,500
- **Level Bands**: levels are grouped in bands of `GameConstants.levelsPerBand` (5), and each `LevelBand` in `GameConstants.levelBands` has its own felt, felt shade and rim colour; `GameConstants.bandForLevel` maps a level to its band, and beyond the last band they come round again. The board's felt, the rail's glow, the level sign and the panel around the board take the band's colours; everything with a role (gold, brass, the four slot tiers, cyan) is the same on every band. A new band's felt must be dark enough for every role colour to keep a contrast of 3 to 1 on it, and its rim may not be gold or brass; tests check both
- **Type**: `buildGameTheme()` (`lib/utils/game_theme.dart`) gives display, headline, title and label styles the bundled Oxanium face and leaves body styles on Roboto. Oxanium ships as static regular and bold files in `assets/fonts/` because `FontWeight` does not drive a variable font's weight axis; add another static weight there if one is needed
- **Game Loop**: the 16 ms loop in `GameManager` runs only while something it drives is changing: a ball in play, a score popup, confetti or the ball count highlight. It stops itself after a tick in which none of those is left, and a launch starts it again; after game over it runs until the last popup has finished. Anything new that the loop animates must be added to `_isIdle`, or it will freeze when the loop stops. The board does not rebuild on the manager's notifications: its painter repaints from a listenable (the manager, the game state and a frame counter that the board's ticker advances), and peg animation (the prize peg shimmer and the hit pulse) runs on that ticker, which stops when no peg is animating. The level result (game-over phase, high score, achievements) is recorded once per level, guarded by `_levelResultSaved`. `GameScreen` calls `GameManager.stopLoop()` from `dispose`, which is what stops play when the player presses Back; any other screen that hosts the board must do the same, and any route into `GameScreen` must call `startGame()` first. `stopLoop()` must not notify listeners, because it runs during dispose. `GameScreen` also pauses a ball in play when the app is hidden (an `AppLifecycleListener` with `onHide`), and does not resume it when the app returns: the player presses Resume
- **Launch Rule**: `GameState.canLaunchBall` is the one gate for launching; `GameManager` and the board both read it. It is false while the game is paused (`GameState.isPaused`: pause is the `ready` phase with balls still on the board, and this flag is what tells the two apart), while the launcher is carrying a ball up its channel (`GameState.launcherBusy`, which `GameManager` sets at a launch and clears on release: the launcher carries one ball at a time), and when no balls remain. With `GameState.singleBallLaunch` on (the default) it also needs no ball in play; with it off a ball can be launched during play. The player changes it on the settings screen (`lib/screens/settings_screen.dart`, reached from the menu) through `GameManager.setSingleBallLaunch`, which applies it and saves it with `StorageService.saveSingleBallLaunch`; `GameManager` reads the saved choice when it is given a storage service: in its constructor, or in `attachServices`, which `main.dart`'s `ChangeNotifierProxyProvider2` calls when storage and achievements finish loading. The manager is created the first time something asks for it, which can be before they have, so anything the manager needs from a service that loads late must be applied in `attachServices` as well. A new setting follows the same path. `resetLevel()` and `loadLevel()` clear the paused and busy flags
- **Game Transitions**: `GameManager.startGame`, `resetGame`, `nextLevel` and `selectLevel` each call `_ballLauncher.reset()` first, because cancelling the loop strands a launcher that is mid-`traveling`, and each clears `_levelResultSaved`, because a transition that left it set would never record the next game over, and `_firstBall` with `_firstBallSeen`, so that the next round has a first ball of its own; any new method that restarts play or changes level must do the same. `GameState.loadLevel()` clears the balls in play, as `resetLevel()` does, so no ball is carried onto another level by `nextLevel`, `selectLevel` or `startNewGame`. `GameState.resetLevel()` and `loadLevel()` call `_clearEffects()`; any new transient visual effect must be cleared there
- **Score Accounting**: `GameState.score` is the running total across levels and is what the header shows. `GameState.levelScore` is the points won on the current level, and anything that records or rewards one level's result (the high score saved at game over, `AchievementService.trackLevelScore`) uses it. `loadLevel()` records the score at the start of the level and `resetLevel()` returns the score to it, so Restart gives back the balls and takes back the level's points. `StorageService.saveHighScore` keeps the top `maxScoresPerLevel` (10) scores per level. Levels do not stop at 20: Next Level has no upper limit, so anything that lists stored scores asks `StorageService.levelsWithScores()` which levels have a table (it reads the stored keys) and never loops over a fixed range. The High Scores screen and `getTotalScore` do; the level picker shows levels 1 to 20 on purpose. The two single-level score achievements unlock at `AchievementService.highRollerScore` (20,000) and `scoreMasterScore` (25,000), which about one round in ten and one in a hundred reach in `tool/scoring_simulation_test.dart`; their descriptions are written from those constants, and if scoring is retuned the tool's High Roller and Score Master columns say whether they still fit. When stored achievements are loaded, only progress and the unlock date come from storage (`Achievement.restoreFrom`): the name, description and reward are the code's, so a changed rule is shown as it is now and what was unlocked stays unlocked
- **Achievements**: every achievement is unlocked by a `track*` method of `AchievementService` that `GameManager` calls from the game loop, and `test/services/achievement_service_test.dart` fails if a tracking method has no caller under `lib/`: two achievements once had rules no round could meet and methods nothing called (#85). Combo King is one ball collecting every prize peg on the level: the physics engine, which knows which ball hit which peg, counts them on the ball (`Ball.prizePegsCollected`), and the manager compares that with the level's prize pegs when the bonus triggers. Lucky Shot is the first ball of a round landing in a 2,000 slot: the manager keeps that ball (`_firstBall`, the first in play each round) until it lands or is lost, so a bonus ball that lands before it neither wins nor blocks it, and the four game transitions clear it. A new achievement needs a rule a round can meet (measure it with `tool/scoring_simulation_test.dart`, which prints the share of rounds earning Combo King and Lucky Shot) and a call from the loop

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
- **CI Gates** (`.github/workflows/ci.yml`; the `test` job, in order): analyzer, formatting, generated mocks up to date, tests, coverage of changed lines at least 85% (pull requests only), golden tests. A second job, `build`, builds the app in profile mode. `flutter test --coverage` only records libraries that a test loads, so `test/all_libraries_loaded_test.dart` imports every file under `lib/` and fails when one is missing from its list; add new files there, or an untested file would be skipped by the coverage check instead of failing it. A failed golden step uploads the difference images as the `golden-failures` artifact. The integration tests in `integration_test/` need a device, so they are not part of this job: `.github/workflows/integration.yml` runs them on an Android emulator when they, the drawing code in `lib/widgets/` or that file change, once a week, and on demand
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
- [ ] Code formatted and analyzed (`dart format` leaves nothing changed, `flutter analyze` with no issues)
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
