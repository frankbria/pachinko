import 'dart:math';
import 'level.dart';
import '../utils/constants.dart';

/// The board of one calendar day, the same on every phone (#117).
///
/// The day is the date in UTC, not the phone's own: every player has the
/// same board at the same moment, which a shared leaderboard needs, and
/// moving the phone to another time zone neither changes the board nor
/// gives a second one on the same day. The board changes at midnight UTC.
class DailyBoard {
  /// The day, counted in whole days from 1 January 1970 (UTC).
  final int day;

  const DailyBoard(this.day);

  /// The board of the UTC date at [moment], whatever time zone [moment] is
  /// written in.
  factory DailyBoard.on(DateTime moment) {
    final utc = moment.toUtc();
    return DailyBoard(
        DateTime.utc(utc.year, utc.month, utc.day).millisecondsSinceEpoch ~/
            Duration.millisecondsPerDay);
  }

  /// The board's date, at midnight UTC.
  DateTime get date => DateTime.utc(1970, 1, 1 + day);

  /// The seed of the board's layout and of its bounces: the date written as
  /// a number, 20261123 for 23 November 2026, so it is the same everywhere.
  int get seed => date.year * 10000 + date.month * 100 + date.day;

  /// The level whose pattern, features, colours and bonus the board plays
  /// with: one of [GameConstants.dailyFirstLevel] to
  /// [GameConstants.dailyLastLevel], picked by the [seed].
  int get levelNumber =>
      GameConstants.dailyFirstLevel +
      Random(seed).nextInt(
          GameConstants.dailyLastLevel - GameConstants.dailyFirstLevel + 1);

  /// Generates the board. Two calls, in one app or on two phones, give the
  /// same pegs, prize pegs, features and slots.
  Level generate() => Level.generate(
      levelNumber, GameConstants.boardWidth, GameConstants.boardHeight,
      seed: seed, name: GameStrings.daily);

  @override
  bool operator ==(Object other) => other is DailyBoard && other.day == day;

  @override
  int get hashCode => day.hashCode;
}

/// The player's run of days in a row with a daily round played to the end.
class DailyStreak {
  /// The last day a daily round was finished on, as [DailyBoard.day].
  final int lastDay;

  /// How many days in a row, up to [lastDay], had a daily round finished.
  final int length;

  const DailyStreak({required this.lastDay, required this.length});

  /// No daily round finished yet.
  static const DailyStreak none = DailyStreak(lastDay: 0, length: 0);

  /// The streak once a daily round has been finished on [day]: one longer the
  /// day after the last, the same on the same day (or a day the clock was
  /// put back to), and a new streak of one after a missed day.
  DailyStreak playedOn(int day) {
    if (length > 0 && day <= lastDay) return this;
    final continues = length > 0 && day == lastDay + 1;
    return DailyStreak(lastDay: day, length: continues ? length + 1 : 1);
  }

  /// The streak as it stands on [today]: broken, so zero, once a whole day
  /// has passed without a round.
  int lengthOn(int today) => today - lastDay <= 1 ? length : 0;
}
