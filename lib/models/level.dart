import 'dart:math';
import 'package:vector_math/vector_math_64.dart';
import 'peg.dart';
import 'slot.dart';
import '../utils/constants.dart';
import '../utils/peg_patterns.dart';

class Level {
  final int levelNumber;
  final String name;
  final List<Peg> pegs;
  final List<Slot> slots;
  final List<Peg> specialPegs;
  final double boardWidth;
  final double boardHeight;
  
  Level({
    required this.levelNumber,
    required this.name,
    required this.pegs,
    required this.slots,
    required this.specialPegs,
    this.boardWidth = 400.0,
    this.boardHeight = 600.0,
  });

  factory Level.generate(int levelNumber, double boardWidth, double boardHeight) {
    final random = Random(levelNumber); // Deterministic random for consistent levels
    final pegs = <Peg>[];
    final slots = <Slot>[];
    final specialPegs = <Peg>[];
    
    // Generate regular pegs using pattern-based approach
    final regularPegs = PegPatterns.getPatternForLevel(random, levelNumber, boardWidth, boardHeight);
    pegs.addAll(regularPegs);
    
    // Generate special pegs (2-4 per level) with proper spacing
    final specialPegCount = 2 + random.nextInt(3);
    const minSpacing = 35.0; // Base spacing for regular pegs
    const specialMinSpacing = 50.0; // Larger spacing for special pegs
    
    for (int i = 0; i < specialPegCount; i++) {
      double x = 0, y = 0;
      bool validPosition = false;
      int attempts = 0;
      
      // Try to find a valid position with proper spacing
      while (!validPosition && attempts < 50) {
        x = 80 + random.nextDouble() * (boardWidth - 160);
        y = 150 + random.nextDouble() * (boardHeight - 400);
        
        // Check if position is in launch channel area
        final inLaunchChannel = x > GameConstants.launchChannelStartX - 40 && 
                               y > GameConstants.launchChannelEndY && 
                               y < GameConstants.launchChannelStartY + 30;
        
        if (inLaunchChannel) {
          attempts++;
          continue;
        }
        
        // Check spacing with all existing pegs (regular and special)
        bool hasProperSpacing = true;
        for (final existingPeg in pegs) {
          final distance = (Vector2(x, y) - existingPeg.position).length;
          final requiredSpacing = existingPeg.type == PegType.special ? specialMinSpacing : minSpacing;
          if (distance < requiredSpacing) {
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
        final specialPeg = Peg(
          position: Vector2(x, y),
          radius: 15.0,
          type: PegType.special,
          isHighlighted: true,
        );
        pegs.add(specialPeg);
        specialPegs.add(specialPeg);
      }
    }
    
    // Generate slots with inverse probability distribution
    final slotCount = 7;
    final slotWidth = boardWidth / slotCount;
    
    for (int i = 0; i < slotCount; i++) {
      final x = slotWidth * i + slotWidth / 2;
      final y = boardHeight - 40;
      
      // Inverse probability distribution for scoring
      int points;
      if (i == 0 || i == slotCount - 1) {
        points = 2000; // High points at edges (low probability)
      } else if (i == slotCount ~/ 2) {
        points = 1000; // Medium-high points at center
      } else if (i == 1 || i == slotCount - 2) {
        points = 200; // Medium points
      } else {
        points = 50; // Low points at 1/3 and 2/3 positions (high probability)
      }
      
      final slot = Slot(
        position: Vector2(x, y),
        width: slotWidth - 4,
        height: 60,
        pointValue: points,
      );
      slots.add(slot);
    }
    
    return Level(
      levelNumber: levelNumber,
      name: 'Level $levelNumber',
      pegs: pegs,
      slots: slots,
      specialPegs: specialPegs,
      boardWidth: boardWidth,
      boardHeight: boardHeight,
    );
  }

  void reset() {
    for (final peg in pegs) {
      peg.reset();
    }
    for (final slot in slots) {
      slot.reset();
    }
  }

  bool get allSpecialPegsHit {
    return specialPegs.every((peg) => peg.hasBeenHit);
  }

  double get launchX => GameConstants.ballLaunchX;
  double get launchY => GameConstants.ballLaunchY;
}