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
    
    // Speed based on launch power (200-500 pixels/second)
    final speed = 200.0 + (_launchPower / _maxPower) * 300.0;
    
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
      // Ball is now free-falling in the peg field
      final finalVelocity = _calculateReleaseVelocity();
      _currentBall!.velocity = finalVelocity;
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
  
  Vector2 _calculateReleaseVelocity() {
    // Calculate velocity based on the current path direction
    if (_launchPath.length < 2) {
      return Vector2(0, 150); // Fallback for edge case
    }

    // Find the segment we're currently on for accurate direction
    int currentSegment = _launchPath.length - 2;
    
    // Use the last few segments to calculate smooth direction
    // This ensures the velocity matches the curve direction
    if (_launchPath.length >= 3) {
      final thirdToLast = _launchPath[_launchPath.length - 3];
      final secondToLast = _launchPath[_launchPath.length - 2];
      final lastPoint = _launchPath[_launchPath.length - 1];
      
      // Calculate direction from the average of the last segments
      // This creates a smoother transition
      final dir1 = (secondToLast - thirdToLast).normalized();
      final dir2 = (lastPoint - secondToLast).normalized();
      final direction = ((dir1 + dir2) / 2).normalized();
      
      // Calculate speed based on launch power (150-350 pixels/second)
      // Lower speeds for smoother entry into peg field
      final powerMultiplier = 0.5 + (_launchPower / _maxPower) * 1.0; // 0.5 to 1.5
      final baseSpeed = 200.0 * powerMultiplier;
      
      // Apply direction to create velocity vector
      return direction * baseSpeed;
    }

    // Fallback: use last two points
    final secondToLast = _launchPath[_launchPath.length - 2];
    final lastPoint = _launchPath[_launchPath.length - 1];
    final direction = (lastPoint - secondToLast).normalized();
    final baseSpeed = 200.0;
    
    return direction * baseSpeed;
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