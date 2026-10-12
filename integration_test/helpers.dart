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
/// [distance] board pixels long (the length sets the power).
///
/// The launch point is a board coordinate. On a device the board is scaled
/// and sits somewhere inside the screen, so the point is converted through
/// the board's rectangle; dragging at the raw coordinate misses the launcher.
Future<void> dragLauncher(WidgetTester tester, double distance) async {
  final board = tester.getRect(find.byType(PachinkoBoard));
  final scale = math.min(
    board.width / GameConstants.boardWidth,
    board.height / GameConstants.boardHeight,
  );
  final launcher = board.topLeft +
      Offset(
        GameConstants.launchChannelStartX * scale,
        GameConstants.launchChannelStartY * scale,
      );
  await tester.dragFrom(launcher, Offset(0, -distance * scale));
  await tester.pump();
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
