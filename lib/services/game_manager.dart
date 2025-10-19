import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import '../models/ball.dart';
import '../models/ball_launcher.dart';
import '../models/game_state.dart';
import '../models/peg.dart';
import '../models/slot.dart';
import '../utils/constants.dart';
import '../utils/graphics_config.dart';
import 'physics_engine.dart';
import 'graphics/particle_system.dart';
import 'graphics/performance_monitor.dart';
import 'graphics/animation_controller.dart';

class GameManager extends ChangeNotifier {
  final GameState _gameState = GameState();
  final PhysicsEngine _physicsEngine = PhysicsEngine();
  final BallLauncher _ballLauncher = BallLauncher();
  final ParticleSystem _particleSystem = ParticleSystem();
  final PerformanceMetrics _performanceMonitor = PerformanceMetrics();
  final AnimationController _animationController = AnimationController();
  Timer? _gameTimer;
  DateTime _lastFrameTime = DateTime.now();
  GraphicsQuality _currentQuality = GraphicsQuality.high;

  // Getters
  GameState get gameState => _gameState;
  PhysicsEngine get physicsEngine => _physicsEngine;
  BallLauncher get ballLauncher => _ballLauncher;
  ParticleSystem get particleSystem => _particleSystem;
  PerformanceMetrics get performanceMonitor => _performanceMonitor;
  AnimationController get animationController => _animationController;
  bool get isRunning => _gameTimer?.isActive ?? false;
  
  void startGame({int level = 1}) {
    _gameState.startNewGame(level: level);
    _setupGlowAnimations();
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
    final frameStartTime = DateTime.now();
    final deltaTime = frameStartTime.difference(_lastFrameTime).inMicroseconds / 1000000.0;
    _lastFrameTime = frameStartTime;

    // Cap delta time to prevent large jumps
    final clampedDeltaTime = deltaTime.clamp(0.0, 1.0 / 30.0);

    _updatePhysics(clampedDeltaTime);
    _checkGameState();

    notifyListeners();

    // Record frame time for performance monitoring (in milliseconds)
    final frameEndTime = DateTime.now();
    final frameTime = frameEndTime.difference(frameStartTime).inMicroseconds / 1000.0;
    _performanceMonitor.recordFrameTime(frameTime);

    // Adjust particle quality based on performance
    final recommendedQuality = _performanceMonitor.getRecommendedQuality();
    if (recommendedQuality != _currentQuality) {
      _currentQuality = recommendedQuality;
      _particleSystem.adjustQuality(_convertQuality(recommendedQuality));
    }
  }

  /// Converts GraphicsQuality to ParticleQualityLevel.
  ParticleQualityLevel _convertQuality(GraphicsQuality quality) {
    switch (quality) {
      case GraphicsQuality.high:
        return ParticleQualityLevel.high;
      case GraphicsQuality.medium:
        return ParticleQualityLevel.medium;
      case GraphicsQuality.low:
        return ParticleQualityLevel.low;
    }
  }

  void _updatePhysics(double deltaTime) {
    final balls = _gameState.activeBalls;
    final level = _gameState.currentLevel;

    if (level == null) return;

    // Update particle system
    _particleSystem.update(deltaTime);

    // Update animation controller for glow effects
    _animationController.update(deltaTime);

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

    // Spawn trail particles for moving balls
    for (final ball in freeBalls) {
      final velocityMagnitude = ball.velocity.length;
      if (velocityMagnitude > 50.0) {
        _particleSystem.spawnTrailParticle(
          position: ball.position,
          velocity: ball.velocity * 0.3,
          color: ball.color,
          lifetime: GameConstants.particleTrailLifetime,
        );
      }
    }

    // Check peg collisions (only for free balls)
    final pegCollisions = _physicsEngine.checkPegCollisions(freeBalls, level.pegs);
    _handlePegHits(pegCollisions);

    // Check slot collisions (only for free balls)
    final hitSlots = _physicsEngine.checkSlotCollisions(freeBalls, level.slots);
    _handleSlotHits(hitSlots);

    // Remove inactive balls (use loop instead of removeWhere to avoid unmodifiable list error)
    for (final ball in List.from(balls)) {
      if (!ball.isActive) {
        _gameState.removeBall(ball);
      }
    }
  }

  void _handlePegHits(List<PegCollision> pegCollisions) {
    for (final collision in pegCollisions) {
      final peg = collision.peg;
      
      // Spawn collision burst particles
      final pegColor = peg.type == PegType.special 
          ? GameConstants.specialPegColor 
          : GameConstants.normalPegColor;
      
      // Special pegs get enhanced particle effects
      final particleCount = peg.type == PegType.special 
          ? 12  // More particles for special pegs
          : GameConstants.collisionBurstParticleCount;
      
      _particleSystem.spawnCollisionBurst(
        position: collision.collisionPosition,
        pegColor: pegColor,
        particleCount: particleCount,
      );
      
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
      
      // Trigger visual bonus effect - spawn particle bursts at all special peg locations
      final specialPegs = level.pegs.where((peg) => peg.type == PegType.special).toList();
      
      for (final peg in specialPegs) {
        // Spawn large golden burst at each special peg
        _particleSystem.spawnCollisionBurst(
          position: vm.Vector2(peg.position.x, peg.position.y),
          pegColor: GameConstants.specialPegColor,
          particleCount: 16, // Extra large burst for bonus trigger
        );
      }
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
    _setupGlowAnimations();
    notifyListeners();
  }

  /// Sets up glow animations for all special pegs in the current level
  ///
  /// Creates looping pulsing animations for special pegs.
  /// Each special peg gets its own animation with a 2-second cycle.
  void _setupGlowAnimations() {
    final level = _gameState.currentLevel;
    if (level == null) return;

    // Find all special pegs
    final specialPegs = level.pegs.where((peg) => peg.type == PegType.special).toList();

    // Create glow animation for each special peg
    for (int i = 0; i < specialPegs.length; i++) {
      final animationId = 'special_peg_glow_$i';
      
      // Remove existing animation if present
      if (_animationController.hasAnimation(animationId)) {
        _animationController.removeAnimation(animationId);
      }

      // Create new looping animation (2-second cycle, easeInOut for smooth pulsing)
      _animationController.createAnimation(
        id: animationId,
        duration: 2.0,
        curve: AnimationCurve.easeInOut,
        loop: true,
      );

      // Start animation immediately
      _animationController.start(animationId);
    }
  }


  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }
}