import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_board.dart';
import '../models/game_settings.dart';
import '../models/high_score.dart';
import '../models/star_targets.dart';

/// Service for persisting high scores to local storage.
///
/// Uses SharedPreferences for local-only storage (no network transmission).
/// Implements dependency injection pattern for testability.
class StorageService {
  /// Maximum number of scores kept per level.
  static const int maxScoresPerLevel = 10;

  /// What every stored key of a level's score table starts with.
  static const String _levelKeyPrefix = 'highscores_level_';

  final SharedPreferences _prefs;

  /// Creates a StorageService with dependency injection for testability.
  ///
  /// In production, use [initialize()] instead to get a properly configured instance.
  /// For testing, pass a mock SharedPreferences instance.
  StorageService({required SharedPreferences prefs}) : _prefs = prefs;

  static const String _singleBallLaunchKey = 'setting_single_ball_launch';

  /// Whether a ball may only be launched once no ball is in play. On, unless
  /// the player has turned it off.
  bool get singleBallLaunch => _prefs.getBool(_singleBallLaunchKey) ?? true;

  /// Saves the player's choice for [singleBallLaunch].
  Future<void> saveSingleBallLaunch(bool value) async {
    await _prefs.setBool(_singleBallLaunchKey, value);
  }

  static const String _soundOnKey = 'setting_sound_on';
  static const String _soundVolumeKey = 'setting_sound_volume';
  static const String _vibrationOnKey = 'setting_vibration_on';
  static const String _reducedMotionKey = 'setting_reduced_motion';
  static const String _leftHandedKey = 'setting_left_handed';

  /// The player's sound, vibration, motion and launcher settings, or the defaults of a
  /// new install for any not chosen yet.
  GameSettings get settings {
    const defaults = GameSettings();
    return GameSettings(
      soundOn: _prefs.getBool(_soundOnKey) ?? defaults.soundOn,
      soundVolume: _prefs.getDouble(_soundVolumeKey) ?? defaults.soundVolume,
      vibrationOn: _prefs.getBool(_vibrationOnKey) ?? defaults.vibrationOn,
      reducedMotion: _prefs.getBool(_reducedMotionKey),
      leftHanded: _prefs.getBool(_leftHandedKey) ?? defaults.leftHanded,
    );
  }

  /// Saves [settings]. Reduced motion is stored only once the player has
  /// chosen it, so that until then it follows the system.
  Future<void> saveSettings(GameSettings settings) async {
    await _prefs.setBool(_soundOnKey, settings.soundOn);
    await _prefs.setDouble(_soundVolumeKey, settings.soundVolume);
    await _prefs.setBool(_vibrationOnKey, settings.vibrationOn);
    await _prefs.setBool(_leftHandedKey, settings.leftHanded);
    final reducedMotion = settings.reducedMotion;
    if (reducedMotion != null) {
      await _prefs.setBool(_reducedMotionKey, reducedMotion);
    }
  }

  static const String _launchHintShownKey = 'hint_launch_shown';
  static const String _prizePegHintShownKey = 'hint_prize_peg_shown';

  /// Whether the ghost hand that shows the drag on the plunger is still to be
  /// shown: true until the player's first launch on this install.
  bool get launchHintDue => !(_prefs.getBool(_launchHintShownKey) ?? false);

  /// Records that the player has launched a ball, so the ghost hand is not
  /// shown again.
  Future<void> saveLaunchHintShown() async {
    await _prefs.setBool(_launchHintShownKey, true);
  }

  /// Whether the callout that says what the prize pegs are for is still to be
  /// shown: true until the first prize peg hit on this install.
  bool get prizePegHintDue => !(_prefs.getBool(_prizePegHintShownKey) ?? false);

  /// Records that the prize peg callout has been shown.
  Future<void> savePrizePegHintShown() async {
    await _prefs.setBool(_prizePegHintShownKey, true);
  }

  /// What every stored key of a level's stars starts with.
  static const String _starsKeyPrefix = 'stars_level_';

  /// The stars stored for each level that has any, by level number. Stars
  /// are stored separately from the scores so that clearing the scores, or
  /// raising a level's targets later, takes no star or unlock away.
  Map<int, int> get storedStars {
    try {
      return {
        for (final key in _prefs.getKeys())
          if (key.startsWith(_starsKeyPrefix))
            if (int.tryParse(key.substring(_starsKeyPrefix.length))
                case final level?)
              level: _prefs.getInt(key) ?? 0,
      };
    } catch (e) {
      debugPrint('Error reading stars: $e');
      return {};
    }
  }

  /// Records that [level] has won [stars], unless it already has more. A
  /// failure is logged, not thrown: nothing waits on the save.
  Future<void> saveStars(int level, int stars) async {
    try {
      final key = '$_starsKeyPrefix$level';
      if (stars > (_prefs.getInt(key) ?? 0)) await _prefs.setInt(key, stars);
    } catch (e) {
      debugPrint('Error saving stars: $e');
    }
  }

  static const String _dailyBestDayKey = 'daily_best_day';
  static const String _dailyBestScoreKey = 'daily_best_score';
  static const String _dailyStreakDayKey = 'daily_streak_last_day';
  static const String _dailyStreakLengthKey = 'daily_streak_length';
  static const String _dailyPendingDayKey = 'daily_pending_day';
  static const String _dailyPendingScoreKey = 'daily_pending_score';

  /// The best score of a daily round finished on [day], or null when none
  /// was. Only the latest day's best is kept.
  int? dailyBest(int day) => _prefs.getInt(_dailyBestDayKey) == day
      ? _prefs.getInt(_dailyBestScoreKey)
      : null;

  /// The player's streak of days with a daily round finished.
  DailyStreak get dailyStreak => DailyStreak(
        lastDay: _prefs.getInt(_dailyStreakDayKey) ?? DailyStreak.none.lastDay,
        length: _prefs.getInt(_dailyStreakLengthKey) ?? DailyStreak.none.length,
      );

  /// Records a daily round of [score] finished on the board of [day]: the
  /// day's best when it beats it, unless a later day's best is stored, and
  /// the streak. A failure is logged, not thrown: nothing waits on the save.
  Future<void> recordDailyRound(int day, int score) async {
    try {
      final bestDay = _prefs.getInt(_dailyBestDayKey);
      if (bestDay == null ||
          day > bestDay ||
          day == bestDay && score > (dailyBest(day) ?? 0)) {
        await _prefs.setInt(_dailyBestDayKey, day);
        await _prefs.setInt(_dailyBestScoreKey, score);
      }
      final streak = dailyStreak.playedOn(day);
      await _prefs.setInt(_dailyStreakDayKey, streak.lastDay);
      await _prefs.setInt(_dailyStreakLengthKey, streak.length);
    } catch (e) {
      debugPrint('Error saving the daily round: $e');
    }
  }

  /// The daily score still to post to the leaderboard, with the day it was
  /// won on, or null when there is none.
  ({int day, int score})? get pendingDailyScore {
    final day = _prefs.getInt(_dailyPendingDayKey);
    final score = _prefs.getInt(_dailyPendingScoreKey);
    return day == null || score == null ? null : (day: day, score: score);
  }

  /// Keeps [score], won on [day], to post to the leaderboard once it can be,
  /// in place of any score kept before.
  Future<void> savePendingDailyScore(int day, int score) async {
    await _prefs.setInt(_dailyPendingDayKey, day);
    await _prefs.setInt(_dailyPendingScoreKey, score);
  }

  /// Forgets the score kept for the leaderboard, once posted or too late.
  Future<void> clearPendingDailyScore() async {
    await _prefs.remove(_dailyPendingDayKey);
    await _prefs.remove(_dailyPendingScoreKey);
  }

  /// Initializes StorageService with production SharedPreferences.
  ///
  /// This is the recommended way to create a StorageService in production code.
  /// For testing, use the constructor with a mock SharedPreferences instead.
  static Future<StorageService> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs: prefs);
  }

  /// Saves a high score for a specific level.
  ///
  /// Adds the new score to this level's scores, sorts descending and keeps the
  /// top [maxScoresPerLevel].
  /// Handles storage errors gracefully by logging without throwing exceptions.
  ///
  /// [level]: The level number, 1 or more
  /// [score]: The score achieved
  Future<void> saveHighScore(int level, int score) async {
    try {
      final scores = await getHighScores(level);
      scores.add(HighScore(level: level, score: score));
      scores.sort((a, b) => b.score.compareTo(a.score)); // Sort descending
      if (scores.length > maxScoresPerLevel) {
        scores.removeRange(maxScoresPerLevel, scores.length);
      }

      final key = '$_levelKeyPrefix$level';
      final jsonList = scores.map((s) => s.toJson()).toList();
      await _prefs.setString(key, jsonEncode(jsonList));
    } catch (e) {
      // Log error but don't throw (graceful degradation)
      debugPrint('Error saving high score: $e');
    }
  }

  /// Retrieves all high scores for a specific level.
  ///
  /// Returns an empty list if no scores exist or if data is corrupted.
  /// Handles errors gracefully to prevent app crashes.
  ///
  /// [level]: The level number, 1 or more
  /// Returns: List of HighScore objects, sorted as stored
  Future<List<HighScore>> getHighScores(int level) async {
    try {
      final key = '$_levelKeyPrefix$level';
      final jsonString = _prefs.getString(key);
      if (jsonString == null) return [];

      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => HighScore.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading high scores: $e');
      return []; // Return empty list on error
    }
  }

  /// The levels that have a stored table of scores, lowest first.
  ///
  /// Next Level has no upper limit, so this is read from what is stored
  /// and not assumed to be 1 to 20. Empty if storage cannot be read.
  Future<List<int>> levelsWithScores() async {
    try {
      final levels = <int>[];
      for (final key in _prefs.getKeys()) {
        if (!key.startsWith(_levelKeyPrefix)) continue;
        final level = int.tryParse(key.substring(_levelKeyPrefix.length));
        if (level != null) levels.add(level);
      }
      return levels..sort();
    } catch (e) {
      debugPrint('Error listing levels with scores: $e');
      return [];
    }
  }

  /// Calculates the total score across all levels.
  ///
  /// Aggregates the best (highest) score from each level that has scores.
  /// Returns 0 if no scores exist.
  ///
  /// Returns: Sum of best scores from all levels
  Future<int> getTotalScore() async {
    int total = 0;
    for (final level in await levelsWithScores()) {
      final scores = await getHighScores(level);
      if (scores.isNotEmpty) {
        total += scores.first.score; // Best score for each level
      }
    }
    return total;
  }

  /// Gets the best (highest) score for a specific level.
  ///
  /// [level]: The level number, 1 or more
  /// Returns: The highest HighScore for this level, or null if no scores exist
  Future<HighScore?> getBestScore(int level) async {
    final scores = await getHighScores(level);
    return scores.isEmpty ? null : scores.first; // Already sorted descending
  }

  /// Clears all high score data from storage.
  ///
  /// Only removes keys that start with 'highscores_level_'.
  /// Other app data is preserved, the stars and so the open levels too:
  /// first each level's scores are turned into the stars they win, which a
  /// table stored before stars existed has not been yet.
  /// Handles errors gracefully by logging without throwing exceptions.
  Future<void> clearData() async {
    try {
      for (final level in await levelsWithScores()) {
        if (await getBestScore(level) case final best?) {
          await saveStars(
              level, StarTargets.forLevel(level).starsFor(best.score));
        }
      }
      final keys = _prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_levelKeyPrefix)) {
          await _prefs.remove(key);
        }
      }
    } catch (e) {
      debugPrint('Error clearing data: $e');
    }
  }
}
