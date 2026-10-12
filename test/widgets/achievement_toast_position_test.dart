import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:pachinko_game/models/achievement.dart';
import 'package:pachinko_game/models/ball_launcher.dart';
import 'package:pachinko_game/models/game_state.dart';
import 'package:pachinko_game/screens/game_screen.dart';
import 'package:pachinko_game/screens/menu_screen.dart';
import 'package:pachinko_game/services/game_manager.dart';
import 'package:pachinko_game/utils/constants.dart';
import 'package:pachinko_game/utils/game_theme.dart';
import 'package:pachinko_game/widgets/achievement_toast.dart';
import 'package:pachinko_game/widgets/achievement_toast_overlay.dart';

// Reuse mocks from menu_screen_test
import '../screens/menu_screen_test.mocks.dart';

/// Where the achievement toast sits on each screen (issue #13).
///
/// The overlay is installed above the Navigator, as in `main.dart`. A toast
/// sits at the top of the screen unless a screen anchors it lower; the game
/// screen anchors it below its score header. The tests measure the real
/// widgets with the game's theme.
void main() {
  late MockGameManager mockGameManager;
  late MockGameState mockGameState;
  late MockBallLauncher mockBallLauncher;

  const headerTexts = [
    '12345',
    GameStrings.score,
    '20',
    GameStrings.ballsRemaining,
    '1',
    GameStrings.level,
  ];
  const menuButtons = [
    GameStrings.play,
    'Select Level',
    'How to Play',
    'High Scores',
    'Achievements',
  ];

  setUp(() {
    mockGameManager = MockGameManager();
    mockGameState = MockGameState();
    mockBallLauncher = MockBallLauncher();

    when(mockGameManager.gameState).thenReturn(mockGameState);
    when(mockGameManager.ballLauncher).thenReturn(mockBallLauncher);

    when(mockGameState.score).thenReturn(12345);
    when(mockGameState.ballsRemaining).thenReturn(20);
    when(mockGameState.currentLevel).thenReturn(null);
    when(mockGameState.currentLevelNumber).thenReturn(1);
    when(mockGameState.activeBalls).thenReturn([]);
    when(mockGameState.canLaunchBall).thenReturn(true);
    when(mockGameState.phase).thenReturn(GamePhase.ready);
    when(mockGameState.floatingTexts).thenReturn([]);
    when(mockGameState.confettiParticles).thenReturn([]);
    when(mockGameState.ballCountHighlighted).thenReturn(false);

    when(mockBallLauncher.phase).thenReturn(LaunchPhase.ready);
    when(mockBallLauncher.currentBall).thenReturn(null);
    when(mockBallLauncher.launchPower).thenReturn(0.0);
  });

  /// Pumps [screen] under the toast overlay on a surface of [size].
  ///
  /// The default is a phone in portrait, wide enough for the header in the
  /// test font.
  Future<GlobalKey<AchievementToastOverlayState>> pumpUnderOverlay(
    WidgetTester tester,
    Widget screen, {
    Size size = const Size(480, 854),
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final overlayKey = GlobalKey<AchievementToastOverlayState>();
    await tester.pumpWidget(
      ChangeNotifierProvider<GameManager>.value(
        value: mockGameManager,
        child: MaterialApp(
          theme: buildGameTheme(),
          builder: (context, child) =>
              AchievementToastOverlay(key: overlayKey, child: child!),
          home: screen,
        ),
      ),
    );
    return overlayKey;
  }

  /// Shows a toast, waits for its slide-in to finish and returns its
  /// rectangle on screen.
  Future<Rect> showToast(
    WidgetTester tester,
    GlobalKey<AchievementToastOverlayState> overlayKey,
  ) async {
    final achievement = Achievement(
      id: 'first_launch',
      name: 'First Launch',
      description: 'Launch your first ball',
      icon: Icons.rocket_launch,
      pointValue: 100,
    )..unlock();
    overlayKey.currentState!.showAchievementToast(achievement);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Let the toast dismiss itself so no timer outlives the test
    addTearDown(() async {
      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(seconds: 1));
    });
    return tester.getRect(find.byType(AchievementToast));
  }

  void expectUncovered(WidgetTester tester, Rect toast, List<String> texts) {
    for (final text in texts) {
      final rect = tester.getRect(find.text(text));
      expect(toast.overlaps(rect), isFalse,
          reason: 'the toast $toast covers "$text" at $rect');
    }
  }

  group('Game screen -', () {
    testWidgets(
        'given a toast is showing, then the score, ball count and level stay uncovered',
        (tester) async {
      final overlayKey = await pumpUnderOverlay(tester, const GameScreen());

      final toast = await showToast(tester, overlayKey);

      expectUncovered(tester, toast, headerTexts);
    });

    testWidgets(
        'given a toast is showing, then it starts exactly where the header ends',
        (tester) async {
      final overlayKey = await pumpUnderOverlay(tester, const GameScreen());

      final toast = await showToast(tester, overlayKey);

      final header = tester.getRect(find.byType(SizeChangedLayoutNotifier));
      expect(toast.top, header.bottom);
      expect(header.bottom,
          greaterThan(AchievementToastOverlayState.defaultTopOffset));
    });

    testWidgets('given a toast is showing, then the controls stay uncovered',
        (tester) async {
      final overlayKey = await pumpUnderOverlay(tester, const GameScreen());

      final toast = await showToast(tester, overlayKey);

      expect(toast.overlaps(tester.getRect(find.byIcon(Icons.arrow_back))),
          isFalse);
      expect(toast.overlaps(tester.getRect(find.byIcon(Icons.restart_alt))),
          isFalse);
    });

    testWidgets(
        'given text at twice its size, when a toast is showing, then the taller header stays uncovered',
        (tester) async {
      // A wide surface, so the larger header text still fits on one row
      final overlayKey = await pumpUnderOverlay(
        tester,
        const GameScreen(),
        size: const Size(900, 1400),
        textScale: 2.0,
      );

      final toast = await showToast(tester, overlayKey);

      expectUncovered(tester, toast, headerTexts);
      expect(toast.top,
          tester.getRect(find.byType(SizeChangedLayoutNotifier)).bottom);
    });

    testWidgets(
        'given the text size changes while the screen is open, when a toast is showing, then it follows the header',
        (tester) async {
      final overlayKey = await pumpUnderOverlay(tester, const GameScreen(),
          size: const Size(900, 1400));
      final before =
          tester.getRect(find.byType(SizeChangedLayoutNotifier)).bottom;

      // When: the player raises the system text size
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      await tester.pump();
      await tester.pump();
      final toast = await showToast(tester, overlayKey);

      // Then
      final after =
          tester.getRect(find.byType(SizeChangedLayoutNotifier)).bottom;
      expect(after, greaterThan(before));
      expect(toast.top, after);
    });

    testWidgets(
        'given the player goes back to the menu, when a toast is showing, then it is at the top again',
        (tester) async {
      final overlayKey = await pumpUnderOverlay(tester, const MenuScreen());
      await tester.tap(find.text(GameStrings.play));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(GameScreen), findsOneWidget);

      // When
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      final toast = await showToast(tester, overlayKey);

      // Then
      expect(find.byType(GameScreen), findsNothing);
      expect(toast.top, AchievementToastOverlayState.defaultTopOffset);
    });
  });

  group('Menu screen -', () {
    testWidgets(
        'given a toast is showing, then it is at the top and the buttons stay uncovered',
        (tester) async {
      final overlayKey = await pumpUnderOverlay(tester, const MenuScreen());

      final toast = await showToast(tester, overlayKey);

      expect(toast.top, AchievementToastOverlayState.defaultTopOffset);
      expectUncovered(tester, toast, menuButtons);
    });

    testWidgets(
        'given a small phone, when a toast is showing, then the buttons stay uncovered',
        (tester) async {
      final overlayKey = await pumpUnderOverlay(tester, const MenuScreen(),
          size: const Size(360, 640));

      final toast = await showToast(tester, overlayKey);

      expectUncovered(tester, toast, menuButtons);
    });
  });

  group('Anchor ownership -', () {
    testWidgets(
        'given a second screen has anchored the toasts, when the first releases, then the second anchor holds',
        (tester) async {
      /// Two game screens overlap for a moment when the player goes back and
      /// straight into a new game: the old one is disposed after the new one
      /// has anchored.
      final overlayKey = await pumpUnderOverlay(tester, const MenuScreen());
      final overlay = overlayKey.currentState!;
      final first = Object();
      final second = Object();

      overlay.anchorToasts(first, 100);
      overlay.anchorToasts(second, 140);
      overlay.releaseToasts(first);
      expect((await showToast(tester, overlayKey)).top, 140);

      overlay.releaseToasts(second);
      await tester.pump();
      expect(
        tester.getRect(find.byType(AchievementToast)).top,
        AchievementToastOverlayState.defaultTopOffset,
      );
    });
  });
}
