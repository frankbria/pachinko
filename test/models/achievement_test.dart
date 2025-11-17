import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pachinko_game/models/achievement.dart';

void main() {
  group('Achievement Model Initialization', () {
    test('givenAchievementData_whenCreated_thenFieldsSetCorrectly', () {
      // Given
      const id = 'test_achievement';
      const name = 'Test Achievement';
      const description = 'Test Description';
      const icon = Icons.star;
      const pointValue = 100;

      // When
      final achievement = Achievement(
        id: id,
        name: name,
        description: description,
        icon: icon,
        pointValue: pointValue,
      );

      // Then
      expect(achievement.id, equals(id));
      expect(achievement.name, equals(name));
      expect(achievement.description, equals(description));
      expect(achievement.icon, equals(icon));
      expect(achievement.pointValue, equals(pointValue));
      expect(achievement.progress, equals(0));
      expect(achievement.unlockedDate, isNull);
    });

    test('givenAchievementNotUnlocked_whenCreated_thenUnlockedDateIsNull', () {
      // Given & When
      final achievement = Achievement(
        id: 'test',
        name: 'Test',
        description: 'Test',
        icon: Icons.star,
        pointValue: 100,
      );

      // Then
      expect(achievement.unlockedDate, isNull);
      expect(achievement.isUnlocked, isFalse);
    });
  });

  group('Achievement JSON Serialization', () {
    test('givenAchievementInstance_whenToJsonCalled_thenValidJsonReturned', () {
      // Given
      final timestamp = DateTime(2025, 11, 17, 15, 30);
      final achievement = Achievement(
        id: 'test_id',
        name: 'Test Name',
        description: 'Test Description',
        icon: Icons.emoji_events,
        pointValue: 250,
        progress: 50,
        unlockedDate: timestamp,
      );

      // When
      final json = achievement.toJson();

      // Then
      expect(json, isA<Map<String, dynamic>>());
      expect(json['id'], equals('test_id'));
      expect(json['name'], equals('Test Name'));
      expect(json['description'], equals('Test Description'));
      expect(json['iconCodePoint'], equals(Icons.emoji_events.codePoint));
      expect(json['pointValue'], equals(250));
      expect(json['progress'], equals(50));
      expect(json['unlockedDate'], equals(timestamp.toIso8601String()));
    });

    test('givenValidJson_whenFromJsonCalled_thenAchievementCreated', () {
      // Given
      final timestamp = DateTime(2025, 11, 17, 15, 30);
      final json = {
        'id': 'test_id',
        'name': 'Test Name',
        'description': 'Test Description',
        'iconCodePoint': Icons.star.codePoint,
        'pointValue': 500,
        'progress': 75,
        'unlockedDate': timestamp.toIso8601String(),
      };

      // When
      final achievement = Achievement.fromJson(json);

      // Then
      expect(achievement.id, equals('test_id'));
      expect(achievement.name, equals('Test Name'));
      expect(achievement.description, equals('Test Description'));
      expect(achievement.icon.codePoint, equals(Icons.star.codePoint));
      expect(achievement.pointValue, equals(500));
      expect(achievement.progress, equals(75));
      expect(achievement.unlockedDate, equals(timestamp));
    });

    test('givenJsonWithoutUnlockedDate_whenFromJsonCalled_thenAchievementNotUnlocked', () {
      // Given
      final json = {
        'id': 'test_id',
        'name': 'Test Name',
        'description': 'Test Description',
        'iconCodePoint': Icons.star.codePoint,
        'pointValue': 100,
        'progress': 25,
        'unlockedDate': null,
      };

      // When
      final achievement = Achievement.fromJson(json);

      // Then
      expect(achievement.unlockedDate, isNull);
      expect(achievement.isUnlocked, isFalse);
      expect(achievement.progress, equals(25));
    });
  });

  group('Achievement Progress Tracking', () {
    /// Tests progress update logic ensuring values are clamped between 0-100
    /// and achievements auto-unlock at 100% progress.
    test('givenAchievement_whenProgressUpdated_thenProgressValueChanges', () {
      // Given
      final achievement = Achievement(
        id: 'test',
        name: 'Test',
        description: 'Test',
        icon: Icons.star,
        pointValue: 100,
      );

      // When
      achievement.updateProgress(50);

      // Then
      expect(achievement.progress, equals(50));
      expect(achievement.isUnlocked, isFalse);
    });

    test('givenAchievement_whenProgressReaches100_thenAchievementUnlocked', () {
      // Given
      final achievement = Achievement(
        id: 'test',
        name: 'Test',
        description: 'Test',
        icon: Icons.star,
        pointValue: 100,
      );
      final beforeUpdate = DateTime.now();

      // When
      achievement.updateProgress(100);

      // Then
      expect(achievement.progress, equals(100));
      expect(achievement.isUnlocked, isTrue);
      expect(achievement.unlockedDate, isNotNull);
      expect(achievement.unlockedDate!.isAfter(beforeUpdate) ||
          achievement.unlockedDate!.isAtSameMomentAs(beforeUpdate), isTrue);
    });

    /// Tests that progress updates to unlocked achievements have no effect,
    /// preventing data corruption or unintended state changes.
    test('givenUnlockedAchievement_whenProgressUpdated_thenNoChangeOccurs', () {
      // Given
      final achievement = Achievement(
        id: 'test',
        name: 'Test',
        description: 'Test',
        icon: Icons.star,
        pointValue: 100,
      );
      achievement.unlock();
      final originalDate = achievement.unlockedDate;

      // When - Try to update progress on unlocked achievement
      achievement.updateProgress(50);

      // Then - No changes occur
      expect(achievement.progress, equals(100));
      expect(achievement.unlockedDate, equals(originalDate));
      expect(achievement.isUnlocked, isTrue);
    });

    test('givenProgressValue_whenUpdatedAbove100_thenClampedTo100', () {
      // Given
      final achievement = Achievement(
        id: 'test',
        name: 'Test',
        description: 'Test',
        icon: Icons.star,
        pointValue: 100,
      );

      // When
      achievement.updateProgress(150);

      // Then
      expect(achievement.progress, equals(100));
      expect(achievement.isUnlocked, isTrue);
    });

    test('givenProgressValue_whenUpdatedBelow0_thenClampedTo0', () {
      // Given
      final achievement = Achievement(
        id: 'test',
        name: 'Test',
        description: 'Test',
        icon: Icons.star,
        pointValue: 100,
        progress: 50,
      );

      // When
      achievement.updateProgress(-10);

      // Then
      expect(achievement.progress, equals(0));
      expect(achievement.isUnlocked, isFalse);
    });
  });

  group('Achievement Unlock Logic', () {
    test('givenLockedAchievement_whenUnlockCalled_thenUnlockedDateSet', () {
      // Given
      final achievement = Achievement(
        id: 'test',
        name: 'Test',
        description: 'Test',
        icon: Icons.star,
        pointValue: 100,
      );
      final beforeUnlock = DateTime.now();

      // When
      achievement.unlock();

      // Then
      expect(achievement.unlockedDate, isNotNull);
      expect(achievement.unlockedDate!.isAfter(beforeUnlock) ||
          achievement.unlockedDate!.isAtSameMomentAs(beforeUnlock), isTrue);
    });

    test('givenLockedAchievement_whenUnlockCalled_thenIsUnlockedTrue', () {
      // Given
      final achievement = Achievement(
        id: 'test',
        name: 'Test',
        description: 'Test',
        icon: Icons.star,
        pointValue: 100,
      );

      // When
      achievement.unlock();

      // Then
      expect(achievement.isUnlocked, isTrue);
      expect(achievement.progress, equals(100));
    });

    test('givenAlreadyUnlocked_whenUnlockCalled_thenNoEffect', () async {
      // Given
      final achievement = Achievement(
        id: 'test',
        name: 'Test',
        description: 'Test',
        icon: Icons.star,
        pointValue: 100,
      );
      achievement.unlock();
      final originalDate = achievement.unlockedDate;

      // Wait a tiny bit to ensure time difference if date changes
      await Future.delayed(Duration(milliseconds: 1));

      // When
      achievement.unlock();

      // Then - Date should not change
      expect(achievement.unlockedDate, equals(originalDate));
    });
  });

  group('Achievement Equality', () {
    test('givenSameData_whenCompared_thenAchievementsEqual', () {
      // Given
      final timestamp = DateTime(2025, 11, 17, 15, 30);
      final achievement1 = Achievement(
        id: 'test',
        name: 'Test',
        description: 'Test',
        icon: Icons.star,
        pointValue: 100,
        progress: 50,
        unlockedDate: timestamp,
      );
      final achievement2 = Achievement(
        id: 'test',
        name: 'Test',
        description: 'Test',
        icon: Icons.star,
        pointValue: 100,
        progress: 50,
        unlockedDate: timestamp,
      );

      // When & Then
      expect(achievement1, equals(achievement2));
      expect(achievement1.hashCode, equals(achievement2.hashCode));
    });

    test('givenDifferentData_whenCompared_thenAchievementsNotEqual', () {
      // Given
      final timestamp = DateTime(2025, 11, 17, 15, 30);
      final achievement1 = Achievement(
        id: 'test1',
        name: 'Test',
        description: 'Test',
        icon: Icons.star,
        pointValue: 100,
        progress: 50,
        unlockedDate: timestamp,
      );
      final achievement2 = Achievement(
        id: 'test2', // Different ID
        name: 'Test',
        description: 'Test',
        icon: Icons.star,
        pointValue: 100,
        progress: 50,
        unlockedDate: timestamp,
      );
      final achievement3 = Achievement(
        id: 'test1',
        name: 'Test',
        description: 'Test',
        icon: Icons.star,
        pointValue: 100,
        progress: 75, // Different progress
        unlockedDate: timestamp,
      );

      // When & Then
      expect(achievement1, isNot(equals(achievement2)));
      expect(achievement1, isNot(equals(achievement3)));
    });
  });
}
