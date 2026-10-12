import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_manager.dart';
import '../models/game_state.dart';
import '../utils/constants.dart';
import '../widgets/achievement_toast_overlay.dart';
import '../models/round_summary.dart';
import '../widgets/pachinko_board.dart';
import '../widgets/round_summary_panel.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameManager _gameManager;
  final GlobalKey _headerKey = GlobalKey();
  AchievementToastOverlayState? _toasts;
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _gameManager = context.read<GameManager>();
    _toasts = AchievementToastOverlay.of(context);
    _lifecycleListener = AppLifecycleListener(onHide: _pauseWhileHidden);
    // The header has no size until the first frame has been laid out
    WidgetsBinding.instance.addPostFrameCallback((_) => _anchorToastsBelowHeader());
  }

  /// Tells the toast overlay how tall the score header is, so an achievement
  /// toast starts below it and the score, ball count and level stay readable.
  void _anchorToastsBelowHeader() {
    if (!mounted) return;
    final headerHeight = _headerKey.currentContext?.size?.height;
    if (headerHeight != null) _toasts?.anchorToasts(this, headerHeight);
  }

  /// Pauses a ball in play when the app is no longer visible (Home, the app
  /// switcher). Timers keep firing for a while after that, so without this
  /// the ball would play on unseen. The player resumes with the Resume button.
  void _pauseWhileHidden() {
    if (_gameManager.gameState.phase == GamePhase.playing) {
      _gameManager.pauseGame();
    }
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    // Leaving the screen abandons the game in progress; stop it playing on in the background
    _gameManager.stopLoop();
    // The overlay is an ancestor, and an ancestor cannot be rebuilt while this
    // subtree is being torn down, so the release waits for the frame to end
    final toasts = _toasts;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (toasts != null && toasts.mounted) toasts.releaseToasts(this);
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameConstants.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Game HUD. Its height changes with the text scale, and the toast
            // anchor has to follow it
            NotificationListener<SizeChangedLayoutNotification>(
              onNotification: (_) {
                // Sent during layout, when the overlay cannot be rebuilt yet
                WidgetsBinding.instance.addPostFrameCallback((_) => _anchorToastsBelowHeader());
                return true;
              },
              child: SizeChangedLayoutNotifier(
                key: _headerKey,
                child: _GameHUD(),
              ),
            ),
            
            // Game Board
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                margin: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  // The felt darkens to this at the board's foot, so the
                  // strip under the board continues it
                  color: GameConstants.feltShadeColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: GameConstants.primaryColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const PachinkoBoard(),
              ),
                  const _RoundSummaryOverlay(),
                ],
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

/// The score, the balls left and the level: three matching tiles in one row.
class _GameHUD extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<GameManager>(
      builder: (context, gameManager, child) {
        final gameState = gameManager.gameState;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: _HUDItem(
                  icon: Icons.star,
                  label: GameStrings.score,
                  value: gameState.score.toString(),
                  countTo: gameState.score,
                  // Gold is the score's colour and nothing else's in the header
                  color: GameConstants.secondaryColor,
                  valueColor: GameConstants.secondaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HUDItem(
                  icon: Icons.sports_golf,
                  label: GameStrings.ballsRemaining,
                  value: gameState.ballsRemaining.toString(),
                  color: GameConstants.ballColor,
                  highlighted: gameState.ballCountHighlighted,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HUDItem(
                  icon: Icons.layers,
                  label: GameStrings.level,
                  value: gameState.currentLevelNumber.toString(),
                  color: GameConstants.primaryColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// One stat tile: icon, label and value on a single line.
class _HUDItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color valueColor;
  final bool highlighted;

  /// When set, the value counts up to this number instead of jumping to it.
  final int? countTo;

  const _HUDItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.valueColor = GameConstants.inkColor,
    this.highlighted = false,
    this.countTo,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: highlighted
            ? GameConstants.bonusBallColor.withValues(alpha: 0.25)
            : GameConstants.surfaceColor,
        borderRadius: BorderRadius.circular(10),
        // The same width in both states: a change would resize the header
        border: Border.all(
          color: highlighted
              ? GameConstants.bonusBallColor
              : GameConstants.mutedColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: highlighted ? GameConstants.bonusBallColor : color,
            size: 16,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: highlighted ? GameConstants.bonusBallColor : GameConstants.mutedColor,
              ),
            ),
          ),
          // A long score shrinks to fit its half of the tile
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: countTo == null
                  ? _valueText(context, value)
                  : TweenAnimationBuilder<double>(
                      // No begin: the first build shows the number as it is,
                      // and each later change runs from the number on screen
                      tween: Tween<double>(end: countTo!.toDouble()),
                      duration: const Duration(milliseconds: 400),
                      builder: (context, shown, child) => _valueText(context, shown.round().toString()),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _valueText(BuildContext context, String shown) => Text(
        shown,
        maxLines: 1,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: highlighted ? GameConstants.bonusBallColor : valueColor,
          fontWeight: FontWeight.bold,
        ),
      );
}

/// The round summary, over the board once the last ball has landed. It
/// replaces the bare Next Level button the controls row used to grow.
class _RoundSummaryOverlay extends StatelessWidget {
  const _RoundSummaryOverlay();

  @override
  Widget build(BuildContext context) {
    return Consumer<GameManager>(
      builder: (context, gameManager, child) {
        final gameState = gameManager.gameState;
        if (gameState.phase != GamePhase.gameOver || gameState.ballsRemaining > 0) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: RoundSummaryPanel(
            summary: RoundSummary.of(gameState, isNewBest: gameManager.roundIsNewBest),
            // Leaving does what Back does: the screen's dispose stops the loop
            onMenu: () => Navigator.of(context).pop(),
            onReplay: gameManager.resetGame,
            onNextLevel: gameManager.nextLevel,
          ),
        );
      },
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
                    foregroundColor: GameConstants.onPrimaryColor,
                  ),
                )
              else if (gameState.phase == GamePhase.ready && gameState.activeBalls.isNotEmpty)
                IconButton(
                  onPressed: gameManager.resumeGame,
                  icon: const Icon(Icons.play_arrow),
                  style: IconButton.styleFrom(
                    backgroundColor: GameConstants.primaryColor,
                    foregroundColor: GameConstants.onPrimaryColor,
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
            ],
          ),
        );
      },
    );
  }
}