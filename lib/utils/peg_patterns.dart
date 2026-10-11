import 'dart:math';
import 'package:vector_math/vector_math_64.dart';
import '../models/peg.dart';
import 'constants.dart';

class PegPatterns {
  /// Whether a ball can pass between a peg of [radius] at [position] and every
  /// peg in [pegs], and between it and the field walls.
  ///
  /// Every generator places pegs through this check. A gap narrower than a
  /// ball is a pocket: the ball comes to rest in it and the session soft-locks.
  static bool leavesRoomForBall(Iterable<Peg> pegs, Vector2 position, double radius) {
    const gap = GameConstants.minPegGap;
    if (position.x - radius - GameConstants.fieldLeftBoundaryX < gap) return false;
    if (GameConstants.fieldRightBoundaryX - position.x - radius < gap) return false;
    return pegs.every((peg) => gapTo(peg, position, radius) >= gap);
  }

  /// The gap, edge to edge, between [peg] and a peg of [radius] at [position].
  static double gapTo(Peg peg, Vector2 position, double radius) =>
      (position - peg.position).length - radius - peg.radius;

  static List<Peg> generateRandomPattern(Random random, int levelNumber, double boardWidth, double boardHeight) {
    final pegs = <Peg>[];
    final pegCount = 30 + (levelNumber * 3);

    for (int i = 0; i < pegCount; i++) {
      double x = 0, y = 0;
      final pegRadius = 8.0 + random.nextDouble() * 4.0;
      bool validPosition = false;
      int attempts = 0;

      while (!validPosition && attempts < 50) {
        x = 60 + random.nextDouble() * (boardWidth - 120);
        y = 120 + random.nextDouble() * (boardHeight - 320);
        
        // Check launch channel
        final inLaunchChannel = x > GameConstants.launchChannelStartX - 30 && 
                               y > GameConstants.launchChannelEndY && 
                               y < GameConstants.launchChannelStartY + 30;
        
        if (inLaunchChannel) {
          attempts++;
          continue;
        }
        
        validPosition = leavesRoomForBall(pegs, Vector2(x, y), pegRadius);
        attempts++;
      }

      if (validPosition) {
        final peg = Peg(
          position: Vector2(x, y),
          radius: pegRadius,
        );
        pegs.add(peg);
      }
    }
    
    return pegs;
  }

  static List<Peg> generateHexagonalPattern(Random random, int levelNumber, double boardWidth, double boardHeight) {
    final pegs = <Peg>[];
    const baseSpacing = 45.0;
    const rowOffset = 38.0;
    const hexSpacing = baseSpacing;
    
    final startY = 140.0;
    final endY = boardHeight - 200;
    final rows = ((endY - startY) / rowOffset).floor();
    
    for (int row = 0; row < rows; row++) {
      final y = startY + (row * rowOffset);
      final isEvenRow = row % 2 == 0;
      final xOffset = isEvenRow ? 0.0 : hexSpacing / 2;
      
      final startX = 80.0 + xOffset;
      final endX = boardWidth - 80.0;
      final pegsInRow = ((endX - startX) / hexSpacing).floor();
      
      for (int col = 0; col < pegsInRow; col++) {
        final x = startX + (col * hexSpacing);
        
        // Check launch channel
        final inLaunchChannel = x > GameConstants.launchChannelStartX - 30 && 
                               y > GameConstants.launchChannelEndY && 
                               y < GameConstants.launchChannelStartY + 30;
        
        if (!inLaunchChannel) {
          _addJitteredPeg(pegs, random, x, y, 10);
        }
      }
    }
    
    return pegs;
  }

  static List<Peg> generateTrianglePattern(Random random, int levelNumber, double boardWidth, double boardHeight) {
    final pegs = <Peg>[];
    const spacing = 50.0;
    final startY = 150.0;
    final endY = boardHeight - 220;
    final centerX = boardWidth / 2;
    
    int row = 0;
    double currentY = startY;
    
    while (currentY < endY) {
      final pegsInRow = row + 3; // Start with 3 pegs, increase each row
      final totalWidth = (pegsInRow - 1) * spacing;
      final startX = centerX - totalWidth / 2;
      
      for (int i = 0; i < pegsInRow; i++) {
        final x = startX + (i * spacing);
        
        // Check bounds and launch channel
        if (x > 60 && x < boardWidth - 60) {
          final inLaunchChannel = x > GameConstants.launchChannelStartX - 30 && 
                                 currentY > GameConstants.launchChannelEndY && 
                                 currentY < GameConstants.launchChannelStartY + 30;
          
          if (!inLaunchChannel) {
            _addJitteredPeg(pegs, random, x, currentY, 8);
          }
        }
      }
      
      row++;
      currentY += spacing * 0.8; // Slightly tighter vertical spacing
    }
    
    return pegs;
  }

  /// Adds a peg near grid point ([x], [y]), moved by up to half of [jitter] on
  /// each axis so the grid does not look perfect. The offset is drawn again if
  /// it would close a gap, and the peg is left out if no draw fits.
  static void _addJitteredPeg(List<Peg> pegs, Random random, double x, double y, double jitter) {
    for (int attempt = 0; attempt < 10; attempt++) {
      final position = Vector2(
        x + (random.nextDouble() - 0.5) * jitter,
        y + (random.nextDouble() - 0.5) * jitter,
      );
      final pegRadius = 9.0 + random.nextDouble() * 2.0;
      if (leavesRoomForBall(pegs, position, pegRadius)) {
        pegs.add(Peg(position: position, radius: pegRadius));
        return;
      }
    }
  }

  static List<Peg> getPatternForLevel(Random random, int levelNumber, double boardWidth, double boardHeight) {
    // Use different patterns for different level ranges
    switch (levelNumber % 3) {
      case 0:
        return generateHexagonalPattern(random, levelNumber, boardWidth, boardHeight);
      case 1:
        return generateTrianglePattern(random, levelNumber, boardWidth, boardHeight);
      default:
        return generateRandomPattern(random, levelNumber, boardWidth, boardHeight);
    }
  }
}