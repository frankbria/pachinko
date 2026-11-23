import 'package:flutter/material.dart';
import '../models/star_targets.dart';
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

/// A level's stars: a gold star for each one won and an outline for each
/// still to win. The words beside it say the same, so a screen reader is
/// not told it twice.
class StarRow extends StatelessWidget {
  /// The stars won, 0 to [StarTargets.maxStars].
  final int stars;

  /// The size of each star.
  final double size;

  const StarRow({super.key, required this.stars, required this.size});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < StarTargets.maxStars; i++)
            i < stars
                ? Icon(Icons.star,
                    size: size, color: GameConstants.secondaryColor)
                : Icon(Icons.star_border,
                    size: size, color: GameConstants.mutedColor),
        ],
      ),
    );
  }
}
