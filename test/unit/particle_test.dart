import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math.dart' hide Colors;
import 'package:pachinko_game/models/particle.dart';

void main() {
  group('Particle - Constructor Validation', () {
    test('should create particle with valid parameters', () {
      final particle = Particle(
        position: Vector2(100, 200),
        velocity: Vector2(10, -20),
        color: Colors.red,
        lifetime: 1.0,
        size: 5.0,
      );

      expect(particle.position, Vector2(100, 200));
      expect(particle.velocity, Vector2(10, -20));
      expect(particle.color, Colors.red);
      expect(particle.lifetime, 1.0);
      expect(particle.age, 0.0);
      expect(particle.size, 5.0);
      expect(particle.opacity, 1.0);
      expect(particle.isActive, true);
    });

    test('should create particle with custom age and opacity', () {
      final particle = Particle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.blue,
        lifetime: 2.0,
        age: 0.5,
        size: 10.0,
        opacity: 0.7,
        isActive: false,
      );

      expect(particle.age, 0.5);
      expect(particle.opacity, 0.7);
      expect(particle.isActive, false);
    });

    group('Validation - Lifetime', () {
      test('should throw ArgumentError when lifetime is 0', () {
        expect(
          () => Particle(
            position: Vector2.zero(),
            velocity: Vector2.zero(),
            color: Colors.white,
            lifetime: 0.0,
            size: 5.0,
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Lifetime must be greater than 0'),
          )),
        );
      });

      test('should throw ArgumentError when lifetime is negative', () {
        expect(
          () => Particle(
            position: Vector2.zero(),
            velocity: Vector2.zero(),
            color: Colors.white,
            lifetime: -1.0,
            size: 5.0,
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Lifetime must be greater than 0'),
          )),
        );
      });

      test('should accept minimum valid lifetime (just above 0)', () {
        final particle = Particle(
          position: Vector2.zero(),
          velocity: Vector2.zero(),
          color: Colors.white,
          lifetime: 0.001,
          size: 5.0,
        );

        expect(particle.lifetime, 0.001);
      });
    });

    group('Validation - Age', () {
      test('should throw ArgumentError when age is negative', () {
        expect(
          () => Particle(
            position: Vector2.zero(),
            velocity: Vector2.zero(),
            color: Colors.white,
            lifetime: 1.0,
            age: -0.1,
            size: 5.0,
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Age must be >= 0 and <= lifetime'),
          )),
        );
      });

      test('should throw ArgumentError when age exceeds lifetime', () {
        expect(
          () => Particle(
            position: Vector2.zero(),
            velocity: Vector2.zero(),
            color: Colors.white,
            lifetime: 1.0,
            age: 1.5,
            size: 5.0,
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Age must be >= 0 and <= lifetime'),
          )),
        );
      });

      test('should accept age equal to lifetime', () {
        final particle = Particle(
          position: Vector2.zero(),
          velocity: Vector2.zero(),
          color: Colors.white,
          lifetime: 1.0,
          age: 1.0,
          size: 5.0,
        );

        expect(particle.age, 1.0);
      });

      test('should accept age at zero', () {
        final particle = Particle(
          position: Vector2.zero(),
          velocity: Vector2.zero(),
          color: Colors.white,
          lifetime: 1.0,
          age: 0.0,
          size: 5.0,
        );

        expect(particle.age, 0.0);
      });
    });

    group('Validation - Size', () {
      test('should throw ArgumentError when size is 0', () {
        expect(
          () => Particle(
            position: Vector2.zero(),
            velocity: Vector2.zero(),
            color: Colors.white,
            lifetime: 1.0,
            size: 0.0,
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Size must be > 0 and <= 20'),
          )),
        );
      });

      test('should throw ArgumentError when size is negative', () {
        expect(
          () => Particle(
            position: Vector2.zero(),
            velocity: Vector2.zero(),
            color: Colors.white,
            lifetime: 1.0,
            size: -5.0,
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Size must be > 0 and <= 20'),
          )),
        );
      });

      test('should throw ArgumentError when size exceeds 20', () {
        expect(
          () => Particle(
            position: Vector2.zero(),
            velocity: Vector2.zero(),
            color: Colors.white,
            lifetime: 1.0,
            size: 20.1,
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Size must be > 0 and <= 20'),
          )),
        );
      });

      test('should accept size at maximum boundary (20)', () {
        final particle = Particle(
          position: Vector2.zero(),
          velocity: Vector2.zero(),
          color: Colors.white,
          lifetime: 1.0,
          size: 20.0,
        );

        expect(particle.size, 20.0);
      });

      test('should accept size just above minimum (0.01)', () {
        final particle = Particle(
          position: Vector2.zero(),
          velocity: Vector2.zero(),
          color: Colors.white,
          lifetime: 1.0,
          size: 0.01,
        );

        expect(particle.size, 0.01);
      });
    });

    group('Validation - Opacity', () {
      test('should throw ArgumentError when opacity is negative', () {
        expect(
          () => Particle(
            position: Vector2.zero(),
            velocity: Vector2.zero(),
            color: Colors.white,
            lifetime: 1.0,
            size: 5.0,
            opacity: -0.1,
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Opacity must be between 0.0 and 1.0'),
          )),
        );
      });

      test('should throw ArgumentError when opacity exceeds 1.0', () {
        expect(
          () => Particle(
            position: Vector2.zero(),
            velocity: Vector2.zero(),
            color: Colors.white,
            lifetime: 1.0,
            size: 5.0,
            opacity: 1.1,
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Opacity must be between 0.0 and 1.0'),
          )),
        );
      });

      test('should accept opacity at minimum boundary (0.0)', () {
        final particle = Particle(
          position: Vector2.zero(),
          velocity: Vector2.zero(),
          color: Colors.white,
          lifetime: 1.0,
          size: 5.0,
          opacity: 0.0,
        );

        expect(particle.opacity, 0.0);
      });

      test('should accept opacity at maximum boundary (1.0)', () {
        final particle = Particle(
          position: Vector2.zero(),
          velocity: Vector2.zero(),
          color: Colors.white,
          lifetime: 1.0,
          size: 5.0,
          opacity: 1.0,
        );

        expect(particle.opacity, 1.0);
      });

      test('should accept opacity in middle range (0.5)', () {
        final particle = Particle(
          position: Vector2.zero(),
          velocity: Vector2.zero(),
          color: Colors.white,
          lifetime: 1.0,
          size: 5.0,
          opacity: 0.5,
        );

        expect(particle.opacity, 0.5);
      });
    });
  });

  group('Particle - Lifecycle Management', () {
    test('should start as active by default', () {
      final particle = Particle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.white,
        lifetime: 1.0,
        size: 5.0,
      );

      expect(particle.isActive, true);
    });

    test('should allow creation as inactive', () {
      final particle = Particle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.white,
        lifetime: 1.0,
        size: 5.0,
        isActive: false,
      );

      expect(particle.isActive, false);
    });

    test('should deactivate when age reaches lifetime', () {
      final particle = Particle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.white,
        lifetime: 1.0,
        size: 5.0,
      );

      particle.update(1.0); // Age = 1.0 (equals lifetime)

      expect(particle.isActive, false);
    });

    test('should deactivate when age exceeds lifetime', () {
      final particle = Particle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.white,
        lifetime: 1.0,
        size: 5.0,
      );

      particle.update(1.5); // Age = 1.5 (exceeds lifetime)

      expect(particle.isActive, false);
    });

    test('should remain active when age is less than lifetime', () {
      final particle = Particle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.white,
        lifetime: 1.0,
        size: 5.0,
      );

      particle.update(0.5); // Age = 0.5 (less than lifetime)

      expect(particle.isActive, true);
    });

    test('should not update when inactive', () {
      final particle = Particle(
        position: Vector2(100, 200),
        velocity: Vector2(50, -30),
        color: Colors.white,
        lifetime: 1.0,
        size: 5.0,
        isActive: false,
      );

      final initialPosition = Vector2.copy(particle.position);
      final initialAge = particle.age;

      particle.update(0.1);

      expect(particle.position, initialPosition);
      expect(particle.age, initialAge);
    });
  });

  group('Particle - Position Updates', () {
    test('should update position based on velocity and deltaTime', () {
      final particle = Particle(
        position: Vector2(100, 200),
        velocity: Vector2(50, -30),
        color: Colors.white,
        lifetime: 1.0,
        size: 5.0,
      );

      particle.update(0.1); // deltaTime = 0.1s

      expect(particle.position.x, closeTo(105.0, 0.001)); // 100 + 50*0.1
      expect(particle.position.y, closeTo(197.0, 0.001)); // 200 + -30*0.1
    });

    test('should accumulate position changes over multiple updates', () {
      final particle = Particle(
        position: Vector2(0, 0),
        velocity: Vector2(100, -50),
        color: Colors.white,
        lifetime: 1.0,
        size: 5.0,
      );

      particle.update(0.1); // x = 10, y = -5
      particle.update(0.1); // x = 20, y = -10
      particle.update(0.1); // x = 30, y = -15

      expect(particle.position.x, closeTo(30.0, 0.001));
      expect(particle.position.y, closeTo(-15.0, 0.001));
    });

    test('should handle zero velocity (stationary particle)', () {
      final particle = Particle(
        position: Vector2(50, 75),
        velocity: Vector2(0, 0),
        color: Colors.white,
        lifetime: 1.0,
        size: 5.0,
      );

      particle.update(0.5);

      expect(particle.position.x, 50.0);
      expect(particle.position.y, 75.0);
    });

    test('should handle negative velocity correctly', () {
      final particle = Particle(
        position: Vector2(100, 100),
        velocity: Vector2(-40, -60),
        color: Colors.white,
        lifetime: 1.0,
        size: 5.0,
      );

      particle.update(0.1);

      expect(particle.position.x, closeTo(96.0, 0.001)); // 100 + -40*0.1
      expect(particle.position.y, closeTo(94.0, 0.001)); // 100 + -60*0.1
    });

    test('should handle very small deltaTime values', () {
      final particle = Particle(
        position: Vector2(10, 20),
        velocity: Vector2(100, 200),
        color: Colors.white,
        lifetime: 1.0,
        size: 5.0,
      );

      particle.update(0.001); // 1ms

      expect(particle.position.x, closeTo(10.1, 0.001));
      expect(particle.position.y, closeTo(20.2, 0.001));
    });
  });

  group('Particle - Age Updates', () {
    test('should increment age by deltaTime', () {
      final particle = Particle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.white,
        lifetime: 1.0,
        size: 5.0,
      );

      particle.update(0.25);

      expect(particle.age, closeTo(0.25, 0.001));
    });

    test('should accumulate age over multiple updates', () {
      final particle = Particle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.white,
        lifetime: 1.0,
        size: 5.0,
      );

      particle.update(0.2);
      particle.update(0.3);
      particle.update(0.4);

      expect(particle.age, closeTo(0.9, 0.001));
    });

    test('should handle very small deltaTime increments', () {
      final particle = Particle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.white,
        lifetime: 1.0,
        size: 5.0,
      );

      for (int i = 0; i < 100; i++) {
        particle.update(0.001); // 1ms increments
      }

      expect(particle.age, closeTo(0.1, 0.001));
    });

    test('should allow age to reach exactly lifetime', () {
      final particle = Particle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.white,
        lifetime: 2.0,
        size: 5.0,
      );

      particle.update(2.0);

      expect(particle.age, closeTo(2.0, 0.001));
    });

    test('should allow age to exceed lifetime', () {
      final particle = Particle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.white,
        lifetime: 1.0,
        size: 5.0,
      );

      particle.update(1.5);

      expect(particle.age, closeTo(1.5, 0.001));
    });
  });

  group('Particle - Opacity Fade', () {
    test('should maintain full opacity during first 70% of lifetime', () {
      final particle = Particle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.white,
        lifetime: 1.0,
        size: 5.0,
      );

      particle.update(0.69); // 69% of lifetime

      expect(particle.opacity, 1.0);
    });

    test('should start fading after 70% of lifetime', () {
      final particle = Particle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.white,
        lifetime: 1.0,
        size: 5.0,
      );

      particle.update(0.85); // 85% of lifetime (halfway through fade)

      expect(particle.opacity, lessThan(1.0));
      expect(particle.opacity, greaterThan(0.0));
    });

    test('should fade to 0 opacity at exactly lifetime', () {
      final particle = Particle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.white,
        lifetime: 1.0,
        size: 5.0,
      );

      particle.update(1.0); // 100% of lifetime

      expect(particle.opacity, 0.0);
    });

    test('should have approximately 0.5 opacity at 85% of lifetime', () {
      final particle = Particle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.white,
        lifetime: 1.0,
        size: 5.0,
      );

      particle.update(0.85); // 85% (midpoint of fade: 70% to 100%)

      // At 85%: fadeProgress = (0.85 - 0.7) / (1.0 - 0.7) = 0.15 / 0.3 = 0.5
      expect(particle.opacity, closeTo(0.5, 0.01));
    });

    test('should calculate fade progress correctly for different lifetimes', () {
      final particle = Particle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.white,
        lifetime: 2.0,
        size: 5.0,
      );

      // Fade starts at 1.4s (70% of 2.0s)
      particle.update(1.7); // Halfway through fade period

      expect(particle.opacity, closeTo(0.5, 0.01));
    });

    test('should not fade below 0 opacity', () {
      final particle = Particle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.white,
        lifetime: 1.0,
        size: 5.0,
      );

      particle.update(2.0); // Far beyond lifetime

      expect(particle.opacity, 0.0);
    });

    test('should handle opacity fade at exact 70% boundary', () {
      final particle = Particle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.white,
        lifetime: 1.0,
        size: 5.0,
      );

      particle.update(0.7); // Exactly 70%

      expect(particle.opacity, 1.0); // Should still be full opacity
    });

    test('should fade linearly in last 30% of lifetime', () {
      final particle = Particle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.white,
        lifetime: 1.0,
        size: 5.0,
      );

      // Test linear fade at 75%, 80%, 85%, 90%, 95%
      final testPoints = [
        (0.75, 0.833), // (age, expected opacity)
        (0.80, 0.667),
        (0.85, 0.5),
        (0.90, 0.333),
        (0.95, 0.167),
      ];

      for (final point in testPoints) {
        final testParticle = Particle(
          position: Vector2.zero(),
          velocity: Vector2.zero(),
          color: Colors.white,
          lifetime: 1.0,
          size: 5.0,
        );

        testParticle.update(point.$1);
        expect(testParticle.opacity, closeTo(point.$2, 0.01));
      }
    });

    test('should preserve custom initial opacity before fade starts', () {
      final particle = Particle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.white,
        lifetime: 1.0,
        size: 5.0,
        opacity: 0.5,
      );

      particle.update(0.5); // Before fade starts

      // Note: Current implementation resets to 1.0 during fade logic
      // This test will FAIL initially, revealing the behavior
      expect(particle.opacity, 0.5);
    });
  });

  group('Particle - Deactivation on Expiry', () {
    test('should deactivate when age equals lifetime', () {
      final particle = Particle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.white,
        lifetime: 1.0,
        size: 5.0,
      );

      particle.update(1.0);

      expect(particle.isActive, false);
      expect(particle.opacity, 0.0);
    });

    test('should deactivate when age exceeds lifetime', () {
      final particle = Particle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.white,
        lifetime: 1.0,
        size: 5.0,
      );

      particle.update(1.5);

      expect(particle.isActive, false);
      expect(particle.opacity, 0.0);
    });

    test('should set opacity to 0 on deactivation', () {
      final particle = Particle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.white,
        lifetime: 1.0,
        size: 5.0,
        opacity: 0.8,
      );

      particle.update(1.0);

      expect(particle.opacity, 0.0);
    });

    test('should not deactivate when age is just below lifetime', () {
      final particle = Particle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.white,
        lifetime: 1.0,
        size: 5.0,
      );

      particle.update(0.999);

      expect(particle.isActive, true);
    });

    test('should handle multiple updates leading to deactivation', () {
      final particle = Particle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.white,
        lifetime: 1.0,
        size: 5.0,
      );

      particle.update(0.4);
      expect(particle.isActive, true);

      particle.update(0.4);
      expect(particle.isActive, true);

      particle.update(0.3); // Total: 1.1s
      expect(particle.isActive, false);
    });
  });

  group('Particle - Edge Cases', () {
    test('should handle very long lifetime', () {
      final particle = Particle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.white,
        lifetime: 1000.0,
        size: 5.0,
      );

      particle.update(500.0);

      expect(particle.isActive, true);
      expect(particle.opacity, 1.0); // Still in first 70% (700s)
    });

    test('should handle very short lifetime', () {
      final particle = Particle(
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        color: Colors.white,
        lifetime: 0.01,
        size: 5.0,
      );

      particle.update(0.005); // 50% of lifetime

      expect(particle.isActive, true);

      particle.update(0.006); // Total: 110% of lifetime

      expect(particle.isActive, false);
    });

    test('should handle zero deltaTime update', () {
      final particle = Particle(
        position: Vector2(100, 200),
        velocity: Vector2(50, -30),
        color: Colors.white,
        lifetime: 1.0,
        size: 5.0,
      );

      particle.update(0.0);

      expect(particle.position, Vector2(100, 200));
      expect(particle.age, 0.0);
      expect(particle.isActive, true);
    });

    test('should handle very high velocity values', () {
      final particle = Particle(
        position: Vector2(0, 0),
        velocity: Vector2(10000, -10000),
        color: Colors.white,
        lifetime: 1.0,
        size: 5.0,
      );

      particle.update(0.1);

      expect(particle.position.x, closeTo(1000.0, 0.001));
      expect(particle.position.y, closeTo(-1000.0, 0.001));
    });

    test('should maintain mutable properties across updates', () {
      final particle = Particle(
        position: Vector2(100, 200),
        velocity: Vector2(50, -30),
        color: Colors.red,
        lifetime: 1.0,
        size: 5.0,
      );

      // Manually modify properties
      particle.position = Vector2(300, 400);
      particle.velocity = Vector2(0, 0);
      particle.color = Colors.blue;

      particle.update(0.1);

      expect(particle.position, Vector2(300, 400)); // Velocity is 0, no movement
      expect(particle.color, Colors.blue);
    });
  });

  group('Particle - Integration Scenarios', () {
    test('should simulate complete particle lifecycle', () {
      final particle = Particle(
        position: Vector2(100, 100),
        velocity: Vector2(50, -50),
        color: Colors.orange,
        lifetime: 1.0,
        size: 8.0,
      );

      // Early life (0-70%): Full opacity, position updates
      particle.update(0.35);
      expect(particle.opacity, 1.0);
      expect(particle.isActive, true);
      expect(particle.position.x, closeTo(117.5, 0.1));

      particle.update(0.35); // Total: 0.7s
      expect(particle.opacity, 1.0);
      expect(particle.isActive, true);

      // Fade period (70-100%): Opacity decreases
      particle.update(0.2); // Total: 0.9s
      expect(particle.opacity, lessThan(1.0));
      expect(particle.opacity, greaterThan(0.0));
      expect(particle.isActive, true);

      // End of life: Deactivated
      particle.update(0.15); // Total: 1.05s
      expect(particle.opacity, 0.0);
      expect(particle.isActive, false);

      // After deactivation: No further updates
      final finalPos = Vector2.copy(particle.position);
      particle.update(1.0);
      expect(particle.position, finalPos);
    });

    test('should handle pooling use case (reactivation)', () {
      final particle = Particle(
        position: Vector2(50, 50),
        velocity: Vector2(10, 10),
        color: Colors.green,
        lifetime: 1.0,
        size: 5.0,
      );

      // Expire particle
      particle.update(1.0);
      expect(particle.isActive, false);

      // Simulate pooling reactivation
      particle.isActive = true;
      particle.age = 0.0;
      particle.opacity = 1.0;
      particle.position = Vector2(100, 100);
      particle.velocity = Vector2(20, -20);

      // Should behave like new particle
      particle.update(0.5);
      expect(particle.isActive, true);
      expect(particle.opacity, 1.0);
      expect(particle.position.x, closeTo(110.0, 0.1));
    });
  });
}
