# Golden Test Baselines

This directory contains golden file baselines for visual regression testing in the Pachinko game.

## What are Golden Files?

Golden files are reference images that serve as the "source of truth" for how UI components should render. Flutter's golden testing framework compares newly rendered widgets against these baseline images to detect unintended visual changes.

**Purpose:**
- Catch visual regressions automatically
- Ensure UI consistency across code changes
- Validate rendering behavior across different scenarios
- Document expected visual appearance

## Directory Structure

```
test/golden/
├── README.md                    # This file
├── game_screen/                 # Game screen rendering tests
│   ├── initial_state.png       # Board at game start
│   ├── ball_in_flight.png      # Ball physics rendering
│   └── special_peg_active.png  # Special peg highlight state
├── menu_screen/                 # Menu screen tests
│   ├── default_view.png        # Initial menu appearance
│   └── level_selection.png     # Level select state
├── widgets/                     # Individual widget tests
│   ├── pachinko_board/
│   │   ├── hexagonal_pattern.png
│   │   ├── triangle_pattern.png
│   │   └── random_pattern.png
│   └── power_meter/
│       ├── empty.png
│       ├── half_charged.png
│       └── full_charged.png
└── integration/                 # Full game flow tests
    ├── level_complete.png
    └── game_over.png
```

## Generating Golden Files

### Initial Generation

When creating a new golden test, generate the baseline image:

```bash
flutter test --update-goldens
```

This command runs all tests and saves rendered images as baselines.

### Updating Specific Tests

To update only specific golden files:

```bash
flutter test --update-goldens test/widget/specific_test.dart
```

### Verifying Golden Files

After generation, always manually review the golden files to ensure they represent the correct visual state:

1. Check image clarity and completeness
2. Verify colors, spacing, and alignment
3. Confirm no rendering artifacts
4. Validate against design specifications

## When to Update Golden Files

**UPDATE golden files when:**
- ✅ Intentional UI design changes (colors, spacing, layouts)
- ✅ Adding new visual features or components
- ✅ Fixing rendering bugs (after verifying the fix is correct)
- ✅ Updating to a new Flutter version that changes rendering behavior

**DO NOT update golden files when:**
- ❌ Tests fail due to unintended visual regressions
- ❌ Trying to make failing tests pass without understanding why
- ❌ Changes are still under review or experimental
- ❌ Visual differences are unexpected or unexplained

## Platform-Specific Considerations

**IMPORTANT:** Golden files are platform-specific due to rendering differences.

### Platform Variations

Different operating systems render fonts, anti-aliasing, and graphics differently:

- **Linux:** Primary development platform for this project
- **macOS:** May have font rendering differences
- **Windows:** Different font hinting and pixel scaling
- **CI/CD:** Should match the platform where tests run

### Best Practices

1. **Consistent Test Environment:**
   - Generate golden files on the same platform where CI runs
   - Document which platform baselines are for (see below)
   - Use Docker or VM for reproducible rendering

2. **Platform Directories (if needed):**
   ```
   test/golden/
   ├── linux/          # Linux-specific baselines
   ├── macos/          # macOS-specific baselines
   └── windows/        # Windows-specific baselines
   ```

3. **Current Platform:**
   - **Baseline Platform:** Linux (WSL2)
   - **Flutter Version:** 3.24.5
   - **Dart Version:** 3.5.4
   - All golden files in this directory are generated on Linux

## Testing Workflow

### 1. Write Widget Test with Golden Assertion

```dart
testWidgets('game board renders correctly', (tester) async {
  await tester.pumpWidget(MyApp());

  await expectLater(
    find.byType(PachinkoBoard),
    matchesGoldenFile('golden/game_screen/initial_state.png'),
  );
});
```

### 2. Generate Initial Baseline

```bash
flutter test --update-goldens test/widget/game_board_test.dart
```

### 3. Verify Baseline Image

Open `test/golden/game_screen/initial_state.png` and verify it looks correct.

### 4. Run Tests Normally

```bash
flutter test
```

Tests will fail if rendering deviates from the golden file.

### 5. Handle Test Failures

If a golden test fails:

1. **Investigate:** Understand why the rendering changed
2. **Decide:** Is this an intended change or a regression?
3. **Update (if intended):** Re-run with `--update-goldens`
4. **Fix (if regression):** Correct the code causing the visual bug

## Golden Test Best Practices

### Size and Scope
- Keep golden files focused on specific components
- Use smaller widgets for faster test execution
- Test edge cases (empty, full, error states)

### Stability
- Avoid time-dependent rendering (animations mid-frame)
- Use deterministic random seeds for random patterns
- Pump frames to stable state before comparison

### Performance
- Golden tests are slower than unit tests
- Run selectively during development
- Include in CI pipeline for comprehensive validation

### Maintenance
- Review golden files during code reviews
- Update baselines when design system changes
- Delete obsolete golden files when removing features

## Troubleshooting

### Test Fails on Different Machine
- Verify Flutter and Dart versions match
- Check platform-specific rendering differences
- Consider using platform-specific golden directories

### Golden File Looks Corrupted
- Re-generate with `--update-goldens`
- Check for rendering errors in test setup
- Verify widget tree is fully built before comparison

### Differences Too Sensitive
- Use threshold tolerance for minor pixel differences
- Consider using `matchesGoldenFile` with custom comparator
- Focus on significant visual changes, not sub-pixel variations

## Resources

- [Flutter Golden Testing Guide](https://docs.flutter.dev/cookbook/testing/widget/golden-files)
- [Package: golden_toolkit](https://pub.dev/packages/golden_toolkit) - Enhanced golden testing utilities
- [CI/CD Golden Testing](https://flutter.dev/docs/testing/overview#golden-file-testing)

---

**Last Updated:** 2025-10-18
**Platform:** Linux (WSL2)
**Flutter Version:** 3.24.5
