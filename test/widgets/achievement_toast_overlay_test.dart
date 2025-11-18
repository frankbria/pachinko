import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pachinko_game/widgets/achievement_toast_overlay.dart';
import 'package:pachinko_game/widgets/achievement_toast.dart';
import 'package:pachinko_game/models/achievement.dart';

void main() {
  group('AchievementToastOverlay', () {
    testWidgets(
        'given toast overlay, when showAchievementToast called, then toast appears',
        (tester) async {
      // Arrange
      final achievement = Achievement(
        id: 'test',
        name: 'Test Achievement',
        description: 'Test',
        icon: Icons.star,
        pointValue: 100,
      );
      achievement.unlock();

      late AchievementToastOverlayState overlayState;

      await tester.pumpWidget(
        MaterialApp(
          home: AchievementToastOverlay(
            child: Builder(
              builder: (context) {
                overlayState = AchievementToastOverlay.of(context)!;
                return const Scaffold(body: SizedBox());
              },
            ),
          ),
        ),
      );

      // Assert - No toast initially
      expect(find.byType(AchievementToast), findsNothing);

      // Act - Show toast
      overlayState.showAchievementToast(achievement);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Assert - Toast appears
      expect(find.byType(AchievementToast), findsOneWidget);
      expect(find.text('Test Achievement'), findsOneWidget);

      // Cleanup - Wait for auto-dismiss
      await tester.pump(const Duration(milliseconds: 3500));
      await tester.pumpAndSettle();
    });

    testWidgets(
        'given two achievements, when shown sequentially, then queue works',
        (tester) async {
      // Arrange
      final achievement1 = Achievement(
        id: 'test1',
        name: 'First Achievement',
        description: 'Test 1',
        icon: Icons.star,
        pointValue: 100,
      );
      achievement1.unlock();

      final achievement2 = Achievement(
        id: 'test2',
        name: 'Second Achievement',
        description: 'Test 2',
        icon: Icons.military_tech,
        pointValue: 200,
      );
      achievement2.unlock();

      late AchievementToastOverlayState overlayState;

      await tester.pumpWidget(
        MaterialApp(
          home: AchievementToastOverlay(
            child: Builder(
              builder: (context) {
                overlayState = AchievementToastOverlay.of(context)!;
                return const Scaffold(body: SizedBox());
              },
            ),
          ),
        ),
      );

      // Act - Show first toast
      overlayState.showAchievementToast(achievement1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Assert - First toast visible
      expect(find.text('First Achievement'), findsOneWidget);
      expect(find.text('Second Achievement'), findsNothing);

      // Act - Show second toast (should be queued)
      overlayState.showAchievementToast(achievement2);
      await tester.pump();

      // Assert - First toast still visible, second queued
      expect(find.text('First Achievement'), findsOneWidget);
      expect(find.text('Second Achievement'), findsNothing);

      // Act - Dismiss first toast by tapping
      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();

      // Assert - Second toast now visible
      expect(find.text('First Achievement'), findsNothing);
      expect(find.text('Second Achievement'), findsOneWidget);

      // Cleanup - Wait for auto-dismiss of second toast
      await tester.pump(const Duration(milliseconds: 3500));
      await tester.pumpAndSettle();
    });

    testWidgets('given toast overlay, when context accessed, then of() returns state',
        (tester) async {
      // Arrange
      AchievementToastOverlayState? foundState;

      await tester.pumpWidget(
        MaterialApp(
          home: AchievementToastOverlay(
            child: Builder(
              builder: (context) {
                foundState = AchievementToastOverlay.of(context);
                return const Scaffold(body: SizedBox());
              },
            ),
          ),
        ),
      );

      // Assert
      expect(foundState, isNotNull);
      expect(foundState, isA<AchievementToastOverlayState>());
    });

    testWidgets(
        'given multiple queued toasts, when shown, then only one visible at a time',
        (tester) async {
      // Arrange
      final achievements = [
        Achievement(
          id: 'test1',
          name: 'First',
          description: 'Test',
          icon: Icons.star,
          pointValue: 100,
        )..unlock(),
        Achievement(
          id: 'test2',
          name: 'Second',
          description: 'Test',
          icon: Icons.military_tech,
          pointValue: 200,
        )..unlock(),
        Achievement(
          id: 'test3',
          name: 'Third',
          description: 'Test',
          icon: Icons.emoji_events,
          pointValue: 300,
        )..unlock(),
      ];

      late AchievementToastOverlayState overlayState;

      await tester.pumpWidget(
        MaterialApp(
          home: AchievementToastOverlay(
            child: Builder(
              builder: (context) {
                overlayState = AchievementToastOverlay.of(context)!;
                return const Scaffold(body: SizedBox());
              },
            ),
          ),
        ),
      );

      // Act - Queue all three toasts
      for (final achievement in achievements) {
        overlayState.showAchievementToast(achievement);
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Assert - Only one toast visible at a time
      expect(find.byType(AchievementToast), findsOneWidget);
      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsNothing);
      expect(find.text('Third'), findsNothing);

      // Cleanup - wait for all toasts to auto-dismiss
      await tester.pump(const Duration(milliseconds: 15000));
      await tester.pumpAndSettle();
    });

    testWidgets('given no overlay ancestor, when of() called, then returns null',
        (tester) async {
      // Arrange
      AchievementToastOverlayState? foundState;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                foundState = AchievementToastOverlay.of(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      // Assert
      expect(foundState, isNull);
    });
  });
}
