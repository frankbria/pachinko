import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:pachinko_game/models/ball.dart';
import 'package:pachinko_game/models/ball_launcher.dart';
import 'package:pachinko_game/models/level.dart';
import 'package:pachinko_game/services/physics_engine.dart';
import 'package:pachinko_game/utils/constants.dart';

/// Simulation test for issue #16: no ball may come to rest in the peg field.
///
/// A ball at rest never leaves `GameState.activeBalls`, so the phase stays
/// `playing` and the session is soft-locked. The test plays real balls through
/// the real `PhysicsEngine`, `BallLauncher` and `Level.generate` for levels
/// 1 to 30, stepping the way `GameManager` does, and counts the balls still in
/// play after 30 simulated seconds. Every random source is seeded, so a failure
/// repeats.
void main() {
  const dt = 1.0 / 60.0;
  const maxFrames = 30 * 60;

  /// Steps one free ball until it leaves play. False if it is still in play at the end.
  bool leavesPlay(PhysicsEngine engine, Level level, Ball ball) {
    for (var frame = 0; frame < maxFrames && ball.isActive; frame++) {
      engine.updateBalls([ball], dt);
      engine.checkPegCollisions([ball], level.pegs);
      engine.checkSlotCollisions([ball], level.slots);
    }
    return !ball.isActive;
  }

  /// A ball launched at [power], at the moment the launch channel releases it.
  Ball launchedBall(double power) {
    final launcher = BallLauncher();
    launcher.startCharging();
    launcher.updateCharging(power);
    final ball = launcher.launch()!;
    while (!launcher.updateBallPath(dt)) {}
    return ball;
  }

  /// One bonus, spawned where `GameState.triggerSpecialBonus` spawns it.
  List<Ball> bonusBalls(int levelNumber) {
    final count = GameConstants.bonusBallsBase + levelNumber ~/ 2;
    const spawnWidth =
        GameConstants.bonusBallSpawnMaxX - GameConstants.bonusBallSpawnMinX;
    return [
      for (var i = 0; i < count; i++)
        Ball(
          position: Vector2(
            GameConstants.bonusBallSpawnMinX + spawnWidth * i / (count - 1),
            GameConstants.bonusBallSpawnY,
          ),
        ),
    ];
  }

  test(
      'given levels 1 to 30, when 100 balls are launched on each, then none comes to rest',
      () {
    final stuck = <String>[];
    for (var n = 1; n <= 30; n++) {
      final level = Level.generate(n, 400.0, 600.0);
      final engine = PhysicsEngine(random: Random(n));
      final powers = Random(n);
      for (var i = 0; i < 100; i++) {
        final ball = launchedBall(powers.nextDouble() * 100);
        if (!leavesPlay(engine, level, ball)) {
          stuck.add(
              'level $n at (${ball.position.x.round()}, ${ball.position.y.round()})');
        }
      }
    }
    expect(stuck, isEmpty);
  });

  test(
      'given levels 1 to 30, when 10 bonuses drop on each, then no bonus ball comes to rest',
      () {
    final stuck = <String>[];
    for (var n = 1; n <= 30; n++) {
      final level = Level.generate(n, 400.0, 600.0);
      final engine = PhysicsEngine(random: Random(n));
      for (var round = 0; round < 10; round++) {
        for (final ball in bonusBalls(n)) {
          if (!leavesPlay(engine, level, ball)) {
            stuck.add(
                'level $n at (${ball.position.x.round()}, ${ball.position.y.round()})');
          }
        }
      }
    }
    expect(stuck, isEmpty);
  });
}
