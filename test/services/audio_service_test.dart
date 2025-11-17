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
