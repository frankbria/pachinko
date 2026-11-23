import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pachinko_game/services/audio_service.dart';

import 'audio_service_test.mocks.dart';

/// Tests for AudioService.
///
/// Strategy: the service makes its players through a factory, and the tests
/// hand it mocks, kept in the order it asked for them. The first player of
/// each sound is made at once, in the order of [SoundEffect.values]; the
/// rest only after it has loaded. [playersOf] finds a sound's players by the
/// asset each loaded. A load or start held open on a [Completer] shows the
/// order of the calls when the service is disposed in the middle of one.
@GenerateMocks([AudioPlayer])
void main() {
  late List<MockAudioPlayer> players;
  late Map<MockAudioPlayer, String> assetOf;
  late AudioService audioService;

  MockAudioPlayer newPlayer() {
    final player = MockAudioPlayer();
    when(player.setPlayerMode(any)).thenAnswer((_) async {});
    when(player.setAudioContext(any)).thenAnswer((_) async {});
    when(player.setReleaseMode(any)).thenAnswer((_) async {});
    when(player.setSource(any)).thenAnswer((invocation) async {
      assetOf[player] =
          (invocation.positionalArguments.first as AssetSource).path;
    });
    when(player.stop()).thenAnswer((_) async {});
    when(player.setVolume(any)).thenAnswer((_) async {});
    when(player.setPlaybackRate(any)).thenAnswer((_) async {});
    when(player.resume()).thenAnswer((_) async {});
    when(player.dispose()).thenAnswer((_) async {});
    players.add(player);
    return player;
  }

  /// The players that loaded [effect], in the order they were made.
  List<MockAudioPlayer> playersOf(SoundEffect effect) =>
      players.where((player) => assetOf[player] == effect.asset).toList();

  final allVoices = SoundEffect.values.fold(0, (sum, e) => sum + e.voices);

  setUp(() {
    players = [];
    assetOf = {};
    audioService = AudioService(createPlayer: newPlayer);
  });

  tearDown(() => audioService.dispose());

  group('loading', () {
    test('makes no player before it is initialized', () {
      expect(players, isEmpty);
    });

    test('loads each sound once onto each of its players, in low latency',
        () async {
      await audioService.initialize();

      expect(players, hasLength(allVoices));
      for (final effect in SoundEffect.values) {
        expect(playersOf(effect), hasLength(effect.voices));
        for (final player in playersOf(effect)) {
          final source =
              verify(player.setSource(captureAny)).captured.single as Source;
          expect((source as AssetSource).path, effect.asset);
          verify(player.setPlayerMode(PlayerMode.lowLatency)).called(1);
          verify(player.setReleaseMode(ReleaseMode.stop)).called(1);
        }
      }
    });

    test('every sound file it loads is in the assets', () {
      for (final effect in SoundEffect.values) {
        expect(File('assets/${effect.asset}').existsSync(), isTrue,
            reason: effect.asset);
      }
    });

    test('takes no audio focus, so it mixes with the player\'s music',
        () async {
      await audioService.initialize();

      final context = verify(players.first.setAudioContext(captureAny))
          .captured
          .single as AudioContext;
      expect(context.android.audioFocus, AndroidAudioFocus.none);
    });

    test('a sound\'s other players load only once its first has loaded',
        () async {
      // On Android a player that joins a sound still loading on another
      // copies a sample that does not exist yet, and never sounds
      final firstLoad = Completer<void>();
      final service = AudioService(createPlayer: () {
        final player = newPlayer();
        if (players.length == 1) {
          when(player.setSource(any)).thenAnswer((_) => firstLoad.future);
        }
        return player;
      });
      final initialized = service.initialize();
      await Future<void>.delayed(Duration.zero);

      // The launch's other player is not even made yet; the other sounds
      // are not held up by it
      expect(players, hasLength(allVoices - (SoundEffect.launch.voices - 1)));
      expect(playersOf(SoundEffect.launch), isEmpty);
      expect(
          playersOf(SoundEffect.pegHit), hasLength(SoundEffect.pegHit.voices));

      firstLoad.complete();
      await initialized;
      expect(players, hasLength(allVoices));
      expect(playersOf(SoundEffect.launch),
          hasLength(SoundEffect.launch.voices - 1));
      await service.dispose();
    });

    test('turns off the players\' position updates, which effects never use',
        () async {
      await audioService.initialize();

      for (final player in players) {
        verify(player.positionUpdater = null).called(1);
      }
    });

    test('initializing again makes no more players', () async {
      await audioService.initialize();
      final count = players.length;

      await audioService.initialize();

      expect(players, hasLength(count));
    });
  });

  group('playing', () {
    setUp(() => audioService.initialize());

    final sounds = <SoundEffect, Future<void> Function(AudioService)>{
      SoundEffect.launch: (service) => service.playLaunch(),
      SoundEffect.pegHit: (service) => service.playPegHit(300),
      SoundEffect.specialPeg: (service) => service.playSpecialPeg(),
      SoundEffect.slotScore: (service) => service.playSlotScore(1000),
      SoundEffect.bonusTrigger: (service) => service.playBonusTrigger(),
    };
    for (final entry in sounds.entries) {
      test('${entry.key.name} plays on its own player without reloading',
          () async {
        await entry.value(audioService);

        final player = playersOf(entry.key).first;
        verify(player.resume()).called(1);
        // Loaded once by initialize, and not again to play
        verify(player.setSource(any)).called(1);
        for (final other in players.where((p) => p != player)) {
          verifyNever(other.resume());
        }
      });
    }

    test('several pin sounds in quick succession all play', () async {
      // Eight hits asked for at once, none awaited, as the physics asks
      final pegPlayers = playersOf(SoundEffect.pegHit);
      await Future.wait([
        for (var hit = 0; hit < pegPlayers.length; hit++)
          audioService.playPegHit(200),
      ]);

      for (final player in pegPlayers) {
        verify(player.resume()).called(1);
        verify(player.setSource(any)).called(1);
      }
    });

    test('a start begins a new sound: the player is stopped, then resumed',
        () async {
      await audioService.playLaunch();

      verifyInOrder([
        playersOf(SoundEffect.launch).first.stop(),
        playersOf(SoundEffect.launch).first.resume(),
      ]);
    });

    test('once every player has sounded, the oldest is used again', () async {
      final pegPlayers = playersOf(SoundEffect.pegHit);
      for (var hit = 0; hit <= pegPlayers.length; hit++) {
        await audioService.playPegHit(200);
      }

      verify(pegPlayers.first.resume()).called(2);
      verify(pegPlayers[1].resume()).called(1);
    });

    test('a sound asked for while all its players are starting is dropped',
        () async {
      final bonus = playersOf(SoundEffect.bonusTrigger).single;
      final stopping = Completer<void>();
      when(bonus.stop()).thenAnswer((_) => stopping.future);

      final first = audioService.playBonusTrigger();
      await audioService.playBonusTrigger();
      stopping.complete();
      await first;

      verify(bonus.resume()).called(1);
    });
  });

  test('a sound asked for before its players have loaded is not played',
      () async {
    final loading = Completer<void>();
    final service = AudioService(createPlayer: () {
      final player = newPlayer();
      when(player.setSource(any)).thenAnswer((_) => loading.future);
      return player;
    });
    final initialized = service.initialize();

    await service.playLaunch();
    loading.complete();
    await initialized;

    for (final player in players) {
      verifyNever(player.resume());
    }
    await service.dispose();
  });

  group('tone', () {
    test('a pin sounds louder and higher the harder it is hit', () {
      final speeds = [0.0, 100.0, 300.0, 450.0, AudioService.pegHitFullSpeed];
      final tones = speeds.map(AudioService.pegHitToneFor).toList();
      for (var i = 1; i < tones.length; i++) {
        expect(tones[i].volume, greaterThan(tones[i - 1].volume));
        expect(tones[i].playbackRate, greaterThan(tones[i - 1].playbackRate));
      }
      expect(tones.first, (volume: 0.3, playbackRate: 0.85));
      expect(tones.last.volume, 1.0);
      expect(tones.last.playbackRate, closeTo(1.2, 1e-9));
    });

    test('a pin hit faster than full speed sounds as one at full speed', () {
      expect(
        AudioService.pegHitToneFor(AudioService.pegHitFullSpeed * 3),
        AudioService.pegHitToneFor(AudioService.pegHitFullSpeed),
      );
    });

    test('a slot sounds louder and higher by tier, cool to hot', () {
      final tones = [50, 200, 1000, 2000].map(AudioService.slotToneFor);
      final list = tones.toList();
      for (var i = 1; i < list.length; i++) {
        expect(list[i].volume, greaterThan(list[i - 1].volume));
        expect(list[i].playbackRate, greaterThan(list[i - 1].playbackRate));
      }
      expect(list.last, (volume: 1.0, playbackRate: 1.25));
    });

    test('a pin and a slot are played at their tone', () async {
      await audioService.initialize();

      await audioService.playPegHit(0);
      await audioService.playSlotScore(2000);

      final pin = playersOf(SoundEffect.pegHit).first;
      verify(pin.setVolume(0.3)).called(1);
      verify(pin.setPlaybackRate(0.85)).called(1);
      final slot = playersOf(SoundEffect.slotScore).first;
      verify(slot.setVolume(1.0)).called(1);
      verify(slot.setPlaybackRate(1.25)).called(1);
    });
  });

  group('board features (#114)', () {
    test('a windmill is a pin played lower, and the gate is quieter and low',
        () {
      for (final speed in [0.0, 300.0, AudioService.pegHitFullSpeed]) {
        final pin = AudioService.pegHitToneFor(speed);
        final windmill = AudioService.windmillToneFor(speed);
        expect(windmill.volume, pin.volume);
        expect(windmill.playbackRate, closeTo(pin.playbackRate * 0.6, 1e-9));
        final gate = AudioService.gateToneFor(speed);
        expect(gate.volume, closeTo(pin.volume * 0.8, 1e-9));
        expect(gate.playbackRate, 0.7);
      }
    });

    test('each feature plays its own sample at its own tone', () async {
      await audioService.initialize();

      await audioService.playTulipOpen();
      await audioService.playTulipCatch();
      await audioService.playWindmillHit(0);
      await audioService.playGateHit(0);

      final chimes = playersOf(SoundEffect.specialPeg);
      verify(chimes[0].setPlaybackRate(AudioService.tulipOpenTone.playbackRate))
          .called(1);
      verify(chimes[1]
              .setPlaybackRate(AudioService.tulipCatchTone.playbackRate))
          .called(1);
      final windmill = AudioService.windmillToneFor(0);
      verify(playersOf(SoundEffect.pegHit)
              .first
              .setPlaybackRate(windmill.playbackRate))
          .called(1);
      verify(playersOf(SoundEffect.slotScore).first.setPlaybackRate(0.7))
          .called(1);
    });
  });

  group('volume', () {
    setUp(() => audioService.initialize());

    test('scales every sound played afterwards', () async {
      audioService.setVolume(0.5);

      await audioService.playLaunch();
      await audioService.playSlotScore(50);

      verify(playersOf(SoundEffect.launch).first.setVolume(0.5)).called(1);
      verify(playersOf(SoundEffect.slotScore).first.setVolume(0.25)).called(1);
    });

    test('is clamped to 0 to 1', () async {
      audioService.setVolume(-1);
      await audioService.playLaunch();
      audioService.setVolume(2);
      await audioService.playLaunch();

      final launch = playersOf(SoundEffect.launch);
      verify(launch[0].setVolume(0.0)).called(1);
      verify(launch[1].setVolume(1.0)).called(1);
    });
  });

  group('sound off', () {
    setUp(() => audioService.initialize());

    test('plays nothing while off, and plays again once on', () async {
      audioService.enabled = false;

      await audioService.playLaunch();
      await audioService.playPegHit(300);
      await audioService.playSpecialPeg();
      await audioService.playSlotScore(2000);
      await audioService.playBonusTrigger();

      for (final effect in SoundEffect.values) {
        for (final player in playersOf(effect)) {
          verifyNever(player.resume());
        }
      }

      audioService.enabled = true;
      await audioService.playLaunch();
      verify(playersOf(SoundEffect.launch).first.resume()).called(1);
    });
  });

  group('failures do not escape', () {
    /// Sounds are played without being awaited. A failure inside a player
    /// (it was disposed while a sound was loading, or the platform has no
    /// audio) would otherwise surface as an unhandled error.
    test('a player that fails to start, and the next sound still plays',
        () async {
      await audioService.initialize();
      final launch = playersOf(SoundEffect.launch);
      when(launch[0].resume()).thenThrow(StateError('player disposed'));

      await expectLater(audioService.playLaunch(), completes);
      await audioService.playLaunch();

      verify(launch[1].resume()).called(1);
    });

    test('a later player that fails to load is left out, and the rest play',
        () async {
      var launchLoads = 0;
      final service = AudioService(createPlayer: () {
        final player = newPlayer();
        when(player.setSource(any)).thenAnswer((invocation) async {
          final path =
              (invocation.positionalArguments.first as AssetSource).path;
          if (path == SoundEffect.launch.asset && ++launchLoads == 2) {
            throw StateError('load interrupted');
          }
          assetOf[player] = path;
        });
        return player;
      });

      await expectLater(service.initialize(), completes);
      await service.playLaunch();
      await service.playLaunch();

      final failed = players.where((p) => !assetOf.containsKey(p)).single;
      verifyNever(failed.resume());
      verify(playersOf(SoundEffect.launch).single.resume()).called(2);
      await service.dispose();
    });

    test('a sound whose first player fails to load stays silent, alone',
        () async {
      // Its other players would race for a sample that never loaded, so
      // they are not made
      final service = AudioService(createPlayer: () {
        final player = newPlayer();
        if (players.length == 1) {
          when(player.setSource(any))
              .thenThrow(StateError('no audio on this platform'));
        }
        return player;
      });

      await expectLater(service.initialize(), completes);
      await service.playLaunch();
      await service.playBonusTrigger();

      expect(players, hasLength(allVoices - (SoundEffect.launch.voices - 1)));
      verifyNever(players.first.resume());
      verify(playersOf(SoundEffect.bonusTrigger).single.resume()).called(1);
      await service.dispose();
    });

    test('players that cannot be made leave the service silent', () async {
      final withoutPlayers = AudioService(
          createPlayer: () => throw UnsupportedError('no audio here'));

      await expectLater(withoutPlayers.initialize(), completes);
      await expectLater(withoutPlayers.playLaunch(), completes);
      await expectLater(withoutPlayers.dispose(), completes);
    });

    test('a player that fails to dispose, and the others are still disposed',
        () async {
      await audioService.initialize();
      when(players.first.dispose()).thenThrow(StateError('already disposed'));

      await expectLater(audioService.dispose(), completes);
      verify(players.last.dispose()).called(1);
    });
  });

  group('disposal while a sound is loading or starting', () {
    /// The app disposes the service without waiting, and a sound may still
    /// be loading or starting. A player disposed in the middle of a platform
    /// call goes on receiving events on streams that are closed, which the
    /// plugin reports as an unhandled error (issue #66).
    test('a sound still starting: the player outlives it and is not resumed',
        () async {
      await audioService.initialize();
      final launch = playersOf(SoundEffect.launch).first;
      final stopping = Completer<void>();
      when(launch.stop()).thenAnswer((_) => stopping.future);
      final sound = audioService.playLaunch();

      final disposed = audioService.dispose();
      await Future<void>.delayed(Duration.zero);
      for (final player in players) {
        verifyNever(player.dispose());
      }

      stopping.complete();
      await disposed;
      await sound;
      for (final player in players) {
        verify(player.dispose()).called(1);
      }
      verifyNever(launch.setVolume(any));
      verifyNever(launch.resume());
    });

    test('a sound still resuming: the players outlive it', () async {
      await audioService.initialize();
      final launch = playersOf(SoundEffect.launch).first;
      final resuming = Completer<void>();
      when(launch.resume()).thenAnswer((_) => resuming.future);
      final sound = audioService.playLaunch();
      await Future<void>.delayed(Duration.zero);

      final disposed = audioService.dispose();
      await Future<void>.delayed(Duration.zero);
      verifyNever(launch.dispose());
      await audioService.playLaunch();
      verify(launch.resume()).called(1);

      resuming.complete();
      await disposed;
      await sound;
      verify(launch.dispose()).called(1);
    });

    test('the preload still running: the players outlive it', () async {
      final loading = Completer<void>();
      final service = AudioService(createPlayer: () {
        final player = newPlayer();
        when(player.setSource(any)).thenAnswer((_) => loading.future);
        return player;
      });
      final preload = service.initialize();

      final disposed = service.dispose();
      await Future<void>.delayed(Duration.zero);
      verifyNever(players.first.dispose());

      loading.complete();
      await disposed;
      await preload;
      verify(players.first.dispose()).called(1);
      // The first players' loads ended after dispose: no others are made
      expect(players, hasLength(SoundEffect.values.length));
      // A player whose load ended after dispose is never played
      await service.playLaunch();
      verifyNever(players.first.resume());
    });

    test('a load that fails: the players are still disposed', () async {
      final loading = Completer<void>();
      final service = AudioService(createPlayer: () {
        final player = newPlayer();
        when(player.setSource(any)).thenAnswer((_) => loading.future);
        return player;
      });
      final preload = service.initialize();
      final disposed = service.dispose();
      // Until every player has asked for its source
      await Future<void>.delayed(Duration.zero);

      loading.completeError(StateError('load interrupted'));

      await expectLater(disposed, completes);
      await preload;
      expect(players, hasLength(SoundEffect.values.length));
      for (final player in players) {
        verify(player.dispose()).called(1);
      }
    });

    test('a disposed service touches no player', () async {
      await audioService.initialize();
      await audioService.dispose();
      for (final player in players) {
        clearInteractions(player);
      }

      await audioService.playPegHit(300);
      await audioService.initialize();

      for (final player in players) {
        verifyZeroInteractions(player);
      }
    });

    test('disposing twice disposes each player once', () async {
      await audioService.initialize();
      final first = audioService.dispose();
      // A second caller waits for the same teardown
      expect(audioService.dispose(), same(first));
      await first;
      await audioService.dispose();

      for (final player in players) {
        verify(player.dispose()).called(1);
      }
    });

    test('disposed before it was initialized, it never makes a player',
        () async {
      await audioService.dispose();
      await audioService.initialize();

      expect(players, isEmpty);
    });
  });
}
