/// The player's choices for sound, vibration and motion, as the settings
/// screen shows them and `StorageService` keeps them.
///
/// Immutable: a change is a new value from [copyWith], given to
/// `GameManager.updateSettings`, which applies it and saves it.
class GameSettings {
  /// Whether sound effects play.
  final bool soundOn;

  /// How loud sound effects are, 0 to 1.
  final double soundVolume;

  /// Whether the phone vibrates for what happens on the board.
  final bool vibrationOn;

  /// Whether the board leaves out confetti and the prize peg shimmer and
  /// draws a short ball trail. Null until the player chooses, and then the
  /// system's setting decides (see [reducesMotion]).
  final bool? reducedMotion;

  /// The settings of a new install: sound and vibration on at full volume,
  /// and motion as the system has it.
  const GameSettings({
    this.soundOn = true,
    this.soundVolume = 1.0,
    this.vibrationOn = true,
    this.reducedMotion,
  });

  /// Whether the board reduces motion, given whether the system asks apps
  /// to ([systemDisablesAnimations], `MediaQuery.disableAnimations`).
  bool reducesMotion({required bool systemDisablesAnimations}) =>
      reducedMotion ?? systemDisablesAnimations;

  /// These settings with the given ones changed.
  GameSettings copyWith({
    bool? soundOn,
    double? soundVolume,
    bool? vibrationOn,
    bool? reducedMotion,
  }) =>
      GameSettings(
        soundOn: soundOn ?? this.soundOn,
        soundVolume: soundVolume ?? this.soundVolume,
        vibrationOn: vibrationOn ?? this.vibrationOn,
        reducedMotion: reducedMotion ?? this.reducedMotion,
      );

  @override
  bool operator ==(Object other) =>
      other is GameSettings &&
      other.soundOn == soundOn &&
      other.soundVolume == soundVolume &&
      other.vibrationOn == vibrationOn &&
      other.reducedMotion == reducedMotion;

  @override
  String toString() => 'GameSettings(soundOn: $soundOn, '
      'soundVolume: $soundVolume, vibrationOn: $vibrationOn, '
      'reducedMotion: $reducedMotion)';

  @override
  int get hashCode =>
      Object.hash(soundOn, soundVolume, vibrationOn, reducedMotion);
}
