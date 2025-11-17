import 'package:flutter_test/flutter_test.dart';
import 'package:pachinko_game/models/slot.dart';
import 'package:vector_math/vector_math_64.dart';
import 'dart:ui';

void main() {
  group('Slot Initialization -', () {
    test('given default parameters, when slot created, then initializes with correct values', () {
      // Given
      final position = Vector2(100.0, 200.0);
      const width = 50.0;
      const height = 30.0;
      const pointValue = 100;

      // When
      final slot = Slot(
        position: position,
        width: width,
        height: height,
        pointValue: pointValue,
      );

      // Then
      expect(slot.position, equals(position));
      expect(slot.width, equals(width));
      expect(slot.height, equals(height));
      expect(slot.pointValue, equals(pointValue));
      expect(slot.ballCount, equals(0));
    });

    test('given custom color, when slot created, then uses custom color', () {
      // Given
      final position = Vector2(100.0, 200.0);
      const customColor = Color(0xFF123456);

      // When
      final slot = Slot(
        position: position,
        width: 50.0,
        height: 30.0,
        pointValue: 100,
        color: customColor,
      );

      // Then
      expect(slot.color, equals(customColor));
    });

    test('given null color, when slot created, then derives color from pointValue', () {
      // Given
      final position = Vector2(100.0, 200.0);
      const pointValue = 1000;

      // When
      final slot = Slot(
        position: position,
        width: 50.0,
        height: 30.0,
        pointValue: pointValue,
        // color not provided
      );

      // Then
      expect(slot.color, equals(const Color(0xFFFF5722))); // Red for ≥1000 points
    });

    test('given custom ballCount, when slot created, then initializes with custom count', () {
      // Given
      final position = Vector2(100.0, 200.0);
      const initialBallCount = 5;

      // When
      final slot = Slot(
        position: position,
        width: 50.0,
        height: 30.0,
        pointValue: 100,
        ballCount: initialBallCount,
      );

      // Then
      expect(slot.ballCount, equals(initialBallCount));
    });
  });

  group('AABB Collision Detection -', () {
    /// Tests AABB (Axis-Aligned Bounding Box) collision detection.
    ///
    /// AABB uses rectangular bounds checking: point must satisfy ALL four conditions:
    /// - x >= left (centerX - width/2)
    /// - x <= right (centerX + width/2)
    /// - y >= top (centerY - height/2)
    /// - y <= bottom (centerY + height/2)
    ///
    /// This differs from circle collision (Task 1.3 Peg model) which uses radial distance:
    /// - Circle: distance <= (r1 + r2) - single comparison
    /// - AABB: four independent boundary comparisons - all must be true
    test('given ball inside slot bounds, when containsPoint called, then returns true', () {
      // Given
      final slot = Slot(
        position: Vector2(100.0, 200.0),
        width: 50.0,
        height: 30.0,
        pointValue: 100,
      );
      final ballPosition = Vector2(100.0, 200.0); // Center of slot

      // When
      final result = slot.containsPoint(ballPosition);

      // Then
      expect(result, isTrue);
    });

    test('given ball outside slot bounds, when containsPoint called, then returns false', () {
      // Given
      final slot = Slot(
        position: Vector2(100.0, 200.0),
        width: 50.0,
        height: 30.0,
        pointValue: 100,
      );
      final ballPosition = Vector2(200.0, 300.0); // Far outside

      // When
      final result = slot.containsPoint(ballPosition);

      // Then
      expect(result, isFalse);
    });

    /// Tests exact left boundary condition.
    ///
    /// AABB boundary testing uses <= for inclusive boundaries.
    /// Left edge: x = centerX - width/2 = 100 - 25 = 75
    /// Using <= ensures point exactly at boundary is considered inside.
    test('given ball exactly at left boundary, when containsPoint called, then returns true', () {
      // Given
      final slot = Slot(
        position: Vector2(100.0, 200.0),
        width: 50.0,
        height: 30.0,
        pointValue: 100,
      );
      final ballPosition = Vector2(75.0, 200.0); // Exactly at left edge (100 - 50/2)

      // When
      final result = slot.containsPoint(ballPosition);

      // Then
      expect(result, isTrue);
    });

    /// Tests exact right boundary condition.
    ///
    /// Right edge: x = centerX + width/2 = 100 + 25 = 125
    /// Using <= ensures point exactly at boundary is considered inside.
    test('given ball exactly at right boundary, when containsPoint called, then returns true', () {
      // Given
      final slot = Slot(
        position: Vector2(100.0, 200.0),
        width: 50.0,
        height: 30.0,
        pointValue: 100,
      );
      final ballPosition = Vector2(125.0, 200.0); // Exactly at right edge (100 + 50/2)

      // When
      final result = slot.containsPoint(ballPosition);

      // Then
      expect(result, isTrue);
    });

    /// Tests exact top boundary condition.
    ///
    /// Top edge: y = centerY - height/2 = 200 - 15 = 185
    /// Using <= ensures point exactly at boundary is considered inside.
    test('given ball exactly at top boundary, when containsPoint called, then returns true', () {
      // Given
      final slot = Slot(
        position: Vector2(100.0, 200.0),
        width: 50.0,
        height: 30.0,
        pointValue: 100,
      );
      final ballPosition = Vector2(100.0, 185.0); // Exactly at top edge (200 - 30/2)

      // When
      final result = slot.containsPoint(ballPosition);

      // Then
      expect(result, isTrue);
    });

    /// Tests exact bottom boundary condition.
    ///
    /// Bottom edge: y = centerY + height/2 = 200 + 15 = 215
    /// Using <= ensures point exactly at boundary is considered inside.
    test('given ball exactly at bottom boundary, when containsPoint called, then returns true', () {
      // Given
      final slot = Slot(
        position: Vector2(100.0, 200.0),
        width: 50.0,
        height: 30.0,
        pointValue: 100,
      );
      final ballPosition = Vector2(100.0, 215.0); // Exactly at bottom edge (200 + 30/2)

      // When
      final result = slot.containsPoint(ballPosition);

      // Then
      expect(result, isTrue);
    });

    /// Tests corner collision detection.
    ///
    /// AABB corners are the intersection of two boundary edges.
    /// Top-left corner: (left, top) = (75, 185)
    /// All four boundary conditions must pass for corner to be inside.
    test('given ball at top-left corner, when containsPoint called, then returns true', () {
      // Given
      final slot = Slot(
        position: Vector2(100.0, 200.0),
        width: 50.0,
        height: 30.0,
        pointValue: 100,
      );
      final ballPosition = Vector2(75.0, 185.0); // Top-left corner

      // When
      final result = slot.containsPoint(ballPosition);

      // Then
      expect(result, isTrue);
    });

    test('given ball at bottom-right corner, when containsPoint called, then returns true', () {
      // Given
      final slot = Slot(
        position: Vector2(100.0, 200.0),
        width: 50.0,
        height: 30.0,
        pointValue: 100,
      );
      final ballPosition = Vector2(125.0, 215.0); // Bottom-right corner

      // When
      final result = slot.containsPoint(ballPosition);

      // Then
      expect(result, isTrue);
    });

    test('given ball just outside left boundary, when containsPoint called, then returns false', () {
      // Given
      final slot = Slot(
        position: Vector2(100.0, 200.0),
        width: 50.0,
        height: 30.0,
        pointValue: 100,
      );
      final ballPosition = Vector2(74.9, 200.0); // Just outside left edge

      // When
      final result = slot.containsPoint(ballPosition);

      // Then
      expect(result, isFalse);
    });

    test('given ball just outside right boundary, when containsPoint called, then returns false', () {
      // Given
      final slot = Slot(
        position: Vector2(100.0, 200.0),
        width: 50.0,
        height: 30.0,
        pointValue: 100,
      );
      final ballPosition = Vector2(125.1, 200.0); // Just outside right edge

      // When
      final result = slot.containsPoint(ballPosition);

      // Then
      expect(result, isFalse);
    });
  });

  group('Color Assignment by Point Value -', () {
    /// Tests point-based color derivation logic.
    ///
    /// Color thresholds (from _getColorForPoints):
    /// - ≥1000 points: Red (0xFFFF5722)
    /// - 500-999 points: Orange (0xFFFF9800)
    /// - 100-499 points: Amber (0xFFFFC107)
    /// - <100 points: Green (0xFF4CAF50)
    test('given high points (≥1000), when slot created without color, then uses red color', () {
      // Given
      const pointValue = 2000;

      // When
      final slot = Slot(
        position: Vector2(100.0, 200.0),
        width: 50.0,
        height: 30.0,
        pointValue: pointValue,
      );

      // Then
      expect(slot.color, equals(const Color(0xFFFF5722))); // Red
    });

    test('given medium-high points (500-999), when slot created without color, then uses orange color', () {
      // Given
      const pointValue = 750;

      // When
      final slot = Slot(
        position: Vector2(100.0, 200.0),
        width: 50.0,
        height: 30.0,
        pointValue: pointValue,
      );

      // Then
      expect(slot.color, equals(const Color(0xFFFF9800))); // Orange
    });

    test('given medium points (100-499), when slot created without color, then uses amber color', () {
      // Given
      const pointValue = 250;

      // When
      final slot = Slot(
        position: Vector2(100.0, 200.0),
        width: 50.0,
        height: 30.0,
        pointValue: pointValue,
      );

      // Then
      expect(slot.color, equals(const Color(0xFFFFC107))); // Amber
    });

    test('given low points (<100), when slot created without color, then uses green color', () {
      // Given
      const pointValue = 50;

      // When
      final slot = Slot(
        position: Vector2(100.0, 200.0),
        width: 50.0,
        height: 30.0,
        pointValue: pointValue,
      );

      // Then
      expect(slot.color, equals(const Color(0xFF4CAF50))); // Green
    });

    /// Tests exact threshold boundary for color assignment.
    ///
    /// At exactly 1000 points, should use >= comparison to assign red color.
    /// This prevents off-by-one errors in threshold comparisons.
    test('given exactly 1000 points, when slot created without color, then uses red color', () {
      // Given
      const pointValue = 1000;

      // When
      final slot = Slot(
        position: Vector2(100.0, 200.0),
        width: 50.0,
        height: 30.0,
        pointValue: pointValue,
      );

      // Then
      expect(slot.color, equals(const Color(0xFFFF5722))); // Red (≥1000)
    });

    test('given exactly 500 points, when slot created without color, then uses orange color', () {
      // Given
      const pointValue = 500;

      // When
      final slot = Slot(
        position: Vector2(100.0, 200.0),
        width: 50.0,
        height: 30.0,
        pointValue: pointValue,
      );

      // Then
      expect(slot.color, equals(const Color(0xFFFF9800))); // Orange (≥500)
    });

    test('given exactly 100 points, when slot created without color, then uses amber color', () {
      // Given
      const pointValue = 100;

      // When
      final slot = Slot(
        position: Vector2(100.0, 200.0),
        width: 50.0,
        height: 30.0,
        pointValue: pointValue,
      );

      // Then
      expect(slot.color, equals(const Color(0xFFFFC107))); // Amber (≥100)
    });
  });

  group('Ball Count Management -', () {
    test('given new slot, when created with default ballCount, then ballCount is 0', () {
      // Given / When
      final slot = Slot(
        position: Vector2(100.0, 200.0),
        width: 50.0,
        height: 30.0,
        pointValue: 100,
      );

      // Then
      expect(slot.ballCount, equals(0));
    });

    test('given slot with balls, when addBall called, then ballCount increments', () {
      // Given
      final slot = Slot(
        position: Vector2(100.0, 200.0),
        width: 50.0,
        height: 30.0,
        pointValue: 100,
      );

      // When
      slot.addBall();
      slot.addBall();
      slot.addBall();

      // Then
      expect(slot.ballCount, equals(3));
    });

    test('given slot with balls, when reset called, then ballCount returns to 0', () {
      // Given
      final slot = Slot(
        position: Vector2(100.0, 200.0),
        width: 50.0,
        height: 30.0,
        pointValue: 100,
      );
      slot.addBall();
      slot.addBall();
      expect(slot.ballCount, equals(2)); // Verify balls were added

      // When
      slot.reset();

      // Then
      expect(slot.ballCount, equals(0));
    });
  });

  group('Position Getters -', () {
    /// Tests position calculation getters used for AABB collision detection.
    ///
    /// Slot uses center-based positioning with width/height dimensions.
    /// Getters calculate boundary edges from center position:
    /// - left = centerX - width/2
    /// - right = centerX + width/2
    /// - top = centerY - height/2
    /// - bottom = centerY + height/2
    test('given slot with position, when centerX accessed, then returns x coordinate', () {
      // Given
      final slot = Slot(
        position: Vector2(150.0, 250.0),
        width: 60.0,
        height: 40.0,
        pointValue: 100,
      );

      // When
      final centerX = slot.centerX;

      // Then
      expect(centerX, equals(150.0));
    });

    test('given slot with position, when centerY accessed, then returns y coordinate', () {
      // Given
      final slot = Slot(
        position: Vector2(150.0, 250.0),
        width: 60.0,
        height: 40.0,
        pointValue: 100,
      );

      // When
      final centerY = slot.centerY;

      // Then
      expect(centerY, equals(250.0));
    });

    test('given slot with dimensions, when left accessed, then returns centerX minus half width', () {
      // Given
      final slot = Slot(
        position: Vector2(150.0, 250.0),
        width: 60.0,
        height: 40.0,
        pointValue: 100,
      );

      // When
      final left = slot.left;

      // Then
      expect(left, equals(120.0)); // 150 - 60/2 = 120
    });

    test('given slot with dimensions, when right accessed, then returns centerX plus half width', () {
      // Given
      final slot = Slot(
        position: Vector2(150.0, 250.0),
        width: 60.0,
        height: 40.0,
        pointValue: 100,
      );

      // When
      final right = slot.right;

      // Then
      expect(right, equals(180.0)); // 150 + 60/2 = 180
    });

    test('given slot with dimensions, when top accessed, then returns centerY minus half height', () {
      // Given
      final slot = Slot(
        position: Vector2(150.0, 250.0),
        width: 60.0,
        height: 40.0,
        pointValue: 100,
      );

      // When
      final top = slot.top;

      // Then
      expect(top, equals(230.0)); // 250 - 40/2 = 230
    });

    test('given slot with dimensions, when bottom accessed, then returns centerY plus half height', () {
      // Given
      final slot = Slot(
        position: Vector2(150.0, 250.0),
        width: 60.0,
        height: 40.0,
        pointValue: 100,
      );

      // When
      final bottom = slot.bottom;

      // Then
      expect(bottom, equals(270.0)); // 250 + 40/2 = 270
    });
  });

  group('Bounds Getter -', () {
    /// Tests Rect bounds creation for rendering.
    ///
    /// Bounds getter creates a Rect from center position using Rect.fromCenter.
    /// Used by rendering system to draw slot rectangles on canvas.
    test('given slot with dimensions, when bounds accessed, then returns Rect with correct center', () {
      // Given
      final slot = Slot(
        position: Vector2(150.0, 250.0),
        width: 60.0,
        height: 40.0,
        pointValue: 100,
      );

      // When
      final bounds = slot.bounds;

      // Then
      expect(bounds.center.dx, equals(150.0));
      expect(bounds.center.dy, equals(250.0));
    });

    test('given slot with dimensions, when bounds accessed, then returns Rect with correct dimensions', () {
      // Given
      final slot = Slot(
        position: Vector2(150.0, 250.0),
        width: 60.0,
        height: 40.0,
        pointValue: 100,
      );

      // When
      final bounds = slot.bounds;

      // Then
      expect(bounds.width, equals(60.0));
      expect(bounds.height, equals(40.0));
    });

    test('given slot with dimensions, when bounds accessed, then Rect edges match position getters', () {
      // Given
      final slot = Slot(
        position: Vector2(150.0, 250.0),
        width: 60.0,
        height: 40.0,
        pointValue: 100,
      );

      // When
      final bounds = slot.bounds;

      // Then
      expect(bounds.left, equals(slot.left));     // 120.0
      expect(bounds.right, equals(slot.right));   // 180.0
      expect(bounds.top, equals(slot.top));       // 230.0
      expect(bounds.bottom, equals(slot.bottom)); // 270.0
    });
  });
}
