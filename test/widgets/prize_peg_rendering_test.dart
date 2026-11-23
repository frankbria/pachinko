import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vector_math/vector_math_64.dart' show Vector2;
import 'package:pachinko_game/models/ball.dart';
import 'package:pachinko_game/models/game_settings.dart';
import 'package:pachinko_game/models/peg.dart';
import 'package:pachinko_game/services/game_manager.dart';
import 'package:pachinko_game/utils/constants.dart';
import 'package:pachinko_game/widgets/pachinko_board.dart';

/// How the board draws a prize peg before and after it is collected. A prize
/// has to read as a prize: gold, haloed and ringed while it is still to win,
/// dim with one thin ring once it has been hit.
///
/// Each test shows the board with a real game and records what the painter
/// draws around one of the level's prize pegs.
void main() {
  Future<CustomPainter> pumpBoard(
      WidgetTester tester, GameManager manager) async {
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

  /// The circles the painter draws centred on [peg], in order.
  List<Invocation> circlesAt(CustomPainter painter, Peg peg) {
    final canvas = TestRecordingCanvas();
    painter.paint(canvas, const Size(400, 600));
    final centre = Offset(peg.position.x, peg.position.y);
    return canvas.invocations
        .map((recorded) => recorded.invocation)
        .where((invocation) =>
            invocation.memberName == #drawCircle &&
            invocation.positionalArguments[0] == centre)
        .toList();
  }

  double radiusOf(Invocation circle) => circle.positionalArguments[1] as double;
  Paint paintOf(Invocation circle) => circle.positionalArguments[2] as Paint;
  bool isRing(Invocation circle) =>
      paintOf(circle).style == PaintingStyle.stroke;
  bool isGold(Paint paint) =>
      paint.color.toARGB32() & 0xFFFFFF ==
      GameConstants.specialPegColor.toARGB32() & 0xFFFFFF;

  testWidgets(
      'given a prize peg still to win, then it is a sphere with a halo and two gold rings',
      (tester) async {
    final manager = GameManager();
    addTearDown(manager.dispose);
    final painter = await pumpBoard(tester, manager);
    final prize = manager.gameState.currentLevel!.specialPegs.first;
    await tester.pump(const Duration(milliseconds: 200));

    final drawn = circlesAt(painter, prize);
    final body = drawn
        .where((circle) => radiusOf(circle) == prize.radius && !isRing(circle));
    final halo = drawn.where((circle) =>
        !isRing(circle) &&
        radiusOf(circle) > prize.radius &&
        paintOf(circle).shader != null);
    final rings = drawn.where(isRing).toList();

    expect(body, hasLength(2), reason: 'the two gradient passes of a sphere');
    // A prize still to win is a light. A shadow showing through its halo
    // would read as a dark ring (the "holes, not prizes" of the review)
    final canvas = TestRecordingCanvas();
    painter.paint(canvas, const Size(400, 600));
    final centre = Offset(prize.position.x, prize.position.y);
    final shadows =
        canvas.invocations.map((recorded) => recorded.invocation).where((call) {
      if (call.memberName != #drawCircle) return false;
      final at = call.positionalArguments[0] as Offset;
      return at.dx > centre.dx &&
          at.dy > centre.dy &&
          (at - centre).distance < prize.radius;
    });
    expect(shadows, isEmpty,
        reason: 'no shadow down and to the right of a glowing prize');
    expect(halo, hasLength(1), reason: 'a soft halo wider than the peg');
    expect(drawn.indexOf(halo.single), lessThan(drawn.indexOf(body.first)),
        reason: 'the halo is behind the peg');

    expect(rings, hasLength(2));
    expect(
        rings.every(
            (ring) => isGold(paintOf(ring)) && radiusOf(ring) > prize.radius),
        isTrue);
    rings.sort((a, b) => radiusOf(a).compareTo(radiusOf(b)));
    expect(paintOf(rings.last).color.a, lessThan(paintOf(rings.first).color.a),
        reason: 'the outer ring is the fainter one');
  });

  testWidgets(
      'given a prize peg that has been collected, then it has one thin ring and no halo',
      (tester) async {
    final manager = GameManager();
    addTearDown(manager.dispose);
    final painter = await pumpBoard(tester, manager);
    final prize = manager.gameState.currentLevel!.specialPegs.first;

    prize.onHit();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 1));
    expect(prize.isAnimating, isFalse, reason: 'the hit flash is over');

    final drawn = circlesAt(painter, prize);
    final rings = drawn.where(isRing);

    expect(
        drawn.where(
            (circle) => radiusOf(circle) == prize.radius && !isRing(circle)),
        hasLength(2));
    expect(
        drawn.where(
            (circle) => !isRing(circle) && radiusOf(circle) > prize.radius),
        isEmpty,
        reason: 'no halo and no glow disc');
    // No longer a light: it sits on the board and casts a shadow like a pin
    final canvas = TestRecordingCanvas();
    painter.paint(canvas, const Size(400, 600));
    final centre = Offset(prize.position.x, prize.position.y);
    final shadows =
        canvas.invocations.map((recorded) => recorded.invocation).where((call) {
      if (call.memberName != #drawCircle) return false;
      final at = call.positionalArguments[0] as Offset;
      return at.dx > centre.dx &&
          at.dy > centre.dy &&
          (at - centre).distance < prize.radius;
    });
    expect(shadows, hasLength(1));
    expect(rings, hasLength(1));
    expect(paintOf(rings.single).strokeWidth, lessThanOrEqualTo(1.5));
    expect(isGold(paintOf(rings.single)), isTrue);
  });

  testWidgets(
      'given a prize peg whose shimmer has moved on, then its halo and rings have changed strength',
      (tester) async {
    // The shimmer is advanced by the board's ticker; paint only reads it
    final manager = GameManager();
    addTearDown(manager.dispose);
    final painter = await pumpBoard(tester, manager);
    final prize = manager.gameState.currentLevel!.specialPegs.first;
    double ringStrength() =>
        paintOf(circlesAt(painter, prize).firstWhere(isRing)).color.a;

    await tester.pump(const Duration(milliseconds: 100));
    final before = ringStrength();
    await tester.pump(const Duration(milliseconds: 600));

    expect(ringStrength(), isNot(closeTo(before, 0.001)));
    expect(ringStrength(), closeTo(ringStrength(), 1e-9),
        reason: 'painting again does not move it');
  });

  testWidgets('given confetti in the air, then the board draws every piece',
      (tester) async {
    final manager = GameManager();
    addTearDown(manager.dispose);
    final painter = await pumpBoard(tester, manager);
    manager.gameState.spawnConfetti(Vector2(200, 300), 12);

    final canvas = TestRecordingCanvas();
    painter.paint(canvas, const Size(400, 600));

    // Each piece is turned to its own angle before it is drawn
    expect(
        canvas.invocations
            .where((recorded) => recorded.invocation.memberName == #rotate),
        hasLength(12));
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets(
      'given the bonus, then its overlay is under the bonus balls and the confetti',
      (tester) async {
    // Drawn over them, the scrim and the glow would muddy their colours
    final manager = GameManager();
    addTearDown(manager.dispose);
    final painter = await pumpBoard(tester, manager);
    manager.gameState.triggerSpecialBonus();
    manager.gameState.spawnConfetti(Vector2(200, 300), 6);
    final ball = manager.gameState.activeBalls.first;

    final canvas = TestRecordingCanvas();
    painter.paint(canvas, const Size(400, 600));
    final drawn =
        canvas.invocations.map((recorded) => recorded.invocation).toList();
    final scrim = drawn.indexWhere((call) =>
        call.memberName == #drawRect &&
        call.positionalArguments[0] ==
            const Rect.fromLTWH(
                0, 0, GameConstants.boardWidth, GameConstants.boardHeight));
    final firstBall = drawn.indexWhere((call) =>
        call.memberName == #drawCircle &&
        call.positionalArguments[0] ==
            Offset(ball.position.x, ball.position.y));
    final firstConfetti =
        drawn.indexWhere((call) => call.memberName == #rotate);

    expect(scrim, isNot(-1));
    expect(scrim, lessThan(firstBall));
    expect(scrim, lessThan(firstConfetti));
    await tester.pump(const Duration(seconds: 4));
  });

  group('reduced motion', () {
    /// The player's choice, or the system's when the player has not chosen:
    /// no confetti, a prize peg whose rings hold still, a short trail.
    Future<(GameManager, CustomPainter)> reducedBoard(WidgetTester tester,
        {bool? chosen, bool system = false}) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: system);
      addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final manager = GameManager();
      addTearDown(manager.dispose);
      await manager.updateSettings((_) => GameSettings(reducedMotion: chosen));
      return (manager, await pumpBoard(tester, manager));
    }

    testWidgets('given it chosen, then no confetti is drawn', (tester) async {
      final (manager, painter) = await reducedBoard(tester, chosen: true);
      manager.gameState.spawnConfetti(Vector2(200, 300), 12);

      final canvas = TestRecordingCanvas();
      painter.paint(canvas, const Size(400, 600));

      expect(
          canvas.invocations
              .where((recorded) => recorded.invocation.memberName == #rotate),
          isEmpty);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets(
        'given the system asks for it, then a prize peg does not shimmer and the board ticker rests',
        (tester) async {
      final (manager, painter) = await reducedBoard(tester, system: true);
      final prize = manager.gameState.currentLevel!.specialPegs.first;
      List<double> ringStrengths() => circlesAt(painter, prize)
          .where(isRing)
          .map((ring) => paintOf(ring).color.a)
          .toList();

      final before = ringStrengths();
      await tester.pump(const Duration(milliseconds: 600));

      expect(before, hasLength(2), reason: 'still a prize, with its rings');
      expect(ringStrengths(), before);
      expect(tester.binding.hasScheduledFrame, isFalse,
          reason: 'nothing on the board is animating');
    });

    testWidgets(
        'given the player turned it off, then the shimmer runs even though the system asks for less motion',
        (tester) async {
      final (manager, painter) =
          await reducedBoard(tester, chosen: false, system: true);
      final prize = manager.gameState.currentLevel!.specialPegs.first;
      double ringStrength() =>
          paintOf(circlesAt(painter, prize).firstWhere(isRing)).color.a;

      await tester.pump(const Duration(milliseconds: 100));
      final before = ringStrength();
      await tester.pump(const Duration(milliseconds: 600));

      expect(ringStrength(), isNot(closeTo(before, 0.001)));
    });

    testWidgets('given it chosen, then a ball trails only its last positions',
        (tester) async {
      // A ball with a full trail behind it, standing still: the trail circles
      // are the ball's colour and no wider than the ball
      final (manager, painter) = await reducedBoard(tester, chosen: true);
      final ball = Ball(position: Vector2(200, 300));
      for (var step = 0; step < Ball.maxTrailLength; step++) {
        ball.position = Vector2(200, 200 + step * 10.0);
        ball.recordTrail();
      }
      ball.position = Vector2(200, 400);
      manager.gameState.launchBall(ball);

      final canvas = TestRecordingCanvas();
      painter.paint(canvas, const Size(400, 600));
      final trailPoints = ball.trail
          .map((point) => Offset(point.x, point.y))
          .where((point) => canvas.invocations.any((recorded) =>
              recorded.invocation.memberName == #drawCircle &&
              recorded.invocation.positionalArguments[0] == point))
          .toList();

      expect(trailPoints, hasLength(reducedMotionTrailLength));
      expect(trailPoints.last, Offset(ball.trail.last.x, ball.trail.last.y));
      manager.stopLoop();
    });
  });
}
