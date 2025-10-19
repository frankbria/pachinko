import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

import 'package:pachinko_game/models/ball.dart';
import 'package:pachinko_game/models/peg.dart';
import 'package:pachinko_game/models/game_state.dart';
import 'package:pachinko_game/services/game_manager.dart';
import 'package:pachinko_game/widgets/pachinko_board.dart';
import 'package:pachinko_game/utils/constants.dart';

/// Widget Test Suite for PachinkoBoard Component
///
/// This test suite validates that PachinkoBoard renders correctly across
/// different game states without errors.
///
/// Test Coverage:
/// - Basic rendering without errors
/// - Rendering with no balls (empty state)
/// - Rendering with active balls
/// - Rendering with particle effects
/// - Rendering with special bonus state
/// - Golden file comparison for visual regression
///
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PachinkoBoard Widget Tests', () {

    test('PachinkoBoard can be instantiated', () {
      expect(() => const PachinkoBoard(), returnsNormally);
    });

    testWidgets('PachinkoBoard renders without errors', (tester) async {
      final gameManager = _createGameManager();
      gameManager.selectLevel(1);

      await tester.pumpWidget(_createTestApp(gameManager));

      // Verify widget is rendered
      expect(find.byType(PachinkoBoard), findsOneWidget);

      // Verify no errors thrown during initial render
      expect(tester.takeException(), isNull);

      gameManager.dispose();
    });

    testWidgets('PachinkoBoard renders with empty game state (no balls)', (tester) async {
      final gameManager = _createGameManager();
      gameManager.selectLevel(1);

      await tester.pumpWidget(_createTestApp(gameManager));
      await tester.pumpAndSettle();

      // Verify board renders without active balls
      expect(gameManager.gameState.activeBalls.isEmpty, isTrue);
      expect(find.byType(PachinkoBoard), findsOneWidget);
      expect(tester.takeException(), isNull);

      gameManager.dispose();
    });

    testWidgets('PachinkoBoard renders with active balls', (tester) async {
      final gameManager = _createGameManager();
      gameManager.selectLevel(1);

      await tester.pumpWidget(_createTestApp(gameManager));
      await tester.pump();

      // Add a ball to the game state
      final testBall = Ball(
        position: vm.Vector2(200, 100),
        velocity: vm.Vector2(50, 100),
        color: GameConstants.ballColor,
      );
      gameManager.gameState.launchBall(testBall);

      await tester.pump();

      // Verify board renders with active ball
      expect(gameManager.gameState.activeBalls.length, equals(1));
      expect(find.byType(PachinkoBoard), findsOneWidget);
      expect(tester.takeException(), isNull);

      gameManager.dispose();
    });

    testWidgets('PachinkoBoard renders with multiple active balls', (tester) async {
      final gameManager = _createGameManager();
      gameManager.selectLevel(1);

      await tester.pumpWidget(_createTestApp(gameManager));
      await tester.pump();

      // Add multiple balls directly to active balls list (bypassing launch logic)
      final ball1 = Ball(
        position: vm.Vector2(150, 100),
        velocity: vm.Vector2(30, 80),
        color: GameConstants.ballColor,
      );
      final ball2 = Ball(
        position: vm.Vector2(200, 130),
        velocity: vm.Vector2(40, 90),
        color: GameConstants.ballColor,
      );
      final ball3 = Ball(
        position: vm.Vector2(250, 160),
        velocity: vm.Vector2(50, 100),
        color: GameConstants.ballColor,
      );

      // Directly add balls to test rendering with multiple balls
      gameManager.gameState.launchBall(ball1);
      // Set phase back to ready to allow additional ball launches in test
      gameManager.gameState.updatePhase(GamePhase.ready);
      gameManager.gameState.launchBall(ball2);
      gameManager.gameState.updatePhase(GamePhase.ready);
      gameManager.gameState.launchBall(ball3);

      await tester.pump();

      // Verify board renders with multiple balls
      expect(gameManager.gameState.activeBalls.length, equals(3));
      expect(find.byType(PachinkoBoard), findsOneWidget);
      expect(tester.takeException(), isNull);

      gameManager.dispose();
    });

    testWidgets('PachinkoBoard renders with particle effects', (tester) async {
      final gameManager = _createGameManager();
      gameManager.selectLevel(1);

      await tester.pumpWidget(_createTestApp(gameManager));
      await tester.pump();

      // Add a ball with velocity to generate trail particles
      final testBall = Ball(
        position: vm.Vector2(200, 200),
        velocity: vm.Vector2(100, 150), // High velocity to trigger particles
        color: GameConstants.ballColor,
      );
      gameManager.gameState.launchBall(testBall);

      // Pump several frames to allow particle generation
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      // Verify rendering doesn't throw with particles
      expect(find.byType(PachinkoBoard), findsOneWidget);
      expect(tester.takeException(), isNull);

      gameManager.dispose();
    });

    testWidgets('PachinkoBoard renders with special bonus triggered', (tester) async {
      final gameManager = _createGameManager();
      gameManager.selectLevel(1);

      await tester.pumpWidget(_createTestApp(gameManager));
      await tester.pump();

      // Trigger special bonus
      gameManager.gameState.triggerSpecialBonus();

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify board renders with special bonus effect
      expect(gameManager.gameState.specialBonusTriggered, isTrue);
      expect(find.byType(PachinkoBoard), findsOneWidget);
      expect(tester.takeException(), isNull);

      gameManager.dispose();
    });

    testWidgets('PachinkoBoard renders with all peg types', (tester) async {
      final gameManager = _createGameManager();
      gameManager.selectLevel(1);

      await tester.pumpWidget(_createTestApp(gameManager));
      await tester.pumpAndSettle();

      final level = gameManager.gameState.currentLevel;
      expect(level, isNotNull);
      expect(level!.pegs.isNotEmpty, isTrue);

      // Verify both normal and special pegs exist
      final hasNormalPegs = level.pegs.any((peg) => peg.type == PegType.normal);
      final hasSpecialPegs = level.pegs.any((peg) => peg.type == PegType.special);

      expect(hasNormalPegs, isTrue);
      expect(hasSpecialPegs, isTrue);
      expect(find.byType(PachinkoBoard), findsOneWidget);
      expect(tester.takeException(), isNull);

      gameManager.dispose();
    });

    testWidgets('PachinkoBoard renders with launch channel visualization', (tester) async {
      final gameManager = _createGameManager();
      gameManager.selectLevel(1);

      await tester.pumpWidget(_createTestApp(gameManager));
      await tester.pumpAndSettle();

      // Verify board renders with launch channel
      expect(find.byType(PachinkoBoard), findsOneWidget);
      expect(tester.takeException(), isNull);

      gameManager.dispose();
    });

    testWidgets('PachinkoBoard handles drag interaction without errors', (tester) async {
      final gameManager = _createGameManager();
      gameManager.selectLevel(1);

      await tester.pumpWidget(_createTestApp(gameManager));
      await tester.pumpAndSettle();

      // Simulate drag gesture in launch area
      final launchAreaCenter = Offset(
        GameConstants.launchChannelStartX + GameConstants.launchChannelWidth / 2,
        GameConstants.launchChannelStartY - 10,
      );

      await tester.drag(find.byType(PachinkoBoard), const Offset(0, -100));
      await tester.pump();

      // Verify no errors during drag interaction
      expect(tester.takeException(), isNull);

      gameManager.dispose();
    });

    testWidgets('PachinkoBoard renders different levels without errors', (tester) async {
      for (int levelNum = 1; levelNum <= 3; levelNum++) {
        final gameManager = _createGameManager();
        gameManager.selectLevel(levelNum);

        await tester.pumpWidget(_createTestApp(gameManager));
        await tester.pumpAndSettle();

        // Verify each level renders successfully
        expect(find.byType(PachinkoBoard), findsOneWidget);
        expect(gameManager.gameState.currentLevel, isNotNull);
        expect(tester.takeException(), isNull);

        gameManager.dispose();
      }
    });

    testWidgets('PachinkoBoard renders with power meter indicator', (tester) async {
      final gameManager = _createGameManager();
      gameManager.selectLevel(1);

      await tester.pumpWidget(_createTestApp(gameManager));
      await tester.pump();

      // Start charging and update power
      gameManager.startLaunchCharging();
      gameManager.updateLaunchPower(50.0);

      await tester.pump();
      await tester.pumpAndSettle();

      // Verify rendering with power meter
      expect(find.byType(PachinkoBoard), findsOneWidget);
      expect(tester.takeException(), isNull);

      gameManager.dispose();
    });

    // Note: Golden file tests require golden files to be generated first.
    // Run: flutter test --update-goldens test/widget/pachinko_board_test.dart
    // Then manually verify the golden files before committing.

    testWidgets('PachinkoBoard golden file - basic rendering', (tester) async {
      final gameManager = _createGameManager();
      gameManager.selectLevel(1);

      await tester.pumpWidget(_createTestApp(gameManager));
      await tester.pumpAndSettle();

      // Golden file comparison for basic rendering
      await expectLater(
        find.byType(PachinkoBoard),
        matchesGoldenFile('golden/widget/pachinko_board_basic.png'),
      );

      gameManager.dispose();
    }, skip: true); // Skip until golden files are generated

    testWidgets('PachinkoBoard golden file - with balls', (tester) async {
      final gameManager = _createGameManager();
      gameManager.selectLevel(1);

      await tester.pumpWidget(_createTestApp(gameManager));
      await tester.pump();

      // Add balls in consistent positions
      final ball1 = Ball(
        position: vm.Vector2(200, 150),
        velocity: vm.Vector2(50, 100),
        color: GameConstants.ballColor,
      );
      final ball2 = Ball(
        position: vm.Vector2(180, 250),
        velocity: vm.Vector2(-30, 80),
        color: GameConstants.ballColor,
      );

      gameManager.gameState.launchBall(ball1);
      gameManager.gameState.launchBall(ball2);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Golden file comparison with balls
      await expectLater(
        find.byType(PachinkoBoard),
        matchesGoldenFile('golden/widget/pachinko_board_with_balls.png'),
      );

      gameManager.dispose();
    }, skip: true); // Skip until golden files are generated

    testWidgets('PachinkoBoard handles rapid state changes without errors', (tester) async {
      final gameManager = _createGameManager();
      gameManager.selectLevel(1);

      await tester.pumpWidget(_createTestApp(gameManager));
      await tester.pump();

      // Rapidly change game states
      for (int i = 0; i < 5; i++) {
        final ball = Ball(
          position: vm.Vector2(200, 100 + i * 20.0),
          velocity: vm.Vector2(50, 100),
          color: GameConstants.ballColor,
        );
        gameManager.gameState.launchBall(ball);
        await tester.pump();
      }

      // Trigger special bonus
      gameManager.gameState.triggerSpecialBonus();
      await tester.pump();

      // Update power
      gameManager.startLaunchCharging();
      gameManager.updateLaunchPower(75.0);
      await tester.pump();

      // Verify no errors during rapid state changes
      expect(find.byType(PachinkoBoard), findsOneWidget);
      expect(tester.takeException(), isNull);

      gameManager.dispose();
    });
  });
}

// ============================================================================
// Test Helper Functions
// ============================================================================

/// Creates a GameManager instance for testing
GameManager _createGameManager() {
  return GameManager();
}

/// Creates a test app wrapper with Provider for PachinkoBoard
Widget _createTestApp(GameManager gameManager) {
  return MaterialApp(
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
  );
}
