# Integration Test Suite

This directory contains integration tests for the Pachinko game, focusing on end-to-end validation of features and user experiences.

## Visual Regression Tests

**File**: `visual_regression_test.dart`

Comprehensive visual regression test suite for the Graphics Architecture Overhaul (Feature 002).

### Test Coverage

The suite validates 12 distinct visual scenarios:

1. **Anti-aliasing verification** - Validates smooth rendering across all game elements
2. **Particle trail rendering** - Verifies ball motion trails are visible and smooth
3. **Collision burst effects** - Checks particle bursts appear on peg collisions
4. **Peg glow animations** - Validates special peg pulsing glow effects
5. **Special peg collision effects** - Verifies enhanced particles for special pegs
6. **Special bonus screen effects** - Checks full-screen bonus activation visuals
7. **Hexagonal peg pattern** - Validates organized hexagonal peg layouts
8. **Triangle peg pattern** - Validates organized triangle peg layouts
9. **Random peg pattern** - Validates random peg distribution quality
10. **Multiple ball trails** - Verifies distinct trails for concurrent balls
11. **Power meter gradient** - Validates smooth color transitions in power meter
12. **Scaled viewport** - Checks rendering quality across different screen sizes

### Running Visual Regression Tests

#### First-Time Setup (Generate Golden Files)

```bash
# Generate initial golden file baselines
flutter test --update-goldens test/integration/visual_regression_test.dart
```

This will create golden files in `test/golden/integration/` directory.

**IMPORTANT**: After generating golden files, manually inspect each one to ensure it represents the correct visual state:

```bash
# View golden files
ls -lh test/golden/integration/
# Open with image viewer to verify quality
```

#### Normal Test Execution

```bash
# Run all visual regression tests
flutter test test/integration/visual_regression_test.dart

# Run specific test
flutter test test/integration/visual_regression_test.dart --plain-name "particle trail"
```

#### Updating Golden Files After Changes

When you intentionally change visual elements:

```bash
# Update all golden files
flutter test --update-goldens test/integration/visual_regression_test.dart

# Update specific test
flutter test --update-goldens test/integration/visual_regression_test.dart --plain-name "particle trail"
```

### Test Results Interpretation

**All tests passing**: Visual output matches golden files perfectly
**Tests failing**: Visual differences detected - investigate before updating goldens

```
✅ PASS → Visual output matches baseline (expected behavior)
❌ FAIL → Visual regression detected (investigate root cause)
```

### Platform Considerations

Golden files are platform-specific due to rendering differences:

- **Generated on**: Linux (WSL2)
- **Flutter**: 3.24.5
- **Dart**: 3.5.4

Running tests on different platforms may produce pixel-perfect differences. For CI/CD, ensure tests run on the same platform where golden files were generated.

### Test Helper Functions

The test suite includes reusable helper functions:

- `_setupTestGame()` - Creates test game environment with Provider setup
- `_teardownTest()` - Cleans up resources after tests
- `_createTestWrapper()` - Wraps widgets for standalone testing
- `_simulateGameTime()` - Advances time for animation testing
- `_hasActiveParticles()` - Verifies particle system is active
- `_createTestBall()` - Creates deterministic ball configurations

### Troubleshooting

#### Test fails with "Could not be compared against non-existent file"

**Cause**: Golden files haven't been generated yet.

**Solution**:
```bash
flutter test --update-goldens test/integration/visual_regression_test.dart
```

#### Test fails with "rasterized image does not match golden file"

**Cause**: Intentional or unintentional visual changes.

**Solution**:
1. Review the diff to understand what changed
2. If intended: Re-generate goldens with `--update-goldens`
3. If unintended: Fix the code causing the visual regression

#### Tests pass locally but fail in CI

**Cause**: Platform rendering differences or Flutter version mismatch.

**Solution**:
1. Verify Flutter/Dart versions match CI environment
2. Consider platform-specific golden directories
3. Use Docker for reproducible test environments

### Best Practices

1. **Generate golden files once** - After implementing visual features
2. **Review before committing** - Inspect golden files manually before git commit
3. **Update intentionally** - Only regenerate when visual changes are desired
4. **Document changes** - Explain why golden files were updated in commit messages
5. **Test on target platform** - Generate goldens on the same platform as CI/CD

### Related Documentation

- [Golden Test Guidelines](../golden/README.md) - Detailed golden testing methodology
- [Spec 002](../../specs/002-graphics-overhaul/spec.md) - Graphics overhaul requirements
- [Tasks 002](../../specs/002-graphics-overhaul/tasks.md) - Implementation task breakdown

### Test Maintenance

When adding new visual features:

1. Add new test case to `visual_regression_test.dart`
2. Generate golden file with `--update-goldens`
3. Manually verify golden file quality
4. Commit both test code and golden file
5. Update this README with new test description

When removing features:

1. Remove test case from `visual_regression_test.dart`
2. Delete corresponding golden file
3. Update this README
