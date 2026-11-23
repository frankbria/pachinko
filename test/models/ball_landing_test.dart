import 'package:flutter_test/flutter_test.dart';
import 'package:pachinko_game/models/ball_landing.dart';

void main() {
  test('each slot of the row of seven is named by where it is', () {
    final names = [
      for (var index = 0; index < 7; index++)
        BallLanding(points: 50, slotIndex: index, slotCount: 7).slotName,
    ];

    expect(names, [
      'left edge',
      'second from left',
      'third from left',
      'centre',
      'third from right',
      'second from right',
      'right edge',
    ]);
  });

  test('two landings in the same slot are not equal, so each is heard', () {
    expect(BallLanding(points: 50, slotIndex: 1, slotCount: 7),
        isNot(BallLanding(points: 50, slotIndex: 1, slotCount: 7)));
  });
}
