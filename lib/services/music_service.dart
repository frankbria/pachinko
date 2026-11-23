import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'platform_calls.dart';

/// A piece of the game's music, by the name of its file in `assets/music/`.
enum MusicTrack {
  /// The menu and the screens reached from it.
  menu('menu_loop', loops: true),

  /// A round in play.
  round('round_loop', loops: true),

  /// The moment the bonus triggers, leading into [feverLoop].
  feverStinger('fever_stinger', loops: false),

  /// The fever, for as long as it lasts.
  feverLoop('fever_loop', loops: true);

  const MusicTrack(this.fileName, {required this.loops});

  /// The file's name without its extension.
  final String fileName;

  /// Whether the track plays round and round; one that does not plays once.
  final bool loops;

  /// Where the track's file would be in the app's assets, in the order of
  /// [MusicService.formats], as the asset manifest lists them.
  List<String> get candidateAssets => [
        for (final format in MusicService.formats)
          'assets/music/$fileName.$format'
      ];
}

/// What the music is for: the screen the player is on, or the fever.
enum MusicScene { menu, round, fever }

/// How far the music drops under what is on the screen.
enum MusicDuck {
  /// Full level.
  none(1.0),

  /// The round summary: a few decibels down (about -4 dB).
  summary(0.6),

  /// The game paused: low (about -14 dB).
  paused(0.2);

  const MusicDuck(this.level);

  /// The music's volume is multiplied by this.
  final double level;
}

/// Plays the game's music: a loop for the menu, one for a round, and a
/// stinger leading into a loop for the fever, crossfading between them.
///
/// The game says what the music is for ([playScene]) and how far it drops
/// ([setDuck]); this works out what plays. A track whose file is not in
/// `assets/music/` is silent, and the game plays on as it does with none: so
/// it does until the owner's music is encoded there.
///
/// It follows `AudioService`'s rules: nothing awaits it, no method throws (a
/// failing player is caught and logged), and every call to a player goes
/// through [PlatformCalls], which [dispose] waits for.
class MusicService {
  /// Creates the service. [createPlayer] makes each player and [listAssets]
  /// says which files the app has; both are for tests. No player exists
  /// until [initialize].
  MusicService({
    AudioPlayer Function()? createPlayer,
    Future<List<String>> Function()? listAssets,
  })  : _createPlayer = createPlayer ?? AudioPlayer.new,
        _listAssets = listAssets ?? _bundledAssets;

  /// The formats a track's file may be in, the first found winning: AAC,
  /// and Ogg Vorbis or WAV if AAC leaves a gap at a loop's seam.
  static const List<String> formats = ['m4a', 'ogg', 'wav'];

  /// How long one track takes to give way to another.
  static const Duration crossfade = Duration(seconds: 1);

  /// How long a round's music takes to fade out when the bonus triggers.
  static const Duration feverFadeOut = Duration(milliseconds: 300);

  /// How often a fade changes the volume.
  static const Duration fadeStep = Duration(milliseconds: 50);

  /// Music takes no audio focus, like the sound effects: the player's own
  /// music goes on, and the music volume setting is how to quiet the game's.
  static final AudioContext _musicContext = AudioContextConfig(
    focus: AudioContextConfigFocus.mixWithOthers,
  ).build();

  static Future<List<String>> _bundledAssets() async =>
      (await AssetManifest.loadFromAssetBundle(rootBundle)).listAssets();

  final AudioPlayer Function() _createPlayer;
  final Future<List<String>> Function() _listAssets;

  /// Every player made, loaded or not, so that [dispose] reaches them all.
  final List<AudioPlayer> _allPlayers = [];

  /// The player of each track whose file loaded.
  final Map<MusicTrack, AudioPlayer> _players = {};

  /// How far up each track is faded, 0 to 1.
  final Map<MusicTrack, double> _gain = {
    for (final track in MusicTrack.values) track: 0.0,
  };

  /// The fade under way on each track.
  final Map<MusicTrack, Timer> _fades = {};

  /// The tracks whose players have been told to play.
  final Set<MusicTrack> _sounding = {};

  StreamSubscription<void>? _stingerEnds;

  final PlatformCalls _calls = PlatformCalls();

  MusicScene? _scene;
  MusicDuck _duck = MusicDuck.none;
  double _volume = 1.0;
  bool _enabled = true;
  bool _hidden = false;
  bool _initialized = false;
  bool _disposed = false;

  /// What the music is for; null until the game first says.
  MusicScene? get scene => _scene;

  /// How far the music drops.
  MusicDuck get duck => _duck;

  /// The music volume, 0 to 1, before any [duck].
  double get volume => _volume;

  /// Whether music plays. Off, every track is paused where it is.
  bool get enabled => _enabled;

  set enabled(bool on) {
    _enabled = on;
    _applyAll();
  }

  /// Whether the fever stinger will sound when the bonus triggers, in place
  /// of the bonus sound effect: music is on and the stinger's file loaded.
  bool get playsFeverStinger =>
      _enabled && _volume > 0 && _players.containsKey(MusicTrack.feverStinger);

  /// Finds which tracks' files the app has and loads each onto a player of
  /// its own. The app does not await it; whatever the game asked for in the
  /// meantime starts as each track loads. Calling it again does nothing.
  Future<void> initialize() async {
    if (_initialized || _disposed) return;
    _initialized = true;
    final Set<String> assets;
    try {
      assets = (await _listAssets()).toSet();
    } catch (e) {
      debugPrint('MusicService: could not list the assets: $e');
      return;
    }
    await Future.wait([
      for (final track in MusicTrack.values)
        if (track.candidateAssets.where(assets.contains).firstOrNull
            case final asset?)
          _load(track, asset),
    ]);
  }

  /// Makes a player and loads [asset] onto it for [track]. The player is
  /// made in the same turn as its first call, so that an error in making it
  /// has a caller.
  Future<void> _load(MusicTrack track, String asset) async {
    if (_disposed) return;
    final AudioPlayer player;
    try {
      player = _createPlayer();
    } catch (e) {
      debugPrint('MusicService: no player for ${track.name}: $e');
      return;
    }
    _allPlayers.add(player);
    try {
      await _calls.track(_prepare(track, player, asset));
    } catch (e) {
      debugPrint('MusicService: could not load $asset: $e');
      return;
    }
    if (_disposed) return;
    _players[track] = player;
    if (track == MusicTrack.feverStinger) {
      _stingerEnds = player.onPlayerComplete.listen((_) => _stingerEnded());
    }
    _apply(track);
  }

  Future<void> _prepare(
      MusicTrack track, AudioPlayer player, String asset) async {
    // Nothing here needs the position, which the player would otherwise ask
    // the platform for on every frame while it plays
    player.positionUpdater = null;
    await player.setPlayerMode(PlayerMode.mediaPlayer);
    await player.setAudioContext(_musicContext);
    await player
        .setReleaseMode(track.loops ? ReleaseMode.loop : ReleaseMode.stop);
    await player.setVolume(0);
    // AssetSource takes the path under assets/
    await player.setSource(AssetSource(asset.substring('assets/'.length)));
  }

  /// Plays the music for [scene]. The menu's and a round's loops crossfade
  /// over [crossfade], and each carries on from where it was left. The
  /// fever fades the other loops out over [feverFadeOut] and plays the
  /// stinger from its start, then the fever loop from its start until
  /// another scene is asked for. Asking for the scene already playing
  /// changes nothing.
  void playScene(MusicScene scene) {
    if (scene == _scene || _disposed) return;
    _scene = scene;
    switch (scene) {
      case MusicScene.menu:
        _crossfadeTo(MusicTrack.menu);
      case MusicScene.round:
        _crossfadeTo(MusicTrack.round);
      case MusicScene.fever:
        _fadeTo(MusicTrack.menu, 0, feverFadeOut);
        _fadeTo(MusicTrack.round, 0, feverFadeOut);
        _fadeTo(MusicTrack.feverLoop, 0, feverFadeOut);
        _playFromStart(_players.containsKey(MusicTrack.feverStinger)
            ? MusicTrack.feverStinger
            : MusicTrack.feverLoop);
    }
  }

  /// Drops the music to [duck]'s level at once.
  void setDuck(MusicDuck duck) {
    if (duck == _duck) return;
    _duck = duck;
    _applyAll();
  }

  /// Sets the music volume, clamped to 0 to 1, from now on.
  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    _applyAll();
  }

  /// Pauses the music while the app is [hidden], and carries on from where
  /// it was when the app returns.
  void setAppHidden(bool hidden) {
    _hidden = hidden;
    _applyAll();
  }

  void _crossfadeTo(MusicTrack track) {
    for (final other in MusicTrack.values) {
      if (other != track) _fadeTo(other, 0, crossfade);
    }
    _fadeTo(track, 1, crossfade);
  }

  /// Fades [track] to [target] in steps of [fadeStep] over [duration].
  void _fadeTo(MusicTrack track, double target, Duration duration) {
    _fades.remove(track)?.cancel();
    final start = _gain[track]!;
    if (start == target || _disposed) return;
    final steps =
        math.max(1, duration.inMicroseconds ~/ fadeStep.inMicroseconds);
    var step = 0;
    _fades[track] = Timer.periodic(fadeStep, (timer) {
      step++;
      _gain[track] = start + (target - start) * step / steps;
      if (step == steps) {
        timer.cancel();
        _fades.remove(track);
      }
      _apply(track);
    });
  }

  /// Plays [track] from its start at full level.
  void _playFromStart(MusicTrack track) {
    _fades.remove(track)?.cancel();
    _gain[track] = 1;
    final player = _players[track];
    if (player != null) _call(track, () => player.seek(Duration.zero));
    _apply(track);
  }

  /// The stinger has played to its end, and the fever loop follows it if
  /// the fever is still on.
  void _stingerEnded() {
    // A fade out still running would set the gain up again on its next step
    // and start the stinger over
    _fades.remove(MusicTrack.feverStinger)?.cancel();
    _gain[MusicTrack.feverStinger] = 0;
    _sounding.remove(MusicTrack.feverStinger);
    if (_scene == MusicScene.fever) _playFromStart(MusicTrack.feverLoop);
  }

  void _applyAll() {
    for (final track in MusicTrack.values) {
      _apply(track);
    }
  }

  /// Gives [track]'s player its volume now, and plays or pauses it.
  void _apply(MusicTrack track) {
    final player = _players[track];
    if (player == null || _disposed) return;
    final gain = _gain[track]!;
    _call(track, () => player.setVolume(gain * _duck.level * _volume));
    final audible = _enabled && !_hidden && _volume > 0 && gain > 0;
    if (audible && _sounding.add(track)) {
      _call(track, player.resume);
    } else if (!audible && _sounding.remove(track)) {
      _call(track, player.pause);
    }
  }

  /// Makes [call] to [track]'s player without awaiting it. Never throws.
  void _call(MusicTrack track, Future<void> Function() call) {
    unawaited(() async {
      try {
        await _calls.track(call());
      } catch (e) {
        debugPrint('MusicService: ${track.name} failed: $e');
      }
    }());
  }

  /// Disposes every player. The app does not await it, so it never throws.
  /// Waits for loads and calls in flight first; anything asked for
  /// afterwards is ignored. Calling it again returns the same teardown.
  Future<void> dispose() => _disposal ??= _dispose();

  Future<void>? _disposal;

  Future<void> _dispose() async {
    _disposed = true;
    for (final fade in _fades.values) {
      fade.cancel();
    }
    _fades.clear();
    // Its end is not awaited: nothing more can arrive once it is cancelled
    unawaited(_stingerEnds?.cancel());
    await _calls.settled();
    for (final player in _allPlayers) {
      try {
        await player.dispose();
      } catch (e) {
        debugPrint('MusicService: could not dispose a player: $e');
      }
    }
  }
}
