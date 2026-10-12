import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:vector_math/vector_math_64.dart' show Vector2;
import 'package:pachinko_game/main.dart' as app;
import 'package:pachinko_game/screens/game_screen.dart';
import 'package:pachinko_game/services/game_manager.dart';
import 'package:pachinko_game/utils/constants.dart';

import 'helpers.dart';

/// Takes screenshots of the game running on a device, for a pull request that
/// changes how it looks: the menu, levels 1, 2, 3 and 9, and one full round
/// with the bonus set off half way through.
///
/// This is not one of the integration tests. Its name does not end in
/// `_test`, so `flutter test integration_test` skips it. Run it with:
///
///     flutter drive --driver=test_driver/integration_test.dart \
///       --target=integration_test/screenshots.dart -d <device>
///
/// The images are written to `build/screenshots/` on the host.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Captures the frame the app has just drawn, at the device's resolution,
  /// and hands it to the driver under [name].
  ///
  /// The frame is read from the render tree, as golden tests do, and not with
  /// `binding.takeScreenshot`: that needs the Android surface converted to an
  /// image view first, which changes how the app is rendered.
  Future<void> capture(WidgetTester tester, String name) async {
    final view = tester.binding.renderViews.first;
    final layer = view.debugLayer! as OffsetLayer;
    final bytes = await tester.runAsync(() async {
      final image = await layer.toImage(view.paintBounds);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data!.buffer.asUint8List();
    });
    final report = binding.reportData ??= <String, dynamic>{};
    final screenshots = report['screenshots'] ??= <dynamic>[];
    (screenshots as List<dynamic>)
        .add(<String, dynamic>{'screenshotName': name, 'bytes': bytes});
  }

  /// Opens the screen behind the menu button [label], captures it as [name]
  /// and comes back.
  Future<void> openFromMenu(
      WidgetTester tester, String label, String name) async {
    await toastsGone(tester);
    await tester.ensureVisible(find.text(label));
    await tester.tap(find.text(label));
    await settle(tester);
    await toastsGone(tester);
    await capture(tester, name);
    await tester.pageBack();
    await settle(tester);
  }

  testWidgets('screenshots of the menu, four levels and one full round',
      (tester) async {
    app.main();
    await settle(tester);
    await capture(tester, '01-menu');

    await tester.ensureVisible(find.text(GameStrings.settings));
    await tester.tap(find.text(GameStrings.settings));
    await settle(tester);
    await capture(tester, '02-settings');
    await tester.pageBack();
    await settle(tester);

    // The screens around the game, before anything has been played
    await tester.tap(find.text('Select Level'));
    await settle(tester);
    await capture(tester, '03-level-picker-unplayed');
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    await tester.tap(find.text('How to Play'));
    await settle(tester);
    await capture(tester, '04-how-to-play');
    await tester.tap(find.text('Got it!'));
    await settle(tester);
    await openFromMenu(tester, 'High Scores', '05-high-scores-empty');
    await openFromMenu(tester, 'Achievements', '06-achievements-locked');

    await tester.tap(find.text(GameStrings.play));
    await settle(tester);
    final gameManager = Provider.of<GameManager>(
        tester.element(find.byType(GameScreen)),
        listen: false);

    // Levels 1, 6, 11 and 16 are the first of each band of colours
    for (final level in [16, 11, 9, 6, 3, 2, 1]) {
      gameManager.startGame(level: level);
      await settle(tester);
      await capture(tester, 'level-$level-ready');
    }

    // One full round on level 1, which the loop above left loaded. First one
    // prize peg is marked as hit, to show a collected prize beside two that
    // are still to win
    gameManager.gameState.currentLevel!.specialPegs.first.onHit();
    await tester.pump(const Duration(milliseconds: 1200));
    await capture(tester, 'level-1-prize-collected');

    // The launcher at three powers: a drag held and then released. The board
    // takes power as half the drag's length in screen pixels
    final down = launcherOnScreen(tester);
    final drag = await tester.startGesture(down);
    for (final percent in [25, 50, 100]) {
      await drag.moveTo(down - Offset(0, 2.0 * percent));
      await tester.pump(const Duration(milliseconds: 100));
      await capture(tester, 'launcher-$percent');
    }
    await drag.up();
    await pumpUntil(tester, () => gameManager.gameState.activeBalls.isEmpty,
        timeout: const Duration(seconds: 60),
        what: 'the full-power ball to land');

    int launched = 0;
    while (gameManager.gameState.ballsRemaining > 0) {
      await pumpUntil(tester, () => gameManager.gameState.canLaunchBall,
          what: 'the launcher to be ready for ball ${launched + 1}');
      await dragLauncher(tester, 60 + 10.0 * (launched % 5));
      launched++;
      if (launched == 5) {
        // Just after the ball leaves the launch channel; a fixed wait can
        // outlast a fast ball
        await pumpUntil(
            tester, () => gameManager.ballLauncher.currentBall == null,
            what: 'ball $launched to leave the channel');
        await tester.pump(const Duration(milliseconds: 300));
        await capture(tester, 'level-1-ball-in-play');
      }
      if (launched == 10) {
        // The bonus needs every prize peg hit, which a scripted round cannot
        // count on, so it is set off directly, with the confetti the game
        // throws when it is earned
        // Every prize peg collected is what earns it, and what the round
        // summary reports
        for (final peg in gameManager.gameState.currentLevel!.specialPegs) {
          peg.onHit();
        }
        gameManager.gameState.triggerSpecialBonus();
        gameManager.gameState.spawnConfetti(
          Vector2(GameConstants.boardWidth / 2, GameConstants.boardHeight / 2),
          50,
        );
        await tester.pump(const Duration(milliseconds: 350));
        await capture(tester, 'level-1-bonus-overlay');
        await tester.pump(const Duration(milliseconds: 550));
        await capture(tester, 'level-1-bonus-balls');
      }
      if (launched == 12) {
        // A ball in the right 2,000 slot cannot be counted on, so this one
        // is set down just above it once it has left the channel. Its popup
        // rises where the launcher's hint is written, and the hint steps
        // aside
        await pumpUntil(
            tester, () => gameManager.ballLauncher.currentBall == null,
            what: 'ball $launched to leave the channel');
        final slot = gameManager.gameState.currentLevel!.slots.last;
        final ball = gameManager.gameState.activeBalls.single;
        ball.position.setValues(slot.position.x, slot.top - 30);
        ball.velocity.setZero();
      }
      await pumpUntil(tester, () => gameManager.gameState.activeBalls.isEmpty,
          timeout: const Duration(seconds: 60), what: 'ball $launched to land');
      if (launched == 3 || launched == 12) {
        // The slot is still lit and its popup still rising
        await tester.pump(const Duration(milliseconds: 150));
        await capture(tester,
            launched == 3 ? 'level-1-slot-lit' : 'level-1-edge-slot-lit');
      }
    }
    await settle(tester);
    await capture(tester, 'level-1-round-over');

    // Back on the menu, the same screens with a round behind them. The
    // round's achievements are announced first: a toast would take the taps
    await toastsGone(tester);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await settle(tester);
    await openFromMenu(tester, 'High Scores', '07-high-scores-filled');
    await openFromMenu(tester, 'Achievements', '08-achievements-unlocked');
    await tester.ensureVisible(find.text('Select Level'));
    await tester.tap(find.text('Select Level'));
    await settle(tester);
    await capture(tester, '09-level-picker-played');
  }, timeout: const Timeout(Duration(minutes: 15)));
}
