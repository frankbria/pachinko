import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:pachinko_game/models/achievement.dart';
import 'package:pachinko_game/screens/achievements_screen.dart';
import 'package:pachinko_game/services/achievement_service.dart';

import 'achievements_screen_test.mocks.dart';

// Generate mocks for AchievementService
@GenerateMocks([AchievementService])
void main() {
  late MockAchievementService mockService;

  setUp(() {
    mockService = MockAchievementService();
  });

  Widget createTestWidget() {
    return MaterialApp(
      home: ChangeNotifierProvider<AchievementService>.value(
        value: mockService,
        child: const AchievementsScreen(),
      ),
    );
  }

  group('AchievementsScreen - UI Rendering', () {
    testWidgets('givenAchievementsScreen_whenRendered_thenTitleDisplayed',
        (WidgetTester tester) async {
      // Given
      when(mockService.getAllAchievements()).thenReturn([]);
      when(mockService.getUnlockedAchievements()).thenReturn([]);
      when(mockService.getLockedAchievements()).thenReturn([]);
      when(mockService.getTotalPoints()).thenReturn(0);

      // When
      await tester.pumpWidget(createTestWidget());

      // Then
      expect(find.text('Achievements'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('givenNoAchievements_whenRendered_thenEmptyStateDisplayed',
        (WidgetTester tester) async {
      // Given
      when(mockService.getAllAchievements()).thenReturn([]);
      when(mockService.getUnlockedAchievements()).thenReturn([]);
      when(mockService.getLockedAchievements()).thenReturn([]);
      when(mockService.getTotalPoints()).thenReturn(0);

      // When
      await tester.pumpWidget(createTestWidget());

      // Then
      expect(find.textContaining('No achievements available'), findsOneWidget);
    });

    testWidgets('givenAchievements_whenRendered_thenStatsBannerDisplayed',
        (WidgetTester tester) async {
      // Given
      final achievements = [
        Achievement(
          id: 'test1',
          name: 'Test 1',
          description: 'Test',
          icon: Icons.star,
          pointValue: 100,
        ),
        Achievement(
          id: 'test2',
          name: 'Test 2',
          description: 'Test',
          icon: Icons.star,
          pointValue: 200,
        )..unlock(),
      ];
      when(mockService.getAllAchievements()).thenReturn(achievements);
      when(mockService.getUnlockedAchievements()).thenReturn([achievements[1]]);
      when(mockService.getLockedAchievements()).thenReturn([achievements[0]]);
      when(mockService.getTotalPoints()).thenReturn(200);

      // When
      await tester.pumpWidget(createTestWidget());

      // Then
      expect(find.textContaining('50%'), findsOneWidget); // Completion percentage
      expect(find.text('200'), findsWidgets); // Total points (also appears in chip)
      expect(find.textContaining('1/2'), findsOneWidget); // Unlocked count
    });
  });

  group('AchievementsScreen - Unlocked Achievements', () {
    testWidgets('givenUnlockedAchievement_whenDisplayed_thenShowsNameAndDate',
        (WidgetTester tester) async {
      // Given
      final timestamp = DateTime(2025, 11, 17, 15, 30);
      final achievement = Achievement(
        id: 'test',
        name: 'Test Achievement',
        description: 'Test Description',
        icon: Icons.emoji_events,
        pointValue: 250,
      )..unlockedDate = timestamp;

      when(mockService.getAllAchievements()).thenReturn([achievement]);
      when(mockService.getUnlockedAchievements()).thenReturn([achievement]);
      when(mockService.getLockedAchievements()).thenReturn([]);
      when(mockService.getTotalPoints()).thenReturn(250);

      // When
      await tester.pumpWidget(createTestWidget());

      // Then
      expect(find.text('Test Achievement'), findsOneWidget);
      expect(find.text('Test Description'), findsOneWidget);
      expect(find.text('250 points'), findsOneWidget);
      expect(find.textContaining('11/17/2025'), findsOneWidget);
    });

    testWidgets('givenMultipleUnlocked_whenDisplayed_thenSortedByDateDesc',
        (WidgetTester tester) async {
      // Given
      final old = Achievement(
        id: 'old',
        name: 'Old Achievement',
        description: 'Test',
        icon: Icons.star,
        pointValue: 100,
      )..unlockedDate = DateTime(2025, 11, 15);

      final recent = Achievement(
        id: 'recent',
        name: 'Recent Achievement',
        description: 'Test',
        icon: Icons.star,
        pointValue: 100,
      )..unlockedDate = DateTime(2025, 11, 17);

      when(mockService.getAllAchievements()).thenReturn([old, recent]);
      when(mockService.getUnlockedAchievements()).thenReturn([old, recent]);
      when(mockService.getLockedAchievements()).thenReturn([]);
      when(mockService.getTotalPoints()).thenReturn(200);

      // When
      await tester.pumpWidget(createTestWidget());

      // Then - Recent should appear before old
      final listTiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
      expect(listTiles.length, greaterThanOrEqualTo(2));

      // First unlocked achievement should be "Recent Achievement"
      final firstTitle = (listTiles[0].title as Text).data;
      expect(firstTitle, contains('Recent Achievement'));
    });
  });

  group('AchievementsScreen - Locked Achievements', () {
    testWidgets('givenLockedAchievement_whenDisplayed_thenShowsProgressBar',
        (WidgetTester tester) async {
      // Given
      final achievement = Achievement(
        id: 'test',
        name: 'Locked Achievement',
        description: 'Complete 10 levels',
        icon: Icons.lock,
        pointValue: 500,
        progress: 50,
      );

      when(mockService.getAllAchievements()).thenReturn([achievement]);
      when(mockService.getUnlockedAchievements()).thenReturn([]);
      when(mockService.getLockedAchievements()).thenReturn([achievement]);
      when(mockService.getTotalPoints()).thenReturn(0);

      // When
      await tester.pumpWidget(createTestWidget());

      // Then
      expect(find.text('Locked Achievement'), findsOneWidget);
      expect(find.text('Complete 10 levels'), findsOneWidget);
      expect(find.text('500 points'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('givenMultipleLocked_whenDisplayed_thenSortedByProgressDesc',
        (WidgetTester tester) async {
      // Given
      final lowProgress = Achievement(
        id: 'low',
        name: 'Low Progress',
        description: 'Test',
        icon: Icons.star,
        pointValue: 100,
        progress: 25,
      );

      final highProgress = Achievement(
        id: 'high',
        name: 'High Progress',
        description: 'Test',
        icon: Icons.star,
        pointValue: 100,
        progress: 75,
      );

      when(mockService.getAllAchievements()).thenReturn([lowProgress, highProgress]);
      when(mockService.getUnlockedAchievements()).thenReturn([]);
      when(mockService.getLockedAchievements()).thenReturn([lowProgress, highProgress]);
      when(mockService.getTotalPoints()).thenReturn(0);

      // When
      await tester.pumpWidget(createTestWidget());

      // Then - High progress should appear first
      final progressIndicators = tester.widgetList<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      ).toList();

      expect(progressIndicators.length, equals(2));
      expect(progressIndicators[0].value, equals(0.75)); // High progress first
      expect(progressIndicators[1].value, equals(0.25)); // Low progress second
    });
  });

  group('AchievementsScreen - Mixed Display', () {
    testWidgets('givenMixedAchievements_whenDisplayed_thenUnlockedFirstThenLocked',
        (WidgetTester tester) async {
      // Given
      final unlocked = Achievement(
        id: 'unlocked',
        name: 'Unlocked Achievement',
        description: 'Test',
        icon: Icons.check,
        pointValue: 100,
      )..unlock();

      final locked = Achievement(
        id: 'locked',
        name: 'Locked Achievement',
        description: 'Test',
        icon: Icons.lock,
        pointValue: 100,
        progress: 50,
      );

      when(mockService.getAllAchievements()).thenReturn([locked, unlocked]);
      when(mockService.getUnlockedAchievements()).thenReturn([unlocked]);
      when(mockService.getLockedAchievements()).thenReturn([locked]);
      when(mockService.getTotalPoints()).thenReturn(100);

      // When
      await tester.pumpWidget(createTestWidget());

      // Then - Unlocked section should come before locked section
      expect(find.text('Unlocked (1)'), findsOneWidget);
      expect(find.text('Locked (1)'), findsOneWidget);

      final unlockedHeader = tester.getTopLeft(find.text('Unlocked (1)'));
      final lockedHeader = tester.getTopLeft(find.text('Locked (1)'));

      expect(unlockedHeader.dy, lessThan(lockedHeader.dy));
    });
  });

  group('AchievementsScreen - Navigation', () {
    testWidgets('givenBackButton_whenTapped_thenNavigatesBack',
        (WidgetTester tester) async {
      // Given
      when(mockService.getAllAchievements()).thenReturn([]);
      when(mockService.getUnlockedAchievements()).thenReturn([]);
      when(mockService.getLockedAchievements()).thenReturn([]);
      when(mockService.getTotalPoints()).thenReturn(0);

      // Create navigation stack
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider<AchievementService>.value(
                          value: mockService,
                          child: const AchievementsScreen(),
                        ),
                      ),
                    );
                  },
                  child: const Text('Open Achievements'),
                ),
              ),
            ),
          ),
        ),
      );

      // Navigate to achievements screen
      await tester.tap(find.text('Open Achievements'));
      await tester.pumpAndSettle();

      // Verify we're on the achievements screen
      expect(find.byType(AchievementsScreen), findsOneWidget);

      // When - Tap back button
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Then - Should navigate back
      expect(find.byType(AchievementsScreen), findsNothing);
      expect(find.text('Open Achievements'), findsOneWidget);
    });
  });
}
