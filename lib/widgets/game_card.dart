import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// The shared surface for a row or a card on the screens around the game:
/// dark glass with a hairline rim. [rim] replaces the rim's colour, for a
/// card that has something to say (an unlocked achievement is rimmed gold).
class GameCard extends StatelessWidget {
  final Widget child;
  final Color? rim;
  final EdgeInsetsGeometry padding;

  const GameCard({
    super.key,
    required this.child,
    this.rim,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: padding,
      decoration: BoxDecoration(
        color: GameConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: rim ?? GameConstants.mutedColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: child,
    );
  }
}

/// [number] with its thousands grouped: 12500 as "12,500".
String groupedThousands(int number) => number
    .toString()
    .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (match) => '${match[1]},');
