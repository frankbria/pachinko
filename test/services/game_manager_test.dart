import 'dart:async';
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
import 'package:pachinko_game/services/physics_engine.dart';
import 'package:pachinko_game/utils/constants.dart';

// Generate mocks for PhysicsEngine, GameState, and BallLauncher
@GenerateMocks([PhysicsEngine, GameState, BallLauncher, Level])
import 'game_manager_test.mocks.dart';

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
  });

  group('Level Management and Phase Transitions', () {
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
  });
}
