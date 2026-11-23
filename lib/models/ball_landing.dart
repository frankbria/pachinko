/// A ball landing in a slot, as the game screen announces it to a screen
/// reader.
///
/// Each landing is a new object, without value equality, so that two
/// landings in the same slot in a row are each heard.
class BallLanding {
  /// The points the slot is worth.
  final int points;

  /// Where the slot is in the row, from 0 at the left.
  final int slotIndex;

  /// How many slots the row has.
  final int slotCount;

  BallLanding({
    required this.points,
    required this.slotIndex,
    required this.slotCount,
  });

  static const List<String> _ordinals = ['second', 'third', 'fourth', 'fifth'];

  /// Where the slot is, in words: "left edge", "centre", "second from
  /// right" and so on.
  String get slotName {
    final fromRight = slotCount - 1 - slotIndex;
    if (slotIndex == 0) return 'left edge';
    if (fromRight == 0) return 'right edge';
    if (slotIndex == fromRight) return 'centre';
    final fromEdge = slotIndex < fromRight ? slotIndex : fromRight;
    final side = slotIndex < fromRight ? 'left' : 'right';
    // shortcut: words for rows of up to eleven slots; the row has seven, and
    // a longer one needs more ordinals here
    return '${_ordinals[fromEdge - 1]} from $side';
  }
}
