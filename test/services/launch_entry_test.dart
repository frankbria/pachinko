import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:pachinko_game/models/ball.dart';
import 'package:pachinko_game/models/ball_launcher.dart';
import 'package:pachinko_game/models/level.dart';
import 'package:pachinko_game/models/peg.dart';
import 'package:pachinko_game/services/physics_engine.dart';
import 'package:pachinko_game/utils/constants.dart';

/// Launch power is aim (#112): it sets where the ball enters the pin field,
/// smoothly, and the board marks that point while the player charges.
void main() {
  const step = GameConstants.physicsTimeStep;

  /// Launches a ball at [power] the way the game does, carries it up the
  /// channel and flies it with the physics until it comes down past
  /// [GameConstants.fieldEntryY], and returns its x there.
  double flownEntryX(double power) {
    final launcher = BallLauncher()
      ..startCharging()
      ..updateCharging(power);
    final ball = launcher.launch()!;
    while (!launcher.updateBallPath(step)) {}
    final engine = PhysicsEngine();
    for (int i = 0; i < 10 * GameConstants.physicsStepsPerSecond; i++) {
      final above = ball.position.y < GameConstants.fieldEntryY;
      engine.updateBalls([ball], step);
      if (above && ball.position.y >= GameConstants.fieldEntryY) {
        return ball.position.x;
      }
    }
    fail('the ball launched at $power never came down into the field');
  }

  test(
      'given every whole power from 0 to 100, then the entry point moves one way only, in small steps, across the field',
      () {
    final entries = [
      for (int power = 0; power <= 100; power++)
        PhysicsEngine.entryXFor(power.toDouble())
    ];

    for (int power = 1; power <= 100; power++) {
      final move = entries[power - 1] - entries[power];
      expect(move, greaterThan(0),
          reason: 'power $power enters further from the channel than '
              '${power - 1}: $entries');
      expect(move, lessThanOrEqualTo(PhysicsEngine.maxEntryStep),
          reason: 'from power ${power - 1} to $power: $entries');
    }
    expect(entries.first, greaterThan(GameConstants.fieldRightBoundaryX - 80),
        reason: 'the weakest comes down beside the channel');
    expect(
        entries.last,
        lessThan(
            GameConstants.fieldLeftBoundaryX + 2 * GameConstants.minPegGap),
        reason: 'the strongest comes down by the far wall');
  });

  test(
      'given a launch at any power, then the predicted entry point is where the ball enters',
      () {
    for (double power = 0; power <= 100; power += 2.5) {
      expect(PhysicsEngine.entryXFor(power), flownEntryX(power),
          reason: 'power $power');
    }
  });

  test(
      'given real launches on levels 1 to 30, then each enters the field, or meets its first peg, where the marker says',
      () {
    for (int n = 1; n <= 30; n++) {
      final level = Level.generate(
          n, GameConstants.boardWidth, GameConstants.boardHeight);
      for (double power = 0; power <= 100; power += 5) {
        final launcher = BallLauncher()
          ..startCharging()
          ..updateCharging(power);
        final ball = launcher.launch()!;
        while (!launcher.updateBallPath(step)) {}
        final engine = PhysicsEngine()..seed(n);
        double? enteredAt;
        for (int i = 0; enteredAt == null && i < 1200; i++) {
          final above = ball.position.y < GameConstants.fieldEntryY;
          engine.updateBalls([ball], step);
          final touches = level.pegs
              .any((peg) => peg.checkCollision(ball.position, ball.radius));
          if (touches ||
              (above && ball.position.y >= GameConstants.fieldEntryY)) {
            enteredAt = ball.position.x;
          }
          engine.checkPegCollisions([ball], level.pegs);
        }
        expect(enteredAt, PhysicsEngine.entryXFor(power, pegs: level.pegs),
            reason: 'level $n, power $power');
      }
    }
  });

  test(
      'given the launcher at a power, then the ball it releases is the one the prediction flies',
      () {
    final launcher = BallLauncher()
      ..startCharging()
      ..updateCharging(40);
    final ball = launcher.launch()!;
    while (!launcher.updateBallPath(step)) {}
    final released = BallLauncher.releasedBall(40);

    expect(released.position, ball.position);
    expect(released.velocity, ball.velocity);
  });

  group('The entry rows', () {
    /// A ball moving fast sideways into a pin at [y], as off the dome.
    Ball bounceOffPinAt(double y) {
      final pin = Peg(position: Vector2(200, y));
      final ball = Ball(
          position:
              Vector2(200 + pin.radius + GameConstants.ballRadius - 1, y - 2),
          velocity: Vector2(-400, 50));
      PhysicsEngine().checkPegCollisions([ball], [pin]);
      return ball;
    }

    test(
        'given a fast ball meeting a pin in the entry rows, then it keeps little of its speed',
        () {
      final caught = bounceOffPinAt(GameConstants.entryRowsBottomY - 20);
      final below = bounceOffPinAt(GameConstants.entryRowsBottomY + 40);

      expect(caught.velocity.length, lessThan(0.4 * 400));
      expect(below.velocity.length, greaterThan(0.6 * 400),
          reason: 'the pins below keep their bounce');
    });

    test(
        'given a ball dropped onto the top of an entry-row pin, then it rolls off within a second and a half',
        () {
      // A caught ball is slow, and a slow ball is not caught again: without
      // that, the grip would balance it on the pin for many seconds, firing
      // the pin's flash and sound all the while
      for (final offset in [0.0, 0.5, 1.0, 3.0]) {
        for (final radius in [8.0, 11.0, 15.0]) {
          final pin = Peg(position: Vector2(200, 150), radius: radius);
          final ball = Ball(position: Vector2(200 + offset, 150 - radius - 70));
          final engine = PhysicsEngine()..seed(1);
          // It falls 70 px onto the pin, about 0.4 s, and must then be
          // below it
          double seconds = 0;
          while (seconds < 3 && ball.position.y <= pin.position.y + radius) {
            engine.updateBalls([ball], step);
            engine.checkPegCollisions([ball], [pin]);
            seconds += step;
          }
          expect(seconds, lessThan(1.5),
              reason: 'offset $offset, pin radius $radius');
        }
      }
    });
  });
}
