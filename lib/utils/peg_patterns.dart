import 'dart:math';
import 'package:vector_math/vector_math_64.dart';
import '../models/peg.dart';
import 'constants.dart';

class PegPatterns {
  static List<Peg> generateRandomPattern(Random random, int levelNumber, double boardWidth, double boardHeight) {
    final pegs = <Peg>[];
    final pegCount = 30 + (levelNumber * 3);
    const minSpacing = 35.0;
    
    for (int i = 0; i < pegCount; i++) {
      double x = 0, y = 0;
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
        
        // Check spacing
        bool hasProperSpacing = true;
        for (final existingPeg in pegs) {
          final distance = (Vector2(x, y) - existingPeg.position).length;
          if (distance < minSpacing) {
            hasProperSpacing = false;
            break;
          }
        }
        
        if (hasProperSpacing) {
          validPosition = true;
        }
        attempts++;
      }
      
      if (validPosition) {
        final pegRadius = 8.0 + random.nextDouble() * 4.0;
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
          // Add some randomness to prevent perfect grid
          final offsetX = x + (random.nextDouble() - 0.5) * 10;
          final offsetY = y + (random.nextDouble() - 0.5) * 10;
          
          final pegRadius = 9.0 + random.nextDouble() * 2.0;
          final peg = Peg(
            position: Vector2(offsetX, offsetY),
            radius: pegRadius,
          );
          pegs.add(peg);
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
            // Add slight randomness
            final offsetX = x + (random.nextDouble() - 0.5) * 8;
            final offsetY = currentY + (random.nextDouble() - 0.5) * 8;
            
            final pegRadius = 9.0 + random.nextDouble() * 2.0;
            final peg = Peg(
              position: Vector2(offsetX, offsetY),
              radius: pegRadius,
            );
            pegs.add(peg);
          }
        }
      }
      
      row++;
      currentY += spacing * 0.8; // Slightly tighter vertical spacing
    }
    
    return pegs;
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