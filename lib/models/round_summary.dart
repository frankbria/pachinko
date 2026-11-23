import '../utils/constants.dart';
import 'daily_board.dart';
import 'game_state.dart';
import 'peg.dart';
import 'star_targets.dart';

/// How many balls landed in the slots of one value, and what they scored.
class SlotTierTally {
  final int pointValue;
  final int balls;

  const SlotTierTally({required this.pointValue, required this.balls});

  int get points => pointValue * balls;
}

/// How a round went, for the summary shown when the last ball lands.
///
/// Everything is read from the game state at that moment; nothing is kept
/// while the round is played.
class RoundSummary {
  final int levelNumber;

  /// The daily board the round was played on, or null on a level.
  final DailyBoard? daily;

  /// The points won on this level, not the run's total.
  final int score;

  /// One entry per slot value, highest first, including values nothing
  /// landed in.
  final List<SlotTierTally> tiers;

  final int prizePegsCollected;
  final int prizePegsTotal;

  /// The bonus balls the round earned: none unless every prize peg was
  /// collected.
  final int bonusBalls;

  /// The points the fever added over what the slots pay without it. The
  /// [tiers] count slot values; [score] includes these.
  final int feverPoints;

  /// Whether [score] beats the level's best before this round, or the
  /// day's on the daily board. Null when it
  /// is not known (there is no storage, or it has not answered yet).
  final bool? isNewBest;

  const RoundSummary({
    required this.levelNumber,
    this.daily,
    required this.score,
    required this.tiers,
    required this.prizePegsCollected,
    required this.prizePegsTotal,
    required this.bonusBalls,
    this.feverPoints = 0,
    this.isNewBest,
  });

  /// The stars [score] wins on this level, 0 to [StarTargets.maxStars].
  int get stars => StarTargets.forLevel(levelNumber).starsFor(score);

  /// How many points [score] fell short of the next star, or null when it won
  /// every star.
  int? get pointsShortOfNextStar =>
      StarTargets.forLevel(levelNumber).pointsShortOfNextStar(score);

  /// The balls that landed in a slot. A ball that fell between two slots is
  /// not among them.
  int get ballsLanded => tiers.fold(0, (sum, tier) => sum + tier.balls);

  /// Reads the summary of the round just played from [state].
  factory RoundSummary.of(GameState state, {bool? isNewBest}) {
    final level = state.currentLevel;
    final slots = level?.slots ?? const [];
    final prizes = (level?.pegs ?? const <Peg>[])
        .where((peg) => peg.type == PegType.special);
    final values = GameConstants.slotPointValues.values.toSet().toList()
      ..sort((a, b) => b.compareTo(a));

    return RoundSummary(
      levelNumber: state.currentLevelNumber,
      daily: state.daily,
      score: state.levelScore,
      tiers: [
        for (final value in values)
          SlotTierTally(
            pointValue: value,
            balls: slots
                .where((slot) => slot.pointValue == value)
                .fold(0, (sum, slot) => sum + slot.ballCount),
          ),
      ],
      prizePegsCollected: prizes.where((peg) => peg.isCollected).length,
      prizePegsTotal: prizes.length,
      // Collecting every prize peg is what earns the bonus. The game state's
      // own bonus flag only lasts as long as the announcement on screen
      bonusBalls: prizes.isNotEmpty && prizes.every((peg) => peg.isCollected)
          ? GameConstants.bonusBallsFor(state.currentLevelNumber)
          : 0,
      feverPoints: state.feverPoints,
      isNewBest: isNewBest,
    );
  }
}
