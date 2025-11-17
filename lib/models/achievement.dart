import 'package:flutter/material.dart';

/// Represents a game achievement that can be tracked and unlocked.
///
/// Each achievement tracks progress (0-100), unlock status, and rewards points.
/// Achievements automatically unlock when progress reaches 100%.
class Achievement {
  /// Unique identifier for this achievement.
  final String id;

  /// Display name shown to users.
  final String name;

  /// Description of how to unlock this achievement.
  final String description;

  /// Icon displayed in the achievements UI.
  final IconData icon;

  /// Points awarded when achievement is unlocked.
  final int pointValue;

  /// Current progress toward unlocking (0-100).
  int progress;

  /// Date/time when achievement was unlocked. Null if locked.
  DateTime? unlockedDate;

  /// Creates an Achievement with the specified properties.
  ///
  /// [progress] defaults to 0 if not provided.
  /// [unlockedDate] is null by default (locked state).
  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.pointValue,
    this.progress = 0,
    this.unlockedDate,
  });

  /// Returns true if this achievement has been unlocked.
  bool get isUnlocked => unlockedDate != null;

  /// Updates progress toward unlocking this achievement.
  ///
  /// Progress is clamped between 0-100. If progress reaches 100%,
  /// the achievement automatically unlocks.
  ///
  /// Updates to already-unlocked achievements have no effect.
  void updateProgress(int newProgress) {
    if (!isUnlocked) {
      progress = newProgress.clamp(0, 100);
      if (progress >= 100) {
        unlock();
      }
    }
  }

  /// Unlocks this achievement immediately.
  ///
  /// Sets [unlockedDate] to current time and [progress] to 100.
  /// Has no effect if already unlocked.
  void unlock() {
    if (!isUnlocked) {
      unlockedDate = DateTime.now();
      progress = 100;
    }
  }

  /// Converts this achievement to JSON for persistence.
  ///
  /// Icon is stored as codePoint for serialization compatibility.
  /// Timestamp is stored in ISO 8601 format.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconCodePoint': icon.codePoint,
      'pointValue': pointValue,
      'progress': progress,
      'unlockedDate': unlockedDate?.toIso8601String(),
    };
  }

  /// Creates an Achievement from JSON data.
  ///
  /// [json] must contain all required fields. Missing fields will throw.
  /// Icon is reconstructed from codePoint with MaterialIcons font.
  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: IconData(
        json['iconCodePoint'] as int,
        fontFamily: 'MaterialIcons',
      ),
      pointValue: json['pointValue'] as int,
      progress: json['progress'] as int? ?? 0,
      unlockedDate: json['unlockedDate'] != null
          ? DateTime.parse(json['unlockedDate'] as String)
          : null,
    );
  }

  /// Checks equality based on id, progress, and unlocked date.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Achievement &&
        other.id == id &&
        other.progress == progress &&
        other.unlockedDate == unlockedDate;
  }

  /// Generates hash code based on id, progress, and unlocked date.
  @override
  int get hashCode => Object.hash(id, progress, unlockedDate);

  /// Returns string representation for debugging.
  @override
  String toString() {
    return 'Achievement(id: $id, name: $name, progress: $progress, unlocked: $isUnlocked)';
  }
}
