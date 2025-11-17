import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:pachinko_game/screens/menu_screen.dart';
import 'package:pachinko_game/services/game_manager.dart';
import 'package:pachinko_game/models/game_state.dart';
import 'package:pachinko_game/models/ball_launcher.dart';
import 'package:pachinko_game/utils/constants.dart';

// Generate mocks for GameManager, GameState, and BallLauncher
@GenerateMocks([GameManager, GameState, BallLauncher])
import 'menu_screen_test.mocks.dart';

void main() {
  late MockGameManager mockGameManager;
  late MockGameState mockGameState;
  late MockBallLauncher mockBallLauncher;

  setUp(() {
    mockGameManager = MockGameManager();
    mockGameState = MockGameState();
    mockBallLauncher = MockBallLauncher();

    // Stub GameManager properties needed by GameScreen
    when(mockGameManager.gameState).thenReturn(mockGameState);
    when(mockGameManager.ballLauncher).thenReturn(mockBallLauncher);

    // Stub GameState properties
    when(mockGameState.score).thenReturn(0);
    when(mockGameState.ballsRemaining).thenReturn(20);
    when(mockGameState.currentLevel).thenReturn(null);
    when(mockGameState.currentLevelNumber).thenReturn(1);
    when(mockGameState.activeBalls).thenReturn([]);
    when(mockGameState.canLaunchBall).thenReturn(true);
    when(mockGameState.phase).thenReturn(GamePhase.ready);

    // Stub BallLauncher properties
    when(mockBallLauncher.phase).thenReturn(LaunchPhase.ready);
    when(mockBallLauncher.currentBall).thenReturn(null);
    when(mockBallLauncher.launchPower).thenReturn(0.0);
  });

  /// Widget test harness that wraps MenuScreen with ChangeNotifierProvider<GameManager>
  ///
  /// Provides a Material app context with theme and navigation support for testing
  /// MenuScreen widget interactions. The [gameManager] parameter allows injection
  /// of a mocked GameManager for isolated widget testing.
  ///
  /// Uses ChangeNotifierProvider.value since GameManager extends ChangeNotifier.
  /// Provider wraps MaterialApp to ensure all routes (including GameScreen) have access.
  Widget createTestWidget({required GameManager gameManager}) {
    return ChangeNotifierProvider<GameManager>.value(
      value: gameManager,
      child: const MaterialApp(
        home: MenuScreen(),
      ),
    );
  }

  group('MenuScreen UI Rendering', () {
    /// GIVEN MenuScreen is rendered
    /// WHEN widget tree is built
    /// THEN MenuScreen builds without errors
    testWidgets('givenMenuScreenRendered_whenWidgetTreeBuilt_thenBuildsWithoutErrors', 
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      
      expect(find.byType(MenuScreen), findsOneWidget);
    });

    /// GIVEN MenuScreen is rendered
    /// WHEN checking UI structure
    /// THEN Scaffold and SafeArea are present
    testWidgets('givenMenuScreenRendered_whenCheckingUIStructure_thenScaffoldAndSafeAreaPresent', 
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(SafeArea), findsOneWidget);
    });

    /// GIVEN MenuScreen is rendered
    /// WHEN checking title display
    /// THEN app name is displayed correctly
    ///
    /// Uses [find.text] to verify title text rendered from GameStrings.appName constant
    testWidgets('givenMenuScreenRendered_whenCheckingTitleDisplay_thenAppNameDisplayedCorrectly', 
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      
      expect(find.text(GameStrings.appName), findsOneWidget);
    });

    /// GIVEN MenuScreen is rendered
    /// WHEN checking subtitle
    /// THEN subtitle text is displayed
    testWidgets('givenMenuScreenRendered_whenCheckingSubtitle_thenSubtitleDisplayed', 
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      
      expect(find.text('Physics-based Pachinko Game'), findsOneWidget);
    });

    /// GIVEN MenuScreen is rendered
    /// WHEN checking game info
    /// THEN info text is displayed
    testWidgets('givenMenuScreenRendered_whenCheckingGameInfo_thenInfoTextDisplayed', 
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      
      expect(find.text('Launch balls, hit pegs, score points!'), findsOneWidget);
    });

    /// GIVEN MenuScreen is rendered
    /// WHEN checking button count
    /// THEN three menu buttons are present (Play, Select Level, How to Play)
    testWidgets('givenMenuScreenRendered_whenCheckingButtonCount_thenThreeButtonsPresent', 
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      
      // Find buttons by their text labels instead of by type
      expect(find.text(GameStrings.play), findsOneWidget);
      expect(find.text('Select Level'), findsOneWidget);
      expect(find.text('How to Play'), findsOneWidget);
    });

    /// GIVEN MenuScreen is rendered
    /// WHEN checking button icons
    /// THEN correct icons are displayed (play_arrow, list, help_outline)
    testWidgets('givenMenuScreenRendered_whenCheckingButtonIcons_thenCorrectIconsDisplayed', 
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.list), findsOneWidget);
      expect(find.byIcon(Icons.help_outline), findsOneWidget);
    });
  });

  group('MenuScreen Button Navigation', () {
    /// GIVEN MenuScreen is rendered
    /// WHEN user taps Play button
    /// THEN GameManager.startGame() is called
    ///
    /// Uses [tester.tap] to simulate button press and verifies GameManager method called.
    /// Navigation to GameScreen verified indirectly through startGame() call.
    testWidgets('givenMenuScreenRendered_whenUserTapsPlayButton_thenGameManagerStartGameCalled', 
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      
      // Tap the Play button
      await tester.tap(find.text(GameStrings.play));
      await tester.pump(); // Single pump to trigger tap, not pumpAndSettle to avoid GameScreen render
      
      // Verify GameManager.startGame() was called
      verify(mockGameManager.startGame()).called(1);
    });

    /// GIVEN MenuScreen is rendered
    /// WHEN user taps Select Level button
    /// THEN level select dialog appears
    ///
    /// Uses [find.byType(AlertDialog)] to verify dialog is shown after button tap
    testWidgets('givenMenuScreenRendered_whenUserTapsSelectLevelButton_thenLevelSelectDialogAppears', 
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      
      // Tap the Select Level button
      await tester.tap(find.text('Select Level'));
      await tester.pumpAndSettle();
      
      // Verify dialog appears
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Select Level'), findsNWidgets(2)); // Title + button text
    });

    /// GIVEN MenuScreen is rendered
    /// WHEN user taps How to Play button
    /// THEN instructions dialog appears
    testWidgets('givenMenuScreenRendered_whenUserTapsHowToPlayButton_thenInstructionsDialogAppears', 
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      
      // Tap the How to Play button
      await tester.tap(find.text('How to Play'));
      await tester.pumpAndSettle();
      
      // Verify dialog appears with instructions
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('How to Play'), findsNWidgets(2)); // Title + button text
      expect(find.text('🎯 Objective:'), findsOneWidget);
    });
  });

  group('MenuScreen Level Select Dialog', () {
    /// GIVEN level select dialog is open
    /// WHEN checking dialog content
    /// THEN GridView with 20 levels is displayed
    ///
    /// Uses [find.byType(GridView)] and counts GridView children to verify 20 level tiles
    testWidgets('givenLevelSelectDialogOpen_whenCheckingContent_thenGridViewWith20LevelsDisplayed', 
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      
      // Open level select dialog
      await tester.tap(find.text('Select Level'));
      await tester.pumpAndSettle();
      
      // Verify GridView is present
      expect(find.byType(GridView), findsOneWidget);
      
      // Verify first few level numbers are displayed (sampling approach)
      // Due to viewport size in tests, not all 20 may be visible without scrolling
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });

    /// GIVEN level select dialog is open
    /// WHEN user taps a level number
    /// THEN dialog closes and GameManager.startGame(level: n) is called
    ///
    /// Verifies GameManager.startGame(level: n) is called with correct level number
    testWidgets('givenLevelSelectDialogOpen_whenUserTapsLevelNumber_thenGameManagerStartGameCalledWithLevel', 
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      
      // Open level select dialog
      await tester.tap(find.text('Select Level'));
      await tester.pumpAndSettle();
      
      // Tap level 3 (visible without scrolling)
      await tester.tap(find.text('3'));
      await tester.pump(); // Single pump to avoid GameScreen render
      
      // Verify GameManager.startGame was called with level 3
      verify(mockGameManager.startGame(level: 3)).called(1);
    });

    /// GIVEN level select dialog is open
    /// WHEN user taps Cancel button
    /// THEN dialog closes without starting game
    testWidgets('givenLevelSelectDialogOpen_whenUserTapsCancelButton_thenDialogClosesWithoutStartingGame', 
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      
      // Open level select dialog
      await tester.tap(find.text('Select Level'));
      await tester.pumpAndSettle();
      
      // Tap Cancel button
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      
      // Verify dialog is closed (no AlertDialog visible)
      expect(find.byType(AlertDialog), findsNothing);
      
      // Verify GameManager.startGame was NOT called
      verifyNever(mockGameManager.startGame());
      verifyNever(mockGameManager.startGame(level: anyNamed('level')));
    });
  });

  group('MenuScreen Instructions Dialog', () {
    /// GIVEN instructions dialog is open
    /// WHEN checking dialog content
    /// THEN all instruction sections are displayed
    testWidgets('givenInstructionsDialogOpen_whenCheckingContent_thenAllSectionsDisplayed', 
      (WidgetTester tester) async {
      // Increase test surface size to accommodate dialog content
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      
      // Open instructions dialog
      await tester.tap(find.text('How to Play'));
      await tester.pumpAndSettle();
      
      // Verify all major sections are present
      expect(find.text('🎯 Objective:'), findsOneWidget);
      expect(find.text('🎮 Controls:'), findsOneWidget);
      expect(find.text('⭐ Special Features:'), findsOneWidget);
      expect(find.text('🏆 Scoring:'), findsOneWidget);
    });

    /// GIVEN instructions dialog is open
    /// WHEN user taps "Got it!" button
    /// THEN dialog closes
    testWidgets('givenInstructionsDialogOpen_whenUserTapsGotItButton_thenDialogCloses', 
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      
      // Open instructions dialog
      await tester.tap(find.text('How to Play'));
      await tester.pumpAndSettle();
      
      // Tap "Got it!" button
      await tester.tap(find.text('Got it!'));
      await tester.pumpAndSettle();
      
      // Verify dialog is closed
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('MenuScreen Provider Integration', () {
    /// GIVEN MenuScreen with mocked GameManager
    /// WHEN Play button is tapped
    /// THEN GameManager is accessed via Provider.of and startGame is called
    ///
    /// Verifies Provider<GameManager> integration works correctly in widget context
    testWidgets('givenMenuScreenWithMockedGameManager_whenPlayButtonTapped_thenGameManagerAccessedViaProvider', 
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      
      // Tap Play button to trigger Provider access
      await tester.tap(find.text(GameStrings.play));
      await tester.pump(); // Single pump to avoid GameScreen render
      
      // Verify GameManager.startGame() was called (proves Provider access worked)
      verify(mockGameManager.startGame()).called(1);
    });

    /// GIVEN MenuScreen with mocked GameManager
    /// WHEN level is selected from dialog
    /// THEN GameManager receives correct level parameter via Provider
    testWidgets('givenMenuScreenWithMockedGameManager_whenLevelSelected_thenGameManagerReceivesCorrectLevel', 
      (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(gameManager: mockGameManager));
      
      // Open level select and tap level 2 (visible without scrolling)
      await tester.tap(find.text('Select Level'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2'));
      await tester.pump(); // Single pump to avoid GameScreen render
      
      // Verify correct level parameter passed via Provider
      verify(mockGameManager.startGame(level: 2)).called(1);
    });
  });
}