import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vector_math/vector_math_64.dart' show Vector2;
import 'package:pachinko_game/models/ball.dart';
import 'package:pachinko_game/models/game_state.dart';
import 'package:pachinko_game/models/round_summary.dart';
import 'package:pachinko_game/screens/game_screen.dart';
import 'package:pachinko_game/services/game_manager.dart';
import 'package:pachinko_game/services/storage_service.dart';
import 'package:pachinko_game/utils/game_theme.dart';
import 'package:pachinko_game/widgets/game_card.dart';
import 'package:pachinko_game/widgets/round_summary_panel.dart';

/// The round summary: what the panel shows for a given round, and that the
/// game screen puts it up when the last ball lands and wires its three
/// actions to the transitions that already exist.
void main() {
  const example = RoundSummary(
    levelNumber: 3,
    score: 8550,
    tiers: [
      SlotTierTally(pointValue: 2000, balls: 2),
      SlotTierTally(pointValue: 1000, balls: 2),
      SlotTierTally(pointValue: 200, balls: 10),
      SlotTierTally(pointValue: 50, balls: 11),
    ],
    prizePegsCollected: 3,
    prizePegsTotal: 3,
    bonusBalls: 6,
    isNewBest: true,
  );

  Future<void> pumpPanel(WidgetTester tester, RoundSummary summary,
          {List<String>? tapped}) =>
      tester.pumpWidget(MaterialApp(
        theme: buildGameTheme(),
        home: Scaffold(
          body: Center(
            child: RoundSummaryPanel(
              summary: summary,
              onMenu: () => tapped?.add('menu'),
              onReplay: () => tapped?.add('replay'),
              onNextLevel: () => tapped?.add('next'),
            ),
          ),
        ),
      ));

  testWidgets(
      'given the round in the issue, then the panel shows its score, every tier, the prizes and the bonus',
      (tester) async {
    await pumpPanel(tester, example);

    expect(find.text('Level 3'), findsOneWidget);
    expect(find.text('8,550'), findsOneWidget);
    expect(find.text('New best for this level'), findsOneWidget);
    for (final row in [
      ['2000', '× 2', '4,000'],
      ['1000', '× 2', '2,000'],
      ['200', '× 10', '2,000'],
      ['50', '× 11', '550'],
    ]) {
      final line = find
          .ancestor(of: find.text(row[0]), matching: find.byType(Row))
          .first;
      expect(find.descendant(of: line, matching: find.text(row[1])),
          findsOneWidget,
          reason: '$row');
      expect(find.descendant(of: line, matching: find.text(row[2])),
          findsOneWidget,
          reason: '$row');
    }
    expect(find.text('3 of 3'), findsOneWidget);
    expect(find.text('+6'), findsOneWidget);
  });

  testWidgets(
      'given a round that is not a best and earned no bonus, then neither is claimed',
      (tester) async {
    await pumpPanel(
      tester,
      const RoundSummary(
        levelNumber: 1,
        score: 400,
        tiers: [SlotTierTally(pointValue: 200, balls: 2)],
        prizePegsCollected: 1,
        prizePegsTotal: 3,
        bonusBalls: 0,
        isNewBest: false,
      ),
    );

    expect(find.text('New best for this level'), findsNothing);
    expect(find.text('Bonus balls'), findsNothing);
    expect(find.text('1 of 3'), findsOneWidget);
  });

  testWidgets('given the three actions, then each button calls its own',
      (tester) async {
    final tapped = <String>[];
    await pumpPanel(tester, example, tapped: tapped);

    await tester.tap(find.text('Menu'));
    await tester.tap(find.text('Replay'));
    await tester.tap(find.text('Next Level'));

    expect(tapped, ['menu', 'replay', 'next']);
  });

  test('numbers are grouped in thousands', () {
    expect(groupedThousands(0), '0');
    expect(groupedThousands(550), '550');
    expect(groupedThousands(8550), '8,550');
    expect(groupedThousands(1234567), '1,234,567');
  });

  group('On the game screen', () {
    late GameManager manager;

    /// Plays a whole round of [manager]'s level by dropping every ball into
    /// the first 200 slot, with real time passing between balls.
    Future<void> playRound(WidgetTester tester) async {
      final slot = manager.gameState.currentLevel!.slots
          .firstWhere((slot) => slot.pointValue == 200);
      await tester.runAsync(() async {
        while (manager.gameState.ballsRemaining > 0) {
          manager.gameState.launchBall(Ball(
              position: Vector2(slot.position.x, slot.top - 4),
              velocity: Vector2(0, 300)));
          manager.resumeGame();
          await Future<void>.delayed(const Duration(milliseconds: 60));
        }
        await Future<void>.delayed(const Duration(milliseconds: 80));
      });
      await tester.pump();
    }

    Future<void> pumpScreen(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      manager = GameManager(
          storageService:
              StorageService(prefs: await SharedPreferences.getInstance()));
      addTearDown(manager.dispose);
      manager.startGame();
      await tester.pumpWidget(ChangeNotifierProvider<GameManager>.value(
        value: manager,
        child: MaterialApp(
          theme: buildGameTheme(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) => const GameScreen())),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets(
        'given a round in play, then there is no summary; when the last ball lands, then it appears with the round\'s numbers',
        (tester) async {
      await pumpScreen(tester);
      expect(find.byType(RoundSummaryPanel), findsNothing);

      await playRound(tester);

      expect(manager.gameState.phase, GamePhase.gameOver);
      expect(find.byType(RoundSummaryPanel), findsOneWidget);
      expect(find.text('4,000'), findsNWidgets(2),
          reason: 'the score, and the 200 tier: 20 balls');
      expect(find.text('× 20'), findsOneWidget);
      expect(find.text('New best for this level'), findsOneWidget);
    });

    testWidgets(
        'given the summary, when Replay is tapped, then the level starts again with the launcher reset',
        (tester) async {
      await pumpScreen(tester);
      await playRound(tester);

      await tester.tap(find.text('Replay'));
      await tester.pump();

      expect(find.byType(RoundSummaryPanel), findsNothing);
      expect(manager.gameState.currentLevelNumber, 1,
          reason: 'the same level again');
      expect(manager.gameState.ballsRemaining, 20);
      expect(manager.gameState.levelScore, 0);
      expect(manager.ballLauncher.currentBall, isNull);
      expect(manager.gameState.canLaunchBall, isTrue);
    });

    testWidgets(
        'given the summary, when Next Level is tapped, then the next level is ready to play',
        (tester) async {
      await pumpScreen(tester);
      await playRound(tester);

      await tester.tap(find.text('Next Level'));
      await tester.pump();

      expect(find.byType(RoundSummaryPanel), findsNothing);
      expect(manager.gameState.currentLevelNumber, 2);
      expect(manager.ballLauncher.currentBall, isNull);
      expect(manager.gameState.canLaunchBall, isTrue);
    });

    testWidgets(
        'given the summary, when Menu is tapped, then the game screen closes and its loop stops',
        (tester) async {
      await pumpScreen(tester);
      await playRound(tester);

      await tester.tap(find.text('Menu'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(GameScreen), findsNothing);
      expect(manager.isRunning, isFalse);
    });

    testWidgets('given a score change, then the header counts up to it',
        (tester) async {
      await pumpScreen(tester);
      expect(find.text('0'), findsOneWidget);

      manager.gameState.addScore(1000);
      manager.updateLaunchPower(0); // any call that makes the manager notify
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('1000'), findsNothing, reason: 'still counting');

      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('1000'), findsOneWidget);
    });
  });

  test('the panel takes its colours from the theme and the roles', () {
    final source =
        File('lib/widgets/round_summary_panel.dart').readAsStringSync();

    expect(source, isNot(contains('Colors.')));
    expect(source, isNot(contains(RegExp(r'Color(\.from\w+)?\('))));
  });
}
