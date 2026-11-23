import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pachinko_game/models/game_settings.dart';
import 'package:pachinko_game/models/ball_launcher.dart';
import 'package:pachinko_game/models/game_state.dart';
import 'package:pachinko_game/screens/game_screen.dart';
import 'package:pachinko_game/services/game_manager.dart';
import 'package:pachinko_game/services/storage_service.dart';
import 'package:pachinko_game/utils/constants.dart';
import 'package:pachinko_game/widgets/first_round_hints.dart';
import 'package:pachinko_game/widgets/pachinko_board.dart';

import '../screens/menu_screen_test.mocks.dart';

/// The first round teaches the game (#111): a ghost hand shows the drag on
/// the plunger until the first launch on the install, a callout says what
/// the prize pegs are for at the first prize peg hit, and the game screen
/// opens How to Play. The game screen never settles while a prize peg
/// shimmers, so these tests pump for fixed times instead of pumpAndSettle.
void main() {
  /// Where the board's launch hint is written, in board pixels from the top.
  const hintTop = GameConstants.launchChannelStartY + 25;

  /// A game manager on a fresh start of the app, over [prefs] as stored so
  /// far, its first level started.
  GameManager startApp(SharedPreferences prefs) {
    final manager = GameManager(storageService: StorageService(prefs: prefs))
      ..startGame();
    addTearDown(manager.dispose);
    return manager;
  }

  Future<void> showBoard(WidgetTester tester, GameManager manager) async {
    await tester.pumpWidget(ChangeNotifierProvider<GameManager>.value(
      value: manager,
      child: const MaterialApp(home: Scaffold(body: PachinkoBoard())),
    ));
    await tester.pump(const Duration(milliseconds: 50));
  }

  /// Whether the board, painted now, writes the launch hint.
  bool hintDrawn(WidgetTester tester) {
    final painter = tester
        .widget<CustomPaint>(find.descendant(
            of: find.byType(PachinkoBoard), matching: find.byType(CustomPaint)))
        .painter!;
    final canvas = TestRecordingCanvas();
    painter.paint(canvas, const Size(400, 600));
    return canvas.invocations.any((call) =>
        call.invocation.memberName == #drawParagraph &&
        (call.invocation.positionalArguments[1] as Offset).dy == hintTop);
  }

  group('The ghost hand', () {
    testWidgets(
        'given a first install, then it shows in place of the written hint, and after a launch it is gone, also after a restart',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final manager = startApp(prefs);
      await showBoard(tester, manager);

      expect(find.byType(GhostHand), findsOneWidget);
      expect(hintDrawn(tester), isFalse,
          reason: 'the hand pulls the plunger down across the hint');

      // The test surface is 800 x 600, so the board is drawn at its own size
      await tester.dragFrom(const Offset(375, 470), const Offset(0, -100));
      await tester.pump();
      manager.stopLoop();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(GhostHand), findsNothing);
      expect(hintDrawn(tester), isTrue);

      // The app starts again over the same storage
      await tester.pumpWidget(const SizedBox());
      final restarted = startApp(prefs);
      await showBoard(tester, restarted);
      expect(find.byType(GhostHand), findsNothing);
      expect(hintDrawn(tester), isTrue);
    });

    testWidgets(
        'given a first install, when the player holds the plunger and the app restarts before a launch, then the hand is back',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final manager = startApp(prefs);
      await showBoard(tester, manager);

      final gesture = await tester.startGesture(const Offset(375, 470));
      await gesture.moveBy(const Offset(0, 30));
      await tester.pump();
      expect(manager.ballLauncher.phase, LaunchPhase.charging);
      expect(find.byType(GhostHand), findsNothing,
          reason: 'it loops only until the player touches the plunger');

      await tester.pumpWidget(const SizedBox());
      await gesture.cancel();
      final restarted = startApp(prefs);
      await showBoard(tester, restarted);
      expect(find.byType(GhostHand), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets(
        'given the hand showing, then it starts on the plunger, pulls down and comes back',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await showBoard(tester, startApp(await SharedPreferences.getInstance()));
      double handTop() => tester.getTopLeft(find.byIcon(Icons.touch_app)).dy;

      final atRest = handTop();
      await tester.pump(GhostHand.cycle ~/ 2);
      final pulled = handTop();
      await tester.pump(GhostHand.cycle ~/ 2);

      expect(
          atRest,
          closeTo(
              GameConstants.launchChannelStartY + GameConstants.ballRadius, 1));
      expect(pulled - atRest, closeTo(GhostHand.pull, 1));
      expect(handTop(), closeTo(atRest, 1));
      expect(tester.getRect(find.byIcon(Icons.touch_app)).right,
          lessThanOrEqualTo(GameConstants.boardWidth),
          reason: 'nothing the board draws crosses its edge');
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('The prize peg callout', () {
    late MockGameManager manager;

    setUp(() {
      manager = MockGameManager();
      when(manager.showsLaunchHint).thenReturn(false);
      when(manager.prizePegHint).thenReturn(4);
      when(manager.settings).thenReturn(const GameSettings());
    });

    Future<void> showHints(WidgetTester tester, {double scale = 1.0}) =>
        tester.pumpWidget(ChangeNotifierProvider<GameManager>.value(
          value: manager,
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: GameConstants.boardWidth * scale,
                height: GameConstants.boardHeight * scale,
                child: FirstRoundHints(scale: scale),
              ),
            ),
          ),
        ));

    testWidgets(
        'given the first prize peg hit, then it gives the level\'s real count, in board text of at least 12 px, inside the board',
        (tester) async {
      await showHints(tester, scale: 0.9);
      await tester.pump(const Duration(milliseconds: 500));

      final text = find.text(GameStrings.prizePegHint(4));
      expect(text, findsOneWidget);
      expect(
          tester.widget<Text>(text).style!.fontSize, greaterThanOrEqualTo(12));
      final rect = tester.getRect(find.byType(PrizePegCallout).first);
      final board = tester.getRect(find.byType(FirstRoundHints));
      final callout = tester.getRect(
          find.ancestor(of: text, matching: find.byType(Container)).first);
      expect(callout.left, greaterThanOrEqualTo(board.left));
      expect(callout.right, lessThanOrEqualTo(board.right));
      expect(callout.top, greaterThanOrEqualTo(rect.top));
      await tester.pump(PrizePegCallout.duration);
    });

    testWidgets(
        'given the callout, then it fades in, stays, fades out and asks the manager to take it down',
        (tester) async {
      await showHints(tester);
      double opacity() => tester
          .widget<FadeTransition>(find.descendant(
              of: find.byType(PrizePegCallout),
              matching: find.byType(FadeTransition)))
          .opacity
          .value;

      expect(opacity(), 0.0);
      await tester.pump(const Duration(seconds: 2));
      expect(opacity(), 1.0);
      verifyNever(manager.dismissPrizePegHint());

      await tester.pump(const Duration(seconds: 2));
      expect(opacity(), 0.0);
      // The controller's clock starts on the frame after the callout appears
      await tester.pump(const Duration(milliseconds: 20));
      verify(manager.dismissPrizePegHint()).called(1);
    });
  });

  group('How to Play from the game screen', () {
    testWidgets(
        'given a ball in play, when the help button is pressed, then the game pauses, How to Play opens, and the game is still paused once it closes',
        (tester) async {
      final manager = GameManager()..startGame();
      addTearDown(manager.dispose);
      await tester.pumpWidget(ChangeNotifierProvider<GameManager>.value(
        value: manager,
        child: const MaterialApp(home: GameScreen()),
      ));
      manager.startLaunchCharging();
      manager.updateLaunchPower(60);
      manager.launchBall();
      await tester.pump(const Duration(milliseconds: 200));
      expect(manager.gameState.phase, GamePhase.playing);

      await tester.tap(find.byTooltip(GameStrings.howToPlay));
      await tester.pump(const Duration(milliseconds: 400));
      expect(manager.gameState.isPaused, isTrue);
      expect(find.text(GameStrings.howToPlay), findsWidgets);
      expect(find.text('Got it!'), findsOneWidget);

      await tester.tap(find.text('Got it!'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Got it!'), findsNothing);
      expect(manager.gameState.isPaused, isTrue);
      expect(manager.isRunning, isFalse);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets(
        'given no ball in play, when the help button is pressed, then How to Play opens and nothing is paused',
        (tester) async {
      final manager = GameManager()..startGame();
      addTearDown(manager.dispose);
      await tester.pumpWidget(ChangeNotifierProvider<GameManager>.value(
        value: manager,
        child: const MaterialApp(home: GameScreen()),
      ));

      await tester.tap(find.byTooltip(GameStrings.howToPlay));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Got it!'), findsOneWidget);
      expect(manager.gameState.isPaused, isFalse);
      expect(manager.gameState.canLaunchBall, isTrue);
      await tester.tap(find.text('Got it!'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpWidget(const SizedBox());
    });
  });
}
