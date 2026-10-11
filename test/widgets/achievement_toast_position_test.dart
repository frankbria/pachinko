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
/// The overlay is installed above the Navigator, as in `main.dart`, so one
/// position has to work on every screen. The tests measure the real widgets on
/// a phone-sized screen with the game's theme.
void main() {
  late MockGameManager mockGameManager;
  late MockGameState mockGameState;
  late MockBallLauncher mockBallLauncher;

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

  /// Pumps [screen] under the toast overlay, shows a toast and waits for its
  /// slide-in to finish. Returns the toast's rectangle on screen.
  Future<Rect> showToastOver(WidgetTester tester, Widget screen) async {
    // A phone in portrait; wide enough for the header in the test font
    tester.view.physicalSize = const Size(480, 854);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

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

    final toast = tester.getRect(find.byType(AchievementToast));

    // Let the toast dismiss itself so no timer outlives the test
    addTearDown(() async {
      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(seconds: 1));
    });
    return toast;
  }

  testWidgets('given the game screen, when a toast is showing, then the score, ball count and level stay uncovered',
      (tester) async {
    // When
    final toast = await showToastOver(tester, const GameScreen());

    // Then: every header value and label is clear of the toast
    for (final text in [
      '12345',
      GameStrings.score,
      '20',
      GameStrings.ballsRemaining,
      '1',
      GameStrings.level,
    ]) {
      final rect = tester.getRect(find.text(text));
      expect(toast.overlaps(rect), isFalse, reason: 'the toast $toast covers "$text" at $rect');
    }
  });

  testWidgets('given the game screen, when a toast is showing, then it sits directly below the header',
      (tester) async {
    // When
    final toast = await showToastOver(tester, const GameScreen());

    // Then: no higher than the lowest header label, and not far down the board
    final headerBottom = tester.getRect(find.text(GameStrings.ballsRemaining)).bottom;
    expect(toast.top, greaterThanOrEqualTo(headerBottom));
    expect(toast.top, lessThan(headerBottom + 40));
  });

  testWidgets('given the game screen, when a toast is showing, then the controls stay uncovered',
      (tester) async {
    // When
    final toast = await showToastOver(tester, const GameScreen());

    // Then
    expect(toast.overlaps(tester.getRect(find.byIcon(Icons.arrow_back))), isFalse);
    expect(toast.overlaps(tester.getRect(find.byIcon(Icons.restart_alt))), isFalse);
  });

  testWidgets('given the menu screen, when a toast is showing, then the menu buttons stay uncovered',
      (tester) async {
    // When
    final toast = await showToastOver(tester, const MenuScreen());

    // Then
    for (final label in [GameStrings.play, 'Select Level', 'How to Play', 'High Scores', 'Achievements']) {
      final rect = tester.getRect(find.text(label));
      expect(toast.overlaps(rect), isFalse, reason: 'the toast $toast covers "$label" at $rect');
    }
  });
}
