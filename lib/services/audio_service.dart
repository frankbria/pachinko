import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// A sound effect the game plays, with its asset and how many copies of it
/// can sound at once.
enum SoundEffect {
  /// A ball leaving the launcher.
  launch('sounds/launch.mp3', voices: 2),

  /// A ball bouncing off a pin: the most frequent sound, so it has the most
  /// voices, enough for three balls in play.
  pegHit('sounds/peg_hit.wav', voices: 8),

  /// A ball collecting a prize peg.
  specialPeg('sounds/special_peg.mp3', voices: 2),

  /// A ball landing in a slot.
  slotScore('sounds/slot_score.wav', voices: 4),

  /// The bonus triggering.
  bonusTrigger('sounds/bonus_trigger.wav', voices: 1);

  const SoundEffect(this.asset, {required this.voices});

  /// The file, relative to `assets/` as `AssetSource` takes it.
  final String asset;

  /// Players loaded with this sound. A sound asked for while all of them
  /// are starting is dropped; one asked for while all are sounding cuts off
  /// the oldest.
  final int voices;
}

/// How loud (0 to 1, before the service's volume) and at what playback rate
/// a sound plays. A higher rate is a higher pitch.
typedef SoundTone = ({double volume, double playbackRate});

/// Plays the game's sound effects.
///
/// Each sound is loaded once, by [initialize], onto its own players in
/// low-latency mode (Android's `SoundPool`), so playing it reloads nothing.
/// A pin sounds louder and higher the harder the ball hits it
/// ([pegHitToneFor]) and a slot by its tier ([slotToneFor]).
///
/// Nothing in the game awaits a sound, so no method here throws: a failing
/// player is caught and logged. [dispose] waits for loads and starts in
/// flight before it disposes the players.
class AudioService {
  /// Creates the service. [createPlayer] makes each player and is for tests;
  /// by default it makes a real `AudioPlayer`. No player exists until
  /// [initialize].
  AudioService({AudioPlayer Function()? createPlayer})
      : _createPlayer = createPlayer ?? AudioPlayer.new;

  /// The impact speed, in pixels a second along the line between ball and
  /// pin, at which a pin sounds at its loudest and highest.
  static const double pegHitFullSpeed = 600;

  /// Sound effects take no audio focus, so they mix with the player's own
  /// music instead of pausing it.
  static final AudioContext _effectsContext = AudioContextConfig(
    focus: AudioContextConfigFocus.mixWithOthers,
  ).build();

  final AudioPlayer Function() _createPlayer;

  /// Every player made, loaded or not, so that [dispose] reaches them all.
  final List<AudioPlayer> _players = [];

  /// The players of each sound whose load finished.
  final Map<SoundEffect, List<AudioPlayer>> _loaded = {
    for (final effect in SoundEffect.values) effect: [],
  };

  /// Where each sound's round of its players continues from.
  final Map<SoundEffect, int> _nextVoice = {
    for (final effect in SoundEffect.values) effect: 0,
  };

  /// Players in the middle of starting a sound; they are skipped, because
  /// two starts on one player would interleave.
  final Set<AudioPlayer> _starting = {};

  /// The volume set by [setVolume], 0 to 1.
  double _volume = 1.0;

  bool _initialized = false;

  /// Set by [dispose]. No sound is loaded or started afterwards.
  bool _disposed = false;

  /// Platform calls that have started and not finished. [dispose] waits for
  /// them: a player disposed in the middle of one goes on receiving platform
  /// events on streams that are closed, which the plugin reports as an error
  /// no caller can catch.
  final Set<Future<void>> _inFlight = {};

  /// Runs [calls] and keeps it in [_inFlight] until it ends, whether it
  /// succeeds or fails.
  Future<void> _tracked(Future<void> calls) async {
    final settled = calls.then<void>((_) {}, onError: (Object _) {});
    _inFlight.add(settled);
    try {
      await calls;
    } finally {
      _inFlight.remove(settled);
    }
  }

  /// The tone of a pin hit at [impactSpeed]: from soft and low at rest to
  /// loud and high at [pegHitFullSpeed] and above.
  static SoundTone pegHitToneFor(double impactSpeed) {
    final strength = (impactSpeed / pegHitFullSpeed).clamp(0.0, 1.0);
    return (volume: 0.3 + 0.7 * strength, playbackRate: 0.85 + 0.35 * strength);
  }

  /// The tone of a slot worth [points], by its tier (the tiers of
  /// `Slot.colorFor`): a 50 quiet and low, a 2,000 full and high.
  static SoundTone slotToneFor(int points) {
    if (points >= 2000) return (volume: 1.0, playbackRate: 1.25);
    if (points >= 1000) return (volume: 0.85, playbackRate: 1.1);
    if (points >= 100) return (volume: 0.65, playbackRate: 0.95);
    return (volume: 0.5, playbackRate: 0.85);
  }

  static const SoundTone _plain = (volume: 1.0, playbackRate: 1.0);

  /// Makes and loads every sound's players. The app does not await it; a
  /// sound asked for before its players have loaded is not played. Calling
  /// it again does nothing.
  Future<void> initialize() async {
    if (_initialized || _disposed) return;
    _initialized = true;
    await Future.wait([
      for (final effect in SoundEffect.values) _loadEffect(effect),
    ]);
  }

  /// Loads [effect] onto its first player, then onto the rest. On Android a
  /// player given a sound that another is still loading copies that one's
  /// sample before it exists, and never sounds; once the first has loaded,
  /// the others share its sample. If the first fails, the sound stays
  /// silent rather than have the rest race for a sample that never loaded.
  Future<void> _loadEffect(SoundEffect effect) async {
    if (!await _loadVoice(effect)) return;
    await Future.wait([
      for (var voice = 1; voice < effect.voices; voice++) _loadVoice(effect),
    ]);
  }

  /// Makes a player and loads [effect] onto it, and says whether it loaded.
  ///
  /// The player is made only here, in the same turn as its first call: a
  /// player starts registering with the platform as it is made, and an error
  /// there with nothing awaiting it would reach no caller.
  Future<bool> _loadVoice(SoundEffect effect) async {
    if (_disposed) return false;
    final AudioPlayer player;
    try {
      player = _createPlayer();
    } catch (e) {
      debugPrint('AudioService: no player for ${effect.name}: $e');
      return false;
    }
    _players.add(player);
    try {
      await _tracked(_load(effect, player));
    } catch (e) {
      debugPrint('AudioService: could not load ${effect.asset}: $e');
      return false;
    }
    if (_disposed) return false;
    _loaded[effect]!.add(player);
    return true;
  }

  Future<void> _load(SoundEffect effect, AudioPlayer player) async {
    // A sound effect needs no position. The player's own updater would ask
    // the platform for one on every frame after each start, unawaited, and
    // a SoundPool sound never reports that it has finished to stop it
    player.positionUpdater = null;
    await player.setPlayerMode(PlayerMode.lowLatency);
    await player.setAudioContext(_effectsContext);
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setSource(AssetSource(effect.asset));
  }

  /// The next player of [effect] in turn that is loaded and not starting.
  AudioPlayer? _nextFreeVoice(SoundEffect effect) {
    final voices = _loaded[effect]!;
    for (var tried = 0; tried < voices.length; tried++) {
      final index = (_nextVoice[effect]! + tried) % voices.length;
      final player = voices[index];
      if (!_starting.contains(player)) {
        _nextVoice[effect] = (index + 1) % voices.length;
        return player;
      }
    }
    return null;
  }

  /// Plays [effect] at [tone] on its next free player. Never throws.
  Future<void> _play(SoundEffect effect, SoundTone tone) async {
    if (_disposed) return;
    final player = _nextFreeVoice(effect);
    if (player == null) return;
    _starting.add(player);
    try {
      await _tracked(_start(player, tone));
    } catch (e) {
      debugPrint('AudioService: could not play ${effect.asset}: $e');
    } finally {
      _starting.remove(player);
    }
  }

  Future<void> _start(AudioPlayer player, SoundTone tone) async {
    // Stopping ends the player's last sound, so that the next start is a
    // new one from the beginning, at the rate set below
    await player.stop();
    // Disposed while it stopped: the player is about to go
    if (_disposed) return;
    await player.setVolume(tone.volume * _volume);
    await player.setPlaybackRate(tone.playbackRate);
    if (_disposed) return;
    await player.resume();
  }

  /// Plays the launch: a ball leaving the launcher.
  Future<void> playLaunch() => _play(SoundEffect.launch, _plain);

  /// Plays a pin hit at [impactSpeed], the speed at which the ball met the
  /// pin along the line between them (see [pegHitToneFor]).
  Future<void> playPegHit(double impactSpeed) =>
      _play(SoundEffect.pegHit, pegHitToneFor(impactSpeed));

  /// Plays the prize peg chime.
  ///
  /// Attribution: "Sound by mokasza from Freesound.org (CC-BY 4.0)"
  Future<void> playSpecialPeg() => _play(SoundEffect.specialPeg, _plain);

  /// Plays a ball landing in a slot worth [points] (see [slotToneFor]).
  Future<void> playSlotScore(int points) =>
      _play(SoundEffect.slotScore, slotToneFor(points));

  /// Plays the bonus fanfare.
  Future<void> playBonusTrigger() => _play(SoundEffect.bonusTrigger, _plain);

  /// Sets the volume of every sound from now on, clamped to 0 to 1.
  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
  }

  /// Disposes every player. The app does not await it, so it never throws,
  /// and a player that fails to dispose does not keep the others alive.
  ///
  /// Waits for loads and starts in flight first (see [_inFlight]). Sounds
  /// asked for afterwards are ignored. Calling it again returns the same
  /// teardown.
  Future<void> dispose() => _disposal ??= _dispose();

  Future<void>? _disposal;

  Future<void> _dispose() async {
    _disposed = true;
    await Future.wait(_inFlight.toList());
    for (final player in _players) {
      try {
        await player.dispose();
      } catch (e) {
        debugPrint('AudioService: could not dispose a player: $e');
      }
    }
  }
}
