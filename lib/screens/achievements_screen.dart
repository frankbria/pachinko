import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pachinko_game/services/achievement_service.dart';
import 'package:pachinko_game/models/achievement.dart';

/// Screen displaying all achievements with progress tracking.
///
/// Shows unlocked achievements with dates and locked achievements with progress bars.
/// Displays statistics banner with completion percentage and total points.
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<AchievementService>(context);
    final allAchievements = service.getAllAchievements();
    final unlockedAchievements = service.getUnlockedAchievements();
    final lockedAchievements = service.getLockedAchievements();
    final totalPoints = service.getTotalPoints();

    // Sort unlocked by date (newest first)
    final sortedUnlocked = List<Achievement>.from(unlockedAchievements)
      ..sort((a, b) => (b.unlockedDate ?? DateTime(0))
          .compareTo(a.unlockedDate ?? DateTime(0)));

    // Sort locked by progress (highest first)
    final sortedLocked = List<Achievement>.from(lockedAchievements)
      ..sort((a, b) => b.progress.compareTo(a.progress));

    final completionPercentage = allAchievements.isEmpty
        ? 0
        : (unlockedAchievements.length * 100 / allAchievements.length).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: allAchievements.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'No achievements available',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),
            )
          : Column(
              children: [
                // Stats Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.deepPurple, Colors.purple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        icon: Icons.emoji_events,
                        label: 'Completion',
                        value: '$completionPercentage%',
                      ),
                      _buildStatItem(
                        icon: Icons.star,
                        label: 'Total Points',
                        value: totalPoints.toString(),
                      ),
                      _buildStatItem(
                        icon: Icons.workspace_premium,
                        label: 'Unlocked',
                        value: '${unlockedAchievements.length}/${allAchievements.length}',
                      ),
                    ],
                  ),
                ),

                // Achievement Lists
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Unlocked Achievements Section
                      if (sortedUnlocked.isNotEmpty) ...[
                        Text(
                          'Unlocked (${sortedUnlocked.length})',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...sortedUnlocked.map((achievement) =>
                            _buildUnlockedAchievementTile(achievement)),
                        const SizedBox(height: 24),
                      ],

                      // Locked Achievements Section
                      if (sortedLocked.isNotEmpty) ...[
                        Text(
                          'Locked (${sortedLocked.length})',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...sortedLocked.map((achievement) =>
                            _buildLockedAchievementTile(achievement)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 32),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildUnlockedAchievementTile(Achievement achievement) {
    final dateFormat = DateFormat('MM/dd/yyyy');
    final unlockedDateStr = achievement.unlockedDate != null
        ? dateFormat.format(achievement.unlockedDate!)
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.amber,
          child: Icon(achievement.icon, color: Colors.white),
        ),
        title: Text(
          achievement.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(achievement.description),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  unlockedDateStr,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        trailing: Chip(
          label: Text('${achievement.pointValue} points'),
          backgroundColor: Colors.amber.shade100,
        ),
      ),
    );
  }

  Widget _buildLockedAchievementTile(Achievement achievement) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      color: Colors.grey.shade100,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey,
          child: Icon(achievement.icon, color: Colors.white),
        ),
        title: Text(
          achievement.name,
          style: const TextStyle(color: Colors.black87),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              achievement.description,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: achievement.progress / 100,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${achievement.progress}%',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        trailing: Chip(
          label: Text('${achievement.pointValue} points'),
          backgroundColor: Colors.grey.shade300,
        ),
      ),
    );
  }
}
