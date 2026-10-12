import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_manager.dart';
import '../utils/constants.dart';
import 'game_screen.dart';
import 'high_scores_screen.dart';
import 'settings_screen.dart';
import '../widgets/game_card.dart';
import 'achievements_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: SafeArea(
          child: Center(
            // Six buttons are taller than a small phone held sideways
            child: SingleChildScrollView(
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // The title as a magenta neon sign. The padding is wider than
                // the glow, so the sign and its glow both fit any screen
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 28.0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      GameStrings.appName,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Color.lerp(GameConstants.magentaColor, GameConstants.inkColor, 0.75),
                        fontWeight: FontWeight.bold,
                        shadows: [
                          const Shadow(blurRadius: 8.0, color: GameConstants.magentaColor),
                          Shadow(
                            blurRadius: 24.0,
                            color: GameConstants.magentaColor.withValues(alpha: 0.8),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                
                // Subtitle
                Text(
                  'Physics-based Pachinko Game',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: GameConstants.mutedColor,
                  ),
                ),
                
                const SizedBox(height: 60),
                
                // Play Button
                _MenuButton(
                  title: GameStrings.play,
                  icon: Icons.play_arrow,
                  onPressed: () => _startGame(context),
                  isPrimary: true,
                ),
                
                const SizedBox(height: 20),
                
                // Level Select Button
                _MenuButton(
                  title: 'Select Level',
                  icon: Icons.list,
                  onPressed: () => _showLevelSelect(context),
                ),
                
                const SizedBox(height: 20),
                
                // Instructions Button
                _MenuButton(
                  title: 'How to Play',
                  icon: Icons.help_outline,
                  onPressed: () => _showInstructions(context),
                ),

                const SizedBox(height: 20),

                // High Scores Button
                _MenuButton(
                  title: 'High Scores',
                  icon: Icons.emoji_events,
                  onPressed: () => _showHighScores(context),
                ),

                const SizedBox(height: 20),

                // Achievements Button
                _MenuButton(
                  title: 'Achievements',
                  icon: Icons.workspace_premium,
                  onPressed: () => _showAchievements(context),
                ),

                const SizedBox(height: 20),

                // Settings Button
                _MenuButton(
                  title: GameStrings.settings,
                  icon: Icons.settings,
                  onPressed: () => _showSettings(context),
                ),

                const SizedBox(height: 60),
                
                // Game Info
                Text(
                  'Launch balls, hit pegs, score points!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: GameConstants.mutedColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _startGame(BuildContext context) {
    final gameManager = context.read<GameManager>();
    gameManager.startGame();
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const GameScreen(),
      ),
    );
  }

  /// The level picker: twenty tiles in rows of five. A level that has been
  /// played is rimmed in gold and shows its best score.
  void _showLevelSelect(BuildContext context) {
    final bestScores = context.read<GameManager>().bestScoresByLevel();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Select Level'),
        // A fixed box: a dialog asks its content for its natural size, which
        // a grid cannot give. Four rows of five fit it at a phone's width
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: FutureBuilder<Map<int, int>>(
            future: bestScores,
            builder: (_, snapshot) {
              final best = snapshot.data ?? const <int, int>{};
              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: 20,
                itemBuilder: (_, index) {
                  final levelNumber = index + 1;
                  return _levelTile(context, dialogContext, levelNumber, best[levelNumber]);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _levelTile(BuildContext context, BuildContext dialogContext, int levelNumber, int? best) {
    return GestureDetector(
      onTap: () {
        Navigator.of(dialogContext).pop();
        _startGameFromLevel(context, levelNumber);
      },
      child: Container(
        decoration: BoxDecoration(
          color: GameConstants.cabinetColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: best != null
                ? GameConstants.secondaryColor.withValues(alpha: 0.8)
                : GameConstants.mutedColor.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$levelNumber',
              style: const TextStyle(
                color: GameConstants.inkColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            if (best != null)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  groupedThousands(best),
                  style: const TextStyle(
                    color: GameConstants.secondaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _startGameFromLevel(BuildContext context, int level) {
    final gameManager = context.read<GameManager>();
    gameManager.startGame(level: level);
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const GameScreen(),
      ),
    );
  }

  void _showInstructions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Play'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _heading(Icons.flag, 'Objective'),
              _body('Score as many points as possible with 20 balls.'),
              _heading(Icons.touch_app, 'Controls'),
              _body('• Drag from the launcher: the longer the drag, the more power\n'
                  '• Release to launch\n'
                  '• Pegs change the ball\'s direction'),
              _heading(Icons.auto_awesome, 'Special Features'),
              _body('• Gold pegs are prizes: hit them all for bonus balls\n'
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
  }

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
              style: const TextStyle(color: GameConstants.inkColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );

  Widget _body(String text) => Text(text, style: const TextStyle(color: GameConstants.mutedColor));

  void _showHighScores(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const HighScoresScreen(),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  void _showAchievements(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AchievementsScreen(),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _MenuButton({
    required this.title,
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? GameConstants.primaryColor : GameConstants.surfaceColor,
          foregroundColor: isPrimary ? GameConstants.onPrimaryColor : GameConstants.inkColor,
          elevation: isPrimary ? 8 : 0,
          shadowColor: GameConstants.primaryColor.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
            // Dark glass: a hairline rim in place of a shadow
            side: isPrimary
                ? BorderSide.none
                : BorderSide(color: GameConstants.mutedColor.withValues(alpha: 0.35), width: 1.5),
          ),
        ),
      ),
    );
  }
}