import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pachinko_game/models/achievement.dart';

/// Service for tracking and managing game achievements.
///
/// Monitors game events, updates achievement progress, persists state,
/// and triggers unlock notifications. Extends ChangeNotifier for reactive UI updates.
class AchievementService extends ChangeNotifier {
  static const String _storageKey = 'achievements';

  final SharedPreferences _prefs;
  final List<Achievement> _achievements = [];

  // Callback invoked when an achievement is unlocked
  void Function(Achievement)? onAchievementUnlocked;

  // Tracking counters for progress-based achievements
  int _totalLevelsCompleted = 0;
  int _totalScore = 0;
  int _specialBonusCount = 0;
  int _edgeSlotCount = 0;
  final Map<int, int> _levelScores = {}; // Track scores per level

  /// Private constructor for dependency injection pattern
  AchievementService._(this._prefs);

  /// Static factory method for async initialization
  ///
  /// Loads all achievement definitions and restores progress from storage.
  /// Returns a fully initialized service ready for use.
  static Future<AchievementService> create(SharedPreferences prefs) async {
    final service = AchievementService._(prefs);
    await service._initialize();
    return service;
  }

  /// Initializes all achievement definitions and loads saved progress
  Future<void> _initialize() async {
    _defineAchievements();
    await _loadProgress();
  }

  /// Defines all 18 achievements with their unlock criteria
  void _defineAchievements() {
    _achievements.addAll([
      // Progression achievements (6)
      Achievement(
        id: 'first_launch',
        name: 'First Launch',
        description: 'Launch your first ball',
        icon: Icons.rocket_launch,
        pointValue: 100,
      ),
      Achievement(
        id: 'novice_player',
        name: 'Novice Player',
        description: 'Complete level 5',
        icon: Icons.star,
        pointValue: 250,
      ),
      Achievement(
        id: 'advanced_player',
        name: 'Advanced Player',
        description: 'Complete level 10',
        icon: Icons.star_half,
        pointValue: 250,
      ),
      Achievement(
        id: 'expert_player',
        name: 'Expert Player',
        description: 'Complete level 15',
        icon: Icons.stars,
        pointValue: 500,
      ),
      Achievement(
        id: 'master_player',
        name: 'Master Player',
        description: 'Complete level 20',
        icon: Icons.military_tech,
        pointValue: 500,
      ),
      Achievement(
        id: 'marathon_runner',
        name: 'Marathon Runner',
        description: 'Complete 50 total levels',
        icon: Icons.directions_run,
        pointValue: 1000,
      ),

      // Scoring achievements (5)
      Achievement(
        id: 'high_roller',
        name: 'High Roller',
        description: 'Score 50,000+ in single level',
        icon: Icons.trending_up,
        pointValue: 250,
      ),
      Achievement(
        id: 'score_master',
        name: 'Score Master',
        description: 'Score 100,000+ in single level',
        icon: Icons.emoji_events,
        pointValue: 500,
      ),
      Achievement(
        id: 'millionaire',
        name: 'Millionaire',
        description: 'Accumulate 1,000,000 total points',
        icon: Icons.attach_money,
        pointValue: 1000,
      ),
      Achievement(
        id: 'point_collector',
        name: 'Point Collector',
        description: 'Score 10,000+ on 10 different levels',
        icon: Icons.collections,
        pointValue: 500,
      ),
      Achievement(
        id: 'edge_master',
        name: 'Edge Master',
        description: 'Land in edge slots 20 times',
        icon: Icons.pin_drop,
        pointValue: 500,
      ),

      // Special mechanics achievements (4)
      Achievement(
        id: 'perfect_shot',
        name: 'Perfect Shot',
        description: 'Hit all special pegs in one level',
        icon: Icons.gps_fixed,
        pointValue: 500,
      ),
      Achievement(
        id: 'bonus_hunter',
        name: 'Bonus Hunter',
        description: 'Trigger 20 special bonuses',
        icon: Icons.local_fire_department,
        pointValue: 250,
      ),
      Achievement(
        id: 'combo_king',
        name: 'Combo King',
        description: 'Hit 5 special pegs with one ball',
        icon: Icons.flash_on,
        pointValue: 1000,
      ),
      Achievement(
        id: 'lucky_shot',
        name: 'Lucky Shot',
        description: 'Score 5,000+ with single ball',
        icon: Icons.casino,
        pointValue: 250,
      ),

      // Collection achievements (3)
      Achievement(
        id: 'achievement_hunter',
        name: 'Achievement Hunter',
        description: 'Unlock 10 achievements',
        icon: Icons.workspace_premium,
        pointValue: 500,
      ),
      Achievement(
        id: 'completionist',
        name: 'Completionist',
        description: 'Unlock all achievements',
        icon: Icons.verified,
        pointValue: 1000,
      ),
      Achievement(
        id: 'early_bird',
        name: 'Early Bird',
        description: 'Unlock 5 achievements in first session',
        icon: Icons.alarm,
        pointValue: 250,
      ),
    ]);
  }

  /// Loads achievement progress from SharedPreferences
  ///
  /// Gracefully handles missing or corrupted data by resetting to defaults.
  Future<void> _loadProgress() async {
    try {
      final savedData = _prefs.getStringList(_storageKey);
      if (savedData == null || savedData.isEmpty) return;

      // Create a map of saved achievements by id
      final Map<String, Achievement> savedAchievements = {};
      for (final jsonStr in savedData) {
        try {
          final achievement = Achievement.fromJson(jsonDecode(jsonStr));
          savedAchievements[achievement.id] = achievement;

          // Restore tracking counters from saved state
          if (achievement.id == 'marathon_runner') {
            _totalLevelsCompleted = achievement.progress * 50 ~/ 100;
          } else if (achievement.id == 'millionaire') {
            _totalScore = achievement.progress * 1000000 ~/ 100;
          } else if (achievement.id == 'bonus_hunter') {
            _specialBonusCount = achievement.progress * 20 ~/ 100;
          } else if (achievement.id == 'edge_master') {
            _edgeSlotCount = achievement.progress * 20 ~/ 100;
          }
        } catch (e) {
          // Skip corrupted individual entries
          continue;
        }
      }

      // Update existing achievements with saved progress
      for (int i = 0; i < _achievements.length; i++) {
        final saved = savedAchievements[_achievements[i].id];
        if (saved != null) {
          _achievements[i] = saved;
        }
      }
    } catch (e) {
      // Gracefully handle corrupted data by keeping defaults
      debugPrint('Error loading achievement progress: $e');
    }
  }

  /// Saves current achievement state to SharedPreferences
  Future<void> _saveProgress() async {
    try {
      final jsonList = _achievements.map((a) => jsonEncode(a.toJson())).toList();
      await _prefs.setStringList(_storageKey, jsonList);
    } catch (e) {
      debugPrint('Error saving achievement progress: $e');
    }
  }

  /// Checks if an achievement was unlocked and triggers notification
  void _checkUnlock(Achievement achievement) {
    if (achievement.isUnlocked) {
      onAchievementUnlocked?.call(achievement);
      _saveProgress();
      checkCollectionAchievements(); // Check meta-achievements
      notifyListeners();
    }
  }

  // ============================================================================
  // Event Tracking Methods
  // ============================================================================

  /// Tracks when a ball is launched
  void trackBallLaunched() {
    final achievement = _achievements.firstWhere((a) => a.id == 'first_launch');
    if (!achievement.isUnlocked) {
      achievement.unlock();
      _checkUnlock(achievement);
    }
  }

  /// Tracks when a level is completed
  void trackLevelComplete(int level) {
    _totalLevelsCompleted++;

    // Check milestone achievements (use separate if statements to allow multiple unlocks)
    if (level >= 5) {
      final achievement = _achievements.firstWhere((a) => a.id == 'novice_player');
      if (!achievement.isUnlocked) {
        achievement.unlock();
        _checkUnlock(achievement);
      }
    }
    if (level >= 10) {
      final achievement = _achievements.firstWhere((a) => a.id == 'advanced_player');
      if (!achievement.isUnlocked) {
        achievement.unlock();
        _checkUnlock(achievement);
      }
    }
    if (level >= 15) {
      final achievement = _achievements.firstWhere((a) => a.id == 'expert_player');
      if (!achievement.isUnlocked) {
        achievement.unlock();
        _checkUnlock(achievement);
      }
    }
    if (level >= 20) {
      final achievement = _achievements.firstWhere((a) => a.id == 'master_player');
      if (!achievement.isUnlocked) {
        achievement.unlock();
        _checkUnlock(achievement);
      }
    }

    // Check marathon runner (50 total levels)
    final marathon = _achievements.firstWhere((a) => a.id == 'marathon_runner');
    if (!marathon.isUnlocked) {
      marathon.updateProgress((_totalLevelsCompleted * 100 / 50).round());
      if (marathon.isUnlocked) {
        _checkUnlock(marathon);
      } else {
        _saveProgress();
        notifyListeners();
      }
    }
  }

  /// Tracks the score for a completed level
  void trackLevelScore(int level, int score) {
    _totalScore += score;
    _levelScores[level] = score;

    // Check single-level score achievements (check higher threshold first for proper callback order)
    if (score >= 50000) {
      final achievement = _achievements.firstWhere((a) => a.id == 'high_roller');
      if (!achievement.isUnlocked) {
        achievement.unlock();
        _checkUnlock(achievement);
      }
    }
    if (score >= 100000) {
      final achievement = _achievements.firstWhere((a) => a.id == 'score_master');
      if (!achievement.isUnlocked) {
        achievement.unlock();
        _checkUnlock(achievement);
      }
    }

    // Check millionaire (total score)
    final millionaire = _achievements.firstWhere((a) => a.id == 'millionaire');
    if (!millionaire.isUnlocked) {
      millionaire.updateProgress((_totalScore * 100 / 1000000).round().clamp(0, 100));
      if (millionaire.isUnlocked) {
        _checkUnlock(millionaire);
      } else {
        _saveProgress();
        notifyListeners();
      }
    }

    // Check point collector (10+ levels with 10,000+ points)
    final levelsOver10k = _levelScores.values.where((s) => s >= 10000).length;
    if (levelsOver10k >= 10) {
      final achievement = _achievements.firstWhere((a) => a.id == 'point_collector');
      if (!achievement.isUnlocked) {
        achievement.unlock();
        _checkUnlock(achievement);
      }
    }
  }

  /// Tracks the score from a single ball
  void trackSingleBallScore(int score) {
    if (score >= 5000) {
      final achievement = _achievements.firstWhere((a) => a.id == 'lucky_shot');
      if (!achievement.isUnlocked) {
        achievement.unlock();
        _checkUnlock(achievement);
      }
    }
  }

  /// Tracks when all special pegs are hit in a level
  void trackAllSpecialPegsHit() {
    final achievement = _achievements.firstWhere((a) => a.id == 'perfect_shot');
    if (!achievement.isUnlocked) {
      achievement.unlock();
      _checkUnlock(achievement);
    }
  }

  /// Tracks when a special bonus is triggered
  void trackSpecialBonus() {
    _specialBonusCount++;

    final achievement = _achievements.firstWhere((a) => a.id == 'bonus_hunter');
    if (!achievement.isUnlocked) {
      achievement.updateProgress((_specialBonusCount * 100 / 20).round());
      if (achievement.isUnlocked) {
        _checkUnlock(achievement);
      } else {
        _saveProgress();
        notifyListeners();
      }
    }
  }

  /// Tracks when multiple special pegs are hit with one ball
  void trackSpecialPegCombo(int count) {
    if (count >= 5) {
      final achievement = _achievements.firstWhere((a) => a.id == 'combo_king');
      if (!achievement.isUnlocked) {
        achievement.unlock();
        _checkUnlock(achievement);
      }
    }
  }

  /// Tracks when a ball lands in an edge slot
  void trackEdgeSlot() {
    _edgeSlotCount++;

    final achievement = _achievements.firstWhere((a) => a.id == 'edge_master');
    if (!achievement.isUnlocked) {
      achievement.updateProgress((_edgeSlotCount * 100 / 20).round());
      if (achievement.isUnlocked) {
        _checkUnlock(achievement);
      } else {
        _saveProgress();
        notifyListeners();
      }
    }
  }

  /// Checks and updates collection meta-achievements
  void checkCollectionAchievements() {
    final unlockedCount = getUnlockedAchievements().length;

    // Achievement Hunter (10 achievements)
    if (unlockedCount >= 10) {
      final achievement = _achievements.firstWhere((a) => a.id == 'achievement_hunter');
      if (!achievement.isUnlocked) {
        achievement.unlock();
        _checkUnlock(achievement);
      }
    }

    // Completionist (all achievements excluding itself)
    final completionist = _achievements.firstWhere((a) => a.id == 'completionist');
    if (!completionist.isUnlocked) {
      final otherAchievements = _achievements.where((a) => a.id != 'completionist');
      if (otherAchievements.every((a) => a.isUnlocked)) {
        completionist.unlock();
        _checkUnlock(completionist);
      }
    }

    // Early Bird (5 in first session) - handled by UI/game manager
  }

  // ============================================================================
  // Public Getter Methods
  // ============================================================================

  /// Returns all achievements (locked and unlocked)
  List<Achievement> getAllAchievements() => List.unmodifiable(_achievements);

  /// Returns only unlocked achievements
  List<Achievement> getUnlockedAchievements() {
    return _achievements.where((a) => a.isUnlocked).toList();
  }

  /// Returns only locked achievements
  List<Achievement> getLockedAchievements() {
    return _achievements.where((a) => !a.isUnlocked).toList();
  }

  /// Returns total points earned from unlocked achievements
  int getTotalPoints() {
    return _achievements
        .where((a) => a.isUnlocked)
        .fold(0, (sum, a) => sum + a.pointValue);
  }
}
