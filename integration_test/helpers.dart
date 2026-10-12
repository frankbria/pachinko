import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:pachinko_game/utils/constants.dart';
import 'package:pachinko_game/widgets/pachinko_board.dart';

/// Lets a screen change finish.
///
/// The game screen never settles while a prize peg shimmers: the board's
/// ticker schedules a frame on every frame, so `pumpAndSettle` would wait for
/// ever. This pumps for a fixed time instead.
Future<void> settle(WidgetTester tester) async {
  for (int i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Launches a ball the way a player does: a drag upward from the launcher,
/// [distance] board pixels long. The board works out the power from the
/// drag's length on screen, so the same [distance] launches harder on a
/// larger board; any drag longer than the touch slop launches a ball.
///
/// The launch point is a board coordinate. On a device the board is scaled
/// and sits somewhere inside the screen, so the point is converted through
/// the board's rectangle; dragging at the raw coordinate misses the launcher.
Future<void> dragLauncher(WidgetTester tester, double distance) async {
  await tester.dragFrom(
      launcherOnScreen(tester), Offset(0, -distance * boardScale(tester)));
  await tester.pump();
}

/// How many screen pixels one board pixel is.
double boardScale(WidgetTester tester) {
  final board = tester.getRect(find.byType(PachinkoBoard));
  return math.min(
    board.width / GameConstants.boardWidth,
    board.height / GameConstants.boardHeight,
  );
}

/// Where the launcher is on the screen.
Offset launcherOnScreen(WidgetTester tester) {
  final scale = boardScale(tester);
  return tester.getRect(find.byType(PachinkoBoard)).topLeft +
      Offset(
        GameConstants.launchChannelStartX * scale,
        GameConstants.launchChannelStartY * scale,
      );
}

/// Pumps frames until [condition] holds. Fails the test if it does not within
/// [timeout].
Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 20),
  String what = 'the condition',
}) async {
  final end = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(end)) {
      fail('Timed out after ${timeout.inSeconds} s waiting for $what');
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
}
