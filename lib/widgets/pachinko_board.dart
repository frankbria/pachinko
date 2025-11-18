import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import '../services/game_manager.dart';
import '../models/game_state.dart';
import '../models/peg.dart';
import '../utils/constants.dart';

class PachinkoBoard extends StatefulWidget {
  const PachinkoBoard({super.key});

  @override
  State<PachinkoBoard> createState() => _PachinkoBoardState();
}

class _PachinkoBoardState extends State<PachinkoBoard> {
  vm.Vector2? _dragStart;
  vm.Vector2? _dragEnd;
  bool _isDragging = false;
  double _currentScale = 1.0; // Store current scale for touch handling

  @override
  Widget build(BuildContext context) {
    return Consumer<GameManager>(
      builder: (context, gameManager, child) {
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
                  dragStart: _dragStart,
                  dragEnd: _dragEnd,
                  isDragging: _isDragging,
                ),
                size: Size.infinite,
              );
            },
          ),
        );
      },
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
  final vm.Vector2? dragStart;
  final vm.Vector2? dragEnd;
  final bool isDragging;

  _PachinkoBoardPainter({
    required this.gameManager,
    this.dragStart,
    this.dragEnd,
    this.isDragging = false,
  });

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
    
    // Draw background
    _drawBackground(canvas, size, scale);
    
    // Draw slots
    _drawSlots(canvas, level);
    
    // Draw pegs
    _drawPegs(canvas, level);
    
    // Draw balls
    _drawBalls(canvas, gameState);
    
    // Draw launch channel and area
    _drawLaunchChannel(canvas, level);
    _drawLaunchArea(canvas, level);
    
    // Draw launch power indicator
    if (isDragging && dragStart != null && dragEnd != null && gameState.canLaunchBall) {
      _drawLaunchPowerIndicator(canvas, scale);
    }
    
    // Draw special bonus indicator
    if (gameState.specialBonusTriggered) {
      _drawSpecialBonusEffect(canvas, size, scale);
    }
    
    canvas.restore();
  }

  void _drawBackground(Canvas canvas, Size size, double scale) {
    final paint = Paint()
      ..color = GameConstants.boardColor
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(
      Rect.fromLTWH(0, 0, GameConstants.boardWidth, GameConstants.boardHeight),
      paint,
    );
  }

  void _drawSlots(Canvas canvas, level) {
    for (final slot in level.slots) {
      final paint = Paint()
        ..color = slot.color
        ..style = PaintingStyle.fill;
      
      final borderPaint = Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      
      final rect = Rect.fromCenter(
        center: Offset(slot.position.x, slot.position.y),
        width: slot.width,
        height: slot.height,
      );
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        paint,
      );
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        borderPaint,
      );
      
      // Draw point value
      final textPainter = TextPainter(
        text: TextSpan(
          text: slot.pointValue.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          slot.position.x - textPainter.width / 2,
          slot.position.y - textPainter.height / 2,
        ),
      );
      
      // Draw ball count if any
      if (slot.ballCount > 0) {
        final ballCountPainter = TextPainter(
          text: TextSpan(
            text: '×${slot.ballCount}',
            style: const TextStyle(
              color: Colors.yellow,
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
  }

  void _drawPegs(Canvas canvas, level) {
    for (final peg in level.pegs) {
      // Update peg animation
      peg.updateAnimation(1/60); // Assuming 60 FPS

      // Draw pulse glow effect (on hit)
      if (peg.pulseGlowRadius > 0.0) {
        final pulsePaint = Paint()
          ..color = peg.color.withOpacity(peg.pulseGlowOpacity)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(
          Offset(peg.position.x, peg.position.y),
          peg.pulseGlowRadius,
          pulsePaint,
        );
      }

      // Draw shimmer glow for special pegs
      if (peg.type == PegType.special && peg.isHighlighted && peg.shimmerIntensity > 0.0) {
        final shimmerPaint = Paint()
          ..color = GameConstants.specialPegColor.withOpacity(0.3 * peg.shimmerIntensity)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(
          Offset(peg.position.x, peg.position.y),
          peg.radius + (5 + 3 * peg.shimmerIntensity),
          shimmerPaint,
        );
      }

      // Draw peg body
      final paint = Paint()
        ..color = peg.renderColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(peg.position.x, peg.position.y),
        peg.radius,
        paint,
      );
    }
  }

  void _drawBalls(Canvas canvas, GameState gameState) {
    for (final ball in gameState.activeBalls) {
      if (!ball.isActive) continue;
      
      final paint = Paint()
        ..color = ball.color
        ..style = PaintingStyle.fill;
      
      final borderPaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      
      canvas.drawCircle(
        Offset(ball.position.x, ball.position.y),
        ball.radius,
        paint,
      );
      
      canvas.drawCircle(
        Offset(ball.position.x, ball.position.y),
        ball.radius,
        borderPaint,
      );
    }
  }

  void _drawLaunchChannel(Canvas canvas, level) {
    // Draw launch channel walls
    final wallPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    // Left wall of channel - lowered by 25 pixels total
    canvas.drawLine(
      Offset(GameConstants.launchChannelStartX, GameConstants.launchChannelStartY),
      Offset(GameConstants.launchChannelStartX, 135.0),  // Left side at y=135
      wallPaint,
    );
    
    // Right wall of channel - keeps original height
    canvas.drawLine(
      Offset(GameConstants.launchChannelStartX + GameConstants.launchChannelWidth, GameConstants.launchChannelStartY),
      Offset(GameConstants.launchChannelStartX + GameConstants.launchChannelWidth, GameConstants.launchChannelEndY),  // Right side at y=110
      wallPaint,
    );
    
    // Draw curved boundary at TOP of field - user's exact specification
    final curvePaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Top boundary: quadratic bezier from left to right
    const topBoundaryStartX = 30.0;
    const topBoundaryStartY = 110.0;  // Lowered to match left launch tube wall
    const topBoundaryControlX = 210.0;
    const topBoundaryControlY = -100.0; // Control point above screen for downward bow
    const topBoundaryEndX = 390.0;
    const topBoundaryEndY = 110.0;

    final boundaryPath = Path();
    boundaryPath.moveTo(topBoundaryStartX, topBoundaryStartY);
    boundaryPath.quadraticBezierTo(
      topBoundaryControlX, topBoundaryControlY,  // Control point
      topBoundaryEndX, topBoundaryEndY            // End point
    );
    canvas.drawPath(boundaryPath, curvePaint);

    // Left vertical FIELD barrier at x=30 (playfield boundary)
    canvas.drawLine(
      Offset(30.0, GameConstants.launchChannelStartY),
      Offset(30.0, 110.0),  // Ends at y=110, where top boundary starts
      curvePaint,
    );
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

  void _drawSpecialBonusEffect(Canvas canvas, Size size, double scale) {
    final paint = Paint()
      ..color = GameConstants.bonusBallColor.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(
      Rect.fromLTWH(0, 0, GameConstants.boardWidth, GameConstants.boardHeight),
      paint,
    );
    
    // Draw bonus text
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'SPECIAL BONUS!',
        style: TextStyle(
          color: GameConstants.bonusBallColor,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (GameConstants.boardWidth - textPainter.width) / 2,
        GameConstants.boardHeight / 2 - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}