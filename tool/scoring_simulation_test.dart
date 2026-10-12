// Plays whole rounds through the real level generator, launcher, physics and
// game state, and reports where balls land, how often the bonus triggers, how
// many balls a round plays and what it scores (issue #46).
//
// It is a measuring tool, not a test: it asserts nothing, and it lives in
// tool/ so that `flutter test` does not run it. Run it with
//
//     flutter test tool/scoring_simulation_test.dart \
//       --dart-define=LEVELS=60 --dart-define=ROUNDS=20
//
// and read the lines that start with SIM and BAND. To compare two commits,
// copy this file into a checkout of each: it only uses what GameState,
// BallLauncher, PhysicsEngine and Level have offered since #6.
//
// The round is stepped the way GameManager._updatePhysics steps it. Launch
// power is uniform on 0 to 100, which a player's is not. The physics engine's
// own randomness is not seeded, so figures move by about a point between runs.
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:pachinko_game/models/ball.dart';
import 'package:pachinko_game/models/ball_launcher.dart';
import 'package:pachinko_game/models/game_state.dart';
import 'package:pachinko_game/models/peg.dart';
import 'package:pachinko_game/services/achievement_service.dart';
import 'package:pachinko_game/services/physics_engine.dart';

class Tally {
  int rounds = 0,
      bonusRounds = 0,
      balls = 0,
      stuck = 0,
      gap = 0,
      score = 0,
      prizePegs = 0,
      pegs = 0;
  int over10k = 0, best = 0;

  /// Every round's score, for the percentiles.
  final scores = <int>[];
  final slots = <int, int>{50: 0, 200: 0, 1000: 0, 2000: 0};
  void add(Tally o) {
    rounds += o.rounds;
    bonusRounds += o.bonusRounds;
    balls += o.balls;
    stuck += o.stuck;
    gap += o.gap;
    score += o.score;
    prizePegs += o.prizePegs;
    pegs += o.pegs;
    over10k += o.over10k;
    scores.addAll(o.scores);
    best = max(best, o.best);
    o.slots.forEach((k, v) => slots[k] = slots[k]! + v);
  }

  String share(int n) => '${(100 * n / rounds).toStringAsFixed(1)}%';
  String band(String name) =>
      '$name | ${share(bonusRounds)} | ${(balls / rounds).toStringAsFixed(1)} | ${(score / rounds).round()} | '
      '${share(over10k)} | ${percentile(50)} | ${percentile(90)} | ${percentile(99)} | '
      '${share(reaching(AchievementService.highRollerScore))} | '
      '${share(reaching(AchievementService.scoreMasterScore))} | $best';

  /// How many rounds scored at least [threshold].
  int reaching(int threshold) =>
      scores.where((score) => score >= threshold).length;

  /// The score that [p] percent of rounds did not beat.
  int percentile(int p) {
    final sorted = [...scores]..sort();
    return sorted[((sorted.length - 1) * p / 100).round()];
  }

  String pct(int n) => '${(100 * n / balls).toStringAsFixed(1)}%';
  String row(String name) =>
      '$name | ${(pegs / rounds).toStringAsFixed(1)} | ${(prizePegs / rounds).toStringAsFixed(2)} | '
      '${(100 * bonusRounds / rounds).toStringAsFixed(1)}% | ${(balls / rounds).toStringAsFixed(1)} | '
      '${pct(slots[50]!)} | ${pct(slots[200]!)} | ${pct(slots[1000]!)} | ${pct(slots[2000]!)} | '
      '${pct(gap)} | ${pct(stuck)} | ${(score / rounds).round()} | ${(score / balls).round()}';
}

void main() {
  const dt = 1.0 / 60.0;
  const maxFrames = 30 * 60;
  const rounds = int.fromEnvironment('ROUNDS', defaultValue: 20);
  const levels = int.fromEnvironment('LEVELS', defaultValue: 30);
  // PegPatterns.getPatternForLevel picks the pattern from the level number
  const names = {1: 'triangle', 2: 'random', 0: 'hexagonal'};

  Ball launchedBall(double power) {
    final launcher = BallLauncher();
    launcher.startCharging();
    launcher.updateCharging(power);
    final ball = launcher.launch()!;
    while (!launcher.updateBallPath(dt)) {}
    return ball;
  }

  Tally playRound(int levelNumber, int seed) {
    final tally = Tally()..rounds = 1;
    final state = GameState()..startNewGame(level: levelNumber);
    final level = state.currentLevel!;
    tally.pegs = level.pegs.length;
    tally.prizePegs =
        level.pegs.where((peg) => peg.type == PegType.special).length;
    final engine = PhysicsEngine();
    final powers = Random(seed);

    while (state.ballsRemaining > 0) {
      state.launchBall(launchedBall(powers.nextDouble() * 100));
      int frames = 0;
      while (state.activeBalls.isNotEmpty) {
        final balls = state.activeBalls.toList();
        if (++frames > maxFrames) {
          // At rest in the peg field: the soft-lock that #16 fixed
          for (final ball in balls) {
            tally.stuck++;
            tally.balls++;
            state.removeBall(ball);
          }
          break;
        }
        engine.updateBalls(balls, dt);
        final hitPegs = engine.checkPegCollisions(balls, level.pegs);
        if (hitPegs.any((peg) => peg.type == PegType.special) &&
            level.allSpecialPegsHit &&
            !state.specialBonusTriggered) {
          state.triggerSpecialBonus();
          tally.bonusRounds = 1;
          // The bonus balls have only just dropped: they get the full time
          // before anything is counted as stuck
          frames = 0;
        }
        final hitSlots = engine.checkSlotCollisions(balls, level.slots);
        for (final slot in hitSlots) {
          state.addScore(slot.pointValue);
          tally.slots[slot.pointValue] = tally.slots[slot.pointValue]! + 1;
        }
        for (final ball in balls) {
          if (!ball.isActive) {
            tally.balls++;
            if (!ball.hasLanded) tally.gap++;
            state.removeBall(ball);
          }
        }
      }
    }
    tally.score = state.score;
    tally.best = state.score;
    if (state.score >= 10000) tally.over10k = 1;
    tally.scores.add(state.score);
    state.dispose();
    return tally;
  }

  test('scoring simulation', () {
    final byPattern = {0: Tally(), 1: Tally(), 2: Tally()};
    final all = Tally();
    final bands = {
      'levels 1-10': Tally(),
      'levels 11-20': Tally(),
      'levels 21-40': Tally(),
      'levels 41-60': Tally()
    };
    for (int n = 1; n <= levels; n++) {
      for (int r = 0; r < rounds; r++) {
        final t = playRound(n, n * 1000 + r);
        byPattern[n % 3]!.add(t);
        all.add(t);
        bands[n <= 10
                ? 'levels 1-10'
                : n <= 20
                    ? 'levels 11-20'
                    : n <= 40
                        ? 'levels 21-40'
                        : 'levels 41-60']!
            .add(t);
      }
    }
    // ignore: avoid_print
    print('SIM levels 1..$levels, $rounds rounds each');
    // ignore: avoid_print
    print(
        'SIM pattern | pegs | prize pegs | bonus rounds | balls/round | 50 | 200 | 1000 | 2000 | gap | stuck | score/round | score/ball');
    for (final k in [1, 2, 0]) {
      // ignore: avoid_print
      print('SIM ${byPattern[k]!.row(names[k]!)}');
    }
    // ignore: avoid_print
    print('SIM ${all.row('all')}');
    // ignore: avoid_print
    print(
        'BAND levels | bonus rounds | balls/round | score/round | rounds over 10k | p50 | p90 | p99 | High Roller | Score Master | best round');
    bands.forEach((name, tally) {
      // ignore: avoid_print
      if (tally.rounds > 0) print('BAND ${tally.band(name)}');
    });
    // ignore: avoid_print
    print('BAND ${all.band('all')}');
  }, timeout: const Timeout(Duration(minutes: 20)));
}
