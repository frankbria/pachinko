import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pachinko_game/widgets/achievement_toast.dart';
import 'package:pachinko_game/models/achievement.dart';

void main() {
  group('AchievementToast', () {
    testWidgets('given achievement toast, when rendered, then shows achievement name',
        (tester) async {
      // Arrange
      bool dismissed = false;
      final achievement = Achievement(
        id: 'test',
        name: 'Test Achievement',
        description: 'Test description',
        icon: Icons.star,
        pointValue: 100,
      );
      achievement.unlock();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AchievementToast(
              achievement: achievement,
              onDismissed: () => dismissed = true,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Assert
      expect(find.text('Test Achievement'), findsOneWidget);
      expect(find.text('100 points'), findsOneWidget);
      expect(find.text('Achievement Unlocked!'), findsOneWidget);

      // Cleanup - Wait for auto-dismiss to prevent pending timer
      await tester.pump(const Duration(milliseconds: 3500));
      await tester.pumpAndSettle();
    });

    testWidgets('given achievement toast, when tapped, then dismisses',
        (tester) async {
      // Arrange
      bool dismissed = false;
      final achievement = Achievement(
        id: 'test',
        name: 'Test Achievement',
        description: 'Test',
        icon: Icons.star,
        pointValue: 100,
      );
      achievement.unlock();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AchievementToast(
              achievement: achievement,
              onDismissed: () => dismissed = true,
            ),
          ),
        ),
      );

      // Wait for initial animation
      await tester.pump(const Duration(milliseconds: 500));

      // Act - Tap toast
      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();

      // Assert
      expect(dismissed, true);
    });

    testWidgets('given achievement toast, when 3.5s elapsed, then auto-dismisses',
        (tester) async {
      // Arrange
      bool dismissed = false;
      final achievement = Achievement(
        id: 'test',
        name: 'Test Achievement',
        description: 'Test',
        icon: Icons.star,
        pointValue: 100,
      );
      achievement.unlock();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AchievementToast(
              achievement: achievement,
              onDismissed: () => dismissed = true,
            ),
          ),
        ),
      );

      // Act - Wait for auto-dismiss (3.5 seconds + animation)
      await tester.pump(const Duration(milliseconds: 3500));
      await tester.pumpAndSettle();

      // Assert
      expect(dismissed, true);
    });

    testWidgets('given achievement toast, when rendered, then shows trophy icon',
        (tester) async {
      // Arrange
      bool dismissed = false;
      final achievement = Achievement(
        id: 'test',
        name: 'Test Achievement',
        description: 'Test',
        icon: Icons.star,
        pointValue: 100,
      );
      achievement.unlock();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AchievementToast(
              achievement: achievement,
              onDismissed: () => dismissed = true,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Assert - Check for emoji_events (trophy) icon
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
      // Also check for the achievement's custom icon
      expect(find.byIcon(Icons.star), findsOneWidget);

      // Cleanup
      await tester.pump(const Duration(milliseconds: 3500));
      await tester.pumpAndSettle();
    });

    testWidgets('given achievement toast, when rendered, then has gold border',
        (tester) async {
      // Arrange
      bool dismissed = false;
      final achievement = Achievement(
        id: 'test',
        name: 'Test Achievement',
        description: 'Test',
        icon: Icons.star,
        pointValue: 100,
      );
      achievement.unlock();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AchievementToast(
              achievement: achievement,
              onDismissed: () => dismissed = true,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Assert - Find the Container with gold border
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(GestureDetector),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
      expect((decoration.border as Border).top.color, const Color(0xFFFFD700));

      // Cleanup
      await tester.pump(const Duration(milliseconds: 3500));
      await tester.pumpAndSettle();
    });
  });
}
