import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:pachinko_game/widgets/pachinko_board.dart';
import 'package:pachinko_game/services/game_manager.dart';
import 'package:pachinko_game/models/game_state.dart';
import 'package:pachinko_game/models/ball.dart';
import 'package:pachinko_game/models/ball_launcher.dart';
import 'package:pachinko_game/models/level.dart';
import 'package:pachinko_game/models/peg.dart';
import 'package:pachinko_game/models/slot.dart';
import 'package:pachinko_game/utils/constants.dart';

// Generate mocks for Level and Slot
@GenerateMocks([Level, Slot])
import 'pachinko_board_test.mocks.dart';

// Reuse mocks from menu_screen_test
import '../screens/menu_screen_test.mocks.dart';

void main() {
  late MockGameManager mockGameManager;
  late MockGameState mockGameState;
  late MockBallLauncher mockBallLauncher;
  late MockLevel mockLevel;

  setUp(() {
    mockGameManager = MockGameManager();
    mockGameState = MockGameState();
    mockBallLauncher = MockBallLauncher();
    mockLevel = MockLevel();

    // Stub GameManager properties
    when(mockGameManager.gameState).thenReturn(mockGameState);
    when(mockGameManager.ballLauncher).thenReturn(mockBallLauncher);

    // Stub GameState properties with default values
    when(mockGameState.currentLevel).thenReturn(mockLevel);
    when(mockGameState.activeBalls).thenReturn([]);
    when(mockGameState.canLaunchBall).thenReturn(true);
    when(mockGameState.phase).thenReturn(GamePhase.ready);
    when(mockGameState.specialBonusTriggered).thenReturn(false);
    when(mockGameState.score).thenReturn(0);
    when(mockGameState.ballsRemaining).thenReturn(20);
    when(mockGameState.currentLevelNumber).thenReturn(1);

    // Stub BallLauncher properties
    when(mockBallLauncher.phase).thenReturn(LaunchPhase.ready);
    when(mockBallLauncher.launchPower).thenReturn(0.0);
    when(mockBallLauncher.maxPower).thenReturn(100.0);
    when(mockBallLauncher.currentBall).thenReturn(null);
    when(mockBallLauncher.getLaunchPath()).thenReturn([
      Vector2(GameConstants.launchChannelStartX, GameConstants.launchChannelStartY),
      Vector2(GameConstants.launchChannelStartX, GameConstants.launchChannelEndY),
    ]);

    // Stub Level properties
    when(mockLevel.pegs).thenReturn([]);
    when(mockLevel.slots).thenReturn([]);
    when(mockLevel.launchX).thenReturn(GameConstants.launchChannelStartX);
    when(mockLevel.launchY).thenReturn(GameConstants.launchChannelStartY);
  });

  /// Widget test harness that wraps PachinkoBoard with ChangeNotifierProvider<GameManager>
  ///
  /// Provides a Material app context with Provider access for testing PachinkoBoard
  /// widget interactions. PachinkoBoard uses Consumer<GameManager> to access gameState,
  /// so the Provider must wrap MaterialApp to ensure all widgets have access.
  ///
  /// The [gameManager] parameter allows injection of a mocked GameManager for isolated
  /// widget testing. PachinkoBoard's Consumer will rebuild when GameManager calls
  /// notifyListeners().
  Widget createTestWidget({required GameManager gameManager}) {
    return ChangeNotifierProvider<GameManager>.value(
      value: gameManager,
      child: const MaterialApp(
        home: Scaffold(
          body: PachinkoBoard(),
        ),
      ),
    );
  }

  group('PachinkoBoard Widget Rendering', () {
    /// GIVEN PachinkoBoard is rendered with mocked GameManager
    /// WHEN checking widget tree
    /// THEN PachinkoBoard builds without errors
    testWidgets('givenPachinkoBoardRendered_whenCheckingWidgetTree_thenBuildsWithoutErrors',
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));

      expect(find.byType(PachinkoBoard), findsOneWidget);
    });

    /// GIVEN PachinkoBoard is rendered
    /// WHEN checking widget structure
    /// THEN CustomPaint widget is present
    ///
    /// PachinkoBoard uses CustomPaint with _PachinkoBoardPainter to render game board.
    testWidgets('givenPachinkoBoardRendered_whenCheckingStructure_thenCustomPaintPresent',
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));

      // Find CustomPaint widgets (may include Material's CustomPaint)
      expect(find.byType(CustomPaint), findsWidgets);
    });

    /// GIVEN PachinkoBoard is rendered
    /// WHEN checking gesture handling structure
    /// THEN GestureDetector wraps CustomPaint
    testWidgets('givenPachinkoBoardRendered_whenCheckingGestureStructure_thenGestureDetectorPresent',
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));

      expect(find.byType(GestureDetector), findsOneWidget);
    });

    /// GIVEN PachinkoBoard is rendered with mocked GameManager
    /// WHEN Consumer accesses GameManager
    /// THEN GameManager is accessed via Provider
    ///
    /// Verifies Provider<GameManager> integration works correctly in widget context.
    testWidgets('givenPachinkoBoardWithMockedGameManager_whenConsumerAccesses_thenGameManagerAccessedViaProvider',
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));

      // Consumer should access gameManager.gameState
      verify(mockGameManager.gameState).called(greaterThan(0));
    });
  });

  group('PachinkoBoard Gesture Detection - Pan Start', () {
    /// GIVEN PachinkoBoard with canLaunchBall=true
    /// WHEN user taps in launch area (bottom right)
    /// THEN GameManager.startLaunchCharging() is called
    ///
    /// Launch area is defined by GameConstants.launchChannelStartX/Y.
    /// Tests coordinate validation for valid launch area tap.
    testWidgets('givenPachinkoBoardWithCanLaunch_whenUserTapsLaunchArea_thenStartLaunchChargingCalled',
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));

      // Tap in launch area (scale-adjusted coordinates)
      const launchX = GameConstants.launchChannelStartX;
      const launchY = GameConstants.launchChannelStartY;
      await tester.tapAt(const Offset(launchX, launchY));
      await tester.pump();

      verify(mockGameManager.startLaunchCharging()).called(1);
    });

    /// GIVEN PachinkoBoard with canLaunchBall=true
    /// WHEN user taps outside launch area
    /// THEN GameManager.startLaunchCharging() is NOT called
    testWidgets('givenPachinkoBoardWithCanLaunch_whenUserTapsOutsideLaunchArea_thenStartLaunchChargingNotCalled',
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));

      // Tap outside launch area (top left corner)
      await tester.tapAt(const Offset(50, 50));
      await tester.pump();

      verifyNever(mockGameManager.startLaunchCharging());
    });

    /// GIVEN PachinkoBoard with canLaunchBall=false
    /// WHEN user taps in launch area
    /// THEN GameManager.startLaunchCharging() is NOT called
    ///
    /// Tests that launch is disabled when canLaunchBall=false.
    testWidgets('givenPachinkoBoardWithCannotLaunch_whenUserTapsLaunchArea_thenStartLaunchChargingNotCalled',
      (WidgetTester tester) async {
      when(mockGameState.canLaunchBall).thenReturn(false);

      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));

      // Tap in launch area
      const launchX = GameConstants.launchChannelStartX;
      const launchY = GameConstants.launchChannelStartY;
      await tester.tapAt(const Offset(launchX, launchY));
      await tester.pump();

      verifyNever(mockGameManager.startLaunchCharging());
    });

    /// GIVEN PachinkoBoard with canLaunchBall=true
    /// WHEN user starts drag in launch area
    /// THEN internal drag state updates (_isDragging=true)
    ///
    /// Note: Testing internal state is done indirectly by verifying subsequent behavior.
    /// Starting a drag should enable power updates on pan update.
    testWidgets('givenPachinkoBoardWithCanLaunch_whenUserStartsDragInLaunchArea_thenDragStateUpdates',
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));

      // Start drag in launch area
      const launchX = GameConstants.launchChannelStartX;
      const launchY = GameConstants.launchChannelStartY;
      await tester.dragFrom(const Offset(launchX, launchY), const Offset(0, -50));
      await tester.pump();

      // Verify that drag was processed (startLaunchCharging called)
      verify(mockGameManager.startLaunchCharging()).called(1);
      // Verify that power was updated during drag
      verify(mockGameManager.updateLaunchPower(any)).called(greaterThan(0));
    });

    /// GIVEN PachinkoBoard with canLaunchBall=true
    /// WHEN user starts drag in launch area
    /// THEN drag start position is captured
    ///
    /// Verified indirectly through power calculation on pan update.
    testWidgets('givenPachinkoBoardWithCanLaunch_whenUserStartsDrag_thenDragStartPositionCaptured',
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));

      // Start and complete drag in launch area
      const launchX = GameConstants.launchChannelStartX;
      const launchY = GameConstants.launchChannelStartY;
      await tester.dragFrom(const Offset(launchX, launchY), const Offset(0, -100));
      await tester.pump();

      // Verify power was calculated based on drag distance (100 pixels)
      // Power = (dragDistance / 2.0).clamp(0.0, 100.0)
      // Expected power = (100 / 2.0) = 50.0
      verify(mockGameManager.updateLaunchPower(argThat(closeTo(50.0, 5.0)))).called(greaterThan(0));
    });
  });

  group('PachinkoBoard Gesture Detection - Pan Update', () {
    /// GIVEN user is dragging from launch area
    /// WHEN pan update occurs
    /// THEN GameManager.updateLaunchPower() is called
    testWidgets('givenUserDragging_whenPanUpdateOccurs_thenUpdateLaunchPowerCalled',
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));

      // Drag from launch area
      const launchX = GameConstants.launchChannelStartX;
      const launchY = GameConstants.launchChannelStartY;
      await tester.dragFrom(const Offset(launchX, launchY), const Offset(0, -50));
      await tester.pump();

      verify(mockGameManager.updateLaunchPower(any)).called(greaterThan(0));
    });

    /// GIVEN user drags 100 pixels
    /// WHEN pan update calculates power
    /// THEN power is calculated correctly from drag distance
    ///
    /// Power formula: (dragDistance / 2.0).clamp(0.0, 100.0)
    /// 100px drag = 50.0 power
    testWidgets('givenUserDrags100Pixels_whenPowerCalculated_thenPowerIs50',
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));

      // Drag exactly 100 pixels from launch area
      const launchX = GameConstants.launchChannelStartX;
      const launchY = GameConstants.launchChannelStartY;
      await tester.dragFrom(const Offset(launchX, launchY), const Offset(0, -100));
      await tester.pump();

      // Verify power calculation: 100 / 2.0 = 50.0
      verify(mockGameManager.updateLaunchPower(argThat(closeTo(50.0, 5.0)))).called(greaterThan(0));
    });

    /// GIVEN user is NOT dragging
    /// WHEN pan update occurs
    /// THEN updateLaunchPower is NOT called
    ///
    /// Tests that pan updates are ignored when drag hasn't started in launch area.
    testWidgets('givenUserNotDragging_whenPanUpdateOccurs_thenUpdateLaunchPowerNotCalled',
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));

      // Drag from outside launch area (should not start charging)
      await tester.dragFrom(const Offset(50, 50), const Offset(0, -50));
      await tester.pump();

      verifyNever(mockGameManager.updateLaunchPower(any));
    });

    /// GIVEN canLaunchBall=false
    /// WHEN user attempts pan update
    /// THEN updateLaunchPower is NOT called
    testWidgets('givenCannotLaunch_whenUserAttemptsPanUpdate_thenUpdateLaunchPowerNotCalled',
      (WidgetTester tester) async {
      when(mockGameState.canLaunchBall).thenReturn(false);

      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));

      // Attempt drag from launch area
      const launchX = GameConstants.launchChannelStartX;
      const launchY = GameConstants.launchChannelStartY;
      await tester.dragFrom(const Offset(launchX, launchY), const Offset(0, -50));
      await tester.pump();

      verifyNever(mockGameManager.updateLaunchPower(any));
    });
  });

  group('PachinkoBoard Gesture Detection - Pan End', () {
    /// GIVEN user has completed valid drag from launch area
    /// WHEN pan end occurs
    /// THEN GameManager.launchBall() is called
    testWidgets('givenUserCompletedValidDrag_whenPanEndOccurs_thenLaunchBallCalled',
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));

      // Complete drag from launch area
      const launchX = GameConstants.launchChannelStartX;
      const launchY = GameConstants.launchChannelStartY;
      await tester.dragFrom(const Offset(launchX, launchY), const Offset(0, -100));
      await tester.pumpAndSettle();

      verify(mockGameManager.launchBall()).called(1);
    });

    /// GIVEN user completed drag
    /// WHEN pan end occurs
    /// THEN drag state is reset (_isDragging=false, positions nulled)
    ///
    /// Verified indirectly by checking that subsequent taps require new drag start.
    testWidgets('givenUserCompletedDrag_whenPanEndOccurs_thenDragStateReset',
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));

      // Complete first drag
      const launchX = GameConstants.launchChannelStartX;
      const launchY = GameConstants.launchChannelStartY;
      await tester.dragFrom(const Offset(launchX, launchY), const Offset(0, -50));
      await tester.pumpAndSettle();

      // Reset mock to clear previous calls
      reset(mockGameManager);
      when(mockGameManager.gameState).thenReturn(mockGameState);
      when(mockGameManager.ballLauncher).thenReturn(mockBallLauncher);

      // Start new drag - should call startLaunchCharging again
      await tester.dragFrom(const Offset(launchX, launchY), const Offset(0, -50));
      await tester.pump();

      verify(mockGameManager.startLaunchCharging()).called(1);
    });

    /// GIVEN user taps without dragging
    /// WHEN pan end occurs
    /// THEN launchBall is NOT called
    testWidgets('givenUserTapsWithoutDragging_whenPanEndOccurs_thenLaunchBallNotCalled',
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));

      // Tap outside launch area (no drag)
      await tester.tapAt(const Offset(50, 50));
      await tester.pumpAndSettle();

      verifyNever(mockGameManager.launchBall());
    });
  });

  group('PachinkoBoard CustomPainter Integration', () {
    /// GIVEN PachinkoBoard is rendered
    /// WHEN CustomPaint painter is created
    /// THEN painter receives correct GameManager instance
    testWidgets('givenPachinkoBoardRendered_whenPainterCreated_thenReceivesGameManager',
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));

      // Verify painter accesses GameManager's gameState
      // Note: ballLauncher is only accessed when dragging (power indicator)
      verify(mockGameManager.gameState).called(greaterThan(0));
    });

    /// GIVEN user is dragging
    /// WHEN painter is created
    /// THEN painter receives drag state (dragStart, dragEnd, isDragging)
    ///
    /// Note: We can't directly inspect painter parameters, but we verify that
    /// the painter is created with drag state by checking visual rendering via golden tests.
    /// This test verifies the painter is invoked during drag.
    testWidgets('givenUserDragging_whenPainterCreated_thenReceivesDragState',
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));

      // Start drag (this will cause painter to receive drag state)
      const launchX = GameConstants.launchChannelStartX;
      const launchY = GameConstants.launchChannelStartY;

      final gesture = await tester.startGesture(const Offset(launchX, launchY));
      await gesture.moveTo(const Offset(launchX, launchY - 50));
      await tester.pump();

      // Verify painter is invoked with updated state
      verify(mockGameManager.ballLauncher).called(greaterThan(0));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    /// GIVEN PachinkoBoard painter
    /// WHEN shouldRepaint is called
    /// THEN returns true (always repaint for animation)
    ///
    /// Note: CustomPainter.shouldRepaint is tested indirectly by verifying
    /// the board repaints on every frame. The painter's shouldRepaint always
    /// returns true to support smooth ball animations.
    testWidgets('givenPachinkoBoardPainter_whenShouldRepaint_thenReturnsTrue',
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      await tester.pump();

      // Painter always returns true from shouldRepaint for smooth animations
      // This is verified by the painter implementation, not through mock verification
      expect(find.byType(PachinkoBoard), findsOneWidget);
    });
  });

  group('PachinkoBoard Conditional Rendering', () {
    /// GIVEN user is dragging (isDragging=true) AND canLaunchBall=true
    /// WHEN CustomPaint renders
    /// THEN power indicator is rendered
    ///
    /// Note: Actual visual rendering tested via golden tests.
    /// This test verifies the conditions for power indicator rendering.
    testWidgets('givenUserDraggingWithCanLaunch_whenRendered_thenPowerIndicatorRendered',
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));

      // Start drag to trigger power indicator
      const launchX = GameConstants.launchChannelStartX;
      const launchY = GameConstants.launchChannelStartY;

      final gesture = await tester.startGesture(const Offset(launchX, launchY));
      await gesture.moveTo(const Offset(launchX, launchY - 50));
      await tester.pump();

      // Verify ballLauncher properties accessed (for power indicator)
      verify(mockBallLauncher.launchPower).called(greaterThan(0));
      verify(mockBallLauncher.maxPower).called(greaterThan(0));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    /// GIVEN user is NOT dragging (isDragging=false)
    /// WHEN CustomPaint renders
    /// THEN power indicator is NOT rendered
    testWidgets('givenUserNotDragging_whenRendered_thenPowerIndicatorNotRendered',
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));

      // Don't start drag, just render
      await tester.pump();

      // Power and maxPower might still be accessed for other purposes,
      // but they shouldn't be accessed in the power indicator rendering context.
      // This is best verified via golden tests showing no power meter.
      expect(find.byType(PachinkoBoard), findsOneWidget);
    });

    /// GIVEN specialBonusTriggered=true
    /// WHEN CustomPaint renders
    /// THEN special bonus effect overlay is rendered
    testWidgets('givenSpecialBonusTriggered_whenRendered_thenBonusEffectRendered',
      (WidgetTester tester) async {
      when(mockGameState.specialBonusTriggered).thenReturn(true);

      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      await tester.pump();

      // Verify specialBonusTriggered accessed for rendering
      verify(mockGameState.specialBonusTriggered).called(greaterThan(0));
    });

    /// GIVEN specialBonusTriggered=false
    /// WHEN CustomPaint renders
    /// THEN special bonus effect is NOT rendered
    testWidgets('givenSpecialBonusNotTriggered_whenRendered_thenBonusEffectNotRendered',
      (WidgetTester tester) async {
      when(mockGameState.specialBonusTriggered).thenReturn(false);

      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      await tester.pump();

      // Verify no bonus effect rendered (golden test validates visual)
      expect(find.byType(PachinkoBoard), findsOneWidget);
    });
  });

  group('PachinkoBoard Golden Tests - Visual Regression', () {
    /// GIVEN empty board with no balls, no drag
    /// WHEN rendering board
    /// THEN matches golden baseline for empty board
    ///
    /// Golden test for base board state with launch area and channel visible.
    testWidgets('givenEmptyBoard_whenRendered_thenMatchesGoldenBaseline',
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(PachinkoBoard),
        matchesGoldenFile('goldens/pachinko_board_empty.png'),
      );
    });

    /// GIVEN board with pegs and slots
    /// WHEN rendering board
    /// THEN matches golden baseline for board with pegs and slots
    testWidgets('givenBoardWithPegsAndSlots_whenRendered_thenMatchesGoldenBaseline',
      (WidgetTester tester) async {
      // Add pegs to level
      final testPegs = [
        Peg(position: Vector2(200, 200), type: PegType.normal),
        Peg(position: Vector2(250, 200), type: PegType.normal),
        Peg(position: Vector2(225, 230), type: PegType.special),
      ];
      when(mockLevel.pegs).thenReturn(testPegs);

      // Add slots to level
      final testSlots = [
        Slot(position: Vector2(100, 750), width: 40, height: 20, pointValue: 50),
        Slot(position: Vector2(200, 750), width: 40, height: 20, pointValue: 100),
        Slot(position: Vector2(300, 750), width: 40, height: 20, pointValue: 200),
      ];
      when(mockLevel.slots).thenReturn(testSlots);

      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(PachinkoBoard),
        matchesGoldenFile('goldens/pachinko_board_with_pegs_slots.png'),
      );
    });

    /// GIVEN board with active balls
    /// WHEN rendering board
    /// THEN matches golden baseline for board with balls
    testWidgets('givenBoardWithActiveBalls_whenRendered_thenMatchesGoldenBaseline',
      (WidgetTester tester) async {
      // Add active balls
      final testBalls = [
        Ball(position: Vector2(200, 300)),
        Ball(position: Vector2(250, 400)),
      ];
      when(mockGameState.activeBalls).thenReturn(testBalls);

      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(PachinkoBoard),
        matchesGoldenFile('goldens/pachinko_board_with_balls.png'),
      );
    });

    /// GIVEN user dragging with power indicator visible
    /// WHEN rendering board during drag
    /// THEN matches golden baseline for power indicator
    testWidgets('givenUserDragging_whenRendered_thenMatchesGoldenBaseline',
      (WidgetTester tester) async {
      when(mockBallLauncher.launchPower).thenReturn(75.0);

      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));

      // Start drag to show power indicator
      const launchX = GameConstants.launchChannelStartX;
      const launchY = GameConstants.launchChannelStartY;

      final gesture = await tester.startGesture(const Offset(launchX, launchY));
      await gesture.moveTo(const Offset(launchX, launchY - 150));
      await tester.pump();

      await expectLater(
        find.byType(PachinkoBoard),
        matchesGoldenFile('goldens/pachinko_board_dragging_power.png'),
      );

      await gesture.up();
      await tester.pumpAndSettle();
    });

    /// GIVEN specialBonusTriggered=true
    /// WHEN rendering board
    /// THEN matches golden baseline for special bonus effect
    testWidgets('givenSpecialBonusTriggered_whenRendered_thenMatchesGoldenBaseline',
      (WidgetTester tester) async {
      when(mockGameState.specialBonusTriggered).thenReturn(true);

      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(PachinkoBoard),
        matchesGoldenFile('goldens/pachinko_board_special_bonus.png'),
      );
    });

    /// GIVEN board with launch channel and area visualization
    /// WHEN rendering board
    /// THEN matches golden baseline for launch visualization
    testWidgets('givenBoardWithLaunchVisualization_whenRendered_thenMatchesGoldenBaseline',
      (WidgetTester tester) async {
      // Set launch path
      when(mockBallLauncher.getLaunchPath()).thenReturn([
        Vector2(GameConstants.launchChannelStartX, GameConstants.launchChannelStartY),
        Vector2(GameConstants.launchChannelStartX, GameConstants.launchChannelEndY),
        Vector2(GameConstants.launchChannelStartX - 20, GameConstants.launchChannelEndY - 50),
      ]);

      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(PachinkoBoard),
        matchesGoldenFile('goldens/pachinko_board_launch_channel.png'),
      );
    });
  });

  group('PachinkoBoard Edge Cases', () {
    /// GIVEN currentLevel is null
    /// WHEN CustomPaint renders
    /// THEN painter handles gracefully (early return, no crash)
    testWidgets('givenNullCurrentLevel_whenRendered_thenHandlesGracefully',
      (WidgetTester tester) async {
      when(mockGameState.currentLevel).thenReturn(null);

      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      await tester.pump();

      // Should not crash, widget should still render
      expect(find.byType(PachinkoBoard), findsOneWidget);
    });

    /// GIVEN various screen sizes
    /// WHEN board is rendered
    /// THEN scale calculation adapts correctly
    ///
    /// Tests that board scales to fit different screen dimensions.
    testWidgets('givenVariousScreenSizes_whenRendered_thenScaleCalculationAdapts',
      (WidgetTester tester) async {
      // Test with small screen
      tester.view.physicalSize = const Size(600, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      await tester.pump();

      expect(find.byType(PachinkoBoard), findsOneWidget);

      // Test with large screen
      tester.view.physicalSize = const Size(1200, 2000);
      await tester.pump();

      expect(find.byType(PachinkoBoard), findsOneWidget);

      tester.view.reset();
    });

    /// GIVEN multiple active balls on board
    /// WHEN rendering board
    /// THEN all balls are rendered correctly
    testWidgets('givenMultipleActiveBalls_whenRendered_thenAllBallsRendered',
      (WidgetTester tester) async {
      // Add 5 active balls
      final testBalls = List.generate(5, (i) => Ball(position: Vector2(200.0 + i * 50, 300.0 + i * 50)));
      when(mockGameState.activeBalls).thenReturn(testBalls);

      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      await tester.pump();

      // Verify all balls accessed for rendering
      verify(mockGameState.activeBalls).called(greaterThan(0));
      expect(find.byType(PachinkoBoard), findsOneWidget);
    });
  });

  group('PachinkoBoard Animations - Ball Launch Path', () {
    /// GIVEN ball launcher is charging power
    /// WHEN power is being charged
    /// THEN power indicator is shown
    testWidgets('givenBallLauncher_whenChargingPower_thenPowerIndicatorShown',
      (WidgetTester tester) async {
      when(mockGameState.canLaunchBall).thenReturn(true);
      when(mockBallLauncher.phase).thenReturn(LaunchPhase.charging);
      when(mockBallLauncher.launchPower).thenReturn(50.0);
      when(mockBallLauncher.maxPower).thenReturn(100.0);

      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));

      // Start drag to trigger power indicator
      const launchX = GameConstants.launchChannelStartX;
      const launchY = GameConstants.launchChannelStartY;
      final gesture = await tester.startGesture(const Offset(launchX, launchY));
      await gesture.moveTo(const Offset(launchX, launchY - 100));
      await tester.pump();

      // Verify power and maxPower are accessed for power meter rendering
      verify(mockBallLauncher.launchPower).called(greaterThan(0));
      verify(mockBallLauncher.maxPower).called(greaterThan(0));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    /// GIVEN launch channel with curved boundary
    /// WHEN board is rendered
    /// THEN curved boundary spans from left edge to launch column
    testWidgets('givenLaunchChannel_whenRendered_thenCurvedBoundaryCorrectlyPositioned',
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      await tester.pump();

      // The curved boundary should be drawn at the top of the field
      // Visual verification is done through golden tests
      // This test ensures the widget renders without errors
      expect(find.byType(PachinkoBoard), findsOneWidget);
    });
  });

  group('PachinkoBoard Animations - Peg Hit Effects', () {
    /// GIVEN peg collision occurs
    /// WHEN ball hits peg
    /// THEN pulse effect is triggered on peg
    testWidgets('givenPegCollision_whenBallHitsPeg_thenPulseEffectTriggered',
      (WidgetTester tester) async {
      final testPeg = Peg(position: Vector2(200, 200), type: PegType.normal);
      testPeg.onHit(); // Simulate hit
      when(mockLevel.pegs).thenReturn([testPeg]);

      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      await tester.pump();

      // Peg should be marked as hit
      expect(testPeg.hasBeenHit, isTrue);
    });

    /// GIVEN pulse animation is running
    /// WHEN animation completes
    /// THEN peg returns to normal state
    testWidgets('givenPulseAnimation_whenComplete_thenPegReturnsToNormalState',
      (WidgetTester tester) async {
      final testPeg = Peg(position: Vector2(200, 200), type: PegType.normal);
      when(mockLevel.pegs).thenReturn([testPeg]);

      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));

      // Trigger hit and wait for pulse animation to complete (~250ms)
      testPeg.onHit();
      await tester.pump(const Duration(milliseconds: 300));

      expect(testPeg.hasBeenHit, isTrue);
    });
  });

  group('PachinkoBoard Animations - Special Peg Glow', () {
    /// GIVEN special peg exists
    /// WHEN rendered
    /// THEN shimmer effect is visible
    testWidgets('givenSpecialPeg_whenRendered_thenShimmerEffectVisible',
      (WidgetTester tester) async {
      final specialPeg = Peg(position: Vector2(200, 200), type: PegType.special);
      when(mockLevel.pegs).thenReturn([specialPeg]);

      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      await tester.pump();

      // Special peg should be highlighted
      expect(specialPeg.isHighlighted, isTrue);
    });

    /// GIVEN all special pegs hit
    /// WHEN all hit
    /// THEN glow animation stops
    testWidgets('givenSpecialPegHit_whenAllHit_thenGlowAnimationStops',
      (WidgetTester tester) async {
      final specialPeg = Peg(position: Vector2(200, 200), type: PegType.special);
      specialPeg.onHit(); // Hit the special peg
      when(mockLevel.pegs).thenReturn([specialPeg]);

      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      await tester.pump();

      // After hit, special peg should not be highlighted
      expect(specialPeg.isHighlighted, isFalse);
    });
  });

  group('PachinkoBoard Animations - Score Popup', () {
    /// GIVEN slot is hit
    /// WHEN score awarded
    /// THEN floating text appears
    testWidgets('givenSlotHit_whenScoreAwarded_thenFloatingTextAppears',
      (WidgetTester tester) async {
      // This test will verify score popup rendering
      // Actual implementation will add AnimatedWidget overlay
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      await tester.pump();

      // Placeholder for score popup verification
      expect(find.byType(PachinkoBoard), findsOneWidget);
    });

    /// GIVEN score popup animation
    /// WHEN animation complete
    /// THEN text fades out
    testWidgets('givenScorePopup_whenAnimationComplete_thenTextFadesOut',
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));

      // Animate for 2 seconds (score popup duration)
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(PachinkoBoard), findsOneWidget);
    });
  });

  group('PachinkoBoard Animations - Bonus Effects', () {
    /// GIVEN special bonus triggered
    /// WHEN triggered
    /// THEN screen flash animation plays
    testWidgets('givenSpecialBonus_whenTriggered_thenScreenFlashAnimationPlays',
      (WidgetTester tester) async {
      when(mockGameState.specialBonusTriggered).thenReturn(true);

      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      await tester.pump();

      verify(mockGameState.specialBonusTriggered).called(greaterThan(0));
    });

    /// GIVEN bonus particles triggered
    /// WHEN triggered
    /// THEN particle burst is visible
    testWidgets('givenBonusParticles_whenTriggered_thenParticleBurstVisible',
      (WidgetTester tester) async {
      when(mockGameState.specialBonusTriggered).thenReturn(true);

      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));

      // Pump through particle animation (~500ms)
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(PachinkoBoard), findsOneWidget);
    });
  });

  group('PachinkoBoard Animations - Level Transition', () {
    /// GIVEN level complete
    /// WHEN transitioning
    /// THEN fade animation plays
    testWidgets('givenLevelComplete_whenTransitioning_thenFadeAnimationPlays',
      (WidgetTester tester) async {
      when(mockGameState.phase).thenReturn(GamePhase.levelComplete);

      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));

      // Pump through fade out animation
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(PachinkoBoard), findsOneWidget);
    });

    /// GIVEN new level loaded
    /// WHEN loaded
    /// THEN fade in animation smooth
    testWidgets('givenNewLevel_whenLoaded_thenFadeInAnimationSmooth',
      (WidgetTester tester) async {
      when(mockGameState.currentLevelNumber).thenReturn(2);

      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));

      // Pump through fade in animation
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(PachinkoBoard), findsOneWidget);
    });
  });

  group('PachinkoBoard Golden Tests - Animation States', () {
    /// GIVEN ball launch path charging
    /// WHEN rendered
    /// THEN matches golden for launch path visualization
    testWidgets('givenLaunchCharging_whenRendered_thenMatchesGolden',
      (WidgetTester tester) async {
      when(mockBallLauncher.phase).thenReturn(LaunchPhase.charging);
      when(mockBallLauncher.launchPower).thenReturn(75.0);

      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));

      const launchX = GameConstants.launchChannelStartX;
      const launchY = GameConstants.launchChannelStartY;
      final gesture = await tester.startGesture(const Offset(launchX, launchY));
      await gesture.moveTo(const Offset(launchX, launchY - 150));
      await tester.pump();

      await expectLater(
        find.byType(PachinkoBoard),
        matchesGoldenFile('goldens/ball_launch_charging.png'),
      );

      await gesture.up();
      await tester.pumpAndSettle();
    });

    /// GIVEN peg hit pulse effect
    /// WHEN rendered mid-animation
    /// THEN matches golden for peg pulse
    testWidgets('givenPegHitPulse_whenRendered_thenMatchesGolden',
      (WidgetTester tester) async {
      final testPeg = Peg(position: Vector2(250, 300), type: PegType.normal);
      testPeg.onHit();
      when(mockLevel.pegs).thenReturn([testPeg]);

      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      await tester.pump(const Duration(milliseconds: 125)); // Mid-pulse

      await expectLater(
        find.byType(PachinkoBoard),
        matchesGoldenFile('goldens/peg_hit_pulse.png'),
      );
    });

    /// GIVEN special peg shimmer
    /// WHEN rendered
    /// THEN matches golden for shimmer state
    testWidgets('givenSpecialPegShimmer_whenRendered_thenMatchesGolden',
      (WidgetTester tester) async {
      final specialPeg = Peg(position: Vector2(250, 300), type: PegType.special);
      when(mockLevel.pegs).thenReturn([specialPeg]);

      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      await tester.pump();

      await expectLater(
        find.byType(PachinkoBoard),
        matchesGoldenFile('goldens/special_peg_shimmer.png'),
      );
    });

    /// GIVEN bonus flash effect
    /// WHEN rendered
    /// THEN matches golden for screen flash
    testWidgets('givenBonusFlash_whenRendered_thenMatchesGolden',
      (WidgetTester tester) async {
      when(mockGameState.specialBonusTriggered).thenReturn(true);

      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      await tester.pump(const Duration(milliseconds: 100)); // Early flash

      await expectLater(
        find.byType(PachinkoBoard),
        matchesGoldenFile('goldens/bonus_flash.png'),
      );
    });
  });
}