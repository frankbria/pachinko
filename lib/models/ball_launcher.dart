import 'dart:math' as math;
import 'package:flutter/material.dart';
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
  double _maxPower = 100.0;
  Ball? _currentBall;
  List<Vector2> _launchPath = [];
  int _pathIndex = 0;
  double _pathProgress = 0.0;
  double _totalPathLength = 0.0;
  
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
    final startX = GameConstants.ballLaunchX;
    final startY = GameConstants.ballLaunchY;
    
    // Path up the channel
    const pathSegments = 20;
    for (int i = 0; i <= pathSegments; i++) {
      final progress = i / pathSegments;
      final y = startY - (progress * (startY - GameConstants.launchChannelEndY));
      _launchPath.add(Vector2(startX, y));
    }
    
    // Curve at the top (quarter circle from right to left)
    const curveSegments = 15;
    const curveRadius = 40.0;
    final curveStartX = startX;
    final curveEndY = GameConstants.launchChannelEndY;
    
    for (int i = 1; i <= curveSegments; i++) {
      final angle = (i / curveSegments) * (3.14159 / 2); // 90 degrees
      final x = curveStartX - (curveRadius * (1 - math.cos(angle)));
      final y = curveEndY - (curveRadius * math.sin(angle));
      _launchPath.add(Vector2(x, y));
    }
    
    // Entry point to peg field
    final entryX = curveStartX - curveRadius;
    final entryY = curveEndY - curveRadius;
    _launchPath.add(Vector2(entryX, entryY));
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
      color: const Color(0xFFFFFFFF),
    );
    
    _pathIndex = 0;
    _pathProgress = 0.0;
    _phase = LaunchPhase.traveling;
    
    return _currentBall;
  }
  
  bool updateBallPath(double deltaTime) {
    if (_phase != LaunchPhase.traveling || _currentBall == null) return false;

    // Speed based on launch power
    final speed = 200.0 + (_launchPower / _maxPower) * 300.0; // 200-500 pixels/second

    // Calculate total path length if not cached
    if (_totalPathLength == 0.0) {
      for (int i = 0; i < _launchPath.length - 1; i++) {
        _totalPathLength += (_launchPath[i + 1] - _launchPath[i]).length;
      }
    }

    // Advance along path based on speed
    _pathProgress += speed * deltaTime;

    // Check if we've completed the path
    if (_pathProgress >= _totalPathLength) {
      // Ball is now free-falling in the peg field
      // Velocity is already set from the last path segment - no need to recalculate
      _currentBall!.position = _launchPath.last;
      _phase = LaunchPhase.released;
      return true; // Ball is now released to physics
    }

    // Find which segment we're on and where within that segment
    double accumulatedLength = 0.0;
    int currentSegment = 0;

    for (int i = 0; i < _launchPath.length - 1; i++) {
      final segmentLength = (_launchPath[i + 1] - _launchPath[i]).length;

      if (_pathProgress < accumulatedLength + segmentLength) {
        // We're on this segment
        currentSegment = i;
        final segmentProgress = (_pathProgress - accumulatedLength) / segmentLength;
        final current = _launchPath[i];
        final next = _launchPath[i + 1];

        // Interpolate position smoothly along segment
        _currentBall!.position = current + (next - current) * segmentProgress;

        // Update ball velocity to match path direction for smooth transition
        final pathDirection = (next - current).normalized();
        _currentBall!.velocity = pathDirection * speed;

        break;
      }

      accumulatedLength += segmentLength;
      currentSegment = i;
    }

    // If we're on the last segment, ensure velocity matches that segment direction
    if (currentSegment >= _launchPath.length - 2) {
      final lastSegment = _launchPath.length - 2;
      final current = _launchPath[lastSegment];
      final next = _launchPath[lastSegment + 1];
      final pathDirection = (next - current).normalized();
      _currentBall!.velocity = pathDirection * speed;
    }

    return false; // Ball still traveling on guided path
  }
  
  Vector2 _calculateReleaseVelocity() {
    // Calculate direction tangent to final path segment for smooth transition
    final pathDirection = (_launchPath[_launchPath.length - 1] -
                          _launchPath[_launchPath.length - 2]).normalized();

    // Scale speed based on launch power (200-500 pixels/second)
    final releaseSpeed = 200.0 + (_launchPower / _maxPower) * 300.0;

    // Apply direction and speed for smooth continuation from path
    final releaseVelocity = pathDirection * releaseSpeed;

    return releaseVelocity;
  }
  
  void reset() {
    _phase = LaunchPhase.ready;
    _launchPower = 0.0;
    _currentBall = null;
    _pathIndex = 0;
    _pathProgress = 0.0;
    _totalPathLength = 0.0;
  }
  
  List<Vector2> getLaunchPath() => List.unmodifiable(_launchPath);
}