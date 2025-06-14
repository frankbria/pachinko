import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_manager.dart';
import '../utils/constants.dart';
import 'game_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameConstants.backgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              GameConstants.backgroundColor,
              GameConstants.boardColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Game Title
                Text(
                  GameStrings.appName,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      const Shadow(
                        blurRadius: 10.0,
                        color: GameConstants.primaryColor,
                        offset: Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Subtitle
                Text(
                  'Physics-based Pachinko Game',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white70,
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
                
                const SizedBox(height: 60),
                
                // Game Info
                Text(
                  'Launch balls, hit pegs, score points!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white60,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
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

  void _showLevelSelect(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GameConstants.surfaceColor,
        title: const Text('Select Level', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 20, // Show first 20 levels
            itemBuilder: (context, index) {
              final levelNumber = index + 1;
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  _startGameFromLevel(context, levelNumber);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: GameConstants.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: GameConstants.secondaryColor),
                  ),
                  child: Center(
                    child: Text(
                      '$levelNumber',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
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

  void _showInstructions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GameConstants.surfaceColor,
        title: const Text('How to Play', style: TextStyle(color: Colors.white)),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🎯 Objective:',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Text(
                'Score as many points as possible with 20 balls!\n',
                style: TextStyle(color: Colors.white70),
              ),
              Text(
                '🎮 Controls:',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Text(
                '• Tap and drag to aim your ball\n'
                '• Release to launch\n'
                '• Hit pegs to change ball direction\n',
                style: TextStyle(color: Colors.white70),
              ),
              Text(
                '⭐ Special Features:',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Text(
                '• Orange pegs are special - hit all special pegs to get bonus balls!\n'
                '• Edge slots give highest points but are hardest to reach\n'
                '• Center slot gives good points with medium difficulty\n',
                style: TextStyle(color: Colors.white70),
              ),
              Text(
                '🏆 Scoring:',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Text(
                '• Edge slots: 2000 points\n'
                '• Center slot: 1000 points\n'
                '• Other slots: 50-200 points\n',
                style: TextStyle(color: Colors.white70),
              ),
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
          foregroundColor: Colors.white,
          elevation: isPrimary ? 8 : 4,
          shadowColor: isPrimary 
              ? GameConstants.primaryColor.withOpacity(0.5) 
              : Colors.black.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
      ),
    );
  }
}