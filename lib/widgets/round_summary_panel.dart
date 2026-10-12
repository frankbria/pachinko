import 'package:flutter/material.dart';
import '../models/round_summary.dart';
import '../models/slot.dart';
import '../utils/constants.dart';

/// The panel shown over the board when the last ball lands: what the round
/// scored and how, and where to go next.
class RoundSummaryPanel extends StatelessWidget {
  final RoundSummary summary;
  final VoidCallback onMenu;
  final VoidCallback onReplay;
  final VoidCallback onNextLevel;

  const RoundSummaryPanel({
    super.key,
    required this.summary,
    required this.onMenu,
    required this.onReplay,
    required this.onNextLevel,
  });

  /// 8550 as "8,550".
  static String grouped(int number) => number
      .toString()
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (match) => '${match[1]},');

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: GameConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GameConstants.secondaryColor.withValues(alpha: 0.6), width: 1.5),
      ),
      // Scrolls when the board's panel is shorter than the summary
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${GameStrings.level} ${summary.levelNumber}',
            style: text.titleMedium?.copyWith(color: GameConstants.mutedColor),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              grouped(summary.score),
              style: text.displaySmall?.copyWith(
                color: GameConstants.secondaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (summary.isNewBest == true)
            Text(
              GameStrings.newBest,
              style: text.labelLarge?.copyWith(color: GameConstants.secondaryColor),
            ),
          const SizedBox(height: 12),
          for (final tier in summary.tiers) _row(text, tier),
          const Divider(height: 20),
          _line(text, GameStrings.prizePegs, '${summary.prizePegsCollected} of ${summary.prizePegsTotal}'),
          if (summary.bonusBalls > 0) _line(text, GameStrings.bonusBalls, '+${summary.bonusBalls}'),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton(onPressed: onMenu, child: const Text(GameStrings.menu)),
              OutlinedButton(onPressed: onReplay, child: const Text(GameStrings.replay)),
              FilledButton(onPressed: onNextLevel, child: const Text(GameStrings.nextLevel)),
            ],
          ),
        ],
        ),
      ),
    );
  }

  /// One slot tier: its value in its colour, how many balls, what they scored.
  Widget _row(TextTheme text, SlotTierTally tier) {
    final colour = Slot.colorFor(tier.pointValue);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              '${tier.pointValue}',
              style: text.titleSmall?.copyWith(color: colour, fontWeight: FontWeight.bold),
            ),
          ),
          Text('× ${tier.balls}', style: text.bodyMedium?.copyWith(color: GameConstants.inkColor)),
          const Spacer(),
          Text(grouped(tier.points), style: text.bodyMedium?.copyWith(color: GameConstants.inkColor)),
        ],
      ),
    );
  }

  Widget _line(TextTheme text, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Text(label, style: text.bodyMedium?.copyWith(color: GameConstants.mutedColor)),
            const Spacer(),
            Text(value, style: text.bodyMedium?.copyWith(color: GameConstants.inkColor)),
          ],
        ),
      );
}
