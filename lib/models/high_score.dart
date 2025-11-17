/// Represents a high score entry for a specific level in the Pachinko game.
///
/// Each high score tracks the level, score achieved, and timestamp when the score was recorded.
/// High scores are persistable through JSON serialization and can be sorted by score value.
class HighScore {
  /// The level number where this score was achieved (1-20).
  final int level;

  /// The score value achieved in this level.
  final int score;

  /// The timestamp when this score was recorded.
  /// Defaults to the current time if not provided.
  final DateTime timestamp;

  /// Creates a new HighScore instance.
  ///
  /// [level] and [score] are required parameters.
  /// [timestamp] is optional and defaults to DateTime.now() if not provided.
  HighScore({
    required this.level,
    required this.score,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Converts this HighScore to a JSON map for serialization.
  ///
  /// The timestamp is converted to ISO 8601 string format for storage compatibility.
  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'score': score,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Creates a HighScore from a JSON map.
  ///
  /// Throws [TypeError] if required fields are missing.
  /// Throws [FormatException] if timestamp string is invalid.
  factory HighScore.fromJson(Map<String, dynamic> json) {
    return HighScore(
      level: json['level'] as int,
      score: json['score'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Compares this HighScore to another for sorting purposes.
  ///
  /// Returns a negative value if this score is greater (should come first),
  /// zero if equal, or positive if this score is less (should come after).
  ///
  /// This implements descending order (highest score first).
  int compareTo(HighScore other) {
    return other.score.compareTo(score); // Descending order
  }

  /// Checks equality based on level, score, and timestamp.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HighScore &&
        other.level == level &&
        other.score == score &&
        other.timestamp == timestamp;
  }

  /// Generates hash code based on level, score, and timestamp.
  @override
  int get hashCode => Object.hash(level, score, timestamp);

  /// Returns a string representation of this HighScore for debugging.
  @override
  String toString() {
    return 'HighScore(level: $level, score: $score, timestamp: $timestamp)';
  }
}
