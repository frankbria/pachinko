import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_manager.dart';
import '../utils/constants.dart';
import '../widgets/achievement_toast_overlay.dart';

/// The game's settings: whether a ball may only be launched once no ball is
/// in play, sound and its volume, the music's volume, vibration, reduced
/// motion and the side the launcher is on, and the game's credits.
///
/// Each choice goes through the manager ([GameManager.setSingleBallLaunch],
/// [GameManager.updateSettings]), which applies it to the game at once and
/// saves it.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameManager = context.watch<GameManager>();
    final settings = gameManager.settings;
    final reducesMotion = settings.reducesMotion(
        systemDisablesAnimations: MediaQuery.disableAnimationsOf(context));
    // Each control changes one setting of the manager's own at the moment of
    // the change, not of those built here: two changes before a rebuild must
    // both stand, and so must the stored settings a change does not touch
    final change = gameManager.updateSettings;

    // Toasts start below the app bar: one at the top would lie over the
    // title and the Back button
    return ToastAnchor(
        child: Scaffold(
      appBar: AppBar(title: const Text(GameStrings.settings)),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text(GameStrings.singleBallLaunch),
            subtitle: const Text(GameStrings.singleBallLaunchHint),
            value: gameManager.gameState.singleBallLaunch,
            onChanged: gameManager.setSingleBallLaunch,
          ),
          SwitchListTile(
            title: const Text(GameStrings.soundEffects),
            value: settings.soundOn,
            onChanged: (on) =>
                change((current) => current.copyWith(soundOn: on)),
          ),
          ListTile(
            title: const Text(GameStrings.volume),
            subtitle: Slider(
              value: settings.soundVolume,
              divisions: 10,
              label: '${(settings.soundVolume * 100).round()}%',
              semanticFormatterCallback: (volume) =>
                  '${(volume * 100).round()}%',
              onChanged: settings.soundOn
                  ? (volume) =>
                      change((current) => current.copyWith(soundVolume: volume))
                  : null,
            ),
          ),
          ListTile(
            title: const Text(GameStrings.musicVolume),
            subtitle: Slider(
              value: settings.musicVolume,
              divisions: 10,
              label: '${(settings.musicVolume * 100).round()}%',
              semanticFormatterCallback: (volume) =>
                  '${(volume * 100).round()}%',
              onChanged: settings.soundOn
                  ? (volume) =>
                      change((current) => current.copyWith(musicVolume: volume))
                  : null,
            ),
          ),
          SwitchListTile(
            title: const Text(GameStrings.vibration),
            subtitle: const Text(GameStrings.vibrationHint),
            value: settings.vibrationOn,
            onChanged: (on) =>
                change((current) => current.copyWith(vibrationOn: on)),
          ),
          SwitchListTile(
            title: const Text(GameStrings.reducedMotion),
            subtitle: const Text(GameStrings.reducedMotionHint),
            value: reducesMotion,
            onChanged: (reduce) =>
                change((current) => current.copyWith(reducedMotion: reduce)),
          ),
          SwitchListTile(
            title: const Text(GameStrings.leftHanded),
            subtitle: const Text(GameStrings.leftHandedHint),
            value: settings.leftHanded,
            onChanged: (left) =>
                change((current) => current.copyWith(leftHanded: left)),
          ),
          const ListTile(
            title: Text(GameStrings.credits),
            subtitle: Text(GameStrings.creditLines),
          ),
        ],
      ),
    ));
  }
}
