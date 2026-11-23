import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// How strongly the phone vibrates, weakest first.
enum HapticStrength { light, medium, heavy }

/// Vibrations for what happens on the board: a light tick for a pin, medium
/// for a prize peg, heavy for a 1,000 or 2,000 slot and for the bonus.
///
/// Rate limited, so that a ball rolling across pins does not buzz without a
/// break: within [minimumInterval] of the last pulse, only a stronger one is
/// felt.
class HapticsService {
  /// Creates the service. [clock] gives the time since some fixed start, and
  /// is for tests; without it the service reads elapsed real time.
  HapticsService({Duration Function()? clock})
      : _clock = clock ?? _elapsedRealTime();

  /// The shortest time between two pulses of the same or a weaker strength.
  static const Duration minimumInterval = Duration(milliseconds: 80);

  static Duration Function() _elapsedRealTime() {
    final stopwatch = Stopwatch()..start();
    return () => stopwatch.elapsed;
  }

  final Duration Function() _clock;
  Duration? _lastPulseAt;
  HapticStrength _lastStrength = HapticStrength.light;

  /// A ball bounced off a pin.
  void pin() => _pulse(HapticStrength.light);

  /// A ball collected a prize peg.
  void prizePeg() => _pulse(HapticStrength.medium);

  /// A ball landed in a slot worth [points]; only 1,000 and up are felt.
  void slot(int points) {
    if (points >= 1000) _pulse(HapticStrength.heavy);
  }

  /// The bonus triggered.
  void bonus() => _pulse(HapticStrength.heavy);

  void _pulse(HapticStrength strength) {
    final now = _clock();
    final last = _lastPulseAt;
    if (last != null &&
        now - last < minimumInterval &&
        strength.index <= _lastStrength.index) {
      return;
    }
    _lastPulseAt = now;
    _lastStrength = strength;
    _vibrate(strength);
  }

  /// Nothing awaits a vibration, so a platform that fails one is logged
  /// rather than left to raise an error no caller can catch.
  Future<void> _vibrate(HapticStrength strength) async {
    try {
      await switch (strength) {
        HapticStrength.light => HapticFeedback.lightImpact(),
        HapticStrength.medium => HapticFeedback.mediumImpact(),
        HapticStrength.heavy => HapticFeedback.heavyImpact(),
      };
    } catch (e) {
      debugPrint('HapticsService: could not vibrate: $e');
    }
  }
}
