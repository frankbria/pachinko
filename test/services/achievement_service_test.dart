import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pachinko_game/models/achievement.dart';
import 'package:pachinko_game/services/achievement_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'achievement_service_test.mocks.dart';

// Generate mocks for SharedPreferences
@GenerateMocks([SharedPreferences])
void main() {
  late MockSharedPreferences mockPrefs;
  late AchievementService service;

  setUp(() {
    mockPrefs = MockSharedPreferences();
  });

  group('AchievementService Initialization', () {
    test('givenNoSavedData_whenInitialized_thenAllAchievementsLocked', () async {
      // Given
      when(mockPrefs.getStringList('achievements')).thenReturn(null);

      // When
      service = await AchievementService.create(mockPrefs);

      // Then
      expect(service.getAllAchievements().length, equals(18));
      expect(service.getUnlockedAchievements().isEmpty, isTrue);
      expect(service.getLockedAchievements().length, equals(18));
      expect(service.getTotalPoints(), equals(0));
    });

    test('givenSavedProgress_whenInitialized_thenProgressRestored', () async {
      // Given
      final savedData = [
        '{"id":"first_launch","name":"First Launch","description":"Launch your first ball","iconCodePoint":${Icons.rocket_launch.codePoint},"pointValue":100,"progress":100,"unlockedDate":"2025-11-17T15:30:00.000"}',
        '{"id":"novice_player","name":"Novice Player","description":"Complete level 5","iconCodePoint":${Icons.star.codePoint},"pointValue":250,"progress":50,"unlockedDate":null}',
      ];
      when(mockPrefs.getStringList('achievements')).thenReturn(savedData);

      // When
      service = await AchievementService.create(mockPrefs);

      // Then
      expect(service.getUnlockedAchievements().length, equals(1));
      expect(service.getUnlockedAchievements().first.id, equals('first_launch'));
      expect(service.getTotalPoints(), equals(100));

      final novice = service.getAllAchievements().firstWhere((a) => a.id == 'novice_player');
      expect(novice.progress, equals(50));
      expect(novice.isUnlocked, isFalse);
    });

    test('givenCorruptedData_whenInitialized_thenResetToDefaults', () async {
      // Given - Invalid JSON data
      when(mockPrefs.getStringList('achievements')).thenReturn(['invalid json']);

      // When
      service = await AchievementService.create(mockPrefs);

      // Then - Should gracefully recover with defaults
      expect(service.getAllAchievements().length, equals(18));
      expect(service.getUnlockedAchievements().isEmpty, isTrue);
    });
  });

  group('AchievementService Event Tracking - Ball Launch', () {
    test('givenFirstBallLaunch_whenTracked_thenFirstLaunchUnlocked', () async {
      // Given
      when(mockPrefs.getStringList('achievements')).thenReturn(null);
      when(mockPrefs.setStringList(any, any)).thenAnswer((_) async => true);
      service = await AchievementService.create(mockPrefs);

      Achievement? unlockedAchievement;
      service.onAchievementUnlocked = (achievement) {
        unlockedAchievement = achievement;
      };

      // When
      service.trackBallLaunched();

      // Then
      expect(unlockedAchievement, isNotNull);
      expect(unlockedAchievement!.id, equals('first_launch'));
      expect(service.getTotalPoints(), equals(100));
      verify(mockPrefs.setStringList('achievements', any)).called(1);
    });

    test('givenMultipleLaunches_whenTracked_thenFirstLaunchOnlyUnlockedOnce', () async {
      // Given
      when(mockPrefs.getStringList('achievements')).thenReturn(null);
      when(mockPrefs.setStringList(any, any)).thenAnswer((_) async => true);
      service = await AchievementService.create(mockPrefs);

      int unlockCount = 0;
      service.onAchievementUnlocked = (_) => unlockCount++;

      // When
      service.trackBallLaunched();
      service.trackBallLaunched();
      service.trackBallLaunched();

      // Then - Should only unlock once
      expect(unlockCount, equals(1));
      expect(service.getTotalPoints(), equals(100));
    });
  });

  group('AchievementService Event Tracking - Level Complete', () {
    test('givenLevel5Completed_whenTracked_thenNovicePlayerUnlocked', () async {
      // Given
      when(mockPrefs.getStringList('achievements')).thenReturn(null);
      when(mockPrefs.setStringList(any, any)).thenAnswer((_) async => true);
      service = await AchievementService.create(mockPrefs);

      Achievement? unlockedAchievement;
      service.onAchievementUnlocked = (achievement) {
        unlockedAchievement = achievement;
      };

      // When
      for (int i = 1; i <= 5; i++) {
        service.trackLevelComplete(i);
      }

      // Then
      expect(unlockedAchievement!.id, equals('novice_player'));
      expect(service.getTotalPoints(), equals(250));
    });

    test('givenLevel10Completed_whenTracked_thenAdvancedPlayerUnlocked', () async {
      // Given
      when(mockPrefs.getStringList('achievements')).thenReturn(null);
      when(mockPrefs.setStringList(any, any)).thenAnswer((_) async => true);
      service = await AchievementService.create(mockPrefs);

      Achievement? lastUnlocked;
      service.onAchievementUnlocked = (achievement) {
        lastUnlocked = achievement;
      };

      // When
      for (int i = 1; i <= 10; i++) {
        service.trackLevelComplete(i);
      }

      // Then
      expect(lastUnlocked!.id, equals('advanced_player'));
      expect(service.getUnlockedAchievements().length, greaterThanOrEqualTo(2)); // novice + advanced
    });

    test('given50LevelsCompleted_whenTracked_thenMarathonRunnerUnlocked', () async {
      // Given
      when(mockPrefs.getStringList('achievements')).thenReturn(null);
      when(mockPrefs.setStringList(any, any)).thenAnswer((_) async => true);
      service = await AchievementService.create(mockPrefs);

      List<Achievement> unlocked = [];
      service.onAchievementUnlocked = unlocked.add;

      // When
      for (int i = 1; i <= 50; i++) {
        service.trackLevelComplete(i);
      }

      // Then
      expect(unlocked.any((a) => a.id == 'marathon_runner'), isTrue);
    });
  });

  group('AchievementService Event Tracking - Scoring', () {
    test('givenLevelScore50000_whenTracked_thenHighRollerUnlocked', () async {
      // Given
      when(mockPrefs.getStringList('achievements')).thenReturn(null);
      when(mockPrefs.setStringList(any, any)).thenAnswer((_) async => true);
      service = await AchievementService.create(mockPrefs);

      Achievement? unlockedAchievement;
      service.onAchievementUnlocked = (achievement) {
        unlockedAchievement = achievement;
      };

      // When
      service.trackLevelScore(1, 50000);

      // Then
      expect(unlockedAchievement!.id, equals('high_roller'));
    });

    test('givenLevelScore100000_whenTracked_thenScoreMasterUnlocked', () async {
      // Given
      when(mockPrefs.getStringList('achievements')).thenReturn(null);
      when(mockPrefs.setStringList(any, any)).thenAnswer((_) async => true);
      service = await AchievementService.create(mockPrefs);

      Achievement? unlockedAchievement;
      service.onAchievementUnlocked = (achievement) {
        unlockedAchievement = achievement;
      };

      // When
      service.trackLevelScore(1, 100000);

      // Then
      expect(unlockedAchievement!.id, equals('score_master'));
    });

    test('givenTotalScore1Million_whenTracked_thenMillionaireUnlocked', () async {
      // Given
      when(mockPrefs.getStringList('achievements')).thenReturn(null);
      when(mockPrefs.setStringList(any, any)).thenAnswer((_) async => true);
      service = await AchievementService.create(mockPrefs);

      List<Achievement> unlocked = [];
      service.onAchievementUnlocked = unlocked.add;

      // When
      for (int i = 0; i < 100; i++) {
        service.trackLevelScore(i, 10000);
      }

      // Then
      expect(unlocked.any((a) => a.id == 'millionaire'), isTrue);
    });

    test('given10Levels10000Plus_whenTracked_thenPointCollectorUnlocked', () async {
      // Given
      when(mockPrefs.getStringList('achievements')).thenReturn(null);
      when(mockPrefs.setStringList(any, any)).thenAnswer((_) async => true);
      service = await AchievementService.create(mockPrefs);

      Achievement? unlockedAchievement;
      service.onAchievementUnlocked = (achievement) {
        unlockedAchievement = achievement;
      };

      // When
      for (int i = 1; i <= 10; i++) {
        service.trackLevelScore(i, 10000);
      }

      // Then
      expect(unlockedAchievement!.id, equals('point_collector'));
    });

    test('givenSingleBallScore5000_whenTracked_thenLuckyShotUnlocked', () async {
      // Given
      when(mockPrefs.getStringList('achievements')).thenReturn(null);
      when(mockPrefs.setStringList(any, any)).thenAnswer((_) async => true);
      service = await AchievementService.create(mockPrefs);

      Achievement? unlockedAchievement;
      service.onAchievementUnlocked = (achievement) {
        unlockedAchievement = achievement;
      };

      // When
      service.trackSingleBallScore(5000);

      // Then
      expect(unlockedAchievement!.id, equals('lucky_shot'));
    });
  });

  group('AchievementService Event Tracking - Special Mechanics', () {
    test('givenAllSpecialPegsHit_whenTracked_thenPerfectShotUnlocked', () async {
      // Given
      when(mockPrefs.getStringList('achievements')).thenReturn(null);
      when(mockPrefs.setStringList(any, any)).thenAnswer((_) async => true);
      service = await AchievementService.create(mockPrefs);

      Achievement? unlockedAchievement;
      service.onAchievementUnlocked = (achievement) {
        unlockedAchievement = achievement;
      };

      // When
      service.trackAllSpecialPegsHit();

      // Then
      expect(unlockedAchievement!.id, equals('perfect_shot'));
    });

    test('given20SpecialBonuses_whenTracked_thenBonusHunterUnlocked', () async {
      // Given
      when(mockPrefs.getStringList('achievements')).thenReturn(null);
      when(mockPrefs.setStringList(any, any)).thenAnswer((_) async => true);
      service = await AchievementService.create(mockPrefs);

      Achievement? unlockedAchievement;
      service.onAchievementUnlocked = (achievement) {
        unlockedAchievement = achievement;
      };

      // When
      for (int i = 0; i < 20; i++) {
        service.trackSpecialBonus();
      }

      // Then
      expect(unlockedAchievement!.id, equals('bonus_hunter'));
    });

    test('given5SpecialPegsOneBall_whenTracked_thenComboKingUnlocked', () async {
      // Given
      when(mockPrefs.getStringList('achievements')).thenReturn(null);
      when(mockPrefs.setStringList(any, any)).thenAnswer((_) async => true);
      service = await AchievementService.create(mockPrefs);

      Achievement? unlockedAchievement;
      service.onAchievementUnlocked = (achievement) {
        unlockedAchievement = achievement;
      };

      // When
      service.trackSpecialPegCombo(5);

      // Then
      expect(unlockedAchievement!.id, equals('combo_king'));
    });

    test('given20EdgeSlots_whenTracked_thenEdgeMasterUnlocked', () async {
      // Given
      when(mockPrefs.getStringList('achievements')).thenReturn(null);
      when(mockPrefs.setStringList(any, any)).thenAnswer((_) async => true);
      service = await AchievementService.create(mockPrefs);

      Achievement? unlockedAchievement;
      service.onAchievementUnlocked = (achievement) {
        unlockedAchievement = achievement;
      };

      // When
      for (int i = 0; i < 20; i++) {
        service.trackEdgeSlot();
      }

      // Then
      expect(unlockedAchievement!.id, equals('edge_master'));
    });
  });

  group('AchievementService Event Tracking - Collection', () {
    test('given10Achievements_whenUnlocked_thenAchievementHunterUnlocked', () async {
      // Given
      when(mockPrefs.getStringList('achievements')).thenReturn(null);
      when(mockPrefs.setStringList(any, any)).thenAnswer((_) async => true);
      service = await AchievementService.create(mockPrefs);

      List<Achievement> unlocked = [];
      service.onAchievementUnlocked = unlocked.add;

      // When - Trigger enough events to unlock 10 achievements
      service.trackBallLaunched(); // first_launch (1)
      for (int i = 1; i <= 20; i++) {
        service.trackLevelComplete(i); // novice, advanced, expert, master (4)
      }
      service.trackLevelScore(1, 100000); // high_roller, score_master (2)
      for (int i = 0; i < 20; i++) {
        service.trackSpecialBonus(); // bonus_hunter (1)
      }
      service.trackSingleBallScore(5000); // lucky_shot (1)
      service.trackAllSpecialPegsHit(); // perfect_shot (1)
      // Total: 10 achievements unlocked

      // Then
      expect(unlocked.any((a) => a.id == 'achievement_hunter'), isTrue);
    });

    test('givenAllAchievements_whenUnlocked_thenCompletionistUnlocked', () async {
      // Given
      when(mockPrefs.getStringList('achievements')).thenReturn(null);
      when(mockPrefs.setStringList(any, any)).thenAnswer((_) async => true);
      service = await AchievementService.create(mockPrefs);

      // When - Manually unlock all achievements except completionist
      for (var achievement in service.getAllAchievements()) {
        if (achievement.id != 'completionist') {
          achievement.unlock();
        }
      }
      service.checkCollectionAchievements();

      // Then
      final completionist = service.getAllAchievements().firstWhere((a) => a.id == 'completionist');
      expect(completionist.isUnlocked, isTrue);
    });
  });

  group('AchievementService Persistence', () {
    test('givenAchievementUnlocked_whenSaved_thenDataPersisted', () async {
      // Given
      when(mockPrefs.getStringList('achievements')).thenReturn(null);
      when(mockPrefs.setStringList(any, any)).thenAnswer((_) async => true);
      service = await AchievementService.create(mockPrefs);

      // When
      service.trackBallLaunched();

      // Then
      final captured = verify(mockPrefs.setStringList('achievements', captureAny)).captured;
      expect(captured.isNotEmpty, isTrue);
      final savedList = captured.last as List<String>;
      expect(savedList.any((json) => json.contains('first_launch')), isTrue);
    });

    test('givenProgressUpdate_whenSaved_thenChangesPersisted', () async {
      // Given
      when(mockPrefs.getStringList('achievements')).thenReturn(null);
      when(mockPrefs.setStringList(any, any)).thenAnswer((_) async => true);
      service = await AchievementService.create(mockPrefs);

      // When - Update progress without unlocking
      service.trackLevelComplete(1);

      // Then - Should still save progress
      verify(mockPrefs.setStringList('achievements', any)).called(greaterThan(0));
    });
  });

  group('AchievementService Get Methods', () {
    test('givenMixedAchievements_whenGetUnlocked_thenOnlyUnlockedReturned', () async {
      // Given
      final savedData = [
        '{"id":"first_launch","name":"First Launch","description":"Launch your first ball","iconCodePoint":${Icons.rocket_launch.codePoint},"pointValue":100,"progress":100,"unlockedDate":"2025-11-17T15:30:00.000"}',
        '{"id":"novice_player","name":"Novice Player","description":"Complete level 5","iconCodePoint":${Icons.star.codePoint},"pointValue":250,"progress":50,"unlockedDate":null}',
      ];
      when(mockPrefs.getStringList('achievements')).thenReturn(savedData);
      service = await AchievementService.create(mockPrefs);

      // When
      final unlocked = service.getUnlockedAchievements();

      // Then
      expect(unlocked.length, equals(1));
      expect(unlocked.first.id, equals('first_launch'));
    });

    test('givenMixedAchievements_whenGetLocked_thenOnlyLockedReturned', () async {
      // Given
      final savedData = [
        '{"id":"first_launch","name":"First Launch","description":"Launch your first ball","iconCodePoint":${Icons.rocket_launch.codePoint},"pointValue":100,"progress":100,"unlockedDate":"2025-11-17T15:30:00.000"}',
      ];
      when(mockPrefs.getStringList('achievements')).thenReturn(savedData);
      service = await AchievementService.create(mockPrefs);

      // When
      final locked = service.getLockedAchievements();

      // Then
      expect(locked.length, equals(17)); // 18 total - 1 unlocked
      expect(locked.every((a) => !a.isUnlocked), isTrue);
    });

    test('givenUnlockedAchievements_whenGetTotalPoints_thenCorrectSum', () async {
      // Given
      final savedData = [
        '{"id":"first_launch","name":"First Launch","description":"Launch your first ball","iconCodePoint":${Icons.rocket_launch.codePoint},"pointValue":100,"progress":100,"unlockedDate":"2025-11-17T15:30:00.000"}',
        '{"id":"high_roller","name":"High Roller","description":"Score 50,000+ in single level","iconCodePoint":${Icons.trending_up.codePoint},"pointValue":250,"progress":100,"unlockedDate":"2025-11-17T16:00:00.000"}',
      ];
      when(mockPrefs.getStringList('achievements')).thenReturn(savedData);
      service = await AchievementService.create(mockPrefs);

      // When
      final totalPoints = service.getTotalPoints();

      // Then
      expect(totalPoints, equals(350)); // 100 + 250
    });
  });

  group('AchievementService Notification Callback', () {
    test('givenCallback_whenAchievementUnlocked_thenCallbackInvoked', () async {
      // Given
      when(mockPrefs.getStringList('achievements')).thenReturn(null);
      when(mockPrefs.setStringList(any, any)).thenAnswer((_) async => true);
      service = await AchievementService.create(mockPrefs);

      Achievement? notifiedAchievement;
      service.onAchievementUnlocked = (achievement) {
        notifiedAchievement = achievement;
      };

      // When
      service.trackBallLaunched();

      // Then
      expect(notifiedAchievement, isNotNull);
      expect(notifiedAchievement!.id, equals('first_launch'));
    });

    test('givenNoCallback_whenAchievementUnlocked_thenNoError', () async {
      // Given
      when(mockPrefs.getStringList('achievements')).thenReturn(null);
      when(mockPrefs.setStringList(any, any)).thenAnswer((_) async => true);
      service = await AchievementService.create(mockPrefs);
      // No callback set

      // When & Then - Should not throw
      expect(() => service.trackBallLaunched(), returnsNormally);
    });
  });
}
