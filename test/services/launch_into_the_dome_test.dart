import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:pachinko_game/models/ball.dart';
import 'package:pachinko_game/models/ball_launcher.dart';
import 'package:pachinko_game/services/physics_engine.dart';
import 'package:pachinko_game/utils/constants.dart';

/// A launched ball leaves the top of the channel under the physics alone and
/// meets the dome, which guides it and does not throw it back (#96). A weak
/// launch drops into the field near the channel; a full one rides the dome
/// over its top to the far side.
///
/// These fly a ball with no pegs in the field, frame by frame, from its
/// release until it has come down past the dome's ends.
void main() {
  const frame = 1 / 60;
  const startX = GameConstants.topCurveStartX;
  const endX = GameConstants.topCurveEndX;

  /// The dome's height at [x].
  double domeY(double x) {
    final t = (x - startX) / (endX - startX);
    return (1 - t) * (1 - t) * GameConstants.topCurveStartY +
        2 * (1 - t) * t * GameConstants.topCurveControlY +
        t * t * GameConstants.topCurveEndY;
  }

  /// How far the ball's centre is from the dome, measured across the curve.
  double clearance(Ball ball) {
    const h = 0.25;
    final slope =
        (domeY(ball.position.x + h) - domeY(ball.position.x - h)) / (2 * h);
    return (ball.position.y - domeY(ball.position.x)) /
        math.sqrt(1 + slope * slope);
  }

  /// A ball launched at [power], carried to the top of the channel.
  Ball launched(double power) {
    final launcher = BallLauncher()
      ..startCharging()
      ..updateCharging(power);
    final ball = launcher.launch()!;
    for (int i = 0; i < 10000 && !launcher.updateBallPath(frame); i++) {}
    return ball;
  }

  /// Flies [ball] until it is below the dome's ends, calling [each] after
  /// every frame with the ball and where it was before the frame.
  void fly(Ball ball, void Function(Ball ball, Vector2 before) each) {
    final engine = PhysicsEngine();
    for (int i = 0; i < 600 && ball.position.y < 150; i++) {
      final before = ball.position.clone();
      engine.updateBalls([ball], frame);
      each(ball, before);
    }
    expect(ball.position.y, greaterThanOrEqualTo(150),
        reason: 'the ball came down');
  }

  /// Where the ball is, left to right, as it comes down past the dome.
  double entersAt(double power) {
    final ball = launched(power);
    fly(ball, (_, __) {});
    return ball.position.x;
  }

  /// For how many frames the ball is pressed against the dome.
  int framesOnTheDome(double power) {
    int frames = 0;
    fly(launched(power), (ball, _) {
      if (clearance(ball) - ball.radius < 0.5) frames++;
    });
    return frames;
  }

  test(
      'given a launch at any power, then no part of the ball is ever outside the dome',
      () {
    for (double power = 0; power <= 100; power += 5) {
      fly(launched(power), (ball, _) {
        if (ball.position.x < startX || ball.position.x > endX) return;
        expect(clearance(ball), greaterThanOrEqualTo(ball.radius - 0.05),
            reason: 'power $power at ${ball.position}');
      });
    }
  });

  test(
      'given more power, then the ball comes down further from the channel, from beside it to the far side',
      () {
    final powers = [0.0, 20.0, 40.0, 60.0, 80.0];
    final entries = powers.map(entersAt).toList();

    for (int i = 1; i < entries.length; i++) {
      expect(entries[i], lessThan(entries[i - 1] - 15),
          reason: 'power ${powers[i]} against ${powers[i - 1]}: $entries');
    }
    expect(entries.first, greaterThan(250),
        reason: 'the weakest comes down beside the channel');
    expect(entersAt(100), lessThan(80),
        reason: 'the strongest comes down at the far side');
  });

  test(
      'given full power, then the ball rides the dome over its top; given half power, then it touches the dome and flies free under it',
      () {
    expect(framesOnTheDome(100), greaterThan(25));
    expect(framesOnTheDome(50), lessThan(8));
  });

  test(
      'given the weakest launch, then it enters the field and is never moved sideways by a wall',
      () {
    for (final power in [0.0, 5.0, 10.0]) {
      final ball = launched(power);
      final speed = ball.velocity.length;
      fly(ball, (ball, before) {
        // A wall that caught the ball in the channel's mouth would move it
        // many pixels in one frame
        expect((ball.position - before).length, lessThan(speed * frame + 4),
            reason: 'power $power at ${ball.position}');
        if (ball.position.y > GameConstants.launchChannelEndY + ball.radius) {
          expect(
              ball.position.x,
              lessThanOrEqualTo(
                  GameConstants.fieldRightBoundaryX - ball.radius + 0.01),
              reason: 'power $power: below the dome the ball is in the field');
        }
      });
    }
  });

  test(
      'given a ball that flies up into the dome, then the dome stops its rise and gives it no speed and no bounce',
      () {
    // Straight up under the top of the dome, as off a pin
    final ball = Ball(
        position: Vector2(GameConstants.topCurveControlX, 60),
        velocity: Vector2(0, -400));
    final engine = PhysicsEngine();
    double fastest = ball.velocity.length;
    bool touched = false;

    for (int i = 0; i < 30; i++) {
      engine.updateBalls([ball], frame);
      fastest = math.max(fastest, ball.velocity.length);
      if (clearance(ball) - ball.radius < 0.5) {
        touched = true;
        // The old dome threw the ball back at 0.7 of its speed
        expect(ball.velocity.y.abs(), lessThan(40),
            reason: 'on the dome the ball is not moving away from it');
      }
    }

    expect(touched, isTrue);
    expect(fastest, lessThanOrEqualTo(400.0));
  });

  test(
      'given a ball sliding along the dome, then it keeps the speed it has along the curve',
      () {
    // Pressed against the top of the dome and moving along it, fast enough
    // to stay on: only gravity and the air change its speed
    final apex = Vector2(GameConstants.topCurveControlX,
        domeY(GameConstants.topCurveControlX) + GameConstants.ballRadius);
    final ball = Ball(position: apex, velocity: Vector2(-600, 0));
    final engine = PhysicsEngine();

    engine.updateBalls([ball], frame);

    expect(clearance(ball) - ball.radius, lessThan(0.5));
    expect(ball.velocity.length, closeTo(600, 6));
    expect(ball.velocity.x, lessThan(-590));
  });
}
