// Unit tests for Peg model
//
// This test suite validates all Peg model functionality including:
// - Initialization and default values
// - Collision detection (circle-circle collision geometry)
// - Collision normal calculation (mathematical correctness)
// - Special peg highlighting mechanics
// - Hit tracking and state persistence
// - Color rendering based on type and state
//
// Tests follow Given-When-Then naming pattern for clarity:
// - Given: Initial state/context
// - When: Action performed
// - Then: Expected outcome

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:pachinko_game/models/peg.dart';

void main() {
  group('Peg Initialization -', () {
    test('given a position, when peg is created, then it initializes with correct defaults', () {
      // Given
      final position = Vector2(100, 200);

      // When
      final peg = Peg(position: position);

      // Then
      expect(peg.position, equals(position));
      expect(peg.radius, equals(12.0));
      expect(peg.type, equals(PegType.normal));
      expect(peg.isHighlighted, isFalse);
      expect(peg.hasBeenHit, isFalse);
    });

    test('given custom parameters, when peg is created, then it uses provided values', () {
      // Given
      final position = Vector2(150, 250);
      const customRadius = 15.0;
      const customColor = Color(0xFF00FF00);

      // When
      final peg = Peg(
        position: position,
        radius: customRadius,
        type: PegType.special,
        color: customColor,
        isHighlighted: true,
        hasBeenHit: true,
      );

      // Then
      expect(peg.position, equals(position));
      expect(peg.radius, equals(customRadius));
      expect(peg.type, equals(PegType.special));
      expect(peg.color, equals(customColor));
      expect(peg.isHighlighted, isTrue);
      expect(peg.hasBeenHit, isTrue);
    });

    test('given normal type, when peg is created, then color defaults to green', () {
      // Given
      final position = Vector2(100, 100);

      // When
      final peg = Peg(position: position, type: PegType.normal);

      // Then
      expect(peg.color, equals(const Color(0xFF4CAF50))); // Green
    });

    test('given special type, when peg is created, then color defaults to orange', () {
      // Given
      final position = Vector2(100, 100);

      // When
      final peg = Peg(position: position, type: PegType.special);

      // Then
      expect(peg.color, equals(const Color(0xFFFF9800))); // Orange
    });

    test('given bonus type, when peg is created, then color defaults to pink', () {
      // Given
      final position = Vector2(100, 100);

      // When
      final peg = Peg(position: position, type: PegType.bonus);

      // Then
      expect(peg.color, equals(const Color(0xFFE91E63))); // Pink
    });

    test('given custom color, when peg is created, then it overrides default color', () {
      // Given
      final position = Vector2(100, 100);
      const customColor = Color(0xFFFFFFFF); // White

      // When
      final peg = Peg(
        position: position,
        type: PegType.normal,
        color: customColor,
      );

      // Then
      expect(peg.color, equals(customColor));
      expect(peg.color, isNot(equals(const Color(0xFF4CAF50)))); // Not default green
    });
  });

  group('Collision Detection -', () {
    /// Validates circle-circle collision formula: distance <= (r1 + r2)
    ///
    /// This test verifies the core collision detection logic where two circles
    /// (peg and ball) are considered colliding when the distance between their
    /// centers is less than or equal to the sum of their radii.
    test('given ball within peg radius, when checkCollision called, then returns true', () {
      // Given
      final peg = Peg(position: Vector2(100, 100), radius: 12.0);
      final ballPosition = Vector2(105, 100); // 5 pixels away, within combined radius
      const ballRadius = 8.0;

      // When
      final result = peg.checkCollision(ballPosition, ballRadius);

      // Then
      expect(result, isTrue); // distance (5) <= pegRadius (12) + ballRadius (8) = 20
    });

    test('given ball outside peg radius, when checkCollision called, then returns false', () {
      // Given
      final peg = Peg(position: Vector2(100, 100), radius: 12.0);
      final ballPosition = Vector2(150, 100); // 50 pixels away, outside combined radius
      const ballRadius = 8.0;

      // When
      final result = peg.checkCollision(ballPosition, ballRadius);

      // Then
      expect(result, isFalse); // distance (50) > pegRadius (12) + ballRadius (8) = 20
    });

    /// Edge case: Verifies exact boundary handling in collision detection
    ///
    /// When the ball is positioned exactly at the sum of the radii, the
    /// collision should still be detected (<=, not <). This prevents
    /// off-by-one errors in collision response.
    test('given ball exactly at peg radius boundary, when checkCollision called, then returns true', () {
      // Given
      final peg = Peg(position: Vector2(100, 100), radius: 12.0);
      final ballPosition = Vector2(120, 100); // Exactly 20 pixels away (12 + 8)
      const ballRadius = 8.0;

      // When
      final result = peg.checkCollision(ballPosition, ballRadius);

      // Then
      expect(result, isTrue); // distance (20) == pegRadius (12) + ballRadius (8) = 20
    });

    /// Edge case: Ball overlapping peg center (distance = 0)
    ///
    /// This extreme case verifies collision detection handles zero distance
    /// correctly, which can occur during physics edge cases or initialization.
    test('given ball at peg center, when checkCollision called, then returns true', () {
      // Given
      final peg = Peg(position: Vector2(100, 100), radius: 12.0);
      final ballPosition = Vector2(100, 100); // Exact same position
      const ballRadius = 8.0;

      // When
      final result = peg.checkCollision(ballPosition, ballRadius);

      // Then
      expect(result, isTrue); // distance (0) <= pegRadius (12) + ballRadius (8) = 20
    });

    test('given ball grazing peg edge, when checkCollision called, then returns true', () {
      // Given
      final peg = Peg(position: Vector2(100, 100), radius: 12.0);
      // Place ball 19.5 pixels away (just barely within combined radius of 20)
      final ballPosition = Vector2(119.5, 100);
      const ballRadius = 8.0;

      // When
      final result = peg.checkCollision(ballPosition, ballRadius);

      // Then
      expect(result, isTrue); // distance (19.5) < pegRadius (12) + ballRadius (8) = 20
    });

    test('given ball just beyond peg radius, when checkCollision called, then returns false', () {
      // Given
      final peg = Peg(position: Vector2(100, 100), radius: 12.0);
      // Place ball 20.1 pixels away (just beyond combined radius of 20)
      final ballPosition = Vector2(120.1, 100);
      const ballRadius = 8.0;

      // When
      final result = peg.checkCollision(ballPosition, ballRadius);

      // Then
      expect(result, isFalse); // distance (20.1) > pegRadius (12) + ballRadius (8) = 20
    });
  });

  group('Collision Normal Calculation -', () {
    /// Validates collision normal vector calculation: n = normalize(ballPos - pegPos)
    ///
    /// The collision normal points from the peg center toward the ball contact point.
    /// This direction is crucial for realistic bounce physics. The normal must be
    /// normalized to unit length for consistent force application.
    test('given ball to the right of peg, when getCollisionNormal called, then returns normalized right vector', () {
      // Given
      final peg = Peg(position: Vector2(100, 100));
      final ballPosition = Vector2(150, 100); // 50 pixels to the right

      // When
      final normal = peg.getCollisionNormal(ballPosition);

      // Then
      expect(normal.x, closeTo(1.0, 0.001)); // Points right (1, 0)
      expect(normal.y, closeTo(0.0, 0.001));
    });

    test('given ball to the left of peg, when getCollisionNormal called, then returns normalized left vector', () {
      // Given
      final peg = Peg(position: Vector2(100, 100));
      final ballPosition = Vector2(50, 100); // 50 pixels to the left

      // When
      final normal = peg.getCollisionNormal(ballPosition);

      // Then
      expect(normal.x, closeTo(-1.0, 0.001)); // Points left (-1, 0)
      expect(normal.y, closeTo(0.0, 0.001));
    });

    test('given ball above peg, when getCollisionNormal called, then returns normalized up vector', () {
      // Given
      final peg = Peg(position: Vector2(100, 100));
      final ballPosition = Vector2(100, 50); // 50 pixels above (lower y value)

      // When
      final normal = peg.getCollisionNormal(ballPosition);

      // Then
      expect(normal.x, closeTo(0.0, 0.001));
      expect(normal.y, closeTo(-1.0, 0.001)); // Points up (0, -1)
    });

    test('given ball below peg, when getCollisionNormal called, then returns normalized down vector', () {
      // Given
      final peg = Peg(position: Vector2(100, 100));
      final ballPosition = Vector2(100, 150); // 50 pixels below (higher y value)

      // When
      final normal = peg.getCollisionNormal(ballPosition);

      // Then
      expect(normal.x, closeTo(0.0, 0.001));
      expect(normal.y, closeTo(1.0, 0.001)); // Points down (0, 1)
    });

    /// Validates diagonal collision normal calculation
    ///
    /// For a 45-degree angle, the normalized normal should be (√2/2, √2/2) ≈ (0.707, 0.707).
    /// This tests the normalization process for non-axis-aligned collisions.
    test('given ball at 45 degree angle, when getCollisionNormal called, then returns normalized diagonal vector', () {
      // Given
      final peg = Peg(position: Vector2(100, 100));
      final ballPosition = Vector2(150, 150); // 45 degrees down-right

      // When
      final normal = peg.getCollisionNormal(ballPosition);

      // Then
      // For 45 degrees: cos(45°) = sin(45°) = √2/2 ≈ 0.707
      expect(normal.x, closeTo(0.707, 0.01));
      expect(normal.y, closeTo(0.707, 0.01));
    });

    /// Mathematical validation: All collision normals must have unit length
    ///
    /// Verifies the normalization invariant: |n| = √(nx² + ny²) = 1
    /// This property is essential for consistent physics calculations across
    /// all collision angles.
    test('given any ball position, when getCollisionNormal called, then normal vector has unit length', () {
      // Given
      final peg = Peg(position: Vector2(100, 100));
      final testPositions = [
        Vector2(120, 130),  // Arbitrary position 1
        Vector2(85, 95),    // Arbitrary position 2
        Vector2(150, 75),   // Arbitrary position 3
        Vector2(100, 200),  // Vertical
        Vector2(200, 100),  // Horizontal
      ];

      // When & Then
      for (final ballPosition in testPositions) {
        final normal = peg.getCollisionNormal(ballPosition);
        final length = normal.length;

        expect(length, closeTo(1.0, 0.001)); // Unit vector: length = 1
      }
    });
  });

  group('Special Peg Highlighting -', () {
    test('given normal peg, when created, then isHighlighted is false', () {
      // Given & When
      final peg = Peg(position: Vector2(100, 100), type: PegType.normal);

      // Then
      expect(peg.isHighlighted, isFalse);
    });

    /// Verifies special peg highlighting activation on level reset
    ///
    /// Special pegs should be visually highlighted at the start of each level
    /// to indicate they trigger bonus ball mechanics when hit.
    test('given special peg, when reset is called, then isHighlighted becomes true', () {
      // Given
      final peg = Peg(
        position: Vector2(100, 100),
        type: PegType.special,
        isHighlighted: false,
      );

      // When
      peg.reset();

      // Then
      expect(peg.isHighlighted, isTrue);
    });

    /// Edge case: Special peg highlighting deactivates after being hit
    ///
    /// Once a special peg is hit, it should lose its highlight to indicate
    /// it has already been triggered and won't grant additional bonuses.
    test('given highlighted special peg, when onHit is called, then isHighlighted becomes false', () {
      // Given
      final peg = Peg(
        position: Vector2(100, 100),
        type: PegType.special,
        isHighlighted: true,
      );

      // When
      peg.onHit();

      // Then
      expect(peg.isHighlighted, isFalse);
      expect(peg.hasBeenHit, isTrue);
    });

    test('given bonus peg, when reset is called, then isHighlighted remains false', () {
      // Given
      final peg = Peg(
        position: Vector2(100, 100),
        type: PegType.bonus,
        isHighlighted: false,
      );

      // When
      peg.reset();

      // Then
      expect(peg.isHighlighted, isFalse); // Bonus pegs don't get highlighted
    });
  });

  group('Hit Tracking -', () {
    test('given unhit peg, when onHit is called, then hasBeenHit becomes true', () {
      // Given
      final peg = Peg(position: Vector2(100, 100), hasBeenHit: false);

      // When
      peg.onHit();

      // Then
      expect(peg.hasBeenHit, isTrue);
    });

    /// Edge case: Double-hit prevention (state persistence)
    ///
    /// Once a peg is hit, subsequent hits should not change its state.
    /// This prevents double-counting scoring and ensures each peg
    /// contributes to game mechanics only once per level.
    test('given hit peg, when onHit called again, then hasBeenHit remains true', () {
      // Given
      final peg = Peg(position: Vector2(100, 100), hasBeenHit: true);

      // When
      peg.onHit(); // Second hit

      // Then
      expect(peg.hasBeenHit, isTrue); // Still true, no state change
    });

    test('given hit peg, when reset is called, then hasBeenHit becomes false', () {
      // Given
      final peg = Peg(position: Vector2(100, 100), hasBeenHit: true);

      // When
      peg.reset();

      // Then
      expect(peg.hasBeenHit, isFalse); // Ready for new level
    });
  });

  group('Color Rendering -', () {
    test('given normal unhit peg, when renderColor accessed, then returns full opacity color', () {
      // Given
      final peg = Peg(
        position: Vector2(100, 100),
        type: PegType.normal,
        hasBeenHit: false,
      );

      // When
      final renderColor = peg.renderColor;

      // Then
      expect(renderColor.opacity, equals(1.0)); // Full opacity
      expect(renderColor, equals(const Color(0xFF4CAF50))); // Green
    });

    test('given hit peg, when renderColor accessed, then returns reduced opacity color', () {
      // Given
      final peg = Peg(
        position: Vector2(100, 100),
        type: PegType.normal,
        hasBeenHit: true,
      );

      // When
      final renderColor = peg.renderColor;

      // Then
      expect(renderColor.opacity, equals(0.6)); // Reduced opacity
    });

    /// Validates special peg visual glow effect
    ///
    /// Highlighted special pegs should have a yellow tint (Color.lerp with yellow)
    /// to draw player attention and indicate bonus potential.
    test('given highlighted special peg, when renderColor accessed, then returns yellow-tinted color', () {
      // Given
      final peg = Peg(
        position: Vector2(100, 100),
        type: PegType.special,
        isHighlighted: true,
        hasBeenHit: false,
      );

      // When
      final renderColor = peg.renderColor;

      // Then
      // Color.lerp between orange (0xFFFF9800) and yellow (0xFFFFFF00) at 0.5
      // Should produce a yellow-tinted orange
      expect(renderColor, isNot(equals(const Color(0xFFFF9800)))); // Not pure orange
      expect(renderColor.opacity, equals(1.0)); // Full opacity
    });

    test('given unhighlighted special peg, when renderColor accessed, then returns normal special color', () {
      // Given
      final peg = Peg(
        position: Vector2(100, 100),
        type: PegType.special,
        isHighlighted: false,
        hasBeenHit: false,
      );

      // When
      final renderColor = peg.renderColor;

      // Then
      expect(renderColor, equals(const Color(0xFFFF9800))); // Orange, no glow
      expect(renderColor.opacity, equals(1.0));
    });

    test('given hit special peg, when renderColor accessed, then returns reduced opacity color', () {
      // Given
      final peg = Peg(
        position: Vector2(100, 100),
        type: PegType.special,
        isHighlighted: false,
        hasBeenHit: true,
      );

      // When
      final renderColor = peg.renderColor;

      // Then
      expect(renderColor.opacity, equals(0.6)); // Reduced opacity (hit state overrides type)
    });
  });
}
