import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import '../services/game_manager.dart';
import '../models/game_state.dart';
import '../models/level.dart';
import '../models/peg.dart';
import '../utils/constants.dart';
import 'board_effects.dart';
import 'board_static_layer.dart';

class PachinkoBoard extends StatefulWidget {
  const PachinkoBoard({super.key});

  @override
  State<PachinkoBoard> createState() => _PachinkoBoardState();
}

class _PachinkoBoardState extends State<PachinkoBoard>
    with SingleTickerProviderStateMixin {
  vm.Vector2? _dragStart;
  vm.Vector2? _dragEnd;
  bool _isDragging = false;
  double _currentScale = 1.0; // Store current scale for touch handling

  late final GameManager _gameManager;

  // Peg animation (the prize peg shimmer and the hit pulse) runs on the
  // board's own ticker, so it does not depend on the game loop ticking
  late final Ticker _pegTicker;
  Duration _lastPegTick = Duration.zero;
  final ValueNotifier<int> _pegFrame = ValueNotifier<int>(0);

  // What makes the board repaint. It repaints without rebuilding
  late final Listenable _repaint;

  // The felt, rail, pins and slots, recorded once per level
  final BoardStaticLayer _staticLayer = BoardStaticLayer();

  @override
  void initState() {
    super.initState();
    _gameManager = context.read<GameManager>();
    _pegTicker = createTicker(_onPegTick);
    _repaint = Listenable.merge([_gameManager, _gameManager.gameState, _pegFrame]);
    _gameManager.addListener(_syncPegTicker);
    _syncPegTicker();
  }

  @override
  void dispose() {
    _gameManager.removeListener(_syncPegTicker);
    _pegTicker.dispose();
    _pegFrame.dispose();
    _staticLayer.dispose();
    super.dispose();
  }

  bool get _pegsAnimating =>
      _gameManager.gameState.currentLevel?.pegs.any((peg) => peg.isAnimating) ?? false;

  /// Runs the peg ticker while a peg is animating and stops it otherwise, so
  /// a board with nothing to animate draws no frames.
  void _syncPegTicker() {
    if (_pegsAnimating) {
      if (!_pegTicker.isActive) {
        _lastPegTick = Duration.zero;
        _pegTicker.start();
      }
    } else if (_pegTicker.isActive) {
      _pegTicker.stop();
    }
  }

  void _onPegTick(Duration elapsed) {
    final deltaTime = (elapsed - _lastPegTick).inMicroseconds / Duration.microsecondsPerSecond;
    _lastPegTick = elapsed;
    final pegs = _gameManager.gameState.currentLevel?.pegs ?? const <Peg>[];
    for (final peg in pegs) {
      peg.updateAnimation(deltaTime);
    }
    _pegFrame.value++;
    _syncPegTicker();
  }

  @override
  Widget build(BuildContext context) {
    final gameManager = _gameManager;
    return GestureDetector(
      onPanStart: (details) => _onPanStart(details, gameManager),
      onPanUpdate: (details) => _onPanUpdate(details, gameManager),
      onPanEnd: (details) => _onPanEnd(details, gameManager),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate scale for touch handling
          final scaleX = constraints.maxWidth / GameConstants.boardWidth;
          final scaleY = constraints.maxHeight / GameConstants.boardHeight;
          _currentScale = scaleX < scaleY ? scaleX : scaleY;

          return CustomPaint(
            painter: _PachinkoBoardPainter(
              gameManager: gameManager,
              staticLayer: _staticLayer,
              repaint: _repaint,
              dragStart: _dragStart,
              dragEnd: _dragEnd,
              isDragging: _isDragging,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }

  void _onPanStart(DragStartDetails details, GameManager gameManager) {
    if (!gameManager.gameState.canLaunchBall) return;
    
    // Check if tap is in launch area (bottom right)
    final tapX = details.localPosition.dx;
    final tapY = details.localPosition.dy;
    
    // Scale coordinates to game coordinates
    final gameX = tapX / _getScale(gameManager);
    final gameY = tapY / _getScale(gameManager);
    
    // Check if tap is near the launch area
    if (gameX > GameConstants.launchChannelStartX - 50 && 
        gameY > GameConstants.launchChannelStartY - 50) {
      gameManager.startLaunchCharging();
      setState(() {
        _isDragging = true;
        _dragStart = vm.Vector2(tapX, tapY);
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details, GameManager gameManager) {
    if (!_isDragging || !gameManager.gameState.canLaunchBall) return;
    
    setState(() {
      _dragEnd = vm.Vector2(details.localPosition.dx, details.localPosition.dy);
    });
    
    // Calculate power based on drag distance
    if (_dragStart != null && _dragEnd != null) {
      final dragDistance = (_dragEnd! - _dragStart!).length;
      final power = (dragDistance / 2.0).clamp(0.0, 100.0); // 0 to 100
      gameManager.updateLaunchPower(power);
    }
  }

  void _onPanEnd(DragEndDetails details, GameManager gameManager) {
    if (_isDragging && gameManager.gameState.canLaunchBall) {
      gameManager.launchBall();
    }
    
    setState(() {
      _isDragging = false;
      _dragStart = null;
      _dragEnd = null;
    });
  }
  
  double _getScale(GameManager gameManager) {
    return _currentScale;
  }
}

class _PachinkoBoardPainter extends CustomPainter {
  final GameManager gameManager;
  final BoardStaticLayer staticLayer;
  final vm.Vector2? dragStart;
  final vm.Vector2? dragEnd;
  final bool isDragging;

  _PachinkoBoardPainter({
    required this.gameManager,
    required this.staticLayer,
    required Listenable repaint,
    this.dragStart,
    this.dragEnd,
    this.isDragging = false,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final gameState = gameManager.gameState;
    final level = gameState.currentLevel;
    
    if (level == null) return;
    
    // Scale the board to fit the available space
    final scaleX = size.width / GameConstants.boardWidth;
    final scaleY = size.height / GameConstants.boardHeight;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    
    canvas.save();
    canvas.scale(scale);
    
    // Felt, rail, pins and slots: recorded once per level and replayed
    canvas.drawPicture(staticLayer.pictureFor(level));

    _drawSlotCounts(canvas, level);
    _drawAnimatedPegs(canvas, level);

    // The bonus announcement dims the board. It goes under the balls, the
    // confetti and the score popups, which would be muddied beneath it
    if (gameState.specialBonusTriggered) {
      paintBonusOverlay(
        canvas,
        opacity: gameState.bonusOverlayOpacity,
        bonusBalls: 5 + (gameState.currentLevelNumber ~/ 2),
      );
    }

    // Draw balls
    _drawBalls(canvas, gameState);

    _drawLaunchArea(canvas, level);
    
    // Draw launch power indicator
    if (isDragging && dragStart != null && dragEnd != null && gameState.canLaunchBall) {
      _drawLaunchPowerIndicator(canvas, scale);
    }

    // Draw confetti particles
    for (final particle in gameState.confettiParticles) {
      paintConfettiPiece(canvas, particle);
    }

    // Draw floating texts
    for (final floatingText in gameState.floatingTexts) {
      _drawFloatingText(canvas, floatingText);
    }

    canvas.restore();
  }

  /// How many balls each slot has caught. The slots themselves are in the
  /// static layer; the count changes during a level.
  void _drawSlotCounts(Canvas canvas, Level level) {
    for (final slot in level.slots) {
      if (slot.ballCount == 0) continue;

      final ballCountPainter = TextPainter(
        text: TextSpan(
          text: '×${slot.ballCount}',
          style: const TextStyle(
            color: GameConstants.inkColor,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      ballCountPainter.layout();
      ballCountPainter.paint(
        canvas,
        Offset(
          slot.position.x - ballCountPainter.width / 2,
          slot.position.y + 15,
        ),
      );
    }
  }

  /// Prize pegs, and any pin in the middle of its hit pulse. A pin at rest is
  /// in the static layer and is not drawn again here.
  ///
  /// A prize peg still to win is a gold sphere in a soft halo with two rings,
  /// which breathe with its shimmer. Once collected it is dim, with one thin
  /// ring and no halo, so that it is plain which prizes remain.
  void _drawAnimatedPegs(Canvas canvas, Level level) {
    for (final peg in level.pegs) {
      if (peg.type != PegType.special && !peg.isAnimating) continue;
      final centre = Offset(peg.position.x, peg.position.y);

      // Draw pulse glow effect (on hit)
      if (peg.pulseGlowRadius > 0.0) {
        final pulsePaint = Paint()
          ..color = peg.color.withValues(alpha: peg.pulseGlowOpacity)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(centre, peg.pulseGlowRadius, pulsePaint);
      }

      Paint ring(double width, double strength) => Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = GameConstants.specialPegColor.withValues(alpha: strength);

      if (peg.type != PegType.special) {
        paintSphere(canvas, centre, peg.radius, peg.renderColor);
      } else if (peg.isCollected) {
        paintSphere(canvas, centre, peg.radius, peg.renderColor);
        canvas.drawCircle(centre, peg.radius + 2, ring(1, 0.55));
      } else {
        paintSphere(canvas, centre, peg.radius, peg.renderColor, glowColour: GameConstants.specialPegColor);
        // shimmerIntensity runs from 0.0 to 0.6
        final strength = 0.5 + 0.7 * peg.shimmerIntensity;
        canvas.drawCircle(centre, peg.radius + 3, ring(1.5, strength));
        canvas.drawCircle(centre, peg.radius + 6.5, ring(1, strength * 0.45));
      }
    }
  }

  /// Each ball as a shaded sphere over a soft glow, with a fading trail
  /// behind it: the ball is what the player has to follow.
  void _drawBalls(Canvas canvas, GameState gameState) {
    for (final ball in gameState.activeBalls) {
      if (!ball.isActive) continue;

      // Oldest first: each step nearer the ball is larger and more opaque
      final trail = ball.trail;
      for (int i = 0; i < trail.length; i++) {
        final nearness = (i + 1) / (trail.length + 1);
        canvas.drawCircle(
          Offset(trail[i].x, trail[i].y),
          ball.radius * (0.3 + 0.6 * nearness),
          Paint()..color = ball.color.withValues(alpha: 0.35 * nearness),
        );
      }

      paintSphere(
        canvas,
        Offset(ball.position.x, ball.position.y),
        ball.radius,
        ball.color,
        glowColour: ball.color,
      );
    }
  }

  void _drawLaunchArea(Canvas canvas, level) {
    // Draw launch area background
    final paint = Paint()
      ..color = GameConstants.primaryColor.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(
      Rect.fromLTWH(
        GameConstants.launchChannelStartX - 20,
        GameConstants.launchChannelStartY - 20,
        GameConstants.launchChannelWidth + 40,
        40,
      ),
      paint,
    );
    
    // Draw launch point
    final launchPaint = Paint()
      ..color = GameConstants.ballColor
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(level.launchX, level.launchY),
      GameConstants.ballRadius,
      launchPaint,
    );
    
    // Draw launch instructions
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'DRAG TO\nLAUNCH',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        GameConstants.launchChannelStartX - 15,
        GameConstants.launchChannelStartY + 25,
      ),
    );
  }

  void _drawLaunchPowerIndicator(Canvas canvas, double scale) {
    // Draw power meter
    final power = gameManager.ballLauncher.launchPower;
    final maxPower = gameManager.ballLauncher.maxPower;
    final powerRatio = power / maxPower;
    
    // Power meter background
    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    final meterRect = Rect.fromLTWH(
      GameConstants.launchChannelStartX - 60,
      GameConstants.launchChannelStartY - 100,
      20,
      100,
    );
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(meterRect, const Radius.circular(10)),
      bgPaint,
    );
    
    // Power meter fill
    final powerPaint = Paint()
      ..color = Color.lerp(Colors.green, Colors.red, powerRatio)!
      ..style = PaintingStyle.fill;
    
    final powerHeight = meterRect.height * powerRatio;
    final powerRect = Rect.fromLTWH(
      meterRect.left,
      meterRect.bottom - powerHeight,
      meterRect.width,
      powerHeight,
    );
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(powerRect, const Radius.circular(10)),
      powerPaint,
    );
    
    // Power meter label
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'POWER\n${(powerRatio * 100).toInt()}%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        meterRect.left - 10,
        meterRect.top - 30,
      ),
    );
  }

  void _drawFloatingText(Canvas canvas, floatingText) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: floatingText.text,
        style: TextStyle(
          color: floatingText.color.withOpacity(floatingText.opacity),
          fontSize: 20,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(floatingText.opacity * 0.5),
              blurRadius: 4,
              offset: const Offset(1, 1),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        floatingText.currentPosition.dx - textPainter.width / 2,
        floatingText.currentPosition.dy,
      ),
    );
  }

  /// The game's own changes reach the painter through its repaint listenable.
  /// A new painter only needs a repaint when what it was built with differs.
  @override
  bool shouldRepaint(covariant _PachinkoBoardPainter oldDelegate) =>
      oldDelegate.gameManager != gameManager ||
      oldDelegate.dragStart != dragStart ||
      oldDelegate.dragEnd != dragEnd ||
      oldDelegate.isDragging != isDragging;
}