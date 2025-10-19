# Pachinko Game - Development Reference

## Project Overview
A modern graphical Pachinko idle game for Android. Features authentic pachinko machine mechanics with realistic ball launching, physics simulation, and strategic scoring.

## Current Status: 🚧 GRAPHICS OVERHAUL IN PROGRESS (Feature 002)
### Completed Features
- ✅ Authentic ball launching system (bottom-right launch channel)
- ✅ Advanced physics engine with collision detection
- ✅ Organized peg patterns with proper spacing
- ✅ Complete UI with power meter and visual feedback
- ✅ Level progression system with varying patterns
- ✅ Special peg bonus mechanics
- ✅ Cross-platform (Linux desktop, Android-ready)

### Graphics Enhancement (Feature 002) - 52% Complete
**Branch**: `002-graphics-overhaul` | **Spec**: `specs/002-graphics-overhaul/spec.md`

✅ **Phase 1-2: Infrastructure & Foundation** (T001-T012) - COMPLETE
- Graphics configuration system with quality levels (High/Medium/Low)
- Particle model with lifecycle management and object pooling
- ParticleSystem with separate pools (100 trail, 50 collision)
- AnimationState & AnimationController with easing curves
- PerformanceMonitor with 60-frame circular buffer and FPS tracking
- RenderingLayer with anti-aliasing support

✅ **Phase 3: Particle Effects (P1)** (T013-T029) - COMPLETE
- 128 unit tests for particle system (all passing)
- Trail particles on ball movement (velocity > 50 px/s)
- Collision burst effects on peg hits (8-particle radial pattern)
- Particle rendering integrated in PachinkoBoard CustomPainter
- Performance-based adaptive quality adjustment
- Special peg collision enhancements

✅ **Phase 4: Testing Framework (P1)** (T034-T041) - COMPLETE
- 13 widget tests for PachinkoBoard rendering
- 12 visual regression tests with golden file baselines
- Performance monitoring integration in GameManager
- Automated test utilities (update_goldens.sh, generate_coverage.sh)
- Graphics subsystem: **98.45% coverage** (exceeds 85% requirement)

🚧 **Phase 5: Glow Animations (P2)** (T042-T057) - 26% Complete
- ✅ T042-T043: AnimationState + AnimationController (49 tests passing)
  - Multi-animation coordination with easing curves
  - Looping and non-looping animation support
  - Linear, easeIn, easeOut, easeInOut curve implementations
- 📋 T044-T045: GlowEffect widget and integration tests
- 📋 T046-T057: GlowEffect implementation and GameManager integration

📋 **Pending**:
- Phase 6: UI polish and anti-aliasing (T058-T067)
- Phase 7: Performance optimization (T068-T072)
- Phase 8: Documentation and polish (T073-T082)

**Test Status**: **289 passing** | 2 skipped (widget golden baselines) | 98.45% graphics coverage

## Technology Stack
- **Framework:** Flutter 3.24.5
- **Language:** Dart 3.5.4
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
│   ├── ball_launcher.dart      # Authentic launch system
│   ├── peg.dart                # Peg collision and types
│   ├── slot.dart               # Scoring slots at bottom
│   ├── level.dart              # Level generation and management
│   ├── game_state.dart         # Global game state management
│   └── particle.dart           # ✨ NEW: Particle effect model
├── services/
│   ├── physics_engine.dart     # Ball physics and collision detection
│   ├── game_manager.dart       # Main game loop and coordination
│   └── graphics/               # ✨ NEW: Graphics system
│       ├── particle_system.dart     # Particle pools and orchestration
│       ├── animation_controller.dart # Animation state management
│       ├── performance_monitor.dart  # FPS tracking and quality control
│       └── rendering_layer.dart      # Anti-aliased Paint configuration
├── screens/
│   ├── game_screen.dart        # Main gameplay screen
│   └── menu_screen.dart        # Main menu with level selection
├── widgets/
│   └── pachinko_board.dart     # Custom Canvas game board renderer (w/ particles)
└── utils/
    ├── constants.dart          # Game configuration and styling
    ├── graphics_config.dart    # ✨ NEW: Graphics constants
    └── peg_patterns.dart       # Organized peg layouts

test/
├── unit/                       # ✨ NEW: Unit tests (215 passing)
│   ├── particle_test.dart           # Particle model tests (56 tests)
│   ├── particle_pool_test.dart      # Pool management tests (31 tests)
│   ├── particle_system_test.dart    # System orchestration (28 tests)
│   ├── animation_controller_test.dart # Animation tests (35 tests)
│   ├── performance_monitor_test.dart  # Performance tests (39 tests)
│   └── performance_monitor_implementation_test.dart # (26 tests)
├── integration/                # ✨ NEW: Integration tests
│   ├── visual_regression_test.dart  # Golden file tests (12 tests)
│   └── README.md               # Visual testing guide
└── golden/                     # ✨ NEW: Golden file baselines
    ├── README.md               # Visual regression guidelines
    └── integration/            # Integration test golden files
```

## Key Commands
- `export PATH="/home/frankbria/projects/pachinko/tools/flutter/bin:$PATH"` - Set Flutter path
- `flutter run` - Run the game
- `flutter build apk` - Build Android APK
- `flutter test` - Run tests
- `flutter analyze` - Check code quality
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
- **Smart Peg Spacing**: 35px minimum spacing prevents overlap, ensures smooth ball flow
- **Pattern Variety**: Hexagonal, Triangle, and Random patterns cycle through levels
- **Physics Simulation**: 60 FPS with gravity, air resistance, realistic bouncing
- **Special Pegs**: 2-4 highlighted pegs per level trigger 5+ bonus balls
- **Inverse Scoring**: Edge slots = 2000pts, center = 1000pts, sides = 50-200pts
- **Power System**: Drag-to-charge launcher with visual power meter

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
  flutter test --coverage
  genhtml coverage/lcov.info -o coverage/html
  ```
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

- [ ] All tests pass (`flutter test`)
- [ ] Code coverage meets 85% minimum threshold
- [ ] Coverage report reviewed for meaningful test quality
- [ ] Code formatted and analyzed (`flutter format`, `flutter analyze`)
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
