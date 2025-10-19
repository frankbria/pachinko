# Development Guide

This document explains the feature branch development workflow used in this project.

## Branch Strategy

### `master` Branch
- **Purpose**: Stable, playable releases
- **Status**: v0.1.0 - Fully functional Pachinko prototype
- **Protection**: Direct commits discouraged - use feature branches

### Feature Branches
Active development happens in feature branches that get merged to master when complete.

#### Current: `002-graphics-overhaul`
**Progress**: 65% complete
**Goal**: Transform basic prototype into production-quality graphics system

**What's Complete**:
- ✅ Phase 1-2: Infrastructure (particle system, performance monitoring)
- ✅ Phase 3-4: Foundation (rendering layers, game integration)
- ✅ Phase 5: Glow Animations (pulsing special pegs, enhanced particles)
- Status: 303 tests passing, 98.45% graphics coverage

**What's Next**:
- 🔄 Phase 6: UI Polish (transitions, animations, anti-aliasing)
- 🔄 Phase 7: Performance (optimization, degradation testing)
- 🔄 Phase 8: Documentation (cleanup, final testing)

## Quality Standards

Before merging any feature branch to master, ALL requirements must be met:

### Testing Requirements
- ✅ **100% test pass rate** - Zero failing tests
- ✅ **85% minimum code coverage** - For all new code
- ✅ **Test types**:
  - Unit tests for business logic
  - Widget tests for UI components
  - Integration tests for game flows
  - Visual regression tests (golden files)

### Documentation Requirements
- ✅ **Code documentation** - Doc comments for public APIs
- ✅ **Implementation docs** - Update CLAUDE.md with changes
- ✅ **README updates** - Keep feature lists current
- ✅ **Breaking changes** - Document prominently

### Git Workflow Requirements
- ✅ **Conventional commits** - Format: `feat:`, `fix:`, `docs:`, `test:`, `refactor:`
- ✅ **Descriptive messages** - Explain WHAT changed and WHY
- ✅ **All changes committed** - No uncommitted work
- ✅ **All commits pushed** - Backup and enable collaboration

## Development Workflow

### Starting a New Feature

```bash
# Create feature branch from master
git checkout master
git pull origin master
git checkout -b 003-feature-name

# Make changes...
# Run tests...
# Commit regularly...
```

### During Development

```bash
# Run tests before committing
flutter test

# Check code coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Commit with conventional format
git add .
git commit -m "feat(module): description of change

Detailed explanation of what changed and why.

- Bullet point details
- Test results
- Breaking changes if any"

# Push regularly
git push origin 003-feature-name
```

### Completing a Feature

**Checklist before merging to master**:
- [ ] All tests passing (`flutter test`)
- [ ] Code coverage ≥85% for new code
- [ ] Code formatted (`flutter format`)
- [ ] Code analyzed (`flutter analyze`)
- [ ] Documentation updated (CLAUDE.md, README.md)
- [ ] All changes committed with conventional commits
- [ ] All commits pushed to remote
- [ ] Manual testing on target platforms

```bash
# Final verification
flutter test
flutter analyze
flutter format --set-exit-if-changed

# Merge to master
git checkout master
git merge 003-feature-name
git push origin master

# Tag release if appropriate
git tag -a v0.2.0 -m "Graphics overhaul complete"
git push origin v0.2.0
```

## Viewing Feature Progress

### See What's in a Feature Branch

```bash
# List all branches
git branch -a

# Checkout a feature branch
git checkout 002-graphics-overhaul

# See commits in feature branch
git log master..002-graphics-overhaul --oneline

# See diff from master
git diff master...002-graphics-overhaul
```

### Run the Latest Features

```bash
# Clone repository
git clone https://github.com/frankbria/pachinko.git
cd pachinko

# Switch to feature branch
git checkout 002-graphics-overhaul

# Add Flutter to PATH
export PATH="$(pwd)/tools/flutter/bin:$PATH"

# Run the game
flutter run
```

## Code Style

### Dart/Flutter Conventions
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Use `flutter format` before committing
- Fix all `flutter analyze` warnings

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types**: `feat`, `fix`, `docs`, `test`, `refactor`, `style`, `perf`, `chore`

**Examples**:
```
feat(graphics): implement particle system with trail effects

- Created ParticleSystem class with object pooling
- Added trail particles on ball movement (velocity > 50)
- Collision bursts with 8 particles per peg hit
- Test coverage: 100% (68/68 lines)

Closes #42
```

```
fix(physics): correct ball launch trajectory

Ball was falling straight down instead of arcing into peg field.
Fixed release velocity to include upward and leftward components.

- Leftward: -200 px/s
- Upward: -150 to -350 px/s (power-dependent)
```

## Testing Strategy

### Test Organization
```
test/
├── unit/           # Business logic tests (229 passing)
├── widget/         # UI component tests (24 passing)
└── integration/    # End-to-end + visual regression (50 passing)
```

### Running Tests

```bash
# All tests
flutter test

# Specific test file
flutter test test/unit/particle_system_test.dart

# With coverage
flutter test --coverage

# Update golden files (visual regression)
flutter test --update-goldens

# Watch mode (rerun on changes)
flutter test --watch
```

### Writing Tests

Follow **TDD (Test-Driven Development)**:
1. **RED**: Write failing test
2. **GREEN**: Implement minimum code to pass
3. **REFACTOR**: Improve code quality

Example:
```dart
// 1. RED - Write test first
test('particle fades out in last 30% of lifetime', () {
  final particle = Particle(/* ... */);
  particle.age = particle.lifetime * 0.8; // 80% through
  particle.update(0.1);
  expect(particle.opacity, lessThan(1.0)); // Should be fading
});

// 2. GREEN - Implement feature
void update(double deltaTime) {
  if (age > lifetime * 0.7) {
    opacity = 1.0 - (age - lifetime * 0.7) / (lifetime * 0.3);
  }
}

// 3. REFACTOR - Improve code
```

## Architecture Overview

### Project Structure
```
lib/
├── models/              # Game entities
│   ├── ball.dart
│   ├── peg.dart
│   └── particle.dart
├── services/            # Game logic
│   ├── game_manager.dart
│   ├── physics_engine.dart
│   └── graphics/       # Graphics subsystems
│       ├── particle_system.dart
│       ├── performance_monitor.dart
│       ├── animation_controller.dart
│       └── rendering_layer.dart
├── screens/             # UI screens
├── widgets/             # Custom widgets
└── utils/               # Constants, helpers
```

### Key Design Patterns
- **Provider Pattern**: State management (GameManager)
- **Object Pooling**: Particle reuse (100 trail, 50 collision)
- **Custom Painting**: Canvas-based rendering (60 FPS)
- **Separation of Concerns**: Models, Services, UI

## Troubleshooting

### Common Issues

**Tests failing after changes**:
```bash
# Check which tests are failing
flutter test --reporter expanded

# Update golden files if visual changes are intentional
flutter test --update-goldens test/integration/visual_regression_test.dart
```

**Coverage not meeting 85%**:
```bash
# Generate detailed coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
# Open coverage/html/index.html in browser
```

**Merge conflicts**:
```bash
# Update your branch with latest master
git checkout 003-feature-name
git fetch origin
git merge origin/master
# Resolve conflicts...
git add .
git commit
```

## Release Process

### Version Numbering
- **v0.x.x**: Pre-1.0 development
- **v1.x.x**: Production releases
- Format: `MAJOR.MINOR.PATCH`

### Creating a Release
1. Complete feature branch
2. Pass all quality gates
3. Merge to master
4. Tag with version
5. Update CHANGELOG.md
6. Build release artifacts
7. Deploy (when ready)

## Contact

Questions about the development process? Open an issue or check existing documentation:
- [README.md](./README.md) - Project overview
- [CLAUDE.md](./CLAUDE.md) - Detailed implementation docs
- [TODO.md](./TODO.md) - Known issues and future work

