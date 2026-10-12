import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import '../models/ball_launcher.dart';
import '../models/game_state.dart';
import '../models/peg.dart';
import '../models/slot.dart';
import '../utils/constants.dart';
import 'physics_engine.dart';
import 'audio_service.dart';
import 'storage_service.dart';
import 'achievement_service.dart';

class GameManager extends ChangeNotifier {
  final GameState _gameState;
  final PhysicsEngine _physicsEngine;
  final BallLauncher _ballLauncher;
  final AudioService? _audioService;
  StorageService? _storageService;
  AchievementService? _achievementService;
  Timer? _gameTimer;
  DateTime _lastFrameTime = DateTime.now();
  bool _levelResultSaved = false;

  /// The player's choice of launch mode, made while there was no storage to
  /// save it to. Saved when storage is attached.
  bool? _unsavedSingleBallLaunch;
  bool _disposed = false;

  /// Creates a GameManager with optional dependency injection.
  ///
  /// Dependencies default to production instances if not provided,
  /// enabling both production use and testability with mocks.
  GameManager({
    GameState? gameState,
    PhysicsEngine? physicsEngine,
    BallLauncher? ballLauncher,
    AudioService? audioService,
    StorageService? storageService,
    AchievementService? achievementService,
  }) : _audioService = audioService,
       _storageService = storageService,
       _achievementService = achievementService,
       _gameState = gameState ?? GameState(),
       _physicsEngine = physicsEngine ?? PhysicsEngine(audioService: audioService),
       _ballLauncher = ballLauncher ?? BallLauncher() {
    // The player's saved choice, when there is storage to read it from
    if (storageService != null) {
      _gameState.singleBallLaunch = storageService.singleBallLaunch;
    }
  }

  /// Gives the manager the services that load after the app has started.
  ///
  /// The app creates the manager the first time something asks for it, and
  /// storage loads after the first frame, so the manager can be the older of
  /// the two. When storage arrives the saved settings are applied. A service
  /// the manager already has is left alone, and so is one passed as null.
  ///
  /// A choice the player made while there was no storage stands: it is saved
  /// now, and the stored value does not replace it. This is called while
  /// widgets are being built, so listeners hear of a change just afterwards.
  void attachServices({StorageService? storageService, AchievementService? achievementService}) {
    if (achievementService != null) _achievementService = achievementService;
    if (storageService == null || identical(storageService, _storageService)) return;
    _storageService = storageService;

    final unsaved = _unsavedSingleBallLaunch;
    if (unsaved != null) {
      _unsavedSingleBallLaunch = null;
      unawaited(storageService.saveSingleBallLaunch(unsaved));
    } else if (_gameState.singleBallLaunch != storageService.singleBallLaunch) {
      _gameState.singleBallLaunch = storageService.singleBallLaunch;
      scheduleMicrotask(() {
        if (!_disposed) notifyListeners();
      });
    }
  }

  /// Sets whether a ball may only be launched once no ball is in play,
  /// applies it to the game at once and saves it for the next start.
  Future<void> setSingleBallLaunch(bool value) async {
    _gameState.singleBallLaunch = value;
    notifyListeners();
    final storage = _storageService;
    if (storage == null) {
      // Kept until storage arrives: see attachServices
      _unsavedSingleBallLaunch = value;
      return;
    }
    await storage.saveSingleBallLaunch(value);
  }

  // Getters
  GameState get gameState => _gameState;
  PhysicsEngine get physicsEngine => _physicsEngine;
  BallLauncher get ballLauncher => _ballLauncher;
  bool get isRunning => _gameTimer?.isActive ?? false;
  
  void startGame({int level = 1}) {
    _ballLauncher.reset();
    _levelResultSaved = false;
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
    _ballLauncher.reset();
    _levelResultSaved = false;
    _gameTimer?.cancel();
    _gameState.resetLevel();
    notifyListeners();
  }

  /// Stops the game loop without changing game state or notifying listeners.
  ///
  /// Safe to call while widgets are being disposed.
  void stopLoop() {
    _gameTimer?.cancel();
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

    // Play launch sound IMMEDIATELY - before any state changes
    // This eliminates perceived delay between visual action and audio
    _audioService?.playLaunch();

    final ball = _ballLauncher.launch();
    if (ball != null) {
      _gameState.launchBall(ball);
      // The launcher carries one ball at a time up its channel
      _gameState.launcherBusy = true;

      // Track ball launch achievement
      _achievementService?.trackBallLaunched();

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

    // Update visual effects
    _gameState.updateFloatingTexts(clampedDeltaTime);
    _gameState.updateBallCountHighlight(clampedDeltaTime);
    _gameState.updateConfetti(clampedDeltaTime);

    _checkGameState();

    // Nothing left for the loop to move: stop until the next launch. The board
    // animates its own pegs, so it does not need these ticks
    if (_isIdle) _gameTimer?.cancel();

    notifyListeners();
  }

  /// Whether nothing the loop drives is changing: no ball in play (a ball in
  /// the launch channel counts as in play) and no score popup, confetti or
  /// ball count highlight.
  bool get _isIdle =>
      _gameState.activeBalls.isEmpty &&
      _gameState.floatingTexts.isEmpty &&
      _gameState.confettiParticles.isEmpty &&
      !_gameState.ballCountHighlighted;

  void _updatePhysics(double deltaTime) {
    final balls = _gameState.activeBalls;
    final level = _gameState.currentLevel;
    
    if (level == null) return;

    // Where each ball is before this step moves it, for the trail behind it
    for (final ball in balls) {
      ball.recordTrail();
    }

    // Update ball launcher (for balls traveling on guided path)
    if (_ballLauncher.phase == LaunchPhase.traveling) {
      final ballReleased = _ballLauncher.updateBallPath(deltaTime);
      if (ballReleased && _ballLauncher.currentBall != null) {
        // Ball is now released to physics simulation
        _ballLauncher.reset();
        _gameState.launcherBusy = false;
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
    for (final ball in List.from(balls)) {
      if (!ball.isActive) {
        _gameState.removeBall(ball);
      }
    }
  }

  void _handlePegHits(List<Peg> hitPegs) {
    for (final peg in hitPegs) {
      if (peg.type == PegType.special) {
        // Play special peg sound
        _audioService?.playSpecialPeg();
        _checkSpecialBonus();
      }
    }
  }

  void _handleSlotHits(List<Slot> hitSlots) {
    for (final slot in hitSlots) {
      _gameState.addScore(slot.pointValue);
      // Play slot score sound
      _audioService?.playSlotScore(slot.pointValue);

      // Add floating text for visual feedback
      _gameState.addFloatingText(
        '+${slot.pointValue}',
        Offset(slot.position.x, slot.position.y - 20), // Above slot
        _getScoreColor(slot.pointValue),
      );

      // Track edge slot achievement (edge slots are worth 2000 points)
      if (slot.pointValue >= 2000) {
        _achievementService?.trackEdgeSlot();
      }
    }
  }

  Color _getScoreColor(int points) {
    if (points >= 2000) return const Color(0xFFFFD700); // Gold
    if (points >= 1000) return const Color(0xFFFFA500); // Orange
    if (points >= 500) return const Color(0xFFFFFF00); // Yellow
    return Colors.white;
  }

  void _checkSpecialBonus() {
    final level = _gameState.currentLevel;
    if (level == null || _gameState.specialBonusTriggered) return;

    if (level.allSpecialPegsHit) {
      _gameState.triggerSpecialBonus();
      // Play bonus trigger fanfare
      _audioService?.playBonusTrigger();

      // Spawn confetti at center of board
      _gameState.spawnConfetti(
        vm.Vector2(GameConstants.boardWidth / 2, GameConstants.boardHeight / 2),
        50, // 50 confetti particles
      );

      // Track achievements
      _achievementService?.trackAllSpecialPegsHit();
      _achievementService?.trackSpecialBonus();
    }
  }

  void _checkGameState() {
    if (_gameState.activeBalls.isEmpty) {
      if (_gameState.ballsRemaining <= 0) {
        // The loop keeps running so the last score popup and peg flashes finish animating
        if (!_levelResultSaved) {
          _levelResultSaved = true;
          _gameState.updatePhase(GamePhase.gameOver);

          // Save high score when level completes
          _saveHighScore();
        }
      } else {
        _gameState.updatePhase(GamePhase.ready);
      }
    }
  }

  /// Saves the points won on the current level as that level's high score.
  void _saveHighScore() {
    final storageService = _storageService;
    final level = _gameState.currentLevel?.levelNumber ?? 1;
    final score = _gameState.levelScore;

    if (storageService != null) {
      storageService.saveHighScore(level, score);
    }

    // Track achievements for level completion and score
    _achievementService?.trackLevelComplete(level);
    _achievementService?.trackLevelScore(level, score);
  }

  void nextLevel() {
    _ballLauncher.reset();
    _levelResultSaved = false;
    _gameTimer?.cancel();
    _gameState.nextLevel();
    notifyListeners();
  }

  /// Jumps to [levelNumber] within the current run.
  ///
  /// No screen calls this: the level picker starts a new game with
  /// [startGame]. It keeps the running score, including points from the level
  /// that is left, so whoever gives it a caller should first decide whether a
  /// jump starts a new run (raised in the reviews of #5 and #20).
  void selectLevel(int levelNumber) {
    _ballLauncher.reset();
    _levelResultSaved = false;
    _gameTimer?.cancel();
    _gameState.loadLevel(levelNumber);
    notifyListeners();
  }


  @override
  void dispose() {
    _disposed = true;
    _gameTimer?.cancel();
    super.dispose();
  }
}