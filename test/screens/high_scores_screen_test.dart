import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:pachinko_game/models/high_score.dart';
import 'package:pachinko_game/screens/high_scores_screen.dart';
import 'package:pachinko_game/services/storage_service.dart';

import 'high_scores_screen_test.mocks.dart';

// Generate mocks for StorageService
@GenerateMocks([StorageService])
void main() {
  late MockStorageService mockStorageService;

  setUp(() {
    mockStorageService = MockStorageService();
  });

  Widget createTestWidget() {
    return MaterialApp(
      home: Provider<StorageService?>.value(
        value: mockStorageService,
        child: HighScoresScreen(),
      ),
    );
  }

  group('HighScoresScreen - UI Rendering', () {
    testWidgets('givenHighScoresScreen_whenRendered_thenTitleDisplayed',
        (WidgetTester tester) async {
      // Given
      for (int i = 1; i <= 20; i++) {
        when(mockStorageService.getHighScores(i)).thenAnswer((_) async => []);
      }

      // When
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.text('High Scores'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('givenStoredScores_whenScreenLoaded_thenScoresListDisplayed',
        (WidgetTester tester) async {
      // Given
      final scores = [
        HighScore(level: 1, score: 5000, timestamp: DateTime(2025, 11, 17)),
        HighScore(level: 2, score: 7000, timestamp: DateTime(2025, 11, 16)),
      ];

      when(mockStorageService.getHighScores(1)).thenAnswer((_) async => [scores[0]]);
      when(mockStorageService.getHighScores(2)).thenAnswer((_) async => [scores[1]]);
      for (int i = 3; i <= 20; i++) {
        when(mockStorageService.getHighScores(i)).thenAnswer((_) async => []);
      }

      // When
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.text('5000 points'), findsOneWidget);
      expect(find.text('7000 points'), findsOneWidget);
      expect(find.byType(ListTile), findsNWidgets(2));
    });

    testWidgets('givenNoScores_whenScreenLoaded_thenEmptyStateDisplayed',
        (WidgetTester tester) async {
      // Given
      for (int i = 1; i <= 20; i++) {
        when(mockStorageService.getHighScores(i)).thenAnswer((_) async => []);
      }

      // When
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.textContaining('No high scores yet!'), findsOneWidget);
      expect(find.textContaining('Play to set your first record'), findsOneWidget);
    });
  });

  group('HighScoresScreen - Score Display', () {
    testWidgets('givenMultipleScores_whenDisplayed_thenSortedByScoreDescending',
        (WidgetTester tester) async {
      // Given
      final scores = [
        HighScore(level: 1, score: 3000, timestamp: DateTime(2025, 11, 15)),
        HighScore(level: 2, score: 9000, timestamp: DateTime(2025, 11, 17)),
        HighScore(level: 3, score: 5000, timestamp: DateTime(2025, 11, 16)),
      ];

      when(mockStorageService.getHighScores(1)).thenAnswer((_) async => [scores[0]]);
      when(mockStorageService.getHighScores(2)).thenAnswer((_) async => [scores[1]]);
      when(mockStorageService.getHighScores(3)).thenAnswer((_) async => [scores[2]]);
      for (int i = 4; i <= 20; i++) {
        when(mockStorageService.getHighScores(i)).thenAnswer((_) async => []);
      }

      // When
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Then - Verify sorted order (highest first)
      final listTiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
      expect(listTiles.length, equals(3));

      // First item should be 9000 points
      final firstTitle = (listTiles[0].title as Text).data;
      expect(firstTitle, contains('9000'));

      // Second item should be 5000 points
      final secondTitle = (listTiles[1].title as Text).data;
      expect(secondTitle, contains('5000'));

      // Third item should be 3000 points
      final thirdTitle = (listTiles[2].title as Text).data;
      expect(thirdTitle, contains('3000'));
    });

    testWidgets('givenScoreEntry_whenRendered_thenShowsLevelScoreTimestamp',
        (WidgetTester tester) async {
      // Given
      final timestamp = DateTime(2025, 11, 17, 15, 30);
      final score = HighScore(level: 5, score: 8500, timestamp: timestamp);

      when(mockStorageService.getHighScores(5)).thenAnswer((_) async => [score]);
      for (int i = 1; i <= 20; i++) {
        if (i != 5) {
          when(mockStorageService.getHighScores(i)).thenAnswer((_) async => []);
        }
      }

      // When
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.text('5'), findsOneWidget); // Level in CircleAvatar
      expect(find.text('8500 points'), findsOneWidget); // Score
      expect(find.textContaining('11/17/2025'), findsOneWidget); // Timestamp
    });
  });

  group('HighScoresScreen - Clear Data Button', () {
    testWidgets('givenClearButton_whenTapped_thenConfirmationDialogShown',
        (WidgetTester tester) async {
      // Given
      for (int i = 1; i <= 20; i++) {
        when(mockStorageService.getHighScores(i)).thenAnswer((_) async => []);
      }

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // When
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      // Then
      expect(find.text('Clear All Scores?'), findsOneWidget);
      expect(find.text('This will delete all high score data permanently.'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
    });

    testWidgets('givenConfirmation_whenCleared_thenScoresRemoved',
        (WidgetTester tester) async {
      // Given
      final score = HighScore(level: 1, score: 5000, timestamp: DateTime.now());
      when(mockStorageService.getHighScores(1)).thenAnswer((_) async => [score]);
      for (int i = 2; i <= 20; i++) {
        when(mockStorageService.getHighScores(i)).thenAnswer((_) async => []);
      }
      when(mockStorageService.clearData()).thenAnswer((_) async => {});

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // When - Tap clear button and confirm
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      // Then
      verify(mockStorageService.clearData()).called(1);
    });
  });

  group('HighScoresScreen - Navigation', () {
    testWidgets('givenBackButton_whenTapped_thenNavigatesToMenu',
        (WidgetTester tester) async {
      // Given
      for (int i = 1; i <= 20; i++) {
        when(mockStorageService.getHighScores(i)).thenAnswer((_) async => []);
      }

      // Create test widget with navigation stack
      await tester.pumpWidget(
        Provider<StorageService?>.value(
          value: mockStorageService,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => HighScoresScreen()),
                      );
                    },
                    child: const Text('Open High Scores'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Navigate to high scores screen
      await tester.tap(find.text('Open High Scores'));
      await tester.pumpAndSettle();

      // Verify we're on the high scores screen
      expect(find.byType(HighScoresScreen), findsOneWidget);

      // When - Tap back button
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Then - Screen should pop (back to home)
      expect(find.byType(HighScoresScreen), findsNothing);
      expect(find.text('Open High Scores'), findsOneWidget);
    });
  });
}
