import 'package:flutter_test/flutter_test.dart';
import 'package:pachinko_game/widgets/floating_text.dart';
import 'package:flutter/material.dart';

void main() {
  group('FloatingText', () {
    test('given new floating text, when created, then opacity is 1.0', () {
      // Arrange & Act
      final floatingText = FloatingText(
        text: '+100',
        startPosition: const Offset(100, 100),
        color: Colors.white,
      );

      // Assert
      expect(floatingText.opacity, 1.0);
      expect(floatingText.yOffset, 0.0);
      expect(floatingText.timer, 0.0);
    });

    test('given floating text, when updated halfway, then moves upward and stays opaque', () {
      // Arrange
      final floatingText = FloatingText(
        text: '+100',
        startPosition: const Offset(100, 100),
        color: Colors.white,
      );

      // Act
      final expired = floatingText.update(0.75); // Halfway through 1.5s duration

      // Assert
      expect(expired, false);
      expect(floatingText.opacity, 1.0); // Still fully opaque before last 0.5s
      expect(floatingText.yOffset, closeTo(37.5, 0.1)); // 0.75s * 50px/s
      expect(floatingText.currentPosition.dy, closeTo(62.5, 0.1)); // 100 - 37.5
    });

    test('given floating text, when in fade-out period, then opacity decreases', () {
      // Arrange
      final floatingText = FloatingText(
        text: '+100',
        startPosition: const Offset(100, 100),
        color: Colors.white,
      );

      // Act - Update to 1.25s (within last 0.5s of 1.5s duration)
      floatingText.update(1.25);

      // Assert
      expect(floatingText.opacity, closeTo(0.5, 0.1)); // (1.5 - 1.25) / 0.5 = 0.5
    });

    test('given floating text, when duration expires, then update returns true', () {
      // Arrange
      final floatingText = FloatingText(
        text: '+100',
        startPosition: const Offset(100, 100),
        color: Colors.white,
      );

      // Act
      final expired = floatingText.update(1.6); // Beyond 1.5s duration

      // Assert
      expect(expired, true);
    });

    test('given floating text, when multiple updates, then accumulates correctly', () {
      // Arrange
      final floatingText = FloatingText(
        text: '+100',
        startPosition: const Offset(100, 100),
        color: Colors.white,
      );

      // Act
      floatingText.update(0.5);
      floatingText.update(0.5);
      final expired = floatingText.update(0.5);

      // Assert
      expect(expired, true); // Total 1.5s
      expect(floatingText.timer, 1.5);
    });

    test('given floating text, when accessing currentPosition, then calculates correctly', () {
      // Arrange
      final floatingText = FloatingText(
        text: '+100',
        startPosition: const Offset(100, 200),
        color: Colors.white,
      );

      // Act
      floatingText.update(1.0);

      // Assert
      expect(floatingText.currentPosition.dx, 100); // X stays the same
      expect(floatingText.currentPosition.dy, closeTo(150, 0.1)); // 200 - (1.0 * 50)
    });
  });
}
