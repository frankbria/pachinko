import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:games_services/games_services.dart';
import '../models/daily_board.dart';

/// Where the daily board's scores are posted for every player to compare
/// (#117).
abstract interface class DailyLeaderboard {
  /// Posts [score], won on [board]. Returns whether it was posted: false
  /// when the player is not signed in, is offline, or the post failed, so
  /// that it can be posted later. Never throws.
  Future<bool> submit(DailyBoard board, int score);
}

/// The daily leaderboard on Google Play Games Services.
///
/// The player is signed in to Play Games the first time a score is posted.
/// Each score is tagged with its board's date, so a score can be told from
/// one won on another day's board, which Play Games' daily window (it ends
/// at midnight Pacific time, not UTC) can hold at once.
class PlayGamesLeaderboard implements DailyLeaderboard {
  /// The leaderboard's ID from Play Console.
  final String leaderboardId;

  /// The sign-in, once asked for: posts made while it is under way share it,
  /// because the plugin answers only the latest of two sign-ins at once. A
  /// failed sign-in is forgotten, so the next post tries again.
  Future<void>? _signIn;

  PlayGamesLeaderboard(this.leaderboardId);

  /// The leaderboard of [leaderboardId], or null when the ID is empty (the
  /// switch is off) or the game runs in a browser, which has no Play Games.
  static PlayGamesLeaderboard? fromId(String leaderboardId) =>
      leaderboardId.isEmpty || kIsWeb
          ? null
          : PlayGamesLeaderboard(leaderboardId);

  @override
  Future<bool> submit(DailyBoard board, int score) async {
    try {
      final signIn = _signIn ??= GameAuth.signIn();
      try {
        await signIn;
      } catch (_) {
        if (identical(_signIn, signIn)) _signIn = null;
        rethrow;
      }
      await Leaderboards.submitScore(
        score: Score(
          androidLeaderboardID: leaderboardId,
          iOSLeaderboardID: leaderboardId,
          value: score,
          token: '${board.seed}',
        ),
      );
      return true;
    } on PlatformException catch (error) {
      debugPrint('Daily score not posted: $error');
      return false;
    } on MissingPluginException catch (error) {
      debugPrint('Daily score not posted: $error');
      return false;
    }
  }
}
