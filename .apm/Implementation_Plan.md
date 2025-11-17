Phase 1: Testing Foundation - Agent_Testing_Foundation_Models, Agent_Testing_Foundation_Services, Agent_Testing_Foundation_UI, Agent_Testing_Foundation_Integration

Task 1.1: Fix Broken Test Infrastructure - Agent_Testing_Foundation_Models
- Update `test/widget_test.dart` to reference correct classes (MenuScreen, GameManager, Provider)
- Run `flutter test` to verify test executes without errors and app launches successfully in test environment
- Document test execution commands in task completion notes

Task 1.2: Unit Tests - Ball Model - Agent_Testing_Foundation_Models - Depends on Task 1.1 output
1. Create `test/models/ball_test.dart` with test structure and imports following Given-When-Then naming pattern
2. Write failing tests for core scenarios: initialization defaults, physics update (gravity application, velocity integration, air resistance), apply impulse, reset state, out-of-bounds detection
3. Run tests to verify they fail appropriately (testing the tests) - `flutter test test/models/ball_test.dart`
4. Verify existing `lib/models/ball.dart` implementation passes all tests (no code changes needed, just testing)
5. Run coverage analysis to confirm 85%+ coverage on ball.dart - `flutter test --coverage` and validate coverage/lcov.info
6. Prepare PR with conventional commit: `test(models): add comprehensive unit tests for Ball model` - ensure Given-When-Then naming, dartdoc comments on complex test scenarios

Task 1.3: Unit Tests - Peg Model - Agent_Testing_Foundation_Models - Depends on Task 1.1 output
1. Create `test/models/peg_test.dart` with Given-When-Then test structure for collision detection scenarios
2. Write failing tests for: collision detection (hit, miss, edge cases), collision normal calculation accuracy, special peg highlighting, hit tracking (prevent double-counting), color rendering based on type/state
3. Run tests to verify appropriate failures - `flutter test test/models/peg_test.dart`
4. Verify existing `lib/models/peg.dart` passes all tests (collision math validation)
5. Run coverage analysis to confirm 85%+ coverage on peg.dart
6. Prepare PR with commit: `test(models): add unit tests for Peg collision and special mechanics` - include dartdoc for collision normal calculation tests

Task 1.4: Unit Tests - Slot Model - Agent_Testing_Foundation_Models - Depends on Task 1.1 output
1. Create `test/models/slot_test.dart` with Given-When-Then test structure
2. Write failing tests for: AABB collision detection (ball in slot, ball outside slot, edge cases), scoring value validation (edge slots 2000pts, center 1000pts, side slots 50-200pts), slot positioning accuracy
3. Run tests to verify failures - `flutter test test/models/slot_test.dart`
4. Verify existing `lib/models/slot.dart` passes all tests
5. Run coverage analysis to confirm 85%+ coverage on slot.dart
6. Prepare PR with commit: `test(models): add unit tests for Slot collision and scoring` - Given-When-Then naming enforced

Task 1.5: Unit Tests - Ball Launcher Model - Agent_Testing_Foundation_Models - Depends on Task 1.1 output
1. Create `test/models/ball_launcher_test.dart` with Given-When-Then structure for launch mechanics
2. Write failing tests for: launch path generation (35 segments), curve mathematics (quarter-circle, 40px radius), power calculation (0-100 range), phase transitions (ready�charging�traveling�released), release velocity based on power, ball path interpolation accuracy
3. Run tests to verify failures - `flutter test test/models/ball_launcher_test.dart`
4. Verify existing `lib/models/ball_launcher.dart` passes all tests (validate path geometry calculations)
5. Run coverage analysis to confirm 85%+ coverage on ball_launcher.dart
6. Prepare PR with commit: `test(models): add unit tests for BallLauncher path geometry and mechanics` - include dartdoc for complex geometry tests

Task 1.6: Unit Tests - Level Model - Agent_Testing_Foundation_Models - Depends on Task 1.1 output
1. Create `test/models/level_test.dart` with Given-When-Then structure for level generation
2. Write failing tests for: deterministic generation (same seed = same level), pattern cycling (level % 3 for hexagonal/triangle/random), special peg placement (2-4 pegs, 50px spacing), launch channel avoidance, inverse scoring distribution validation, valid peg positioning (50 attempt limit logic)
3. Run tests to verify failures - `flutter test test/models/level_test.dart`
4. Verify existing `lib/models/level.dart` passes all tests (validate procedural generation logic)
5. Run coverage analysis to confirm 85%+ coverage on level.dart
6. Prepare PR with commit: `test(models): add unit tests for Level procedural generation and constraints` - dartdoc for determinism and spatial constraint tests

Task 1.7: Unit Tests - Game State Model - Agent_Testing_Foundation_Models - Depends on Task 1.1 output
1. Create `test/models/game_state_test.dart` with Given-When-Then structure for state management
2. Write failing tests for: initial state setup, score addition and updates (with notifyListeners validation), ball launching and tracking, bonus trigger mechanics (5 + level/2 balls formula), phase transitions, level progression, game over conditions, ChangeNotifier notification behavior
3. Run tests to verify failures - `flutter test test/models/game_state_test.dart`
4. Verify existing `lib/models/game_state.dart` passes all tests (validate state mutation and notification logic)
5. Run coverage analysis to confirm 85%+ coverage on game_state.dart
6. Prepare PR with commit: `test(models): add unit tests for GameState management and ChangeNotifier` - dartdoc for ChangeNotifier testing pattern

Task 1.8: Unit Tests - Physics Engine Service - Agent_Testing_Foundation_Services - Depends on Task 1.1 output
1. Add mockito and build_runner to pubspec.yaml dev_dependencies if not present, run `flutter pub get`, generate mocks with `dart run build_runner build`
2. Create `test/services/physics_engine_test.dart` with Given-When-Then structure and mocked Ball/Peg objects using mockito
3. Write failing tests for: gravity application (980.0 px/s�), ball velocity integration over time, air resistance (0.999 damping factor), wall collision bounce (0.7 restitution), peg collision detection (circle-circle), peg collision resolution with impulse, slot collision (AABB), random angle perturbation (�0.1 rad), trajectory calculations
4. Run tests to verify failures - `flutter test test/services/physics_engine_test.dart`
5. Verify existing `lib/services/physics_engine.dart` passes all tests (validate physics constants and numerical accuracy)
6. Run coverage analysis to confirm 85%+ coverage on physics_engine.dart, prepare PR with commit: `test(services): add unit tests for PhysicsEngine with mocked dependencies` - dartdoc for physics constant validation tests

Task 1.9: Unit Tests - Game Manager Service - Agent_Testing_Foundation_Services - Depends on Task 1.1 output - Depends on Task 1.8 output
1. Create `test/services/game_manager_test.dart` with Given-When-Then structure and mocked dependencies (PhysicsEngine, GameState, BallLauncher) using mockito
2. Write failing tests for: game initialization, game loop timing (16ms ticks verification), delta time clamping (max 1/30 FPS = 33.33ms), ball launcher integration (launch phase coordination), special peg bonus triggering (verify GameState interaction), slot hit scoring (verify GameState score updates), pause/resume functionality, timer cleanup on dispose, phase coordination between components
3. Run tests to verify failures - `flutter test test/services/game_manager_test.dart`
4. Verify existing `lib/services/game_manager.dart` passes all tests (validate timing and coordination logic)
5. Run coverage analysis to confirm 85%+ coverage on game_manager.dart
6. Prepare PR with commit: `test(services): add unit tests for GameManager with mocked dependencies` - dartdoc for timer and coordination tests

Task 1.10: Widget Tests - Menu Screen - Agent_Testing_Foundation_UI - Depends on Task 1.1 output by Agent_Testing_Foundation_Models
1. Create `test/screens/menu_screen_test.dart` with Given-When-Then structure and widget test harness (pumpWidget with Provider setup for GameManager)
2. Write failing tests for: title displays correctly (finder by text), play button navigation (tap simulation and route verification), level select dialog opens (tap and dialog finder), level grid displays 20 levels (count verification), How to Play dialog functionality (tap and content verification), GameManager integration (Provider.of access)
3. Run tests to verify failures - `flutter test test/screens/menu_screen_test.dart`
4. Verify existing `lib/screens/menu_screen.dart` passes all tests (validate UI rendering and interaction logic)
5. Run coverage analysis to confirm 85%+ coverage on menu_screen.dart
6. Prepare PR with commit: `test(screens): add widget tests for MenuScreen navigation and dialogs` - Given-When-Then naming

Task 1.11: Widget Tests - Game Screen - Agent_Testing_Foundation_UI - Depends on Task 1.1 output by Agent_Testing_Foundation_Models
1. Create `test/screens/game_screen_test.dart` with Given-When-Then structure and widget test harness (pumpWidget with Provider<GameState> and Provider<GameManager> mocks)
2. Write failing tests for: HUD displays score/balls/level (finder by text with current state values), PachinkoBoard renders (finder by widget type), control buttons present (pause, resume, next level, back), pause/resume toggle (tap simulation and state verification), next level button conditional display (verify appears when level complete, hidden otherwise), back navigation (tap and route pop verification), Consumer updates on state change (trigger GameState.notifyListeners, verify rebuild)
3. Run tests to verify failures - `flutter test test/screens/game_screen_test.dart`
4. Verify existing `lib/screens/game_screen.dart` passes all tests (validate state-driven UI updates)
5. Run coverage analysis to confirm 85%+ coverage on game_screen.dart
6. Prepare PR with commit: `test(screens): add widget tests for GameScreen with Provider state management` - dartdoc for Consumer behavior tests

Task 1.12: Widget Tests - Pachinko Board (with golden tests) - Agent_Testing_Foundation_UI - Depends on Task 1.1 output by Agent_Testing_Foundation_Models
1. Create `test/widgets/pachinko_board_test.dart` with Given-When-Then structure and widget test harness (pumpWidget with full game state setup for CustomPainter context)
2. Write failing tests for: gesture detection (GestureDetector onPanStart/Update/End), power calculation from drag distance (verify dragY to power 0-100 mapping), launch trigger on pan end (verify BallLauncher.launch called), board scaling calculation (screen size to game coordinates), special bonus overlay display (verify overlay appears when all special pegs hit)
3. Add golden tests for canvas rendering: pegs (different colors for normal/special/hit), balls (position and appearance), slots (score labels), launch path visualization (curve during charging), special bonus overlay (visual appearance) - use `matchesGoldenFile('pachinko_board_golden.png')`
4. Run tests to verify failures, generate golden reference images - `flutter test --update-goldens test/widgets/pachinko_board_test.dart`
5. Verify existing `lib/widgets/pachinko_board.dart` passes all tests (validate gesture logic and rendering)
6. Run coverage analysis to confirm 85%+ coverage on pachinko_board.dart, prepare PR with commit: `test(widgets): add widget and golden tests for PachinkoBoard custom painter` - commit golden reference images, dartdoc for golden test maintenance

Task 1.13: Integration Tests - Complete Game Flows - Agent_Testing_Foundation_Integration - Depends on Task 1.1 output by Agent_Testing_Foundation_Models
1. Create `integration_test/` directory and files: `app_test.dart` (basic app launch), `game_flow_test.dart` (complete gameplay), update `pubspec.yaml` with `integration_test` sdk dependency if needed
2. Write failing integration tests in `app_test.dart`: app launches without errors, menu screen displays correctly, navigation to game screen works
3. Write failing integration tests in `game_flow_test.dart` with Given-When-Then structure: complete game flow (menu � play � launch balls � score points � level complete � next level), ball launching and physics simulation (verify balls move correctly over time), scoring system (verify score accumulation), special bonus triggering (hit all special pegs, verify bonus balls spawn), level progression (levels 1-5 with different patterns), game over scenario (20 balls exhausted), back navigation preserves state
4. Run integration tests to verify failures - `flutter test integration_test/`
5. Verify existing app implementation passes all integration tests (validate end-to-end functionality)
6. Run coverage analysis (integration tests contribute to overall coverage), prepare PR with commit: `test(integration): add end-to-end tests for complete game flows` - document test execution time and ensure < 2 minute target

Task 1.14: Coverage Validation & Phase Gate Verification - Agent_Testing_Foundation_Integration - Depends on all tasks (1.2-1.13) output by Agent_Testing_Foundation_Models, Agent_Testing_Foundation_Services, Agent_Testing_Foundation_UI
1. Run comprehensive coverage analysis across all test files - `flutter test --coverage`
2. Validate coverage thresholds: Overall coverage e 85%, models/ e 85%, services/ e 85%, screens/ e 85%, widgets/ e 85%, utils/ coverage (no minimum but report)
3. Validate test pass rate: 100% tests passing (zero failures, zero skipped)
4. Generate coverage report summary: Total lines covered/total lines, per-directory breakdown, list any files below 85% threshold
5. Present coverage report to User with phase gate status: "Phase 1 complete - 85% coverage achieved, 100% test pass rate, Phase 2 UNLOCKED" or "Phase 1 incomplete - coverage gaps identified, additional tests required before Phase 2"

Phase 2: Feature Implementation - Agent_Audio_Integration, Agent_Visual_Effects, Agent_Persistence_Features

Task 2.1: Sound Asset Research & Sourcing - Agent_Audio_Integration
1. Ad-Hoc Delegation – Research royalty-free sound asset libraries and identify 5 sound effects
2. Consolidate research findings: List recommended sound assets with source URLs, preview links, licensing terms (ensure commercial use allowed for pachinko game: launch sound, peg hit sound, special peg sound, slot score sound, bonus trigger sound)
3. User Approval Checkpoint: Present sound asset previews to User for listening validation - User approves audio quality before proceeding
4. Document final asset selection with licensing information: Source URLs, license type (Creative Commons, royalty-free, etc.), attribution requirements if any
5. Download approved assets to `assets/sounds/` directory (launch.mp3, peg_hit.mp3, special_peg.mp3, slot_score.mp3, bonus_trigger.mp3), update `pubspec.yaml` to include assets/ directory

Task 2.2: Audio Service Implementation & Integration - Agent_Audio_Integration - Depends on Task 2.1 output
1. Create failing tests in `test/services/audio_service_test.dart` with Given-When-Then structure: playLaunch(), playPegHit(), playSpecialPeg(), playSlotScore(int points), playBonusTrigger(), setVolume(double), dispose(), audio pooling (simultaneous playback), verify no lag/stuttering
2. Implement `lib/services/audio_service.dart` with just_audio library: AudioPlayer pool for simultaneous playback, load assets from `assets/sounds/`, implement playback methods, volume control, dispose cleanup
3. Integrate audio service into game: Add Provider<AudioService> to main.dart, integrate playLaunch() in ball_launcher.dart:107, playPegHit() in physics_engine.dart:104 (on collision), playSpecialPeg() and playBonusTrigger() in game_manager.dart:144, playSlotScore() in game_manager.dart:155
4. Run tests to verify AudioService passes all tests - `flutter test test/services/audio_service_test.dart`
5. Run coverage analysis to confirm 85%+ coverage on audio_service.dart, manual testing to verify no audio lag/stuttering during gameplay (60 FPS requirement maintained)
6. Prepare PR with commit: `feat(audio): implement AudioService with just_audio and integrate sound effects` - dartdoc for audio pooling pattern

Task 2.3: Animations & Visual Polish - Agent_Visual_Effects
1. Create failing tests in updated `test/widgets/pachinko_board_test.dart` and new animation test files with Given-When-Then structure: ball launch animation (curve interpolation), peg hit animation (pulse effect triggers), special peg glow (shimmer state), score popup (floating text appearance), bonus trigger (flash + particles), level transition (fade timing) - update golden tests for visual regression
2. Implement animations in `lib/widgets/pachinko_board.dart`: Add AnimatedBuilder for ball launch path, peg hit pulse (Canvas glow effect), score popup (floating Text widget with Animate extension)
3. Implement special peg glow in `lib/models/peg.dart`: Add animation state field, shimmer effect in `lib/widgets/pachinko_board.dart` rendering
4. Implement bonus trigger and level transition in `lib/screens/game_screen.dart`: Screen flash overlay with Animate, particle burst effect, fade in/out animation for level changes
5. Run tests to verify all animations pass tests (including updated golden tests), run performance profiling to confirm 60 FPS maintained during animations (emulator validation), User Approval Checkpoint: Present major visual changes for User review
6. Run coverage analysis to confirm 85%+ coverage on animation code, prepare PR with commit: `feat(ui): implement animations and visual polish with flutter_animate` - dartdoc for animation performance considerations

Task 2.4: High Score Persistence - Agent_Persistence_Features
1. Create failing tests in `test/services/storage_service_test.dart`, `test/models/high_score_test.dart`, `test/screens/high_scores_screen_test.dart` with Given-When-Then structure: saveHighScore(level, score), getHighScores(level) returns sorted list, getTotalScore() aggregates all scores, clearData() removes all data, HighScore model serialization, UI displays high scores correctly
2. Implement `lib/models/high_score.dart`: Model with level, score, timestamp fields, JSON serialization (toJson, fromJson)
3. Implement `lib/services/storage_service.dart` with shared_preferences: saveHighScore persists to storage with key pattern "highscore_level_X", getHighScores loads and sorts scores, getTotalScore aggregates, clearData removes all keys
4. Implement `lib/screens/high_scores_screen.dart`: Display high scores per level with ListView, show personal best on level complete screen, clear data option button
5. Integrate into menu: Update `lib/screens/menu_screen.dart` to add "High Scores" button, navigate to HighScoresScreen, verify scores persist across app restarts (manual testing with flutter run, close, reopen)
6. Run tests to verify all persistence logic passes, run coverage analysis to confirm 85%+ coverage on storage_service.dart and high_score.dart, prepare PR with commit: `feat(persistence): implement high score persistence with shared_preferences` - dartdoc for serialization pattern

Task 2.5: Achievement System - Agent_Persistence_Features
1. Design 15-20 achievements with criteria from CODE_REVIEW.md: "First Launch" (launch first ball), "Perfect Shot" (hit all special pegs in one level), "High Roller" (score 50,000+), "Streak Master" (complete 5 levels in a row), "Collector" (unlock all achievements), "Level 20" (reach level 20), plus 9-14 more creative achievements - document achievement definitions with unlock criteria
2. Create failing tests in `test/models/achievement_test.dart`, `test/services/achievement_service_test.dart`, `test/screens/achievements_screen_test.dart` with Given-When-Then structure: Achievement model, checkProgress(event), unlockAchievement(id), getUnlockedAchievements(), persistence (save/load), notification display, UI rendering (badges, progress bars)
3. Implement `lib/models/achievement.dart`: Model with id, name, description, criteria, unlocked status, progress tracking, icon/badge reference
4. Implement `lib/services/achievement_service.dart`: Track game events (ball launched, special peg hit, level complete, score threshold), check achievement criteria, unlock logic, persistence with shared_preferences, notification system on unlock (SnackBar or overlay)
5. Integrate achievement tracking into game: Add AchievementService provider to main.dart, track events in game_manager.dart (ball launch, level complete, score update), physics_engine.dart (special peg hit), implement `lib/screens/achievements_screen.dart` (display unlocked achievements with badges, progress bars for incomplete)
6. Run tests to verify all achievement logic passes, run coverage analysis to confirm 85%+ coverage on achievement files, prepare PR with commit: `feat(achievements): implement achievement system with 15-20 unique badges` - dartdoc for achievement tracking pattern

Phase 3: Android Optimization - Agent_Android_Release_Config, Agent_Android_Release_Optimization

Task 3.1: Android Keystore Generation & Signing Configuration - Agent_Android_Release_Config
1. Generate release keystore using keytool: `keytool -genkey -v -keystore ~/pachinko-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias pachinko` - use strong passwords, document keystore location (DO NOT commit to git)
2. Create `android/key.properties` file with keystore credentials (storePassword, keyPassword, keyAlias, storeFile path), add `key.properties` to `.gitignore` to prevent credential exposure
3. Configure signing in `android/app/build.gradle`: Load key.properties, configure signingConfigs for release build type, reference keystore for APK signing
4. User Coordination: Instruct User to securely backup keystore file (`~/pachinko-release-key.jks`) and key.properties to secure location outside git repo - keystore loss prevents future app updates
5. Validate signing configuration: Run `flutter build apk --release` to verify APK builds and signs successfully, inspect APK with `jarsigner -verify` to confirm signature

Task 3.2: Android App Configuration & ProGuard Rules - Agent_Android_Release_Config
- Update `android/app/src/main/AndroidManifest.xml`: Set app name to "Pachinko" (not "pachinko_game"), configure minSdkVersion 21, targetSdkVersion 34, add necessary permissions if needed (internet access for potential future features, though current game is offline)
- Create/update `android/app/proguard-rules.pro`: Add ProGuard rules for code obfuscation and optimization (keep Flutter engine classes, keep game model classes for reflection, optimize unused code removal)
- Enable ProGuard in `android/app/build.gradle`: Configure release build type with `minifyEnabled true`, `shrinkResources true`, `proguardFiles` reference
- Validate configuration: Run `flutter build apk --release`, verify APK size reduction (ProGuard optimization), test APK installation on emulator to ensure obfuscation doesn't break functionality

Task 3.3: App Icon & Splash Screen Implementation - Agent_Android_Release_Config
1. User Coordination: Obtain app icon design from User (high-resolution PNG, minimum 512x512px recommended) - User committed to provide today
2. Generate icon assets at 5 densities: mdpi (48x48), hdpi (72x72), xhdpi (96x96), xxhdpi (144x144), xxxhdpi (192x192) - use image resizing tool or flutter_launcher_icons package
3. Place icon assets in `android/app/src/main/res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png`, update `android/app/src/main/AndroidManifest.xml` to reference `@mipmap/ic_launcher`
4. Configure splash screen in `android/app/src/main/res/drawable/launch_background.xml`: Design splash using app icon or branding elements, ensure consistent with game theme
5. Validate icon and splash on emulator: Test on different screen sizes (5", 6", 7") and densities, verify icon displays correctly in launcher, splash screen shows during app load

Task 3.4: Android Emulator Setup & Configuration - Agent_Android_Release_Optimization
- Create Android emulator configurations using avdmanager: API levels to test (API 21 for minSdk, API 34 for targetSdk, API 28-30 for mid-range), device profiles for screen sizes (5" 16:9, 6" 18:9, 7" tablet), ensure sufficient RAM allocated (2GB minimum)
- Start emulators and verify functionality: `flutter run -d <emulator-id>` to test game launch, verify 60 FPS performance on emulator, test touch input and gestures
- Document emulator configuration: List created AVDs with API levels and screen specs, document commands to start each emulator for future testing
- Validate emulator meets testing requirements: Confirm game runs at 60 FPS (use Flutter DevTools performance overlay), memory usage < 200MB, no rendering issues across different screen sizes

Task 3.5: Cloud Testing Service Research & Evaluation - Agent_Android_Release_Optimization - Depends on Task 3.4 output
1. Ad-Hoc Delegation – Research cloud Android device testing services (Firebase Test Lab, AWS Device Farm, BrowserStack, Sauce Labs)
2. Consolidate research findings: Compare services on: device coverage (API levels 21-34, manufacturers), pricing (free tier vs paid plans), test execution time limits, integration with GitHub Actions CI, ease of setup
3. User Decision Checkpoint: Present service comparison to User, recommend best option based on features and cost (e.g., Firebase Test Lab free tier for basic testing), User selects service based on budget constraints
4. Document setup instructions for chosen service: Account creation steps, test matrix configuration (device selection, API levels), integration approach (manual upload vs CI integration), cost management tips
5. Create integration plan: If User approves CI integration, outline GitHub Actions workflow for cloud testing (or defer to Phase 4 CI setup task), document how to trigger cloud tests manually for immediate use

Task 3.6: Spatial Hashing & Collision Detection Optimization - Agent_Android_Release_Optimization
1. Create failing tests in updated `test/services/physics_engine_test.dart`: Spatial hashing grid creation, ball-to-cell assignment, nearby cell queries (3x3 grid around ball), collision detection returns same results as O(n²) brute force (accuracy validation), performance test (measure collision check time)
2. Implement spatial hashing in `lib/services/physics_engine.dart`: Create SpatialGrid class with cell size based on peg radius, map balls to grid cells, query nearby cells (3x3 neighborhood) instead of all pegs, update collision detection to use spatial grid
3. Validate collision accuracy: Run all existing physics tests to ensure collision behavior unchanged (same collision normals, same impulse calculations, same outcomes), verify no physics regression
4. Performance benchmarking: Measure FPS before and after optimization using Flutter DevTools, target 60 FPS on emulator with 50+ balls active, document FPS improvement in PR description
5. Run coverage analysis to confirm 85%+ coverage maintained on physics_engine.dart (including new spatial hashing code)
6. Prepare PR with commit: `perf(physics): implement spatial hashing for O(n) collision detection` - dartdoc explaining spatial grid algorithm, document performance improvement metrics

Task 3.7: Memory Management & Rendering Optimization - Agent_Android_Release_Optimization
1. Create failing tests for optimizations: Object pool test (ball reuse, no new allocations after initial pool), render cache test (static elements cached, not redrawn every frame), shouldRepaint test (only repaints when game state changes), memory usage test (measure peak allocation)
2. Implement object pooling for Ball in `lib/models/ball.dart` or new `lib/utils/object_pool.dart`: Create BallPool class, reuse Ball instances instead of creating new ones, reset() instead of new Ball(), manage pool size (limit to 50 balls max)
3. Implement rendering optimizations in `lib/widgets/pachinko_board.dart`: Cache static peg/slot rendering to separate layer, update shouldRepaint to compare game state (balls, phase, launchPath) instead of always returning true, minimize Paint object allocations
4. Performance validation: Measure FPS with optimizations using Flutter DevTools, target 60 FPS sustained with 20 active balls on emulator, measure memory usage (< 200MB target), verify no rendering glitches
5. Run coverage analysis to confirm 85%+ coverage on optimized code
6. Prepare PR with commit: `perf(rendering): implement object pooling and render caching for 60 FPS` - dartdoc explaining optimization patterns, document FPS and memory improvements

Task 3.8: Device Testing Execution & Performance Validation - Agent_Android_Release_Optimization - Depends on Task 3.1 output by Agent_Android_Release_Config - Depends on Task 3.2 output by Agent_Android_Release_Config - Depends on Task 3.3 output by Agent_Android_Release_Config - Depends on Task 3.4 output - Depends on Task 3.6 output - Depends on Task 3.7 output
1. Execute performance tests on emulator: Run game with Flutter DevTools performance overlay, measure sustained FPS (target 60 FPS), memory usage (target < 200MB), app startup time (target < 100ms), battery drain during 1-hour session (if emulator supports), validate no frame drops during ball launches or bonus triggers
2. Execute compatibility tests on emulator: Test on API 21 (minSdk), API 28-30 (mid-range), API 34 (targetSdk), different screen sizes (5", 6", 7"), different aspect ratios (16:9, 18:9, 19.5:9), verify no rendering issues or crashes
3. Execute functional tests on emulator: Test app lifecycle (pause, resume, background), audio playback (sound effects play correctly, no lag), device rotation (portrait/landscape if supported), state persistence on app restart, game flows (menu → play → level complete)
4. User Coordination: Provide Samsung S23+ testing instructions to User (install APK, run performance/compatibility/functional test scenarios), User executes tests on physical device and reports results (FPS, memory, any issues observed)
5. Consolidate test results: Document emulator results and Samsung S23+ results in test report, compare performance across devices, identify any device-specific issues or optimizations needed
6. Validate against release targets: Confirm performance targets met (60 FPS ✓, < 200MB memory ✓, < 100ms startup ✓), compatibility across Android 5.0-14 ✓, functional tests pass ✓ - mark Phase 3 complete if all targets achieved

Phase 4: Quality Infrastructure - Agent_Quality_Infrastructure

Task 4.1: API Documentation (dartdoc) - Agent_Quality_Infrastructure
1. Document models layer (`lib/models/*.dart`): Add dartdoc comments to Ball, Peg, Slot, BallLauncher, Level, GameState - include brief descriptions, detailed explanations, parameter/return value docs, examples for complex classes (Level generation, BallLauncher path geometry)
2. Document services layer (`lib/services/*.dart`): Add dartdoc comments to PhysicsEngine, GameManager, AudioService, StorageService, AchievementService - include algorithm explanations (spatial hashing, physics calculations), usage examples
3. Document screens/widgets (`lib/screens/*.dart`, `lib/widgets/*.dart`): Add dartdoc comments to MenuScreen, GameScreen, HighScoresScreen, AchievementsScreen, PachinkoBoard - include widget usage examples, parameter explanations
4. Document utils (`lib/utils/*.dart`): Add dartdoc comments to constants.dart (explain game parameters), peg_patterns.dart (pattern generation logic)
5. Run `dart doc` to generate documentation and verify zero warnings, review generated HTML docs to ensure clarity and completeness
6. Prepare PR with commit: `docs(api): add comprehensive dartdoc comments to all public APIs` - ensure standard Dart style guide followed, examples provided for complex classes

Task 4.2: Code Quality Improvements - Agent_Quality_Infrastructure
- Fix identified issues: Correct typo "baseLegsPerLevel" → "basePegsPerLevel" in constants.dart:89, remove unused debug flags (constants.dart:70-71), add missing LaunchPhase import in game_manager.dart, extract magic numbers to named constants (e.g., gravity 980.0, damping 0.999)
- Add error handling for storage operations in storage_service.dart: Wrap shared_preferences calls in try-catch, handle errors gracefully (return empty lists on load failure, log errors), prevent crashes on storage access issues
- Implement simple logging service in `lib/utils/logger.dart`: Create Logger class with debug/info/warning/error methods, log to console with timestamps and log levels, integrate into critical paths (physics errors, storage failures, achievement unlock events)
- Run `flutter analyze` to verify zero issues, run `flutter format` to ensure consistent formatting, prepare PR with commit: `refactor(quality): fix typos, extract constants, add error handling and logging` - document all fixes in PR description

Task 4.3: Pre-commit Hooks Setup - Agent_Quality_Infrastructure
1. Read pre-commit template from `~/projects/templates/.pre-commit-config.yaml` to understand pattern, identify Python-specific hooks (black, ruff, pytest) to map to Flutter equivalents (flutter format, flutter analyze, flutter test)
2. Create `.pre-commit-config.yaml` for Flutter: Configure repos for flutter hooks, add hooks for flutter format (auto-format code), flutter analyze (lint checks), optional flutter test (can be slow, maybe skip for pre-commit and rely on CI)
3. Install pre-commit: Run `pre-commit install` to set up git hooks, configure to run on `git commit`, ensure hooks block commits if checks fail
4. Test pre-commit hooks: Make test commit with formatting issues to verify flutter format runs, make commit with lint issues to verify flutter analyze blocks, test bypass with `git commit --no-verify` to confirm escape hatch works
5. Document pre-commit usage in project docs: Add section to README.md or CLAUDE.md explaining pre-commit hooks, how to install (`pre-commit install`), how to bypass if needed (`--no-verify`), what checks run (format, analyze)

Task 4.4: GitHub Actions CI/CD Pipeline - Agent_Quality_Infrastructure - Depends on Task 4.3 output
1. Create `.github/workflows/test.yml` with GitHub Actions workflow: Configure triggers (on push, pull_request), setup job with ubuntu-latest runner, checkout code step, setup Flutter 3.24.5 (use subosito/flutter-action)
2. Add test steps to workflow: Run `flutter pub get` to install dependencies, run `flutter analyze` (fails workflow if issues found), run `flutter test --coverage` (generates coverage report)
3. Add coverage threshold validation: Parse coverage/lcov.info to calculate coverage percentage, fail workflow if coverage < 85%, alternatively integrate codecov action for automated coverage reporting and threshold enforcement
4. Test CI workflow: Create test branch with intentional lint issue to verify flutter analyze fails workflow, create test branch with passing tests to verify workflow succeeds, verify coverage threshold enforcement works
5. Add CI status badge to README.md: Include GitHub Actions badge showing test workflow status, helps visualize CI health in repo
6. Document CI pipeline in project docs: Explain what CI checks run (analyze, test, coverage), how to view workflow results on GitHub, coverage threshold requirement (85%), troubleshooting failed workflows

Task 4.5: Update Project Documentation - Agent_Quality_Infrastructure - Depends on Task 4.1 output - Depends on Task 4.2 output - Depends on Task 4.4 output
- Update README.md: Reflect current implementation status (update feature completion checkboxes, remove ⚠️ warnings after testing/features/Android work complete), update performance metrics table with measured values, remove broken links, verify all referenced files exist
- Update CLAUDE.md: Mark completed phases (Phase 1-3 in "Current Implementation Status"), update "Key Game Mechanics" if any gameplay changes, ensure command examples are accurate and tested
- Create CHANGELOG.md: Document version history following Keep a Changelog format, add v0.1.0 (initial playable prototype), v1.0.0 (production-ready release with tests, features, Android optimization), list major changes per version
- Prepare PR with commit: `docs(project): update documentation to reflect production-ready status` - ensure no outdated information remains, all links work, documentation matches codebase reality

Phase 5: Advanced Features (Optional - Low Priority) - Agent_Advanced_Features

Task 5.1: Multiple Save Slots - Agent_Advanced_Features
1. Create failing tests for save slot system: Profile model, multiple save slots (3-5 slots), save/load per slot, stats tracking per profile, profile selection UI
2. Implement Profile model and storage: Extend storage_service.dart with profile management, save slot data structure (profile name, level progress, total score, stats)
3. Implement profile selection screen: Create ProfileSelectScreen, list available slots, new profile creation, delete profile option
4. Integrate profile system into game: Load selected profile on startup, save progress to active profile, track stats per profile (total playtime, levels completed, highest score)
5. Run tests to verify all profile logic passes, run coverage analysis to confirm 85%+ coverage
6. Prepare PR with commit: `feat(profiles): implement multiple save slots with profile management` - TDD enforced

Task 5.2: Daily Challenges - Agent_Advanced_Features
1. Create failing tests for daily challenge system: Deterministic daily level generation (date-based seed), challenge reward system, completion tracking, leaderboard persistence
2. Implement daily challenge generation: Create DailyChallenge model, generate level based on current date seed, special challenge modifiers (limited balls, required special pegs, score targets)
3. Implement challenge reward system: Bonus points for daily completion, streak tracking (consecutive days), special achievements for challenge completion
4. Create daily challenge UI: Challenge menu entry, display challenge rules and rewards, leaderboard showing top scores for current day's challenge
5. Run tests to verify all challenge logic passes, run coverage analysis to confirm 85%+ coverage
6. Prepare PR with commit: `feat(challenges): implement daily challenge system with procedural generation` - TDD enforced

Task 5.3: Theme Customization - Agent_Advanced_Features
1. Create failing tests for theme system: Theme model, ball color themes (unlockable), board background themes, theme persistence, unlock logic (achievement-based or score-based)
2. Implement theme system: Create Theme model, define 5-10 ball color schemes, define 3-5 board backgrounds, theme storage with shared_preferences
3. Implement theme unlock system: Unlock themes via achievements or score milestones, integrate with existing achievement system
4. Create theme selection UI: Theme menu screen, preview ball colors and backgrounds, apply selected theme to game
5. Run tests to verify all theme logic passes, run coverage analysis to confirm 85%+ coverage, validate theme rendering in game (golden tests updated)
6. Prepare PR with commit: `feat(themes): implement customizable ball colors and board backgrounds` - TDD enforced
