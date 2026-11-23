import 'package:flutter_test/flutter_test.dart';
import 'package:pachinko_game/models/daily_board.dart';
import 'package:pachinko_game/models/level.dart';
import 'package:pachinko_game/utils/constants.dart';

/// The pegs, prize pegs, features and slots of [level], as plain values to
/// compare two separately generated boards by.
List<Object> layoutOf(Level level) => [
      level.levelNumber,
      [
        for (final peg in level.pegs) (peg.position.x, peg.position.y, peg.type)
      ],
      [for (final peg in level.specialPegs) (peg.position.x, peg.position.y)],
      [for (final feature in level.features) feature.runtimeType],
      [for (final slot in level.slots) (slot.position.x, slot.pointValue)],
    ];

void main() {
  group('Which day counts -', () {
    test('Given 23 November 2026 in UTC When read Then its seed is the date',
        () {
      final board = DailyBoard.on(DateTime.utc(2026, 11, 23, 15, 30));

      expect(board.seed, 20261123);
      expect(board.date, DateTime.utc(2026, 11, 23));
    });

    test(
        'Given the last second before midnight UTC and midnight When read Then they are two days in a row',
        () {
      final before = DailyBoard.on(DateTime.utc(2026, 11, 23, 23, 59, 59));
      final after = DailyBoard.on(DateTime.utc(2026, 11, 24));

      expect(after.day, before.day + 1);
      expect(before.seed, 20261123);
      expect(after.seed, 20261124);
    });

    test(
        'Given phones in New York and Tokyo at the same moment When read Then they have the same board, the UTC date',
        () {
      // 20:00 on 23 November in New York and 10:00 on 24 November in Tokyo
      // are both 01:00 on 24 November in UTC
      final newYork =
          DailyBoard.on(DateTime.parse('2026-11-23T20:00:00-05:00'));
      final tokyo = DailyBoard.on(DateTime.parse('2026-11-24T10:00:00+09:00'));

      expect(newYork, tokyo);
      expect({newYork, tokyo}, hasLength(1));
      expect(newYork.seed, 20261124);
    });

    test(
        'Given the phone\'s local time When read Then the board is that of the same moment in UTC',
        () {
      final moment = DateTime(2026, 11, 23, 12);

      expect(DailyBoard.on(moment), DailyBoard.on(moment.toUtc()));
    });

    test('Given the end of a year When read Then the next day is a new year',
        () {
      final last = DailyBoard.on(DateTime.utc(2026, 12, 31, 12));

      expect(DailyBoard(last.day + 1).seed, 20270101);
    });
  });

  group('The board -', () {
    test(
        'Given the same date When generated twice, as two app sessions would Then the boards are the same',
        () {
      final first = DailyBoard.on(DateTime.utc(2026, 11, 23, 8)).generate();
      final second = DailyBoard.on(DateTime.utc(2026, 11, 23, 22)).generate();

      expect(layoutOf(second), layoutOf(first));
      expect(first.name, GameStrings.daily);
    });

    test(
        'Given two days When generated Then the boards differ from each other and from their level',
        () {
      final today = DailyBoard.on(DateTime.utc(2026, 11, 23));
      final tomorrow = DailyBoard(today.day + 1);
      final level = Level.generate(today.levelNumber, GameConstants.boardWidth,
          GameConstants.boardHeight);

      expect(layoutOf(tomorrow.generate()), isNot(layoutOf(today.generate())));
      expect(layoutOf(today.generate()), isNot(layoutOf(level)));
    });

    test(
        'Given a year of days When each board is read Then its level is one of the daily levels, and each is used',
        () {
      final first = DailyBoard.on(DateTime.utc(2026));
      final levels = {
        for (int day = 0; day < 365; day++)
          DailyBoard(first.day + day).levelNumber
      };

      expect(levels.reduce((a, b) => a < b ? a : b),
          GameConstants.dailyFirstLevel);
      expect(
          levels.reduce((a, b) => a > b ? a : b), GameConstants.dailyLastLevel);
      expect(
          levels,
          hasLength(GameConstants.dailyLastLevel -
              GameConstants.dailyFirstLevel +
              1));
    });

    test('Given a board When generated Then it has every prize peg', () {
      final level = DailyBoard.on(DateTime.utc(2026, 11, 23)).generate();

      expect(level.specialPegs, hasLength(GameConstants.prizePegsPerLevel));
    });
  });

  group('Streak -', () {
    const day = 20000;

    test('Given no round yet When a round is finished Then the streak is one',
        () {
      final streak = DailyStreak.none.playedOn(day);

      expect(streak.length, 1);
      expect(streak.lengthOn(day), 1);
    });

    test(
        'Given a round today When another is finished today Then the streak stays the same',
        () {
      final streak = DailyStreak.none.playedOn(day).playedOn(day);

      expect(streak.length, 1);
    });

    test(
        'Given rounds on three days in a row When read Then the streak is three',
        () {
      final streak =
          DailyStreak.none.playedOn(day).playedOn(day + 1).playedOn(day + 2);

      expect(streak.length, 3);
      expect(streak.lengthOn(day + 2), 3);
    });

    test(
        'Given yesterday\'s round When read today, before playing Then the streak still stands',
        () {
      final streak = DailyStreak.none.playedOn(day).playedOn(day + 1);

      expect(streak.lengthOn(day + 2), 2);
    });

    test('Given a missed day When read Then the streak is broken', () {
      final streak = DailyStreak.none.playedOn(day).playedOn(day + 1);

      expect(streak.lengthOn(day + 3), 0);
    });

    test(
        'Given a missed day When a round is finished Then a new streak of one starts',
        () {
      final streak =
          DailyStreak.none.playedOn(day).playedOn(day + 1).playedOn(day + 3);

      expect(streak.length, 1);
      expect(streak.lastDay, day + 3);
    });

    test(
        'Given the clock put back a day When a round is finished Then the streak is unchanged',
        () {
      final streak = DailyStreak.none.playedOn(day).playedOn(day + 1);

      expect(streak.playedOn(day).length, 2);
      expect(streak.playedOn(day).lastDay, day + 1);
    });
  });
}
