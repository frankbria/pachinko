import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:pachinko_game/models/game_state.dart';
import 'package:pachinko_game/models/ball.dart';
import 'package:vector_math/vector_math_64.dart';

/// Comprehensive unit tests for GameState model
///
/// Tests state management with ChangeNotifier, score tracking, ball launching,
/// bonus mechanics (5 + level/2 formula), level progression, game over conditions,
/// and ChangeNotifier notification behavior.
///
/// Testing Strategy:
/// - ChangeNotifier validation: Use listener callbacks to verify notifyListeners() calls
/// - State mutations: Verify state changes and listener notifications
/// - Bonus formula: Validate 5 + (level ~/ 2) calculation at different levels
/// - Phase transitions: Test GamePhase state machine with activeBalls and ballsRemaining
/// - Game over: Verify condition (ballsRemaining <= 0 && activeBalls.isEmpty)
void main() {
  group('GameState Initialization -', () {
    test('given GameState constructor, when created, then initializes with default values', () {
      /// Validates initial state setup before any game starts
      /// Default state: score=0, balls=20, phase=loading, no active balls, no level loaded
      
      // Given / When
      final gameState = GameState();

      // Then
      expect(gameState.score, equals(0));
      expect(gameState.ballsRemaining, equals(20));
      expect(gameState.totalBalls, equals(20));
      expect(gameState.phase, equals(GamePhase.loading));
      expect(gameState.activeBalls, isEmpty);
      expect(gameState.currentLevel, isNull);
      expect(gameState.currentLevelNumber, equals(1));
      expect(gameState.specialBonusTriggered, isFalse);
      expect(gameState.isGameOver, isFalse);
      expect(gameState.canLaunchBall, isFalse); // phase != ready
    });

    test('given GameState, when startNewGame called, then initializes game with level 1', () {
      /// Validates startNewGame() resets score, balls, and loads first level
      /// Sets phase to ready for ball launching
      
      // Given
      final gameState = GameState();

      // When
      gameState.startNewGame();

      // Then
      expect(gameState.score, equals(0));
      expect(gameState.ballsRemaining, equals(20));
      expect(gameState.phase, equals(GamePhase.ready));
      expect(gameState.currentLevel, isNotNull);
      expect(gameState.currentLevelNumber, equals(1));
      expect(gameState.canLaunchBall, isTrue);
    });

    test('given GameState, when startNewGame called with custom level, then loads specified level', () {
      /// Validates startNewGame() can start at any level number
      
      // Given
      final gameState = GameState();

      // When
      gameState.startNewGame(level: 5);

      // Then
      expect(gameState.currentLevelNumber, equals(5));
      expect(gameState.currentLevel, isNotNull);
      expect(gameState.phase, equals(GamePhase.ready));
    });
  });

  group('Score Management -', () {
    test('given GameState, when addScore called, then score increases', () {
      /// Validates addScore() correctly adds points to cumulative score
      
      // Given
      final gameState = GameState();
      gameState.startNewGame();

      // When
      gameState.addScore(100);

      // Then
      expect(gameState.score, equals(100));
    });

    test('given GameState, when addScore called multiple times, then score accumulates', () {
      /// Validates cumulative scoring across multiple addScore() calls
      
      // Given
      final gameState = GameState();
      gameState.startNewGame();

      // When
      gameState.addScore(100);
      gameState.addScore(250);
      gameState.addScore(50);

      // Then
      expect(gameState.score, equals(400));
    });

    test('given GameState with listener, when addScore called, then notifyListeners triggered', () {
      /// Validates ChangeNotifier behavior: addScore() calls notifyListeners()
      /// Uses listener callback counter to verify notification
      
      // Given
      final gameState = GameState();
      gameState.startNewGame();
      int listenerCallCount = 0;
      gameState.addListener(() {
        listenerCallCount++;
      });

      // When
      gameState.addScore(100);

      // Then - listener should be called
      expect(listenerCallCount, greaterThan(0));
      expect(gameState.score, equals(100));
    });
  });

  group('Ball Launching -', () {
    test('given GameState ready, when launchBall called, then ballsRemaining decrements', () {
      /// Validates launchBall() decrements ballsRemaining counter
      
      // Given
      final gameState = GameState();
      gameState.startNewGame();
      final initialBalls = gameState.ballsRemaining;
      final ball = Ball(position: Vector2(200, 300));

      // When
      gameState.launchBall(ball);

      // Then
      expect(gameState.ballsRemaining, equals(initialBalls - 1));
      expect(gameState.ballsRemaining, equals(19));
    });

    test('given GameState ready, when launchBall called, then ball added to activeBalls', () {
      /// Validates launchBall() adds ball to active balls list
      
      // Given
      final gameState = GameState();
      gameState.startNewGame();
      final ball = Ball(position: Vector2(200, 300));

      // When
      gameState.launchBall(ball);

      // Then
      expect(gameState.activeBalls.length, equals(1));
      expect(gameState.activeBalls.contains(ball), isTrue);
    });

    test('given GameState ready, when launchBall called, then phase changes to playing', () {
      /// Validates launchBall() triggers phase transition: ready → playing
      
      // Given
      final gameState = GameState();
      gameState.startNewGame();
      expect(gameState.phase, equals(GamePhase.ready));

      // When
      gameState.launchBall(Ball(position: Vector2(200, 300)));

      // Then
      expect(gameState.phase, equals(GamePhase.playing));
    });

    test('given GameState with canLaunchBall false, when launchBall called, then no effect', () {
      /// Validates launchBall() guard condition: only works when canLaunchBall is true
      /// canLaunchBall requires phase==ready AND ballsRemaining>0
      
      // Given
      final gameState = GameState();
      // Don't call startNewGame - phase will be loading
      expect(gameState.canLaunchBall, isFalse);
      final initialBalls = gameState.ballsRemaining;

      // When
      gameState.launchBall(Ball(position: Vector2(200, 300)));

      // Then - no change
      expect(gameState.ballsRemaining, equals(initialBalls));
      expect(gameState.activeBalls, isEmpty);
    });

    test('given GameState ready with listener, when launchBall called, then notifyListeners triggered', () {
      /// Validates ChangeNotifier behavior: launchBall() calls notifyListeners()
      
      // Given
      final gameState = GameState();
      gameState.startNewGame();
      int listenerCallCount = 0;
      gameState.addListener(() {
        listenerCallCount++;
      });

      // When
      gameState.launchBall(Ball(position: Vector2(200, 300)));

      // Then
      expect(listenerCallCount, greaterThan(0));
    });

    test('given GameState with multiple balls launched, when tracking, then ballsRemaining decrements correctly', () {
      /// Validates ball tracking across multiple launches

      // Given
      final gameState = GameState();
      gameState.startNewGame();

      // When
      gameState.launchBall(Ball(position: Vector2(200, 300)));
      gameState.updatePhase(GamePhase.ready); // Reset to ready for next launch
      gameState.launchBall(Ball(position: Vector2(210, 300)));
      gameState.updatePhase(GamePhase.ready);
      gameState.launchBall(Ball(position: Vector2(220, 300)));

      // Then
      expect(gameState.ballsRemaining, equals(17)); // 20 - 3
      expect(gameState.activeBalls.length, equals(3));
    });
  });

  group('Ball Removal and Phase Transitions -', () {
    test('given GameState with active ball, when removeBall called, then ball removed from activeBalls', () {
      /// Validates removeBall() removes ball from active list
      
      // Given
      final gameState = GameState();
      gameState.startNewGame();
      final ball = Ball(position: Vector2(200, 300));
      gameState.launchBall(ball);
      expect(gameState.activeBalls.length, equals(1));

      // When
      gameState.removeBall(ball);

      // Then
      expect(gameState.activeBalls.length, equals(0));
    });

    test('given GameState with last active ball, when removeBall called and balls remain, then phase returns to ready', () {
      /// Validates phase transition: when all balls removed but more balls available, return to ready
      
      // Given
      final gameState = GameState();
      gameState.startNewGame();
      final ball = Ball(position: Vector2(200, 300));
      gameState.launchBall(ball);
      expect(gameState.ballsRemaining, greaterThan(0));

      // When
      gameState.removeBall(ball);

      // Then
      expect(gameState.activeBalls, isEmpty);
      expect(gameState.phase, equals(GamePhase.ready));
    });

    test('given GameState with last ball, when removeBall called and no balls remain, then phase changes to gameOver', () {
      /// Validates game over condition: ballsRemaining==0 && activeBalls.isEmpty

      // Given
      final gameState = GameState();
      gameState.startNewGame();
      // Launch all 20 balls
      for (int i = 0; i < 20; i++) {
        gameState.launchBall(Ball(position: Vector2(200.0 + i, 300)));
        if (i < 19) gameState.updatePhase(GamePhase.ready); // Reset phase for next launch
      }
      expect(gameState.ballsRemaining, equals(0));
      expect(gameState.activeBalls.length, equals(20));

      // When - remove all balls
      final ballsToRemove = List.from(gameState.activeBalls);
      for (final ball in ballsToRemove) {
        gameState.removeBall(ball);
      }

      // Then
      expect(gameState.phase, equals(GamePhase.gameOver));
      expect(gameState.isGameOver, isTrue);
    });

    test('given GameState with listener, when removeBall called, then notifyListeners triggered', () {
      /// Validates ChangeNotifier behavior: removeBall() calls notifyListeners()
      
      // Given
      final gameState = GameState();
      gameState.startNewGame();
      final ball = Ball(position: Vector2(200, 300));
      gameState.launchBall(ball);
      int listenerCallCount = 0;
      gameState.addListener(() {
        listenerCallCount++;
      });

      // When
      gameState.removeBall(ball);

      // Then
      expect(listenerCallCount, greaterThan(0));
    });
  });

  group('Bonus Mechanics -', () {
    test('given GameState level 1, when triggerSpecialBonus called, then adds 5 bonus balls', () {
      /// Validates bonus formula: 5 + (level ~/ 2)
      /// Level 1: 5 + (1 ~/ 2) = 5 + 0 = 5 bonus balls
      
      // Given
      final gameState = GameState();
      gameState.startNewGame(level: 1);
      final initialActiveBalls = gameState.activeBalls.length;

      // When
      gameState.triggerSpecialBonus();

      // Then - 5 bonus balls added directly to activeBalls
      expect(gameState.activeBalls.length, equals(initialActiveBalls + 5));
    });

    test('given GameState level 2, when triggerSpecialBonus called, then adds 6 bonus balls', () {
      /// Level 2: 5 + (2 ~/ 2) = 5 + 1 = 6 bonus balls
      
      // Given
      final gameState = GameState();
      gameState.startNewGame(level: 2);

      // When
      gameState.triggerSpecialBonus();

      // Then
      expect(gameState.activeBalls.length, equals(6));
    });

    test('given GameState level 4, when triggerSpecialBonus called, then adds 7 bonus balls', () {
      /// Level 4: 5 + (4 ~/ 2) = 5 + 2 = 7 bonus balls
      
      // Given
      final gameState = GameState();
      gameState.startNewGame(level: 4);

      // When
      gameState.triggerSpecialBonus();

      // Then
      expect(gameState.activeBalls.length, equals(7));
    });

    test('given GameState level 10, when triggerSpecialBonus called, then adds 10 bonus balls', () {
      /// Level 10: 5 + (10 ~/ 2) = 5 + 5 = 10 bonus balls
      
      // Given
      final gameState = GameState();
      gameState.startNewGame(level: 10);

      // When
      gameState.triggerSpecialBonus();

      // Then
      expect(gameState.activeBalls.length, equals(10));
    });

    test('given GameState, when triggerSpecialBonus called, then specialBonusTriggered becomes true', () {
      /// Validates bonus trigger flag prevents multiple bonus activations
      
      // Given
      final gameState = GameState();
      gameState.startNewGame();
      expect(gameState.specialBonusTriggered, isFalse);

      // When
      gameState.triggerSpecialBonus();

      // Then
      expect(gameState.specialBonusTriggered, isTrue);
    });

    test('given bonus already triggered, when triggerSpecialBonus called again, then no additional balls added', () {
      /// Validates guard condition: bonus can only trigger once per level
      
      // Given
      final gameState = GameState();
      gameState.startNewGame();
      gameState.triggerSpecialBonus();
      final ballsAfterFirstBonus = gameState.activeBalls.length;

      // When
      gameState.triggerSpecialBonus(); // Try to trigger again

      // Then - no additional balls added
      expect(gameState.activeBalls.length, equals(ballsAfterFirstBonus));
    });

    test('given GameState with listener, when triggerSpecialBonus called, then notifyListeners triggered', () {
      /// Validates ChangeNotifier behavior: triggerSpecialBonus() calls notifyListeners()
      
      // Given
      final gameState = GameState();
      gameState.startNewGame();
      int listenerCallCount = 0;
      gameState.addListener(() {
        listenerCallCount++;
      });

      // When
      gameState.triggerSpecialBonus();

      // Then
      expect(listenerCallCount, greaterThan(0));
    });
  });

  group('Level Progression -', () {
    test('given GameState on level 1, when nextLevel called, then level increments to 2', () {
      /// Validates nextLevel() increments currentLevelNumber
      
      // Given
      final gameState = GameState();
      gameState.startNewGame(level: 1);
      expect(gameState.currentLevelNumber, equals(1));

      // When
      gameState.nextLevel();

      // Then
      expect(gameState.currentLevelNumber, equals(2));
    });

    test('given GameState, when nextLevel called, then new level loaded', () {
      /// Validates nextLevel() loads a new Level instance
      
      // Given
      final gameState = GameState();
      gameState.startNewGame(level: 1);
      final oldLevel = gameState.currentLevel;

      // When
      gameState.nextLevel();

      // Then - new level instance loaded
      expect(gameState.currentLevel, isNotNull);
      expect(gameState.currentLevel, isNot(same(oldLevel)));
    });

    test('given GameState, when nextLevel called, then balls reset to totalBalls', () {
      /// Validates nextLevel() resets ballsRemaining for new level
      
      // Given
      final gameState = GameState();
      gameState.startNewGame();
      // Launch some balls
      gameState.launchBall(Ball(position: Vector2(200, 300)));
      gameState.launchBall(Ball(position: Vector2(210, 300)));
      expect(gameState.ballsRemaining, lessThan(gameState.totalBalls));

      // When
      gameState.nextLevel();

      // Then
      expect(gameState.ballsRemaining, equals(gameState.totalBalls));
      expect(gameState.ballsRemaining, equals(20));
    });

    test('given GameState, when nextLevel called, then phase set to ready', () {
      /// Validates nextLevel() resets phase to ready for new level
      
      // Given
      final gameState = GameState();
      gameState.startNewGame();
      gameState.updatePhase(GamePhase.playing);

      // When
      gameState.nextLevel();

      // Then
      expect(gameState.phase, equals(GamePhase.ready));
    });

    test('given GameState, when nextLevel called, then specialBonusTriggered reset', () {
      /// Validates nextLevel() resets bonus trigger flag for new level
      
      // Given
      final gameState = GameState();
      gameState.startNewGame();
      gameState.triggerSpecialBonus();
      expect(gameState.specialBonusTriggered, isTrue);

      // When
      gameState.nextLevel();

      // Then
      expect(gameState.specialBonusTriggered, isFalse);
    });
  });

  group('Game Over Conditions -', () {
    test('given GameState with balls remaining, when checked, then isGameOver returns false', () {
      /// Validates game over condition: false when ballsRemaining > 0
      
      // Given
      final gameState = GameState();
      gameState.startNewGame();

      // When / Then
      expect(gameState.ballsRemaining, greaterThan(0));
      expect(gameState.isGameOver, isFalse);
    });

    test('given GameState with active balls, when checked, then isGameOver returns false', () {
      /// Validates game over condition: false when activeBalls not empty
      
      // Given
      final gameState = GameState();
      gameState.startNewGame();
      gameState.launchBall(Ball(position: Vector2(200, 300)));

      // When / Then
      expect(gameState.activeBalls, isNotEmpty);
      expect(gameState.isGameOver, isFalse);
    });

    test('given GameState with no balls and no active balls, when checked, then isGameOver returns true', () {
      /// Validates game over condition: true when ballsRemaining <= 0 AND activeBalls.isEmpty

      // Given
      final gameState = GameState();
      gameState.startNewGame();
      // Launch and remove all balls
      for (int i = 0; i < 20; i++) {
        final ball = Ball(position: Vector2(200.0 + i, 300));
        gameState.launchBall(ball);
        if (i < 19) gameState.updatePhase(GamePhase.ready);
      }
      final ballsToRemove = List.from(gameState.activeBalls);
      for (final ball in ballsToRemove) {
        gameState.removeBall(ball);
      }

      // When / Then
      expect(gameState.ballsRemaining, equals(0));
      expect(gameState.activeBalls, isEmpty);
      expect(gameState.isGameOver, isTrue);
    });

    test('given GameState game over, when canLaunchBall checked, then returns false', () {
      /// Validates canLaunchBall: false when game over (ballsRemaining <= 0)

      // Given
      final gameState = GameState();
      gameState.startNewGame();
      // Exhaust all balls
      for (int i = 0; i < 20; i++) {
        final ball = Ball(position: Vector2(200.0 + i, 300));
        gameState.launchBall(ball);
        if (i < 19) gameState.updatePhase(GamePhase.ready);
      }
      final ballsToRemove = List.from(gameState.activeBalls);
      for (final ball in ballsToRemove) {
        gameState.removeBall(ball);
      }

      // When / Then
      expect(gameState.isGameOver, isTrue);
      expect(gameState.canLaunchBall, isFalse);
    });
  });

  group('Reset Functionality -', () {
    test('given GameState with hit pegs, when resetLevel called, then level state resets', () {
      /// Validates resetLevel() calls currentLevel.reset()
      
      // Given
      final gameState = GameState();
      gameState.startNewGame();
      // Level should exist after startNewGame
      expect(gameState.currentLevel, isNotNull);

      // When
      gameState.resetLevel();

      // Then - level reset() was called (we can't directly verify but state should be reset)
      expect(gameState.phase, equals(GamePhase.ready));
      expect(gameState.specialBonusTriggered, isFalse);
    });

    test('given GameState with active balls, when resetLevel called, then activeBalls cleared', () {
      /// Validates resetLevel() clears all active balls

      // Given
      final gameState = GameState();
      gameState.startNewGame();
      gameState.launchBall(Ball(position: Vector2(200, 300)));
      gameState.updatePhase(GamePhase.ready);
      gameState.launchBall(Ball(position: Vector2(210, 300)));
      expect(gameState.activeBalls.length, equals(2));

      // When
      gameState.resetLevel();

      // Then
      expect(gameState.activeBalls, isEmpty);
    });

    test('given GameState with used balls, when resetLevel called, then ballsRemaining reset to totalBalls', () {
      /// Validates resetLevel() restores full ball count
      
      // Given
      final gameState = GameState();
      gameState.startNewGame();
      gameState.launchBall(Ball(position: Vector2(200, 300)));
      expect(gameState.ballsRemaining, lessThan(gameState.totalBalls));

      // When
      gameState.resetLevel();

      // Then
      expect(gameState.ballsRemaining, equals(gameState.totalBalls));
      expect(gameState.ballsRemaining, equals(20));
    });

    test('given GameState with listener, when resetLevel called, then notifyListeners triggered', () {
      /// Validates ChangeNotifier behavior: resetLevel() calls notifyListeners()
      
      // Given
      final gameState = GameState();
      gameState.startNewGame();
      int listenerCallCount = 0;
      gameState.addListener(() {
        listenerCallCount++;
      });

      // When
      gameState.resetLevel();

      // Then
      expect(listenerCallCount, greaterThan(0));
    });
  });

  group('Phase Transitions -', () {
    test('given GameState, when updatePhase called, then phase changes', () {
      /// Validates direct phase update via updatePhase()
      
      // Given
      final gameState = GameState();
      gameState.startNewGame();
      expect(gameState.phase, equals(GamePhase.ready));

      // When
      gameState.updatePhase(GamePhase.playing);

      // Then
      expect(gameState.phase, equals(GamePhase.playing));
    });

    test('given GameState with listener, when updatePhase called, then notifyListeners triggered', () {
      /// Validates ChangeNotifier behavior: updatePhase() calls notifyListeners()
      
      // Given
      final gameState = GameState();
      gameState.startNewGame();
      int listenerCallCount = 0;
      gameState.addListener(() {
        listenerCallCount++;
      });

      // When
      gameState.updatePhase(GamePhase.levelComplete);

      // Then
      expect(listenerCallCount, greaterThan(0));
    });
  });

  group('Pause and Resume -', () {
    test('given GameState playing, when pauseGame called, then phase changes to ready', () {
      /// Validates pause functionality changes phase to ready (simple pause implementation)
      
      // Given
      final gameState = GameState();
      gameState.startNewGame();
      gameState.updatePhase(GamePhase.playing);

      // When
      gameState.pauseGame();

      // Then
      expect(gameState.phase, equals(GamePhase.ready));
    });

    test('given GameState paused with active balls, when resumeGame called, then phase changes to playing', () {
      /// Validates resume functionality restores playing phase when balls are active
      
      // Given
      final gameState = GameState();
      gameState.startNewGame();
      gameState.launchBall(Ball(position: Vector2(200, 300)));
      gameState.pauseGame();
      expect(gameState.activeBalls, isNotEmpty);

      // When
      gameState.resumeGame();

      // Then
      expect(gameState.phase, equals(GamePhase.playing));
    });

    test('given GameState paused with no active balls, when resumeGame called, then phase unchanged', () {
      /// Validates resume guard condition: only resume if activeBalls not empty
      
      // Given
      final gameState = GameState();
      gameState.startNewGame();
      gameState.pauseGame();
      expect(gameState.activeBalls, isEmpty);
      expect(gameState.phase, equals(GamePhase.ready));

      // When
      gameState.resumeGame();

      // Then - phase stays ready (no active balls to resume)
      expect(gameState.phase, equals(GamePhase.ready));
    });

    test('given GameState, when pauseGame called with listener, then notifyListeners triggered', () {
      /// Validates ChangeNotifier behavior: pauseGame() calls notifyListeners()
      
      // Given
      final gameState = GameState();
      gameState.startNewGame();
      gameState.updatePhase(GamePhase.playing);
      int listenerCallCount = 0;
      gameState.addListener(() {
        listenerCallCount++;
      });

      // When
      gameState.pauseGame();

      // Then
      expect(listenerCallCount, greaterThan(0));
    });

    test('given GameState, when resumeGame called with listener, then notifyListeners triggered', () {
      /// Validates ChangeNotifier behavior: resumeGame() calls notifyListeners()
      
      // Given
      final gameState = GameState();
      gameState.startNewGame();
      gameState.launchBall(Ball(position: Vector2(200, 300)));
      gameState.pauseGame();
      int listenerCallCount = 0;
      gameState.addListener(() {
        listenerCallCount++;
      });

      // When
      gameState.resumeGame();

      // Then
      expect(listenerCallCount, greaterThan(0));
    });
  });

  group('ChangeNotifier Behavior -', () {
    test('given GameState with listener, when loadLevel called, then notifyListeners triggered', () {
      /// Validates ChangeNotifier behavior: loadLevel() calls notifyListeners()
      
      // Given
      final gameState = GameState();
      int listenerCallCount = 0;
      gameState.addListener(() {
        listenerCallCount++;
      });

      // When
      gameState.loadLevel(1);

      // Then
      expect(listenerCallCount, greaterThan(0));
    });

    test('given GameState with multiple listeners, when state changes, then all listeners notified', () {
      /// Validates multiple listeners can be attached and all receive notifications
      
      // Given
      final gameState = GameState();
      gameState.startNewGame();
      int listener1CallCount = 0;
      int listener2CallCount = 0;
      gameState.addListener(() {
        listener1CallCount++;
      });
      gameState.addListener(() {
        listener2CallCount++;
      });

      // When
      gameState.addScore(100);

      // Then - both listeners should be called
      expect(listener1CallCount, greaterThan(0));
      expect(listener2CallCount, greaterThan(0));
    });

    test('given GameState with listener removed, when state changes, then removed listener not called', () {
      /// Validates listener removal works correctly
      
      // Given
      final gameState = GameState();
      gameState.startNewGame();
      int listenerCallCount = 0;
      void listener() {
        listenerCallCount++;
      }
      gameState.addListener(listener);
      gameState.addScore(50); // Trigger once
      final initialCallCount = listenerCallCount;
      
      // When - remove listener and trigger again
      gameState.removeListener(listener);
      gameState.addScore(50);

      // Then - call count should not increase
      expect(listenerCallCount, equals(initialCallCount));
    });
  });

  group('Bonus Screen Auto-Dismiss -', () {
    test('given bonus triggered, when 2.5 seconds elapse, then bonus flag resets', () async {
      /// Validates bonus overlay auto-dismisses after 2.5 seconds

      // Given
      final gameState = GameState();
      gameState.startNewGame();
      gameState.triggerSpecialBonus();
      expect(gameState.specialBonusTriggered, isTrue);
      expect(gameState.bonusOverlayOpacity, equals(1.0));

      // When - wait 2.6 seconds (past 2.5s timer)
      await Future.delayed(const Duration(milliseconds: 2600));

      // Then
      expect(gameState.specialBonusTriggered, isFalse);
      expect(gameState.bonusOverlayOpacity, equals(0.0));
    });

    test('given bonus triggered, when less than 2 seconds elapse, then bonus still visible', () async {
      /// Validates bonus overlay stays visible during timer period

      // Given
      final gameState = GameState();
      gameState.startNewGame();
      gameState.triggerSpecialBonus();

      // When - wait 1 second (less than 2.5s timer)
      await Future.delayed(const Duration(milliseconds: 1000));

      // Then - bonus still visible
      expect(gameState.specialBonusTriggered, isTrue);
      expect(gameState.bonusOverlayOpacity, equals(1.0));
    });

    test('given bonus triggered twice in quick succession, when timer runs, then only one dismissal occurs', () async {
      /// Validates timer cancellation prevents multiple dismissals
      /// Second trigger should cancel first timer and start new one

      // Given
      final gameState = GameState();
      gameState.startNewGame();

      gameState.triggerSpecialBonus();
      await Future.delayed(const Duration(milliseconds: 500));

      // Reset bonus flag to allow second trigger
      gameState.resetLevel();
      gameState.startNewGame();

      gameState.triggerSpecialBonus(); // Trigger again (should cancel first timer)

      // When - wait 2.6 seconds from SECOND trigger
      await Future.delayed(const Duration(milliseconds: 2600));

      // Then - bonus dismissed only once
      expect(gameState.specialBonusTriggered, isFalse);
      expect(gameState.bonusOverlayOpacity, equals(0.0));
    });

    test('given bonus triggered, when resetLevel called, then timer cancelled and bonus cleared', () {
      /// Validates resetLevel() cancels pending bonus timer

      // Given
      final gameState = GameState();
      gameState.startNewGame();
      gameState.triggerSpecialBonus();
      expect(gameState.specialBonusTriggered, isTrue);

      // When
      gameState.resetLevel();

      // Then - bonus cleared immediately
      expect(gameState.specialBonusTriggered, isFalse);
      expect(gameState.bonusOverlayOpacity, equals(0.0));
    });

    test('given bonus triggered, when GameState disposed, then timer cancelled without error', () {
      /// Validates dispose() properly cleans up timer

      // Given
      final gameState = GameState();
      gameState.startNewGame();
      gameState.triggerSpecialBonus();

      // When - dispose should not throw
      expect(() => gameState.dispose(), returnsNormally);
    });

    test('given bonus triggered, when dismissed by timer, then notifyListeners triggered', () async {
      /// Validates ChangeNotifier notification on auto-dismiss

      // Given
      final gameState = GameState();
      gameState.startNewGame();
      int listenerCallCount = 0;
      gameState.addListener(() {
        listenerCallCount++;
      });

      final callCountBeforeBonus = listenerCallCount;
      gameState.triggerSpecialBonus();
      final callCountAfterBonus = listenerCallCount;

      // When - wait for auto-dismiss
      await Future.delayed(const Duration(milliseconds: 2600));

      // Then - listener called on both trigger and dismiss
      expect(callCountAfterBonus, greaterThan(callCountBeforeBonus)); // Called on trigger
      expect(listenerCallCount, greaterThan(callCountAfterBonus)); // Called on auto-dismiss
    });
  });

  group('Visual Feedback -', () {
    test('given GameState, when addFloatingText called, then floating text added to list', () {
      /// Validates addFloatingText() adds text to floatingTexts list

      // Given
      final gameState = GameState();
      gameState.startNewGame();
      expect(gameState.floatingTexts, isEmpty);

      // When
      gameState.addFloatingText(
        '+100',
        const Offset(100, 100),
        const Color(0xFFFFFFFF),
      );

      // Then
      expect(gameState.floatingTexts.length, equals(1));
      expect(gameState.floatingTexts.first.text, equals('+100'));
    });

    test('given GameState with floating text, when updateFloatingTexts called with time, then texts updated', () {
      /// Validates updateFloatingTexts() updates text animations

      // Given
      final gameState = GameState();
      gameState.startNewGame();
      gameState.addFloatingText(
        '+100',
        const Offset(100, 100),
        const Color(0xFFFFFFFF),
      );
      final initialTexts = gameState.floatingTexts.length;

      // When - update with small time delta
      gameState.updateFloatingTexts(0.5);

      // Then - text still exists (not expired yet)
      expect(gameState.floatingTexts.length, equals(initialTexts));
    });

    test('given GameState with expired floating text, when updateFloatingTexts called, then expired texts removed', () {
      /// Validates updateFloatingTexts() removes expired texts

      // Given
      final gameState = GameState();
      gameState.startNewGame();
      gameState.addFloatingText(
        '+100',
        const Offset(100, 100),
        const Color(0xFFFFFFFF),
      );
      expect(gameState.floatingTexts.length, equals(1));

      // When - update with time beyond duration (1.6s > 1.5s)
      gameState.updateFloatingTexts(1.6);

      // Then - text removed
      expect(gameState.floatingTexts, isEmpty);
    });

    test('given GameState, when spawnConfetti called, then correct number of particles created', () {
      /// Validates spawnConfetti() creates requested number of particles

      // Given
      final gameState = GameState();
      gameState.startNewGame();
      expect(gameState.confettiParticles, isEmpty);

      // When
      gameState.spawnConfetti(Vector2(200, 300), 50);

      // Then - 50 particles created
      expect(gameState.confettiParticles.length, equals(50));
    });

    test('given GameState with confetti, when updateConfetti called with time, then particles updated', () {
      /// Validates updateConfetti() updates particle physics

      // Given
      final gameState = GameState();
      gameState.startNewGame();
      gameState.spawnConfetti(Vector2(200, 300), 10);
      final initialParticles = gameState.confettiParticles.length;

      // When - update with small time delta
      gameState.updateConfetti(0.5);

      // Then - particles still exist (not expired yet)
      expect(gameState.confettiParticles.length, equals(initialParticles));
    });

    test('given GameState with expired confetti, when updateConfetti called, then expired particles removed', () {
      /// Validates updateConfetti() removes expired particles

      // Given
      final gameState = GameState();
      gameState.startNewGame();
      gameState.spawnConfetti(Vector2(200, 300), 10);
      expect(gameState.confettiParticles.length, equals(10));

      // When - update with time beyond maxLifetime (2.5s > 2.0s)
      gameState.updateConfetti(2.5);

      // Then - all particles removed
      expect(gameState.confettiParticles, isEmpty);
    });

    test('given GameState, when ball counter highlight triggered, then ballCountHighlighted is true', () {
      /// Validates triggerSpecialBonus() activates ball counter highlight

      // Given
      final gameState = GameState();
      gameState.startNewGame();
      expect(gameState.ballCountHighlighted, isFalse);

      // When
      gameState.triggerSpecialBonus();

      // Then
      expect(gameState.ballCountHighlighted, isTrue);
    });

    test('given GameState with ball counter highlight, when timer expires, then highlight deactivates', () {
      /// Validates updateBallCountHighlight() deactivates after duration

      // Given
      final gameState = GameState();
      gameState.startNewGame();
      gameState.triggerSpecialBonus();
      expect(gameState.ballCountHighlighted, isTrue);

      // When - update beyond highlight duration (1.1s > 1.0s)
      gameState.updateBallCountHighlight(1.1);

      // Then
      expect(gameState.ballCountHighlighted, isFalse);
    });

    test('given GameState with ball counter highlight, when timer running, then highlight remains active', () {
      /// Validates updateBallCountHighlight() keeps highlight during timer

      // Given
      final gameState = GameState();
      gameState.startNewGame();
      gameState.triggerSpecialBonus();
      expect(gameState.ballCountHighlighted, isTrue);

      // When - update within duration (0.5s < 1.0s)
      gameState.updateBallCountHighlight(0.5);

      // Then
      expect(gameState.ballCountHighlighted, isTrue);
    });

    test('given GameState with listener, when addFloatingText called, then notifyListeners triggered', () {
      /// Validates ChangeNotifier behavior: addFloatingText() calls notifyListeners()

      // Given
      final gameState = GameState();
      gameState.startNewGame();
      int listenerCallCount = 0;
      gameState.addListener(() {
        listenerCallCount++;
      });

      // When
      gameState.addFloatingText(
        '+100',
        const Offset(100, 100),
        const Color(0xFFFFFFFF),
      );

      // Then
      expect(listenerCallCount, greaterThan(0));
    });

    test('given GameState with listener, when spawnConfetti called, then notifyListeners triggered', () {
      /// Validates ChangeNotifier behavior: spawnConfetti() calls notifyListeners()

      // Given
      final gameState = GameState();
      gameState.startNewGame();
      int listenerCallCount = 0;
      gameState.addListener(() {
        listenerCallCount++;
      });

      // When
      gameState.spawnConfetti(Vector2(200, 300), 50);

      // Then
      expect(listenerCallCount, greaterThan(0));
    });
  });
}