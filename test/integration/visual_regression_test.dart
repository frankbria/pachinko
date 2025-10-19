import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

import 'package:pachinko_game/models/ball.dart';
import 'package:pachinko_game/models/peg.dart';
import 'package:pachinko_game/models/level.dart';
import 'package:pachinko_game/services/game_manager.dart';
import 'package:pachinko_game/widgets/pachinko_board.dart';
import 'package:pachinko_game/utils/constants.dart';

/// Visual Regression Test Suite for Graphics Overhaul
///
/// This test suite validates all visual elements and rendering behavior
/// using Flutter's golden file testing framework.
///
/// ## Updating Golden Files
///
/// When visual changes are intentional (design updates, new features):
/// ```bash
/// flutter test --update-goldens test/integration/visual_regression_test.dart
/// ```
///
/// After updating, manually review golden files in test/golden/integration/
/// to ensure they represent the correct visual state.
///
/// ## Platform Considerations
///
/// Golden files are platform-specific. These tests are designed for:
/// - Platform: Linux (WSL2)
/// - Flutter Version: 3.24.5
/// - Dart Version: 3.5.4
///
/// Running on different platforms may produce pixel-perfect differences.
///
/// ## Test Coverage
///
/// This suite validates:
/// - Anti-aliasing on all game elements (AC4.1, FR-001, FR-011)
/// - Particle trail rendering (AC1.2, FR-002)
/// - Collision burst effects (AC1.3, FR-003)
/// - Peg glow animations (AC2.1, FR-004)
/// - Visual consistency across game states
///
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Visual Regression Tests - Graphics Overhaul', () {

    // Test AC4.1, FR-001: Anti-aliasing verification
    testWidgets('game board renders with anti-aliasing', (tester) async {
      final gameManager = await _setupTestGame(tester, levelNumber: 1);

      // Allow initial render to complete
      await tester.pumpAndSettle();

      // Verify anti-aliasing is applied to the entire board
      // Golden file should show smooth edges on all elements
      await expectLater(
        find.byType(PachinkoBoard),
        matchesGoldenFile('golden/integration/anti_aliasing_verification.png'),
      );

      _teardownTest(gameManager);
    });

    // Test AC1.2, FR-002: Particle trail rendering
    testWidgets('particle trail follows ball in flight', (tester) async {
      final gameManager = await _setupTestGame(tester, levelNumber: 1);

      // Create a ball in mid-flight position
      final testBall = Ball(
        position: vm.Vector2(200, 300),
        velocity: vm.Vector2(50, 100),
        color: GameConstants.ballColor,
      );
      gameManager.gameState.launchBall(testBall);

      // Simulate several frames to generate particle trail
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      // Wait for trail particles to be visible
      await tester.pump(const Duration(milliseconds: 100));

      // Verify particle trail is visible and smooth
      // Golden file should show particles trailing behind the ball
      await expectLater(
        find.byType(PachinkoBoard),
        matchesGoldenFile('golden/integration/particle_trail_rendering.png'),
      );

      _teardownTest(gameManager);
    });

    // Test AC1.3, FR-003: Collision burst effect
    testWidgets('collision burst effect renders on peg impact', (tester) async {
      final gameManager = await _setupTestGame(tester, levelNumber: 1);

      // Create a ball positioned to collide with a peg
      final level = gameManager.gameState.currentLevel!;
      final targetPeg = level.pegs.first;

      final testBall = Ball(
        position: vm.Vector2(
          targetPeg.position.x - 5, // Position very close to peg
          targetPeg.position.y - 5,
        ),
        velocity: vm.Vector2(100, 100),
        color: GameConstants.ballColor,
      );
      gameManager.gameState.launchBall(testBall);

      // Update physics to trigger collision
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));

      // Wait for burst particles to appear
      await tester.pump(const Duration(milliseconds: 50));

      // Verify collision burst effect is visible
      // Golden file should show particle burst at collision point
      await expectLater(
        find.byType(PachinkoBoard),
        matchesGoldenFile('golden/integration/collision_burst_effect.png'),
      );

      _teardownTest(gameManager);
    });

    // Test AC2.1, FR-004: Peg glow animation
    testWidgets('special peg glow animation renders correctly', (tester) async {
      final gameManager = await _setupTestGame(tester, levelNumber: 1);

      // Ensure special pegs are visible and glowing
      await tester.pumpAndSettle();

      // Verify special pegs have visible glow effect
      // Golden file should show special pegs with pulsing glow
      await expectLater(
        find.byType(PachinkoBoard),
        matchesGoldenFile('golden/integration/peg_glow_animation.png'),
      );

      _teardownTest(gameManager);
    });

    // Test FR-005: Enhanced special peg collision effect
    testWidgets('special peg collision has enhanced particle effect', (tester) async {
      final gameManager = await _setupTestGame(tester, levelNumber: 1);

      // Find a special peg
      final level = gameManager.gameState.currentLevel!;
      final specialPeg = level.pegs.firstWhere(
        (peg) => peg.type == PegType.special,
        orElse: () => level.pegs.first,
      );

      // Create ball to collide with special peg
      final testBall = Ball(
        position: vm.Vector2(
          specialPeg.position.x - 8,
          specialPeg.position.y - 8,
        ),
        velocity: vm.Vector2(150, 150),
        color: GameConstants.ballColor,
      );
      gameManager.gameState.launchBall(testBall);

      // Update to trigger collision
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 50));

      // Verify enhanced particle effect for special peg
      // Golden file should show more intense particle burst
      await expectLater(
        find.byType(PachinkoBoard),
        matchesGoldenFile('golden/integration/special_peg_collision.png'),
      );

      _teardownTest(gameManager);
    });

    // Test FR-006: Special bonus screen effect
    testWidgets('special bonus triggers screen-wide visual effect', (tester) async {
      final gameManager = await _setupTestGame(tester, levelNumber: 1);

      // Manually trigger special bonus
      gameManager.gameState.triggerSpecialBonus();

      // Allow bonus effect to render
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 100));

      // Verify screen-wide bonus effect is visible
      // Golden file should show full-screen bonus indicator
      await expectLater(
        find.byType(PachinkoBoard),
        matchesGoldenFile('golden/integration/special_bonus_effect.png'),
      );

      _teardownTest(gameManager);
    });

    // Test hexagonal pattern rendering (from spec.md peg patterns)
    testWidgets('hexagonal peg pattern renders with anti-aliasing', (tester) async {
      final gameManager = await _setupTestGame(tester, levelNumber: 1);

      await tester.pumpAndSettle();

      // Verify hexagonal pattern is clear and anti-aliased
      await expectLater(
        find.byType(PachinkoBoard),
        matchesGoldenFile('golden/integration/hexagonal_pattern.png'),
      );

      _teardownTest(gameManager);
    });

    // Test triangle pattern rendering
    testWidgets('triangle peg pattern renders with anti-aliasing', (tester) async {
      final gameManager = await _setupTestGame(tester, levelNumber: 2);

      await tester.pumpAndSettle();

      // Verify triangle pattern is clear and anti-aliased
      await expectLater(
        find.byType(PachinkoBoard),
        matchesGoldenFile('golden/integration/triangle_pattern.png'),
      );

      _teardownTest(gameManager);
    });

    // Test random pattern rendering
    testWidgets('random peg pattern renders with anti-aliasing', (tester) async {
      final gameManager = await _setupTestGame(tester, levelNumber: 3);

      await tester.pumpAndSettle();

      // Verify random pattern is clear and anti-aliased
      await expectLater(
        find.byType(PachinkoBoard),
        matchesGoldenFile('golden/integration/random_pattern.png'),
      );

      _teardownTest(gameManager);
    });

    // Test multiple balls with particle trails
    testWidgets('multiple balls render with distinct particle trails', (tester) async {
      final gameManager = await _setupTestGame(tester, levelNumber: 1);

      // Launch multiple balls at different positions
      final ball1 = Ball(
        position: vm.Vector2(150, 200),
        velocity: vm.Vector2(30, 80),
        color: GameConstants.ballColor,
      );
      final ball2 = Ball(
        position: vm.Vector2(250, 250),
        velocity: vm.Vector2(-30, 80),
        color: GameConstants.ballColor,
      );
      final ball3 = Ball(
        position: vm.Vector2(200, 180),
        velocity: vm.Vector2(0, 100),
        color: GameConstants.bonusBallColor,
      );

      gameManager.gameState.launchBall(ball1);
      gameManager.gameState.launchBall(ball2);
      gameManager.gameState.launchBall(ball3);

      // Generate particle trails
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      await tester.pump(const Duration(milliseconds: 100));

      // Verify all balls have visible, non-overlapping trails
      await expectLater(
        find.byType(PachinkoBoard),
        matchesGoldenFile('golden/integration/multiple_ball_trails.png'),
      );

      _teardownTest(gameManager);
    });

    // Test power meter rendering (FR-007)
    testWidgets('power meter renders with color gradient', (tester) async {
      final gameManager = await _setupTestGame(tester, levelNumber: 1);

      // Simulate charging power meter to 50%
      gameManager.startLaunchCharging();
      gameManager.updateLaunchPower(50.0);

      await tester.pump(const Duration(milliseconds: 16));
      await tester.pumpAndSettle();

      // Verify power meter shows correct color gradient
      // Golden file should show green-to-yellow gradient at 50%
      await expectLater(
        find.byType(PachinkoBoard),
        matchesGoldenFile('golden/integration/power_meter_gradient.png'),
      );

      _teardownTest(gameManager);
    });

    // Test rendering quality on different viewport sizes
    testWidgets('board scales correctly to different viewport sizes', (tester) async {
      // Test at a non-standard viewport size
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final gameManager = await _setupTestGame(tester, levelNumber: 1);

      await tester.pumpAndSettle();

      // Verify board scales and maintains quality
      await expectLater(
        find.byType(PachinkoBoard),
        matchesGoldenFile('golden/integration/scaled_viewport.png'),
      );

      _teardownTest(gameManager);
    });
  });
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Creates and sets up a test game environment with a PachinkoBoard widget
///
/// Returns the GameManager instance for test manipulation.
///
/// Usage:
/// ```dart
/// final gameManager = await _setupTestGame(tester, levelNumber: 1);
/// // Perform test actions...
/// _teardownTest(gameManager);
/// ```
Future<GameManager> _setupTestGame(
  WidgetTester tester, {
  required int levelNumber,
}) async {
  final gameManager = GameManager();
  gameManager.selectLevel(levelNumber);

  // Create test widget tree with Provider
  await tester.pumpWidget(
    MaterialApp(
      home: ChangeNotifierProvider<GameManager>.value(
        value: gameManager,
        child: Scaffold(
          body: Container(
            width: 400,
            height: 600,
            color: GameConstants.boardColor,
            child: const PachinkoBoard(),
          ),
        ),
      ),
    ),
  );

  // Allow initial frame to render
  await tester.pump();

  return gameManager;
}

/// Cleans up test resources after test completion
///
/// Disposes the GameManager to prevent memory leaks in tests.
void _teardownTest(GameManager gameManager) {
  gameManager.dispose();
}

/// Creates a test widget wrapper for standalone component testing
///
/// Useful for testing individual rendering components without full game setup.
Widget _createTestWrapper({required Widget child}) {
  return MaterialApp(
    home: Scaffold(
      body: Container(
        width: 400,
        height: 600,
        color: GameConstants.boardColor,
        child: child,
      ),
    ),
  );
}

/// Simulates game time progression for animation testing
///
/// Pumps multiple frames to allow animations to progress.
Future<void> _simulateGameTime(
  WidgetTester tester, {
  required Duration duration,
  Duration frameInterval = const Duration(milliseconds: 16),
}) async {
  final frames = duration.inMilliseconds ~/ frameInterval.inMilliseconds;

  for (int i = 0; i < frames; i++) {
    await tester.pump(frameInterval);
  }
}

/// Verifies a specific particle system is active and rendering
///
/// Helper for particle effect tests to ensure particles are visible.
bool _hasActiveParticles(GameManager gameManager) {
  return gameManager.particleSystem.getAllActiveParticles().isNotEmpty;
}

/// Creates a deterministic ball configuration for consistent testing
///
/// Uses fixed positions and velocities to ensure reproducible test results.
Ball _createTestBall({
  required double x,
  required double y,
  double vx = 0,
  double vy = 0,
  Color? color,
}) {
  return Ball(
    position: vm.Vector2(x, y),
    velocity: vm.Vector2(vx, vy),
    color: color ?? GameConstants.ballColor,
  );
}
