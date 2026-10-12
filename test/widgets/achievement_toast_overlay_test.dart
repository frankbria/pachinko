import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pachinko_game/widgets/achievement_toast_overlay.dart';
import 'package:pachinko_game/widgets/achievement_toast.dart';
import 'package:pachinko_game/models/achievement.dart';

void main() {
  /// Opacity of the toast's fade animation (1.0 = fully visible).
  double toastOpacity(WidgetTester tester) => tester
      .widget<FadeTransition>(find
          .descendant(
            of: find.byType(AchievementToast),
            matching: find.byType(FadeTransition),
          )
          .first)
      .opacity
      .value;

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

    testWidgets(
        'given toast overlay, when context accessed, then of() returns state',
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

    testWidgets(
        'given no overlay ancestor, when of() called, then returns null',
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

    testWidgets(
        'given two queued achievements, when first is dismissed, then second is visible and auto-dismisses',
        (tester) async {
      // Arrange
      final first = Achievement(
        id: 'test1',
        name: 'First Achievement',
        description: 'Test 1',
        icon: Icons.star,
        pointValue: 100,
      )..unlock();
      final second = Achievement(
        id: 'test2',
        name: 'Second Achievement',
        description: 'Test 2',
        icon: Icons.military_tech,
        pointValue: 200,
      )..unlock();
      final overlayKey = GlobalKey<AchievementToastOverlayState>();

      await tester.pumpWidget(
        MaterialApp(
          home: AchievementToastOverlay(
            key: overlayKey,
            child: const Scaffold(body: SizedBox()),
          ),
        ),
      );

      // Act - Show both, then dismiss the first by tapping it
      overlayKey.currentState!.showAchievementToast(first);
      overlayKey.currentState!.showAchievementToast(second);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('First Achievement'));
      await tester.pumpAndSettle();

      // Assert - Second toast is on screen and fully opaque
      expect(find.text('Second Achievement'), findsOneWidget);
      expect(toastOpacity(tester), 1.0);

      // Assert - It dismisses itself after 3.5 seconds
      await tester.pump(const Duration(milliseconds: 3500));
      await tester.pumpAndSettle();
      expect(find.byType(AchievementToast), findsNothing);
    });

    testWidgets(
        'given the same achievement shown twice in a row, when the first is dismissed, then a second toast is visible and auto-dismisses',
        (tester) async {
      /// Each toast needs a fresh State. Keyed by the achievement's id, the
      /// second toast would reuse the first one's State, which has already
      /// dismissed: invisible, deaf to taps, never dismissing, and holding up
      /// every toast queued behind it.
      // Arrange
      final achievement = Achievement(
        id: 'repeat',
        name: 'Repeat Achievement',
        description: 'Shown twice',
        icon: Icons.star,
        pointValue: 100,
      )..unlock();
      final after = Achievement(
        id: 'after',
        name: 'After The Repeat',
        description: 'Queued behind it',
        icon: Icons.military_tech,
        pointValue: 200,
      )..unlock();
      final overlayKey = GlobalKey<AchievementToastOverlayState>();

      await tester.pumpWidget(
        MaterialApp(
          home: AchievementToastOverlay(
            key: overlayKey,
            child: const Scaffold(body: SizedBox()),
          ),
        ),
      );

      // Act - Show it twice with another behind, then dismiss the first by tapping it
      overlayKey.currentState!.showAchievementToast(achievement);
      overlayKey.currentState!.showAchievementToast(achievement);
      overlayKey.currentState!.showAchievementToast(after);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Repeat Achievement'));
      await tester.pumpAndSettle();

      // Assert - The second toast for the same achievement is on screen and fully opaque
      expect(find.text('Repeat Achievement'), findsOneWidget);
      expect(toastOpacity(tester), 1.0);

      // Assert - It dismisses itself, and the toast behind it gets its turn
      await tester.pump(const Duration(milliseconds: 3500));
      await tester.pumpAndSettle();
      expect(find.text('Repeat Achievement'), findsNothing);
      expect(find.text('After The Repeat'), findsOneWidget);
      expect(toastOpacity(tester), 1.0);

      // Cleanup - Let the last toast dismiss itself
      await tester.pump(const Duration(milliseconds: 3500));
      await tester.pumpAndSettle();
      expect(find.byType(AchievementToast), findsNothing);
    });

    testWidgets(
        'given overlay installed in MaterialApp.builder, when toast shown over a pushed route, then toast is visible',
        (tester) async {
      // Arrange
      final achievement = Achievement(
        id: 'test',
        name: 'Test Achievement',
        description: 'Test',
        icon: Icons.star,
        pointValue: 100,
      )..unlock();
      final overlayKey = GlobalKey<AchievementToastOverlayState>();
      final navigatorKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          builder: (context, child) =>
              AchievementToastOverlay(key: overlayKey, child: child!),
          home: const Scaffold(body: Text('home')),
        ),
      );
      navigatorKey.currentState!.push(MaterialPageRoute(
          builder: (_) => const Scaffold(body: Text('second'))));
      await tester.pumpAndSettle();

      // Act
      overlayKey.currentState!.showAchievementToast(achievement);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Assert
      expect(find.text('second'), findsOneWidget);
      expect(find.text('Test Achievement'), findsOneWidget);
      expect(toastOpacity(tester), 1.0);

      // Assert - Toast brings its own Material (no Scaffold above the Navigator)
      expect(
        find.ancestor(
          of: find.byType(AchievementToast),
          matching: find.byType(Material),
        ),
        findsOneWidget,
      );

      // Cleanup - Wait for auto-dismiss
      await tester.pump(const Duration(milliseconds: 3500));
      await tester.pumpAndSettle();
      expect(find.byType(AchievementToast), findsNothing);
    });

    testWidgets(
        'given queued achievements, when first is tapped twice, then next toast is not skipped',
        (tester) async {
      // Arrange
      final overlayKey = GlobalKey<AchievementToastOverlayState>();

      await tester.pumpWidget(
        MaterialApp(
          home: AchievementToastOverlay(
            key: overlayKey,
            child: const Scaffold(body: SizedBox()),
          ),
        ),
      );

      for (final name in ['First', 'Second', 'Third']) {
        overlayKey.currentState!.showAchievementToast(Achievement(
          id: name,
          name: name,
          description: 'Test',
          icon: Icons.star,
          pointValue: 100,
        )..unlock());
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Act - Second tap lands while the dismiss animation is still running
      await tester.tap(find.text('First'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('First'));
      await tester.pumpAndSettle();

      // Assert - The queue advanced by exactly one toast
      expect(find.text('Second'), findsOneWidget);
      expect(find.text('Third'), findsNothing);

      // Cleanup - Wait for remaining toasts to auto-dismiss
      await tester.pump(const Duration(milliseconds: 15000));
      await tester.pumpAndSettle();
    });
  });
}
