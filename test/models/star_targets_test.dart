import 'package:flutter_test/flutter_test.dart';
import 'package:pachinko_game/models/star_targets.dart';
import 'package:pachinko_game/utils/constants.dart';

void main() {
  group('StarTargets.starsFor', () {
    const targets = StarTargets(9000, 14000, 20000);

    test('Given each target and one point below it Then the stars change there',
        () {
      expect(targets.starsFor(0), 0);
      expect(targets.starsFor(8999), 0);
      expect(targets.starsFor(9000), 1);
      expect(targets.starsFor(13999), 1);
      expect(targets.starsFor(14000), 2);
      expect(targets.starsFor(19999), 2);
      expect(targets.starsFor(20000), 3);
      expect(targets.starsFor(1000000), 3);
    });

    test('Given every level Then its own targets behave the same at each one',
        () {
      for (int level = 1; level <= 60; level++) {
        final targets = StarTargets.forLevel(level);
        for (final (stars, target) in [
          (1, targets.one),
          (2, targets.two),
          (3, targets.three)
        ]) {
          expect(targets.starsFor(target), stars,
              reason: 'level $level at $target');
          expect(targets.starsFor(target - 1), stars - 1,
              reason: 'level $level one below $target');
        }
      }
    });
  });

  group('StarTargets.pointsShortOfNextStar', () {
    const targets = StarTargets(9000, 14000, 20000);

    test('Given a score below a target Then it is the distance to that target',
        () {
      expect(targets.pointsShortOfNextStar(0), 9000);
      expect(targets.pointsShortOfNextStar(12200), 1800);
      expect(targets.pointsShortOfNextStar(19999), 1);
    });

    test('Given every star won Then there is no next one', () {
      expect(targets.pointsShortOfNextStar(20000), isNull);
    });
  });

  group('StarTargets.forLevel', () {
    test(
        'Given every level Then its targets rise from one star to three and are round numbers',
        () {
      for (int level = 1; level <= 60; level++) {
        final targets = StarTargets.forLevel(level);
        expect(targets.one, greaterThan(0), reason: 'level $level');
        expect(targets.two, greaterThan(targets.one), reason: 'level $level');
        expect(targets.three, greaterThan(targets.two), reason: 'level $level');
        for (final target in [targets.one, targets.two, targets.three]) {
          expect(target % 500, 0, reason: 'level $level: $target');
        }
      }
    });

    test(
        'Given levels after the hardest layout Then they share one set of targets',
        () {
      const after = GameConstants.hardestLayoutLevel + 1;
      final shared = StarTargets.forLevel(after);
      for (final level in [after + 1, after + 9, 100, 1000]) {
        final targets = StarTargets.forLevel(level);
        expect((
          targets.one,
          targets.two,
          targets.three
        ), (
          shared.one,
          shared.two,
          shared.three
        ), reason: 'level $level');
      }
    });
  });

  group('StarTargets.levelIsOpen', () {
    test('Given nothing won Then level 1 is open and level 2 is not', () {
      expect(StarTargets.levelIsOpen(1, const {}), isTrue);
      expect(StarTargets.levelIsOpen(2, const {}), isFalse);
    });

    test('Given level 1 played without a star Then level 2 stays locked', () {
      expect(StarTargets.levelIsOpen(2, const {1: 0}), isFalse);
    });

    test('Given a star on a level Then the next one opens, and only that one',
        () {
      const stars = {1: 1, 2: 3};
      expect(StarTargets.levelIsOpen(2, stars), isTrue);
      expect(StarTargets.levelIsOpen(3, stars), isTrue);
      expect(StarTargets.levelIsOpen(4, stars), isFalse);
    });

    test('Given level 1 Then it is open whatever is stored', () {
      expect(StarTargets.levelIsOpen(1, const {1: 0, 2: 0}), isTrue);
    });

    test('Given a level beyond 20 Then the same rule opens it', () {
      expect(StarTargets.levelIsOpen(31, const {30: 2}), isTrue);
      expect(StarTargets.levelIsOpen(31, const {29: 2}), isFalse);
    });
  });
}
