import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:pachinko_game/screens/game_screen.dart';
import 'package:pachinko_game/services/game_manager.dart';
import 'package:pachinko_game/models/game_state.dart';
import 'package:pachinko_game/models/ball.dart';
import 'package:pachinko_game/models/ball_launcher.dart';
import 'package:pachinko_game/widgets/pachinko_board.dart';
import 'package:pachinko_game/utils/constants.dart';

// Reuse mocks from menu_screen_test
import 'menu_screen_test.mocks.dart';

void main() {
  late MockGameManager mockGameManager;
  late MockGameState mockGameState;
  late MockBallLauncher mockBallLauncher;

  setUp(() {
    mockGameManager = MockGameManager();
    mockGameState = MockGameState();
    mockBallLauncher = MockBallLauncher();

    // Stub GameManager properties
    when(mockGameManager.gameState).thenReturn(mockGameState);
    when(mockGameManager.ballLauncher).thenReturn(mockBallLauncher);

    // Stub GameState properties with default values
    when(mockGameState.score).thenReturn(1000);
    when(mockGameState.ballsRemaining).thenReturn(15);
    when(mockGameState.currentLevel).thenReturn(null);
    when(mockGameState.currentLevelNumber).thenReturn(3);
    when(mockGameState.activeBalls).thenReturn([]);
    when(mockGameState.canLaunchBall).thenReturn(true);
    when(mockGameState.phase).thenReturn(GamePhase.ready);
    when(mockGameState.isGameOver).thenReturn(false);

    // Stub BallLauncher properties
    when(mockBallLauncher.phase).thenReturn(LaunchPhase.ready);
    when(mockBallLauncher.currentBall).thenReturn(null);
    when(mockBallLauncher.launchPower).thenReturn(0.0);
  });

  /// Widget test harness that wraps GameScreen with ChangeNotifierProvider<GameManager>
  ///
  /// Provides a Material app context with theme and Provider access for testing
  /// GameScreen widget interactions. GameScreen uses Consumer<GameManager> to access
  /// gameState, so the Provider must wrap MaterialApp to ensure all widgets have access.
  ///
  /// The [gameManager] parameter allows injection of a mocked GameManager for isolated
  /// widget testing. GameScreen's Consumer widgets will rebuild when GameManager or
  /// its nested gameState calls notifyListeners().
  Widget createTestWidget({required GameManager gameManager}) {
    return ChangeNotifierProvider<GameManager>.value(
      value: gameManager,
      child: const MaterialApp(
        home: GameScreen(),
      ),
    );
  }

  group('GameScreen HUD Display', () {
    /// GIVEN GameScreen is rendered with mocked GameState
    /// WHEN checking HUD display
    /// THEN GameScreen builds without errors
    testWidgets('givenGameScreenRendered_whenCheckingDisplay_thenBuildsWithoutErrors',
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      
      expect(find.byType(GameScreen), findsOneWidget);
    });

    /// GIVEN GameScreen is rendered with score=1000
    /// WHEN checking HUD score display
    /// THEN score "1000" is displayed in HUD
    ///
    /// Uses Consumer<GameManager> pattern where gameManager.gameState.score is accessed.
    /// Verifies find.text() locates score value from mocked GameState.
    testWidgets('givenGameScreenWithScore1000_whenCheckingHUD_thenScoreDisplayed',
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      
      expect(find.text('1000'), findsOneWidget);
      expect(find.text(GameStrings.score), findsOneWidget);
    });

    /// GIVEN GameScreen is rendered with ballsRemaining=15
    /// WHEN checking HUD balls display
    /// THEN balls count "15" is displayed in HUD
    testWidgets('givenGameScreenWithBalls15_whenCheckingHUD_thenBallsCountDisplayed',
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      
      expect(find.text('15'), findsOneWidget);
      expect(find.text(GameStrings.ballsRemaining), findsOneWidget);
    });

    /// GIVEN GameScreen is rendered with currentLevelNumber=3
    /// WHEN checking HUD level display
    /// THEN level "3" is displayed in HUD
    testWidgets('givenGameScreenWithLevel3_whenCheckingHUD_thenLevelDisplayed',
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      
      expect(find.text('3'), findsOneWidget);
      expect(find.text(GameStrings.level), findsOneWidget);
    });

    /// GIVEN GameScreen is rendered
    /// WHEN checking HUD icons
    /// THEN score, balls, and level icons are displayed
    testWidgets('givenGameScreenRendered_whenCheckingHUDIcons_thenAllIconsDisplayed',
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.sports_golf), findsOneWidget);
      expect(find.byIcon(Icons.layers), findsOneWidget);
    });
  });

  group('GameScreen PachinkoBoard Rendering', () {
    /// GIVEN GameScreen is rendered
    /// WHEN checking for PachinkoBoard widget
    /// THEN PachinkoBoard is present in widget tree
    ///
    /// Uses find.byType(PachinkoBoard) to verify custom widget rendered.
    testWidgets('givenGameScreenRendered_whenCheckingBoard_thenPachinkoBoardPresent',
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      
      expect(find.byType(PachinkoBoard), findsOneWidget);
    });

    /// GIVEN GameScreen is rendered
    /// WHEN checking widget structure
    /// THEN Scaffold and SafeArea are present
    testWidgets('givenGameScreenRendered_whenCheckingStructure_thenScaffoldAndSafeAreaPresent',
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(SafeArea), findsOneWidget);
    });
  });

  group('GameScreen Control Buttons', () {
    /// GIVEN GameScreen is rendered
    /// WHEN checking control buttons
    /// THEN back button is present
    testWidgets('givenGameScreenRendered_whenCheckingControls_thenBackButtonPresent',
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    /// GIVEN GameScreen is rendered
    /// WHEN checking control buttons
    /// THEN reset button is present
    testWidgets('givenGameScreenRendered_whenCheckingControls_thenResetButtonPresent',
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      
      expect(find.byIcon(Icons.restart_alt), findsOneWidget);
    });

    /// GIVEN GameScreen is rendered with phase=ready
    /// WHEN user taps reset button
    /// THEN GameManager.resetGame is called
    testWidgets('givenGameScreenRendered_whenUserTapsResetButton_thenResetGameCalled',
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      
      await tester.tap(find.byIcon(Icons.restart_alt));
      await tester.pump();
      
      verify(mockGameManager.resetGame()).called(1);
    });
  });

  group('GameScreen Pause/Resume Toggle', () {
    /// GIVEN GameScreen with phase=playing
    /// WHEN checking control buttons
    /// THEN pause button is present (play_arrow is NOT present)
    ///
    /// Tests conditional rendering: pause button shown only when phase == GamePhase.playing
    testWidgets('givenGameScreenWithPhasePlaying_whenCheckingControls_thenPauseButtonPresent',
      (WidgetTester tester) async {
      when(mockGameState.phase).thenReturn(GamePhase.playing);
      
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      
      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });

    /// GIVEN GameScreen with phase=ready and activeBalls not empty
    /// WHEN checking control buttons
    /// THEN resume button (play_arrow) is present
    ///
    /// Tests conditional rendering: resume button shown when phase == GamePhase.ready AND activeBalls.isNotEmpty
    testWidgets('givenGameScreenWithPhaseReadyAndActiveBalls_whenCheckingControls_thenResumeButtonPresent',
      (WidgetTester tester) async {
      when(mockGameState.phase).thenReturn(GamePhase.ready);
      when(mockGameState.activeBalls).thenReturn([Ball(position: Vector2(100, 100))]);
      
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsNothing);
    });

    /// GIVEN GameScreen with phase=ready and activeBalls empty
    /// WHEN checking control buttons
    /// THEN neither pause nor resume button is present
    testWidgets('givenGameScreenWithPhaseReadyAndNoActiveBalls_whenCheckingControls_thenNoPauseOrResumeButton',
      (WidgetTester tester) async {
      when(mockGameState.phase).thenReturn(GamePhase.ready);
      when(mockGameState.activeBalls).thenReturn([]);
      
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      
      expect(find.byIcon(Icons.pause), findsNothing);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });

    /// GIVEN GameScreen with phase=playing
    /// WHEN user taps pause button
    /// THEN GameManager.pauseGame is called
    testWidgets('givenGameScreenWithPhasePlaying_whenUserTapsPauseButton_thenPauseGameCalled',
      (WidgetTester tester) async {
      when(mockGameState.phase).thenReturn(GamePhase.playing);
      
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      
      await tester.tap(find.byIcon(Icons.pause));
      await tester.pump();
      
      verify(mockGameManager.pauseGame()).called(1);
    });

    /// GIVEN GameScreen with phase=ready and activeBalls not empty
    /// WHEN user taps resume button
    /// THEN GameManager.resumeGame is called
    testWidgets('givenGameScreenWithPhaseReady_whenUserTapsResumeButton_thenResumeGameCalled',
      (WidgetTester tester) async {
      when(mockGameState.phase).thenReturn(GamePhase.ready);
      when(mockGameState.activeBalls).thenReturn([Ball(position: Vector2(100, 100))]);
      
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();
      
      verify(mockGameManager.resumeGame()).called(1);
    });
  });

  group('GameScreen Next Level Conditional Display', () {
    /// GIVEN GameScreen with phase=gameOver and ballsRemaining=0
    /// WHEN checking control buttons
    /// THEN "Next Level" button is present
    ///
    /// Tests conditional rendering: next level button shown only when phase == GamePhase.gameOver AND ballsRemaining <= 0
    testWidgets('givenGameScreenWithGameOverAndNoBalls_whenCheckingControls_thenNextLevelButtonPresent',
      (WidgetTester tester) async {
      when(mockGameState.phase).thenReturn(GamePhase.gameOver);
      when(mockGameState.ballsRemaining).thenReturn(0);
      
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      
      expect(find.text('Next Level'), findsOneWidget);
      expect(find.byIcon(Icons.skip_next), findsOneWidget);
    });

    /// GIVEN GameScreen with phase=ready (not gameOver)
    /// WHEN checking control buttons
    /// THEN "Next Level" button is NOT present
    testWidgets('givenGameScreenWithPhaseReady_whenCheckingControls_thenNextLevelButtonNotPresent',
      (WidgetTester tester) async {
      when(mockGameState.phase).thenReturn(GamePhase.ready);
      when(mockGameState.ballsRemaining).thenReturn(0);
      
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      
      expect(find.text('Next Level'), findsNothing);
    });

    /// GIVEN GameScreen with phase=gameOver but ballsRemaining > 0
    /// WHEN checking control buttons
    /// THEN "Next Level" button is NOT present
    testWidgets('givenGameScreenWithGameOverButBallsRemaining_whenCheckingControls_thenNextLevelButtonNotPresent',
      (WidgetTester tester) async {
      when(mockGameState.phase).thenReturn(GamePhase.gameOver);
      when(mockGameState.ballsRemaining).thenReturn(5);
      
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      
      expect(find.text('Next Level'), findsNothing);
    });

    /// GIVEN GameScreen with phase=gameOver and ballsRemaining=0
    /// WHEN user taps "Next Level" button
    /// THEN GameManager.nextLevel is called
    testWidgets('givenGameScreenWithGameOver_whenUserTapsNextLevelButton_thenNextLevelCalled',
      (WidgetTester tester) async {
      when(mockGameState.phase).thenReturn(GamePhase.gameOver);
      when(mockGameState.ballsRemaining).thenReturn(0);
      
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      
      await tester.tap(find.text('Next Level'));
      await tester.pump();
      
      verify(mockGameManager.nextLevel()).called(1);
    });
  });

  group('GameScreen Back Navigation', () {
    /// GIVEN GameScreen is rendered
    /// WHEN user taps back button
    /// THEN Navigator.pop is called (verified by MenuScreen appearing)
    ///
    /// Back button triggers Navigator.of(context).pop(). We verify this by checking
    /// that tapping the button causes navigation away from GameScreen.
    testWidgets('givenGameScreenRendered_whenUserTapsBackButton_thenNavigationOccurs',
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      
      // Verify GameScreen is displayed
      expect(find.byType(GameScreen), findsOneWidget);
      
      // Tap back button
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      
      // After pop, GameScreen should no longer be in tree
      expect(find.byType(GameScreen), findsNothing);
    });
  });

  group('GameScreen Consumer State Display', () {
    /// GIVEN GameScreen is rendered with different state values
    /// WHEN Consumer rebuilds with new mock state
    /// THEN UI displays current mock state values
    ///
    /// Note: Testing actual Consumer rebuild on notifyListeners() requires a real
    /// ChangeNotifier, not a mock. These tests verify Consumer accesses current state.
    /// The UI updating on state changes is tested implicitly through conditional rendering
    /// tests (pause/resume toggle, next level conditional display).
    testWidgets('givenGameScreenRendered_whenConsumerAccesses State_thenCurrentStateDisplayed',
      (WidgetTester tester) async {
      // Render with different state values
      when(mockGameState.score).thenReturn(5000);
      when(mockGameState.ballsRemaining).thenReturn(5);
      when(mockGameState.currentLevelNumber).thenReturn(10);

      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));

      // Verify Consumer displays current state values
      expect(find.text('5000'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
    });
  });
}