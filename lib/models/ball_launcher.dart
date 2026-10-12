import 'package:vector_math/vector_math_64.dart';
import '../utils/constants.dart';
import 'ball.dart';

enum LaunchPhase {
  ready,
  charging,
  launching,
  traveling,
  released,
}

class BallLauncher {
  LaunchPhase _phase = LaunchPhase.ready;
  double _launchPower = 0.0;
  final double _maxPower = 100.0;
  Ball? _currentBall;
  final List<Vector2> _launchPath = [];
  double _pathProgress = 0.0;

  LaunchPhase get phase => _phase;
  double get launchPower => _launchPower;
  double get maxPower => _maxPower;
  Ball? get currentBall => _currentBall;

  BallLauncher() {
    _generateLaunchPath();
  }

  void _generateLaunchPath() {
    _launchPath.clear();

    // Start position (bottom right)
    const startX = GameConstants.ballLaunchX;
    const startY = GameConstants.ballLaunchY;

    // Path up the channel
    const pathSegments = 20;
    for (int i = 0; i <= pathSegments; i++) {
      final progress = i / pathSegments;
      final y =
          startY - (progress * (startY - GameConstants.launchChannelEndY));
      _launchPath.add(Vector2(startX, y));
    }
  }

  void startCharging() {
    if (_phase == LaunchPhase.ready) {
      _phase = LaunchPhase.charging;
      _launchPower = 0.0;
    }
  }

  void updateCharging(double power) {
    if (_phase == LaunchPhase.charging) {
      _launchPower = power.clamp(0.0, _maxPower);
    }
  }

  Ball? launch() {
    if (_phase != LaunchPhase.charging) return null;

    _phase = LaunchPhase.launching;

    // Create ball at launch position
    _currentBall = Ball(
      position: Vector2(GameConstants.ballLaunchX, GameConstants.ballLaunchY),
      color: GameConstants.ballColor,
    );

    _pathProgress = 0.0;
    _phase = LaunchPhase.traveling;

    return _currentBall;
  }

  bool updateBallPath(double deltaTime) {
    if (_phase != LaunchPhase.traveling || _currentBall == null) return false;

    final speed = _launchSpeed;

    // Calculate total distance traveled
    _pathProgress += speed * deltaTime;

    // Calculate total path length and cumulative segment lengths
    double totalDistance = 0.0;
    final segmentLengths = <double>[];

    for (int i = 0; i < _launchPath.length - 1; i++) {
      final segmentLength = (_launchPath[i + 1] - _launchPath[i]).length;
      segmentLengths.add(segmentLength);
      totalDistance += segmentLength;
    }

    // Check if we've reached the end of the path
    if (_pathProgress >= totalDistance) {
      // The top of the channel: the ball is let go at the speed it came up
      // with, and the physics has it from here. Where it comes down depends
      // on how far that speed carries it along the dome
      _currentBall!.position = _launchPath.last.clone();
      _currentBall!.velocity = Vector2(0, -speed);
      _phase = LaunchPhase.released;
      return true; // Ball is now released to physics
    }

    // Find which segment we're on and interpolate smoothly
    double accumulatedDistance = 0.0;
    int segmentIndex = 0;

    for (int i = 0; i < segmentLengths.length; i++) {
      if (_pathProgress < accumulatedDistance + segmentLengths[i]) {
        segmentIndex = i;
        break;
      }
      accumulatedDistance += segmentLengths[i];
    }

    // Interpolate position within the current segment
    final distanceInSegment = _pathProgress - accumulatedDistance;
    final segmentProgress = distanceInSegment / segmentLengths[segmentIndex];

    final current = _launchPath[segmentIndex];
    final next = _launchPath[segmentIndex + 1];

    final lerpedX = current.x + (next.x - current.x) * segmentProgress;
    final lerpedY = current.y + (next.y - current.y) * segmentProgress;
    _currentBall!.position = Vector2(lerpedX, lerpedY);

    return false; // Ball still traveling on guided path
  }

  /// The speed the ball travels up the channel and leaves it with: between
  /// [GameConstants.launchSpeedMin] and [GameConstants.launchSpeedMax],
  /// by the launch power.
  double get _launchSpeed =>
      GameConstants.launchSpeedMin +
      (_launchPower / _maxPower) *
          (GameConstants.launchSpeedMax - GameConstants.launchSpeedMin);

  void reset() {
    _phase = LaunchPhase.ready;
    _launchPower = 0.0;
    _currentBall = null;
    _pathProgress = 0.0;
  }

  List<Vector2> getLaunchPath() => List.unmodifiable(_launchPath);
}
