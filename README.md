# Pachinko Game 🎮

[![Follow on X](https://img.shields.io/twitter/follow/FrankBria18044?style=social)](https://x.com/FrankBria18044)

A modern, graphical Pachinko idle game built with Flutter for Android. Features authentic pachinko machine mechanics with realistic ball physics, strategic scoring, and beautiful visual effects.

## 🎮 Game Features

### Core Mechanics (Implemented)

- **Authentic Pachinko Launch**: Ball launches from bottom-right corner, travels up a 35-segment curved channel, enters peg field from top
- **Advanced Physics Engine**: 60 FPS simulation with gravity (980.0 px/s²), air resistance (0.999 damping), and realistic collision detection
- **Smart Peg Patterns**: Three distinct layouts, with every gap between pegs wider than the ball so a ball cannot come to rest
  - **Hexagonal**: Organized grid pattern
  - **Triangle**: Pyramid arrangement
  - **Random**: Chaotic distribution (50 placement attempts per peg)
- **Special Peg Bonuses**: 2-4 highlighted pegs per level (50px spacing) trigger multi-ball bonuses (5 + level/2 balls)
- **Strategic Scoring**: Inverse probability distribution rewards skilled play
  - Edge slots: 2000 points (hardest to reach: narrow slots against the walls)
  - Center slot: 1000 points (medium difficulty)
  - Side slots: 50-200 points (easiest to reach)
- **Infinite Levels**: Pattern cycling with increasing difficulty

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK**: 3.38.1 or higher
- **Dart**: 3.10.0 or higher
- **Platform Tools**:
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
# Android (requires Android Studio and device/emulator)
flutter run -d android

# Web browser
flutter run -d web-server
```

### Building for Release

```bash
# Android APK (release mode)
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release
```

**Note**: A release build is signed with `android/key.properties`, which is not in the repository. `flutter build apk --profile` builds without it.

## 🎯 How to Play

### Basic Gameplay

1. **Launch a Ball**: Drag from the bottom-right corner to build launch power
   - **Power Meter**: Green (low) → Yellow (medium) → Red (high)
   - **Visual Feedback**: Launch path shows curve into peg field
2. **Watch Physics**: Ball travels up the channel, meets the dome and follows it for as far as its power carries it, then bounces through the pegs
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
- **Reward**: 5 bonus balls at level 1, one more for every two levels, and 15 at most (from level 20)
- **Reset**: Special pegs reset each level

## 🏗️ Project Structure

```
lib/
├── main.dart                    # App entry point with Provider setup
├── models/                      # Game objects
│   ├── ball.dart               # Ball physics and state
│   ├── ball_launcher.dart      # Launch channel mechanics
│   ├── peg.dart                # Peg collision and types
│   ├── slot.dart               # Scoring slots
│   ├── level.dart              # Level generation with patterns
│   └── game_state.dart         # Global state management
├── services/                    # Game logic
│   ├── physics_engine.dart     # 60 FPS physics simulation
│   └── game_manager.dart       # Main game loop coordination
├── screens/                     # UI screens
│   ├── game_screen.dart        # Main gameplay interface
│   └── menu_screen.dart        # Menu with level selection
├── widgets/                     # Custom rendering
│   ├── pachinko_board.dart     # Canvas-based game board
│   ├── board_effects.dart      # Bonus announcement and confetti
│   └── board_static_layer.dart # Felt, rail, pins and slots, drawn once per level
└── utils/                       # Configuration
    ├── constants.dart          # Game parameters and styling
    └── peg_patterns.dart       # Pattern generation algorithms
```

## 🧪 Development

### Running Tests

```bash
# Run all tests
flutter test --exclude-tags golden

# Run the golden image tests (baselines were generated on Linux)
flutter test --tags golden

# Run the integration tests (needs a running Android emulator or a device)
flutter test integration_test -d emulator-5554 --timeout 120s

# Run with coverage report
flutter test --coverage --exclude-tags golden
genhtml coverage/lcov.info -o coverage/html

# Coverage of the lines your branch changed (CI requires 85%)
uvx diff-cover coverage/lcov.info --compare-branch=origin/master --fail-under=85

# Open coverage report
open coverage/html/index.html
```

### Code Quality

```bash
# Analyze code for issues (anything it reports fails, info-level lints included; this is what CI runs)
flutter analyze

# Format code
dart format lib test integration_test tool test_driver

# Check for formatting issues (this is what CI runs; an unformatted file fails it)
dart format --output=none --set-exit-if-changed lib test integration_test tool test_driver

# Once per clone: make `git blame` skip the commit that formatted everything
git config blame.ignoreRevsFile .git-blame-ignore-revs
```

**Quality Gates** (enforced by CI):
- Zero `flutter analyze` issues
- 100% test pass rate
- Coverage of changed lines ≥ 85%

### Development Workflow

This project follows feature branch development:

1. Create feature branch: `git checkout -b feature/my-feature`
2. Implement changes with TDD approach
3. Ensure tests pass: `flutter test --exclude-tags golden`
4. Verify coverage: `flutter test --coverage --exclude-tags golden`
5. Commit with conventional commits: `git commit -m "feat: add feature"`
6. Push to remote: `git push origin feature/my-feature`
7. Create pull request for review

See [CLAUDE.md](./CLAUDE.md) for complete development standards.

## 📱 Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| ✅ Android | Configured | Release signing pending |
| ✅ Web | Supported | Used for demos in a browser |

The repository has no project files for other platforms. `flutter create --platforms=<name> .` adds one.

**Android Requirements**:
- Minimum SDK: 21 (Android 5.0 Lollipop)
- Target SDK: 34 (Android 14)
- Performance: 60 FPS on mid-range devices (2+ GB RAM)

## 📝 Documentation

- **[Development Guide](CLAUDE.md)** - AI-assisted development instructions

## 🤝 Contributing

Contributions are welcome! This project follows strict quality standards:

### Quality Requirements (from CLAUDE.md)

Before any PR is merged:

1. **Testing**:
   - All tests must pass (100% pass rate)
   - Minimum 85% code coverage on new code
   - Unit, widget, and integration tests as appropriate

2. **Git Workflow**:
   - Work on feature branches (never directly on `master`)
   - Use conventional commits: `feat:`, `fix:`, `docs:`, `test:`, etc.
   - All changes must be committed and pushed

3. **Documentation**:
   - Update inline code comments
   - Add dartdoc comments for public APIs
   - Update relevant markdown files (README.md, CLAUDE.md, etc.)

4. **Code Quality**:
   - Zero `flutter analyze` warnings
   - Code formatted with `dart format`
   - No TODO comments in final code

### Contribution Workflow

1. Fork the repository
2. Create feature branch: `git checkout -b feature/your-feature`
3. Make changes following quality standards
4. Run tests: `flutter test --coverage --exclude-tags golden`
5. Commit: `git commit -m "feat(scope): description"`
6. Push: `git push origin feature/your-feature`
7. Submit pull request with clear description

## 📄 License

This project is open source. Feel free to use and modify as needed.

## 🏆 Current Achievements

- ✅ **Playable Prototype**: Fully functional core gameplay
- ✅ **60 FPS Physics**: Advanced collision detection and ball dynamics
- ✅ **Authentic Mechanics**: Real pachinko launch channel with curve
- ✅ **Pattern Variety**: 3 distinct peg layouts with smart spacing

## 📞 Support & Feedback

- **Issues**: [GitHub Issues](https://github.com/frankbria/pachinko/issues)
- **Discussions**: [GitHub Discussions](https://github.com/frankbria/pachinko/discussions)
- **Pull Requests**: [GitHub PRs](https://github.com/frankbria/pachinko/pulls)

---

Built with ❤️ using Flutter
