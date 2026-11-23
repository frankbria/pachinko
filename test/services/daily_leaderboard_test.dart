import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pachinko_game/models/daily_board.dart';
import 'package:pachinko_game/services/daily_leaderboard.dart';

/// The Play Games plugin is answered on its method channel, as the Android
/// side would answer it, so these tests check what is asked of Play Games
/// and what the leaderboard makes of each answer.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('games_services');
  final board = DailyBoard.on(DateTime.utc(2026, 11, 23));
  late List<MethodCall> calls;

  /// Answers the plugin's calls, failing those named in [failing] as the
  /// Android side fails them.
  void answer({Set<String> failing = const {}}) {
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (failing.contains(call.method)) {
        throw PlatformException(code: 'failed', message: 'offline');
      }
      return 'success';
    });
  }

  tearDown(() => TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null));

  test('Given no leaderboard ID When built Then the leaderboard is off', () {
    expect(PlayGamesLeaderboard.fromId(''), isNull);
    expect(
        PlayGamesLeaderboard.fromId('CgkI_daily')?.leaderboardId, 'CgkI_daily');
  });

  test(
      'Given Play Games answers When a score is posted Then the player is signed in once and each score is tagged with its board\'s date',
      () async {
    answer();
    final leaderboard = PlayGamesLeaderboard('CgkI_daily');

    expect(await leaderboard.submit(board, 12000), isTrue);
    expect(await leaderboard.submit(board, 13000), isTrue);

    expect(calls.map((call) => call.method),
        ['signIn', 'submitScore', 'submitScore']);
    expect(calls[1].arguments, {
      'leaderboardID': 'CgkI_daily',
      'value': 12000,
      'token': '20261123',
    });
  });

  test(
      'Given the player cannot sign in When a score is posted Then it is not posted, and sign-in is tried again next time',
      () async {
    answer(failing: {'signIn'});
    final leaderboard = PlayGamesLeaderboard('CgkI_daily');

    expect(await leaderboard.submit(board, 12000), isFalse);
    expect(await leaderboard.submit(board, 12000), isFalse);

    expect(calls.map((call) => call.method), ['signIn', 'signIn']);
  });

  test(
      'Given the phone is offline When a score is posted Then it is not posted',
      () async {
    answer(failing: {'submitScore'});

    expect(
        await PlayGamesLeaderboard('CgkI_daily').submit(board, 12000), isFalse);
  });

  test(
      'Given no Play Games plugin When a score is posted Then it is not posted and nothing is thrown',
      () async {
    expect(
        await PlayGamesLeaderboard('CgkI_daily').submit(board, 12000), isFalse);
  });
}
