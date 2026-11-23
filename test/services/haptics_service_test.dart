import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pachinko_game/services/haptics_service.dart';

/// The service's vibrations are read where the platform receives them: the
/// `HapticFeedback.vibrate` calls on the platform channel. A clock the test
/// moves by hand decides what the rate limit sees.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> vibrations;
  late Duration now;
  late HapticsService haptics;

  setUp(() {
    vibrations = [];
    now = Duration.zero;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        vibrations.add(call.arguments as String);
      }
      return null;
    });
    haptics = HapticsService(clock: () => now);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  const light = 'HapticFeedbackType.lightImpact';
  const medium = 'HapticFeedbackType.mediumImpact';
  const heavy = 'HapticFeedbackType.heavyImpact';

  /// Moves the clock on past the rate limit, so the next pulse stands alone.
  void waitOutTheLimit() => now += HapticsService.minimumInterval;

  group('which event gives which strength', () {
    test('a pin is a light tick', () {
      haptics.pin();
      expect(vibrations, [light]);
    });

    test('a prize peg is medium', () {
      haptics.prizePeg();
      expect(vibrations, [medium]);
    });

    test('the bonus is heavy', () {
      haptics.bonus();
      expect(vibrations, [heavy]);
    });

    test('a 1,000 or 2,000 slot is heavy, and a 50 or 200 slot is nothing', () {
      for (final points in [50, 200, 1000, 2000]) {
        haptics.slot(points);
        waitOutTheLimit();
      }
      expect(vibrations, [heavy, heavy]);
    });
  });

  group('rate limit', () {
    test('a ball rolling across pins does not buzz on every contact', () {
      // Ten pin contacts 10 ms apart: within one interval only the first
      // is felt
      for (var contact = 0; contact < 10; contact++) {
        haptics.pin();
        now += const Duration(milliseconds: 10);
      }
      expect(vibrations, [light, light]);
    });

    test('a pin is felt again once the interval has passed', () {
      haptics.pin();
      now += HapticsService.minimumInterval - const Duration(milliseconds: 1);
      haptics.pin();
      now += const Duration(milliseconds: 1);
      haptics.pin();
      expect(vibrations, [light, light]);
    });

    test('a stronger event is felt even straight after a weaker one', () {
      haptics.pin();
      haptics.prizePeg();
      haptics.bonus();
      expect(vibrations, [light, medium, heavy]);
    });

    test('a weaker or equal event straight after a stronger one is not', () {
      haptics.bonus();
      haptics.prizePeg();
      haptics.pin();
      haptics.slot(2000);
      expect(vibrations, [heavy]);
    });
  });

  test('without a clock of its own it reads elapsed real time', () {
    final realTime = HapticsService();
    realTime.pin();
    realTime.pin();
    expect(vibrations, [light]);
  });
}
