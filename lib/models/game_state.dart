import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:flutter/material.dart';
import 'ball.dart';
import 'level.dart';

enum GamePhase {
  loading,
  ready,
  launching,
  playing,
  ballsFalling,
  roundComplete,
  levelComplete,
  gameOver,
}

class GameState extends ChangeNotifier {
  Level? _currentLevel;
  int _currentLevelNumber = 1;
  int _score = 0;
  int _ballsRemaining = 20;
  int _totalBalls = 20;
  List<Ball> _activeBalls = [];
  GamePhase _phase = GamePhase.loading;
  bool _specialBonusTriggered = false;
  int _bonusBallsToAdd = 0;

  // Bonus screen auto-dismiss timer
  Timer? _bonusDisplayTimer;
  double _bonusOverlayOpacity = 0.0;

  // Getters
  Level? get currentLevel => _currentLevel;
  int get currentLevelNumber => _currentLevelNumber;
  int get score => _score;
  int get ballsRemaining => _ballsRemaining;
  int get totalBalls => _totalBalls;
  List<Ball> get activeBalls => List.unmodifiable(_activeBalls);
  GamePhase get phase => _phase;
  bool get specialBonusTriggered => _specialBonusTriggered;
  double get bonusOverlayOpacity => _bonusOverlayOpacity;
  bool get canLaunchBall => _phase == GamePhase.ready && _ballsRemaining > 0;
  bool get isGameOver => _ballsRemaining <= 0 && _activeBalls.isEmpty;
  
  void loadLevel(int levelNumber) {
    _currentLevelNumber = levelNumber;
    _currentLevel = Level.generate(levelNumber, 400, 600);
    _phase = GamePhase.ready;
    _specialBonusTriggered = false;
    _bonusBallsToAdd = 0;
    notifyListeners();
  }

  void startNewGame({int level = 1}) {
    _score = 0;
    _ballsRemaining = _totalBalls;
    _activeBalls.clear();
    loadLevel(level);
  }

  void launchBall(Ball ball) {
    if (!canLaunchBall) return;
    
    _ballsRemaining--;
    _activeBalls.add(ball);
    _phase = GamePhase.playing;
    notifyListeners();
  }

  void addScore(int points) {
    _score += points;
    notifyListeners();
  }

  void removeBall(Ball ball) {
    _activeBalls.remove(ball);
    
    // Check if all balls have finished falling
    if (_activeBalls.isEmpty) {
      if (_bonusBallsToAdd > 0) {
        // Add bonus balls
        _ballsRemaining += _bonusBallsToAdd;
        _bonusBallsToAdd = 0;
        _phase = GamePhase.ready;
      } else if (_ballsRemaining > 0) {
        _phase = GamePhase.ready;
      } else {
        _phase = GamePhase.gameOver;
      }
    }
    notifyListeners();
  }

  void triggerSpecialBonus() {
    if (_specialBonusTriggered) return;

    _specialBonusTriggered = true;
    _bonusOverlayOpacity = 1.0; // Show bonus overlay
    _bonusBallsToAdd = 5 + (_currentLevelNumber ~/ 2); // More bonus balls on higher levels

    // Spawn bonus balls immediately
    final level = _currentLevel;
    if (level != null) {
      for (int i = 0; i < _bonusBallsToAdd; i++) {
        final bonusBall = Ball(
          position: Vector2(
            level.launchX + (i - _bonusBallsToAdd / 2) * 20,
            level.launchY,
          ),
          color: const Color(0xFFFFD700), // Gold color for bonus balls
        );
        _activeBalls.add(bonusBall);
      }
      _bonusBallsToAdd = 0; // Reset since we added them immediately
    }

    // Auto-dismiss bonus overlay after 2.5 seconds
    _bonusDisplayTimer?.cancel();
    _bonusDisplayTimer = Timer(const Duration(milliseconds: 2500), () {
      _specialBonusTriggered = false;
      _bonusOverlayOpacity = 0.0;
      notifyListeners();
    });

    notifyListeners();
  }

  void nextLevel() {
    if (_currentLevel != null) {
      _currentLevelNumber++;
      loadLevel(_currentLevelNumber);
      _ballsRemaining = _totalBalls; // Reset balls for new level
    }
  }

  void resetLevel() {
    _currentLevel?.reset();
    _activeBalls.clear();
    _ballsRemaining = _totalBalls;
    _phase = GamePhase.ready;
    _specialBonusTriggered = false;
    _bonusOverlayOpacity = 0.0;
    _bonusBallsToAdd = 0;
    _bonusDisplayTimer?.cancel(); // Cancel any pending bonus timer
    notifyListeners();
  }

  void pauseGame() {
    if (_phase == GamePhase.playing) {
      _phase = GamePhase.ready; // Simple pause implementation
      notifyListeners();
    }
  }

  void resumeGame() {
    if (_activeBalls.isNotEmpty) {
      _phase = GamePhase.playing;
      notifyListeners();
    }
  }

  void updatePhase(GamePhase newPhase) {
    _phase = newPhase;
    notifyListeners();
  }

  @override
  void dispose() {
    _bonusDisplayTimer?.cancel();
    super.dispose();
  }
}