import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_manager.dart';
import '../utils/constants.dart';

/// The game's settings. One so far: whether a ball may only be launched once
/// no ball is in play.
///
/// The choice goes through [GameManager.setSingleBallLaunch], which applies
/// it to the game and saves it.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameManager = context.watch<GameManager>();

    return Scaffold(
      appBar: AppBar(title: const Text(GameStrings.settings)),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text(GameStrings.singleBallLaunch),
            subtitle: const Text(GameStrings.singleBallLaunchHint),
            value: gameManager.gameState.singleBallLaunch,
            onChanged: gameManager.setSingleBallLaunch,
          ),
        ],
      ),
    );
  }
}
