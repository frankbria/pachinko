import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vector_math/vector_math_64.dart' show Vector2;
import 'package:pachinko_game/models/ball.dart';
import 'package:pachinko_game/services/game_manager.dart';
import 'package:pachinko_game/utils/constants.dart';
import 'package:pachinko_game/widgets/pachinko_board.dart';

/// How the board draws a ball: a shaded sphere over a glow, with a shadow and
/// a fading trail, so that it is the easiest thing on screen to follow.
///
/// Each test shows the board with a real game, puts a ball where it wants it
/// (the game loop has stopped by then, so the ball stays put) and records
/// what the painter draws.
void main() {
  const at = Offset(200, 300);

  /// Shows the board with a game started and its loop idle, and returns the
  /// painter.
  Future<CustomPainter> pumpBoard(WidgetTester tester, GameManager manager) async {
    manager.startGame();
    await tester.pumpWidget(ChangeNotifierProvider<GameManager>.value(
      value: manager,
      child: const MaterialApp(home: Scaffold(body: PachinkoBoard())),
    ));
    // One tick of the game loop: with nothing in play it then stops itself
    await tester.pump(const Duration(milliseconds: 50));
    return tester
        .widget<CustomPaint>(find.descendant(
          of: find.byType(PachinkoBoard),
          matching: find.byType(CustomPaint),
        ))
        .painter!;
  }

  /// The circles the painter draws, in order.
  List<Invocation> circles(CustomPainter painter) {
    final canvas = TestRecordingCanvas();
    painter.paint(canvas, const Size(400, 600));
    return canvas.invocations
        .map((recorded) => recorded.invocation)
        .where((invocation) => invocation.memberName == #drawCircle)
        .toList();
  }

  Offset centreOf(Invocation circle) => circle.positionalArguments[0] as Offset;
  double radiusOf(Invocation circle) => circle.positionalArguments[1] as double;
  Paint paintOf(Invocation circle) => circle.positionalArguments[2] as Paint;

  Ball ballAt(Offset where, {Color color = GameConstants.ballColor}) =>
      Ball(position: Vector2(where.dx, where.dy), color: color);

  testWidgets('given a ball in play, then it is a shaded sphere over a glow, with a shadow beneath it',
      (tester) async {
    final manager = GameManager();
    addTearDown(manager.dispose);
    final painter = await pumpBoard(tester, manager);
    final ball = ballAt(at);
    manager.gameState.launchBall(ball);

    final drawn = circles(painter);
    bool isBody(Invocation circle) => centreOf(circle) == at && radiusOf(circle) == ball.radius;
    final firstBodyPass = drawn.indexWhere(isBody);

    // Two gradient passes, as for every sphere on the board
    expect(drawn.where(isBody), hasLength(2));
    expect(drawn.where(isBody).every((circle) => paintOf(circle).shader != null), isTrue);

    final glow = drawn.indexWhere((circle) =>
        centreOf(circle) == at && radiusOf(circle) > ball.radius && paintOf(circle).shader != null);
    expect(glow, isNot(-1), reason: 'a glow wider than the ball');
    expect(glow, lessThan(firstBodyPass), reason: 'the glow is under the ball');

    final shadow = drawn.indexWhere((circle) {
      final centre = centreOf(circle);
      return centre.dx > at.dx && centre.dy > at.dy && (centre - at).distance < ball.radius;
    });
    expect(shadow, isNot(-1), reason: 'a shadow down and to the right');
    expect(shadow, lessThan(glow), reason: 'the glow is not darkened by the shadow');
  });

  testWidgets('given a ball that has moved, then its trail fades and shrinks towards the tail', (tester) async {
    final manager = GameManager();
    addTearDown(manager.dispose);
    final painter = await pumpBoard(tester, manager);
    final ball = ballAt(const Offset(200, 200));
    for (int step = 0; step < 5; step++) {
      ball.position = Vector2(200, 200 + step * 15.0);
      ball.recordTrail();
    }
    ball.position = Vector2(at.dx, at.dy);
    manager.gameState.launchBall(ball);

    final drawn = circles(painter);
    final body = drawn.indexWhere((circle) => centreOf(circle) == at && radiusOf(circle) == ball.radius);
    final trail = [
      for (final point in ball.trail) drawn.indexWhere((circle) => centreOf(circle) == Offset(point.x, point.y)),
    ];

    expect(trail, everyElement(isNot(-1)), reason: 'every recorded position is drawn');
    expect(trail.every((index) => index < body), isTrue, reason: 'the trail is behind the ball');
    for (int i = 0; i < trail.length; i++) {
      final paint = paintOf(drawn[trail[i]]);
      expect(paint.shader, isNull);
      expect(paint.color.toARGB32() & 0xFFFFFF, ball.color.toARGB32() & 0xFFFFFF);
      expect(radiusOf(drawn[trail[i]]), lessThan(ball.radius));
      if (i > 0) {
        expect(paint.color.a, greaterThan(paintOf(drawn[trail[i - 1]]).color.a),
            reason: 'newer positions are more opaque');
        expect(radiusOf(drawn[trail[i]]), greaterThan(radiusOf(drawn[trail[i - 1]])),
            reason: 'newer positions are larger');
      }
    }
    expect(paintOf(drawn[trail.last]).color.a, lessThan(0.5), reason: 'the trail never competes with the ball');
  });

  testWidgets('given a bonus ball, then its trail is gold', (tester) async {
    final manager = GameManager();
    addTearDown(manager.dispose);
    final painter = await pumpBoard(tester, manager);
    final ball = ballAt(const Offset(200, 280), color: GameConstants.bonusBallColor)..recordTrail();
    ball.position = Vector2(at.dx, at.dy);
    manager.gameState.launchBall(ball);

    final drawn = circles(painter);
    final tail = drawn.firstWhere((circle) => centreOf(circle) == const Offset(200, 280));

    expect(paintOf(tail).color.toARGB32() & 0xFFFFFF, GameConstants.bonusBallColor.toARGB32() & 0xFFFFFF);
    expect(drawn.where((circle) => centreOf(circle) == at && radiusOf(circle) == ball.radius), hasLength(2));
  });

  testWidgets('given no ball in play, then the launcher shows a flat marker, not a sphere', (tester) async {
    // A ball in flight has to be told apart from the marker at a glance
    final manager = GameManager();
    addTearDown(manager.dispose);
    final painter = await pumpBoard(tester, manager);
    final level = manager.gameState.currentLevel!;
    final marker = Offset(level.launchX, level.launchY);

    final atMarker = circles(painter).where((circle) => centreOf(circle) == marker);

    expect(atMarker, hasLength(1));
    expect(paintOf(atMarker.single).shader, isNull);
  });
}
