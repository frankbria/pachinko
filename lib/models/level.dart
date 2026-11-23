import 'dart:math';
import 'package:vector_math/vector_math_64.dart';
import 'board_feature.dart';
import 'peg.dart';
import 'slot.dart';
import '../utils/constants.dart';
import '../utils/peg_patterns.dart';

/// A random shift of a prize peg from its place in the column.
double _jitter(Random random) =>
    (random.nextDouble() * 2 - 1) * GameConstants.prizeColumnJitter;

class Level {
  final int levelNumber;
  final String name;
  final List<Peg> pegs;
  final List<Slot> slots;
  final List<Peg> specialPegs;

  /// The level's tulips, windmill and centre gate, as
  /// [featureKindsFor] gives them.
  final List<BoardFeature> features;
  final double boardWidth;
  final double boardHeight;

  Level({
    required this.levelNumber,
    required this.name,
    required this.pegs,
    required this.slots,
    required this.specialPegs,
    this.features = const [],
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

    // Generate slots with inverse probability distribution
    // The row lies between the field walls, so that every slot is inside
    // the playfield and what is drawn is what a ball can reach
    const slotCount = 7;
    const rowLeft = GameConstants.fieldLeftBoundaryX;
    const rowRight = GameConstants.fieldRightBoundaryX;
    const edgeWidth = GameConstants.edgeSlotWidth;
    const innerWidth = (rowRight - rowLeft - 2 * edgeWidth) / (slotCount - 2);
    double slotLeft = rowLeft;

    for (int i = 0; i < slotCount; i++) {
      final slotWidth = i == 0 || i == slotCount - 1 ? edgeWidth : innerWidth;
      final x = slotLeft + slotWidth / 2;
      slotLeft += slotWidth;
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

    final features = _placeFeatures(featureKindsFor(levelNumber), pegs, slots);
    final columnStep = prizeColumnStepFor(levelNumber,
        centreGate: features.any((feature) => feature is CentreGate));
    final columnSway = prizeColumnSwayFor(levelNumber);

    // The prize pegs, down their zigzag column, spaced apart
    const specialPegCount = GameConstants.prizePegsPerLevel;
    // Centre to centre, between special pegs. It leaves a 20 px gap, which is
    // more than minPegGap, so making room for one never removes another.
    const specialMinSpacing = 50.0;

    for (int i = 0; i < specialPegCount; i++) {
      Vector2? position;
      Vector2?
          crowdedSpot; // The candidate with the fewest regular pegs in its way
      int fewestInTheWay = pegs.length + 1;

      // Try to find a valid position with proper spacing
      for (int attempts = 0; position == null && attempts < 200; attempts++) {
        final sway = i.isEven ? -columnSway : columnSway;
        final x = GameConstants.prizeColumnX + sway + _jitter(random);
        final y =
            GameConstants.prizeColumnTopY + i * columnStep + _jitter(random);

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
        if (!_clearOfFeatures(
            features, candidate, GameConstants.specialPegRadius)) {
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

    return Level(
      levelNumber: levelNumber,
      name: 'Level $levelNumber',
      pegs: pegs,
      slots: slots,
      specialPegs: specialPegs,
      features: features,
      boardWidth: boardWidth,
      boardHeight: boardHeight,
    );
  }

  /// How far apart the prize pegs on level [levelNumber] stand, down the
  /// column: further on later levels (#115). On a level with the centre gate
  /// the step stays [GameConstants.centreGateColumnStep], so that the lowest
  /// prize peg leaves a ball room past the gate.
  static double prizeColumnStepFor(int levelNumber,
          {required bool centreGate}) =>
      centreGate
          ? GameConstants.centreGateColumnStep
          : GameConstants.alongDifficulty(
              levelNumber,
              GameConstants.prizeColumnStep,
              GameConstants.prizeColumnStepHardest);

  /// How far either side of the middle the prize pegs on level
  /// [levelNumber] stand: further on later levels (#115).
  static double prizeColumnSwayFor(int levelNumber) =>
      GameConstants.alongDifficulty(levelNumber, GameConstants.prizeColumnSway,
          GameConstants.prizeColumnSwayHardest);

  /// Which features level [levelNumber] has. The first two levels have
  /// none, so the first round teaches the pins and slots alone; tulips come
  /// on odd levels from 3 and on every level after 20, a windmill on even
  /// levels from 4, and the centre gate on every fifth level, the last of
  /// each band.
  static Set<FeatureKind> featureKindsFor(int levelNumber) => {
        if (levelNumber >= 3 && (levelNumber.isOdd || levelNumber > 20))
          FeatureKind.tulips,
        if (levelNumber >= 4 && levelNumber.isEven) FeatureKind.windmill,
        if (levelNumber >= 5 && levelNumber % 5 == 0) FeatureKind.centreGate,
      };

  /// Places the features of [kinds], taking out the regular pegs in their
  /// way, and adds each tulip's trigger pin to [pegs]. The centre gate stands
  /// over the middle slot of [slots].
  static List<BoardFeature> _placeFeatures(
      Set<FeatureKind> kinds, List<Peg> pegs, List<Slot> slots) {
    final features = <BoardFeature>[];
    if (kinds.contains(FeatureKind.tulips)) {
      for (final (x, outwards) in const [
        (GameConstants.tulipLeftX, -1.0),
        (GameConstants.tulipRightX, 1.0),
      ]) {
        final position = Vector2(x, GameConstants.tulipY);
        final trigger = Peg(
          position: position +
              Vector2(outwards * GameConstants.tulipTriggerOffsetX,
                  -GameConstants.tulipTriggerRise),
          radius: GameConstants.tulipTriggerRadius,
        );
        _makeRoom(pegs, position, GameConstants.tulipRadius);
        _makeRoom(pegs, trigger.position, trigger.radius);
        pegs.add(trigger);
        features.add(Tulip(position: position, triggerPin: trigger));
      }
    }
    if (kinds.contains(FeatureKind.windmill)) {
      final windmill = Windmill(
          pivot: Vector2(GameConstants.windmillX, GameConstants.windmillY));
      _makeRoom(pegs, windmill.centre, windmill.reach);
      features.add(windmill);
    }
    if (kinds.contains(FeatureKind.centreGate)) {
      final gate = CentreGate(
          pivot: Vector2(
              slots[slots.length ~/ 2].position.x, GameConstants.centreGateY));
      _makeRoom(pegs, gate.centre, gate.reach);
      features.add(gate);
    }
    return features;
  }

  /// Takes out of [pegs] every peg that would leave less than a ball's room
  /// between it and a circle of [radius] at [centre].
  static void _makeRoom(List<Peg> pegs, Vector2 centre, double radius) =>
      pegs.removeWhere((peg) =>
          PegPatterns.gapTo(peg, centre, radius) < GameConstants.minPegGap);

  /// Whether a peg of [radius] at [position] leaves a ball room past every
  /// one of [features], at any position the feature moves through.
  static bool _clearOfFeatures(
          List<BoardFeature> features, Vector2 position, double radius) =>
      features.every((feature) =>
          (position - feature.centre).length - radius - feature.reach >=
          GameConstants.minPegGap);

  /// The level's tulips.
  Iterable<Tulip> get tulips => features.whereType<Tulip>();

  void reset() {
    for (final peg in pegs) {
      peg.reset();
    }
    for (final feature in features) {
      feature.reset();
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
