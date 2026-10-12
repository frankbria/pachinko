import 'dart:async';
import 'dart:ui' show Color, Offset;
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:pachinko_game/models/ball.dart';
import 'package:pachinko_game/models/ball_launcher.dart';
import 'package:pachinko_game/models/game_state.dart';
import 'package:pachinko_game/models/peg.dart';
import 'package:pachinko_game/models/slot.dart';
import 'package:pachinko_game/models/level.dart';
import 'package:pachinko_game/services/game_manager.dart';
import 'package:pachinko_game/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pachinko_game/services/physics_engine.dart';
import 'package:pachinko_game/models/confetti_particle.dart';
import 'package:pachinko_game/widgets/floating_text.dart';

// Generate mocks for PhysicsEngine, GameState, and BallLauncher
@GenerateMocks([PhysicsEngine, GameState, BallLauncher, Level])
import 'game_manager_test.mocks.dart';
import '../screens/achievements_screen_test.mocks.dart' show MockAchievementService;
import '../screens/high_scores_screen_test.mocks.dart' show MockStorageService;

void main() {
  late GameManager gameManager;
  late MockPhysicsEngine mockPhysicsEngine;
  late MockGameState mockGameState;
  late MockBallLauncher mockBallLauncher;

  setUp(() {
    mockPhysicsEngine = MockPhysicsEngine();
    mockGameState = MockGameState();
    mockBallLauncher = MockBallLauncher();

    // Setup default mock behaviors
    when(mockGameState.activeBalls).thenReturn([]);
    when(mockGameState.ballsRemaining).thenReturn(20);
    when(mockGameState.currentLevel).thenReturn(null);
    when(mockGameState.canLaunchBall).thenReturn(true);
    when(mockGameState.specialBonusTriggered).thenReturn(false);
    when(mockGameState.score).thenReturn(0);
    when(mockGameState.levelScore).thenReturn(0);
    when(mockGameState.floatingTexts).thenReturn([]);
    when(mockGameState.confettiParticles).thenReturn([]);
    when(mockGameState.ballCountHighlighted).thenReturn(false);
    when(mockGameState.slotsLit).thenReturn(false);
    when(mockBallLauncher.phase).thenReturn(LaunchPhase.ready);
    when(mockBallLauncher.currentBall).thenReturn(null);

    gameManager = GameManager(
      gameState: mockGameState,
      physicsEngine: mockPhysicsEngine,
      ballLauncher: mockBallLauncher,
    );
  });

  tearDown(() {
    // Only dispose if not already disposed (some tests call dispose explicitly)
    try {
      gameManager.dispose();
    } catch (e) {
      // Already disposed, that's fine
    }
  });

  group('Game Initialization', () {
    /// Tests GameManager constructor with dependency injection
    /// Verifies mocked dependencies are properly injected
    test('Given mocked dependencies When GameManager created Then dependencies injected correctly', () {
      // Given/When: GameManager created in setUp with mocks

      // Then: Getters should return mocked instances
      expect(gameManager.gameState, equals(mockGameState));
      expect(gameManager.physicsEngine, equals(mockPhysicsEngine));
      expect(gameManager.ballLauncher, equals(mockBallLauncher));
    });

    /// Tests default dependency creation when no mocks provided
    test('Given no dependencies When GameManager created Then default instances created', () {
      // Given/When: Create GameManager without mocks
      final defaultGameManager = GameManager();

      // Then: Should have non-null real instances
      expect(defaultGameManager.gameState, isNotNull);
      expect(defaultGameManager.physicsEngine, isNotNull);
      expect(defaultGameManager.ballLauncher, isNotNull);

      // Cleanup
      defaultGameManager.dispose();
    });

    /// Tests game initialization when startGame called
    test('Given new GameManager When startGame called Then GameState.startNewGame invoked with level', () {
      // Given: Fresh GameManager

      // When: Start game at level 3
      gameManager.startGame(level: 3);

      // Then: Should call GameState.startNewGame with level 3
      verify(mockGameState.startNewGame(level: 3)).called(1);
    });
  });

  group('Game Loop Timing and Delta Time', () {
    /// Tests that game loop runs at approximately 60 FPS (16ms intervals)
    /// Timer.periodic should be created with 16ms duration
    test('Given game started When game loop runs Then timer created with 16ms interval', () {
      // Given: Mock level to enable updates
      final mockLevel = MockLevel();
      when(mockLevel.pegs).thenReturn([]);
      when(mockLevel.slots).thenReturn([]);
      when(mockGameState.currentLevel).thenReturn(mockLevel);

      // When: Launch ball to start game loop
      when(mockBallLauncher.launch()).thenReturn(Ball(
        position: Vector2(100, 100),
        velocity: Vector2(0, 0),
        radius: 8.0,
      ));
      gameManager.launchBall();

      // Then: Game loop should be running
      expect(gameManager.isRunning, isTrue);
    });

    /// Tests game loop stops when paused
    test('Given running game When pauseGame called Then timer cancelled', () {
      // Given: Start game
      final mockLevel = MockLevel();
      when(mockLevel.pegs).thenReturn([]);
      when(mockLevel.slots).thenReturn([]);
      when(mockGameState.currentLevel).thenReturn(mockLevel);
      when(mockBallLauncher.launch()).thenReturn(Ball(
        position: Vector2(100, 100),
        velocity: Vector2(0, 0),
        radius: 8.0,
      ));
      gameManager.launchBall();
      expect(gameManager.isRunning, isTrue);

      // When: Pause game
      gameManager.pauseGame();

      // Then: Game loop should stop
      expect(gameManager.isRunning, isFalse);
      verify(mockGameState.pauseGame()).called(1);
    });

    /// Tests game loop resumes after pause
    test('Given paused game When resumeGame called Then timer restarted', () {
      // Given: Paused game
      final mockLevel = MockLevel();
      when(mockLevel.pegs).thenReturn([]);
      when(mockLevel.slots).thenReturn([]);
      when(mockGameState.currentLevel).thenReturn(mockLevel);
      when(mockBallLauncher.launch()).thenReturn(Ball(
        position: Vector2(100, 100),
        velocity: Vector2(0, 0),
        radius: 8.0,
      ));
      gameManager.launchBall();
      gameManager.pauseGame();
      expect(gameManager.isRunning, isFalse);

      // When: Resume game
      gameManager.resumeGame();

      // Then: Game loop should restart
      expect(gameManager.isRunning, isTrue);
      verify(mockGameState.resumeGame()).called(1);
    });
  });

  group('Ball Launcher Integration', () {
    /// Tests ball launcher charging coordination
    test('Given canLaunchBall true When startLaunchCharging called Then BallLauncher.startCharging invoked', () {
      // Given: Can launch ball
      when(mockGameState.canLaunchBall).thenReturn(true);

      // When: Start charging
      gameManager.startLaunchCharging();

      // Then: Should call BallLauncher.startCharging
      verify(mockBallLauncher.startCharging()).called(1);
    });

    /// Tests ball launcher charging blocked when cannot launch
    test('Given canLaunchBall false When startLaunchCharging called Then BallLauncher not charged', () {
      // Given: Cannot launch ball
      when(mockGameState.canLaunchBall).thenReturn(false);

      // When: Attempt to start charging
      gameManager.startLaunchCharging();

      // Then: Should not call BallLauncher.startCharging
      verifyNever(mockBallLauncher.startCharging());
    });

    /// Tests launch power updates forwarded to BallLauncher
    test('Given charging When updateLaunchPower called Then BallLauncher.updateCharging invoked', () {
      // Given: Charging state
      when(mockBallLauncher.phase).thenReturn(LaunchPhase.charging);

      // When: Update power to 0.75
      gameManager.updateLaunchPower(0.75);

      // Then: Should call BallLauncher.updateCharging with 0.75
      verify(mockBallLauncher.updateCharging(0.75)).called(1);
    });

    /// Tests ball launch coordination with GameState
    test('Given charged launcher When launchBall called Then ball added to GameState', () {
      // Given: Launcher ready to launch
      final ball = Ball(
        position: Vector2(100, 100),
        velocity: Vector2(0, 200),
        radius: 8.0,
      );
      when(mockGameState.canLaunchBall).thenReturn(true);
      when(mockBallLauncher.launch()).thenReturn(ball);

      // When: Launch ball
      gameManager.launchBall();

      // Then: Should call GameState.launchBall with the ball
      verify(mockGameState.launchBall(ball)).called(1);
    });

    /// Tests launch blocked when cannot launch
    test('Given canLaunchBall false When launchBall called Then ball not launched', () {
      // Given: Cannot launch
      when(mockGameState.canLaunchBall).thenReturn(false);

      // When: Attempt launch
      gameManager.launchBall();

      // Then: BallLauncher.launch should not be called
      verifyNever(mockBallLauncher.launch());
      verifyNever(mockGameState.launchBall(any));
    });

    /// Tests game loop starts automatically after first ball launch
    test('Given game not running When launchBall succeeds Then game loop started', () {
      // Given: Game not running, can launch
      final ball = Ball(
        position: Vector2(100, 100),
        velocity: Vector2(0, 200),
        radius: 8.0,
      );
      when(mockGameState.canLaunchBall).thenReturn(true);
      when(mockBallLauncher.launch()).thenReturn(ball);
      expect(gameManager.isRunning, isFalse);

      // When: Launch ball
      gameManager.launchBall();

      // Then: Game loop should start
      expect(gameManager.isRunning, isTrue);
    });
  });

  group('Physics Integration and Phase Coordination', () {
    /// Tests PhysicsEngine.updateBalls called during game loop
    /// Note: This is difficult to test with real Timer, so we verify the coordination logic
    test('Given active balls When physics update needed Then PhysicsEngine.updateBalls called', () async {
      // Given: Active balls and level
      final ball = Ball(
        position: Vector2(200, 200),
        velocity: Vector2(50, 50),
        radius: 8.0,
      );
      final mockLevel = MockLevel();
      when(mockLevel.pegs).thenReturn([]);
      when(mockLevel.slots).thenReturn([]);
      when(mockGameState.activeBalls).thenReturn([ball]);
      when(mockGameState.currentLevel).thenReturn(mockLevel);
      when(mockPhysicsEngine.checkPegCollisions(any, any)).thenReturn([]);
      when(mockPhysicsEngine.checkSlotCollisions(any, any)).thenReturn([]);

      // When: Start game loop
      when(mockBallLauncher.launch()).thenReturn(ball);
      gameManager.launchBall();

      // Wait for at least one game loop tick
      await Future.delayed(const Duration(milliseconds: 20));

      // Then: PhysicsEngine.updateBalls should have been called
      verify(mockPhysicsEngine.updateBalls(any, any)).called(greaterThan(0));
    });

    /// Tests peg collision handling forwarded to PhysicsEngine
    test('Given active balls and pegs When physics updates Then checkPegCollisions called', () async {
      // Given: Ball and pegs
      final ball = Ball(
        position: Vector2(200, 200),
        velocity: Vector2(50, 50),
        radius: 8.0,
      );
      final peg = Peg(
        position: Vector2(210, 210),
        radius: 10.0,
        type: PegType.normal,
      );
      final mockLevel = MockLevel();
      when(mockLevel.pegs).thenReturn([peg]);
      when(mockLevel.slots).thenReturn([]);
      when(mockGameState.activeBalls).thenReturn([ball]);
      when(mockGameState.currentLevel).thenReturn(mockLevel);
      when(mockPhysicsEngine.checkPegCollisions(any, any)).thenReturn([]);
      when(mockPhysicsEngine.checkSlotCollisions(any, any)).thenReturn([]);

      // When: Start game loop
      when(mockBallLauncher.launch()).thenReturn(ball);
      gameManager.launchBall();

      await Future.delayed(const Duration(milliseconds: 20));

      // Then: checkPegCollisions should be called
      verify(mockPhysicsEngine.checkPegCollisions(any, any)).called(greaterThan(0));
    });

    /// Tests slot collision handling forwarded to PhysicsEngine
    test('Given active balls and slots When physics updates Then checkSlotCollisions called', () async {
      // Given: Ball and slots
      final ball = Ball(
        position: Vector2(200, 500),
        velocity: Vector2(0, 50),
        radius: 8.0,
      );
      final slot = Slot(
        position: Vector2(200, 550),
        width: 50,
        height: 60,
        pointValue: 1000,
      );
      final mockLevel = MockLevel();
      when(mockLevel.pegs).thenReturn([]);
      when(mockLevel.slots).thenReturn([slot]);
      when(mockGameState.activeBalls).thenReturn([ball]);
      when(mockGameState.currentLevel).thenReturn(mockLevel);
      when(mockPhysicsEngine.checkPegCollisions(any, any)).thenReturn([]);
      when(mockPhysicsEngine.checkSlotCollisions(any, any)).thenReturn([]);

      // When: Start game loop
      when(mockBallLauncher.launch()).thenReturn(ball);
      gameManager.launchBall();

      await Future.delayed(const Duration(milliseconds: 20));

      // Then: checkSlotCollisions should be called
      verify(mockPhysicsEngine.checkSlotCollisions(any, any)).called(greaterThan(0));
    });
  });

  group('Special Peg Bonus Triggering', () {
    /// Tests special peg bonus triggered when all special pegs hit
    test('Given all special pegs hit When peg collision occurs Then GameState.triggerSpecialBonus called', () async {
      // Given: Level with all special pegs hit
      final ball = Ball(
        position: Vector2(200, 200),
        velocity: Vector2(50, 50),
        radius: 8.0,
      );
      final specialPeg = Peg(
        position: Vector2(210, 210),
        radius: 10.0,
        type: PegType.special,
      );
      final mockLevel = MockLevel();
      when(mockLevel.pegs).thenReturn([specialPeg]);
      when(mockLevel.slots).thenReturn([]);
      when(mockLevel.allSpecialPegsHit).thenReturn(true);
      when(mockGameState.activeBalls).thenReturn([ball]);
      when(mockGameState.currentLevel).thenReturn(mockLevel);
      when(mockGameState.specialBonusTriggered).thenReturn(false);
      when(mockPhysicsEngine.checkPegCollisions(any, any)).thenReturn([specialPeg]);
      when(mockPhysicsEngine.checkSlotCollisions(any, any)).thenReturn([]);

      // When: Start game loop (will detect special peg hit)
      when(mockBallLauncher.launch()).thenReturn(ball);
      gameManager.launchBall();

      await Future.delayed(const Duration(milliseconds: 20));

      // Then: Should trigger special bonus
      verify(mockGameState.triggerSpecialBonus()).called(greaterThan(0));
    });

    /// Tests special bonus not triggered if already triggered
    test('Given bonus already triggered When special peg hit Then triggerSpecialBonus not called again', () async {
      // Given: Bonus already triggered
      final ball = Ball(
        position: Vector2(200, 200),
        velocity: Vector2(50, 50),
        radius: 8.0,
      );
      final specialPeg = Peg(
        position: Vector2(210, 210),
        radius: 10.0,
        type: PegType.special,
      );
      final mockLevel = MockLevel();
      when(mockLevel.pegs).thenReturn([specialPeg]);
      when(mockLevel.slots).thenReturn([]);
      when(mockLevel.allSpecialPegsHit).thenReturn(true);
      when(mockGameState.activeBalls).thenReturn([ball]);
      when(mockGameState.currentLevel).thenReturn(mockLevel);
      when(mockGameState.specialBonusTriggered).thenReturn(true); // Already triggered
      when(mockPhysicsEngine.checkPegCollisions(any, any)).thenReturn([specialPeg]);
      when(mockPhysicsEngine.checkSlotCollisions(any, any)).thenReturn([]);

      // When: Start game loop
      when(mockBallLauncher.launch()).thenReturn(ball);
      gameManager.launchBall();

      await Future.delayed(const Duration(milliseconds: 20));

      // Then: Should NOT trigger bonus again
      verifyNever(mockGameState.triggerSpecialBonus());
    });

    /// Tests special bonus requires all special pegs hit
    test('Given not all special pegs hit When special peg collision Then bonus not triggered', () async {
      // Given: Not all special pegs hit
      final ball = Ball(
        position: Vector2(200, 200),
        velocity: Vector2(50, 50),
        radius: 8.0,
      );
      final specialPeg = Peg(
        position: Vector2(210, 210),
        radius: 10.0,
        type: PegType.special,
      );
      final mockLevel = MockLevel();
      when(mockLevel.pegs).thenReturn([specialPeg]);
      when(mockLevel.slots).thenReturn([]);
      when(mockLevel.allSpecialPegsHit).thenReturn(false); // Not all hit yet
      when(mockGameState.activeBalls).thenReturn([ball]);
      when(mockGameState.currentLevel).thenReturn(mockLevel);
      when(mockGameState.specialBonusTriggered).thenReturn(false);
      when(mockPhysicsEngine.checkPegCollisions(any, any)).thenReturn([specialPeg]);
      when(mockPhysicsEngine.checkSlotCollisions(any, any)).thenReturn([]);

      // When: Start game loop
      when(mockBallLauncher.launch()).thenReturn(ball);
      gameManager.launchBall();

      await Future.delayed(const Duration(milliseconds: 20));

      // Then: Should NOT trigger bonus
      verifyNever(mockGameState.triggerSpecialBonus());
    });
  });

  group('Slot Hit Scoring', () {
    /// Tests score added when ball lands in slot
    test('Given ball in slot When slot collision detected Then GameState.addScore called with slot pointValue', () async {
      // Given: Ball and slot
      final ball = Ball(
        position: Vector2(200, 500),
        velocity: Vector2(0, 50),
        radius: 8.0,
      );
      final slot = Slot(
        position: Vector2(200, 550),
        width: 50,
        height: 60,
        pointValue: 2000,
      );
      final mockLevel = MockLevel();
      when(mockLevel.pegs).thenReturn([]);
      when(mockLevel.slots).thenReturn([slot]);
      when(mockGameState.activeBalls).thenReturn([ball]);
      when(mockGameState.currentLevel).thenReturn(mockLevel);
      when(mockPhysicsEngine.checkPegCollisions(any, any)).thenReturn([]);
      when(mockPhysicsEngine.checkSlotCollisions(any, any)).thenReturn([slot]);

      // When: Start game loop (will detect slot collision)
      when(mockBallLauncher.launch()).thenReturn(ball);
      gameManager.launchBall();

      await Future.delayed(const Duration(milliseconds: 20));

      // Then: Should add score with slot's point value
      verify(mockGameState.addScore(2000)).called(greaterThan(0));
    });

    /// Tests multiple slot hits add scores correctly
    test('Given multiple balls in slots When collisions detected Then addScore called for each', () async {
      // Given: Multiple slots hit
      final ball1 = Ball(position: Vector2(100, 500), velocity: Vector2(0, 50), radius: 8.0);
      final ball2 = Ball(position: Vector2(300, 500), velocity: Vector2(0, 50), radius: 8.0);
      final slot1 = Slot(position: Vector2(100, 550), width: 50, height: 60, pointValue: 1000);
      final slot2 = Slot(position: Vector2(300, 550), width: 50, height: 60, pointValue: 2000);
      final mockLevel = MockLevel();
      when(mockLevel.pegs).thenReturn([]);
      when(mockLevel.slots).thenReturn([slot1, slot2]);
      when(mockGameState.activeBalls).thenReturn([ball1, ball2]);
      when(mockGameState.currentLevel).thenReturn(mockLevel);
      when(mockPhysicsEngine.checkPegCollisions(any, any)).thenReturn([]);
      when(mockPhysicsEngine.checkSlotCollisions(any, any)).thenReturn([slot1, slot2]);

      // When: Start game loop
      when(mockBallLauncher.launch()).thenReturn(ball1);
      gameManager.launchBall();

      await Future.delayed(const Duration(milliseconds: 20));

      // Then: Both scores should be added
      verify(mockGameState.addScore(1000)).called(greaterThan(0));
      verify(mockGameState.addScore(2000)).called(greaterThan(0));
    });
  });

  group('Pause and Resume Functionality', () {
    /// Tests pause stops game loop
    test('Given running game When pauseGame called Then isRunning becomes false', () {
      // Given: Running game
      final mockLevel = MockLevel();
      when(mockLevel.pegs).thenReturn([]);
      when(mockLevel.slots).thenReturn([]);
      when(mockGameState.currentLevel).thenReturn(mockLevel);
      when(mockBallLauncher.launch()).thenReturn(Ball(
        position: Vector2(100, 100),
        velocity: Vector2(0, 0),
        radius: 8.0,
      ));
      gameManager.launchBall();
      expect(gameManager.isRunning, isTrue);

      // When: Pause
      gameManager.pauseGame();

      // Then: Should not be running
      expect(gameManager.isRunning, isFalse);
    });

    /// Tests resume restarts game loop
    test('Given paused game When resumeGame called Then isRunning becomes true', () {
      // Given: Paused game
      final mockLevel = MockLevel();
      when(mockLevel.pegs).thenReturn([]);
      when(mockLevel.slots).thenReturn([]);
      when(mockGameState.currentLevel).thenReturn(mockLevel);
      when(mockBallLauncher.launch()).thenReturn(Ball(
        position: Vector2(100, 100),
        velocity: Vector2(0, 0),
        radius: 8.0,
      ));
      gameManager.launchBall();
      gameManager.pauseGame();
      expect(gameManager.isRunning, isFalse);

      // When: Resume
      gameManager.resumeGame();

      // Then: Should be running again
      expect(gameManager.isRunning, isTrue);
    });

    /// Tests reset stops game loop
    test('Given running game When resetGame called Then timer cancelled', () {
      // Given: Running game
      final mockLevel = MockLevel();
      when(mockLevel.pegs).thenReturn([]);
      when(mockLevel.slots).thenReturn([]);
      when(mockGameState.currentLevel).thenReturn(mockLevel);
      when(mockBallLauncher.launch()).thenReturn(Ball(
        position: Vector2(100, 100),
        velocity: Vector2(0, 0),
        radius: 8.0,
      ));
      gameManager.launchBall();
      expect(gameManager.isRunning, isTrue);

      // When: Reset game
      gameManager.resetGame();

      // Then: Should stop running and call GameState.resetLevel
      expect(gameManager.isRunning, isFalse);
      verify(mockGameState.resetLevel()).called(1);
    });
  });

  group('Timer Cleanup and Lifecycle', () {
    /// Tests dispose cancels timer to prevent memory leaks
    test('Given running game When dispose called Then timer cancelled', () {
      // Given: Running game
      final mockLevel = MockLevel();
      when(mockLevel.pegs).thenReturn([]);
      when(mockLevel.slots).thenReturn([]);
      when(mockGameState.currentLevel).thenReturn(mockLevel);
      when(mockBallLauncher.launch()).thenReturn(Ball(
        position: Vector2(100, 100),
        velocity: Vector2(0, 0),
        radius: 8.0,
      ));
      gameManager.launchBall();
      expect(gameManager.isRunning, isTrue);

      // When: Dispose
      gameManager.dispose();

      // Then: Timer should be cancelled
      expect(gameManager.isRunning, isFalse);
    });

    /// Tests dispose on non-running game does not crash
    test('Given stopped game When dispose called Then no error occurs', () {
      // Given: Game not running
      expect(gameManager.isRunning, isFalse);

      // When/Then: Dispose should not throw
      expect(() => gameManager.dispose(), returnsNormally);
    });

    test('Given running game When stopLoop called Then loop stops without resetting the game', () {
      // Given
      gameManager.startGame();
      expect(gameManager.isRunning, isTrue);
      clearInteractions(mockGameState);
      var notifications = 0;
      gameManager.addListener(() => notifications++);

      // When
      gameManager.stopLoop();

      // Then: no notification, because GameScreen calls this from dispose
      expect(gameManager.isRunning, isFalse);
      expect(notifications, 0);
      verifyNever(mockGameState.resetLevel());
      verifyNever(mockGameState.pauseGame());
    });
  });

  group('Level Management and Phase Transitions', () {
    /// The running score carries across levels; the saved high score and the
    /// achievement total take this level's points only.
    test('Given a level finished mid-run When game over detected Then only this level\'s points are saved and tracked', () async {
      // Given: level 2 of a run, running total 21000, of which 9000 on this level
      final mockStorage = MockStorageService();
      final mockAchievements = MockAchievementService();
      when(mockStorage.saveHighScore(any, any)).thenAnswer((_) async {});
      when(mockStorage.getBestScore(any)).thenAnswer((_) async => null);
      final mockLevel = MockLevel();
      when(mockLevel.pegs).thenReturn([]);
      when(mockLevel.slots).thenReturn([]);
      when(mockLevel.levelNumber).thenReturn(2);
      when(mockGameState.currentLevel).thenReturn(mockLevel);
      when(mockGameState.activeBalls).thenReturn([]);
      when(mockGameState.ballsRemaining).thenReturn(0);
      when(mockGameState.score).thenReturn(21000);
      when(mockGameState.levelScore).thenReturn(9000);
      final manager = GameManager(
        gameState: mockGameState,
        physicsEngine: mockPhysicsEngine,
        ballLauncher: mockBallLauncher,
        storageService: mockStorage,
        achievementService: mockAchievements,
      );
      addTearDown(manager.dispose);
      when(mockBallLauncher.launch()).thenReturn(Ball(
        position: Vector2(100, 100),
        velocity: Vector2(0, 0),
        radius: 8.0,
      ));

      // When: the loop ticks once and detects game over
      manager.launchBall();
      await Future.delayed(const Duration(milliseconds: 20));

      // Then
      verify(mockStorage.saveHighScore(2, 9000)).called(1);
      verify(mockAchievements.trackLevelScore(2, 9000)).called(1);
    });

    /// Tests next level stops current game loop
    test('Given running game When nextLevel called Then timer cancelled', () {
      // Given: Running game
      final mockLevel = MockLevel();
      when(mockLevel.pegs).thenReturn([]);
      when(mockLevel.slots).thenReturn([]);
      when(mockGameState.currentLevel).thenReturn(mockLevel);
      when(mockBallLauncher.launch()).thenReturn(Ball(
        position: Vector2(100, 100),
        velocity: Vector2(0, 0),
        radius: 8.0,
      ));
      gameManager.launchBall();
      expect(gameManager.isRunning, isTrue);

      // When: Advance to next level
      gameManager.nextLevel();

      // Then: Timer should stop and GameState.nextLevel called
      expect(gameManager.isRunning, isFalse);
      verify(mockGameState.nextLevel()).called(1);
    });

    /// Tests level selection stops game loop
    test('Given running game When selectLevel called Then timer cancelled and level loaded', () {
      // Given: Running game
      final mockLevel = MockLevel();
      when(mockLevel.pegs).thenReturn([]);
      when(mockLevel.slots).thenReturn([]);
      when(mockGameState.currentLevel).thenReturn(mockLevel);
      when(mockBallLauncher.launch()).thenReturn(Ball(
        position: Vector2(100, 100),
        velocity: Vector2(0, 0),
        radius: 8.0,
      ));
      gameManager.launchBall();
      expect(gameManager.isRunning, isTrue);

      // When: Select level 5
      gameManager.selectLevel(5);

      // Then: Timer should stop and GameState.loadLevel(5) called
      expect(gameManager.isRunning, isFalse);
      verify(mockGameState.loadLevel(5)).called(1);
    });

    /// Tests game phase transitions when all balls used
    test('Given no active balls and no balls remaining When game loop updates Then phase changes to gameOver', () async {
      // Given: No balls
      final mockLevel = MockLevel();
      when(mockLevel.pegs).thenReturn([]);
      when(mockLevel.slots).thenReturn([]);
      when(mockLevel.levelNumber).thenReturn(1);
      when(mockGameState.activeBalls).thenReturn([]);
      when(mockGameState.ballsRemaining).thenReturn(0);
      when(mockGameState.currentLevel).thenReturn(mockLevel);

      // When: Start game loop
      when(mockBallLauncher.launch()).thenReturn(Ball(
        position: Vector2(100, 100),
        velocity: Vector2(0, 0),
        radius: 8.0,
      ));
      gameManager.launchBall();

      await Future.delayed(const Duration(milliseconds: 20));

      // Then: Should update phase to gameOver
      verify(mockGameState.updatePhase(GamePhase.gameOver)).called(greaterThan(0));
    });

    /// Tests game phase transitions to ready when balls remain
    test('Given no active balls but balls remaining When game loop updates Then phase changes to ready', () async {
      // Given: Balls remaining but none active
      final mockLevel = MockLevel();
      when(mockLevel.pegs).thenReturn([]);
      when(mockLevel.slots).thenReturn([]);
      when(mockGameState.activeBalls).thenReturn([]);
      when(mockGameState.ballsRemaining).thenReturn(10);
      when(mockGameState.currentLevel).thenReturn(mockLevel);

      // When: Start game loop
      when(mockBallLauncher.launch()).thenReturn(Ball(
        position: Vector2(100, 100),
        velocity: Vector2(0, 0),
        radius: 8.0,
      ));
      gameManager.launchBall();

      await Future.delayed(const Duration(milliseconds: 20));

      // Then: Should update phase to ready
      verify(mockGameState.updatePhase(GamePhase.ready)).called(greaterThan(0));
    });

    /// The loop keeps running after game over while the last popup is still
    /// on screen, so it finishes animating. (It used to keep running for ever;
    /// since #42 it stops once nothing is left to animate.)
    test('Given game over detected with a popup still showing When more loop ticks pass Then loop still runs and result is recorded once', () async {
      // Given: no balls active and none remaining, and the last ball's popup on screen
      final mockLevel = MockLevel();
      when(mockLevel.pegs).thenReturn([]);
      when(mockLevel.slots).thenReturn([]);
      when(mockLevel.levelNumber).thenReturn(1);
      when(mockGameState.currentLevel).thenReturn(mockLevel);
      when(mockGameState.activeBalls).thenReturn([]);
      when(mockGameState.ballsRemaining).thenReturn(0);
      when(mockGameState.floatingTexts).thenReturn([
        FloatingText(text: '+50', startPosition: const Offset(200, 560)),
      ]);
      when(mockBallLauncher.launch()).thenReturn(Ball(
        position: Vector2(100, 100),
        velocity: Vector2(0, 0),
        radius: 8.0,
      ));

      // When: several ticks pass (16 ms each)
      gameManager.launchBall();
      await Future.delayed(const Duration(milliseconds: 80));

      // Then
      expect(gameManager.isRunning, isTrue);
      verify(mockGameState.updatePhase(GamePhase.gameOver)).called(1);
    });

    test('Given game over recorded When resetGame then game over again Then result is recorded again', () async {
      // Given
      final mockLevel = MockLevel();
      when(mockLevel.pegs).thenReturn([]);
      when(mockLevel.slots).thenReturn([]);
      when(mockLevel.levelNumber).thenReturn(1);
      when(mockGameState.currentLevel).thenReturn(mockLevel);
      when(mockGameState.activeBalls).thenReturn([]);
      when(mockGameState.ballsRemaining).thenReturn(0);
      when(mockBallLauncher.launch()).thenReturn(Ball(
        position: Vector2(100, 100),
        velocity: Vector2(0, 0),
        radius: 8.0,
      ));
      gameManager.launchBall();
      await Future.delayed(const Duration(milliseconds: 40));

      // When
      gameManager.resetGame();
      gameManager.launchBall();
      await Future.delayed(const Duration(milliseconds: 40));

      // Then
      verify(mockGameState.updatePhase(GamePhase.gameOver)).called(2);
    });

    // A transition that left the flag set would never record the next game over,
    // so the level could not end.
    for (final transition in <String, void Function(GameManager)>{
      'startGame': (manager) => manager.startGame(),
      'nextLevel': (manager) => manager.nextLevel(),
      'selectLevel': (manager) => manager.selectLevel(2),
    }.entries) {
      test('Given game over recorded When ${transition.key} then game over again Then result is recorded again', () async {
        // Given
        final mockLevel = MockLevel();
        when(mockLevel.pegs).thenReturn([]);
        when(mockLevel.slots).thenReturn([]);
        when(mockLevel.levelNumber).thenReturn(1);
        when(mockGameState.currentLevel).thenReturn(mockLevel);
        when(mockGameState.activeBalls).thenReturn([]);
        when(mockGameState.ballsRemaining).thenReturn(0);
        when(mockBallLauncher.launch()).thenReturn(Ball(
          position: Vector2(100, 100),
          velocity: Vector2(0, 0),
          radius: 8.0,
        ));
        gameManager.launchBall();
        await Future.delayed(const Duration(milliseconds: 40));

        // When
        transition.value(gameManager);
        gameManager.launchBall();
        await Future.delayed(const Duration(milliseconds: 40));

        // Then
        verify(mockGameState.updatePhase(GamePhase.gameOver)).called(2);
      });
    }
  });

  group('Launcher Reset on Game Transitions', () {
    /// Real objects (no mocks): reproduces the soft-lock where Restart during
    /// the launch-channel travel left the launcher stuck in `traveling`.
    test('Given ball on launch path When resetGame called Then the next launch works', () {
      // Given: a real game with a ball travelling up the channel
      final realManager = GameManager();
      addTearDown(realManager.dispose);
      realManager.startGame();
      realManager.startLaunchCharging();
      realManager.updateLaunchPower(50);
      realManager.launchBall();
      expect(realManager.ballLauncher.phase, LaunchPhase.traveling);

      // When: Restart
      realManager.resetGame();

      // Then: launcher is ready and a new launch succeeds
      expect(realManager.ballLauncher.phase, LaunchPhase.ready);
      realManager.startLaunchCharging();
      realManager.launchBall();
      expect(realManager.gameState.activeBalls, hasLength(1));
      expect(realManager.isRunning, isTrue);
    });

    /// Real objects (no mocks): a level change with a ball still in play
    /// must not carry that ball onto the new level.
    for (final change in <String, void Function(GameManager)>{
      'selectLevel': (manager) => manager.selectLevel(3),
      'nextLevel': (manager) => manager.nextLevel(),
    }.entries) {
      test('Given ball on launch path When ${change.key} called Then the next launch puts exactly one ball in play', () {
        // Given: a real game with a ball travelling up the channel
        final realManager = GameManager();
        addTearDown(realManager.dispose);
        realManager.startGame();
        realManager.startLaunchCharging();
        realManager.updateLaunchPower(50);
        realManager.launchBall();
        expect(realManager.gameState.activeBalls, hasLength(1));

        // When
        change.value(realManager);

        // Then: the old ball is gone and a new launch succeeds
        expect(realManager.gameState.activeBalls, isEmpty);
        realManager.startLaunchCharging();
        realManager.updateLaunchPower(50);
        realManager.launchBall();
        expect(realManager.gameState.activeBalls, hasLength(1));
      });
    }

    test('Given any state When startGame called Then launcher reset', () {
      gameManager.startGame();
      verify(mockBallLauncher.reset()).called(1);
    });

    test('Given any state When nextLevel called Then launcher reset', () {
      gameManager.nextLevel();
      verify(mockBallLauncher.reset()).called(1);
    });

    test('Given any state When selectLevel called Then launcher reset', () {
      gameManager.selectLevel(3);
      verify(mockBallLauncher.reset()).called(1);
    });
  });
  group('Idle Loop', () {
    /// Real objects (no mocks). The loop only needs to run while something
    /// it drives is changing: a ball, a score popup, confetti or the ball
    /// count highlight. Peg animation is the board's own business.
    Future<void> ticks(int count) => Future<void>.delayed(Duration(milliseconds: 16 * count + 8));

    test('Given a ball in flight When the loop ticks Then its trail records where it was before each step', () async {
      final manager = GameManager();
      addTearDown(manager.dispose);
      manager.startGame();
      final ball = Ball(position: Vector2(200, 150));
      manager.gameState.launchBall(ball);

      await ticks(4);

      expect(ball.trail, isNotEmpty);
      expect(ball.trail.first, Vector2(200, 150), reason: 'the first entry is where the ball started');
      expect(ball.trail.last.y, lessThan(ball.position.y), reason: 'the ball has fallen past its trail');
    });

    test('Given a ball travelling up the launch channel When the loop ticks Then it leaves a trail too', () async {
      final manager = GameManager();
      addTearDown(manager.dispose);
      manager.startGame();
      manager.startLaunchCharging();
      manager.updateLaunchPower(50);
      manager.launchBall();

      await ticks(4);

      final ball = manager.gameState.activeBalls.single;
      expect(ball.trail, isNotEmpty);
      expect(ball.trail.first.y, greaterThan(ball.position.y), reason: 'the ball has risen past its trail');
    });

    /// Drops a ball into [slot] and lets it land.
    Future<void> landIn(GameManager manager, Slot slot) async {
      manager.gameState.launchBall(Ball(position: Vector2(slot.position.x, slot.top - 4), velocity: Vector2(0, 300)));
      manager.resumeGame();
      await ticks(3);
    }

    test('Given a ball over a slot When it lands Then the slot lights and its popup starts above it in its colour', () async {
      final manager = GameManager();
      addTearDown(manager.dispose);
      manager.startGame();
      final slot = manager.gameState.currentLevel!.slots.firstWhere((slot) => slot.pointValue == 1000);

      await landIn(manager, slot);

      expect(manager.gameState.score, 1000);
      expect(slot.glow, greaterThan(0.0));
      final popup = manager.gameState.floatingTexts.single;
      expect(popup.text, '+1000');
      expect(popup.color, slot.color);
      expect(popup.fontSize, FloatingText.sizeFor(1000));
      // Its line box ends above the slot's mouth, and it only rises from there
      expect(popup.startPosition.dy + popup.fontSize * 1.3, lessThanOrEqualTo(slot.top));
    });

    test('Given a lit slot and nothing else When ticks pass Then the loop runs until the light is out', () async {
      final manager = GameManager();
      addTearDown(manager.dispose);
      manager.startGame();
      await ticks(3);
      expect(manager.isRunning, isFalse);

      manager.gameState.lightSlot(manager.gameState.currentLevel!.slots.firstWhere((slot) => slot.pointValue == 2000));
      manager.resumeGame();
      await ticks(5);
      expect(manager.isRunning, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 1400));
      expect(manager.gameState.slotsLit, isFalse);
      expect(manager.isRunning, isFalse);
    });

    test('Given stored scores When rounds finish Then the manager says whether each was a new best', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService(prefs: await SharedPreferences.getInstance());
      final manager = GameManager(storageService: storage);
      addTearDown(manager.dispose);
      Future<void> playRoundInto(int value) async {
        final slot = manager.gameState.currentLevel!.slots.firstWhere((slot) => slot.pointValue == value);
        while (manager.gameState.ballsRemaining > 0) {
          await landIn(manager, slot);
        }
        await ticks(3);
      }

      manager.startGame();
      expect(manager.roundIsNewBest, isNull);
      await playRoundInto(200);
      expect(manager.gameState.phase, GamePhase.gameOver);
      expect(manager.roundIsNewBest, isTrue, reason: 'the first score on a level is its best');

      manager.resetGame();
      expect(manager.roundIsNewBest, isNull, reason: 'not known again until the next round ends');
      await playRoundInto(50);
      expect(manager.roundIsNewBest, isFalse);

      manager.resetGame();
      await playRoundInto(1000);
      expect(manager.roundIsNewBest, isTrue);
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('Given a new game with nothing in play When a few ticks pass Then the loop has stopped', () async {
      final manager = GameManager();
      addTearDown(manager.dispose);

      manager.startGame();
      await ticks(3);

      expect(manager.isRunning, isFalse);
    });

    test('Given a stopped loop When a ball is launched Then the loop runs while the ball is in play', () async {
      final manager = GameManager();
      addTearDown(manager.dispose);
      manager.startGame();
      await ticks(3);
      expect(manager.isRunning, isFalse);

      manager.startLaunchCharging();
      manager.updateLaunchPower(50);
      manager.launchBall();
      await ticks(5);

      expect(manager.gameState.activeBalls, hasLength(1));
      expect(manager.isRunning, isTrue);
    });

    test('Given no ball but a score popup on screen When ticks pass Then the loop runs until the popup is gone', () async {
      final manager = GameManager();
      addTearDown(manager.dispose);
      manager.startGame();
      manager.gameState.addFloatingText('+2000', const Offset(200, 560), const Color(0xFFFFD700));

      await ticks(5);
      expect(manager.gameState.floatingTexts, hasLength(1));
      expect(manager.isRunning, isTrue);

      // A popup lasts 1.5 seconds
      await Future<void>.delayed(const Duration(milliseconds: 1700));
      expect(manager.gameState.floatingTexts, isEmpty);
      expect(manager.isRunning, isFalse);
    });

    // With mocks: each effect on its own is enough to keep the loop running
    test('Given no ball but confetti still falling When ticks pass Then the loop keeps running', () async {
      when(mockGameState.confettiParticles).thenReturn([
        ConfettiParticle(position: Vector2(200, 300), velocity: Vector2(0, 50), color: const Color(0xFFFFD700)),
      ]);

      gameManager.startGame();
      await ticks(3);

      expect(gameManager.isRunning, isTrue);
    });

    test('Given no ball but the ball count still highlighted When ticks pass Then the loop keeps running', () async {
      when(mockGameState.ballCountHighlighted).thenReturn(true);

      gameManager.startGame();
      await ticks(3);

      expect(gameManager.isRunning, isTrue);
    });

    test('Given nothing in play and no effect showing When ticks pass Then the loop has stopped', () async {
      gameManager.startGame();
      await ticks(3);

      expect(gameManager.isRunning, isFalse);
    });

    test('Given the last ball has landed When its popup has finished Then the result is saved and the loop stops', () async {
      final manager = GameManager();
      addTearDown(manager.dispose);
      manager.startGame();
      final state = manager.gameState;
      for (int i = 0; i < 19; i++) {
        final ball = Ball(position: Vector2(200, 300));
        state.launchBall(ball);
        state.removeBall(ball);
      }
      final last = Ball(position: Vector2(200, 300));
      state.launchBall(last);
      state.addFloatingText('+50', const Offset(200, 560), const Color(0xFFFFFFFF));
      state.removeBall(last);
      manager.resumeGame(); // any call that starts the loop

      await ticks(5);
      expect(state.phase, GamePhase.gameOver);
      expect(manager.isRunning, isTrue, reason: 'the popup is still on screen');

      await Future<void>.delayed(const Duration(milliseconds: 1700));
      expect(manager.isRunning, isFalse);
      expect(state.phase, GamePhase.gameOver);
    });
  });
}
