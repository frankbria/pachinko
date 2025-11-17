import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pachinko_game/main.dart' as app;
import 'package:pachinko_game/screens/menu_screen.dart';
import 'package:pachinko_game/screens/game_screen.dart';
import 'package:pachinko_game/utils/constants.dart';

/// Integration tests for basic app launch and navigation functionality.
///
/// These tests verify that the app launches correctly, displays the menu screen,
/// and supports basic navigation to the game screen.
///
/// Key differences from unit/widget tests:
/// - Uses real Provider setup (no mocks)
/// - Tests full widget tree integration
/// - Verifies actual app behavior in a simulated environment
/// - Uses IntegrationTestWidgetsFlutterBinding for integration context
///
/// All tests follow Given-When-Then naming pattern for clarity.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Launch Tests', () {
    /// GIVEN app is launched
    /// WHEN app initializes
    /// THEN app builds without errors and displays MaterialApp
    testWidgets('givenAppLaunched_whenAppInitializes_thenAppBuildsWithoutErrors',
      (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Verify MaterialApp is present
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    /// GIVEN app is launched
    /// WHEN MenuScreen displays
    /// THEN title and play button are present
    ///
    /// Verifies that the initial screen shows the app name and main navigation.
    testWidgets('givenAppLaunched_whenMenuDisplays_thenTitleAndButtonsPresent',
      (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify MenuScreen is displayed
      expect(find.byType(MenuScreen), findsOneWidget);

      // Verify app title
      expect(find.text(GameStrings.appName), findsOneWidget);

      // Verify main buttons
      expect(find.text(GameStrings.play), findsOneWidget);
      expect(find.text('Select Level'), findsOneWidget);
      expect(find.text('How to Play'), findsOneWidget);
    });
  });

  group('Navigation Tests', () {
    /// GIVEN app is on MenuScreen
    /// WHEN user taps play button
    /// THEN GameScreen is displayed
    ///
    /// Tests navigation from menu to game using real Provider and GameManager.
    testWidgets('givenMenuScreen_whenUserTapsPlayButton_thenGameScreenDisplays',
      (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify starting on MenuScreen
      expect(find.byType(MenuScreen), findsOneWidget);

      // Tap play button
      await tester.tap(find.text(GameStrings.play));
      await tester.pumpAndSettle();

      // Verify GameScreen is now displayed
      expect(find.byType(GameScreen), findsOneWidget);
      expect(find.byType(MenuScreen), findsNothing);
    });

    /// GIVEN app is on GameScreen
    /// WHEN user taps back button
    /// THEN MenuScreen is displayed again
    testWidgets('givenGameScreen_whenUserTapsBackButton_thenMenuScreenDisplays',
      (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to game
      await tester.tap(find.text(GameStrings.play));
      await tester.pumpAndSettle();
      expect(find.byType(GameScreen), findsOneWidget);

      // Tap back button
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Verify back on MenuScreen
      expect(find.byType(MenuScreen), findsOneWidget);
      expect(find.byType(GameScreen), findsNothing);
    });

    /// GIVEN app is on MenuScreen
    /// WHEN user opens level select dialog and selects level 3
    /// THEN GameScreen displays with level 3 loaded
    ///
    /// Tests level selection flow using real game state.
    testWidgets('givenMenuScreen_whenUserSelectsLevel3_thenGameScreenDisplaysLevel3',
      (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Open level select dialog
      await tester.tap(find.text('Select Level'));
      await tester.pumpAndSettle();

      // Verify dialog is open
      expect(find.byType(AlertDialog), findsOneWidget);

      // Select level 3
      await tester.tap(find.text('3'));
      await tester.pumpAndSettle();

      // Verify on GameScreen with level 3
      expect(find.byType(GameScreen), findsOneWidget);
      expect(find.text('3'), findsWidgets); // Level number displayed in HUD
    });
  });
}
