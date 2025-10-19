/// Unit tests for AnimationState and animation system
///
/// Tests Requirements (from spec.md AC2.2, AC2.3):
/// - AnimationState creation with id, duration, curve, loop
/// - start() begins animation progression
/// - getValue() returns current progress (0.0 to 1.0)
/// - update() advances running animations by deltaTime
/// - Curve application (linear, easeIn, easeOut, easeInOut)
/// - Looping animations wrap to 0.0 progress
/// - Non-looping animations stop at 1.0
/// - Multiple concurrent animations
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:pachinko_game/services/graphics/animation_controller.dart';

void main() {
  group('AnimationState', () {
    group('creation and initialization', () {
      test('creates animation with required parameters', () {
        final animation = AnimationState(
          id: 'test-anim',
          duration: 2.0,
        );

        expect(animation.id, equals('test-anim'));
        expect(animation.duration, equals(2.0));
        expect(animation.curve, equals(AnimationCurve.linear));
        expect(animation.loop, isFalse);
        expect(animation.progress, equals(0.0));
        expect(animation.elapsedTime, equals(0.0));
        expect(animation.isRunning, isTrue);
      });

      test('creates animation with custom curve', () {
        final animation = AnimationState(
          id: 'ease-in-anim',
          duration: 1.5,
          curve: AnimationCurve.easeIn,
        );

        expect(animation.curve, equals(AnimationCurve.easeIn));
      });

      test('creates animation with loop enabled', () {
        final animation = AnimationState(
          id: 'looping-anim',
          duration: 1.0,
          loop: true,
        );

        expect(animation.loop, isTrue);
      });

      test('creates animation with custom initial values', () {
        final animation = AnimationState(
          id: 'custom-anim',
          duration: 3.0,
          progress: 0.5,
          elapsedTime: 1.5,
          isRunning: false,
        );

        expect(animation.progress, equals(0.5));
        expect(animation.elapsedTime, equals(1.5));
        expect(animation.isRunning, isFalse);
      });

      test('throws assertion error when duration is zero', () {
        expect(
          () => AnimationState(id: 'invalid', duration: 0.0),
          throwsA(isA<AssertionError>()),
        );
      });

      test('throws assertion error when duration is negative', () {
        expect(
          () => AnimationState(id: 'invalid', duration: -1.0),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('copyWith', () {
      test('creates copy with updated id', () {
        final original = AnimationState(id: 'original', duration: 1.0);
        final copy = original.copyWith(id: 'updated');

        expect(copy.id, equals('updated'));
        expect(copy.duration, equals(1.0));
      });

      test('creates copy with updated duration', () {
        final original = AnimationState(id: 'test', duration: 1.0);
        final copy = original.copyWith(duration: 2.5);

        expect(copy.id, equals('test'));
        expect(copy.duration, equals(2.5));
      });

      test('creates copy with updated curve', () {
        final original = AnimationState(id: 'test', duration: 1.0);
        final copy = original.copyWith(curve: AnimationCurve.easeOut);

        expect(copy.curve, equals(AnimationCurve.easeOut));
      });

      test('creates copy with updated loop', () {
        final original = AnimationState(id: 'test', duration: 1.0);
        final copy = original.copyWith(loop: true);

        expect(copy.loop, isTrue);
      });

      test('creates copy with updated progress', () {
        final original = AnimationState(id: 'test', duration: 1.0);
        final copy = original.copyWith(progress: 0.75);

        expect(copy.progress, equals(0.75));
      });

      test('creates copy with updated elapsedTime', () {
        final original = AnimationState(id: 'test', duration: 2.0);
        final copy = original.copyWith(elapsedTime: 1.2);

        expect(copy.elapsedTime, equals(1.2));
      });

      test('creates copy with updated isRunning', () {
        final original = AnimationState(id: 'test', duration: 1.0);
        final copy = original.copyWith(isRunning: false);

        expect(copy.isRunning, isFalse);
      });

      test('creates copy with multiple updated fields', () {
        final original = AnimationState(id: 'test', duration: 1.0);
        final copy = original.copyWith(
          progress: 0.5,
          elapsedTime: 0.5,
          isRunning: false,
        );

        expect(copy.progress, equals(0.5));
        expect(copy.elapsedTime, equals(0.5));
        expect(copy.isRunning, isFalse);
      });

      test('preserves original values when no parameters provided', () {
        final original = AnimationState(
          id: 'test',
          duration: 2.0,
          curve: AnimationCurve.easeIn,
          loop: true,
          progress: 0.3,
          elapsedTime: 0.6,
          isRunning: false,
        );
        final copy = original.copyWith();

        expect(copy.id, equals('test'));
        expect(copy.duration, equals(2.0));
        expect(copy.curve, equals(AnimationCurve.easeIn));
        expect(copy.loop, isTrue);
        expect(copy.progress, equals(0.3));
        expect(copy.elapsedTime, equals(0.6));
        expect(copy.isRunning, isFalse);
      });
    });

    group('equality and hashCode', () {
      test('two animations with same values are equal', () {
        final anim1 = AnimationState(
          id: 'test',
          duration: 1.0,
          curve: AnimationCurve.linear,
          loop: false,
          progress: 0.5,
          elapsedTime: 0.5,
          isRunning: true,
        );
        final anim2 = AnimationState(
          id: 'test',
          duration: 1.0,
          curve: AnimationCurve.linear,
          loop: false,
          progress: 0.5,
          elapsedTime: 0.5,
          isRunning: true,
        );

        expect(anim1, equals(anim2));
        expect(anim1.hashCode, equals(anim2.hashCode));
      });

      test('animations with different ids are not equal', () {
        final anim1 = AnimationState(id: 'test1', duration: 1.0);
        final anim2 = AnimationState(id: 'test2', duration: 1.0);

        expect(anim1, isNot(equals(anim2)));
      });

      test('animations with different durations are not equal', () {
        final anim1 = AnimationState(id: 'test', duration: 1.0);
        final anim2 = AnimationState(id: 'test', duration: 2.0);

        expect(anim1, isNot(equals(anim2)));
      });

      test('animations with different curves are not equal', () {
        final anim1 = AnimationState(
          id: 'test',
          duration: 1.0,
          curve: AnimationCurve.linear,
        );
        final anim2 = AnimationState(
          id: 'test',
          duration: 1.0,
          curve: AnimationCurve.easeIn,
        );

        expect(anim1, isNot(equals(anim2)));
      });

      test('animations with different loop values are not equal', () {
        final anim1 = AnimationState(id: 'test', duration: 1.0, loop: false);
        final anim2 = AnimationState(id: 'test', duration: 1.0, loop: true);

        expect(anim1, isNot(equals(anim2)));
      });

      test('animations with different progress are not equal', () {
        final anim1 = AnimationState(
          id: 'test',
          duration: 1.0,
          progress: 0.3,
        );
        final anim2 = AnimationState(
          id: 'test',
          duration: 1.0,
          progress: 0.5,
        );

        expect(anim1, isNot(equals(anim2)));
      });

      test('identical objects are equal', () {
        final anim = AnimationState(id: 'test', duration: 1.0);

        expect(anim, equals(anim));
      });
    });

    group('toString', () {
      test('includes all relevant fields', () {
        final animation = AnimationState(
          id: 'test-anim',
          duration: 2.5,
          curve: AnimationCurve.easeIn,
          loop: true,
          progress: 0.35,
          elapsedTime: 0.875,
          isRunning: true,
        );

        final str = animation.toString();
        expect(str, contains('test-anim'));
        expect(str, contains('2.5'));
        expect(str, contains('0.35'));
        expect(str, contains('0.88')); // elapsedTime rounded to 2 decimals
        expect(str, contains('easeIn'));
        expect(str, contains('true')); // isRunning and loop
      });
    });
  });

  group('AnimationCurve', () {
    test('has all required curve types', () {
      expect(AnimationCurve.values, contains(AnimationCurve.linear));
      expect(AnimationCurve.values, contains(AnimationCurve.easeIn));
      expect(AnimationCurve.values, contains(AnimationCurve.easeOut));
      expect(AnimationCurve.values, contains(AnimationCurve.easeInOut));
    });

    test('has exactly four curve types', () {
      expect(AnimationCurve.values.length, equals(4));
    });
  });

  group('AnimationController', () {
    group('createAnimation', () {
      test('creates and registers animation with controller', () {
        final controller = AnimationController();
        final animation = controller.createAnimation(
          id: 'test-anim',
          duration: 2.0,
        );

        expect(animation.id, equals('test-anim'));
        expect(animation.duration, equals(2.0));
        expect(animation.isRunning, isFalse); // Starts paused
        expect(controller.hasAnimation('test-anim'), isTrue);
        expect(controller.animationCount, equals(1));
      });

      test('creates animation with custom curve', () {
        final controller = AnimationController();
        final animation = controller.createAnimation(
          id: 'ease-anim',
          duration: 1.5,
          curve: AnimationCurve.easeIn,
        );

        expect(animation.curve, equals(AnimationCurve.easeIn));
      });

      test('creates animation with loop enabled', () {
        final controller = AnimationController();
        final animation = controller.createAnimation(
          id: 'loop-anim',
          duration: 1.0,
          loop: true,
        );

        expect(animation.loop, isTrue);
      });
    });

    group('start and stop', () {
      test('start() begins animation progression', () {
        final controller = AnimationController();
        controller.createAnimation(id: 'test', duration: 1.0);

        final started = controller.start('test');
        expect(started, isTrue);

        final value = controller.getValue('test');
        expect(value, isNotNull);
      });

      test('start() returns false for non-existent animation', () {
        final controller = AnimationController();
        expect(controller.start('nonexistent'), isFalse);
      });

      test('stop() pauses animation', () {
        final controller = AnimationController();
        controller.createAnimation(id: 'test', duration: 1.0);
        controller.start('test');

        final stopped = controller.stop('test');
        expect(stopped, isTrue);
      });

      test('stop() returns false for non-existent animation', () {
        final controller = AnimationController();
        expect(controller.stop('nonexistent'), isFalse);
      });
    });

    group('getValue', () {
      test('returns current progress with curve applied', () {
        final controller = AnimationController();
        controller.createAnimation(id: 'test', duration: 1.0);
        controller.start('test');

        final value = controller.getValue('test');
        expect(value, isNotNull);
        expect(value, greaterThanOrEqualTo(0.0));
        expect(value, lessThanOrEqualTo(1.0));
      });

      test('returns null for non-existent animation', () {
        final controller = AnimationController();
        expect(controller.getValue('nonexistent'), isNull);
      });

      test('linear curve returns raw progress', () {
        final controller = AnimationController();
        controller.createAnimation(
          id: 'linear',
          duration: 1.0,
          curve: AnimationCurve.linear,
        );
        controller.start('linear');
        controller.update(0.5); // 50% through

        final value = controller.getValue('linear');
        expect(value, closeTo(0.5, 0.01));
      });

      test('easeIn curve applies slow start', () {
        final controller = AnimationController();
        controller.createAnimation(
          id: 'ease-in',
          duration: 1.0,
          curve: AnimationCurve.easeIn,
        );
        controller.start('ease-in');
        controller.update(0.5);

        final value = controller.getValue('ease-in');
        // easeIn(0.5) = 0.5^2 = 0.25
        expect(value, closeTo(0.25, 0.01));
      });

      test('easeOut curve applies slow end', () {
        final controller = AnimationController();
        controller.createAnimation(
          id: 'ease-out',
          duration: 1.0,
          curve: AnimationCurve.easeOut,
        );
        controller.start('ease-out');
        controller.update(0.5);

        final value = controller.getValue('ease-out');
        // easeOut(0.5) = 1 - (1-0.5)^2 = 1 - 0.25 = 0.75
        expect(value, closeTo(0.75, 0.01));
      });

      test('easeInOut curve applies slow start and end', () {
        final controller = AnimationController();
        controller.createAnimation(
          id: 'ease-in-out',
          duration: 1.0,
          curve: AnimationCurve.easeInOut,
        );
        controller.start('ease-in-out');
        controller.update(0.25);

        final value = controller.getValue('ease-in-out');
        // easeInOut(0.25) = 2 * 0.25^2 = 0.125
        expect(value, closeTo(0.125, 0.01));
      });
    });

    group('update', () {
      test('advances running animations by deltaTime', () {
        final controller = AnimationController();
        controller.createAnimation(id: 'test', duration: 2.0);
        controller.start('test');

        controller.update(0.5);

        final value = controller.getValue('test');
        expect(value, closeTo(0.25, 0.01)); // 0.5 / 2.0 = 0.25
      });

      test('does not update stopped animations', () {
        final controller = AnimationController();
        controller.createAnimation(id: 'test', duration: 1.0);
        controller.start('test');
        controller.stop('test');

        controller.update(0.5);

        final value = controller.getValue('test');
        expect(value, equals(0.0)); // Still at start
      });

      test('looping animations wrap to 0.0 progress', () {
        final controller = AnimationController();
        controller.createAnimation(
          id: 'loop',
          duration: 1.0,
          loop: true,
        );
        controller.start('loop');

        controller.update(1.5); // Past duration

        final value = controller.getValue('loop');
        expect(value, closeTo(0.5, 0.01)); // Wrapped around
      });

      test('non-looping animations stop at 1.0', () {
        final controller = AnimationController();
        controller.createAnimation(
          id: 'once',
          duration: 1.0,
          loop: false,
        );
        controller.start('once');

        controller.update(1.5); // Past duration

        final value = controller.getValue('once');
        expect(value, equals(1.0)); // Clamped at end
      });

      test('multiple updates accumulate time', () {
        final controller = AnimationController();
        controller.createAnimation(id: 'test', duration: 2.0);
        controller.start('test');

        controller.update(0.5);
        controller.update(0.5);

        final value = controller.getValue('test');
        expect(value, closeTo(0.5, 0.01)); // 1.0 / 2.0 = 0.5
      });
    });

    group('multiple concurrent animations', () {
      test('handles multiple animations independently', () {
        final controller = AnimationController();
        controller.createAnimation(id: 'anim1', duration: 1.0);
        controller.createAnimation(id: 'anim2', duration: 2.0);

        controller.start('anim1');
        controller.start('anim2');
        controller.update(0.5);

        final value1 = controller.getValue('anim1');
        final value2 = controller.getValue('anim2');

        expect(value1, closeTo(0.5, 0.01)); // 0.5 / 1.0
        expect(value2, closeTo(0.25, 0.01)); // 0.5 / 2.0
      });

      test('different curves work independently', () {
        final controller = AnimationController();
        controller.createAnimation(
          id: 'linear',
          duration: 1.0,
          curve: AnimationCurve.linear,
        );
        controller.createAnimation(
          id: 'easeIn',
          duration: 1.0,
          curve: AnimationCurve.easeIn,
        );

        controller.start('linear');
        controller.start('easeIn');
        controller.update(0.5);

        final linearVal = controller.getValue('linear');
        final easeInVal = controller.getValue('easeIn');

        expect(linearVal, closeTo(0.5, 0.01));
        expect(easeInVal, closeTo(0.25, 0.01)); // 0.5^2
      });
    });

    group('animation management', () {
      test('removeAnimation removes animation from controller', () {
        final controller = AnimationController();
        controller.createAnimation(id: 'test', duration: 1.0);

        final removed = controller.removeAnimation('test');
        expect(removed, isTrue);
        expect(controller.hasAnimation('test'), isFalse);
        expect(controller.animationCount, equals(0));
      });

      test('removeAnimation returns false for non-existent animation', () {
        final controller = AnimationController();
        expect(controller.removeAnimation('nonexistent'), isFalse);
      });

      test('animationIds returns all registered IDs', () {
        final controller = AnimationController();
        controller.createAnimation(id: 'anim1', duration: 1.0);
        controller.createAnimation(id: 'anim2', duration: 2.0);

        final ids = controller.animationIds;
        expect(ids, contains('anim1'));
        expect(ids, contains('anim2'));
        expect(ids.length, equals(2));
      });

      test('animationCount returns correct count', () {
        final controller = AnimationController();
        expect(controller.animationCount, equals(0));

        controller.createAnimation(id: 'anim1', duration: 1.0);
        expect(controller.animationCount, equals(1));

        controller.createAnimation(id: 'anim2', duration: 2.0);
        expect(controller.animationCount, equals(2));

        controller.removeAnimation('anim1');
        expect(controller.animationCount, equals(1));
      });
    });
  });
}