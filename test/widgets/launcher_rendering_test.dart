import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pachinko_game/models/ball_launcher.dart';
import 'package:pachinko_game/models/level.dart';
import 'package:pachinko_game/services/game_manager.dart';
import 'package:pachinko_game/utils/constants.dart';
import 'package:pachinko_game/widgets/board_effects.dart';
import 'package:pachinko_game/widgets/pachinko_board.dart';

/// The launcher since issue #31: the launch channel is the power meter. It
/// fills with light from the plunger upward as the player drags, and nothing
/// about launch power is drawn over the pegs.
void main() {
  List<Invocation> recorded(TestRecordingCanvas canvas, [Symbol? name]) => canvas.invocations
      .map((entry) => entry.invocation)
      .where((invocation) => name == null || invocation.memberName == name)
      .toList();

  /// The bounds of everything [canvas] drew that has bounds.
  List<Rect> boundsOf(TestRecordingCanvas canvas) => [
        for (final call in recorded(canvas))
          if (call.memberName == #drawRect)
            call.positionalArguments[0] as Rect
          else if (call.memberName == #drawRRect)
            (call.positionalArguments[0] as RRect).outerRect
          else if (call.memberName == #drawCircle)
            Rect.fromCircle(
              center: call.positionalArguments[0] as Offset,
              radius: call.positionalArguments[1] as double,
            )
          else if (call.memberName == #drawParagraph)
            Rect.fromLTWH(
              (call.positionalArguments[1] as Offset).dx,
              (call.positionalArguments[1] as Offset).dy,
              (call.positionalArguments[0] as ui.Paragraph).longestLine,
              (call.positionalArguments[0] as ui.Paragraph).height,
            ),
      ];

  TestRecordingCanvas power(double ratio) {
    final canvas = TestRecordingCanvas();
    paintLaunchPower(canvas, ratio);
    return canvas;
  }

  /// The lit part of the channel at [ratio]: the union of its gradient rects.
  Rect? fill(double ratio) {
    final rects = recorded(power(ratio), #drawRect)
        .where((call) => (call.positionalArguments[1] as Paint).shader != null)
        .map((call) => call.positionalArguments[0] as Rect);
    return rects.isEmpty ? null : rects.reduce((a, b) => a.expandToInclude(b));
  }

  const channelLeft = GameConstants.launchChannelStartX;
  const channelRight = GameConstants.launchChannelStartX + GameConstants.launchChannelWidth;

  test('given any power from 0 to 100, then nothing drawn for it overlaps a peg on any level', () {
    final pegs = [
      for (int n = 1; n <= 60; n++)
        for (final peg in Level.generate(n, GameConstants.boardWidth, GameConstants.boardHeight).pegs)
          Rect.fromCircle(center: Offset(peg.position.x, peg.position.y), radius: peg.radius),
    ];

    for (int percent = 0; percent <= 100; percent += 5) {
      for (final drawn in boundsOf(power(percent / 100))) {
        expect(pegs.any(drawn.overlaps), isFalse, reason: 'at $percent%, $drawn');
        expect(drawn.left, greaterThanOrEqualTo(0));
        expect(drawn.right, lessThanOrEqualTo(GameConstants.boardWidth));
      }
    }
  });

  test('given more power, then the light rises from the plunger, inside the channel', () {
    final quarter = fill(0.25)!;
    final half = fill(0.5)!;
    final full = fill(1.0)!;

    expect(half.top, lessThan(quarter.top));
    expect(full.top, lessThan(half.top));
    for (final lit in [quarter, half, full]) {
      expect(lit.bottom, quarter.bottom, reason: 'it always starts at the plunger');
      expect(lit.left, greaterThanOrEqualTo(channelLeft));
      expect(lit.right, lessThanOrEqualTo(channelRight));
    }
    expect(fill(0.0), isNull, reason: 'no power, no light');
  });

  test('given full power, then the light stops at the top of the inner wall', () {
    // The wall's top is y = 135 and stays there (issue #26)
    expect(fill(1.0)!.top, 135.0);
    expect(fill(1.5)!.top, 135.0, reason: 'more than full is drawn as full');
  });

  test('given the ramp, then it runs cyan, violet, magenta with no muddy middle', () {
    expect(launchPowerColour(0.0), GameConstants.cyanColor);
    expect(launchPowerColour(0.5), GameConstants.violetColor);
    expect(launchPowerColour(1.0), GameConstants.magentaColor);
    for (int percent = 0; percent <= 100; percent += 5) {
      final colour = HSVColor.fromColor(launchPowerColour(percent / 100));
      expect(colour.saturation, greaterThan(0.3), reason: 'at $percent%');
      expect(colour.value, greaterThan(0.8), reason: 'at $percent%');
    }
  });

  test('given the ramp is two gradients, then low power draws one and high power both', () {
    // Each gradient has two colours; a three-colour one aborts the CI emulator (#26)
    int gradients(double ratio) => recorded(power(ratio), #drawRect)
        .where((call) => (call.positionalArguments[1] as Paint).shader != null)
        .length;

    expect(gradients(0.25), 1);
    expect(gradients(0.5), 1);
    expect(gradients(0.75), 2);
    expect(gradients(1.0), 2);
  });

  test('given the launcher, then the hint says what to do next', () {
    expect(launchHintFor(LaunchPhase.ready), 'Drag the plunger to launch');
    expect(launchHintFor(LaunchPhase.charging), 'Release to launch');
  });

  testWidgets('given the board at rest, then a plunger is drawn under the resting ball and no power light',
      (tester) async {
    final manager = GameManager();
    addTearDown(manager.dispose);
    manager.startGame();
    await tester.pumpWidget(ChangeNotifierProvider<GameManager>.value(
      value: manager,
      child: const MaterialApp(home: Scaffold(body: PachinkoBoard())),
    ));
    await tester.pump(const Duration(milliseconds: 50));
    final painter = tester
        .widget<CustomPaint>(find.descendant(of: find.byType(PachinkoBoard), matching: find.byType(CustomPaint)))
        .painter!;
    final canvas = TestRecordingCanvas();
    painter.paint(canvas, const Size(400, 600));
    final level = manager.gameState.currentLevel!;
    final ballBottom = level.launchY + GameConstants.ballRadius;

    final plunger = recorded(canvas, #drawRRect).map((call) => (call.positionalArguments[0] as RRect).outerRect).where(
        (rect) => rect.top >= ballBottom - 1 && rect.left >= channelLeft && rect.right <= channelRight);
    expect(plunger, isNotEmpty);
    expect(
      recorded(canvas, #drawRect).where((call) => (call.positionalArguments[1] as Paint).shader != null),
      isEmpty,
    );
  });

  testWidgets('given a drag in progress, then the board lights the channel to the launcher\'s power', (tester) async {
    final manager = GameManager();
    addTearDown(manager.dispose);
    manager.startGame();
    await tester.pumpWidget(ChangeNotifierProvider<GameManager>.value(
      value: manager,
      child: const MaterialApp(home: Scaffold(body: PachinkoBoard())),
    ));
    await tester.pump(const Duration(milliseconds: 50));

    // The test surface is 800 x 600, so the board is drawn at its own size
    final gesture = await tester.startGesture(const Offset(375, 470));
    await gesture.moveBy(const Offset(0, -30));
    await gesture.moveBy(const Offset(0, -70));
    await tester.pump();
    final painter = tester
        .widget<CustomPaint>(find.descendant(of: find.byType(PachinkoBoard), matching: find.byType(CustomPaint)))
        .painter!;
    final canvas = TestRecordingCanvas();
    painter.paint(canvas, const Size(400, 600));
    final ratio = manager.ballLauncher.launchPower / manager.ballLauncher.maxPower;

    expect(ratio, greaterThan(0.2));
    final lit = recorded(canvas, #drawRect)
        .where((call) => (call.positionalArguments[1] as Paint).shader != null)
        .map((call) => call.positionalArguments[0] as Rect)
        .reduce((a, b) => a.expandToInclude(b));
    expect(lit, fill(ratio));
    await gesture.up();
    // The release launches a ball; stop the loop it started before the test ends
    manager.stopLoop();
    await tester.pump(const Duration(milliseconds: 100));
  });
}
