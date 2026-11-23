import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';
import '../utils/constants.dart';
import 'peg.dart';

/// The kinds of board feature a level can have (#114).
enum FeatureKind { tulips, windmill, centreGate }

/// Something on the board besides pins and slots, with its own collision
/// shape in `PhysicsEngine`.
///
/// A feature moves only with play: `PhysicsEngine.updateFeatures` advances
/// it on each physics step that has a ball in play, so it holds still while
/// the game waits for a launch or is paused, and a seeded round plays out the
/// same way every time.
sealed class BoardFeature {
  /// The centre of the disc the feature can reach, at any position it moves
  /// through.
  Vector2 get centre;

  /// The radius of that disc. Level generation keeps every pin, prize peg,
  /// wall and other feature at least `GameConstants.minPegGap` outside it, so
  /// the feature makes no pocket wherever it moves.
  double get reach;

  /// Seconds before a bounce off the feature sounds again, so that a ball
  /// riding it does not sound on every step.
  double soundCooldown = 0.0;

  /// The pause after a sounded bounce before the next one sounds.
  static const double soundRepeatSeconds = 0.15;

  /// Moves the feature on by [deltaTime] seconds of play.
  void advance(double deltaTime) {
    soundCooldown = math.max(0.0, soundCooldown - deltaTime);
  }

  /// Puts the feature back as the level starts.
  void reset() {
    soundCooldown = 0.0;
  }
}

/// A catcher in the field. It opens when its trigger pin is hit, catches a
/// ball that falls into its mouth while open, pays out balls for it and
/// closes again; it also closes when [GameConstants.tulipOpenSeconds] of play
/// pass without a catch. Closed, or met from the side, it is a solid body
/// that balls bounce off.
class Tulip extends BoardFeature {
  /// The centre of the tulip's body.
  final Vector2 position;

  /// The pin above the tulip whose every hit opens it.
  final Peg triggerPin;

  Tulip({required this.position, required this.triggerPin});

  @override
  Vector2 get centre => position;

  @override
  double get reach => GameConstants.tulipRadius;

  double _openSecondsLeft = 0.0;
  int _triggerFiresSeen = 0;

  /// The balls this tulip has caught on this level.
  int catches = 0;

  /// Whether the tulip is open and can catch a ball.
  bool get isOpen => _openSecondsLeft > 0.0;

  /// The share of its open time still to run, from 1.0 as it opens to 0.0.
  double get openRemaining => _openSecondsLeft / GameConstants.tulipOpenSeconds;

  /// Whether the trigger pin has been hit since the tulip last looked, which
  /// opens it, or opens it afresh.
  bool get triggered => triggerPin.timesStruck > _triggerFiresSeen;

  /// Opens the tulip if its trigger pin has been hit since the last step, and
  /// otherwise runs its open time down. Returns whether it has just opened
  /// from closed.
  bool update(double deltaTime) {
    advance(deltaTime);
    if (triggered) {
      _triggerFiresSeen = triggerPin.timesStruck;
      final wasOpen = isOpen;
      _openSecondsLeft = GameConstants.tulipOpenSeconds;
      return !wasOpen;
    }
    _openSecondsLeft = math.max(0.0, _openSecondsLeft - deltaTime);
    return false;
  }

  /// Whether a ball touching the tulip where [normal] points (from the
  /// tulip's centre to the ball's, of unit length) falls into its mouth: only
  /// while open, and only from above, within
  /// [GameConstants.tulipMouthHalfAngle] of straight up.
  bool catchesAt(Vector2 normal) =>
      isOpen && -normal.y >= math.cos(GameConstants.tulipMouthHalfAngle);

  /// The tulip has caught a ball: it counts it and closes.
  void catchBall() {
    catches++;
    _openSecondsLeft = 0.0;
  }

  /// Closes the tulip, keeping its count of catches.
  void close() {
    _openSecondsLeft = 0.0;
    _triggerFiresSeen = triggerPin.timesStruck;
  }

  @override
  void reset() {
    super.reset();
    _openSecondsLeft = 0.0;
    _triggerFiresSeen = 0;
    catches = 0;
  }
}

/// A straight bar that turns about [pivot]: what a windmill blade and the
/// centre gate are made of. It is a segment with round ends, of half
/// thickness [GameConstants.featureBarHalfThickness].
typedef FeatureBar = ({Vector2 start, Vector2 end});

/// Something made of bars that turn about one point: the physics bounces a
/// ball off each bar, giving it the speed of the part of the bar it meets.
sealed class TurningFeature extends BoardFeature {
  /// The point the bars turn about.
  Vector2 get pivot;

  @override
  Vector2 get centre => pivot;

  /// The bars, where they are now.
  List<FeatureBar> get bars;

  /// How fast the bars turn now, in radians a second, clockwise on screen.
  double get angularVelocity;
}

/// A spinner: [GameConstants.windmillBlades] blades that turn at a steady
/// [GameConstants.windmillSpin] and redirect a ball that meets them.
class Windmill extends TurningFeature {
  @override
  final Vector2 pivot;

  Windmill({required this.pivot});

  /// The angle of the first blade, in radians clockwise on screen from
  /// pointing right.
  double angle = 0.0;

  @override
  double get reach =>
      GameConstants.windmillBladeLength + GameConstants.featureBarHalfThickness;

  @override
  double get angularVelocity => GameConstants.windmillSpin;

  @override
  List<FeatureBar> get bars => [
        for (int blade = 0; blade < GameConstants.windmillBlades; blade++)
          (
            start: pivot,
            end: pivot +
                _direction(angle +
                        blade * 2 * math.pi / GameConstants.windmillBlades) *
                    GameConstants.windmillBladeLength,
          ),
      ];

  @override
  void advance(double deltaTime) {
    super.advance(deltaTime);
    angle = (angle + GameConstants.windmillSpin * deltaTime) % (2 * math.pi);
  }

  @override
  void reset() {
    super.reset();
    angle = 0.0;
  }
}

/// A gate that rocks over the centre slot: a bar about its middle, level at
/// the start of a level and swinging up to [GameConstants.centreGateSwing]
/// either way. Level, it turns falling balls away from the slot; steep, it
/// guides them down its length into it.
class CentreGate extends TurningFeature {
  @override
  final Vector2 pivot;

  CentreGate({required this.pivot});

  /// Seconds of play since the level started.
  double time = 0.0;

  static const double _frequency = 2 * math.pi / GameConstants.centreGatePeriod;

  /// The bar's angle from level, in radians, clockwise on screen.
  double get angle =>
      GameConstants.centreGateSwing * math.sin(_frequency * time);

  @override
  double get angularVelocity =>
      GameConstants.centreGateSwing * _frequency * math.cos(_frequency * time);

  @override
  double get reach =>
      GameConstants.centreGateHalfLength +
      GameConstants.featureBarHalfThickness;

  @override
  List<FeatureBar> get bars {
    final half = _direction(angle) * GameConstants.centreGateHalfLength;
    return [(start: pivot - half, end: pivot + half)];
  }

  @override
  void advance(double deltaTime) {
    super.advance(deltaTime);
    time += deltaTime;
  }

  @override
  void reset() {
    super.reset();
    time = 0.0;
  }
}

/// A unit vector [angle] radians clockwise from pointing right, on screen.
Vector2 _direction(double angle) => Vector2(math.cos(angle), math.sin(angle));
