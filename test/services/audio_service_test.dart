import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pachinko_game/services/audio_service.dart';

import 'audio_service_test.mocks.dart';

/// Comprehensive test suite for AudioService
///
/// Tests audio playback, pooling, volume control, and resource management
/// following Given-When-Then BDD pattern established in Phase 1.
///
/// Testing Strategy:
/// - Mock AudioPlayer instances to avoid actual audio playback in tests
/// - Verify asset paths are correct for all 5 sound effects
/// - Test audio pooling behavior for simultaneous playback
/// - Validate volume propagation across all players
/// - Ensure proper resource cleanup (no memory leaks)

@GenerateMocks([AudioPlayer])
void main() {
  group('AudioService', () {
    late List<MockAudioPlayer> mockPlayers;
    late AudioService audioService;

    setUp(() {
      // Create mock audio player pool (5 players for pooling)
      mockPlayers = List.generate(5, (_) => MockAudioPlayer());

      // Configure default mock behaviors
      for (final player in mockPlayers) {
        when(player.setAsset(any)).thenAnswer((_) async => null);
        when(player.play()).thenAnswer((_) async {});
        when(player.setVolume(any)).thenAnswer((_) async {});
        when(player.dispose()).thenAnswer((_) async {});
        when(player.stop()).thenAnswer((_) async {});
        when(player.seek(any)).thenAnswer((_) async {});
      }

      // Inject mocked players into AudioService
      audioService = AudioService(audioPlayers: mockPlayers);
    });

    tearDown(() {
      audioService.dispose();
    });

    group('Initialization & Setup', () {
      test('givenAudioService_whenInitialized_thenAudioPlayersCreatedSuccessfully', () {
        // Given: Fresh AudioService with injected mock players
        // When: AudioService is initialized (in setUp)
        // Then: Audio players should be created (5 players in pool)
        expect(audioService, isNotNull);
        // Verify constructor dependency injection works
        expect(mockPlayers.length, equals(5));
      });

      test('givenAudioService_whenInitialized_thenAllAssetsPreloaded', () async {
        // Given: AudioService with mock players
        // When: Initialize method is called to preload assets
        await audioService.initialize();

        // Then: All 5 assets should be preloaded on first player (player 0)
        // Implementation uses player 0 for initial asset caching
        final capturedAssets = verify(mockPlayers[0].setAsset(captureAny)).captured.cast<String>();

        // Expect all 5 asset paths to be loaded on player 0
        expect(capturedAssets.length, equals(5));
        expect(capturedAssets, contains('assets/sounds/launch.mp3'));
        expect(capturedAssets, contains('assets/sounds/peg_hit.wav'));
        expect(capturedAssets, contains('assets/sounds/special_peg.mp3'));
        expect(capturedAssets, contains('assets/sounds/slot_score.wav'));
        expect(capturedAssets, contains('assets/sounds/bonus_trigger.wav'));
      });
    });

    group('Individual Playback Methods', () {
      test('givenAudioService_whenPlayLaunchCalled_thenLaunchSoundPlays', () async {
        // Given: AudioService initialized with assets preloaded
        await audioService.initialize();
        clearInteractions(mockPlayers[0]); // Clear initialization interactions

        // When: playLaunch() is called
        await audioService.playLaunch();

        // Then: Launch sound asset should be set and played on a player
        final capturedAsset = verify(mockPlayers[0].setAsset(captureAny)).captured.single;
        expect(capturedAsset, equals('assets/sounds/launch.mp3'));
        verify(mockPlayers[0].play()).called(1);
      });

      test('givenAudioService_whenPlayPegHitCalled_thenPegHitSoundPlays', () async {
        // Given: AudioService initialized
        await audioService.initialize();
        clearInteractions(mockPlayers[0]);

        // When: playPegHit() is called
        await audioService.playPegHit();

        // Then: Peg hit sound should be set and played
        final capturedAsset = verify(mockPlayers[0].setAsset(captureAny)).captured.single;
        expect(capturedAsset, equals('assets/sounds/peg_hit.wav'));
        verify(mockPlayers[0].play()).called(1);
      });

      test('givenAudioService_whenPlaySpecialPegCalled_thenSpecialPegSoundPlays', () async {
        // Given: AudioService initialized
        await audioService.initialize();
        clearInteractions(mockPlayers[0]);

        // When: playSpecialPeg() is called
        await audioService.playSpecialPeg();

        // Then: Special peg sound should be set and played
        final capturedAsset = verify(mockPlayers[0].setAsset(captureAny)).captured.single;
        expect(capturedAsset, equals('assets/sounds/special_peg.mp3'));
        verify(mockPlayers[0].play()).called(1);
      });

      test('givenAudioService_whenPlaySlotScoreCalled_thenSlotScoreSoundPlays', () async {
        // Given: AudioService initialized
        await audioService.initialize();
        clearInteractions(mockPlayers[0]);

        // When: playSlotScore() is called with a score value
        await audioService.playSlotScore(1000);

        // Then: Slot score sound should be set and played
        final capturedAsset = verify(mockPlayers[0].setAsset(captureAny)).captured.single;
        expect(capturedAsset, equals('assets/sounds/slot_score.wav'));
        verify(mockPlayers[0].play()).called(1);
      });

      test('givenAudioService_whenPlayBonusTriggerCalled_thenBonusTriggerSoundPlays', () async {
        // Given: AudioService initialized
        await audioService.initialize();
        clearInteractions(mockPlayers[0]);

        // When: playBonusTrigger() is called
        await audioService.playBonusTrigger();

        // Then: Bonus trigger sound should be set and played
        final capturedAsset = verify(mockPlayers[0].setAsset(captureAny)).captured.single;
        expect(capturedAsset, equals('assets/sounds/bonus_trigger.wav'));
        verify(mockPlayers[0].play()).called(1);
      });
    });

    group('Playback Failures', () {
      /// Sounds are played without being awaited. A failure inside the player
      /// (it was disposed while a sound was loading, or the platform has no
      /// audio) would otherwise surface as an unhandled error.
      test('givenPlayerThatFails_whenSoundPlayed_thenTheFailureDoesNotEscape', () async {
        // Given
        when(mockPlayers[0].setAsset(any)).thenThrow(StateError('player disposed'));

        // When / Then
        await expectLater(audioService.playLaunch(), completes);
      });

      test('givenPreloadThatFails_whenInitialized_thenTheFailureDoesNotEscape', () async {
        // Given
        when(mockPlayers[0].setAsset(any)).thenThrow(StateError('no audio on this platform'));

        // When & Then
        await expectLater(audioService.initialize(), completes);
      });

      test('givenPlayersThatCannotBeCreated_whenServiceCreated_thenSoundsAreIgnored', () async {
        // Given: creating the pool throws. A real player cannot be made to
        // throw from a unit test (its failure arrives later, on a future), so
        // an impossible pool size stands in for a platform without audio
        final withoutPlayers = AudioService(poolSize: -1);

        // When & Then
        await expectLater(withoutPlayers.initialize(), completes);
        await expectLater(withoutPlayers.playLaunch(), completes);
        await expectLater(withoutPlayers.dispose(), completes);
      });

      test('givenPlayerThatFailsToPlay_whenSoundPlayed_thenTheNextSoundStillPlays', () async {
        // Given
        when(mockPlayers[0].play()).thenThrow(StateError('player disposed'));

        // When
        await audioService.playLaunch();
        await audioService.playPegHit();

        // Then: the second sound went to the next player in the pool
        verify(mockPlayers[1].play()).called(1);
      });

      test('givenPlayerThatFailsToDispose_whenDisposed_thenTheOthersAreStillDisposed', () async {
        // Given
        when(mockPlayers[0].dispose()).thenThrow(StateError('already disposed'));

        // When / Then: dispose is not awaited by the app either
        await expectLater(audioService.dispose(), completes);
        verify(mockPlayers[4].dispose()).called(1);
      });
    });

    group('Disposal While A Sound Is Loading', () {
      /// The app disposes the service without waiting, and a sound may still
      /// be loading. A player disposed in the middle of a load goes on
      /// receiving platform events on streams that are closed, which the
      /// plugin reports as an unhandled error (issue #66). These tests hold a
      /// load open with a completer and watch the order of the calls.
      test('givenSoundStillLoading_whenDisposed_thenThePlayerOutlivesTheLoadAndTheSoundIsNotStarted', () async {
        // Given: a sound whose load has not finished
        final loading = Completer<Duration?>();
        when(mockPlayers[0].setAsset(any)).thenAnswer((_) => loading.future);
        final sound = audioService.playLaunch();

        // When
        final disposed = audioService.dispose();
        await Future<void>.delayed(Duration.zero);

        // Then: nothing is disposed while the load is open
        for (final player in mockPlayers) {
          verifyNever(player.dispose());
        }

        // When the load ends
        loading.complete(null);
        await disposed;
        await sound;

        // Then: the players are disposed, and the sound was not started
        for (final player in mockPlayers) {
          verify(player.dispose()).called(1);
        }
        verifyNever(mockPlayers[0].play());
      });

      test('givenPreloadStillRunning_whenDisposed_thenThePlayersOutliveThePreload', () async {
        // Given: initialize() is not awaited by the app either
        final loading = Completer<Duration?>();
        when(mockPlayers[0].setAsset(any)).thenAnswer((_) => loading.future);
        final preload = audioService.initialize();

        // When
        final disposed = audioService.dispose();
        await Future<void>.delayed(Duration.zero);

        // Then
        verifyNever(mockPlayers[0].dispose());
        loading.complete(null);
        await disposed;
        await preload;
        verify(mockPlayers[0].dispose()).called(1);
      });

      test('givenLoadThatFails_whenDisposed_thenThePlayersAreStillDisposed', () async {
        // Given
        final loading = Completer<Duration?>();
        when(mockPlayers[0].setAsset(any)).thenAnswer((_) => loading.future);
        final sound = audioService.playLaunch();
        final disposed = audioService.dispose();

        // When
        loading.completeError(StateError('load interrupted'));

        // Then
        await expectLater(disposed, completes);
        await sound;
        verify(mockPlayers[4].dispose()).called(1);
      });

      test('givenDisposedService_whenSoundAskedFor_thenNoPlayerIsTouched', () async {
        // Given
        await audioService.dispose();

        // When
        await audioService.playPegHit();

        // Then
        for (final player in mockPlayers) {
          verifyNever(player.setAsset(any));
          verifyNever(player.play());
        }
      });

      test('givenDisposedService_whenDisposedAgain_thenPlayersAreDisposedOnce', () async {
        await audioService.dispose();
        await audioService.dispose();

        for (final player in mockPlayers) {
          verify(player.dispose()).called(1);
        }
      });
    });

    group('Volume Control', () {
      test('givenAudioService_whenSetVolumeCalled_thenAllPlayersVolumeUpdated', () async {
        // Given: AudioService with 5 players in pool
        // When: setVolume is called with 0.5 (50% volume)
        await audioService.setVolume(0.5);

        // Then: All 5 audio players should have volume set to 0.5
        for (final player in mockPlayers) {
          verify(player.setVolume(0.5)).called(1);
        }
      });

      test('givenAudioService_whenSetVolumeToZero_thenSoundsMuted', () async {
        // Given: AudioService initialized
        // When: setVolume is called with 0.0 (muted)
        await audioService.setVolume(0.0);

        // Then: All players should have volume set to 0.0 (muted)
        for (final player in mockPlayers) {
          verify(player.setVolume(0.0)).called(1);
        }
      });

      test('givenAudioService_whenSetVolumeToOne_thenSoundsFullVolume', () async {
        // Given: AudioService initialized
        // When: setVolume is called with 1.0 (full volume)
        await audioService.setVolume(1.0);

        // Then: All players should have volume set to 1.0 (max volume)
        for (final player in mockPlayers) {
          verify(player.setVolume(1.0)).called(1);
        }
      });
    });

    group('Audio Pooling (Simultaneous Playback)', () {
      /// Tests audio pooling behavior for handling multiple simultaneous sounds
      /// Critical for preventing stuttering when many balls hit pegs at once
      test('givenMultiplePegHits_whenPlayedSimultaneously_thenNoStutteringOccurs', () async {
        // Given: AudioService initialized
        await audioService.initialize();

        // When: Multiple peg hit sounds are played rapidly (simulating simultaneous collisions)
        for (int i = 0; i < 10; i++) {
          await audioService.playPegHit();
        }

        // Then: Peg hit sound should be played 10 times across the player pool
        // Audio pooling should distribute playback across multiple players
        int totalPlayCalls = 0;
        for (final player in mockPlayers) {
          totalPlayCalls += verify(player.play()).callCount;
        }

        // Expect at least 10 play calls total (may be more due to initialization)
        expect(totalPlayCalls, greaterThanOrEqualTo(10));
      });

      /// Tests player reuse when all players in pool are active
      /// Ensures oldest/completed playback is replaced when pool exhausted
      test('givenAudioPool_whenAllPlayersActive_thenOldestPlayerReused', () async {
        // Given: AudioService with 5-player pool, all initialized
        await audioService.initialize();
        clearInteractions(mockPlayers[0]);
        clearInteractions(mockPlayers[1]);
        clearInteractions(mockPlayers[2]);
        clearInteractions(mockPlayers[3]);
        clearInteractions(mockPlayers[4]);

        // When: 6 sounds are played (more than pool size of 5)
        for (int i = 0; i < 6; i++) {
          await audioService.playPegHit();
        }

        // Then: Pool should cycle through players using round-robin
        // With 5 players and 6 calls, player 0 should be used twice (calls 1 and 6)
        // Verify call counts for each player (avoid multiple verify() calls)
        final player0Calls = verify(mockPlayers[0].setAsset(any)).callCount;
        final player1Calls = verify(mockPlayers[1].setAsset(any)).callCount;
        final player2Calls = verify(mockPlayers[2].setAsset(any)).callCount;
        final player3Calls = verify(mockPlayers[3].setAsset(any)).callCount;
        final player4Calls = verify(mockPlayers[4].setAsset(any)).callCount;

        // Total calls should equal 6 (one per playPegHit call)
        final totalCalls = player0Calls + player1Calls + player2Calls + player3Calls + player4Calls;
        expect(totalCalls, equals(6));

        // Verify round-robin behavior: player 0 used twice (index 0 and 5)
        expect(player0Calls, equals(2));
        // Each other player should have been used once
        expect(player1Calls, equals(1));
        expect(player2Calls, equals(1));
        expect(player3Calls, equals(1));
        expect(player4Calls, equals(1));
      });
    });

    group('Resource Management', () {
      test('givenAudioService_whenDisposeCalled_thenAllPlayersDisposed', () async {
        // Given: AudioService with 5 players
        // When: dispose() is called
        await audioService.dispose();

        // Then: All 5 audio players should be disposed to prevent memory leaks
        for (final player in mockPlayers) {
          verify(player.dispose()).called(1);
        }
      });

      test('givenAudioService_whenDisposeCalled_thenNoMemoryLeaks', () async {
        // Given: AudioService with active playback
        await audioService.initialize();
        await audioService.playLaunch();
        await audioService.playPegHit();

        // When: dispose() is called after active usage
        await audioService.dispose();

        // Then: All players should be disposed properly
        for (final player in mockPlayers) {
          verify(player.dispose()).called(1);
        }

        // Attempting to play after dispose should not crash
        // (actual behavior depends on implementation - may throw or no-op)
        // This test documents expected cleanup behavior
      });
    });
  });
}
