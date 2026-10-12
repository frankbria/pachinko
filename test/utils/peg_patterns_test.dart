import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:pachinko_game/models/peg.dart';
import 'package:pachinko_game/utils/constants.dart';
import 'package:pachinko_game/utils/peg_patterns.dart';

void main() {
  const ballDiameter = GameConstants.ballRadius * 2;

  group('leavesRoomForBall -', () {
    final existing = [Peg(position: Vector2(200, 300), radius: 10)];

    test(
        'given a peg whose gap to another is narrower than the minimum, then false',
        () {
      // Radii 10 and 10: the gap is the centre distance minus 20
      final tooClose = Vector2(200 + 20 + GameConstants.minPegGap - 0.5, 300);
      expect(PegPatterns.leavesRoomForBall(existing, tooClose, 10), isFalse);
    });

    test('given a peg whose gap to another is exactly the minimum, then true',
        () {
      final justFits = Vector2(200 + 20 + GameConstants.minPegGap, 300);
      expect(PegPatterns.leavesRoomForBall(existing, justFits, 10), isTrue);
    });

    test('given a peg too close to the left field wall, then false', () {
      const x = GameConstants.fieldLeftBoundaryX + 10 + GameConstants.minPegGap;
      expect(
          PegPatterns.leavesRoomForBall(const [], Vector2(x, 300), 10), isTrue);
      expect(PegPatterns.leavesRoomForBall(const [], Vector2(x - 0.5, 300), 10),
          isFalse);
    });

    test('given a peg too close to the right field wall, then false', () {
      const x =
          GameConstants.fieldRightBoundaryX - 10 - GameConstants.minPegGap;
      expect(
          PegPatterns.leavesRoomForBall(const [], Vector2(x, 300), 10), isTrue);
      expect(PegPatterns.leavesRoomForBall(const [], Vector2(x + 0.5, 300), 10),
          isFalse);
    });

    test('given a peg too close to the curved top boundary, then false', () {
      // Straight below the top of the curve the nearest point of the curve is its apex
      const apexY = 0.25 * GameConstants.topCurveStartY +
          0.5 * GameConstants.topCurveControlY +
          0.25 * GameConstants.topCurveEndY;
      const x = (GameConstants.topCurveStartX + GameConstants.topCurveEndX) / 2;
      const y = apexY + 10 + GameConstants.minPegGap;
      expect(PegPatterns.leavesRoomForBall(const [], Vector2(x, y + 0.5), 10),
          isTrue);
      expect(PegPatterns.leavesRoomForBall(const [], Vector2(x, y - 0.5), 10),
          isFalse);
    });

    test(
        'given pegs just inside and just outside the limit all along the curve, then the limit holds to a fiftieth of a pixel',
        () {
      /// The check walks the curve in steps. A peg whose nearest point on the
      /// curve lies between two steps must be measured as exactly as one whose
      /// nearest point is on a step.
      const p0 = (GameConstants.topCurveStartX, GameConstants.topCurveStartY);
      const p1 =
          (GameConstants.topCurveControlX, GameConstants.topCurveControlY);
      const p2 = (GameConstants.topCurveEndX, GameConstants.topCurveEndY);
      const radius = 10.0;
      // Away from the ends, where the side walls would decide instead
      for (double t = 0.2; t <= 0.8; t += 0.0137) {
        final onCurve = Vector2(
          (1 - t) * (1 - t) * p0.$1 + 2 * (1 - t) * t * p1.$1 + t * t * p2.$1,
          (1 - t) * (1 - t) * p0.$2 + 2 * (1 - t) * t * p1.$2 + t * t * p2.$2,
        );
        final tangent = Vector2(
          2 * (1 - t) * (p1.$1 - p0.$1) + 2 * t * (p2.$1 - p1.$1),
          2 * (1 - t) * (p1.$2 - p0.$2) + 2 * t * (p2.$2 - p1.$2),
        ).normalized();
        // Into the board: perpendicular to the curve, pointing down
        final inward = Vector2(-tangent.y, tangent.x);
        expect(inward.y, greaterThan(0));

        final tooClose =
            onCurve + inward * (radius + GameConstants.minPegGap - 0.02);
        final justClear =
            onCurve + inward * (radius + GameConstants.minPegGap + 0.02);
        expect(
            PegPatterns.leavesRoomForBall(const [], tooClose, radius), isFalse,
            reason: 't=$t');
        expect(
            PegPatterns.leavesRoomForBall(const [], justClear, radius), isTrue,
            reason: 't=$t');
      }
    });

    test(
        'given the largest peg in the top corner of the random pattern, then false',
        () {
      // (60, 120) with radius 12 is the closest the random pattern can come to
      // the curve: about 17 px, more than a ball and less than the minimum gap
      expect(PegPatterns.leavesRoomForBall(const [], Vector2(60, 120), 12),
          isFalse);
      expect(PegPatterns.leavesRoomForBall(const [], Vector2(60, 124), 12),
          isTrue);
    });

    test('the minimum gap is wider than a ball', () {
      expect(GameConstants.minPegGap, greaterThan(ballDiameter));
    });
  });

  group('Patterns -', () {
    /// Each pattern on its own, over many seeds: the jittered grids only
    /// produce a narrow gap now and then, so the level tests alone could miss it.
    final patterns = {
      'random': PegPatterns.generateRandomPattern,
      'hexagonal': PegPatterns.generateHexagonalPattern,
      'triangle': PegPatterns.generateTrianglePattern,
    };

    for (final pattern in patterns.entries) {
      test(
          'given 300 seeds, when the ${pattern.key} pattern is generated, then a ball fits through every gap',
          () {
        for (int seed = 0; seed < 300; seed++) {
          final pegs = pattern.value(Random(seed), seed % 30 + 1, 400.0, 600.0);
          expect(pegs, isNotEmpty);
          for (int i = 0; i < pegs.length; i++) {
            for (int j = i + 1; j < pegs.length; j++) {
              expect(
                PegPatterns.gapTo(pegs[i], pegs[j].position, pegs[j].radius),
                greaterThan(ballDiameter),
                reason: '${pattern.key}, seed $seed: pegs $i and $j',
              );
            }
          }
        }
      });
    }
  });
}
