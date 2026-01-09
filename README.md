# Pachinko Game 🎮

[![Follow on X](https://img.shields.io/twitter/follow/FrankBria18044?style=social)](https://x.com/FrankBria18044)

A modern, graphical Pachinko idle game built with Flutter for Android. Features authentic pachinko machine mechanics with realistic ball physics, strategic scoring, and beautiful visual effects.

## 🚀 Project Status

**Current Release**: v0.1.0 - Playable Prototype (2,243 LOC)
**Active Development Branch**: [`002-graphics-overhaul`](https://github.com/frankbria/pachinko/tree/002-graphics-overhaul) (65% complete)
**Quality Status**: ⚠️ Requires testing infrastructure (0% coverage → 85% required)

### What's Working in Master

Core gameplay is complete and functional:

- ✅ **Authentic Ball Launching** - Bottom-right launch channel with drag-to-charge power meter
- ✅ **Advanced Physics Engine** - 60 FPS realistic ball physics with gravity and collisions
- ✅ **Level System** - 3 distinct peg patterns (hexagonal, triangle, random) with infinite progression
- ✅ **Special Pegs & Bonuses** - Hit all special pegs to trigger 5+ bonus balls
- ✅ **Strategic Scoring** - Inverse probability distribution (edge slots = 2000pts, center = 1000pts)
- ✅ **Cross-Platform Ready** - Runs on Linux desktop, configured for Android deployment

### 🔨 In Development (`002-graphics-overhaul` Branch)

The graphics architecture overhaul transforms the prototype into a polished game:

**✅ Completed (Phase 1-5 - 65%)**:
- Particle system with trail and collision effects
- Performance monitoring with adaptive quality
- Animated glow effects on special pegs (pulsing golden halos)
- Enhanced collision particles (12 for special, 16 for bonus)
- 303 tests passing (98.45% graphics coverage)

**🔄 Next (Phase 6-8 - 35%)**:
- UI polish (transitions, score animations, anti-aliasing)
- Performance optimization (quality adjustments, memory)
- Documentation and cross-platform testing

See [DEVELOPMENT.md](./DEVELOPMENT.md) for feature branch workflow details.

### ⚠️ Critical Requirements Before Release

As documented in [CODE_REVIEW.md](./CODE_REVIEW.md), the following must be completed:

**PHASE 1: CRITICAL FIXES (Required by CLAUDE.md standards)**
- [ ] Fix broken test infrastructure
- [ ] Unit tests for all models (85%+ coverage target)
- [ ] Unit tests for all services (85%+ coverage target)
- [ ] Widget tests for UI layer (85%+ coverage target)
- [ ] Integration tests for complete game flows

**PHASE 2: MISSING FEATURES**
- [ ] Sound effects integration (using `just_audio`)
- [ ] Animations & visual polish (using `flutter_animate`)
- [ ] High score persistence (using `shared_preferences`)
- [ ] Achievement system (15-20 unique achievements)

**PHASE 3: ANDROID OPTIMIZATION**
- [ ] Release signing configuration
- [ ] App icon & branding (5 density variants)
- [ ] Performance optimization (spatial hashing, object pooling)
- [ ] Device testing strategy (low/mid/high-end devices)

**Estimated Time to Production**: 9 weeks (1 developer) following the [implementation timeline](./CODE_REVIEW.md#implementation-timeline)

## 🎮 Game Features

### Core Mechanics (Implemented)

- **Authentic Pachinko Launch**: Ball launches from bottom-right corner, travels up a 35-segment curved channel, enters peg field from top
- **Advanced Physics Engine**: 60 FPS simulation with gravity (980.0 px/s²), air resistance (0.999 damping), and realistic collision detection
- **Smart Peg Patterns**: Three distinct layouts with 35px minimum spacing to prevent overlap
  - **Hexagonal**: Organized grid pattern
  - **Triangle**: Pyramid arrangement
  - **Random**: Chaotic distribution (50 placement attempts per peg)
- **Special Peg Bonuses**: 2-4 highlighted pegs per level (50px spacing) trigger multi-ball bonuses (5 + level/2 balls)
- **Strategic Scoring**: Inverse probability distribution rewards skilled play
  - Edge slots: 2000 points (hardest to reach)
  - Center slot: 1000 points (medium difficulty)
  - Side slots: 50-200 points (easiest to reach)
- **Infinite Levels**: Pattern cycling with increasing difficulty

### Planned Features (Phase 2)

- **Sound Effects**: Launch, peg hit, special peg, slot score, bonus trigger
- **Animations**: Ball trails, peg glow, score popups, screen flash on bonus
- **High Scores**: Per-level leaderboards with persistence
- **Achievements**: 15-20 unlockable badges for gameplay milestones
- **Daily Challenges**: Procedurally generated special levels
- **Theme Customization**: Ball colors, board backgrounds, unlockable schemes

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK**: 3.24.5 or higher
- **Dart**: 3.5.4 or higher
- **Platform Tools**:
  - Linux: Development tools installed
  - Android: Android Studio with SDK 21+ (Android 5.0+)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/frankbria/pachinko.git
cd pachinko
```

2. Set Flutter path (if using bundled Flutter):
```bash
export PATH="/home/frankbria/projects/pachinko/tools/flutter/bin:$PATH"
```

3. Install dependencies:
```bash
flutter pub get
```

4. Verify installation:
```bash
flutter doctor
```

### Running the Game

```bash
# Linux desktop (primary development platform)
flutter run -d linux

# Android (requires Android Studio and device/emulator)
flutter run -d android

# Web browser
flutter run -d web-server

# Windows desktop
flutter run -d windows

# macOS desktop
flutter run -d macos
```

### Building for Release

```bash
# Android APK (release mode)
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release

# Linux executable
flutter build linux --release
```

**Note**: Android release signing is not yet configured. See [CODE_REVIEW.md - Task 3.1](./CODE_REVIEW.md#task-31-android-release-configuration) for setup instructions.

## 🎯 How to Play

### Basic Gameplay

1. **Launch a Ball**: Drag from the bottom-right corner to build launch power
   - **Power Meter**: Green (low) → Yellow (medium) → Red (high)
   - **Visual Feedback**: Launch path shows curve into peg field
2. **Watch Physics**: Ball travels up channel, curves into peg field, bounces through pegs
3. **Score Points**: Ball lands in slots at bottom for points
4. **Special Bonus**: Hit ALL highlighted orange pegs to spawn bonus balls
5. **Level Up**: Complete rounds to progress to new peg patterns

### Scoring Strategy

The scoring system rewards skilled shots to hard-to-reach slots:

| Slot Position | Points | Difficulty |
|---------------|--------|------------|
| Far Left Edge | 2000 | Hardest |
| Far Right Edge | 2000 | Hardest |
| Center | 1000 | Medium |
| Left Side | 50-200 | Easy |
| Right Side | 50-200 | Easy |

**Pro Tip**: Edge slots give 10-40x more points than side slots! Aim for the edges using high-power launches.

### Special Peg Mechanics

- **Orange Pegs**: 2-4 appear randomly per level
- **Bonus Trigger**: Hit ALL special pegs with any balls in the round
- **Reward**: 5 bonus balls at level 1, scaling up (+0.5 per level)
- **Reset**: Special pegs reset each level

## 🏗️ Project Structure

```
lib/
├── main.dart                    # App entry point with Provider setup
├── models/                      # Game objects (689 LOC)
│   ├── ball.dart               # Ball physics and state
│   ├── ball_launcher.dart      # Launch channel mechanics
│   ├── peg.dart                # Peg collision and types
│   ├── slot.dart               # Scoring slots
│   ├── level.dart              # Level generation with patterns
│   └── game_state.dart         # Global state management
├── services/                    # Game logic (357 LOC)
│   ├── physics_engine.dart     # 60 FPS physics simulation
│   └── game_manager.dart       # Main game loop coordination
├── screens/                     # UI screens (473 LOC)
│   ├── game_screen.dart        # Main gameplay interface
│   └── menu_screen.dart        # Menu with level selection
├── widgets/                     # Custom rendering (477 LOC)
│   └── pachinko_board.dart     # Canvas-based game board
└── utils/                       # Configuration (272 LOC)
    ├── constants.dart          # Game parameters and styling
    └── peg_patterns.dart       # Pattern generation algorithms
```

**Total**: 2,243 lines of Dart code across 14 source files

## 🧪 Development

### Running Tests

```bash
# Run all tests
flutter test

# Run with coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Open coverage report
open coverage/html/index.html
```

**Current Status**: Test infrastructure requires fixes (see [CODE_REVIEW.md - Task 1.1](./CODE_REVIEW.md#task-11-fix-broken-test-infrastructure))

### Code Quality

```bash
# Analyze code for issues
flutter analyze

# Format code
flutter format lib/ test/

# Check for formatting issues
flutter format --set-exit-if-changed lib/ test/
```

**Quality Gates** (enforced by CLAUDE.md):
- ✅ Zero `flutter analyze` warnings
- ⚠️ Test coverage ≥ 85% (currently 0%)
- ⚠️ 100% test pass rate (currently N/A)
- ⚠️ 100% API documentation (currently minimal)

### Development Workflow

This project follows feature branch development:

1. Create feature branch: `git checkout -b feature/my-feature`
2. Implement changes with TDD approach
3. Ensure tests pass: `flutter test`
4. Verify coverage: `flutter test --coverage`
5. Commit with conventional commits: `git commit -m "feat: add feature"`
6. Push to remote: `git push origin feature/my-feature`
7. Create pull request for review

See [CLAUDE.md](./CLAUDE.md) for complete development standards.

## 📱 Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| ✅ Linux | Fully Tested | Primary development platform |
| ✅ Android | Configured | Release signing pending |
| ✅ Web | Supported | Canvas rendering works |
| ✅ Windows | Supported | Not tested |
| ✅ macOS | Supported | Not tested |
| ✅ iOS | Supported | Not tested |

**Android Requirements**:
- Minimum SDK: 21 (Android 5.0 Lollipop)
- Target SDK: 34 (Android 14)
- Performance: 60 FPS on mid-range devices (2+ GB RAM)

## 📊 Performance Targets

From [CODE_REVIEW.md](./CODE_REVIEW.md#success-metrics):

| Metric | Target | Current |
|--------|--------|---------|
| Frame Rate | 60 FPS sustained | ✅ Achieved |
| Memory Usage | < 200MB | ⚠️ Not measured |
| App Startup | < 100ms | ⚠️ Not measured |
| Battery Drain | < 10%/hour | ⚠️ Not measured |
| APK Size | < 50MB | ⚠️ Not measured |

### Optimization Roadmap

Planned optimizations (Phase 3):
- Spatial hashing for O(n) collision detection (currently O(n²))
- Object pooling for Ball instances
- Canvas rendering optimization (shouldRepaint logic)
- Static element caching (pegs, slots)

## 📝 Documentation

- **[Product Requirements](PRD.md)** - Original product vision and requirements
- **[Development Guide](CLAUDE.md)** - AI-assisted development instructions
- **[Code Review](CODE_REVIEW.md)** - Comprehensive implementation analysis and task list
- **[Development Workflow](DEVELOPMENT.md)** - Feature branch workflow details
- **[AI Handoff](AI_HANDOFF.md)** - Context for AI-assisted development sessions

## 🤝 Contributing

Contributions are welcome! This project follows strict quality standards:

### Quality Requirements (from CLAUDE.md)

Before any PR is merged:

1. **Testing**:
   - All tests must pass (100% pass rate)
   - Minimum 85% code coverage on new code
   - Unit, widget, and integration tests as appropriate

2. **Git Workflow**:
   - Work on feature branches (never directly on `main`)
   - Use conventional commits: `feat:`, `fix:`, `docs:`, `test:`, etc.
   - All changes must be committed and pushed

3. **Documentation**:
   - Update inline code comments
   - Add dartdoc comments for public APIs
   - Update relevant markdown files (README.md, CLAUDE.md, etc.)

4. **Code Quality**:
   - Zero `flutter analyze` warnings
   - Code formatted with `flutter format`
   - No TODO comments in final code

### Contribution Workflow

1. Fork the repository
2. Create feature branch: `git checkout -b feature/your-feature`
3. Make changes following quality standards
4. Run tests: `flutter test --coverage`
5. Commit: `git commit -m "feat(scope): description"`
6. Push: `git push origin feature/your-feature`
7. Submit pull request with clear description

## 🗺️ Roadmap

### Short-term (Next 9 weeks)

Following the [CODE_REVIEW.md implementation timeline](./CODE_REVIEW.md#implementation-timeline):

**Sprint 1-2** (4 weeks): Testing Infrastructure
- Fix broken test file
- Achieve 85% coverage across models, services, widgets
- Add integration tests for critical flows
- Complete API documentation (dartdoc)

**Sprint 3** (3 weeks): Feature Completion
- Sound effects integration
- Animations and visual polish
- High score persistence
- App icon and branding

**Sprint 4** (2 weeks): Android Polish
- Release signing configuration
- Performance optimization
- Multi-device testing
- Final QA and bug fixes

### Long-term (Post-Release)

- Daily challenge system
- Achievement expansion (15-20 unique badges)
- Theme customization
- Multiple save slots
- Social features (leaderboards, score sharing)
- Power-ups (magnetic pegs, score multipliers)

## 📄 License

This project is open source. Feel free to use and modify as needed.

## 🏆 Current Achievements

- ✅ **Playable Prototype**: Fully functional core gameplay
- ✅ **Clean Architecture**: Well-organized 2,243 LOC codebase
- ✅ **60 FPS Physics**: Advanced collision detection and ball dynamics
- ✅ **Cross-Platform**: Runs on 6 platforms (Linux, Android, Web, Windows, macOS, iOS)
- ✅ **Authentic Mechanics**: Real pachinko launch channel with curve
- ✅ **Pattern Variety**: 3 distinct peg layouts with smart spacing

## 📞 Support & Feedback

- **Issues**: [GitHub Issues](https://github.com/frankbria/pachinko/issues)
- **Discussions**: [GitHub Discussions](https://github.com/frankbria/pachinko/discussions)
- **Pull Requests**: [GitHub PRs](https://github.com/frankbria/pachinko/pulls)

---

Built with ❤️ using Flutter | Last Updated: 2025-11-16
