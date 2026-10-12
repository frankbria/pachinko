import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pachinko_game/services/achievement_service.dart';
import 'package:pachinko_game/models/achievement.dart';
import 'package:pachinko_game/utils/constants.dart';
import 'package:pachinko_game/widgets/achievement_toast_overlay.dart';
import 'package:pachinko_game/widgets/game_card.dart';

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

    // Toasts start below the app bar: one at the top would lie over the
    // title and the Back button
    return ToastAnchor(
        child: Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
      ),
      body: allAchievements.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'No achievements available',
                  style:
                      TextStyle(fontSize: 18, color: GameConstants.mutedColor),
                ),
              ),
            )
          : Column(
              children: [
                // Stats Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: GameConstants.surfaceColor,
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
                        value:
                            '${unlockedAchievements.length}/${allAchievements.length}',
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
                            color: GameConstants.secondaryColor,
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
                            color: GameConstants.mutedColor,
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
    ));
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: GameConstants.inkColor, size: 32),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: GameConstants.inkColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: GameConstants.mutedColor,
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

    // Rimmed and badged in gold: an achievement is a score
    return GameCard(
      rim: GameConstants.secondaryColor.withValues(alpha: 0.7),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: GameConstants.secondaryColor,
          child: Icon(achievement.icon, color: GameConstants.onPrimaryColor),
        ),
        title: Text(
          achievement.name,
          style: const TextStyle(
              color: GameConstants.inkColor, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(achievement.description,
                style: const TextStyle(color: GameConstants.mutedColor)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 12, color: GameConstants.mutedColor),
                const SizedBox(width: 4),
                Text(
                  unlockedDateStr,
                  style: const TextStyle(
                      fontSize: 12, color: GameConstants.mutedColor),
                ),
              ],
            ),
          ],
        ),
        trailing: Text(
          '${achievement.pointValue} points',
          style: const TextStyle(
              color: GameConstants.secondaryColor, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildLockedAchievementTile(Achievement achievement) {
    // No gold anywhere, a lock, and its progress: not yet won
    return GameCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: GameConstants.cabinetColor,
          child: Icon(achievement.icon, color: GameConstants.mutedColor),
        ),
        title: Text(
          achievement.name,
          style: const TextStyle(color: GameConstants.inkColor),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              achievement.description,
              style: const TextStyle(color: GameConstants.mutedColor),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: achievement.progress / 100,
                    backgroundColor:
                        GameConstants.mutedColor.withValues(alpha: 0.25),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        GameConstants.primaryColor),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${achievement.progress}%',
                  style: const TextStyle(
                      fontSize: 12, color: GameConstants.mutedColor),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Icon(Icons.lock, size: 16, color: GameConstants.mutedColor),
            const SizedBox(height: 4),
            Text(
              '${achievement.pointValue} points',
              style: const TextStyle(color: GameConstants.mutedColor),
            ),
          ],
        ),
      ),
    );
  }
}
