import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:pachinko_game/models/peg.dart';
import 'package:pachinko_game/utils/constants.dart';
import 'package:pachinko_game/utils/peg_patterns.dart';

/// The layouts get harder as levels rise, up to [GameConstants.hardestLayoutLevel]
/// (#115). How much harder was measured with
/// `tool/scoring_simulation_test.dart`; these tests hold the shape of the
/// curve: where it starts, where it stops and which way each layout moves.
void main() {
  group('difficultyFor -', () {
    test('given level 1, then it is 0', () {
      expect(GameConstants.difficultyFor(1), 0.0);
    });

    test('given the hardest layout level and any level after it, then it is 1',
        () {
      for (final level in [GameConstants.hardestLayoutLevel, 21, 60, 500]) {
        expect(GameConstants.difficultyFor(level), 1.0, reason: 'level $level');
      }
    });

    test('given levels 1 to 20, then it rises evenly', () {
      const steps = GameConstants.hardestLayoutLevel - 1;
      for (int level = 1; level <= GameConstants.hardestLayoutLevel; level++) {
        expect(GameConstants.difficultyFor(level),
            closeTo((level - 1) / steps, 1e-12));
      }
    });
  });

  group('alongDifficulty -', () {
    test(
        'given level 1, then the easiest value; from the hardest level on, the hardest',
        () {
      expect(GameConstants.alongDifficulty(1, 45, 42), 45.0);
      expect(
          GameConstants.alongDifficulty(
              GameConstants.hardestLayoutLevel, 45, 42),
          42.0);
      expect(GameConstants.alongDifficulty(100, 45, 42), 42.0);
    });

    test('given a level part way along, then the value as far between', () {
      // Level 10 is 9 of the 19 steps from level 1 to level 20
      expect(GameConstants.alongDifficulty(10, 0, 19), closeTo(9.0, 1e-12));
    });
  });

  group('Layouts by level -', () {
    /// Rows are told apart by height: a row's pins are jittered by at most
    /// half the jitter, far less than the step between rows.
    int rowsOf(List<Peg> pegs, double rowStep) {
      final heights = pegs.map((peg) => peg.position.y).toList()..sort();
      var rows = 1;
      for (int i = 1; i < heights.length; i++) {
        if (heights[i] - heights[i - 1] > rowStep / 2) rows++;
      }
      return rows;
    }

    test(
        'given the hexagonal layout, when a later level is generated, then it has more rows and more pins than level 3',
        () {
      final easy = PegPatterns.generateHexagonalPattern(Random(3), 3, 400, 600);
      final hard =
          PegPatterns.generateHexagonalPattern(Random(30), 30, 400, 600);

      expect(rowsOf(hard, GameConstants.hexagonalRowStepHardest),
          greaterThan(rowsOf(easy, GameConstants.hexagonalRowStep)));
      expect(hard.length, greaterThan(easy.length));
    });

    test(
        'given the triangle layout, when a later level is generated, then it has more rows and more pins than level 1',
        () {
      final easy = PegPatterns.generateTrianglePattern(Random(1), 1, 400, 600);
      final hard =
          PegPatterns.generateTrianglePattern(Random(31), 31, 400, 600);

      expect(rowsOf(hard, GameConstants.triangleRowStepHardest),
          greaterThan(rowsOf(easy, GameConstants.triangleRowStep)));
      expect(hard.length, greaterThan(easy.length));
    });

    test(
        'given the hardest values, then pins are closer and more jittered than on level 1',
        () {
      expect(GameConstants.hexagonalSpacingHardest,
          lessThan(GameConstants.hexagonalSpacing));
      expect(GameConstants.hexagonalRowStepHardest,
          lessThan(GameConstants.hexagonalRowStep));
      expect(GameConstants.hexagonalJitterHardest,
          greaterThan(GameConstants.hexagonalJitter));
      expect(GameConstants.triangleSpacingHardest,
          lessThan(GameConstants.triangleSpacing));
      expect(GameConstants.triangleRowStepHardest,
          lessThan(GameConstants.triangleRowStep));
      expect(GameConstants.triangleJitterHardest,
          greaterThan(GameConstants.triangleJitter));
    });

    test(
        'given the random layout on any level, then no pin is below that level\'s lowest row, which rises with the level',
        () {
      expect(GameConstants.randomLayoutBottomMarginHardest,
          greaterThan(GameConstants.randomLayoutBottomMargin));
      for (int level = 1; level <= 60; level++) {
        final lowest = 600 -
            GameConstants.alongDifficulty(
                level,
                GameConstants.randomLayoutBottomMargin,
                GameConstants.randomLayoutBottomMarginHardest);
        final pegs =
            PegPatterns.generateRandomPattern(Random(level), level, 400, 600);
        for (final peg in pegs) {
          expect(peg.position.y, lessThanOrEqualTo(lowest),
              reason: 'level $level');
        }
      }
    });
  });
}
