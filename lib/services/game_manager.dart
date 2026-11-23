import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import '../models/ball.dart';
import '../models/ball_landing.dart';
import '../models/ball_launcher.dart';
import '../models/board_feature.dart';
import '../models/daily_board.dart';
import '../models/game_settings.dart';
import '../models/game_state.dart';
import '../models/peg.dart';
import '../models/slot.dart';
import '../models/star_targets.dart';
import '../widgets/floating_text.dart';
import '../utils/constants.dart';
import 'physics_engine.dart';
import 'audio_service.dart';
import 'haptics_service.dart';
import 'storage_service.dart';
import 'achievement_service.dart';
import 'daily_leaderboard.dart';

class GameManager extends ChangeNotifier {
  final GameState _gameState;
  final PhysicsEngine _physicsEngine;
  final BallLauncher _ballLauncher;
  final AudioService? _audioService;
  final HapticsService? _haptics;
  StorageService? _storageService;
  AchievementService? _achievementService;

  /// The display's clock, from the screen that hosts the board. Null while
  /// no screen does, and then the loop does not run.
  Ticker? _ticker;

  /// The screen whose clock [_ticker] runs on.
  TickerProvider? _vsync;

  /// The physics steps run since the ticker last started.
  int _stepsTaken = 0;

  /// Every physics step this manager has run, to space the trail points.
  int _physicsSteps = 0;

  /// The physics steps between two points of a ball's trail: a point every
  /// 1/60 s.
  static const int _stepsPerTrailPoint =
      GameConstants.physicsStepsPerSecond ~/ 60;
  bool _levelResultSaved = false;

  /// Whether the round just finished beat the level's best. Null until the
  /// stored scores have been read, and when there is no storage.
  bool? _roundIsNewBest;

  /// Whether the current level had a star before the round just finished,
  /// once storage has answered.
  bool _levelHadStar = false;
  bool _disposed = false;

  /// Counts the rounds this manager has started. An answer from storage
  /// about one round must not be shown for a later one.
  int _round = 0;

  /// The first ball launched this round, while it is in play. Lucky Shot is
  /// for that ball alone: a bonus ball it set off may land before it does.
  Ball? _firstBall;

  /// Whether this round's first ball has been seen yet.
  bool _firstBallSeen = false;

  /// The player's choice of launch mode, made while there was no storage to
  /// save it to. Saved when storage is attached.
  bool? _unsavedSingleBallLaunch;

  /// Whether the ghost hand is still to show this install's player the drag.
  /// False until storage says otherwise, so that a returning player never
  /// sees it flash up while storage loads.
  bool _launchHintDue = false;

  /// Whether the first prize peg hit on this install is still to come.
  bool _prizePegHintDue = false;

  /// The level's number of prize pegs while the prize peg callout shows.
  int? _prizePegHint;

  /// The player's sound, vibration and motion settings, as applied.
  GameSettings _settings = const GameSettings();

  /// The changes the player made while there was no storage, as one change.
  /// Replayed onto the stored settings when storage is attached, so that a
  /// choice made then stands without undoing the stored ones it did not touch.
  GameSettings Function(GameSettings stored)? _unsavedChange;

  final ValueNotifier<BallLanding?> _lastLanding = ValueNotifier(null);

  /// Where daily scores are posted, or null while the leaderboard is off.
  final DailyLeaderboard? _leaderboard;

  /// The time now, which says which day's board is today's.
  final DateTime Function() _clock;

  /// Creates a GameManager with optional dependency injection.
  ///
  /// Dependencies default to production instances if not provided,
  /// enabling both production use and testability with mocks.
  GameManager({
    GameState? gameState,
    PhysicsEngine? physicsEngine,
    BallLauncher? ballLauncher,
    AudioService? audioService,
    HapticsService? haptics,
    StorageService? storageService,
    AchievementService? achievementService,
    DailyLeaderboard? leaderboard,
    DateTime Function() clock = DateTime.now,
  })  : _audioService = audioService,
        _leaderboard = leaderboard,
        _clock = clock,
        _haptics = haptics,
        _storageService = storageService,
        _achievementService = achievementService,
        _gameState = gameState ?? GameState(),
        _physicsEngine = physicsEngine ??
            PhysicsEngine(audioService: audioService, haptics: haptics),
        _ballLauncher = ballLauncher ?? BallLauncher() {
    // The player's saved choice, when there is storage to read it from
    if (storageService != null) {
      _gameState.singleBallLaunch = storageService.singleBallLaunch;
      _applySettings(storageService.settings);
      _readHints(storageService);
      unawaited(postPendingDailyScore());
    }
  }

  /// Reads which first-round hints this install has still to show.
  void _readHints(StorageService storage) {
    // shortcut: a ball launched before storage loads (it loads at start-up,
    // well before Play can be pressed) does not count as the first launch;
    // track launches made without storage if that ever matters.
    _launchHintDue = storage.launchHintDue;
    _prizePegHintDue = storage.prizePegHintDue;
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
  void attachServices(
      {StorageService? storageService,
      AchievementService? achievementService}) {
    if (achievementService != null) _achievementService = achievementService;
    if (storageService == null || identical(storageService, _storageService)) {
      return;
    }
    _storageService = storageService;
    unawaited(postPendingDailyScore());
    final shownBefore =
        (_gameState.singleBallLaunch, _launchHintDue, _settings);
    _readHints(storageService);

    final unsaved = _unsavedSingleBallLaunch;
    _unsavedSingleBallLaunch = null;
    if (unsaved != null) {
      unawaited(storageService.saveSingleBallLaunch(unsaved));
    } else {
      _gameState.singleBallLaunch = storageService.singleBallLaunch;
    }
    final unsavedChange = _unsavedChange;
    _unsavedChange = null;
    if (unsavedChange != null) {
      _applySettings(unsavedChange(storageService.settings));
      unawaited(storageService.saveSettings(_settings));
    } else {
      _applySettings(storageService.settings);
    }
    if (shownBefore !=
        (_gameState.singleBallLaunch, _launchHintDue, _settings)) {
      scheduleMicrotask(() {
        if (!_disposed) notifyListeners();
      });
    }
  }

  /// Whether the board shows the ghost hand dragging the plunger: on this
  /// install's first round, until the player first launches, and not while
  /// the player is touching the plunger.
  bool get showsLaunchHint =>
      _launchHintDue && _ballLauncher.phase == LaunchPhase.ready;

  /// The level's number of prize pegs while the board shows the callout that
  /// says what they are for, and null otherwise. It is set at the first prize
  /// peg hit on this install, and only then.
  int? get prizePegHint => _prizePegHint;

  /// Takes the prize peg callout down, once it has been shown for its time.
  void dismissPrizePegHint() {
    _prizePegHint = null;
    notifyListeners();
  }

  /// The best score stored for each level that has been played, for the
  /// level picker. Empty when there is no storage.
  Future<Map<int, int>> bestScoresByLevel({int levels = 20}) async {
    final storage = _storageService;
    if (storage == null) return const {};
    final scores = await Future.wait([
      for (int level = 1; level <= levels; level++) storage.getBestScore(level),
    ]);
    return {
      for (int level = 1; level <= levels; level++)
        if (scores[level - 1] case final score?) level: score.score,
    };
  }

  /// The stars won on each level that has a score or stored stars, for the
  /// level picker and its locks. A level's stars are the more of those
  /// stored and those its best score wins on today's targets, so scores
  /// from before stars existed award theirs, and are stored from then on.
  /// Empty when there is no storage.
  Future<Map<int, int>> starsByLevel() async {
    final storage = _storageService;
    if (storage == null) return const {};
    final stored = storage.storedStars;
    final levels = {...await storage.levelsWithScores(), ...stored.keys};
    final stars = await Future.wait([
      for (final level in levels)
        storage.getBestScore(level).then((best) => math.max(stored[level] ?? 0,
            StarTargets.forLevel(level).starsFor(best?.score ?? 0))),
    ]);
    final byLevel = Map.fromIterables(levels, stars);
    // Stars won by scores alone are stored, so that clearing the scores later
    // keeps them
    await Future.wait([
      for (final MapEntry(key: level, value: won) in byLevel.entries)
        if (won > (stored[level] ?? 0)) storage.saveStars(level, won),
    ]);
    return byLevel;
  }

  /// Today's daily board, by the UTC date.
  DailyBoard get today => DailyBoard.on(_clock());

  /// The best score of a daily round finished today, or null when there was
  /// none or there is no storage.
  int? get dailyBestToday => _storageService?.dailyBest(today.day);

  /// The player's streak of days with a daily round finished, as it stands
  /// today: zero once a day has been missed, and without storage.
  int get dailyStreak => _storageService?.dailyStreak.lengthOn(today.day) ?? 0;

  /// Whether the round summary offers Next Level: the level after this one
  /// is open, because this round won a star or the level already had one.
  /// Never on the daily board, which has no next level.
  bool get nextLevelOpen =>
      _gameState.daily == null &&
      (_levelHadStar ||
          StarTargets.forLevel(_gameState.currentLevelNumber)
                  .starsFor(_gameState.levelScore) >=
              1);

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

  /// The player's sound, vibration and motion settings.
  GameSettings get settings => _settings;

  /// Applies [change] to the settings at once (sound, volume and vibration
  /// go to their services; the board reads reduced motion when it paints)
  /// and saves the result for the next start.
  ///
  /// The change is a function of the current settings, not the whole of
  /// them: made before storage has loaded, it is kept and replayed onto the
  /// stored settings when storage arrives (see [attachServices]).
  Future<void> updateSettings(
      GameSettings Function(GameSettings current) change) async {
    _applySettings(change(_settings));
    notifyListeners();
    final storage = _storageService;
    if (storage == null) {
      final earlier = _unsavedChange;
      _unsavedChange = earlier == null
          ? change
          : (GameSettings stored) => change(earlier(stored));
      return;
    }
    await storage.saveSettings(_settings);
  }

  void _applySettings(GameSettings settings) {
    _settings = settings;
    _audioService
      ?..enabled = settings.soundOn
      ..setVolume(settings.soundVolume);
    _haptics?.enabled = settings.vibrationOn;
  }

  /// The last ball to land in a slot, for the game screen to announce to a
  /// screen reader. Null until a ball has landed.
  ValueListenable<BallLanding?> get lastLanding => _lastLanding;

  // Getters
  GameState get gameState => _gameState;
  PhysicsEngine get physicsEngine => _physicsEngine;
  BallLauncher get ballLauncher => _ballLauncher;

  /// Whether the game loop is advancing on the display's frames.
  bool get isRunning => _ticker?.isActive ?? false;

  /// Runs the game loop on the frames of [vsync], the screen that hosts the
  /// board. The screen calls [detachVsync] before it is disposed. The clock
  /// of an earlier screen is let go: the newest host drives the loop, and a
  /// loop that was running goes on running on it.
  void attachVsync(TickerProvider vsync) {
    final wasRunning = isRunning;
    _ticker?.dispose();
    _vsync = vsync;
    _ticker = vsync.createTicker(_onFrame);
    if (wasRunning) _startGameLoop();
  }

  /// Stops the game loop and lets go of [vsync]'s clock, if it is the one
  /// driving the loop, without notifying listeners: the screen calls this
  /// while it is being disposed, perhaps after a newer screen has attached.
  void detachVsync(TickerProvider vsync) {
    if (!identical(vsync, _vsync)) return;
    _ticker?.dispose();
    _ticker = null;
    _vsync = null;
  }

  /// The seed for the bounces of the round [round] of [level], so that the
  /// same level, round and launches play out the same way.
  static int physicsSeedFor(int level, int round) => level * 1000003 + round;

  /// Begins round [_round] on the current level with its own seed. Every
  /// round of the daily board has the board's seed, so the same launches
  /// play out the same way on every phone and in every round of the day.
  void _beginRound() {
    _round++;
    _physicsEngine.seed(_gameState.daily?.seed ??
        physicsSeedFor(_gameState.currentLevelNumber, _round));
  }

  /// Whether the round just finished beat the level's best score. Null while
  /// that is not known: before the stored scores have been read, when there
  /// is no storage, and once another round has begun.
  bool? get roundIsNewBest => _roundIsNewBest;

  /// Clears what the manager tracks about the round being left, for a
  /// transition that starts another. Cancelling the loop strands a launcher
  /// that is carrying a ball, a set [_levelResultSaved] would keep the next
  /// game over from being recorded, the next round has a first ball of its
  /// own, and the prize peg callout gave the count of the level being left.
  void _clearRoundTracking() {
    _ballLauncher.reset();
    _levelResultSaved = false;
    _roundIsNewBest = null;
    _levelHadStar = false;
    _firstBall = null;
    _firstBallSeen = false;
    _prizePegHint = null;
  }

  /// Starts a new run on [level], or on the [daily] board.
  void startGame({int level = 1, DailyBoard? daily}) {
    _clearRoundTracking();
    _gameState.startNewGame(level: level, daily: daily);
    _beginRound();
    _startGameLoop();
    notifyListeners();
  }

  void pauseGame() {
    _ticker?.stop();
    _gameState.pauseGame();
    notifyListeners();
  }

  void resumeGame() {
    _gameState.resumeGame();
    _startGameLoop();
    notifyListeners();
  }

  void resetGame() {
    _clearRoundTracking();
    _ticker?.stop();
    _gameState.resetLevel();
    _beginRound();
    notifyListeners();
  }

  /// Stops the game loop without changing game state or notifying listeners.
  ///
  /// Safe to call while widgets are being disposed.
  void stopLoop() {
    _ticker?.stop();
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
      if (_launchHintDue) {
        _launchHintDue = false;
        _storageService?.saveLaunchHintShown();
      }

      // Track ball launch achievement
      _achievementService?.trackBallLaunched();

      if (!isRunning) {
        _startGameLoop();
      }
    }

    notifyListeners();
  }

  void _startGameLoop() {
    final ticker = _ticker;
    if (ticker == null || ticker.isActive) return;
    _stepsTaken = 0;
    ticker.start();
  }

  /// One display frame, [elapsed] after the ticker started: runs the physics
  /// steps that fall due by then, so the game moves by the same fixed steps
  /// at any frame rate. Time left over that is less than a step is carried
  /// to the next frame; a frame that is due more than
  /// [GameConstants.maxPhysicsIterations] steps drops the rest.
  void _onFrame(Duration elapsed) {
    final stepsDue = elapsed.inMicroseconds *
        GameConstants.physicsStepsPerSecond ~/
        Duration.microsecondsPerSecond;
    final steps =
        math.min(stepsDue - _stepsTaken, GameConstants.maxPhysicsIterations);
    _stepsTaken = stepsDue;
    if (steps <= 0) return;

    for (int step = 0; step < steps; step++) {
      _step(GameConstants.physicsTimeStep);
    }

    // Nothing left for the loop to move: stop until the next launch. The board
    // animates its own pegs, so it does not need these ticks
    if (_isIdle) _ticker?.stop();

    notifyListeners();
  }

  /// Moves the game on by one fixed step of [deltaTime] seconds.
  void _step(double deltaTime) {
    _updatePhysics(deltaTime);

    _gameState.updateFloatingTexts(deltaTime);
    _gameState.updateBallCountHighlight(deltaTime);
    _gameState.updateConfetti(deltaTime);
    _gameState.updateSlotLights(deltaTime);

    _checkGameState();
  }

  /// Whether nothing the loop drives is changing: no ball in play (a ball in
  /// the launch channel counts as in play) and no score popup, confetti or
  /// ball count highlight, and no slot still lit.
  bool get _isIdle =>
      _gameState.activeBalls.isEmpty &&
      _gameState.floatingTexts.isEmpty &&
      _gameState.confettiParticles.isEmpty &&
      !_gameState.ballCountHighlighted &&
      !_gameState.slotsLit;

  void _updatePhysics(double deltaTime) {
    final balls = _gameState.activeBalls;
    final level = _gameState.currentLevel;

    if (level == null) return;

    // Where each ball is before this step moves it, for the trail behind it.
    // Every other step, so the trail spans the same time as at 60 steps a
    // second and looks the same on any display
    if (_physicsSteps++ % _stepsPerTrailPoint == 0) {
      for (final ball in balls) {
        ball.recordTrail();
      }
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

    // The fever lasts for seconds of play, so it runs down only here, with a
    // ball in play; that also keeps the loop running for its meter
    _gameState.updateFever(deltaTime);
    // The features move with play too, so a seeded round repeats exactly
    _physicsEngine.updateFeatures(level.features, deltaTime);

    // Bonus balls only join once a ball has hit pegs, so the first ball in
    // play this round is the first one launched
    if (!_firstBallSeen) {
      _firstBall = balls.first;
      _firstBallSeen = true;
    }

    // Update ball physics (only for balls not on guided path)
    final freeBalls = balls
        .where((ball) =>
            _ballLauncher.currentBall == null ||
            ball != _ballLauncher.currentBall)
        .toList();

    _physicsEngine.updateBalls(freeBalls, deltaTime);

    // Check peg collisions (only for free balls)
    final hitPegs = _physicsEngine.checkPegCollisions(freeBalls, level.pegs);
    _handlePegHits(hitPegs);

    final featureHits =
        _physicsEngine.checkFeatureCollisions(freeBalls, level.features);
    _handleTulipCatches(featureHits);

    // Check slot collisions (only for free balls)
    final hitSlots = _physicsEngine.checkSlotCollisions(freeBalls, level.slots);
    _handleSlotHits(hitSlots);

    // Lucky Shot: this round's first ball has come to its end, and the slot
    // it lies in, if any, is the one it landed in
    final first = _firstBall;
    if (first != null && !first.isActive) {
      if (first.hasLanded &&
          hitSlots.any((slot) =>
              slot.pointValue >= 2000 && slot.containsPoint(first.position))) {
        _achievementService?.trackFirstBallInEdgeSlot();
      }
      _firstBall = null;
    }

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
        _audioService?.playSpecialPeg();
        _haptics?.prizePeg();
        _showPrizePegHintOnce();
        _checkSpecialBonus();
      }
    }
  }

  /// Pays out for each ball an open tulip caught on this step.
  void _handleTulipCatches(List<FeatureHit> hits) {
    for (final hit in hits) {
      final tulip = hit.feature;
      if (!hit.caught || tulip is! Tulip) continue;
      _gameState.payTulip(tulip);
      _audioService?.playTulipCatch();
      _haptics?.prizePeg();
    }
  }

  /// At the first prize peg hit on this install, tells the player how many
  /// there are to collect for the bonus.
  void _showPrizePegHintOnce() {
    if (!_prizePegHintDue) return;
    _prizePegHintDue = false;
    _prizePegHint = _gameState.currentLevel?.specialPegs.length;
    _storageService?.savePrizePegHintShown();
  }

  void _handleSlotHits(List<Slot> hitSlots) {
    for (final slot in hitSlots) {
      final points = _gameState.scoreLanding(slot);
      _audioService?.playSlotScore(slot.pointValue);
      _haptics?.slot(slot.pointValue);

      // The slot lights, and the popup starts above its mouth, clear of its
      // value, in the slot's own colour and at a size that goes by the score
      _gameState.lightSlot(slot);
      final row = _gameState.currentLevel?.slots ?? const <Slot>[];
      _lastLanding.value = BallLanding(
        points: points,
        slotIndex: row.indexOf(slot),
        slotCount: row.length,
      );
      final size = FloatingText.sizeFor(points);
      _gameState.addFloatingText(
        '+$points',
        Offset(slot.position.x, slot.top - size * 1.4),
        slot.color,
        fontSize: size,
      );

      // Track edge slot achievement (edge slots are worth 2000 points)
      if (slot.pointValue >= 2000) {
        _achievementService?.trackEdgeSlot();
      }
    }
  }

  void _checkSpecialBonus() {
    final level = _gameState.currentLevel;
    if (level == null || _gameState.specialBonusTriggered) return;

    if (level.allSpecialPegsHit) {
      _gameState.triggerSpecialBonus();
      _audioService?.playBonusTrigger();
      _haptics?.bonus();

      // Spawn confetti at center of board
      _gameState.spawnConfetti(
        vm.Vector2(GameConstants.boardWidth / 2, GameConstants.boardHeight / 2),
        50, // 50 confetti particles
      );

      // Track achievements
      _achievementService?.trackAllSpecialPegsHit();
      _achievementService?.trackSpecialBonus();
      // The ball that collected the last prize peg is still in play; if it
      // collected them all, its count is the level's
      final prizePegs = level.specialPegs.length;
      if (prizePegs > 0 &&
          _gameState.activeBalls
              .any((ball) => ball.prizePegsCollected == prizePegs)) {
        _achievementService?.trackAllPrizePegsWithOneBall();
      }
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
  /// A daily round is recorded as the day's instead, and counts for no
  /// level's scores, stars or achievements.
  void _saveHighScore() {
    final storageService = _storageService;
    final level = _gameState.currentLevel?.levelNumber ?? 1;
    final score = _gameState.levelScore;
    final daily = _gameState.daily;
    if (daily != null) {
      if (storageService != null) {
        _recordDailyRound(storageService, daily, score);
      }
      return;
    }

    if (storageService != null) {
      _recordScore(storageService, level, score);
    }

    // Track achievements for level completion and score
    _achievementService?.trackLevelComplete(level);
    _achievementService?.trackLevelScore(level, score);
  }

  /// Saves [score] for [level] and the stars it wins, and works out first
  /// whether it beats the level's best and whether the level already had a
  /// star, so that the round summary can say so and offer Next Level.
  Future<void> _recordScore(
      StorageService storage, int level, int score) async {
    final round = _round;
    // No score stored counts as a best of zero: a first round without a point
    // is saved, but the summary does not call it a best
    final best = (await storage.getBestScore(level))?.score ?? 0;
    final targets = StarTargets.forLevel(level);
    final starsBefore =
        math.max(storage.storedStars[level] ?? 0, targets.starsFor(best));
    await storage.saveHighScore(level, score);
    await storage.saveStars(
        level, math.max(starsBefore, targets.starsFor(score)));
    // The player may have moved on, or left, while storage answered
    if (_disposed || round != _round) return;
    _roundIsNewBest = score > best;
    _levelHadStar = starsBefore >= 1;
    notifyListeners();
  }

  /// Records a daily round of [score] on [board]: the day's best and the
  /// streak, and a new best for the day is posted to the leaderboard, or
  /// kept to post later. Then the summary can say whether it was a best.
  Future<void> _recordDailyRound(
      StorageService storage, DailyBoard board, int score) async {
    final round = _round;
    final best = storage.dailyBest(board.day) ?? 0;
    await storage.recordDailyRound(board.day, score);
    if (score > best && _leaderboard != null) {
      await storage.savePendingDailyScore(board.day, score);
      await postPendingDailyScore();
    }
    if (_disposed || round != _round) return;
    _roundIsNewBest = score > best;
    notifyListeners();
  }

  /// Posts the daily score kept for the leaderboard, if there is one. A
  /// score from an earlier day is dropped, because that day's board is over;
  /// one that fails to post (the player is offline or not signed in) is kept
  /// and tried again at the next start or the next best of the day.
  Future<void> postPendingDailyScore() async {
    final storage = _storageService;
    final leaderboard = _leaderboard;
    if (storage == null || leaderboard == null) return;
    final pending = storage.pendingDailyScore;
    if (pending == null) return;
    final board = today;
    if (pending.day != board.day ||
        await leaderboard.submit(board, pending.score)) {
      await storage.clearPendingDailyScore();
    }
  }

  void nextLevel() {
    _clearRoundTracking();
    _ticker?.stop();
    _gameState.nextLevel();
    _beginRound();
    notifyListeners();
  }

  /// Jumps to [levelNumber] within the current run.
  ///
  /// No screen calls this: the level picker starts a new game with
  /// [startGame]. It keeps the running score, including points from the level
  /// that is left, so whoever gives it a caller should first decide whether a
  /// jump starts a new run (raised in the reviews of #5 and #20).
  void selectLevel(int levelNumber) {
    _clearRoundTracking();
    _ticker?.stop();
    _gameState.loadLevel(levelNumber);
    _beginRound();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.dispose();
    _ticker = null;
    _vsync = null;
    _lastLanding.dispose();
    super.dispose();
  }
}
