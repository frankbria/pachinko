import 'package:flutter_test/flutter_test.dart';
import 'package:pachinko_game/utils/constants.dart';

/// How many balls the bonus drops on a level: five, one more for every two
/// levels, and never more than the maximum (owner's decision, #72).
void main() {
  test('given the first levels, then the bonus grows by one every two levels',
      () {
    expect(GameConstants.bonusBallsFor(1), 5);
    expect(GameConstants.bonusBallsFor(2), 6);
    expect(GameConstants.bonusBallsFor(3), 6);
    expect(GameConstants.bonusBallsFor(10), 10);
  });

  test('given level 20, then the bonus reaches its maximum, and stays there',
      () {
    expect(GameConstants.bonusBallsFor(19), 14);
    expect(GameConstants.bonusBallsFor(20), GameConstants.bonusBallsMax);
    expect(GameConstants.bonusBallsFor(21), GameConstants.bonusBallsMax);
    expect(GameConstants.bonusBallsFor(60), GameConstants.bonusBallsMax);
    expect(GameConstants.bonusBallsMax, 15);
  });

  test('given the maximum, then a round is never more than 35 balls', () {
    expect(GameConstants.ballsPerRound + GameConstants.bonusBallsMax, 35);
  });
}
