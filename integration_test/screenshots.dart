import 'dart:ui' as ui;
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
    (screenshots as List<dynamic>).add(<String, dynamic>{'screenshotName': name, 'bytes': bytes});
  }

  testWidgets('screenshots of the menu, four levels and one full round', (tester) async {
    app.main();
    await settle(tester);
    await capture(tester, '01-menu');

    await tester.ensureVisible(find.text(GameStrings.settings));
    await tester.tap(find.text(GameStrings.settings));
    await settle(tester);
    await capture(tester, '02-settings');
    await tester.pageBack();
    await settle(tester);

    await tester.tap(find.text(GameStrings.play));
    await settle(tester);
    final gameManager =
        Provider.of<GameManager>(tester.element(find.byType(GameScreen)), listen: false);

    for (final level in [9, 3, 2, 1]) {
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

    int launched = 0;
    while (gameManager.gameState.ballsRemaining > 0) {
      await pumpUntil(tester, () => gameManager.gameState.canLaunchBall,
          what: 'the launcher to be ready for ball ${launched + 1}');
      await dragLauncher(tester, 60 + 10.0 * (launched % 5));
      launched++;
      if (launched == 5) {
        // Just after the ball leaves the launch channel; a fixed wait can
        // outlast a fast ball
        await pumpUntil(tester, () => gameManager.ballLauncher.currentBall == null,
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
      await pumpUntil(tester, () => gameManager.gameState.activeBalls.isEmpty,
          timeout: const Duration(seconds: 60), what: 'ball $launched to land');
      if (launched == 3) {
        // The slot is still lit and its popup still rising
        await tester.pump(const Duration(milliseconds: 150));
        await capture(tester, 'level-1-slot-lit');
      }
    }
    await settle(tester);
    await capture(tester, 'level-1-round-over');
  }, timeout: const Timeout(Duration(minutes: 15)));
}
