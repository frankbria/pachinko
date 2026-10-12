import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pachinko_game/models/level.dart';
import 'package:pachinko_game/models/peg.dart';
import 'package:pachinko_game/services/game_manager.dart';
import 'package:pachinko_game/utils/constants.dart';
import 'package:pachinko_game/widgets/board_static_layer.dart';
import 'package:pachinko_game/widgets/pachinko_board.dart';

/// The calls of one kind that [canvas] recorded, in the order they were made.
List<Invocation> calls(TestRecordingCanvas canvas, Symbol name) => canvas.invocations
    .map((recorded) => recorded.invocation)
    .where((invocation) => invocation.memberName == name)
    .toList();

void main() {
  Level level(int number) =>
      Level.generate(number, GameConstants.boardWidth, GameConstants.boardHeight);

  /// What the static layer draws for [level], recorded call by call.
  TestRecordingCanvas record(Level level) {
    final canvas = TestRecordingCanvas();
    paintBoardStaticLayer(canvas, level);
    return canvas;
  }

  group('Board static layer - materials', () {
    test('given a level, then the felt covers the board with a gradient', () {
      final felt = calls(record(level(1)), #drawRect).first;

      expect(
        felt.positionalArguments[0],
        const Rect.fromLTWH(0, 0, GameConstants.boardWidth, GameConstants.boardHeight),
      );
      expect((felt.positionalArguments[1] as Paint).shader, isNotNull);
    });

    test('given a level, then every pin is a shaded sphere with its shadow down and to the right', () {
      // One light, up and to the left: the highlight is in the gradient, and
      // the shadow falls on the other side and is drawn before the pin
      final level1 = level(1);
      final circles = calls(record(level1), #drawCircle);
      final pins = level1.pegs.where((peg) => peg.type != PegType.special).toList();
      expect(pins, isNotEmpty);

      for (final pin in pins) {
        final centre = Offset(pin.position.x, pin.position.y);
        final body = circles.indexWhere((circle) =>
            circle.positionalArguments[0] == centre && circle.positionalArguments[1] == pin.radius);
        expect(body, isNot(-1), reason: 'pin at $centre is drawn');
        expect((circles[body].positionalArguments[2] as Paint).shader, isNotNull,
            reason: 'pin at $centre is shaded');

        final shadow = circles.sublist(0, body).any((circle) {
          final at = circle.positionalArguments[0] as Offset;
          return at.dx > centre.dx && at.dy > centre.dy && (at - centre).distance < pin.radius;
        });
        expect(shadow, isTrue, reason: 'pin at $centre has a shadow down and to the right');
      }
    });

    test('given a level, then prize pegs are left to the animated pass', () {
      final level1 = level(1);
      final circles = calls(record(level1), #drawCircle);
      expect(level1.specialPegs, isNotEmpty);

      for (final prize in level1.specialPegs) {
        final centre = Offset(prize.position.x, prize.position.y);
        expect(circles.where((circle) => circle.positionalArguments[0] == centre), isEmpty);
      }
    });

    test('given a level, then every slot is dark glass with a rim in its tier colour', () {
      final level1 = level(1);
      final rects = calls(record(level1), #drawRRect);

      for (final slot in level1.slots) {
        final mine = rects.where((rect) =>
            (rect.positionalArguments[0] as RRect).center == Offset(slot.position.x, slot.position.y));
        final fills = mine
            .map((rect) => rect.positionalArguments[1] as Paint)
            .where((paint) => paint.style == PaintingStyle.fill);
        final rims = mine
            .map((rect) => rect.positionalArguments[1] as Paint)
            .where((paint) => paint.style == PaintingStyle.stroke);

        expect(fills, isNotEmpty);
        expect(fills.every((paint) => paint.color.toARGB32() != slot.color.toARGB32()), isTrue,
            reason: 'the ${slot.pointValue} slot is not filled with its tier colour');
        expect(rims.any((paint) => paint.color.toARGB32() == slot.color.toARGB32()), isTrue,
            reason: 'the ${slot.pointValue} slot has a rim in its tier colour');
      }
    });

    test('given the launch channel, then its inner wall still ends at y = 135', () {
      // The owner rejected a mock-up with this wall rising to the dome: the
      // mouth under the dome looked too narrow for a ball
      final lines = calls(record(level(1)), #drawLine);
      final innerWall = lines.where(
          (line) => (line.positionalArguments[0] as Offset).dx == GameConstants.launchChannelStartX);

      expect(innerWall, isNotEmpty);
      for (final line in innerWall) {
        expect((line.positionalArguments[1] as Offset).dy, 135.0);
      }
    });

    test('the static layer takes its colours from the roles in GameConstants', () {
      final source = File('lib/widgets/board_static_layer.dart').readAsStringSync();

      expect(source, isNot(contains('Colors.')));
      expect(source, isNot(contains(RegExp(r'Color(\.from\w+)?\('))));
    });
  });

  group('Board static layer - cache', () {
    late BoardStaticLayer layer;

    setUp(() {
      layer = BoardStaticLayer();
      BoardStaticLayer.debugBuildCount = 0;
    });

    tearDown(() => layer.dispose());

    test('given the same level, when asked again, then the same picture comes back', () {
      final level1 = level(1);

      final first = layer.pictureFor(level1);
      final second = layer.pictureFor(level1);

      expect(identical(first, second), isTrue);
      expect(BoardStaticLayer.debugBuildCount, 1);
    });

    test('given another level, then the picture is built again', () {
      final first = layer.pictureFor(level(1));
      final second = layer.pictureFor(level(2));

      expect(identical(first, second), isFalse);
      expect(BoardStaticLayer.debugBuildCount, 2);
    });

    test('given it was disposed, when asked again, then it builds a new picture', () {
      final level1 = level(1);
      layer.pictureFor(level1);
      layer.dispose();

      layer.pictureFor(level1);

      expect(BoardStaticLayer.debugBuildCount, 2);
    });
  });

  group('Board painter and the static layer', () {
    /// Shows the board with a game started, so that there is a level to draw.
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

    /// Paints the board once more, outside the frame pipeline.
    void paintAgain(CustomPainter painter) {
      final recorder = ui.PictureRecorder();
      painter.paint(Canvas(recorder), const Size(400, 600));
      recorder.endRecording().dispose();
    }

    testWidgets('given ordinary repaints, then the static layer is not rebuilt', (tester) async {
      final manager = GameManager();
      addTearDown(manager.dispose);
      BoardStaticLayer.debugBuildCount = 0;

      final painter = await pumpBoard(tester, manager);
      expect(BoardStaticLayer.debugBuildCount, 1);

      paintAgain(painter);
      paintAgain(painter);
      await tester.pump(const Duration(milliseconds: 100));

      expect(BoardStaticLayer.debugBuildCount, 1);
    });

    testWidgets('given the level changes, then the static layer is rebuilt once', (tester) async {
      final manager = GameManager();
      addTearDown(manager.dispose);
      BoardStaticLayer.debugBuildCount = 0;
      final painter = await pumpBoard(tester, manager);

      manager.selectLevel(2);
      await tester.pump();
      paintAgain(painter);

      expect(BoardStaticLayer.debugBuildCount, 2);
    });

    testWidgets('given a painted board, then only prize pegs and pins mid-pulse are drawn over the static layer',
        (tester) async {
      final manager = GameManager();
      addTearDown(manager.dispose);
      final painter = await pumpBoard(tester, manager);
      final pegs = manager.gameState.currentLevel!.pegs;
      final pins = pegs.where((peg) => peg.type == PegType.normal).toList();
      pins.first.onHit();
      await tester.pump(const Duration(milliseconds: 100));

      final canvas = TestRecordingCanvas();
      painter.paint(canvas, const Size(400, 600));
      final circles = calls(canvas, #drawCircle);
      bool drawnAt(Peg peg) => circles.any((circle) =>
          circle.positionalArguments[0] == Offset(peg.position.x, peg.position.y) &&
          circle.positionalArguments[1] == peg.radius);
      bool shadowUnder(Peg peg) => circles.any((circle) {
            final at = circle.positionalArguments[0] as Offset;
            final centre = Offset(peg.position.x, peg.position.y);
            return at.dx > centre.dx && at.dy > centre.dy && (at - centre).distance < peg.radius;
          });

      expect(calls(canvas, #drawPicture), hasLength(1));
      expect(drawnAt(pins.first), isTrue, reason: 'the pin that was hit is drawn while it pulses');
      expect(shadowUnder(pins.first), isTrue);
      expect(drawnAt(pins.last), isFalse, reason: 'a pin at rest is only in the static layer');
      for (final prize in pegs.where((peg) => peg.type == PegType.special)) {
        expect(drawnAt(prize), isTrue);
        expect(shadowUnder(prize), isFalse, reason: 'a glowing peg has no shadow over its glow');
      }
    });

    testWidgets('given a slot that has caught a ball, then its count is drawn over the static layer',
        (tester) async {
      // The count changes during a level, so it cannot be in the picture
      final manager = GameManager();
      addTearDown(manager.dispose);
      final painter = await pumpBoard(tester, manager);
      final slots = manager.gameState.currentLevel!.slots;
      int countsDrawn() {
        final canvas = TestRecordingCanvas();
        painter.paint(canvas, const Size(400, 600));
        return calls(canvas, #drawParagraph)
            .where((text) => slots.any((slot) => (text.positionalArguments[1] as Offset).dy == slot.position.y + 15))
            .length;
      }

      expect(countsDrawn(), 0);
      BoardStaticLayer.debugBuildCount = 0;

      slots[0].addBall();
      slots[3].addBall();

      expect(countsDrawn(), 2);
      expect(BoardStaticLayer.debugBuildCount, 0, reason: 'a ball landing does not rebuild the static layer');
    });

    testWidgets('given pegs mid-animation, when the board is painted twice, then their animation has not moved',
        (tester) async {
      final manager = GameManager();
      addTearDown(manager.dispose);
      final painter = await pumpBoard(tester, manager);
      final pegs = manager.gameState.currentLevel!.pegs;
      pegs.firstWhere((peg) => peg.type == PegType.normal).onHit();
      await tester.pump(const Duration(milliseconds: 100));

      List<List<Object>> animationState() => [
            for (final peg in pegs) [peg.isAnimating, peg.pulseProgress, peg.shimmerIntensity],
          ];
      final before = animationState();
      expect(before.any((state) => state[1] != 0.0), isTrue, reason: 'a pulse is under way');
      expect(before.any((state) => state[2] != 0.0), isTrue, reason: 'a shimmer is under way');

      paintAgain(painter);
      paintAgain(painter);

      expect(animationState(), before);
    });
  });
}
