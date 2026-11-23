import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Opens How to Play over the current screen: the menu's button and the
/// game screen's help button both show it. Completes when it is closed.
Future<void> showHowToPlay(BuildContext context) => showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(GameStrings.howToPlay),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _heading(Icons.flag, 'Objective'),
              _body('Score as many points as possible with 20 balls. Each '
                  'level has three star scores; one star opens the next level.'),
              _heading(Icons.touch_app, 'Controls'),
              _body(
                  '• Drag from the launcher: the longer the drag, the more power\n'
                  '• Power sets where the ball comes down: a soft launch near the launcher, a full one at the far side. A mark on the dome shows where\n'
                  '• Release to launch\n'
                  '• Pegs change the ball\'s direction'),
              _heading(Icons.auto_awesome, 'Special Features'),
              _body('• Gold pegs are prizes: hit them all for bonus balls\n'
                  '• The bonus brings a fever: for a few seconds of play every slot pays ×${GameConstants.feverMultiplier}\n'
                  '• Edge slots give the most points and are the hardest to reach\n'
                  '• The centre slot gives good points'),
              _heading(Icons.emoji_events, 'Scoring'),
              _body('• Edge slots: 2000 points\n'
                  '• Centre slot: 1000 points\n'
                  '• Other slots: 50 to 200 points'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );

/// A section heading in How to Play: an icon from the icon font, not an
/// emoji, and its title.
Widget _heading(IconData icon, String title) => Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: GameConstants.primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
                color: GameConstants.inkColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );

Widget _body(String text) =>
    Text(text, style: const TextStyle(color: GameConstants.mutedColor));
