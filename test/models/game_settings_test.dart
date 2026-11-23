import 'package:flutter_test/flutter_test.dart';
import 'package:pachinko_game/models/game_settings.dart';

void main() {
  test('a new install has sound and vibration on at full volume', () {
    const settings = GameSettings();

    expect(settings.soundOn, isTrue);
    expect(settings.soundVolume, 1.0);
    expect(settings.vibrationOn, isTrue);
    expect(settings.reducedMotion, isNull);
  });

  group('reduced motion', () {
    test('follows the system until the player chooses', () {
      const settings = GameSettings();

      expect(settings.reducesMotion(systemDisablesAnimations: true), isTrue);
      expect(settings.reducesMotion(systemDisablesAnimations: false), isFalse);
    });

    test('the player\'s choice overrides the system', () {
      expect(
          const GameSettings(reducedMotion: false)
              .reducesMotion(systemDisablesAnimations: true),
          isFalse);
      expect(
          const GameSettings(reducedMotion: true)
              .reducesMotion(systemDisablesAnimations: false),
          isTrue);
    });
  });

  test('copyWith changes only what it is given', () {
    const settings = GameSettings();

    expect(
        settings.copyWith(soundOn: false), const GameSettings(soundOn: false));
    expect(settings.copyWith(soundVolume: 0.4),
        const GameSettings(soundVolume: 0.4));
    expect(settings.copyWith(vibrationOn: false),
        const GameSettings(vibrationOn: false));
    expect(settings.copyWith(reducedMotion: true),
        const GameSettings(reducedMotion: true));
  });

  test('settings are equal when every choice is', () {
    expect(const GameSettings(soundVolume: 0.5),
        const GameSettings(soundVolume: 0.5));
    expect(const GameSettings(soundVolume: 0.5).hashCode,
        const GameSettings(soundVolume: 0.5).hashCode);
    expect(const GameSettings(soundVolume: 0.5),
        isNot(const GameSettings(soundVolume: 0.6)));
  });

  test('settings say what they are, for a failing expectation to show', () {
    expect(
        const GameSettings(soundOn: false, reducedMotion: true).toString(),
        'GameSettings(soundOn: false, soundVolume: 1.0, vibrationOn: true, '
        'reducedMotion: true)');
  });
}
