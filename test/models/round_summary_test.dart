import 'package:flutter_test/flutter_test.dart';
import 'package:pachinko_game/models/game_state.dart';
import 'package:pachinko_game/models/round_summary.dart';

/// The summary shown when the last ball lands. Its numbers come from the
/// round itself: the slots' ball counts, the pegs and the level's score.
void main() {
  /// A finished round on [levelNumber] with [counts] balls in the slots of
  /// each value, spread over the slots that carry that value.
  GameState roundWith(Map<int, int> counts, {int levelNumber = 1, int? collected}) {
    final state = GameState()..startNewGame(level: levelNumber);
    final level = state.currentLevel!;
    counts.forEach((value, balls) {
      final slots = level.slots.where((slot) => slot.pointValue == value).toList();
      for (int i = 0; i < balls; i++) {
        slots[i % slots.length].addBall();
        state.addScore(value);
      }
    });
    // null collects every prize peg, which is what earns the bonus
    for (final peg in level.specialPegs.take(collected ?? level.specialPegs.length)) {
      peg.onHit();
    }
    return state;
  }

  test('given the round in the issue, then 25 balls for 8,550 are tallied by tier', () {
    final state = roundWith({2000: 2, 1000: 2, 200: 10, 50: 11});
    addTearDown(state.dispose);

    final summary = RoundSummary.of(state);

    expect(summary.score, 8550);
    expect(summary.ballsLanded, 25);
    expect(
      [for (final tier in summary.tiers) '${tier.pointValue} x ${tier.balls} = ${tier.points}'],
      ['2000 x 2 = 4000', '1000 x 2 = 2000', '200 x 10 = 2000', '50 x 11 = 550'],
    );
    expect(summary.tiers.fold<int>(0, (sum, tier) => sum + tier.points), summary.score);
  });

  test('given a tier nothing landed in, then it is still listed, with zero', () {
    final state = roundWith({200: 3});
    addTearDown(state.dispose);

    final summary = RoundSummary.of(state);

    expect(summary.tiers.map((tier) => tier.pointValue), [2000, 1000, 200, 50]);
    expect(summary.tiers.first.balls, 0);
    expect(summary.tiers.first.points, 0);
  });

  test('given every prize peg collected on level 6, then the bonus balls are reported, long after the overlay has gone', () {
    // GameState.specialBonusTriggered is the overlay's flag: it clears 2.5
    // seconds after the bonus. The summary must not read it
    final state = roundWith({50: 1}, levelNumber: 6);
    addTearDown(state.dispose);
    expect(state.specialBonusTriggered, isFalse);

    final summary = RoundSummary.of(state);

    expect(summary.levelNumber, 6);
    expect(summary.bonusBalls, 5 + 6 ~/ 2);
    expect(summary.prizePegsCollected, summary.prizePegsTotal);
    expect(summary.prizePegsTotal, greaterThan(1));
  });

  test('given one prize peg collected and the rest not, then no bonus balls are reported', () {
    // Every level has at least two prize pegs, so one collected is not all of them
    final state = roundWith({50: 1}, levelNumber: 6, collected: 1);
    addTearDown(state.dispose);

    final summary = RoundSummary.of(state);

    expect(summary.bonusBalls, 0);
    expect(summary.prizePegsCollected, 1);
    expect(summary.prizePegsTotal, state.currentLevel!.specialPegs.length);
  });

  test('given the overlay is showing but not every prize peg is collected, then no bonus balls are reported', () {
    final state = roundWith({50: 1}, collected: 1)..triggerSpecialBonus();
    addTearDown(state.dispose);

    expect(state.specialBonusTriggered, isTrue);
    expect(RoundSummary.of(state).bonusBalls, 0);
  });

  test('given no level loaded, then there are no prize pegs and no bonus', () {
    // "Every prize peg collected" is true of none at all, and must not count
    final state = GameState();
    addTearDown(state.dispose);

    final summary = RoundSummary.of(state);

    expect(summary.prizePegsTotal, 0);
    expect(summary.bonusBalls, 0);
    expect(summary.ballsLanded, 0);
  });

  test('given the second level of a run, then the score is the level\'s own, not the running total', () {
    final state = roundWith({1000: 3});
    addTearDown(state.dispose);
    state.nextLevel();
    state.currentLevel!.slots.firstWhere((slot) => slot.pointValue == 200).addBall();
    state.addScore(200);

    final summary = RoundSummary.of(state);

    expect(state.score, 3200);
    expect(summary.score, 200);
  });

  test('whether it is a new best is passed in, and unknown by default', () {
    final state = roundWith({50: 1});
    addTearDown(state.dispose);

    expect(RoundSummary.of(state).isNewBest, isNull);
    expect(RoundSummary.of(state, isNewBest: true).isNewBest, isTrue);
  });
}
