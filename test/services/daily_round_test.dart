import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pachinko_game/models/daily_board.dart';
import 'package:pachinko_game/services/daily_leaderboard.dart';
import 'package:pachinko_game/services/game_manager.dart';
import 'package:pachinko_game/services/storage_service.dart';

/// A leaderboard that records what is posted to it, and fails while
/// [online] is false, as Play Games does for a player offline or not
/// signed in.
class RecordingLeaderboard implements DailyLeaderboard {
  bool online = true;
  final posted = <(DailyBoard, int)>[];

  @override
  Future<bool> submit(DailyBoard board, int score) async {
    if (!online) return false;
    posted.add((board, score));
    return true;
  }
}

/// The daily board as the game plays it (#117): the manager is hosted on the
/// test's clock, as in fixed_step_loop_test.dart, and its own clock is set
/// to a fixed moment so that "today" is known.
void main() {
  final noon = DateTime.utc(2026, 11, 23, 12);
  final today = DailyBoard.on(noon);

  /// Storage as a new install has it, or holding [values].
  Future<StorageService> storageWith(
      [Map<String, Object> values = const {}]) async {
    SharedPreferences.setMockInitialValues(values);
    return StorageService(prefs: await SharedPreferences.getInstance());
  }

  /// A manager on [tester]'s clock whose day is that of [now].
  GameManager hostedManager(WidgetTester tester,
      {StorageService? storage, DailyLeaderboard? leaderboard, DateTime? now}) {
    final manager = GameManager(
      storageService: storage,
      leaderboard: leaderboard,
      clock: () => now ?? noon,
    )..attachVsync(tester);
    addTearDown(manager.dispose);
    return manager;
  }

  /// Launches a ball at [power] and plays until the next can be launched or
  /// the round is over.
  Future<void> launchAndSettle(
      WidgetTester tester, GameManager manager, double power) async {
    manager.startLaunchCharging();
    manager.updateLaunchPower(power);
    manager.launchBall();
    await tester.pump();
    while (!manager.gameState.canLaunchBall && !manager.gameState.isGameOver) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  /// Plays a whole daily round, the launch powers going round [powers], and
  /// lets the loop and the bonus announcement finish.
  Future<void> playDailyRound(WidgetTester tester, GameManager manager,
      {List<double> powers = const [20, 55, 90]}) async {
    manager.startGame(daily: manager.today);
    for (int ball = 0; !manager.gameState.isGameOver; ball++) {
      await launchAndSettle(tester, manager, powers[ball % powers.length]);
    }
    await tester.pump(const Duration(seconds: 3));
    manager.stopLoop();
  }

  testWidgets(
      'Given two app sessions on the same day When the same launch powers are played Then the boards and every landing slot are the same',
      (tester) async {
    const powers = [10.0, 35.0, 50.0, 75.0, 100.0, 62.0];

    /// One session's board, as its pegs' places, and where its balls
    /// landed and what they scored. Lists, so that two sessions compare by
    /// value.
    Future<List<Object>> session() async {
      final manager = hostedManager(tester);
      manager.startGame(daily: manager.today);
      final level = manager.gameState.currentLevel!;
      final slots = level.slots;
      final landed = <int>[];
      for (final power in powers) {
        final before = [for (final slot in slots) slot.ballCount];
        await launchAndSettle(tester, manager, power);
        for (int i = 0; i < slots.length; i++) {
          for (int n = before[i]; n < slots[i].ballCount; n++) {
            landed.add(i);
          }
        }
      }
      manager.stopLoop();
      await tester.pump(const Duration(seconds: 3));
      return [
        [for (final peg in level.pegs) (peg.position.x, peg.position.y)],
        landed,
        manager.gameState.levelScore,
      ];
    }

    final first = await session();
    final second = await session();

    expect(first[1], hasLength(greaterThanOrEqualTo(powers.length)));
    expect(second, first);
  });

  testWidgets(
      'Given the daily board When a round is replayed Then it is the same board with the same bounces',
      (tester) async {
    final manager = hostedManager(tester);
    manager.startGame(daily: manager.today);
    final board = manager.gameState.currentLevel;
    await launchAndSettle(tester, manager, 40);
    final firstScore = manager.gameState.levelScore;

    manager.resetGame();
    await launchAndSettle(tester, manager, 40);
    manager.stopLoop();
    await tester.pump(const Duration(seconds: 3));

    expect(manager.gameState.daily, today);
    expect(manager.gameState.currentLevel, same(board));
    expect(manager.gameState.levelScore, firstScore);
  });

  testWidgets(
      'Given a daily round played to the end When recorded Then it is the day\'s best, the streak starts and the score is posted',
      (tester) async {
    final storage = await storageWith();
    final leaderboard = RecordingLeaderboard();
    final manager =
        hostedManager(tester, storage: storage, leaderboard: leaderboard);

    await playDailyRound(tester, manager);
    await tester.pump();

    final score = manager.gameState.levelScore;
    expect(score, greaterThan(0));
    expect(manager.dailyBestToday, score);
    expect(manager.dailyStreak, 1);
    expect(manager.roundIsNewBest, isTrue);
    expect(manager.nextLevelOpen, isFalse,
        reason: 'the daily board has no next level');
    expect(leaderboard.posted, [(today, score)]);
    expect(storage.pendingDailyScore, isNull);
    expect(await storage.levelsWithScores(), isEmpty,
        reason: 'a daily round is no level\'s score');
    expect(storage.storedStars, isEmpty);
  });

  testWidgets(
      'Given today\'s best When a lower round is played Then it is not a best and nothing is posted',
      (tester) async {
    final storage = await storageWith();
    await storage.recordDailyRound(today.day, 1000000);
    final leaderboard = RecordingLeaderboard();
    final manager =
        hostedManager(tester, storage: storage, leaderboard: leaderboard);

    await playDailyRound(tester, manager);
    await tester.pump();

    expect(manager.roundIsNewBest, isFalse);
    expect(manager.dailyBestToday, 1000000);
    expect(leaderboard.posted, isEmpty);
  });

  testWidgets(
      'Given the player offline When a best is won Then it is kept, and posted at the next start',
      (tester) async {
    final storage = await storageWith();
    final leaderboard = RecordingLeaderboard()..online = false;
    final manager =
        hostedManager(tester, storage: storage, leaderboard: leaderboard);
    await playDailyRound(tester, manager);
    await tester.pump();
    final score = manager.gameState.levelScore;
    expect(storage.pendingDailyScore, (day: today.day, score: score));

    // The next start, later the same day, once storage has loaded
    leaderboard.online = true;
    final later = hostedManager(tester, leaderboard: leaderboard);
    later.attachServices(storageService: storage);
    await tester.pump();

    expect(leaderboard.posted, [(today, score)]);
    expect(storage.pendingDailyScore, isNull);
  });

  testWidgets(
      'Given a score kept from yesterday When the game starts today Then it is dropped, not posted',
      (tester) async {
    final storage = await storageWith();
    await storage.savePendingDailyScore(today.day - 1, 9000);
    final leaderboard = RecordingLeaderboard();

    hostedManager(tester, storage: storage, leaderboard: leaderboard);
    await tester.pump();

    expect(leaderboard.posted, isEmpty);
    expect(storage.pendingDailyScore, isNull);
  });

  testWidgets(
      'Given the leaderboard is off When a best is won Then nothing is kept to post',
      (tester) async {
    final storage = await storageWith();
    final manager = hostedManager(tester, storage: storage);

    await playDailyRound(tester, manager);
    await tester.pump();

    expect(manager.roundIsNewBest, isTrue);
    expect(storage.pendingDailyScore, isNull);
  });

  testWidgets(
      'Given a streak up to yesterday When read today Then it stands, and a missed day breaks it',
      (tester) async {
    final storage = await storageWith();
    await storage.recordDailyRound(today.day - 2, 500);
    await storage.recordDailyRound(today.day - 1, 500);

    expect(hostedManager(tester, storage: storage).dailyStreak, 2);
    expect(hostedManager(tester, storage: storage).dailyBestToday, isNull);
    expect(
        hostedManager(tester,
                storage: storage, now: noon.add(const Duration(days: 1)))
            .dailyStreak,
        0);
  });

  testWidgets('Given no storage When read Then there is no best and no streak',
      (tester) async {
    final manager = hostedManager(tester);

    expect(manager.dailyBestToday, isNull);
    expect(manager.dailyStreak, 0);
  });

  testWidgets(
      'Given the daily board When a level is started from the menu Then the level is no longer daily',
      (tester) async {
    final manager = hostedManager(tester);
    manager.startGame(daily: manager.today);
    expect(manager.gameState.currentLevelNumber, today.levelNumber);

    manager.startGame(level: 2);

    expect(manager.gameState.daily, isNull);
    expect(manager.gameState.currentLevel!.name, 'Level 2');
    manager.stopLoop();
  });
}
