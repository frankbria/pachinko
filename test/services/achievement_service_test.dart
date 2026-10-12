import 'dart:convert';
import 'dart:io';
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
    test('givenNoSavedData_whenInitialized_thenAllAchievementsLocked',
        () async {
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
      expect(
          service.getUnlockedAchievements().first.id, equals('first_launch'));
      expect(service.getTotalPoints(), equals(100));

      final novice = service
          .getAllAchievements()
          .firstWhere((a) => a.id == 'novice_player');
      expect(novice.progress, equals(50));
      expect(novice.isUnlocked, isFalse);
    });

    test(
        'givenStoredProgressOnTheFourCountedAchievements_whenPlayContinues_thenEachCarriesOnFromWhereItWas',
        () async {
      // Four achievements count something over many rounds. The count is not
      // stored; it is worked back from the stored percentage, so that one
      // more event after a restart finishes what 19 of 20 had started
      String entry(String id, int progress) =>
          jsonEncode({'id': id, 'progress': progress, 'unlockedDate': null});
      when(mockPrefs.getStringList('achievements')).thenReturn([
        entry('marathon_runner', 98), // 49 of 50 levels
        entry('millionaire', 90), // 900,000 of 1,000,000
        entry('bonus_hunter', 95), // 19 of 20 bonuses
        entry('edge_master', 95), // 19 of 20 edge slots
      ]);
      when(mockPrefs.setStringList(any, any)).thenAnswer((_) async => true);
      service = await AchievementService.create(mockPrefs);
      bool unlocked(String id) =>
          service.getAllAchievements().firstWhere((a) => a.id == id).isUnlocked;
      for (final id in [
        'marathon_runner',
        'millionaire',
        'bonus_hunter',
        'edge_master'
      ]) {
        expect(unlocked(id), isFalse, reason: id);
      }

      service.trackLevelComplete(1);
      service.trackLevelScore(1, 100000);
      service.trackSpecialBonus();
      service.trackEdgeSlot();

      expect(unlocked('marathon_runner'), isTrue);
      expect(unlocked('millionaire'), isTrue);
      expect(unlocked('bonus_hunter'), isTrue);
      expect(unlocked('edge_master'), isTrue);
    });

    test('givenCorruptedData_whenInitialized_thenResetToDefaults', () async {
      // Given - Invalid JSON data
      when(mockPrefs.getStringList('achievements'))
          .thenReturn(['invalid json']);

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

    test('givenMultipleLaunches_whenTracked_thenFirstLaunchOnlyUnlockedOnce',
        () async {
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

    test('givenLevel10Completed_whenTracked_thenAdvancedPlayerUnlocked',
        () async {
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
      expect(service.getUnlockedAchievements().length,
          greaterThanOrEqualTo(2)); // novice + advanced
    });

    test('given50LevelsCompleted_whenTracked_thenMarathonRunnerUnlocked',
        () async {
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
    /// The two thresholds come from the scoring simulation (#82): about one
    /// round in ten reaches the first and about one in a hundred the second.
    Future<AchievementService> freshService() async {
      when(mockPrefs.getStringList('achievements')).thenReturn(null);
      when(mockPrefs.setStringList(any, any)).thenAnswer((_) async => true);
      return AchievementService.create(mockPrefs);
    }

    bool unlocked(AchievementService service, String id) =>
        service.getAllAchievements().firstWhere((a) => a.id == id).isUnlocked;

    test('Combo King and Lucky Shot describe rules the game can meet',
        () async {
      // A level has at most four prize pegs and a ball scores 2,000 at most,
      // so "5 special pegs" and "5,000+ with single ball" could never happen
      service = await freshService();
      String description(String id) => service
          .getAllAchievements()
          .firstWhere((a) => a.id == id)
          .description;

      expect(description('combo_king'),
          'Collect every prize peg on a level with one ball');
      expect(description('lucky_shot'),
          'Land the first ball of a round in a 2,000 slot');
    });

    test('the thresholds are 20,000 and 25,000, and each description says so',
        () async {
      service = await freshService();
      String description(String id) => service
          .getAllAchievements()
          .firstWhere((a) => a.id == id)
          .description;

      expect(AchievementService.highRollerScore, 20000);
      expect(AchievementService.scoreMasterScore, 25000);
      expect(description('high_roller'), 'Score 20,000+ in single level');
      expect(description('score_master'), 'Score 25,000+ in single level');
    });

    test(
        'givenLevelScoreOneBelowHighRoller_whenTracked_thenNothingUnlocks_andAtTheThresholdItDoes',
        () async {
      service = await freshService();

      service.trackLevelScore(1, AchievementService.highRollerScore - 1);
      expect(unlocked(service, 'high_roller'), isFalse);

      service.trackLevelScore(1, AchievementService.highRollerScore);
      expect(unlocked(service, 'high_roller'), isTrue);
      expect(unlocked(service, 'score_master'), isFalse);
    });

    test(
        'givenLevelScoreOneBelowScoreMaster_whenTracked_thenOnlyHighRollerUnlocks_andAtTheThresholdBothDo',
        () async {
      service = await freshService();

      service.trackLevelScore(1, AchievementService.scoreMasterScore - 1);
      expect(unlocked(service, 'high_roller'), isTrue);
      expect(unlocked(service, 'score_master'), isFalse);

      service.trackLevelScore(2, AchievementService.scoreMasterScore);
      expect(unlocked(service, 'score_master'), isTrue);
    });

    test(
        'givenAchievementUnlockedUnderTheOldRule_whenLoaded_thenItStaysUnlockedAndReadsAsItIsNow',
        () async {
      // Stored by an earlier version: unlocked, with the description of the time
      final stored = [
        '{"id":"high_roller","name":"High Roller","description":"Score 50,000+ in single level","iconCodePoint":${Icons.trending_up.codePoint},"pointValue":250,"progress":100,"unlockedDate":"2025-11-17T10:00:00.000"}',
      ];
      when(mockPrefs.getStringList('achievements')).thenReturn(stored);
      when(mockPrefs.setStringList(any, any)).thenAnswer((_) async => true);

      service = await AchievementService.create(mockPrefs);
      final highRoller =
          service.getAllAchievements().firstWhere((a) => a.id == 'high_roller');

      expect(highRoller.isUnlocked, isTrue);
      expect(highRoller.unlockedDate, DateTime(2025, 11, 17, 10));
      expect(highRoller.description, 'Score 20,000+ in single level');
    });

    test('givenTotalScore1Million_whenTracked_thenMillionaireUnlocked',
        () async {
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

    test('given10Levels10000Plus_whenTracked_thenPointCollectorUnlocked',
        () async {
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

    test('givenFirstBallInEdgeSlot_whenTracked_thenLuckyShotUnlocked',
        () async {
      // Given
      when(mockPrefs.getStringList('achievements')).thenReturn(null);
      when(mockPrefs.setStringList(any, any)).thenAnswer((_) async => true);
      service = await AchievementService.create(mockPrefs);

      Achievement? unlockedAchievement;
      service.onAchievementUnlocked = (achievement) {
        unlockedAchievement = achievement;
      };

      // When
      service.trackFirstBallInEdgeSlot();

      // Then
      expect(unlockedAchievement!.id, equals('lucky_shot'));
    });
  });

  group('AchievementService Event Tracking - Special Mechanics', () {
    test('givenAllSpecialPegsHit_whenTracked_thenPerfectShotUnlocked',
        () async {
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

    test('givenAllPrizePegsWithOneBall_whenTracked_thenComboKingUnlocked',
        () async {
      // Given
      when(mockPrefs.getStringList('achievements')).thenReturn(null);
      when(mockPrefs.setStringList(any, any)).thenAnswer((_) async => true);
      service = await AchievementService.create(mockPrefs);

      Achievement? unlockedAchievement;
      service.onAchievementUnlocked = (achievement) {
        unlockedAchievement = achievement;
      };

      // When
      service.trackAllPrizePegsWithOneBall();

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
    test('given10Achievements_whenUnlocked_thenAchievementHunterUnlocked',
        () async {
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
      service.trackLevelScore(1,
          AchievementService.scoreMasterScore); // high_roller, score_master (2)
      for (int i = 0; i < 20; i++) {
        service.trackSpecialBonus(); // bonus_hunter (1)
      }
      service.trackFirstBallInEdgeSlot(); // lucky_shot (1)
      service.trackAllSpecialPegsHit(); // perfect_shot (1)
      // Total: 10 achievements unlocked

      // Then
      expect(unlocked.any((a) => a.id == 'achievement_hunter'), isTrue);
    });

    test('givenAllAchievements_whenUnlocked_thenCompletionistUnlocked',
        () async {
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
      final completionist = service
          .getAllAchievements()
          .firstWhere((a) => a.id == 'completionist');
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
      final captured =
          verify(mockPrefs.setStringList('achievements', captureAny)).captured;
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
      verify(mockPrefs.setStringList('achievements', any))
          .called(greaterThan(0));
    });
  });

  group('AchievementService Get Methods', () {
    test('givenMixedAchievements_whenGetUnlocked_thenOnlyUnlockedReturned',
        () async {
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

    test('givenMixedAchievements_whenGetLocked_thenOnlyLockedReturned',
        () async {
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

    test('givenUnlockedAchievements_whenGetTotalPoints_thenCorrectSum',
        () async {
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

  test('every tracking method of the service is called by the game', () {
    // An achievement whose tracking method nothing calls cannot be won,
    // however reasonable its rule reads (#85). Read from the sources: the
    // service's methods, and every other file under lib/
    final service = File('lib/services/achievement_service.dart');
    final methods = RegExp(r'void (track\w+)\(')
        .allMatches(service.readAsStringSync())
        .map((match) => match[1]!)
        .toList();
    final game = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where(
            (file) => file.path.endsWith('.dart') && file.path != service.path)
        .map((file) => file.readAsStringSync())
        .join();

    expect(methods, hasLength(greaterThanOrEqualTo(8)));
    for (final method in methods) {
      expect(game, contains('.$method('),
          reason: 'nothing in lib/ calls AchievementService.$method');
    }
  });
}
