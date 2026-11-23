import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:pachinko_game/models/ball.dart';
import 'package:pachinko_game/screens/game_screen.dart';
import 'package:pachinko_game/services/game_manager.dart';
import 'package:pachinko_game/utils/constants.dart';
import 'package:pachinko_game/utils/game_theme.dart';

/// The game loop advances the physics in fixed steps on the display's clock,
/// and seeds the bounces from the level and the round (#108). These tests
/// host a real manager on the test's clock, whose frames come only when a
/// test pumps them, so each test chooses its own frame times.
void main() {
  /// A real game on [level], its loop hosted on the test's clock.
  GameManager hostedGame(WidgetTester tester, {int level = 1}) {
    final manager = GameManager()..attachVsync(tester);
    addTearDown(manager.dispose);
    manager.startGame(level: level);
    return manager;
  }

  /// Launches a ball at [power] from the plunger.
  void launch(GameManager manager, double power) {
    manager.startLaunchCharging();
    manager.updateLaunchPower(power);
    manager.launchBall();
  }

  /// Plays frames [fps] times a second until [seconds] have passed since
  /// the loop started. Each frame lands on the whole microsecond nearest its
  /// true time, so every frame rate reaches exactly the same moment.
  Future<void> playFrames(WidgetTester tester,
      {required int fps, required int seconds}) async {
    // The first frame starts the ticker: no time has passed in it
    await tester.pump();
    var now = 0;
    for (int frame = 1; frame <= fps * seconds; frame++) {
      final next = (frame * Duration.microsecondsPerSecond / fps).round();
      await tester.pump(Duration(microseconds: next - now));
      now = next;
    }
  }

  testWidgets(
      'Given the same launch When frames come 30, 60 or 120 times a second Then the ball is in the same place at the same time',
      (tester) async {
    final positions = <int, Vector2>{};
    for (final fps in [30, 60, 120]) {
      final manager = hostedGame(tester);
      launch(manager, 60);

      await playFrames(tester, fps: fps, seconds: 1);

      final ball = manager.gameState.activeBalls.single;
      positions[fps] = ball.position.clone();
      manager.stopLoop();
    }

    expect(positions[60], positions[30]);
    expect(positions[120], positions[30]);
    expect(positions[30]!.y, lessThan(GameConstants.launchChannelEndY + 200),
        reason: 'a second in, the ball is still high on the board');
  });

  testWidgets(
      'Given a ball at the fastest speed the board allows When a 1/30 s frame passes Then it bounces off the pin under it',
      (tester) async {
    final manager = hostedGame(tester);
    final level = manager.gameState.currentLevel!;
    // One pin on the board, so nothing else can stop the ball
    final pin = level.pegs.first;
    level.pegs.retainWhere((peg) => identical(peg, pin));

    // A ball launched at full power that then falls the whole height of the
    // board: faster than any ball in play can go
    final fastest = math.sqrt(
        GameConstants.launchSpeedMax * GameConstants.launchSpeedMax +
            2 * GameConstants.gravity * GameConstants.boardHeight);
    // A 1/30 s frame moves it further than a pin and a ball across, which
    // one step of a whole frame would have carried it clean through
    expect(fastest / 30, greaterThan(2 * (pin.radius + 8)));
    final ball = Ball(
      position: Vector2(pin.position.x, pin.position.y - pin.radius - 8 - 10),
      velocity: Vector2(0, fastest),
    );
    manager.gameState.launchBall(ball);

    await tester.pump();
    await tester.pump(const Duration(microseconds: 33334));

    expect(ball.velocity.y, lessThan(0), reason: 'the ball bounced back up');
    expect(ball.position.y, lessThan(pin.position.y),
        reason: 'the ball is still above the pin');
    manager.stopLoop();
  });

  /// Plays [powers] one ball at a time on a new game of [level] and says
  /// which slot each ball landed in, counted from the left, or -1 for a
  /// launch whose ball fell between two slots.
  Future<List<int>> landingSlots(WidgetTester tester, List<double> powers,
      {required int level}) async {
    final manager = hostedGame(tester, level: level);
    final slots = manager.gameState.currentLevel!.slots;
    final landed = <int>[];
    for (final power in powers) {
      final before = [for (final slot in slots) slot.ballCount];
      launch(manager, power);
      await tester.pump();
      while (!manager.gameState.canLaunchBall) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      final landedBefore = landed.length;
      for (int i = 0; i < slots.length; i++) {
        if (slots[i].ballCount > before[i]) landed.add(i);
      }
      if (landed.length == landedBefore) landed.add(-1);
    }
    manager.stopLoop();
    // The bonus announcement takes itself down on a timer of its own
    await tester.pump(const Duration(seconds: 3));
    return landed;
  }

  testWidgets(
      'Given the same level, round and launch powers When played twice Then every ball lands in the same slot',
      (tester) async {
    const powers = [10.0, 35.0, 50.0, 75.0, 100.0];

    final first = await landingSlots(tester, powers, level: 4);
    final second = await landingSlots(tester, powers, level: 4);

    expect(first, hasLength(greaterThanOrEqualTo(powers.length)));
    expect(second, first);
  });

  testWidgets(
      'Given a second screen has attached When the first lets go Then the second still drives the loop',
      (tester) async {
    final manager = GameManager();
    addTearDown(manager.dispose);
    final firstScreen = _Vsync(tester);
    final secondScreen = _Vsync(tester);
    manager.attachVsync(firstScreen);
    manager.attachVsync(secondScreen);
    manager.startGame();
    launch(manager, 50);

    manager.detachVsync(firstScreen);
    expect(manager.isRunning, isTrue, reason: 'not the clock in use');

    manager.detachVsync(secondScreen);
    expect(manager.isRunning, isFalse);
    manager.startLaunchCharging();
    manager.launchBall();
    expect(manager.isRunning, isFalse, reason: 'no screen hosts the loop');
  });

  testWidgets(
      'Given a ball in play When another screen attaches Then the loop goes on running on its clock',
      (tester) async {
    final manager = GameManager();
    addTearDown(manager.dispose);
    final firstScreen = _Vsync(tester);
    manager.attachVsync(firstScreen);
    manager.startGame();
    launch(manager, 50);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final ball = manager.gameState.activeBalls.single;
    final before = ball.position.clone();

    manager.attachVsync(_Vsync(tester));
    manager.detachVsync(firstScreen);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(manager.isRunning, isTrue);
    expect(ball.position, isNot(before), reason: 'the ball still moves');
    manager.stopLoop();
  });

  testWidgets(
      'Given a game screen replaced by another When the old one is disposed after a launch on the new one Then the ball plays on',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final manager = GameManager()..startGame();
    addTearDown(manager.dispose);
    late NavigatorState navigator;
    await tester.pumpWidget(ChangeNotifierProvider<GameManager>.value(
      value: manager,
      child: MaterialApp(
        theme: buildGameTheme(),
        home: Builder(builder: (context) {
          navigator = Navigator.of(context);
          return const SizedBox();
        }),
      ),
    ));
    navigator.push(MaterialPageRoute<void>(builder: (_) => const GameScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // The new screen is built, and takes the loop, while the old one is
    // still on its way out; a ball is launched before the old one goes
    navigator.pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const GameScreen()));
    await tester.pump();
    launch(manager, 50);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(GameScreen), findsOneWidget,
        reason: 'the old screen is gone');
    expect(manager.isRunning, isTrue);
    expect(manager.gameState.activeBalls, isNotEmpty);
    manager.stopLoop();
  });

  testWidgets(
      'Given the loop is running When the manager is disposed and then its screen lets go Then nothing fails',
      (tester) async {
    final manager = GameManager()..attachVsync(tester);
    manager.startGame();
    launch(manager, 50);
    expect(manager.isRunning, isTrue);

    manager.dispose();

    expect(manager.isRunning, isFalse);
    expect(() => manager.detachVsync(tester), returnsNormally);
  });

  test('Given two rounds or two levels When seeded Then the seeds differ', () {
    expect(GameManager.physicsSeedFor(3, 1), GameManager.physicsSeedFor(3, 1));
    expect(GameManager.physicsSeedFor(3, 2),
        isNot(GameManager.physicsSeedFor(3, 1)));
    expect(GameManager.physicsSeedFor(4, 1),
        isNot(GameManager.physicsSeedFor(3, 1)));
  });
}

/// A screen's clock: another provider of the test's tickers, so a test can
/// tell two hosting screens apart.
class _Vsync implements TickerProvider {
  _Vsync(this._tester);
  final WidgetTester _tester;

  @override
  Ticker createTicker(TickerCallback onTick) => _tester.createTicker(onTick);
}
