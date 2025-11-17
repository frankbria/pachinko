import 'package:flutter_test/flutter_test.dart';
import 'package:pachinko_game/models/high_score.dart';

void main() {
  group('HighScore Model Initialization', () {
    test('givenHighScoreData_whenCreated_thenFieldsSetCorrectly', () {
      // Given
      const level = 1;
      const score = 5000;
      final timestamp = DateTime(2025, 11, 17, 15, 30);

      // When
      final highScore = HighScore(
        level: level,
        score: score,
        timestamp: timestamp,
      );

      // Then
      expect(highScore.level, equals(level));
      expect(highScore.score, equals(score));
      expect(highScore.timestamp, equals(timestamp));
    });

    test('givenNoData_whenDefaultConstructor_thenTimestampInitialized', () {
      // Given
      const level = 2;
      const score = 3000;
      final beforeCreation = DateTime.now();

      // When
      final highScore = HighScore(
        level: level,
        score: score,
      );

      // Then
      expect(highScore.level, equals(level));
      expect(highScore.score, equals(score));
      expect(highScore.timestamp.isAfter(beforeCreation) ||
          highScore.timestamp.isAtSameMomentAs(beforeCreation), isTrue);
      expect(highScore.timestamp.isBefore(DateTime.now().add(Duration(seconds: 1))), isTrue);
    });
  });

  group('HighScore JSON Serialization', () {
    test('givenHighScoreInstance_whenToJsonCalled_thenValidJsonReturned', () {
      // Given
      final timestamp = DateTime(2025, 11, 17, 15, 30);
      final highScore = HighScore(
        level: 3,
        score: 7500,
        timestamp: timestamp,
      );

      // When
      final json = highScore.toJson();

      // Then
      expect(json, isA<Map<String, dynamic>>());
      expect(json['level'], equals(3));
      expect(json['score'], equals(7500));
      expect(json['timestamp'], equals(timestamp.toIso8601String()));
    });

    test('givenValidJson_whenFromJsonCalled_thenHighScoreCreated', () {
      // Given
      final timestamp = DateTime(2025, 11, 17, 15, 30);
      final json = {
        'level': 5,
        'score': 12000,
        'timestamp': timestamp.toIso8601String(),
      };

      // When
      final highScore = HighScore.fromJson(json);

      // Then
      expect(highScore.level, equals(5));
      expect(highScore.score, equals(12000));
      expect(highScore.timestamp, equals(timestamp));
    });

    /// Tests deserialization behavior when JSON data is malformed or missing required fields.
    /// This is critical for handling corrupted storage data gracefully without crashing the app.
    test('givenInvalidJson_whenFromJsonCalled_thenThrowsFormatException', () {
      // Given - Missing 'level' field
      final invalidJson = {
        'score': 5000,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // When & Then
      expect(
        () => HighScore.fromJson(invalidJson),
        throwsA(isA<TypeError>()),
      );

      // Given - Invalid timestamp format
      final invalidTimestampJson = {
        'level': 1,
        'score': 5000,
        'timestamp': 'not-a-valid-timestamp',
      };

      // When & Then
      expect(
        () => HighScore.fromJson(invalidTimestampJson),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('HighScore Comparison and Sorting', () {
    test('givenTwoHighScores_whenCompared_thenSortedByScoreDescending', () {
      // Given
      final highScore1 = HighScore(level: 1, score: 5000);
      final highScore2 = HighScore(level: 1, score: 7000);

      // When
      final comparison = highScore1.compareTo(highScore2);

      // Then - highScore2 should come before highScore1 (higher score = lower sort order)
      expect(comparison, greaterThan(0)); // 5000 < 7000, so highScore1 comes after
    });

    test('givenHighScoreList_whenSorted_thenHighestScoreFirst', () {
      // Given
      final scores = [
        HighScore(level: 1, score: 3000),
        HighScore(level: 2, score: 8000),
        HighScore(level: 1, score: 5000),
        HighScore(level: 3, score: 12000),
        HighScore(level: 2, score: 4000),
      ];

      // When
      scores.sort((a, b) => a.compareTo(b));

      // Then - Sorted descending by score
      expect(scores[0].score, equals(12000));
      expect(scores[1].score, equals(8000));
      expect(scores[2].score, equals(5000));
      expect(scores[3].score, equals(4000));
      expect(scores[4].score, equals(3000));
    });
  });

  group('HighScore String Representation', () {
    test('givenHighScore_whenToStringCalled_thenReturnsFormattedString', () {
      // Given
      final timestamp = DateTime(2025, 11, 17, 15, 30);
      final highScore = HighScore(
        level: 3,
        score: 8500,
        timestamp: timestamp,
      );

      // When
      final stringRepresentation = highScore.toString();

      // Then
      expect(stringRepresentation, contains('HighScore'));
      expect(stringRepresentation, contains('level: 3'));
      expect(stringRepresentation, contains('score: 8500'));
      expect(stringRepresentation, contains('timestamp:'));
    });
  });

  group('HighScore Equality', () {
    test('givenSameData_whenCompared_thenHighScoresEqual', () {
      // Given
      final timestamp = DateTime(2025, 11, 17, 15, 30);
      final highScore1 = HighScore(
        level: 1,
        score: 5000,
        timestamp: timestamp,
      );
      final highScore2 = HighScore(
        level: 1,
        score: 5000,
        timestamp: timestamp,
      );

      // When & Then
      expect(highScore1, equals(highScore2));
      expect(highScore1.hashCode, equals(highScore2.hashCode));
    });

    test('givenDifferentData_whenCompared_thenHighScoresNotEqual', () {
      // Given
      final timestamp = DateTime(2025, 11, 17, 15, 30);
      final highScore1 = HighScore(
        level: 1,
        score: 5000,
        timestamp: timestamp,
      );
      final highScore2 = HighScore(
        level: 1,
        score: 6000, // Different score
        timestamp: timestamp,
      );
      final highScore3 = HighScore(
        level: 2, // Different level
        score: 5000,
        timestamp: timestamp,
      );

      // When & Then
      expect(highScore1, isNot(equals(highScore2)));
      expect(highScore1, isNot(equals(highScore3)));
      expect(highScore1.hashCode, isNot(equals(highScore2.hashCode)));
    });
  });
}
