import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart' show Vector2;
import 'package:pachinko_game/models/confetti_particle.dart';
import 'package:pachinko_game/models/game_state.dart';
import 'package:pachinko_game/utils/constants.dart';
import 'package:pachinko_game/widgets/board_effects.dart';

/// The calls of one kind that [canvas] recorded, in the order they were made.
List<Invocation> calls(TestRecordingCanvas canvas, Symbol name) =>
    canvas.invocations
        .map((recorded) => recorded.invocation)
        .where((invocation) => invocation.memberName == name)
        .toList();

void main() {
  int rgb(Color colour) => colour.toARGB32() & 0xFFFFFF;

  group('Bonus overlay', () {
    test(
        'given the overlay fully shown, then a dark scrim covers the board under a gold glow and the text',
        () {
      final canvas = TestRecordingCanvas();

      paintBonusOverlay(canvas, opacity: 1.0, bonusBalls: 5);

      final scrim = calls(canvas, #drawRect).single;
      expect(
        scrim.positionalArguments[0],
        const Rect.fromLTWH(
            0, 0, GameConstants.boardWidth, GameConstants.boardHeight),
      );
      final scrimPaint = scrim.positionalArguments[1] as Paint;
      expect(rgb(scrimPaint.color), rgb(GameConstants.cabinetColor));
      expect(scrimPaint.color.a, inInclusiveRange(0.3, 0.8),
          reason: 'the board stays visible through it');

      final glow = calls(canvas, #drawCircle).single;
      expect((glow.positionalArguments[2] as Paint).shader, isNotNull);
      expect(calls(canvas, #drawParagraph), isNotEmpty);
    });

    test('given the overlay half faded, then the scrim is half as strong', () {
      double scrimAlpha(double opacity) {
        final canvas = TestRecordingCanvas();
        paintBonusOverlay(canvas, opacity: opacity, bonusBalls: 5);
        return (calls(canvas, #drawRect).single.positionalArguments[1] as Paint)
            .color
            .a;
      }

      expect(scrimAlpha(0.5), closeTo(scrimAlpha(1.0) / 2, 0.01));
      expect(scrimAlpha(0.0), 0.0);
    });
  });

  group('Confetti', () {
    ConfettiParticle piece(double size,
            {Color colour = GameConstants.goldColor}) =>
        ConfettiParticle(
          position: Vector2(100, 100),
          velocity: Vector2.zero(),
          color: colour,
          size: size,
        );

    test(
        'given pieces of different sizes, then they are discs, diamonds and streamers, never plain rectangles',
        () {
      Set<Symbol> shapes(double size) {
        final canvas = TestRecordingCanvas();
        paintConfettiPiece(canvas, piece(size));
        return canvas.invocations
            .map((recorded) => recorded.invocation.memberName)
            .where((name) =>
                name == #drawCircle ||
                name == #drawPath ||
                name == #drawRRect ||
                name == #drawRect)
            .toSet();
      }

      final small = shapes(6.5);
      final medium = shapes(9.0);
      final large = shapes(11.5);

      expect(small.single, isNot(#drawRect));
      expect(medium.single, isNot(#drawRect));
      expect(large.single, isNot(#drawRect));
      expect({small.single, medium.single, large.single}, hasLength(3),
          reason: 'three different shapes');
    });

    test(
        'given a fading piece, then it is drawn in its own colour at its own opacity',
        () {
      final fading = piece(9.0, colour: GameConstants.magentaColor)
        ..lifetime = ConfettiParticle.maxLifetime - 0.25;
      final canvas = TestRecordingCanvas();

      paintConfettiPiece(canvas, fading);

      final drawn = canvas.invocations
          .map((recorded) => recorded.invocation)
          .firstWhere((invocation) => invocation.memberName == #drawPath);
      final paint = drawn.positionalArguments[1] as Paint;
      expect(rgb(paint.color), rgb(GameConstants.magentaColor));
      expect(paint.color.a, closeTo(0.5, 0.01));
    });

    test(
        'given confetti spawned by the game, then every piece is in a palette colour',
        () {
      final state = GameState()..startNewGame();

      state.spawnConfetti(Vector2(200, 300), 60);

      final palette = {
        GameConstants.goldColor,
        GameConstants.magentaColor,
        GameConstants.violetColor,
        GameConstants.blueColor,
        GameConstants.cyanColor,
      }.map(rgb).toSet();
      final used = state.confettiParticles
          .map((particle) => rgb(particle.color))
          .toSet();
      expect(used.difference(palette), isEmpty);
      expect(used.length, greaterThan(1), reason: 'not all one colour');
    });
  });

  test('the effects take their colours from the roles in GameConstants', () {
    final source = File('lib/widgets/board_effects.dart').readAsStringSync();

    expect(source, isNot(contains('Colors.')));
    expect(source, isNot(contains(RegExp(r'Color(\.from\w+)?\('))));
  });
}
