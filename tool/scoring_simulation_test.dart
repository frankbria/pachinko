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
// and read the lines that start with SIM and BAND. A BAND line gives the
// spread of round scores on its levels (p10 to p99): the difficulty curve
// (#115) is that p50 stays flat from band to band while the bonus grows. To compare two commits,
// copy this file into a checkout of each: it uses what GameState,
// BallLauncher, PhysicsEngine and Level have offered since #6, the fixed
// step and seeding added in #108, and the fever added in #113. For an older
// commit, run that commit's own copy of the tool.
//
// The round is stepped the way GameManager._updatePhysics steps it, in the
// game's fixed steps, with the fever running down while balls are in play and
// each landing scored by GameState.scoreLanding. Each round's bounces are
// seeded as the game seeds them (GameManager.physicsSeedFor), so a run gives
// the same figures every time. Launch power is uniform on 0 to 100, which a player's is not.
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:pachinko_game/models/ball.dart';
import 'package:pachinko_game/models/ball_launcher.dart';
import 'package:pachinko_game/models/board_feature.dart';
import 'package:pachinko_game/models/game_state.dart';
import 'package:pachinko_game/models/level.dart';
import 'package:pachinko_game/models/peg.dart';
import 'package:pachinko_game/services/achievement_service.dart';
import 'package:pachinko_game/services/game_manager.dart';
import 'package:pachinko_game/services/physics_engine.dart';
import 'package:pachinko_game/utils/constants.dart';

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

  /// Rounds in which one ball collected every prize peg (Combo King), and
  /// rounds whose first ball landed in a 2,000 slot (Lucky Shot).
  int comboRounds = 0, luckyRounds = 0;

  /// What rounds with the bonus scored in all, and what the fever added to
  /// them, against what rounds without it scored.
  int bonusRoundScore = 0, feverPoints = 0;

  /// Per feature kind: rounds on a level with it, and the balls that met it
  /// with what they landed for, against every ball on those levels.
  final featureRounds = <FeatureKind, int>{};
  final featureBalls = <FeatureKind, int>{};
  final featureLanded = <FeatureKind, int>{};
  final featureLandedPoints = <FeatureKind, int>{};
  final levelLanded = <FeatureKind, int>{};
  final levelLandedPoints = <FeatureKind, int>{};

  /// Balls landed in the centre slot on levels with the centre gate.
  int gateLevelCentre = 0;

  /// Tulips opened, balls they caught and balls they paid out.
  int tulipOpens = 0, tulipCatches = 0, tulipBalls = 0;

  /// Every round's score, for the percentiles.
  final scores = <int>[];
  final slots = <int, int>{50: 0, 200: 0, 1000: 0, 2000: 0};

  /// Balls landed in each slot, counted from the left of the row.
  final byPosition = List<int>.filled(7, 0);
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
    comboRounds += o.comboRounds;
    luckyRounds += o.luckyRounds;
    bonusRoundScore += o.bonusRoundScore;
    feverPoints += o.feverPoints;
    best = max(best, o.best);
    void sum(Map<FeatureKind, int> into, Map<FeatureKind, int> from) =>
        from.forEach((k, v) => into[k] = (into[k] ?? 0) + v);
    sum(featureRounds, o.featureRounds);
    sum(featureBalls, o.featureBalls);
    sum(featureLanded, o.featureLanded);
    sum(featureLandedPoints, o.featureLandedPoints);
    sum(levelLanded, o.levelLanded);
    sum(levelLandedPoints, o.levelLandedPoints);
    gateLevelCentre += o.gateLevelCentre;
    tulipOpens += o.tulipOpens;
    tulipCatches += o.tulipCatches;
    tulipBalls += o.tulipBalls;
    o.slots.forEach((k, v) => slots[k] = slots[k]! + v);
    for (int i = 0; i < byPosition.length; i++) {
      byPosition[i] += o.byPosition[i];
    }
  }

  String share(int n) => '${(100 * n / rounds).toStringAsFixed(1)}%';
  String band(String name) =>
      '$name | ${share(bonusRounds)} | ${(balls / rounds).toStringAsFixed(1)} | ${(score / rounds).round()} | '
      '${share(over10k)} | ${percentile(10)} | ${percentile(25)} | ${percentile(50)} | ${percentile(90)} | ${percentile(99)} | '
      '${share(reaching(AchievementService.highRollerScore))} | '
      '${share(reaching(AchievementService.scoreMasterScore))} | '
      '${share(comboRounds)} | ${share(luckyRounds)} | $best';

  /// Mean score of rounds with the bonus and without it, and what the fever
  /// added to a bonus round.
  String fever(String name) {
    final others = rounds - bonusRounds;
    String mean(int total, int count) =>
        count == 0 ? '-' : '${(total / count).round()}';
    return '$name | ${mean(bonusRoundScore, bonusRounds)} | '
        '${mean(score - bonusRoundScore, others)} | '
        '${mean(feverPoints, bonusRounds)}';
  }

  /// How often balls meet a feature of [kind] and what they land for
  /// afterwards, against every ball on the levels that have it.
  String feature(FeatureKind kind) {
    final rounds = featureRounds[kind] ?? 0;
    if (rounds == 0) return '${kind.name} | 0 | - | - | -';
    String per(int n) => (n / rounds).toStringAsFixed(2);
    String mean(int total, int count) =>
        count == 0 ? '-' : (total / count).toStringAsFixed(0);
    var line = '${kind.name} | $rounds | ${per(featureBalls[kind] ?? 0)} | '
        '${mean(featureLandedPoints[kind] ?? 0, featureLanded[kind] ?? 0)} | '
        '${mean(levelLandedPoints[kind] ?? 0, levelLanded[kind] ?? 0)}';
    if (kind == FeatureKind.tulips) {
      line += ' | opens ${per(tulipOpens)} | catches ${per(tulipCatches)} | '
          'balls paid ${per(tulipBalls)}';
    }
    if (kind == FeatureKind.centreGate) {
      final landed = levelLanded[kind] ?? 0;
      line += ' | centre slot '
          '${landed == 0 ? '-' : (100 * gateLevelCentre / landed).toStringAsFixed(1)}%';
    }
    return line;
  }

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
  const dt = GameConstants.physicsTimeStep;
  const maxFrames = 30 * GameConstants.physicsStepsPerSecond;
  const rounds = int.fromEnvironment('ROUNDS', defaultValue: 20);
  const levels = int.fromEnvironment('LEVELS', defaultValue: 30);
  // PegPatterns.getPatternForLevel picks the pattern from the level number
  const names = {1: 'triangle', 2: 'random', 0: 'hexagonal'};

  /// Carries a ball launched at [power] up the channel, calling
  /// [onTravelStep] for each step it spends there: the game counts those
  /// steps as play, so the fever runs down during them.
  Ball launchedBall(double power, void Function() onTravelStep) {
    final launcher = BallLauncher();
    launcher.startCharging();
    launcher.updateCharging(power);
    final ball = launcher.launch()!;
    while (!launcher.updateBallPath(dt)) {
      onTravelStep();
    }
    return ball;
  }

  Tally playRound(int levelNumber, int round, int seed) {
    final tally = Tally()..rounds = 1;
    final state = GameState()..startNewGame(level: levelNumber);
    final level = state.currentLevel!;
    tally.pegs = level.pegs.length;
    tally.prizePegs =
        level.pegs.where((peg) => peg.type == PegType.special).length;
    final engine = PhysicsEngine()
      ..seed(GameManager.physicsSeedFor(levelNumber, round));
    final powers = Random(seed);
    final features = level.features;
    final kinds = Level.featureKindsFor(levelNumber);
    for (final kind in kinds) {
      tally.featureRounds[kind] = 1;
    }
    final tulips = level.tulips.toList();
    // The kinds of feature each ball has met
    final met = <Ball, Set<FeatureKind>>{};
    // Balls a tulip caught, which leave play without landing
    final caught = <Ball>{};
    // Balls whose landing has been credited to the features they met
    final credited = <Ball>{};
    FeatureKind kindOf(BoardFeature feature) => switch (feature) {
          Tulip() => FeatureKind.tulips,
          Windmill() => FeatureKind.windmill,
          CentreGate() => FeatureKind.centreGate,
        };

    /// One step of the features, counting the tulips that open on it.
    void stepFeatures() {
      final wasOpen = [for (final tulip in tulips) tulip.isOpen];
      engine.updateFeatures(features, dt);
      for (int i = 0; i < tulips.length; i++) {
        if (!wasOpen[i] && tulips[i].isOpen) tally.tulipOpens++;
      }
    }

    Ball? firstOfRound;
    while (state.ballsRemaining > 0) {
      final launched = launchedBall(powers.nextDouble() * 100, () {
        state.updateFever(dt);
        stepFeatures();
      });
      final firstBall = firstOfRound ??= launched;
      state.launchBall(launched);
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
        state.updateFever(dt);
        stepFeatures();
        engine.updateBalls(balls, dt);
        final hitPegs = engine.checkPegCollisions(balls, level.pegs);
        for (final hit in engine.checkFeatureCollisions(balls, features)) {
          if ((met[hit.ball] ??= {}).add(kindOf(hit.feature))) {
            final kind = kindOf(hit.feature);
            tally.featureBalls[kind] = (tally.featureBalls[kind] ?? 0) + 1;
          }
          if (hit.caught && hit.feature is Tulip) {
            tally.tulipCatches++;
            caught.add(hit.ball);
            state.payTulip(hit.feature as Tulip);
          }
        }
        if (hitPegs.any((peg) => peg.type == PegType.special) &&
            level.allSpecialPegsHit &&
            !state.specialBonusTriggered) {
          state.triggerSpecialBonus();
          tally.bonusRounds = 1;
          final prizes = level.specialPegs.length;
          if (balls.any((ball) => ball.prizePegsCollected == prizes)) {
            tally.comboRounds = 1;
          }
          // The bonus balls have only just dropped: they get the full time
          // before anything is counted as stuck
          frames = 0;
        }
        final hitSlots = engine.checkSlotCollisions(balls, level.slots);
        for (final slot in hitSlots) {
          if (firstBall.hasLanded &&
              slot.pointValue >= 2000 &&
              slot.containsPoint(firstBall.position)) {
            tally.luckyRounds = 1;
          }
          state.scoreLanding(slot);
          tally.slots[slot.pointValue] = tally.slots[slot.pointValue]! + 1;
          for (final kind in kinds) {
            tally.levelLanded[kind] = (tally.levelLanded[kind] ?? 0) + 1;
            tally.levelLandedPoints[kind] =
                (tally.levelLandedPoints[kind] ?? 0) + slot.pointValue;
          }
          if (kinds.contains(FeatureKind.centreGate) &&
              level.slots.indexOf(slot) == level.slots.length ~/ 2) {
            tally.gateLevelCentre++;
          }
          // The ball that landed here: one this step, in this slot, not yet
          // counted; two can land in one slot on the same step
          final landed = balls
              .where((ball) =>
                  ball.hasLanded &&
                  slot.containsPoint(ball.position) &&
                  !credited.contains(ball))
              .firstOrNull;
          if (landed != null) credited.add(landed);
          for (final kind in met[landed] ?? const <FeatureKind>{}) {
            tally.featureLanded[kind] = (tally.featureLanded[kind] ?? 0) + 1;
            tally.featureLandedPoints[kind] =
                (tally.featureLandedPoints[kind] ?? 0) + slot.pointValue;
          }
          tally.byPosition[level.slots.indexOf(slot)]++;
        }
        for (final ball in balls) {
          if (!ball.isActive) {
            tally.balls++;
            if (!ball.hasLanded && !caught.contains(ball)) tally.gap++;
            state.removeBall(ball);
          }
        }
      }
    }
    tally.score = state.score;
    tally.best = state.score;
    if (state.score >= 10000) tally.over10k = 1;
    tally.scores.add(state.score);
    if (tally.bonusRounds == 1) tally.bonusRoundScore = state.score;
    tally.feverPoints = state.feverPoints;
    tally.tulipBalls = state.tulipBalls;
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
        final t = playRound(n, r + 1, n * 1000 + r);
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
        'BAND levels | bonus rounds | balls/round | score/round | rounds over 10k | p10 | p25 | p50 | p90 | p99 | High Roller | Score Master | Combo King | Lucky Shot | best round');
    bands.forEach((name, tally) {
      // ignore: avoid_print
      if (tally.rounds > 0) print('BAND ${tally.band(name)}');
    });
    // ignore: avoid_print
    print('BAND ${all.band('all')}');
    // ignore: avoid_print
    print(
        'FEVER levels | score of a round with the bonus | without it | fever points in a bonus round');
    bands.forEach((name, tally) {
      // ignore: avoid_print
      if (tally.rounds > 0) print('FEVER ${tally.fever(name)}');
    });
    // ignore: avoid_print
    print('FEVER ${all.fever('all')}');
    // ignore: avoid_print
    print(
        'FEATURE kind | rounds on a level with it | balls meeting it a round | '
        'mean slot value of those balls | of every ball on those levels');
    for (final kind in FeatureKind.values) {
      // ignore: avoid_print
      print('FEATURE ${all.feature(kind)}');
    }
    // ignore: avoid_print
    print('ROW left to right | ${all.byPosition.map(all.pct).join(' | ')}');
  }, timeout: const Timeout(Duration(minutes: 20)));
}
