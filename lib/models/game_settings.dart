/// The player's choices for sound, music, vibration, motion and the launcher's side, as the settings
/// screen shows them and `StorageService` keeps them.
///
/// Immutable: a change is a new value from [copyWith], given to
/// `GameManager.updateSettings`, which applies it and saves it.
class GameSettings {
  /// Whether sound effects play.
  final bool soundOn;

  /// How loud sound effects are, 0 to 1.
  final double soundVolume;

  /// How loud the music is, 0 to 1. With [soundOn] off there is no music
  /// either.
  final double musicVolume;

  /// Whether the phone vibrates for what happens on the board.
  final bool vibrationOn;

  /// Whether the board leaves out confetti and the prize peg shimmer and
  /// draws a short ball trail. Null until the player chooses, and then the
  /// system's setting decides (see [reducesMotion]).
  final bool? reducedMotion;

  /// Whether the launch channel and the plunger are on the left, for a
  /// left-handed player: the board is drawn reflected, and the game played on
  /// it is the same.
  final bool leftHanded;

  /// The settings of a new install: sound and vibration on, effects at full
  /// volume and music at 70%, motion as the system has it, and the launcher on the right.
  const GameSettings({
    this.soundOn = true,
    this.soundVolume = 1.0,
    this.musicVolume = 0.7,
    this.vibrationOn = true,
    this.reducedMotion,
    this.leftHanded = false,
  });

  /// Whether the board reduces motion, given whether the system asks apps
  /// to ([systemDisablesAnimations], `MediaQuery.disableAnimations`).
  bool reducesMotion({required bool systemDisablesAnimations}) =>
      reducedMotion ?? systemDisablesAnimations;

  /// These settings with the given ones changed.
  GameSettings copyWith({
    bool? soundOn,
    double? soundVolume,
    double? musicVolume,
    bool? vibrationOn,
    bool? reducedMotion,
    bool? leftHanded,
  }) =>
      GameSettings(
        soundOn: soundOn ?? this.soundOn,
        soundVolume: soundVolume ?? this.soundVolume,
        musicVolume: musicVolume ?? this.musicVolume,
        vibrationOn: vibrationOn ?? this.vibrationOn,
        reducedMotion: reducedMotion ?? this.reducedMotion,
        leftHanded: leftHanded ?? this.leftHanded,
      );

  @override
  bool operator ==(Object other) =>
      other is GameSettings &&
      other.soundOn == soundOn &&
      other.soundVolume == soundVolume &&
      other.musicVolume == musicVolume &&
      other.vibrationOn == vibrationOn &&
      other.reducedMotion == reducedMotion &&
      other.leftHanded == leftHanded;

  @override
  String toString() => 'GameSettings(soundOn: $soundOn, '
      'soundVolume: $soundVolume, musicVolume: $musicVolume, vibrationOn: $vibrationOn, '
      'reducedMotion: $reducedMotion, leftHanded: $leftHanded)';

  @override
  int get hashCode => Object.hash(soundOn, soundVolume, musicVolume,
      vibrationOn, reducedMotion, leftHanded);
}
