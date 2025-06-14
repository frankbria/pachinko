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
    _pathProgress += speed * deltaTime;
    
    // Move along path segments
    while (_pathProgress >= 20.0 && _pathIndex < _launchPath.length - 1) {
      _pathProgress -= 20.0;
      _pathIndex++;
    }
    
    // Check if we've reached the end of the path
    if (_pathIndex >= _launchPath.length - 1) {
      // Ball is now free-falling in the peg field
      final finalVelocity = _calculateReleaseVelocity();
      _currentBall!.velocity = finalVelocity;
      _phase = LaunchPhase.released;
      return true; // Ball is now released to physics
    }
    
    // Interpolate position along current path segment
    if (_pathIndex < _launchPath.length - 1) {
      final current = _launchPath[_pathIndex];
      final next = _launchPath[_pathIndex + 1];
      final segmentProgress = (_pathProgress / 20.0).clamp(0.0, 1.0);
      
      final lerpedX = current.x + (next.x - current.x) * segmentProgress;
      final lerpedY = current.y + (next.y - current.y) * segmentProgress;
      _currentBall!.position = Vector2(lerpedX, lerpedY);
    }
    
    return false; // Ball still traveling on guided path
  }
  
  Vector2 _calculateReleaseVelocity() {
    // Calculate initial velocity when ball enters peg field
    final powerMultiplier = 0.3 + (_launchPower / _maxPower) * 0.7; // 0.3 to 1.0
    final baseVelocity = Vector2(0, 150); // Slight downward velocity
    
    // Add some horizontal spread based on power
    final horizontalSpread = (_launchPower / _maxPower - 0.5) * 100;
    baseVelocity.x = horizontalSpread;
    
    return baseVelocity * powerMultiplier;
  }
  
  void reset() {
    _phase = LaunchPhase.ready;
    _launchPower = 0.0;
    _currentBall = null;
    _pathIndex = 0;
    _pathProgress = 0.0;
  }
  
  List<Vector2> getLaunchPath() => List.unmodifiable(_launchPath);
}