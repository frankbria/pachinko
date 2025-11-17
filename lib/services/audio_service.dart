import 'package:just_audio/just_audio.dart';

/// Audio service for managing game sound effects with pooling support
///
/// Implements audio playback for 5 game events:
/// - Ball launch (launch.mp3)
/// - Peg hit collision (peg_hit.wav)
/// - Special peg activation (special_peg.mp3)
/// - Scoring slot (slot_score.wav)
/// - Bonus trigger fanfare (bonus_trigger.wav)
///
/// Features:
/// - Audio player pooling for simultaneous playback (prevents stuttering)
/// - Volume control across all players
/// - Dependency injection pattern for testability
/// - Resource management (proper disposal)
///
/// Usage:
/// ```dart
/// // Production: uses default AudioPlayer instances
/// final audioService = AudioService();
/// await audioService.initialize();
/// await audioService.playLaunch();
///
/// // Testing: inject mock players
/// final audioService = AudioService(audioPlayers: mockPlayers);
/// ```
class AudioService {
  /// Audio player pool for handling simultaneous playback
  final List<AudioPlayer> _audioPlayers;

  /// Current player index for round-robin allocation
  int _currentPlayerIndex = 0;

  /// Current volume level (0.0 to 1.0)
  double _volume = 1.0;

  /// Asset paths for sound effects
  static const String _launchAsset = 'assets/sounds/launch.mp3';
  static const String _pegHitAsset = 'assets/sounds/peg_hit.wav';
  static const String _specialPegAsset = 'assets/sounds/special_peg.mp3';
  static const String _slotScoreAsset = 'assets/sounds/slot_score.wav';
  static const String _bonusTriggerAsset = 'assets/sounds/bonus_trigger.wav';

  /// Creates AudioService with dependency injection support
  ///
  /// [audioPlayers] - Optional list of AudioPlayer instances for testing
  /// [poolSize] - Number of audio players in pool (default: 5)
  ///
  /// Production usage:
  /// ```dart
  /// final service = AudioService(); // Uses default players
  /// ```
  ///
  /// Test usage:
  /// ```dart
  /// final service = AudioService(audioPlayers: mockPlayers);
  /// ```
  AudioService({
    List<AudioPlayer>? audioPlayers,
    int poolSize = 5,
  }) : _audioPlayers = audioPlayers ?? _createDefaultPlayers(poolSize);

  /// Creates default audio player pool for production use
  static List<AudioPlayer> _createDefaultPlayers(int poolSize) {
    try {
      return List.generate(poolSize, (_) => AudioPlayer());
    } catch (e) {
      // Platform doesn't support just_audio (e.g., Linux desktop)
      // Return empty list - audio will be disabled but app will function
      print('AudioService: Platform does not support audio ($e)');
      return [];
    }
  }

  /// Initializes audio service by preloading all sound assets
  ///
  /// Should be called once during app initialization to prevent
  /// lag on first playback. Preloads assets on available players
  /// in the pool for faster playback.
  ///
  /// Gracefully handles platforms where just_audio is not available (Linux desktop).
  ///
  /// Call this before using any playback methods:
  /// ```dart
  /// await audioService.initialize();
  /// ```
  Future<void> initialize() async {
    try {
      // Preload all assets to prevent first-play lag
      // We'll load each asset on the first player for initial caching
      // Actual playback will use round-robin allocation
      if (_audioPlayers.isNotEmpty) {
        final player = _audioPlayers[0];

        // Preload all 5 assets sequentially
        await player.setAsset(_launchAsset);
        await player.setAsset(_pegHitAsset);
        await player.setAsset(_specialPegAsset);
        await player.setAsset(_slotScoreAsset);
        await player.setAsset(_bonusTriggerAsset);

        // Reset player for first actual playback
        await player.seek(Duration.zero);
      }
    } catch (e) {
      // Gracefully handle platforms where just_audio is not available (e.g., Linux desktop)
      // Audio will be disabled but app continues to function
      print('AudioService: Failed to initialize (platform may not support just_audio): $e');
    }
  }

  /// Gets next available audio player using round-robin allocation
  ///
  /// Cycles through player pool to distribute playback load
  /// and enable simultaneous sounds without stuttering.
  AudioPlayer _getNextPlayer() {
    final player = _audioPlayers[_currentPlayerIndex];
    _currentPlayerIndex = (_currentPlayerIndex + 1) % _audioPlayers.length;
    return player;
  }

  /// Plays sound effect with specified asset path
  ///
  /// Uses round-robin player allocation for simultaneous playback support.
  /// Sets asset, applies current volume, and plays immediately.
  Future<void> _playSound(String assetPath) async {
    if (_audioPlayers.isEmpty) return;

    final player = _getNextPlayer();

    // Set asset and play
    await player.setAsset(assetPath);
    await player.setVolume(_volume);
    await player.seek(Duration.zero); // Reset to start
    await player.play();
  }

  /// Plays ball launch sound effect
  ///
  /// Triggered when ball is launched from bottom-right channel.
  /// Sound: Mechanical boost/launch effect (~0.5s duration)
  Future<void> playLaunch() async {
    await _playSound(_launchAsset);
  }

  /// Plays peg hit collision sound effect
  ///
  /// Triggered on every ball-peg collision.
  /// Sound: Wooden click, short and non-fatiguing (~0.5s duration)
  ///
  /// Note: This is the most frequently played sound, so pooling
  /// is critical to prevent stuttering when multiple balls hit
  /// pegs simultaneously.
  Future<void> playPegHit() async {
    await _playSound(_pegHitAsset);
  }

  /// Plays special peg activation sound effect
  ///
  /// Triggered when ball hits a special (highlighted) peg.
  /// Sound: Achievement chime, celebratory (~1.6s duration)
  ///
  /// Attribution: "Sound by mokasza from Freesound.org (CC-BY 4.0)"
  /// (Attribution required - must be included in game credits)
  Future<void> playSpecialPeg() async {
    await _playSound(_specialPegAsset);
  }

  /// Plays scoring slot sound effect
  ///
  /// Triggered when ball lands in scoring slot at bottom.
  /// Sound: Victory chime, satisfying completion tone (~0.8s duration)
  ///
  /// [points] - Score value (optional, for future volume scaling)
  Future<void> playSlotScore(int points) async {
    // Future enhancement: Could scale volume based on points
    // Higher scoring slots = louder sound for better feedback
    await _playSound(_slotScoreAsset);
  }

  /// Plays bonus trigger fanfare sound effect
  ///
  /// Triggered when major bonus event occurs (all special pegs hit).
  /// Sound: Exciting power-up fanfare (~1.0s duration)
  ///
  /// This is the "top tier" sound in the audio hierarchy,
  /// providing dramatic feedback for rare bonus events.
  Future<void> playBonusTrigger() async {
    await _playSound(_bonusTriggerAsset);
  }

  /// Sets volume for all audio players in the pool
  ///
  /// [volume] - Volume level from 0.0 (muted) to 1.0 (full volume)
  ///
  /// Applies volume change to all players immediately and
  /// stores for future playback.
  ///
  /// Example:
  /// ```dart
  /// await audioService.setVolume(0.0); // Mute
  /// await audioService.setVolume(0.5); // 50% volume
  /// await audioService.setVolume(1.0); // Full volume
  /// ```
  Future<void> setVolume(double volume) async {
    // Clamp volume to valid range
    _volume = volume.clamp(0.0, 1.0);

    // Apply volume to all players in pool
    for (final player in _audioPlayers) {
      await player.setVolume(_volume);
    }
  }

  /// Disposes all audio players to free resources
  ///
  /// Must be called when AudioService is no longer needed
  /// to prevent memory leaks. Typically called during app
  /// shutdown or when disposing Provider.
  ///
  /// After calling dispose(), do not use any playback methods.
  Future<void> dispose() async {
    for (final player in _audioPlayers) {
      await player.dispose();
    }
  }
}