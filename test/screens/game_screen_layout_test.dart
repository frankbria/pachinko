import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pachinko_game/screens/game_screen.dart';
import 'package:pachinko_game/services/game_manager.dart';
import 'package:pachinko_game/utils/constants.dart';
import 'package:pachinko_game/utils/game_theme.dart';
import 'package:pachinko_game/widgets/pachinko_board.dart';

/// How the game screen divides a phone's height between the header, the
/// board's panel and the controls.
///
/// Measured on a Pixel 7's screen (412 x 915 logical pixels), with the real
/// theme and a real game.
void main() {
  /// Heights of the header and of the board's panel before issue #29, when
  /// the header was three stacked icon, value and label columns.
  const headerBefore = 120.0;
  const panelBefore = 694.3;

  Future<void> pumpGameScreen(WidgetTester tester, {int score = 0}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    final manager = GameManager();
    addTearDown(manager.dispose);
    manager.startGame();
    manager.gameState.addScore(score);
    await tester.pumpWidget(ChangeNotifierProvider<GameManager>.value(
      value: manager,
      child: MaterialApp(theme: buildGameTheme(), home: const GameScreen()),
    ));
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('given a Pixel 7 screen, then the header is one row and the board panel is taller than before',
      (tester) async {
    await pumpGameScreen(tester);

    final header = tester.getSize(find.byType(SizeChangedLayoutNotifier));
    final panel = tester.getSize(find.byType(PachinkoBoard));

    expect(header.height, lessThan(headerBefore / 2));
    expect(panel.height, greaterThan(panelBefore + 50));

    // One row: the three tiles sit side by side, and inside each the label
    // and the value are on one line
    final labels = [GameStrings.score, GameStrings.ballsRemaining, GameStrings.level];
    final rows = labels.map((label) => tester.getCenter(find.text(label)).dy).toSet();
    expect(rows, hasLength(1));
    expect(tester.getCenter(find.text('20')).dy, closeTo(rows.single, 4), reason: 'the ball count beside its label');
  });

  testWidgets('given a score of six digits, then it still fits its tile', (tester) async {
    await pumpGameScreen(tester, score: 123456);

    expect(tester.takeException(), isNull);
    expect(find.text('123456'), findsOneWidget);
    final tile = tester.getRect(find.ancestor(of: find.text('123456'), matching: find.byType(AnimatedContainer)));
    expect(tester.getRect(find.text('123456')).right, lessThanOrEqualTo(tile.right));
  });
}
