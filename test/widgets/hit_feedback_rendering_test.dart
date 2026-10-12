import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pachinko_game/models/level.dart';
import 'package:pachinko_game/models/peg.dart';
import 'package:pachinko_game/services/game_manager.dart';
import 'package:pachinko_game/utils/constants.dart';
import 'package:pachinko_game/widgets/board_effects.dart';
import 'package:pachinko_game/widgets/floating_text.dart';
import 'package:pachinko_game/widgets/pachinko_board.dart';

/// What the board draws when something is hit: a gold ring on a pin, a slot
/// lit in its tier colour, and a score popup that stays inside the board.
void main() {
  List<Invocation> recorded(TestRecordingCanvas canvas, [Symbol? name]) =>
      canvas.invocations
          .map((entry) => entry.invocation)
          .where((invocation) => name == null || invocation.memberName == name)
          .toList();

  int rgb(Color colour) => colour.toARGB32() & 0xFFFFFF;

  Future<CustomPainter> pumpBoard(
      WidgetTester tester, GameManager manager) async {
    manager.startGame();
    await tester.pumpWidget(ChangeNotifierProvider<GameManager>.value(
      value: manager,
      child: const MaterialApp(home: Scaffold(body: PachinkoBoard())),
    ));
    await tester.pump(const Duration(milliseconds: 50));
    return tester
        .widget<CustomPaint>(find.descendant(
            of: find.byType(PachinkoBoard), matching: find.byType(CustomPaint)))
        .painter!;
  }

  group('Peg hit', () {
    testWidgets(
        'given a pin that has just been hit, then a gold ring spreads from it and it glows; at rest again, nothing is drawn',
        (tester) async {
      final manager = GameManager();
      addTearDown(manager.dispose);
      final painter = await pumpBoard(tester, manager);
      final pin = manager.gameState.currentLevel!.pegs
          .firstWhere((peg) => peg.type == PegType.normal);
      final centre = Offset(pin.position.x, pin.position.y);
      List<Invocation> atPin() {
        final canvas = TestRecordingCanvas();
        painter.paint(canvas, const Size(400, 600));
        return recorded(canvas, #drawCircle)
            .where((circle) => circle.positionalArguments[0] == centre)
            .toList();
      }

      pin.onHit();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      final hit = atPin();
      Paint paintOf(Invocation circle) =>
          circle.positionalArguments[2] as Paint;
      double radiusOf(Invocation circle) =>
          circle.positionalArguments[1] as double;

      final rings =
          hit.where((circle) => paintOf(circle).style == PaintingStyle.stroke);
      expect(rings, hasLength(1));
      expect(
          rgb(paintOf(rings.single).color), rgb(GameConstants.specialPegColor));
      expect(radiusOf(rings.single), greaterThan(pin.radius));
      expect(
        hit.where((circle) =>
            paintOf(circle).style == PaintingStyle.fill &&
            paintOf(circle).shader == null &&
            radiusOf(circle) > pin.radius),
        isEmpty,
        reason: 'no flat disc over the pin',
      );
      expect(
        hit.where((circle) =>
            paintOf(circle).shader != null && radiusOf(circle) > pin.radius),
        hasLength(1),
        reason: 'a glow for the moment of the hit',
      );

      await tester.pump(const Duration(seconds: 1));
      expect(pin.isAnimating, isFalse);
      expect(atPin(), isEmpty);
    });
  });

  group('Slot lighting', () {
    Level level(int number) => Level.generate(
        number, GameConstants.boardWidth, GameConstants.boardHeight);

    test(
        'given a lit slot, then its pocket is filled with its tier colour as strongly as it is lit, with its value on top',
        () {
      final level1 = level(1);
      final slot = level1.slots[3];
      slot.glow = 0.5;
      final canvas = TestRecordingCanvas();

      paintSlotLights(canvas, level1.slots);

      final fill = recorded(canvas, #drawRRect).single;
      final paint = fill.positionalArguments[1] as Paint;
      expect((fill.positionalArguments[0] as RRect).outerRect, slot.bounds);
      expect(rgb(paint.color), rgb(slot.color));
      final full = () {
        slot.glow = 1.0;
        final again = TestRecordingCanvas();
        paintSlotLights(again, level1.slots);
        return (recorded(again, #drawRRect).single.positionalArguments[1]
                as Paint)
            .color
            .a;
      }();
      expect(paint.color.a, closeTo(full / 2, 0.01));
      expect(recorded(canvas, #drawParagraph), hasLength(1));
    });

    test('given no slot is lit, then nothing is drawn', () {
      final canvas = TestRecordingCanvas();

      paintSlotLights(canvas, level(1).slots);

      expect(recorded(canvas), isEmpty);
    });

    testWidgets(
        'given a game, when a slot is lit, then the board draws its light',
        (tester) async {
      final manager = GameManager();
      addTearDown(manager.dispose);
      final painter = await pumpBoard(tester, manager);
      final slot = manager.gameState.currentLevel!.slots[0];
      bool lit() {
        final canvas = TestRecordingCanvas();
        painter.paint(canvas, const Size(400, 600));
        return recorded(canvas, #drawRRect).any((call) =>
            (call.positionalArguments[0] as RRect).outerRect == slot.bounds &&
            rgb((call.positionalArguments[1] as Paint).color) ==
                rgb(slot.color));
      }

      expect(lit(), isFalse);
      slot.glow = 1.0;
      expect(lit(), isTrue);
    });
  });

  group('Score popup', () {
    ui.Paragraph popup(double x, double fontSize, {String text = '+2000'}) {
      final canvas = TestRecordingCanvas();
      paintScorePopup(canvas,
          text: text,
          centreTop: Offset(x, 400),
          colour: GameConstants.magentaColor,
          fontSize: fontSize,
          opacity: 1);
      final call = recorded(canvas, #drawParagraph).single;
      final at = call.positionalArguments[1] as Offset;
      final paragraph = call.positionalArguments[0] as ui.Paragraph;
      expect(at.dx, greaterThanOrEqualTo(0), reason: 'left edge at x = $x');
      expect(at.dx + paragraph.longestLine,
          lessThanOrEqualTo(GameConstants.boardWidth),
          reason: 'right edge at x = $x');
      return paragraph;
    }

    test('given popups over the edge slots, then they stay inside the board',
        () {
      // The 2000 slots are the outermost and their popups the largest
      final size = FloatingText.sizeFor(2000);
      popup(28.6, size);
      popup(371.4, size);
      popup(200, size);
    });

    test(
        'given a small and a large score, then the larger is drawn in larger type',
        () {
      expect(FloatingText.sizeFor(50), lessThan(FloatingText.sizeFor(200)));
      expect(FloatingText.sizeFor(200), lessThan(FloatingText.sizeFor(1000)));
      expect(FloatingText.sizeFor(1000), lessThan(FloatingText.sizeFor(2000)));
      expect(
        popup(200, FloatingText.sizeFor(2000), text: '+50').height,
        greaterThan(popup(200, FloatingText.sizeFor(50), text: '+50').height),
      );
    });

    testWidgets(
        'given a popup on the board, then the board draws it at its own size',
        (tester) async {
      final manager = GameManager();
      addTearDown(manager.dispose);
      final painter = await pumpBoard(tester, manager);
      double popupHeight(double fontSize) {
        manager.gameState.addFloatingText(
            '+50', const Offset(200, 300), GameConstants.slateColor,
            fontSize: fontSize);
        final canvas = TestRecordingCanvas();
        painter.paint(canvas, const Size(400, 600));
        final call = recorded(canvas, #drawParagraph).lastWhere(
            (text) => (text.positionalArguments[1] as Offset).dy == 300);
        manager.gameState.resetLevel();
        return (call.positionalArguments[0] as ui.Paragraph).height;
      }

      expect(popupHeight(32), greaterThan(popupHeight(16)));
    });
  });

  group('Bonus announcement', () {
    /// A paragraph does not give its text back, and the overlay's are
    /// disposed once drawn, so the announcement is told apart by where its
    /// lines are put: each is centred, so a longer line starts further left.
    /// "+15 BALLS!" and "+105 BALLS!" differ by a character, and level 200
    /// is where the uncapped formula (5 + 200 ~/ 2 = 105) and the cap part.
    List<Offset> lines(TestRecordingCanvas canvas) => [
          for (final call in recorded(canvas, #drawParagraph))
            call.positionalArguments[1] as Offset
        ];

    testWidgets(
        'given the bonus on level 200, then the board announces the 15 balls the game drops, not 105',
        (tester) async {
      final manager = GameManager();
      addTearDown(manager.dispose);
      final painter = await pumpBoard(tester, manager);
      manager.selectLevel(200);
      await tester.pump();
      manager.gameState.triggerSpecialBonus();
      expect(manager.gameState.activeBalls, hasLength(15));

      List<Offset> announcing(int balls) {
        final canvas = TestRecordingCanvas();
        paintBonusOverlay(canvas,
            opacity: manager.gameState.bonusOverlayOpacity, bonusBalls: balls);
        return lines(canvas);
      }

      final board = TestRecordingCanvas();
      painter.paint(board, const Size(400, 600));
      // The announcement's timer must not outlive the test
      manager.gameState.resetLevel();

      expect(announcing(15), isNot(announcing(105)),
          reason: 'the two announcements must differ for this test to tell');
      expect(lines(board), containsAll(announcing(15)));
      expect(lines(board), isNot(containsAll(announcing(105))));
    });
  });
}
