import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_manager.dart';
import '../models/game_state.dart';
import '../utils/constants.dart';
import '../widgets/pachinko_board.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameConstants.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Game HUD
            _GameHUD(),
            
            // Game Board
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: GameConstants.boardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: GameConstants.primaryColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const PachinkoBoard(),
              ),
            ),
            
            // Game Controls
            _GameControls(),
          ],
        ),
      ),
    );
  }
}

class _GameHUD extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<GameManager>(
      builder: (context, gameManager, child) {
        final gameState = gameManager.gameState;
        
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _HUDItem(
                icon: Icons.star,
                label: GameStrings.score,
                value: gameState.score.toString(),
                color: GameConstants.secondaryColor,
              ),
              _HUDItem(
                icon: Icons.sports_golf,
                label: GameStrings.ballsRemaining,
                value: gameState.ballsRemaining.toString(),
                color: GameConstants.ballColor,
              ),
              _HUDItem(
                icon: Icons.layers,
                label: GameStrings.level,
                value: gameState.currentLevelNumber.toString(),
                color: GameConstants.primaryColor,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HUDItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _HUDItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

class _GameControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<GameManager>(
      builder: (context, gameManager, child) {
        final gameState = gameManager.gameState;
        
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Back button
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                style: IconButton.styleFrom(
                  backgroundColor: GameConstants.surfaceColor,
                  foregroundColor: Colors.white,
                ),
              ),
              
              // Pause/Resume button
              if (gameState.phase == GamePhase.playing)
                IconButton(
                  onPressed: gameManager.pauseGame,
                  icon: const Icon(Icons.pause),
                  style: IconButton.styleFrom(
                    backgroundColor: GameConstants.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                )
              else if (gameState.phase == GamePhase.ready && gameState.activeBalls.isNotEmpty)
                IconButton(
                  onPressed: gameManager.resumeGame,
                  icon: const Icon(Icons.play_arrow),
                  style: IconButton.styleFrom(
                    backgroundColor: GameConstants.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              
              // Reset button
              IconButton(
                onPressed: gameManager.resetGame,
                icon: const Icon(Icons.restart_alt),
                style: IconButton.styleFrom(
                  backgroundColor: GameConstants.surfaceColor,
                  foregroundColor: Colors.white,
                ),
              ),
              
              // Next level button (shown when appropriate)
              if (gameState.phase == GamePhase.gameOver && gameState.ballsRemaining <= 0)
                ElevatedButton.icon(
                  onPressed: gameManager.nextLevel,
                  icon: const Icon(Icons.skip_next),
                  label: const Text('Next Level'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GameConstants.secondaryColor,
                    foregroundColor: Colors.black,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}