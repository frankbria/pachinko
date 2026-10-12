import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:flutter/material.dart';
import 'ball.dart';
import 'level.dart';
import 'confetti_particle.dart';
import '../utils/constants.dart';
import '../widgets/floating_text.dart';

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
  int _levelStartScore = 0;
  int _ballsRemaining = 20;
  int _totalBalls = 20;
  List<Ball> _activeBalls = [];
  GamePhase _phase = GamePhase.loading;
  bool _specialBonusTriggered = false;
  int _bonusBallsToAdd = 0;

  /// Whether a ball can only be launched once no ball is in play.
  ///
  /// On by default. Pause puts the phase back to [GamePhase.ready] with the
  /// ball still on the board, so without this a second ball could be launched
  /// while paused. Turn it off to allow that.
  bool singleBallLaunch = true;

  // Bonus screen auto-dismiss timer
  Timer? _bonusDisplayTimer;
  double _bonusOverlayOpacity = 0.0;

  // Visual effects
  final List<FloatingText> _floatingTexts = [];
  final List<ConfettiParticle> _confettiParticles = [];
  bool _ballCountHighlighted = false;
  double _ballCountHighlightTimer = 0.0;
  static const double _ballCountHighlightDuration = 1.0; // 1 second

  // Getters
  Level? get currentLevel => _currentLevel;
  int get currentLevelNumber => _currentLevelNumber;
  int get score => _score;

  /// Points won on the current level only. [score] is the running total across levels.
  int get levelScore => _score - _levelStartScore;
  int get ballsRemaining => _ballsRemaining;
  int get totalBalls => _totalBalls;
  List<Ball> get activeBalls => List.unmodifiable(_activeBalls);
  GamePhase get phase => _phase;
  bool get specialBonusTriggered => _specialBonusTriggered;
  double get bonusOverlayOpacity => _bonusOverlayOpacity;
  bool get canLaunchBall {
    if (_phase != GamePhase.ready || _ballsRemaining <= 0) return false;
    return !singleBallLaunch || _activeBalls.isEmpty;
  }
  bool get isGameOver => _ballsRemaining <= 0 && _activeBalls.isEmpty;
  List<FloatingText> get floatingTexts => List.unmodifiable(_floatingTexts);
  List<ConfettiParticle> get confettiParticles => List.unmodifiable(_confettiParticles);
  bool get ballCountHighlighted => _ballCountHighlighted;
  
  void loadLevel(int levelNumber) {
    _levelStartScore = _score;
    _currentLevelNumber = levelNumber;
    _currentLevel = Level.generate(levelNumber, 400, 600);
    // A ball still in play belongs to the level being left
    _activeBalls.clear();
    _phase = GamePhase.ready;
    _specialBonusTriggered = false;
    _bonusBallsToAdd = 0;
    _clearEffects();
    notifyListeners();
  }

  void startNewGame({int level = 1}) {
    _score = 0;
    _ballsRemaining = _totalBalls;
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
      // Spread evenly across the top of the playfield so each ball plays through the pegs
      final count = _bonusBallsToAdd;
      const spawnWidth =
          GameConstants.bonusBallSpawnMaxX - GameConstants.bonusBallSpawnMinX;
      for (int i = 0; i < count; i++) {
        final bonusBall = Ball(
          position: Vector2(
            GameConstants.bonusBallSpawnMinX + spawnWidth * i / (count - 1),
            GameConstants.bonusBallSpawnY,
          ),
          color: GameConstants.bonusBallColor,
        );
        _activeBalls.add(bonusBall);
      }
      _bonusBallsToAdd = 0; // Reset since we added them immediately

      // Trigger ball counter highlight
      _ballCountHighlighted = true;
      _ballCountHighlightTimer = _ballCountHighlightDuration;
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

  /// Add floating text for visual feedback
  void addFloatingText(String text, Offset position, Color color) {
    _floatingTexts.add(FloatingText(
      text: text,
      startPosition: position,
      color: color,
    ));
    notifyListeners();
  }

  /// Update floating text animations
  void updateFloatingTexts(double deltaTime) {
    _floatingTexts.removeWhere((text) => text.update(deltaTime));
  }

  /// Spawn confetti particles at position
  void spawnConfetti(Vector2 position, int count) {
    final random = math.Random();

    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 2 * math.pi + random.nextDouble() * 0.5;
      final speed = 100.0 + random.nextDouble() * 150.0;

      final particle = ConfettiParticle(
        position: position.clone(),
        velocity: Vector2(
          math.cos(angle) * speed,
          math.sin(angle) * speed - 200.0, // Initial upward bias
        ),
        color: _randomConfettiColor(random),
        size: 6.0 + random.nextDouble() * 6.0,
      );

      _confettiParticles.add(particle);
    }

    notifyListeners();
  }

  Color _randomConfettiColor(math.Random random) {
    // The palette's bright colours; gold leads because the bonus is gold
    const colors = [
      GameConstants.goldColor,
      GameConstants.magentaColor,
      GameConstants.violetColor,
      GameConstants.blueColor,
      GameConstants.cyanColor,
    ];
    return colors[random.nextInt(colors.length)];
  }

  /// Update confetti particle physics
  void updateConfetti(double deltaTime) {
    _confettiParticles.removeWhere((particle) => particle.update(deltaTime));
  }

  /// Update ball counter highlight animation
  void updateBallCountHighlight(double deltaTime) {
    if (_ballCountHighlightTimer > 0) {
      _ballCountHighlightTimer -= deltaTime;
      if (_ballCountHighlightTimer <= 0) {
        _ballCountHighlighted = false;
        _ballCountHighlightTimer = 0;
      }
    }
  }

  void nextLevel() {
    if (_currentLevel != null) {
      _currentLevelNumber++;
      loadLevel(_currentLevelNumber);
      _ballsRemaining = _totalBalls; // Reset balls for new level
    }
  }

  void resetLevel() {
    _score = _levelStartScore;
    _currentLevel?.reset();
    _activeBalls.clear();
    _ballsRemaining = _totalBalls;
    _phase = GamePhase.ready;
    _specialBonusTriggered = false;
    _bonusBallsToAdd = 0;
    _clearEffects();
    notifyListeners();
  }

  /// Removes all transient visual effects (popups, confetti, bonus overlay).
  void _clearEffects() {
    _floatingTexts.clear();
    _confettiParticles.clear();
    _ballCountHighlighted = false;
    _ballCountHighlightTimer = 0.0;
    _bonusDisplayTimer?.cancel();
    _bonusOverlayOpacity = 0.0;
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