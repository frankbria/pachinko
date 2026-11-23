import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pachinko_game/services/music_service.dart';

import 'audio_service_test.mocks.dart';

/// What a mock player has been told: its volume, whether it is playing, how
/// often it was sent back to its start, and a stream to say it finished.
class _PlayerState {
  double volume = 0;
  bool playing = false;
  int restarts = 0;
  int resumes = 0;
  final StreamController<void> completions = StreamController<void>.broadcast();
}

/// Tests for MusicService.
///
/// Strategy: the service is given mock players, each of which keeps what it
/// was last told in a [_PlayerState], and a list of the app's assets, so a
/// test chooses which music files exist. Fades run on timers, so the tests
/// are widget tests that move the clock on with `tester.pump`. Each row of
/// the playback table in issue #118 has a test here; the game's side, which
/// scene and duck each moment of play asks for, is tested in
/// game_manager_test.dart.
void main() {
  late Map<MockAudioPlayer, _PlayerState> stateOf;
  late Map<MusicTrack, MockAudioPlayer> playerOf;
  late MusicService music;

  /// Every track's file, in AAC.
  final allTracks = [
    for (final track in MusicTrack.values) 'assets/music/${track.fileName}.m4a'
  ];

  MockAudioPlayer newPlayer() {
    final player = MockAudioPlayer();
    final state = _PlayerState();
    stateOf[player] = state;
    when(player.setPlayerMode(any)).thenAnswer((_) async {});
    when(player.setAudioContext(any)).thenAnswer((_) async {});
    when(player.setReleaseMode(any)).thenAnswer((_) async {});
    when(player.setSource(any)).thenAnswer((invocation) async {
      final path = (invocation.positionalArguments.first as AssetSource).path;
      playerOf[MusicTrack.values.firstWhere(
          (track) => path.startsWith('music/${track.fileName}.'))] = player;
    });
    when(player.setVolume(any)).thenAnswer((invocation) async {
      state.volume = invocation.positionalArguments.first as double;
    });
    when(player.resume()).thenAnswer((_) async {
      state.playing = true;
      state.resumes++;
    });
    when(player.pause()).thenAnswer((_) async => state.playing = false);
    when(player.seek(any)).thenAnswer((_) async => state.restarts++);
    when(player.onPlayerComplete).thenAnswer((_) => state.completions.stream);
    when(player.dispose()).thenAnswer((_) async {});
    return player;
  }

  _PlayerState track(MusicTrack track) => stateOf[playerOf[track]!]!;

  /// The stinger plays to its end, and its player stops, as on a phone.
  void finishStinger() {
    track(MusicTrack.feverStinger)
      ..playing = false
      ..completions.add(null);
  }

  MusicService serviceWith(List<String> assets) =>
      MusicService(createPlayer: newPlayer, listAssets: () async => assets);

  /// Moves the clock past a crossfade.
  Future<void> afterCrossfade(WidgetTester tester) =>
      tester.pump(MusicService.crossfade + MusicService.fadeStep);

  /// Moves the clock past the fade out at the start of the fever.
  Future<void> afterFeverFade(WidgetTester tester) =>
      tester.pump(MusicService.feverFadeOut + MusicService.fadeStep);

  setUp(() {
    stateOf = {};
    playerOf = {};
    music = serviceWith(allTracks);
  });

  group('loading', () {
    test('with no music files it makes no player and plays nothing', () async {
      final silent = serviceWith(['assets/sounds/peg_hit.wav']);
      await silent.initialize();
      silent
        ..playScene(MusicScene.round)
        ..playScene(MusicScene.fever)
        ..setDuck(MusicDuck.paused);

      expect(stateOf, isEmpty);
      expect(silent.playsFeverStinger, isFalse);
      expect(silent.scene, MusicScene.fever);
      await silent.dispose();
    });

    test('loads each track that has a file onto a player of its own', () async {
      await music.initialize();

      expect(playerOf.keys, unorderedEquals(MusicTrack.values));
      for (final entry in playerOf.entries) {
        verify(entry.value.setPlayerMode(PlayerMode.mediaPlayer)).called(1);
        verify(entry.value.setReleaseMode(
                entry.key.loops ? ReleaseMode.loop : ReleaseMode.stop))
            .called(1);
        verify(entry.value.positionUpdater = null).called(1);
      }
      await music.dispose();
    });

    test('takes the first format it finds, and AAC before the others',
        () async {
      final mixed = serviceWith([
        'assets/music/menu_loop.ogg',
        'assets/music/round_loop.wav',
        'assets/music/round_loop.m4a',
      ]);
      await mixed.initialize();

      expect(
          playerOf.keys, unorderedEquals([MusicTrack.menu, MusicTrack.round]));
      final source = verify(playerOf[MusicTrack.round]!.setSource(captureAny))
          .captured
          .single as AssetSource;
      expect(source.path, 'music/round_loop.m4a');
      final menuSource =
          verify(playerOf[MusicTrack.menu]!.setSource(captureAny))
              .captured
              .single as AssetSource;
      expect(menuSource.path, 'music/menu_loop.ogg');
      await mixed.dispose();
    });

    test('takes no audio focus, so it mixes with the player\'s music',
        () async {
      await music.initialize();

      final context =
          verify(playerOf[MusicTrack.menu]!.setAudioContext(captureAny))
              .captured
              .single as AudioContext;
      expect(context.android.audioFocus, AndroidAudioFocus.none);
      await music.dispose();
    });

    test('a track that fails to load is left silent, and the rest play',
        () async {
      final failing = MusicService(
        createPlayer: () {
          final player = newPlayer();
          when(player.setSource(argThat(predicate<AssetSource>(
                  (source) => source.path.contains('menu_loop')))))
              .thenThrow(Exception('no decoder'));
          return player;
        },
        listAssets: () async => allTracks,
      );

      await failing.initialize();

      expect(playerOf.containsKey(MusicTrack.menu), isFalse);
      expect(playerOf.containsKey(MusicTrack.round), isTrue);
      await failing.dispose();
    });

    test('a failing asset list leaves the game without music', () async {
      final failing = MusicService(
          createPlayer: newPlayer,
          listAssets: () async => throw Exception('no manifest'));

      await failing.initialize();

      expect(stateOf, isEmpty);
      await failing.dispose();
    });
  });

  group('playback', () {
    testWidgets('the menu fades in and carries on across the menu screens',
        (tester) async {
      await music.initialize();
      music.playScene(MusicScene.menu);
      await afterCrossfade(tester);

      expect(track(MusicTrack.menu).playing, isTrue);
      expect(track(MusicTrack.menu).volume, 1.0);

      // Another menu screen asks again: nothing restarts
      music.playScene(MusicScene.menu);
      await afterCrossfade(tester);
      expect(track(MusicTrack.menu).resumes, 1);
      expect(track(MusicTrack.menu).restarts, 0);
      await music.dispose();
    });

    testWidgets('a scene asked for before the files load starts as they do',
        (tester) async {
      music.playScene(MusicScene.menu);
      await music.initialize();
      await afterCrossfade(tester);

      expect(track(MusicTrack.menu).playing, isTrue);
      await music.dispose();
    });

    testWidgets('a round crossfades from the menu in about a second',
        (tester) async {
      await music.initialize();
      music.playScene(MusicScene.menu);
      await afterCrossfade(tester);

      music.playScene(MusicScene.round);
      await tester.pump(MusicService.crossfade ~/ 2);
      expect(track(MusicTrack.menu).playing, isTrue);
      expect(track(MusicTrack.round).playing, isTrue);
      expect(track(MusicTrack.round).volume, closeTo(0.5, 0.06));

      await afterCrossfade(tester);
      expect(track(MusicTrack.menu).playing, isFalse);
      expect(track(MusicTrack.round).volume, 1.0);
      await music.dispose();
    });

    testWidgets('Replay and Next Level keep the round\'s music playing',
        (tester) async {
      await music.initialize();
      music.playScene(MusicScene.round);
      await afterCrossfade(tester);

      music.playScene(MusicScene.round);
      await afterCrossfade(tester);

      expect(track(MusicTrack.round).resumes, 1);
      expect(track(MusicTrack.round).volume, 1.0);
      await music.dispose();
    });

    testWidgets('back to the menu crossfades to the menu where it was left',
        (tester) async {
      await music.initialize();
      music.playScene(MusicScene.menu);
      await afterCrossfade(tester);
      music.playScene(MusicScene.round);
      await afterCrossfade(tester);

      music.playScene(MusicScene.menu);
      await afterCrossfade(tester);

      expect(track(MusicTrack.round).playing, isFalse);
      expect(track(MusicTrack.menu).playing, isTrue);
      // Resumed, not started again from the top
      expect(track(MusicTrack.menu).restarts, 0);
      await music.dispose();
    });

    testWidgets(
        'the bonus fades the round out, plays the stinger, then the fever '
        'loop until the fever ends, then the round again', (tester) async {
      await music.initialize();
      music.playScene(MusicScene.round);
      await afterCrossfade(tester);

      music.playScene(MusicScene.fever);
      expect(track(MusicTrack.feverStinger).playing, isTrue);
      expect(track(MusicTrack.feverStinger).restarts, 1);
      await afterFeverFade(tester);
      expect(track(MusicTrack.round).playing, isFalse);
      expect(track(MusicTrack.feverLoop).playing, isFalse);

      finishStinger();
      await tester.pump();
      expect(track(MusicTrack.feverLoop).playing, isTrue);
      expect(track(MusicTrack.feverLoop).restarts, 1);
      expect(track(MusicTrack.feverLoop).volume, 1.0);

      music.playScene(MusicScene.round);
      await afterCrossfade(tester);
      expect(track(MusicTrack.feverLoop).playing, isFalse);
      expect(track(MusicTrack.round).playing, isTrue);
      expect(track(MusicTrack.round).volume, 1.0);
      await music.dispose();
    });

    testWidgets('a second fever starts the stinger and the loop from the top',
        (tester) async {
      await music.initialize();
      for (var fever = 1; fever <= 2; fever++) {
        music.playScene(MusicScene.fever);
        finishStinger();
        await tester.pump();
        music.playScene(MusicScene.round);
        await afterCrossfade(tester);
      }

      expect(track(MusicTrack.feverStinger).restarts, 2);
      expect(track(MusicTrack.feverLoop).restarts, 2);
      await music.dispose();
    });

    testWidgets('a stinger that ends after the fever does not start the loop',
        (tester) async {
      await music.initialize();
      music.playScene(MusicScene.fever);
      music.playScene(MusicScene.round);
      finishStinger();
      await afterCrossfade(tester);

      expect(track(MusicTrack.feverLoop).playing, isFalse);
      expect(track(MusicTrack.round).playing, isTrue);
      await music.dispose();
    });

    testWidgets('without a stinger the fever loop starts at once',
        (tester) async {
      final noStinger = serviceWith([
        for (final asset in allTracks)
          if (!asset.contains('stinger')) asset
      ]);
      await noStinger.initialize();
      expect(noStinger.playsFeverStinger, isFalse);

      noStinger.playScene(MusicScene.fever);
      await tester.pump();

      expect(track(MusicTrack.feverLoop).playing, isTrue);
      await noStinger.dispose();
    });

    testWidgets('Back during the fever crossfades to the menu', (tester) async {
      await music.initialize();
      music.playScene(MusicScene.fever);
      finishStinger();
      await tester.pump();

      music.playScene(MusicScene.menu);
      await afterCrossfade(tester);

      expect(track(MusicTrack.feverLoop).playing, isFalse);
      expect(track(MusicTrack.feverStinger).playing, isFalse);
      expect(track(MusicTrack.menu).playing, isTrue);
      expect(track(MusicTrack.menu).volume, 1.0);
      await music.dispose();
    });

    testWidgets('Back during the stinger fades it and plays no fever loop',
        (tester) async {
      await music.initialize();
      music.playScene(MusicScene.fever);
      await tester.pump(MusicService.fadeStep);

      music.playScene(MusicScene.menu);
      await afterCrossfade(tester);
      finishStinger();
      await tester.pump();

      expect(track(MusicTrack.feverStinger).playing, isFalse);
      expect(track(MusicTrack.feverLoop).playing, isFalse);
      expect(track(MusicTrack.menu).playing, isTrue);
      await music.dispose();
    });
  });

  group('level', () {
    testWidgets('pausing drops the music low, and resuming brings it back',
        (tester) async {
      await music.initialize();
      music.playScene(MusicScene.round);
      await afterCrossfade(tester);

      music.setDuck(MusicDuck.paused);
      expect(track(MusicTrack.round).volume, MusicDuck.paused.level);
      expect(track(MusicTrack.round).playing, isTrue);

      music.setDuck(MusicDuck.none);
      expect(track(MusicTrack.round).volume, 1.0);
      await music.dispose();
    });

    testWidgets('the round summary drops the music a few decibels',
        (tester) async {
      await music.initialize();
      music.playScene(MusicScene.round);
      await afterCrossfade(tester);

      music.setDuck(MusicDuck.summary);

      expect(track(MusicTrack.round).volume, MusicDuck.summary.level);
      expect(MusicDuck.summary.level, greaterThan(MusicDuck.paused.level));
      expect(MusicDuck.summary.level, lessThan(1.0));
      expect(music.duck, MusicDuck.summary);
      await music.dispose();
    });

    testWidgets('a bonus during a pause plays the stinger at the paused level',
        (tester) async {
      await music.initialize();
      music.playScene(MusicScene.round);
      await afterCrossfade(tester);
      music.setDuck(MusicDuck.paused);

      music.playScene(MusicScene.fever);
      await tester.pump();

      expect(track(MusicTrack.feverStinger).playing, isTrue);
      expect(track(MusicTrack.feverStinger).volume, MusicDuck.paused.level);
      await music.dispose();
    });

    testWidgets('the volume applies at once to what is playing',
        (tester) async {
      await music.initialize();
      music.playScene(MusicScene.round);
      await afterCrossfade(tester);

      music.setVolume(0.7);
      expect(track(MusicTrack.round).volume, closeTo(0.7, 1e-9));
      expect(music.volume, 0.7);
      music.setVolume(3);
      expect(music.volume, 1.0);

      music.setVolume(0);
      expect(track(MusicTrack.round).playing, isFalse);
      expect(music.playsFeverStinger, isFalse);
      // Without a restart
      expect(track(MusicTrack.round).restarts, 0);
      await music.dispose();
    });

    testWidgets('sound off pauses the music, and on carries it on',
        (tester) async {
      await music.initialize();
      music.playScene(MusicScene.round);
      await afterCrossfade(tester);

      music.enabled = false;
      expect(track(MusicTrack.round).playing, isFalse);
      expect(music.playsFeverStinger, isFalse);

      music.enabled = true;
      expect(track(MusicTrack.round).playing, isTrue);
      expect(music.playsFeverStinger, isTrue);
      expect(track(MusicTrack.round).restarts, 0);
      await music.dispose();
    });

    testWidgets('the app hidden pauses the music, and it resumes on return',
        (tester) async {
      await music.initialize();
      music.playScene(MusicScene.menu);
      await afterCrossfade(tester);

      music.setAppHidden(true);
      expect(track(MusicTrack.menu).playing, isFalse);

      music.setAppHidden(false);
      expect(track(MusicTrack.menu).playing, isTrue);
      expect(track(MusicTrack.menu).restarts, 0);
      await music.dispose();
    });
  });

  group('failures and disposal', () {
    testWidgets('a player that fails to play is caught', (tester) async {
      final failing = MusicService(
        createPlayer: () {
          final player = newPlayer();
          when(player.resume()).thenThrow(Exception('platform error'));
          return player;
        },
        listAssets: () async => allTracks,
      );
      await failing.initialize();

      failing.playScene(MusicScene.menu);
      await afterCrossfade(tester);

      expect(track(MusicTrack.menu).playing, isFalse);
      await failing.dispose();
    });

    test('a player that cannot be made leaves its track silent', () async {
      final failing = MusicService(
          createPlayer: () => throw Exception('no platform'),
          listAssets: () async => allTracks);

      await failing.initialize();

      expect(failing.playsFeverStinger, isFalse);
      await failing.dispose();
    });

    test('dispose waits for a load in flight before disposing the player',
        () async {
      final load = Completer<void>();
      final slow = MusicService(
        createPlayer: () {
          final player = newPlayer();
          when(player.setSource(any)).thenAnswer((_) => load.future);
          return player;
        },
        listAssets: () async => ['assets/music/menu_loop.m4a'],
      );
      final initialized = slow.initialize();
      await Future<void>.delayed(Duration.zero);
      final player = stateOf.keys.single;

      final disposed = slow.dispose();
      await Future<void>.delayed(Duration.zero);
      verifyNever(player.dispose());

      load.complete();
      await disposed;
      await initialized;
      verify(player.dispose()).called(1);
      // Loaded after dispose: never played
      verifyNever(player.resume());
    });

    testWidgets(
        'nothing plays after dispose, and disposing twice is one '
        'teardown', (tester) async {
      await music.initialize();
      final teardown = music.dispose();
      expect(music.dispose(), same(teardown));
      await teardown;

      music
        ..playScene(MusicScene.round)
        ..setVolume(0.5);
      await afterCrossfade(tester);

      for (final state in stateOf.values) {
        expect(state.playing, isFalse);
      }
    });

    test('a player that fails to dispose does not keep the others alive',
        () async {
      final failing = MusicService(
        createPlayer: () {
          final player = newPlayer();
          if (stateOf.length == 1) {
            when(player.dispose()).thenThrow(Exception('already gone'));
          }
          return player;
        },
        listAssets: () async => allTracks,
      );
      await failing.initialize();

      await failing.dispose();

      for (final player in stateOf.keys.skip(1)) {
        verify(player.dispose()).called(1);
      }
    });
  });
}
