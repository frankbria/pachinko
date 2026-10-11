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

    test('given a peg whose gap to another is narrower than the minimum, then false', () {
      // Radii 10 and 10: the gap is the centre distance minus 20
      final tooClose = Vector2(200 + 20 + GameConstants.minPegGap - 0.5, 300);
      expect(PegPatterns.leavesRoomForBall(existing, tooClose, 10), isFalse);
    });

    test('given a peg whose gap to another is exactly the minimum, then true', () {
      final justFits = Vector2(200 + 20 + GameConstants.minPegGap, 300);
      expect(PegPatterns.leavesRoomForBall(existing, justFits, 10), isTrue);
    });

    test('given a peg too close to the left field wall, then false', () {
      const x = GameConstants.fieldLeftBoundaryX + 10 + GameConstants.minPegGap;
      expect(PegPatterns.leavesRoomForBall(const [], Vector2(x, 300), 10), isTrue);
      expect(PegPatterns.leavesRoomForBall(const [], Vector2(x - 0.5, 300), 10), isFalse);
    });

    test('given a peg too close to the right field wall, then false', () {
      const x = GameConstants.fieldRightBoundaryX - 10 - GameConstants.minPegGap;
      expect(PegPatterns.leavesRoomForBall(const [], Vector2(x, 300), 10), isTrue);
      expect(PegPatterns.leavesRoomForBall(const [], Vector2(x + 0.5, 300), 10), isFalse);
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
      test('given 300 seeds, when the ${pattern.key} pattern is generated, then a ball fits through every gap', () {
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
