import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pachinko_game/models/level.dart';
import 'package:pachinko_game/services/game_manager.dart';
import 'package:pachinko_game/utils/constants.dart';
import 'package:pachinko_game/widgets/board_effects.dart';
import 'package:pachinko_game/widgets/board_static_layer.dart';
import 'package:pachinko_game/widgets/pachinko_board.dart';

/// What fills the board's empty space since issue #29: a level sign and prize
/// lamps in the dome, light rising from the slots, a tray of ball counts
/// under them, and a launch area that stays inside the board.
///
/// The drawing is recorded call by call; nothing here compares pixels.
void main() {
  List<Invocation> recorded(TestRecordingCanvas canvas, [Symbol? name]) => canvas.invocations
      .map((entry) => entry.invocation)
      .where((invocation) => name == null || invocation.memberName == name)
      .toList();

  Level level(int number) =>
      Level.generate(number, GameConstants.boardWidth, GameConstants.boardHeight);

  const domeCentreX = (GameConstants.topCurveStartX + GameConstants.topCurveEndX) / 2;

  group('Dome sign', () {
    test('given a level, then its sign is centred under the top of the dome, above the pegs', () {
      final level3 = level(3);
      final canvas = TestRecordingCanvas();
      paintBoardStaticLayer(canvas, level3);

      // The slots' values are the other text in the static layer; they are far below
      final signs = recorded(canvas, #drawParagraph)
          .where((text) => (text.positionalArguments[1] as Offset).dy < GameConstants.topCurveStartY);
      final sign = signs.single;
      final paragraph = sign.positionalArguments[0] as ui.Paragraph;
      final at = sign.positionalArguments[1] as Offset;
      final highestPeg = level3.pegs.map((peg) => peg.position.y - peg.radius).reduce((a, b) => a < b ? a : b);

      expect(at.dx + paragraph.longestLine / 2, closeTo(domeCentreX, 1.0));
      expect(at.dy + paragraph.height, lessThan(highestPeg), reason: 'the sign is clear of the pegs');
    });
  });

  group('Prize lamps', () {
    /// For each lamp, left to right: whether it is lit. A lit lamp is a
    /// shaded sphere; an unlit one is a flat dark disc.
    List<bool> lamps(TestRecordingCanvas canvas) {
      final byX = <double, bool>{};
      for (final circle in recorded(canvas, #drawCircle)) {
        final centre = circle.positionalArguments[0] as Offset;
        if (centre.dy != prizeLampRowY) continue;
        final shaded = (circle.positionalArguments[2] as Paint).shader != null;
        byX[centre.dx] = (byX[centre.dx] ?? false) || shaded;
      }
      return [for (final x in byX.keys.toList()..sort()) byX[x]!];
    }

    test('given three prizes and one collected, then three lamps are drawn and the first is lit', () {
      final canvas = TestRecordingCanvas();

      paintPrizeLamps(canvas, total: 3, collected: 1);

      expect(lamps(canvas), [true, false, false]);
    });

    test('given any number of prizes, then the row of lamps is centred in the dome', () {
      for (final total in [2, 3, 4]) {
        final canvas = TestRecordingCanvas();
        paintPrizeLamps(canvas, total: total, collected: 0);
        final xs = recorded(canvas, #drawCircle)
            .map((circle) => (circle.positionalArguments[0] as Offset).dx)
            .toSet()
            .toList()
          ..sort();

        expect(xs, hasLength(total));
        expect((xs.first + xs.last) / 2, closeTo(domeCentreX, 0.001));
      }
    });

    testWidgets('given a game, when prize pegs are collected, then the board lights a lamp for each',
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
      final prizes = manager.gameState.currentLevel!.specialPegs;
      int lit() {
        final canvas = TestRecordingCanvas();
        painter.paint(canvas, const Size(400, 600));
        return lamps(canvas).where((isLit) => isLit).length;
      }

      expect(lit(), 0);
      prizes[0].onHit();
      expect(lit(), 1);
      prizes[1].onHit();
      expect(lit(), 2);
      await tester.pump(const Duration(seconds: 2));
    });
  });

  group('Light spill', () {
    test('given a level, then a soft round glow rises from each slot, drawn before the slot', () {
      // Round and soft-edged: nothing collides here, so nothing may look like a wall
      final level1 = level(1);
      final canvas = TestRecordingCanvas();
      paintBoardStaticLayer(canvas, level1);
      final drawn = recorded(canvas);

      for (final slot in level1.slots) {
        final spill = drawn.indexWhere((call) =>
            call.memberName == #drawCircle &&
            call.positionalArguments[0] == Offset(slot.position.x, slot.top) &&
            (call.positionalArguments[2] as Paint).shader != null);
        final pocket = drawn.indexWhere((call) =>
            call.memberName == #drawRRect &&
            (call.positionalArguments[0] as RRect).center == Offset(slot.position.x, slot.position.y));

        expect(spill, isNot(-1), reason: 'the ${slot.pointValue} slot has a glow');
        expect(spill, lessThan(pocket), reason: 'the glow is behind the slot');
        expect(drawn[spill].positionalArguments[1] as double, greaterThan(slot.width / 2));
      }
    });
  });

  group('Ball counts', () {
    List<Invocation> countsFor(Level level, {required bool inTray}) {
      final canvas = TestRecordingCanvas();
      paintSlotCounts(canvas, level.slots, inTray: inTray);
      return recorded(canvas);
    }

    test('given room under the board, then the counts are in a tray below the slots', () {
      final level1 = level(1);
      level1.slots[0].addBall();
      level1.slots[3].addBall();

      final drawn = countsFor(level1, inTray: true);
      final tray = drawn.where((call) => call.memberName == #drawRRect).single;
      final counts = drawn.where((call) => call.memberName == #drawParagraph);

      expect((tray.positionalArguments[0] as RRect).top, greaterThanOrEqualTo(GameConstants.boardHeight));
      expect(counts, hasLength(2));
      for (final count in counts) {
        expect((count.positionalArguments[1] as Offset).dy, greaterThan(GameConstants.boardHeight));
      }
    });

    test('given no room under the board, then the counts stay inside their slots', () {
      final level1 = level(1);
      level1.slots[0].addBall();

      final drawn = countsFor(level1, inTray: false);
      final count = drawn.where((call) => call.memberName == #drawParagraph).single;
      final at = count.positionalArguments[1] as Offset;
      final paragraph = count.positionalArguments[0] as ui.Paragraph;

      expect(drawn.where((call) => call.memberName == #drawRRect), isEmpty);
      expect(at.dy, greaterThan(level1.slots[0].position.y));
      expect(at.dy + paragraph.height, lessThanOrEqualTo(level1.slots[0].bottom));
    });

    testWidgets('given a tall panel, the board uses the tray; given an exact fit, it does not', (tester) async {
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
      manager.gameState.currentLevel!.slots[2].addBall();
      bool hasTray(Size size) {
        final canvas = TestRecordingCanvas();
        painter.paint(canvas, size);
        return recorded(canvas, #drawRRect)
            .any((call) => (call.positionalArguments[0] as RRect).top >= GameConstants.boardHeight);
      }

      expect(hasTray(const Size(400, 700)), isTrue);
      expect(hasTray(const Size(400, 600)), isFalse);
    });
  });

  group('Inside the board', () {
    testWidgets('given the board at rest, then nothing it draws crosses the left or right edge', (tester) async {
      // The launch area's box used to overhang the right edge and was cut off by the screen
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
      painter.paint(canvas, const Size(400, 700));

      const edge = Rect.fromLTRB(0, -1000, GameConstants.boardWidth, 2000);
      int checked = 0;
      for (final call in recorded(canvas)) {
        Rect? bounds;
        if (call.memberName == #drawRect) {
          bounds = call.positionalArguments[0] as Rect;
        } else if (call.memberName == #drawRRect) {
          bounds = (call.positionalArguments[0] as RRect).outerRect;
        } else if (call.memberName == #drawCircle) {
          bounds = Rect.fromCircle(
            center: call.positionalArguments[0] as Offset,
            radius: call.positionalArguments[1] as double,
          );
        } else if (call.memberName == #drawParagraph) {
          final paragraph = call.positionalArguments[0] as ui.Paragraph;
          final at = call.positionalArguments[1] as Offset;
          bounds = Rect.fromLTWH(at.dx, at.dy, paragraph.longestLine, paragraph.height);
        }
        if (bounds == null) continue;
        checked++;
        expect(bounds.left, greaterThanOrEqualTo(edge.left), reason: '${call.memberName} at $bounds');
        expect(bounds.right, lessThanOrEqualTo(edge.right), reason: '${call.memberName} at $bounds');
      }
      expect(checked, greaterThan(3), reason: 'the launch area, its marker and its label were looked at');
    });
  });

  test('given the static layer of any level, then nothing in it crosses the board\'s edges either', () {
    // The light from the two edge slots is wider than the space beside them
    // and has to be clipped. Bounds are taken inside whatever clip is in force
    const board = Rect.fromLTWH(0, 0, GameConstants.boardWidth, GameConstants.boardHeight);
    for (final number in [1, 2, 3, 9]) {
      final canvas = TestRecordingCanvas();
      paintBoardStaticLayer(canvas, level(number));

      final clips = <Rect?>[null];
      int clipped = 0;
      for (final call in recorded(canvas)) {
        if (call.memberName == #save) {
          clips.add(clips.last);
        } else if (call.memberName == #restore) {
          clips.removeLast();
        } else if (call.memberName == #clipRect) {
          final clip = call.positionalArguments[0] as Rect;
          clips[clips.length - 1] = clips.last?.intersect(clip) ?? clip;
        }
        Rect? bounds;
        if (call.memberName == #drawRect) {
          bounds = call.positionalArguments[0] as Rect;
        } else if (call.memberName == #drawRRect) {
          bounds = (call.positionalArguments[0] as RRect).outerRect;
        } else if (call.memberName == #drawCircle) {
          bounds = Rect.fromCircle(
            center: call.positionalArguments[0] as Offset,
            radius: call.positionalArguments[1] as double,
          );
        }
        if (bounds == null) continue;
        if (clips.last != null) {
          if (!board.contains(bounds.topLeft) || !board.contains(bounds.bottomRight)) clipped++;
          bounds = bounds.intersect(clips.last!);
        }
        expect(bounds.left, greaterThanOrEqualTo(board.left), reason: 'level $number: ${call.memberName} at $bounds');
        expect(bounds.right, lessThanOrEqualTo(board.right), reason: 'level $number: ${call.memberName} at $bounds');
        expect(bounds.bottom, lessThanOrEqualTo(board.bottom), reason: 'level $number: ${call.memberName} at $bounds');
      }
      expect(clipped, greaterThan(0), reason: 'the edge slots\' glows are the case in point');
    }
  });

  test('text painted on the board is at least 12 logical pixels', () {
    final sizes = <String, List<double>>{};
    for (final file in ['pachinko_board.dart', 'board_static_layer.dart', 'board_effects.dart']) {
      final source = File('lib/widgets/$file').readAsStringSync();
      sizes[file] = [
        for (final match in RegExp(r'fontSize:\s*([0-9.]+)').allMatches(source)) double.parse(match.group(1)!),
      ];
    }

    expect(sizes.values.expand((found) => found), isNotEmpty);
    sizes.forEach((file, found) {
      expect(found.where((size) => size < 12), isEmpty, reason: file);
    });
  });
}
