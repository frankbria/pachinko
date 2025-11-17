# Task 1.13 - Integration Test Plan

## Integration Test Structure

### Directory Organization
```
integration_test/
├── app_test.dart          # Basic app launch and navigation (2 groups, ~5 tests)
└── game_flow_test.dart    # Complete gameplay flows (7 groups, ~15 tests)
```

### Test Groups Planned

#### app_test.dart (Basic App Functionality)
1. **App Launch Tests** (~2 tests)
   - App launches without errors
   - MenuScreen displays correctly with title and buttons

2. **Navigation Tests** (~3 tests)
   - Navigation to GameScreen works (tap play button)
   - Back navigation from GameScreen to MenuScreen
   - Level select dialog opens and allows level selection

#### game_flow_test.dart (Complete Game Flows)
3. **Complete Game Flow Tests** (~2 tests)
   - Menu → play → launch balls → score points → level complete → next level
   - Full gameplay loop validation

4. **Ball Physics Tests** (~2 tests)
   - Ball launching mechanics (drag, power calculation, release)
   - Physics simulation over time (ball movement, gravity, collisions)

5. **Scoring System Tests** (~2 tests)
   - Ball lands in slot, score increases correctly
   - Different slot values scored appropriately

6. **Special Bonus Tests** (~2 tests)
   - Hit all special pegs triggers bonus (5 + level/2 balls added)
   - Bonus balls spawn correctly

7. **Level Progression Tests** (~3 tests)
   - Complete level 1, tap next level, verify level 2 loads
   - Levels 1-5 have different peg patterns (hexagonal, triangle, random)
   - Level number increments correctly

8. **Game Over Tests** (~2 tests)
   - Launch all 20 balls, verify game over state
   - No balls remaining, game over displayed

9. **State Preservation Tests** (~2 tests)
   - Navigate to game, launch balls, back to menu, return to game → state preserved
   - Score, balls remaining, level preserved across navigation

**Total Estimated Tests**: ~20 integration tests

## Key Integration Test Patterns

### 1. Real Dependencies (No Mocks)
```dart
// Integration tests use real app with Provider setup
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('givenAppLaunched_whenMenuDisplays_thenTitleAndButtonsPresent',
    (WidgetTester tester) async {
    // Launch real app
    app.main();
    await tester.pumpAndSettle();

    // Verify real widgets
    expect(find.text(GameStrings.appName), findsOneWidget);
  });
}
```

### 2. Async Timing for Physics Simulation
```dart
// Use pump with duration for physics simulation
await tester.pump(const Duration(milliseconds: 100)); // Single frame
await tester.pump(const Duration(seconds: 1));        // 1 second of simulation
await tester.pumpAndSettle();                         // Wait for all animations
```

### 3. Given-When-Then Naming
```dart
testWidgets('givenGameScreenActive_whenUserLaunchesBall_thenBallMovesAndScores',
  (WidgetTester tester) async {
  // Given: Navigate to game screen
  // When: Launch ball
  // Then: Verify ball moves and score updates
});
```

### 4. State Verification Over Time
```dart
// Verify state changes over multiple frames
final initialScore = gameManager.gameState.score;
await tester.pump(const Duration(seconds: 2)); // Simulate 2 seconds
final finalScore = gameManager.gameState.score;
expect(finalScore, greaterThan(initialScore));
```

## Timing Requirements

- **Target Execution Time**: < 2 minutes for all integration tests
- **Strategy**:
  - Use minimal physics simulation time (1-2 seconds per test)
  - Avoid unnecessary pumpAndSettle() calls
  - Focus on key state transitions
  - Use tearDown to reset state between tests

## Coverage Contribution

Integration tests contribute to overall coverage but primary goal is end-to-end validation:
- Unit tests: 85%+ per file
- Widget tests: 85%+ per file
- Integration tests: Validate real component interaction
- **Combined Phase 1 Coverage Goal**: ≥85% overall

## Real vs. Mock Dependencies

### Real (Integration Tests)
- GameManager (real state management)
- PhysicsEngine (actual ball physics)
- GameState (real game logic)
- BallLauncher (real launch mechanics)
- Provider (actual dependency injection)

### Mocked (Unit/Widget Tests)
- GameManager (MockGameManager)
- GameState (MockGameState)
- BallLauncher (MockBallLauncher)
- Focus on isolated component testing

## Comparison: Integration vs. Unit/Widget Tests

| Aspect | Unit/Widget Tests | Integration Tests |
|--------|-------------------|-------------------|
| **Scope** | Single component | Multiple components |
| **Dependencies** | Mocked | Real |
| **Execution Time** | Fast (< 5 seconds) | Slower (< 2 minutes) |
| **Test Count** | 333 tests | ~20 tests |
| **Coverage Focus** | Line coverage | End-to-end flows |
| **Naming** | Given-When-Then | Given-When-Then |
| **Purpose** | Verify logic correctness | Verify integration |

## Next Steps (Steps 2-5)

- **Step 2**: Write failing app launch/navigation tests in app_test.dart
- **Step 3**: Write failing game flow tests in game_flow_test.dart
- **Step 4**: Write failing game over/state preservation tests + timing validation
- **Step 5**: Run coverage analysis, verify all tests pass, commit and document
