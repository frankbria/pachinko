import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/high_score.dart';

/// Service for persisting high scores to local storage.
///
/// Uses SharedPreferences for local-only storage (no network transmission).
/// Implements dependency injection pattern for testability.
class StorageService {
  /// Maximum number of scores kept per level.
  static const int maxScoresPerLevel = 10;

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
  /// [level]: The level number (1-20)
  /// [score]: The score achieved
  Future<void> saveHighScore(int level, int score) async {
    try {
      final scores = await getHighScores(level);
      scores.add(HighScore(level: level, score: score));
      scores.sort((a, b) => b.score.compareTo(a.score)); // Sort descending
      if (scores.length > maxScoresPerLevel) {
        scores.removeRange(maxScoresPerLevel, scores.length);
      }

      final key = 'highscores_level_$level';
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
  /// [level]: The level number (1-20)
  /// Returns: List of HighScore objects, sorted as stored
  Future<List<HighScore>> getHighScores(int level) async {
    try {
      final key = 'highscores_level_$level';
      final jsonString = _prefs.getString(key);
      if (jsonString == null) return [];

      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => HighScore.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading high scores: $e');
      return []; // Return empty list on error
    }
  }

  /// Calculates the total score across all levels.
  ///
  /// Aggregates the best (highest) score from each level (1-20).
  /// Returns 0 if no scores exist.
  ///
  /// Returns: Sum of best scores from all levels
  Future<int> getTotalScore() async {
    int total = 0;
    for (int level = 1; level <= 20; level++) {
      final scores = await getHighScores(level);
      if (scores.isNotEmpty) {
        total += scores.first.score; // Best score for each level
      }
    }
    return total;
  }

  /// Gets the best (highest) score for a specific level.
  ///
  /// [level]: The level number (1-20)
  /// Returns: The highest HighScore for this level, or null if no scores exist
  Future<HighScore?> getBestScore(int level) async {
    final scores = await getHighScores(level);
    return scores.isEmpty ? null : scores.first; // Already sorted descending
  }

  /// Clears all high score data from storage.
  ///
  /// Only removes keys that start with 'highscores_level_'.
  /// Other app data is preserved.
  /// Handles errors gracefully by logging without throwing exceptions.
  Future<void> clearData() async {
    try {
      final keys = _prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('highscores_level_')) {
          await _prefs.remove(key);
        }
      }
    } catch (e) {
      debugPrint('Error clearing data: $e');
    }
  }
}
