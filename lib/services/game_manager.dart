import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math_64.dart';
import '../models/ball.dart';
import '../models/ball_launcher.dart';
import '../models/game_state.dart';
import '../models/peg.dart';
import '../models/slot.dart';
import '../utils/constants.dart';
import 'physics_engine.dart';

class GameManager extends ChangeNotifier {
  final GameState _gameState;
  final PhysicsEngine _physicsEngine;
  final BallLauncher _ballLauncher;
  Timer? _gameTimer;
  DateTime _lastFrameTime = DateTime.now();

  /// Creates a GameManager with optional dependency injection.
  ///
  /// Dependencies default to production instances if not provided,
  /// enabling both production use and testability with mocks.
  GameManager({
    GameState? gameState,
    PhysicsEngine? physicsEngine,
    BallLauncher? ballLauncher,
  }) : _gameState = gameState ?? GameState(),
       _physicsEngine = physicsEngine ?? PhysicsEngine(),
       _ballLauncher = ballLauncher ?? BallLauncher();

  // Getters
  GameState get gameState => _gameState;
  PhysicsEngine get physicsEngine => _physicsEngine;
  BallLauncher get ballLauncher => _ballLauncher;
  bool get isRunning => _gameTimer?.isActive ?? false;
  
  void startGame({int level = 1}) {
    _gameState.startNewGame(level: level);
    _startGameLoop();
    notifyListeners();
  }

  void pauseGame() {
    _gameTimer?.cancel();
    _gameState.pauseGame();
    notifyListeners();
  }

  void resumeGame() {
    _gameState.resumeGame();
    _startGameLoop();
    notifyListeners();
  }

  void resetGame() {
    _gameTimer?.cancel();
    _gameState.resetLevel();
    notifyListeners();
  }

  void startLaunchCharging() {
    if (_gameState.canLaunchBall) {
      _ballLauncher.startCharging();
      notifyListeners();
    }
  }
  
  void updateLaunchPower(double power) {
    _ballLauncher.updateCharging(power);
    notifyListeners();
  }
  
  void launchBall() {
    if (!_gameState.canLaunchBall) return;
    
    final ball = _ballLauncher.launch();
    if (ball != null) {
      _gameState.launchBall(ball);
      
      if (!isRunning) {
        _startGameLoop();
      }
    }
    
    notifyListeners();
  }

  void _startGameLoop() {
    if (_gameTimer?.isActive == true) return;
    
    _lastFrameTime = DateTime.now();
    _gameTimer = Timer.periodic(
      const Duration(milliseconds: 16), // ~60 FPS
      _updateGame,
    );
  }

  void _updateGame(Timer timer) {
    final currentTime = DateTime.now();
    final deltaTime = currentTime.difference(_lastFrameTime).inMicroseconds / 1000000.0;
    _lastFrameTime = currentTime;
    
    // Cap delta time to prevent large jumps
    final clampedDeltaTime = deltaTime.clamp(0.0, 1.0 / 30.0);
    
    _updatePhysics(clampedDeltaTime);
    _checkGameState();
    
    notifyListeners();
  }

  void _updatePhysics(double deltaTime) {
    final balls = _gameState.activeBalls;
    final level = _gameState.currentLevel;
    
    if (level == null) return;
    
    // Update ball launcher (for balls traveling on guided path)
    if (_ballLauncher.phase == LaunchPhase.traveling) {
      final ballReleased = _ballLauncher.updateBallPath(deltaTime);
      if (ballReleased && _ballLauncher.currentBall != null) {
        // Ball is now released to physics simulation
        _ballLauncher.reset();
      }
    }
    
    if (balls.isEmpty) return;
    
    // Update ball physics (only for balls not on guided path)
    final freeBalls = balls.where((ball) => 
      _ballLauncher.currentBall == null || ball != _ballLauncher.currentBall).toList();
    
    _physicsEngine.updateBalls(freeBalls, deltaTime);
    
    // Check peg collisions (only for free balls)
    final hitPegs = _physicsEngine.checkPegCollisions(freeBalls, level.pegs);
    _handlePegHits(hitPegs);
    
    // Check slot collisions (only for free balls)
    final hitSlots = _physicsEngine.checkSlotCollisions(freeBalls, level.slots);
    _handleSlotHits(hitSlots);
    
    // Remove inactive balls
    balls.removeWhere((ball) => !ball.isActive);
    for (final ball in List.from(balls)) {
      if (!ball.isActive) {
        _gameState.removeBall(ball);
      }
    }
  }

  void _handlePegHits(List<Peg> hitPegs) {
    for (final peg in hitPegs) {
      if (peg.type == PegType.special) {
        _checkSpecialBonus();
      }
    }
  }

  void _handleSlotHits(List<Slot> hitSlots) {
    for (final slot in hitSlots) {
      _gameState.addScore(slot.pointValue);
    }
  }

  void _checkSpecialBonus() {
    final level = _gameState.currentLevel;
    if (level == null || _gameState.specialBonusTriggered) return;
    
    if (level.allSpecialPegsHit) {
      _gameState.triggerSpecialBonus();
    }
  }

  void _checkGameState() {
    if (_gameState.activeBalls.isEmpty) {
      if (_gameState.ballsRemaining <= 0) {
        _gameTimer?.cancel();
        _gameState.updatePhase(GamePhase.gameOver);
      } else {
        _gameState.updatePhase(GamePhase.ready);
      }
    }
  }

  void nextLevel() {
    _gameTimer?.cancel();
    _gameState.nextLevel();
    notifyListeners();
  }

  void selectLevel(int levelNumber) {
    _gameTimer?.cancel();
    _gameState.loadLevel(levelNumber);
    notifyListeners();
  }


  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }
}