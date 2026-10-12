import 'package:flutter_test/flutter_test.dart';
import 'package:pachinko_game/models/game_state.dart';
import 'package:pachinko_game/models/round_summary.dart';

/// The summary shown when the last ball lands. Its numbers come from the
/// round itself: the slots' ball counts, the pegs and the level's score.
void main() {
  /// A finished round on [levelNumber] with [counts] balls in the slots of
  /// each value, spread over the slots that carry that value.
  GameState roundWith(Map<int, int> counts, {int levelNumber = 1, bool bonus = false, int collected = 0}) {
    final state = GameState()..startNewGame(level: levelNumber);
    final level = state.currentLevel!;
    counts.forEach((value, balls) {
      final slots = level.slots.where((slot) => slot.pointValue == value).toList();
      for (int i = 0; i < balls; i++) {
        slots[i % slots.length].addBall();
        state.addScore(value);
      }
    });
    for (final peg in level.specialPegs.take(collected)) {
      peg.onHit();
    }
    if (bonus) state.triggerSpecialBonus();
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

  test('given a round with the bonus on level 6, then the bonus balls and the prize pegs are reported', () {
    final state = roundWith({50: 1}, levelNumber: 6, bonus: true, collected: 1);
    addTearDown(state.dispose);

    final summary = RoundSummary.of(state);

    expect(summary.levelNumber, 6);
    expect(summary.bonusBalls, 5 + 6 ~/ 2);
    // Every level has at least two prize pegs, so one collected is not all of them
    expect(summary.prizePegsCollected, 1);
    expect(summary.prizePegsTotal, state.currentLevel!.specialPegs.length);
    expect(summary.prizePegsTotal, greaterThan(1));
  });

  test('given a round without the bonus, then no bonus balls are reported', () {
    final state = roundWith({50: 1}, collected: 1);
    addTearDown(state.dispose);

    expect(RoundSummary.of(state).bonusBalls, 0);
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
