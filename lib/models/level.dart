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

  factory Level.generate(
      int levelNumber, double boardWidth, double boardHeight) {
    final random =
        Random(levelNumber); // Deterministic random for consistent levels
    final pegs = <Peg>[];
    final slots = <Slot>[];
    final specialPegs = <Peg>[];

    // Generate regular pegs using pattern-based approach
    final regularPegs = PegPatterns.getPatternForLevel(
        random, levelNumber, boardWidth, boardHeight);
    pegs.addAll(regularPegs);

    // Generate special pegs (2-4 per level) with proper spacing
    final specialPegCount = 2 + random.nextInt(3);
    // Centre to centre, between special pegs. It leaves a 20 px gap, which is
    // more than minPegGap, so making room for one never removes another.
    const specialMinSpacing = 50.0;

    for (int i = 0; i < specialPegCount; i++) {
      Vector2? position;
      Vector2?
          crowdedSpot; // The candidate with the fewest regular pegs in its way
      int fewestInTheWay = pegs.length + 1;

      // Try to find a valid position with proper spacing
      for (int attempts = 0; position == null && attempts < 50; attempts++) {
        final x = 80 + random.nextDouble() * (boardWidth - 160);
        final y = 150 + random.nextDouble() * (boardHeight - 400);

        final candidate = Vector2(x, y);
        // Field walls only, which also keeps it out of the launch channel beyond
        // the right wall; the pegs in the way are counted below
        if (!PegPatterns.leavesRoomForBall(
            const [], candidate, GameConstants.specialPegRadius)) {
          continue;
        }
        if (specialPegs.any(
            (peg) => (candidate - peg.position).length < specialMinSpacing)) {
          continue;
        }

        // A ball must fit past every peg
        final inTheWay = pegs
            .where((peg) =>
                PegPatterns.gapTo(
                    peg, candidate, GameConstants.specialPegRadius) <
                GameConstants.minPegGap)
            .length;
        if (inTheWay == 0) {
          position = candidate;
        } else if (inTheWay < fewestInTheWay) {
          fewestInTheWay = inTheWay;
          crowdedSpot = candidate;
        }
      }

      if (position == null && crowdedSpot != null) {
        // A dense field has no free spot. Clear the regular pegs around the
        // least crowded candidate, so every level keeps its special pegs and its bonus.
        final spot = crowdedSpot;
        pegs.removeWhere((peg) =>
            PegPatterns.gapTo(peg, spot, GameConstants.specialPegRadius) <
            GameConstants.minPegGap);
        position = spot;
      }

      if (position != null) {
        final specialPeg = Peg(
          position: position,
          radius: GameConstants.specialPegRadius,
          type: PegType.special,
          isHighlighted: true,
        );
        pegs.add(specialPeg);
        specialPegs.add(specialPeg);
      }
    }

    // Generate slots with inverse probability distribution
    const slotCount = 7;
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
