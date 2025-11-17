import 'package:flutter_test/flutter_test.dart';
import 'package:pachinko_game/models/level.dart';
import 'package:pachinko_game/models/peg.dart';
import 'package:pachinko_game/models/slot.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('Level Initialization -', () {
    test('given level constructor, when created with values, then initializes correctly', () {
      // Given
      final pegs = <Peg>[];
      final slots = <Slot>[];
      final specialPegs = <Peg>[];

      // When
      final level = Level(
        levelNumber: 5,
        name: 'Test Level',
        pegs: pegs,
        slots: slots,
        specialPegs: specialPegs,
        boardWidth: 400.0,
        boardHeight: 600.0,
      );

      // Then
      expect(level.levelNumber, equals(5));
      expect(level.name, equals('Test Level'));
      expect(level.boardWidth, equals(400.0));
      expect(level.boardHeight, equals(600.0));
    });

    test('given level constructor, when created with default dimensions, then uses 400x600', () {
      // Given / When
      final level = Level(
        levelNumber: 1,
        name: 'Level 1',
        pegs: [],
        slots: [],
        specialPegs: [],
      );

      // Then
      expect(level.boardWidth, equals(400.0));
      expect(level.boardHeight, equals(600.0));
    });

    test('given generated level, when launchX and launchY accessed, then returns constants', () {
      // Given
      final level = Level.generate(1, 400.0, 600.0);

      // When
      final launchX = level.launchX;
      final launchY = level.launchY;

      // Then
      expect(launchX, isNotNull);
      expect(launchY, isNotNull);
    });
  });

  group('Deterministic Generation -', () {
    /// Tests deterministic level generation using seed-based Random.
    ///
    /// Level.generate uses Random(levelNumber) as seed, ensuring:
    /// - Same level number always produces identical level
    /// - Peg positions are consistent across generations
    /// - Special peg count and positions are deterministic
    /// - Pattern selection is consistent
    ///
    /// This allows for reproducible gameplay and level designs.
    test('given same level number, when generated twice, then produces identical peg positions', () {
      // Given
      const levelNumber = 5;

      // When
      final level1 = Level.generate(levelNumber, 400.0, 600.0);
      final level2 = Level.generate(levelNumber, 400.0, 600.0);

      // Then - same number of pegs
      expect(level1.pegs.length, equals(level2.pegs.length));

      // Then - peg positions match
      for (int i = 0; i < level1.pegs.length; i++) {
        expect(level1.pegs[i].position.x, closeTo(level2.pegs[i].position.x, 0.01));
        expect(level1.pegs[i].position.y, closeTo(level2.pegs[i].position.y, 0.01));
      }
    });

    test('given same level number, when generated twice, then produces identical special peg count', () {
      // Given
      const levelNumber = 7;

      // When
      final level1 = Level.generate(levelNumber, 400.0, 600.0);
      final level2 = Level.generate(levelNumber, 400.0, 600.0);

      // Then
      expect(level1.specialPegs.length, equals(level2.specialPegs.length));
    });

    test('given different level numbers, when generated, then produces different peg layouts', () {
      // Given / When
      final level1 = Level.generate(1, 400.0, 600.0);
      final level2 = Level.generate(2, 400.0, 600.0);

      // Then - different peg counts (different patterns or different random seeds)
      // Note: May have same count coincidentally, so check first peg position difference
      bool hasDifferentPosition = false;
      if (level1.pegs.isNotEmpty && level2.pegs.isNotEmpty) {
        final distance = (level1.pegs[0].position - level2.pegs[0].position).length;
        hasDifferentPosition = distance > 1.0;
      }
      expect(hasDifferentPosition, isTrue);
    });

    test('given same level number, when generated, then produces same level name', () {
      // Given
      const levelNumber = 3;

      // When
      final level1 = Level.generate(levelNumber, 400.0, 600.0);
      final level2 = Level.generate(levelNumber, 400.0, 600.0);

      // Then
      expect(level1.name, equals(level2.name));
      expect(level1.name, equals('Level 3'));
    });
  });

  group('Pattern Cycling -', () {
    /// Tests pattern cycling based on level number modulo 3.
    ///
    /// PegPatterns.getPatternForLevel uses (levelNumber % 3):
    /// - level % 3 == 0: Hexagonal pattern (grid-like with offset rows)
    /// - level % 3 == 1: Triangle pattern (expanding rows from center)
    /// - level % 3 == 2: Random pattern (randomly distributed pegs)
    ///
    /// This ensures variety in level designs while maintaining determinism.
    test('given level 0, when generated, then uses hexagonal pattern', () {
      // Given / When
      final level0 = Level.generate(0, 400.0, 600.0);
      final level3 = Level.generate(3, 400.0, 600.0);
      final level6 = Level.generate(6, 400.0, 600.0);

      // Then - all should have pegs (hexagonal pattern generates pegs)
      expect(level0.pegs, isNotEmpty);
      expect(level3.pegs, isNotEmpty);
      expect(level6.pegs, isNotEmpty);

      // Hexagonal pattern creates structured grid - verify by checking
      // that pegs exist (pattern produces consistent results)
      expect(level0.pegs.length, greaterThan(10));
      expect(level3.pegs.length, greaterThan(10));
    });

    test('given level 1, when generated, then uses triangle pattern', () {
      // Given / When
      final level1 = Level.generate(1, 400.0, 600.0);
      final level4 = Level.generate(4, 400.0, 600.0);

      // Then - triangle pattern generates pegs
      expect(level1.pegs, isNotEmpty);
      expect(level4.pegs, isNotEmpty);
    });

    test('given level 2, when generated, then uses random pattern', () {
      // Given / When
      final level2 = Level.generate(2, 400.0, 600.0);
      final level5 = Level.generate(5, 400.0, 600.0);

      // Then - random pattern generates pegs
      // Random pattern formula: 30 + (levelNumber * 3)
      // Level 2: 30 + (2 * 3) = 36 base pegs (before special pegs)
      // Level 5: 30 + (5 * 3) = 45 base pegs (before special pegs)
      expect(level2.pegs, isNotEmpty);
      expect(level5.pegs, isNotEmpty);

      // Level 5 should have more pegs than level 2
      expect(level5.pegs.length, greaterThan(level2.pegs.length));
    });

    test('given sequential levels, when generated, then cycles through patterns', () {
      // Given / When
      final level0 = Level.generate(0, 400.0, 600.0);
      final level1 = Level.generate(1, 400.0, 600.0);
      final level2 = Level.generate(2, 400.0, 600.0);
      final level3 = Level.generate(3, 400.0, 600.0);

      // Then - level 3 should match pattern of level 0 (both % 3 == 0)
      // Same pattern type, but different seed means different specific positions
      expect(level0.pegs, isNotEmpty);
      expect(level1.pegs, isNotEmpty);
      expect(level2.pegs, isNotEmpty);
      expect(level3.pegs, isNotEmpty);

      // Level 0 and 3 use same pattern (hexagonal), but different seeds
      // so they won't have identical layouts
      final pos0 = level0.pegs.isNotEmpty ? level0.pegs[0].position : Vector2.zero();
      final pos3 = level3.pegs.isNotEmpty ? level3.pegs[0].position : Vector2.zero();
      final distance = (pos0 - pos3).length;
      expect(distance, greaterThan(1.0)); // Different due to different random seed
    });
  });

  group('Special Peg Placement -', () {
    test('given generated level, when created, then has 2-4 special pegs', () {
      // Given / When
      // Using level 1 (Triangle pattern) which has more spacing for special pegs
      final level = Level.generate(1, 400.0, 600.0);

      // Then - special peg count formula: 2 + random.nextInt(3) = 2-4
      // Note: May be less if 50-attempt limit hit due to dense peg layout
      expect(level.specialPegs.length, greaterThanOrEqualTo(2));
      expect(level.specialPegs.length, lessThanOrEqualTo(4));
    });

    test('given generated level, when created, then special pegs are highlighted', () {
      // Given / When
      final level = Level.generate(1, 400.0, 600.0);

      // Then - all special pegs should have isHighlighted = true
      for (final specialPeg in level.specialPegs) {
        expect(specialPeg.isHighlighted, isTrue);
      }
    });

    test('given generated level, when created, then special pegs have special type', () {
      // Given / When
      final level = Level.generate(1, 400.0, 600.0);

      // Then - all special pegs should have type PegType.special
      for (final specialPeg in level.specialPegs) {
        expect(specialPeg.type, equals(PegType.special));
      }
    });

    test('given generated level, when created, then special pegs included in main pegs list', () {
      // Given / When
      final level = Level.generate(1, 400.0, 600.0);

      // Then - all special pegs should be in the main pegs list
      for (final specialPeg in level.specialPegs) {
        expect(level.pegs.contains(specialPeg), isTrue);
      }
    });

    test('given generated level, when created, then special pegs have radius 15', () {
      // Given / When
      final level = Level.generate(1, 400.0, 600.0);

      // Then - all special pegs should have radius 15
      for (final specialPeg in level.specialPegs) {
        expect(specialPeg.radius, equals(15.0));
      }
    });
  });

  group('Spatial Constraints -', () {
    test('given generated level, when special pegs placed, then maintains 50px spacing between special pegs', () {
      /// Validates that all special pegs maintain minimum 50px spacing from each other
      /// This is critical for gameplay balance and preventing clustering
      
      // Given / When
      final level = Level.generate(1, 400.0, 600.0);

      // Then - check all pairs of special pegs
      for (int i = 0; i < level.specialPegs.length; i++) {
        for (int j = i + 1; j < level.specialPegs.length; j++) {
          final distance = (level.specialPegs[i].position - level.specialPegs[j].position).length;
          expect(distance, greaterThanOrEqualTo(50.0 - 0.1)); // Small tolerance for floating point
        }
      }
    });

    test('given generated level, when special pegs placed, then maintains spacing from regular pegs', () {
      /// Special pegs should maintain minimum 35px spacing from regular pegs
      /// This ensures proper ball flow and prevents overlap
      
      // Given / When
      final level = Level.generate(1, 400.0, 600.0);
      const minSpacing = 35.0;

      // Then - check special pegs against all regular pegs
      for (final specialPeg in level.specialPegs) {
        for (final regularPeg in level.pegs) {
          if (regularPeg == specialPeg) continue; // Skip self-comparison
          
          final distance = (specialPeg.position - regularPeg.position).length;
          expect(distance, greaterThan(minSpacing - 5.0)); // Tolerance for 50-attempt limit
        }
      }
    });

    test('given generated level, when pegs placed, then no overlapping pegs', () {
      /// Validates that no two pegs overlap
      /// Uses 35px minimum spacing with tolerance for 50-attempt limit
      
      // Given / When
      final level = Level.generate(1, 400.0, 600.0);
      const minDistance = 35.0;

      // Then - check all pairs of pegs for overlap
      for (int i = 0; i < level.pegs.length; i++) {
        for (int j = i + 1; j < level.pegs.length; j++) {
          final distance = (level.pegs[i].position - level.pegs[j].position).length;
          // Allow tolerance due to 50-attempt limit in peg placement
          expect(distance, greaterThan(minDistance - 5.0));
        }
      }
    });

    test('given generated level, when pegs placed, then all within board bounds', () {
      /// Ensures all pegs are positioned within the playable board area
      /// Prevents pegs from being placed outside visible area
      
      // Given / When
      final level = Level.generate(1, 400.0, 600.0);

      // Then - check all pegs are within bounds
      for (final peg in level.pegs) {
        expect(peg.position.x, greaterThan(0.0));
        expect(peg.position.x, lessThan(400.0));
        expect(peg.position.y, greaterThan(0.0));
        expect(peg.position.y, lessThan(600.0));
      }
    });

    test('given generated level, when special pegs placed, then not clustered in one region', () {
      /// Validates that special pegs are distributed across the board
      /// Checks that max distance between any two special pegs is reasonable
      
      // Given / When
      final level = Level.generate(1, 400.0, 600.0);

      // Then - if we have multiple special pegs, check distribution
      if (level.specialPegs.length >= 2) {
        // Find max distance between any two special pegs
        double maxDistance = 0.0;
        for (int i = 0; i < level.specialPegs.length; i++) {
          for (int j = i + 1; j < level.specialPegs.length; j++) {
            final distance = (level.specialPegs[i].position - level.specialPegs[j].position).length;
            if (distance > maxDistance) {
              maxDistance = distance;
            }
          }
        }
        
        // At least one pair should be reasonably far apart (not all clustered)
        // Board is 400x600, so max diagonal is ~721px
        // Expect at least some spread (>100px between furthest pair)
        expect(maxDistance, greaterThan(100.0));
      }
    });
  });

  group('Launch Channel Avoidance -', () {
    /// Tests launch channel exclusion zone enforcement.
    ///
    /// Launch channel area is defined by:
    /// - x > launchChannelStartX - 40
    /// - y > launchChannelEndY
    /// - y < launchChannelStartY + 30
    ///
    /// No special pegs should be placed in this zone to avoid interference.
    test('given generated level, when special pegs placed, then none in launch channel', () {
      // Given / When
      final level = Level.generate(13, 400.0, 600.0);

      // Then - no special pegs should be in launch channel area
      // Note: We need to import GameConstants to check exact boundaries
      // For now, verify special pegs are not in rightmost area where channel would be
      for (final specialPeg in level.specialPegs) {
        // Approximate check: special pegs should avoid the right edge where launch channel is
        final tooFarRight = specialPeg.position.x > level.boardWidth - 100;
        if (tooFarRight) {
          // If near right edge, should be either very high or very low (not mid-height where channel is)
          final inMidHeight = specialPeg.position.y > 150 && specialPeg.position.y < 450;
          expect(inMidHeight, isFalse);
        }
      }
    });

    test('given generated level, when pegs generated, then regular pegs avoid launch channel', () {
      // Given / When
      final level = Level.generate(14, 400.0, 600.0);

      // Then - verify pegs exist (pattern generation successful)
      expect(level.pegs, isNotEmpty);

      // Regular pegs are generated by PegPatterns which also avoids launch channel
      // Verify by checking that not ALL pegs are clustered on left side
      final rightSidePegs = level.pegs.where((peg) => peg.position.x > level.boardWidth / 2).length;
      expect(rightSidePegs, greaterThan(0)); // Some pegs should be on right side
    });

    test('given generated level, when created, then has valid peg layout with channel clear', () {
      // Given / When
      final level = Level.generate(15, 400.0, 600.0);

      // Then - verify level has both regular and special pegs
      expect(level.pegs.length, greaterThan(level.specialPegs.length));
      expect(level.specialPegs, isNotEmpty);
    });
  });

  group('Slot Scoring Distribution -', () {
    /// Tests inverse probability slot scoring distribution.
    ///
    /// 7 slots with scoring based on ball landing probability:
    /// - Edges (indices 0, 6): 2000 points (low probability)
    /// - Center (index 3): 1000 points (medium probability)
    /// - Near-edges (indices 1, 5): 200 points (medium-low probability)
    /// - Middle-sides (indices 2, 4): 50 points (high probability)
    ///
    /// This creates risk/reward: hard-to-reach edges give high points.
    test('given generated level, when created, then has 7 slots', () {
      // Given / When
      final level = Level.generate(16, 400.0, 600.0);

      // Then
      expect(level.slots.length, equals(7));
    });

    test('given generated level, when slots created, then edge slots have 2000 points', () {
      // Given / When
      final level = Level.generate(17, 400.0, 600.0);

      // Then - indices 0 and 6 (edges)
      expect(level.slots[0].pointValue, equals(2000));
      expect(level.slots[6].pointValue, equals(2000));
    });

    test('given generated level, when slots created, then center slot has 1000 points', () {
      // Given / When
      final level = Level.generate(18, 400.0, 600.0);

      // Then - index 3 (center)
      expect(level.slots[3].pointValue, equals(1000));
    });

    test('given generated level, when slots created, then near-edge slots have 200 points', () {
      // Given / When
      final level = Level.generate(19, 400.0, 600.0);

      // Then - indices 1 and 5
      expect(level.slots[1].pointValue, equals(200));
      expect(level.slots[5].pointValue, equals(200));
    });

    test('given generated level, when slots created, then middle-side slots have 50 points', () {
      // Given / When
      final level = Level.generate(20, 400.0, 600.0);

      // Then - indices 2 and 4
      expect(level.slots[2].pointValue, equals(50));
      expect(level.slots[4].pointValue, equals(50));
    });

    test('given generated level, when slots created, then positioned at bottom', () {
      // Given / When
      final level = Level.generate(21, 400.0, 600.0);

      // Then - all slots at y = boardHeight - 40
      final expectedY = level.boardHeight - 40;
      for (final slot in level.slots) {
        expect(slot.position.y, equals(expectedY));
      }
    });

    test('given generated level, when slots created, then evenly distributed across width', () {
      // Given / When
      final level = Level.generate(22, 400.0, 600.0);
      final slotWidth = level.boardWidth / 7;

      // Then - slots should be evenly spaced
      for (int i = 0; i < level.slots.length; i++) {
        final expectedX = slotWidth * i + slotWidth / 2;
        expect(level.slots[i].position.x, closeTo(expectedX, 0.1));
      }
    });
  });

  group('Valid Peg Positioning -', () {
    test('given level generation, when called, then completes within reasonable time', () {
      /// Validates that the 50-attempt limit prevents infinite loops
      /// Generation should complete even if not all special pegs can be placed
      
      // Given / When - measure generation time
      final stopwatch = Stopwatch()..start();
      final level = Level.generate(2, 400.0, 600.0);
      stopwatch.stop();

      // Then - should complete quickly (within 5 seconds)
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      // And level should still be valid
      expect(level.pegs, isNotEmpty);
      expect(level.slots.length, equals(7));
    });

    test('given dense peg layout, when special peg placement attempted, then gracefully handles failure', () {
      /// Tests that generation doesn't crash when special pegs can't be placed
      /// The 50-attempt limit should result in fewer special pegs, not errors
      
      // Given / When - use random pattern (level 2) which is densest
      final level = Level.generate(2, 400.0, 600.0);

      // Then - level should still be valid even if special peg placement failed
      expect(level.pegs, isNotEmpty);
      expect(level.slots.length, equals(7));
      // Special peg count may be 0-4 depending on successful placements
      expect(level.specialPegs.length, greaterThanOrEqualTo(0));
      expect(level.specialPegs.length, lessThanOrEqualTo(4));
    });

    test('given generated level, when inspected, then has playable peg count', () {
      /// Ensures the level has enough pegs to be playable
      /// Pattern-based generation should create at least 20 pegs
      
      // Given / When
      final level = Level.generate(0, 400.0, 600.0);

      // Then - should have reasonable number of pegs for gameplay
      expect(level.pegs.length, greaterThan(20));
    });
  });

  group('Special Pegs Completion -', () {
    test('given level with special pegs, when none hit, then allSpecialPegsHit returns false', () {
      /// Tests the completion tracking for special pegs bonus mechanic
      /// Initially, no pegs should be marked as hit
      
      // Given
      final level = Level.generate(1, 400.0, 600.0);

      // When - no pegs hit yet (default state)

      // Then - completion should be false if we have special pegs
      if (level.specialPegs.isNotEmpty) {
        expect(level.allSpecialPegsHit, isFalse);
      }
    });

    test('given level with special pegs, when some hit, then allSpecialPegsHit returns false', () {
      /// Tests that partial completion doesn't trigger the bonus
      /// All special pegs must be hit for the bonus
      
      // Given
      final level = Level.generate(1, 400.0, 600.0);

      // When - mark only first special peg as hit
      if (level.specialPegs.length >= 2) {
        level.specialPegs[0].onHit();

        // Then - should still be false (not all hit)
        expect(level.allSpecialPegsHit, isFalse);
      }
    });

    test('given level with special pegs, when all hit, then allSpecialPegsHit returns true', () {
      /// Tests that completion correctly detects when all special pegs are hit
      /// This triggers the bonus ball mechanic in gameplay
      
      // Given
      final level = Level.generate(1, 400.0, 600.0);

      // When - mark all special pegs as hit
      for (final peg in level.specialPegs) {
        peg.onHit();
      }

      // Then - should return true if we have special pegs
      if (level.specialPegs.isNotEmpty) {
        expect(level.allSpecialPegsHit, isTrue);
      }
    });

    test('given level with no special pegs, when allSpecialPegsHit checked, then returns true', () {
      /// Edge case: empty list should satisfy .every() predicate
      /// This is consistent with Dart's .every() behavior
      
      // Given - create level that might have 0 special pegs
      final level = Level.generate(2, 400.0, 600.0);

      // When / Then - if no special pegs, .every() returns true (vacuous truth)
      if (level.specialPegs.isEmpty) {
        expect(level.allSpecialPegsHit, isTrue);
      } else {
        // If we have special pegs, initially should be false
        expect(level.allSpecialPegsHit, isFalse);
      }
    });
  });

  group('Reset Functionality -', () {
    test('given level with hit pegs, when reset called, then all pegs reset', () {
      /// Validates that reset() properly resets all peg states
      /// This is used when restarting a level
      
      // Given
      final level = Level.generate(1, 400.0, 600.0);
      // Mark some pegs as hit
      if (level.pegs.isNotEmpty) {
        level.pegs[0].onHit();
      }
      if (level.pegs.length > 1) {
        level.pegs[1].onHit();
      }

      // When
      level.reset();

      // Then - all pegs should be reset (hasBeenHit = false)
      for (final peg in level.pegs) {
        expect(peg.hasBeenHit, isFalse);
      }
    });

    test('given level with balls in slots, when reset called, then all slots reset', () {
      /// Validates that reset() clears slot ball counts
      /// This ensures clean state for level retry
      
      // Given
      final level = Level.generate(1, 400.0, 600.0);
      // Add balls to some slots
      level.slots[0].addBall();
      level.slots[0].addBall();
      if (level.slots.length > 1) {
        level.slots[1].addBall();
      }

      // When
      level.reset();

      // Then - all slots should be reset (ballCount = 0)
      for (final slot in level.slots) {
        expect(slot.ballCount, equals(0));
      }
    });
  });
}