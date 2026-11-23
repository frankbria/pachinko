import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/star_targets.dart';
import '../services/game_manager.dart';
import '../utils/constants.dart';
import 'game_screen.dart';
import 'high_scores_screen.dart';
import 'settings_screen.dart';
import '../widgets/game_card.dart';
import '../widgets/how_to_play_dialog.dart';
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32.0, vertical: 28.0),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        GameStrings.appName,
                        style:
                            Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: Color.lerp(GameConstants.magentaColor,
                              GameConstants.inkColor, 0.75),
                          fontWeight: FontWeight.bold,
                          shadows: [
                            const Shadow(
                                blurRadius: 8.0,
                                color: GameConstants.magentaColor),
                            Shadow(
                              blurRadius: 24.0,
                              color: GameConstants.magentaColor
                                  .withValues(alpha: 0.8),
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
                    title: GameStrings.howToPlay,
                    icon: Icons.help_outline,
                    onPressed: () => showHowToPlay(context),
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

  /// The level picker: twenty tiles in rows of five. Each open level shows
  /// its stars; a level whose level before has no star yet is locked and
  /// cannot be started. A played level shows its best score, rimmed in gold.
  void _showLevelSelect(BuildContext context) {
    final gameManager = context.read<GameManager>();
    final progress = Future.wait(
        [gameManager.bestScoresByLevel(), gameManager.starsByLevel()]);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Select Level'),
        // A fixed box: a dialog asks its content for its natural size, which
        // a grid cannot give. Four rows of five fit it at a phone's width
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: FutureBuilder<List<Map<int, int>>>(
            future: progress,
            builder: (_, snapshot) {
              // Until storage answers only level 1 is known to be open
              final [best, stars] =
                  snapshot.data ?? const <Map<int, int>>[{}, {}];
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
                  return _LevelTile(
                    levelNumber: levelNumber,
                    best: best[levelNumber],
                    stars: stars[levelNumber] ?? 0,
                    isOpen: levelNumber == 1 ||
                        snapshot.hasData &&
                            StarTargets.levelIsOpen(levelNumber, stars),
                    onOpen: () {
                      Navigator.of(dialogContext).pop();
                      _startGameFromLevel(context, levelNumber);
                    },
                  );
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

  void _startGameFromLevel(BuildContext context, int level) {
    final gameManager = context.read<GameManager>();
    gameManager.startGame(level: level);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const GameScreen(),
      ),
    );
  }

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

/// One level in the picker: its number, its stars or a lock when it is not
/// open, and its best score once played. A level played before locks
/// existed can be locked and still show its score.
class _LevelTile extends StatelessWidget {
  final int levelNumber;
  final int? best;
  final int stars;
  final bool isOpen;
  final VoidCallback onOpen;

  const _LevelTile({
    required this.levelNumber,
    required this.best,
    required this.stars,
    required this.isOpen,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final score = best;
    return Semantics(
      button: true,
      enabled: isOpen,
      label: '${GameStrings.level} $levelNumber',
      value:
          isOpen ? GameStrings.starsWon(stars, null) : GameStrings.levelLocked,
      hint: isOpen ? null : GameStrings.levelLockedHint,
      // The tile's own tap is hidden with its children, so a screen reader
      // gets it here
      onTap: isOpen ? onOpen : null,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: isOpen ? onOpen : null,
        child: Container(
          decoration: BoxDecoration(
            color: GameConstants.cabinetColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: score != null
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
                style: TextStyle(
                  color: isOpen
                      ? GameConstants.inkColor
                      : GameConstants.mutedColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              if (!isOpen)
                const Icon(Icons.lock,
                    size: 14, color: GameConstants.mutedColor)
              else
                StarRow(stars: stars, size: 12),
              if (score != null)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    groupedThousands(score),
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
          backgroundColor: isPrimary
              ? GameConstants.primaryColor
              : GameConstants.surfaceColor,
          foregroundColor:
              isPrimary ? GameConstants.onPrimaryColor : GameConstants.inkColor,
          elevation: isPrimary ? 8 : 0,
          shadowColor: GameConstants.primaryColor.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
            // Dark glass: a hairline rim in place of a shadow
            side: isPrimary
                ? BorderSide.none
                : BorderSide(
                    color: GameConstants.mutedColor.withValues(alpha: 0.35),
                    width: 1.5),
          ),
        ),
      ),
    );
  }
}
