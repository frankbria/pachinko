import '../utils/constants.dart';

/// The level scores that win one, two and three stars on a level (#116).
///
/// The targets are the 40th, 75th and 95th percentiles of the level's round
/// scores, rounded to the nearest 500, as printed by the STARS lines of
/// `tool/scoring_simulation_test.dart` (see [forLevel]).
class StarTargets {
  /// The score for one star, which also opens the next level.
  final int one;

  /// The score for two stars.
  final int two;

  /// The score for three stars.
  final int three;

  const StarTargets(this.one, this.two, this.three);

  /// The most stars a level can give.
  static const int maxStars = 3;

  /// Levels 1 to [GameConstants.hardestLayoutLevel], in order, from
  /// `flutter test tool/scoring_simulation_test.dart
  /// --dart-define=LEVELS=50 --dart-define=ROUNDS=200`.
  static const List<StarTargets> _byLevel = [
    StarTargets(10000, 15500, 20500),
    StarTargets(11000, 17000, 24000),
    StarTargets(9000, 12500, 18000),
    StarTargets(7000, 11000, 18000),
    StarTargets(11500, 17000, 21500),
    StarTargets(8000, 12500, 18000),
    StarTargets(12500, 18500, 24500),
    StarTargets(9000, 15500, 22500),
    StarTargets(10500, 16000, 23000),
    StarTargets(7500, 14000, 22000),
    StarTargets(13000, 20000, 27500),
    StarTargets(8500, 16000, 23500),
    StarTargets(10500, 17000, 24500),
    StarTargets(11000, 19500, 28000),
    StarTargets(10000, 17500, 25000),
    StarTargets(7500, 14000, 23000),
    StarTargets(11000, 18500, 27000),
    StarTargets(8500, 16500, 25500),
    StarTargets(12500, 21000, 27000),
    StarTargets(8500, 14000, 24500),
  ];

  /// Every level after [GameConstants.hardestLayoutLevel]: the layouts stop
  /// getting harder there, so these are measured over the rounds of levels
  /// 21 to 50 together.
  // shortcut: one pooled set, so a later level whose features or pattern
  // score above the pool is easier to star than one below it; measure a
  // set per level of the 30-level cycle (pattern, windmill and gate repeat
  // every 30 levels) if players find levels past 20 uneven.
  static const StarTargets _afterHardest = StarTargets(9500, 19500, 29000);

  /// The targets of level [levelNumber]; levels after the table share one set.
  static StarTargets forLevel(int levelNumber) =>
      levelNumber >= 1 && levelNumber <= _byLevel.length
          ? _byLevel[levelNumber - 1]
          : _afterHardest;

  /// The stars a level score of [score] wins, 0 to [maxStars].
  int starsFor(int score) => [one, two, three].where((t) => score >= t).length;

  /// How many points [score] is short of the next star, or null when it has
  /// every star.
  int? pointsShortOfNextStar(int score) {
    final stars = starsFor(score);
    if (stars == maxStars) return null;
    return [one, two, three][stars] - score;
  }

  /// Whether level [levelNumber] can be played: level 1 always, any other once
  /// the level before it has a star. [starsByLevel] holds the stars won on
  /// each level; a level missing from it has none.
  static bool levelIsOpen(int levelNumber, Map<int, int> starsByLevel) =>
      levelNumber <= 1 || (starsByLevel[levelNumber - 1] ?? 0) >= 1;
}
