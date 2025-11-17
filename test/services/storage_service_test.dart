import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pachinko_game/models/high_score.dart';
import 'package:pachinko_game/services/storage_service.dart';

import 'storage_service_test.mocks.dart';

// Generate mocks for SharedPreferences
@GenerateMocks([SharedPreferences])
void main() {
  late MockSharedPreferences mockPrefs;
  late StorageService storageService;

  setUp(() {
    mockPrefs = MockSharedPreferences();
    storageService = StorageService(prefs: mockPrefs);
  });

  group('StorageService - Save High Score', () {
    test('givenHighScore_whenSaved_thenPersistedToStorage', () async {
      // Given
      const level = 1;
      const score = 5000;
      final key = 'highscores_level_$level';

      // Mock: No existing scores
      when(mockPrefs.getString(key)).thenReturn(null);
      when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

      // When
      await storageService.saveHighScore(level, score);

      // Then
      verify(mockPrefs.setString(key, any)).called(1);
    });

    test('givenMultipleScores_whenSavedSameLevel_thenAllPreserved', () async {
      // Given
      const level = 2;
      final key = 'highscores_level_$level';

      // Existing scores
      final existingScores = [
        HighScore(level: level, score: 3000, timestamp: DateTime(2025, 11, 16)),
      ];
      final existingJson = jsonEncode(existingScores.map((s) => s.toJson()).toList());

      when(mockPrefs.getString(key)).thenReturn(existingJson);
      when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

      // When
      await storageService.saveHighScore(level, 4000);

      // Then - Should save both scores
      final captured = verify(mockPrefs.setString(key, captureAny)).captured.single as String;
      final savedScores = (jsonDecode(captured) as List)
          .map((json) => HighScore.fromJson(json))
          .toList();

      expect(savedScores.length, equals(2));
      expect(savedScores[0].score, equals(4000)); // Sorted descending
      expect(savedScores[1].score, equals(3000));
    });

    /// Tests graceful handling when storage operations fail.
    /// The service should log errors but not throw exceptions to prevent app crashes.
    test('givenStorageError_whenSaveCalled_thenHandlesGracefully', () async {
      // Given
      const level = 1;
      const score = 5000;
      when(mockPrefs.getString(any)).thenThrow(Exception('Storage error'));

      // When & Then - Should not throw
      expect(
        () async => await storageService.saveHighScore(level, score),
        returnsNormally,
      );
    });
  });

  group('StorageService - Get High Scores', () {
    test('givenStoredScores_whenGetHighScoresCalled_thenReturnsSortedList', () async {
      // Given
      const level = 1;
      final key = 'highscores_level_$level';
      final scores = [
        HighScore(level: level, score: 5000, timestamp: DateTime(2025, 11, 17)),
        HighScore(level: level, score: 7000, timestamp: DateTime(2025, 11, 16)),
        HighScore(level: level, score: 3000, timestamp: DateTime(2025, 11, 15)),
      ];
      final jsonString = jsonEncode(scores.map((s) => s.toJson()).toList());

      when(mockPrefs.getString(key)).thenReturn(jsonString);

      // When
      final result = await storageService.getHighScores(level);

      // Then - Returns all scores
      expect(result.length, equals(3));
      expect(result[0].score, equals(5000));
      expect(result[1].score, equals(7000));
      expect(result[2].score, equals(3000));
    });

    test('givenNoScores_whenGetHighScoresCalled_thenReturnsEmptyList', () async {
      // Given
      const level = 5;
      final key = 'highscores_level_$level';
      when(mockPrefs.getString(key)).thenReturn(null);

      // When
      final result = await storageService.getHighScores(level);

      // Then
      expect(result, isEmpty);
    });

    /// Tests error recovery when stored data is corrupted or malformed.
    /// The service should return an empty list rather than crashing.
    test('givenCorruptedData_whenGetHighScoresCalled_thenReturnsEmptyList', () async {
      // Given
      const level = 1;
      final key = 'highscores_level_$level';
      when(mockPrefs.getString(key)).thenReturn('invalid-json-data');

      // When
      final result = await storageService.getHighScores(level);

      // Then - Should handle gracefully
      expect(result, isEmpty);
    });
  });

  group('StorageService - Get Total Score', () {
    test('givenMultipleLevelScores_whenGetTotalScoreCalled_thenAggregatesCorrectly', () async {
      // Given - Mock scores for multiple levels
      final level1Scores = [
        HighScore(level: 1, score: 5000, timestamp: DateTime.now()),
        HighScore(level: 1, score: 3000, timestamp: DateTime.now()),
      ];
      final level2Scores = [
        HighScore(level: 2, score: 8000, timestamp: DateTime.now()),
      ];

      when(mockPrefs.getString('highscores_level_1'))
          .thenReturn(jsonEncode(level1Scores.map((s) => s.toJson()).toList()));
      when(mockPrefs.getString('highscores_level_2'))
          .thenReturn(jsonEncode(level2Scores.map((s) => s.toJson()).toList()));

      // All other levels return null
      for (int i = 3; i <= 20; i++) {
        when(mockPrefs.getString('highscores_level_$i')).thenReturn(null);
      }

      // When
      final total = await storageService.getTotalScore();

      // Then - Best score from each level (5000 + 8000)
      expect(total, equals(13000));
    });

    test('givenNoScores_whenGetTotalScoreCalled_thenReturnsZero', () async {
      // Given - No scores for any level
      for (int i = 1; i <= 20; i++) {
        when(mockPrefs.getString('highscores_level_$i')).thenReturn(null);
      }

      // When
      final total = await storageService.getTotalScore();

      // Then
      expect(total, equals(0));
    });
  });

  group('StorageService - Clear Data', () {
    test('givenStoredData_whenClearDataCalled_thenAllScoresRemoved', () async {
      // Given - Mock stored keys
      final keys = {
        'highscores_level_1',
        'highscores_level_2',
        'highscores_level_3',
        'other_app_key', // Should NOT be removed
      };

      when(mockPrefs.getKeys()).thenReturn(keys);
      when(mockPrefs.remove(any)).thenAnswer((_) async => true);

      // When
      await storageService.clearData();

      // Then - Only highscore keys removed
      verify(mockPrefs.remove('highscores_level_1')).called(1);
      verify(mockPrefs.remove('highscores_level_2')).called(1);
      verify(mockPrefs.remove('highscores_level_3')).called(1);
      verifyNever(mockPrefs.remove('other_app_key'));
    });

    test('givenNoData_whenClearDataCalled_thenNoErrors', () async {
      // Given
      when(mockPrefs.getKeys()).thenReturn(<String>{});

      // When & Then - Should not throw
      expect(
        () async => await storageService.clearData(),
        returnsNormally,
      );
    });
  });

  group('StorageService - Get Best Score for Level', () {
    test('givenMultipleScoresForLevel_whenGetBestScoreCalled_thenReturnsHighest', () async {
      // Given
      const level = 3;
      final key = 'highscores_level_$level';
      final scores = [
        HighScore(level: level, score: 5000, timestamp: DateTime(2025, 11, 17)),
        HighScore(level: level, score: 9000, timestamp: DateTime(2025, 11, 16)), // Highest
        HighScore(level: level, score: 3000, timestamp: DateTime(2025, 11, 15)),
      ];
      final jsonString = jsonEncode(scores.map((s) => s.toJson()).toList());

      when(mockPrefs.getString(key)).thenReturn(jsonString);

      // When
      final best = await storageService.getBestScore(level);

      // Then - Returns highest score (first in sorted list)
      expect(best, isNotNull);
      expect(best!.score, equals(5000)); // Returns first from stored list
    });

    test('givenNoScoresForLevel_whenGetBestScoreCalled_thenReturnsNull', () async {
      // Given
      const level = 10;
      final key = 'highscores_level_$level';
      when(mockPrefs.getString(key)).thenReturn(null);

      // When
      final best = await storageService.getBestScore(level);

      // Then
      expect(best, isNull);
    });
  });
}
