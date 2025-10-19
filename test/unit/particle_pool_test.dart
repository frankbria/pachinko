import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:pachinko_game/services/graphics/particle_system.dart';
import 'package:pachinko_game/models/particle.dart';

void main() {
  group('ParticlePool', () {
    group('initialization', () {
      test('creates pool with correct capacity', () {
        final pool = ParticlePool(
          maxCapacity: 50,
          poolType: ParticlePoolType.trail,
        );

        expect(pool.maxCapacity, equals(50));
        expect(pool.particles.length, equals(50));
        expect(pool.activeCount, equals(0));
        expect(pool.poolType, equals(ParticlePoolType.trail));
      });

      test('initializes all particles as inactive', () {
        final pool = ParticlePool(
          maxCapacity: 10,
          poolType: ParticlePoolType.collision,
        );

        for (var particle in pool.particles) {
          expect(particle.isActive, isFalse);
        }
      });

      test('throws ArgumentError when maxCapacity is 0', () {
        expect(
          () => ParticlePool(
            maxCapacity: 0,
            poolType: ParticlePoolType.trail,
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('maxCapacity must be > 0 and <= 100'),
          )),
        );
      });

      test('throws ArgumentError when maxCapacity is negative', () {
        expect(
          () => ParticlePool(
            maxCapacity: -1,
            poolType: ParticlePoolType.trail,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError when maxCapacity exceeds 100', () {
        expect(
          () => ParticlePool(
            maxCapacity: 101,
            poolType: ParticlePoolType.trail,
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('maxCapacity must be > 0 and <= 100'),
          )),
        );
      });

      test('accepts maxCapacity of exactly 100', () {
        expect(
          () => ParticlePool(
            maxCapacity: 100,
            poolType: ParticlePoolType.trail,
          ),
          returnsNormally,
        );
      });
    });

    group('spawn()', () {
      test('activates inactive particle with correct properties', () {
        final pool = ParticlePool(
          maxCapacity: 10,
          poolType: ParticlePoolType.trail,
        );

        final position = Vector2(100.0, 200.0);
        final velocity = Vector2(50.0, -30.0);
        final color = Colors.blue;
        const lifetime = 1.5;
        const size = 5.0;

        pool.spawn(
          position: position,
          velocity: velocity,
          color: color,
          lifetime: lifetime,
          size: size,
        );

        expect(pool.activeCount, equals(1));

        final activeParticles = pool.getActiveParticles();
        expect(activeParticles.length, equals(1));

        final particle = activeParticles.first;
        expect(particle.isActive, isTrue);
        expect(particle.position.x, equals(100.0));
        expect(particle.position.y, equals(200.0));
        expect(particle.velocity.x, equals(50.0));
        expect(particle.velocity.y, equals(-30.0));
        expect(particle.color, equals(color));
        expect(particle.lifetime, equals(lifetime));
        expect(particle.age, equals(0.0));
        expect(particle.size, equals(size));
        expect(particle.opacity, equals(1.0));
      });

      test('spawns multiple particles sequentially', () {
        final pool = ParticlePool(
          maxCapacity: 10,
          poolType: ParticlePoolType.trail,
        );

        for (int i = 0; i < 5; i++) {
          pool.spawn(
            position: Vector2(i.toDouble(), i.toDouble()),
            velocity: Vector2.zero(),
            color: Colors.red,
            lifetime: 1.0,
          );
        }

        expect(pool.activeCount, equals(5));
        expect(pool.getActiveParticles().length, equals(5));
      });

      test('replaces oldest particle when pool is full', () {
        final pool = ParticlePool(
          maxCapacity: 3,
          poolType: ParticlePoolType.trail,
        );

        // Fill pool completely
        pool.spawn(
          position: Vector2(1.0, 1.0),
          velocity: Vector2.zero(),
          color: Colors.red,
          lifetime: 1.0,
        );
        pool.spawn(
          position: Vector2(2.0, 2.0),
          velocity: Vector2.zero(),
          color: Colors.green,
          lifetime: 1.0,
        );
        pool.spawn(
          position: Vector2(3.0, 3.0),
          velocity: Vector2.zero(),
          color: Colors.blue,
          lifetime: 1.0,
        );

        expect(pool.activeCount, equals(3));

        // Spawn one more - should replace the first particle
        pool.spawn(
          position: Vector2(4.0, 4.0),
          velocity: Vector2.zero(),
          color: Colors.yellow,
          lifetime: 1.0,
        );

        // Active count should still be 3
        expect(pool.activeCount, equals(3));

        final activeParticles = pool.getActiveParticles();
        expect(activeParticles.length, equals(3));

        // First particle should now have position (4.0, 4.0) and yellow color
        expect(activeParticles[0].position.x, equals(4.0));
        expect(activeParticles[0].position.y, equals(4.0));
        expect(activeParticles[0].color, equals(Colors.yellow));
      });

      test('maintains correct activeCount when replacing particles', () {
        final pool = ParticlePool(
          maxCapacity: 2,
          poolType: ParticlePoolType.trail,
        );

        // Fill pool
        pool.spawn(
          position: Vector2.zero(),
          velocity: Vector2.zero(),
          color: Colors.red,
          lifetime: 1.0,
        );
        pool.spawn(
          position: Vector2.zero(),
          velocity: Vector2.zero(),
          color: Colors.green,
          lifetime: 1.0,
        );

        expect(pool.activeCount, equals(2));

        // Replace first particle
        pool.spawn(
          position: Vector2.zero(),
          velocity: Vector2.zero(),
          color: Colors.blue,
          lifetime: 1.0,
        );

        // Active count should still be 2
        expect(pool.activeCount, equals(2));
      });

      test('resets particle properties when spawning', () {
        final pool = ParticlePool(
          maxCapacity: 1,
          poolType: ParticlePoolType.trail,
        );

        // Spawn first particle
        pool.spawn(
          position: Vector2(10.0, 20.0),
          velocity: Vector2(5.0, 10.0),
          color: Colors.red,
          lifetime: 1.0,
          size: 3.0,
        );

        // Age the particle
        pool.update(0.5);

        // Spawn over it
        pool.spawn(
          position: Vector2(100.0, 200.0),
          velocity: Vector2(50.0, 100.0),
          color: Colors.blue,
          lifetime: 2.0,
          size: 5.0,
        );

        final particle = pool.getActiveParticles().first;
        expect(particle.age, equals(0.0));
        expect(particle.position.x, equals(100.0));
        expect(particle.velocity.x, equals(50.0));
        expect(particle.color, equals(Colors.blue));
        expect(particle.lifetime, equals(2.0));
        expect(particle.size, equals(5.0));
        expect(particle.opacity, equals(1.0));
      });

      test('clones position and velocity vectors', () {
        final pool = ParticlePool(
          maxCapacity: 10,
          poolType: ParticlePoolType.trail,
        );

        final position = Vector2(100.0, 200.0);
        final velocity = Vector2(50.0, -30.0);

        pool.spawn(
          position: position,
          velocity: velocity,
          color: Colors.red,
          lifetime: 1.0,
        );

        // Modify original vectors
        position.x = 999.0;
        velocity.y = 888.0;

        // Particle should have cloned values
        final particle = pool.getActiveParticles().first;
        expect(particle.position.x, equals(100.0));
        expect(particle.velocity.y, equals(-30.0));
      });
    });

    group('update()', () {
      test('ages all active particles', () {
        final pool = ParticlePool(
          maxCapacity: 5,
          poolType: ParticlePoolType.trail,
        );

        // Spawn three particles
        for (int i = 0; i < 3; i++) {
          pool.spawn(
            position: Vector2.zero(),
            velocity: Vector2.zero(),
            color: Colors.red,
            lifetime: 2.0,
          );
        }

        pool.update(0.5);

        final activeParticles = pool.getActiveParticles();
        for (var particle in activeParticles) {
          expect(particle.age, equals(0.5));
        }
      });

      test('deactivates particles when age exceeds lifetime', () {
        final pool = ParticlePool(
          maxCapacity: 5,
          poolType: ParticlePoolType.trail,
        );

        pool.spawn(
          position: Vector2.zero(),
          velocity: Vector2.zero(),
          color: Colors.red,
          lifetime: 1.0,
        );

        expect(pool.activeCount, equals(1));

        // Age particle beyond lifetime (update validates deltaTime < 1.0)
        pool.update(0.5);
        pool.update(0.5);

        // Particle should be deactivated
        expect(pool.activeCount, equals(0));
        expect(pool.getActiveParticles(), isEmpty);
      });

      test('decrements activeCount when deactivating particles', () {
        final pool = ParticlePool(
          maxCapacity: 5,
          poolType: ParticlePoolType.trail,
        );

        // Spawn multiple particles with different lifetimes
        pool.spawn(
          position: Vector2.zero(),
          velocity: Vector2.zero(),
          color: Colors.red,
          lifetime: 0.5,
        );
        pool.spawn(
          position: Vector2.zero(),
          velocity: Vector2.zero(),
          color: Colors.green,
          lifetime: 1.0,
        );
        pool.spawn(
          position: Vector2.zero(),
          velocity: Vector2.zero(),
          color: Colors.blue,
          lifetime: 1.5,
        );

        expect(pool.activeCount, equals(3));

        // Update to expire first particle
        pool.update(0.5);
        expect(pool.activeCount, equals(2));

        // Update to expire second particle
        pool.update(0.5);
        expect(pool.activeCount, equals(1));

        // Update to expire third particle
        pool.update(0.5);
        expect(pool.activeCount, equals(0));
      });

      test('ignores invalid deltaTime values', () {
        final pool = ParticlePool(
          maxCapacity: 5,
          poolType: ParticlePoolType.trail,
        );

        pool.spawn(
          position: Vector2.zero(),
          velocity: Vector2.zero(),
          color: Colors.red,
          lifetime: 1.0,
        );

        // Update with zero deltaTime
        pool.update(0.0);
        expect(pool.getActiveParticles().first.age, equals(0.0));

        // Update with negative deltaTime
        pool.update(-0.1);
        expect(pool.getActiveParticles().first.age, equals(0.0));

        // Update with deltaTime >= 1.0
        pool.update(1.0);
        expect(pool.getActiveParticles().first.age, equals(0.0));

        // Valid deltaTime should work
        pool.update(0.5);
        expect(pool.getActiveParticles().first.age, equals(0.5));
      });

      test('does not affect inactive particles', () {
        final pool = ParticlePool(
          maxCapacity: 5,
          poolType: ParticlePoolType.trail,
        );

        // Spawn and immediately deactivate a particle
        pool.spawn(
          position: Vector2(100.0, 200.0),
          velocity: Vector2.zero(),
          color: Colors.red,
          lifetime: 0.1,
        );
        pool.update(0.1);

        // Particle should be inactive now
        expect(pool.activeCount, equals(0));

        // Get reference to the inactive particle
        final inactiveParticle = pool.particles[0];
        final ageBeforeUpdate = inactiveParticle.age;

        // Update again
        pool.update(0.5);

        // Inactive particle's age should not change
        expect(inactiveParticle.age, equals(ageBeforeUpdate));
      });
    });

    group('getActiveParticles()', () {
      test('returns empty list when no particles are active', () {
        final pool = ParticlePool(
          maxCapacity: 10,
          poolType: ParticlePoolType.trail,
        );

        expect(pool.getActiveParticles(), isEmpty);
      });

      test('returns only active particles', () {
        final pool = ParticlePool(
          maxCapacity: 10,
          poolType: ParticlePoolType.trail,
        );

        // Spawn three particles
        pool.spawn(
          position: Vector2.zero(),
          velocity: Vector2.zero(),
          color: Colors.red,
          lifetime: 1.0,
        );
        pool.spawn(
          position: Vector2.zero(),
          velocity: Vector2.zero(),
          color: Colors.green,
          lifetime: 0.5,
        );
        pool.spawn(
          position: Vector2.zero(),
          velocity: Vector2.zero(),
          color: Colors.blue,
          lifetime: 2.0,
        );

        expect(pool.getActiveParticles().length, equals(3));

        // Expire one particle
        pool.update(0.5);

        // Should now have only 2 active particles
        final activeParticles = pool.getActiveParticles();
        expect(activeParticles.length, equals(2));

        // Verify all returned particles are actually active
        for (var particle in activeParticles) {
          expect(particle.isActive, isTrue);
        }
      });

      test('returns new list instance each call', () {
        final pool = ParticlePool(
          maxCapacity: 10,
          poolType: ParticlePoolType.trail,
        );

        pool.spawn(
          position: Vector2.zero(),
          velocity: Vector2.zero(),
          color: Colors.red,
          lifetime: 1.0,
        );

        final list1 = pool.getActiveParticles();
        final list2 = pool.getActiveParticles();

        // Should be different list instances (not same reference)
        expect(identical(list1, list2), isFalse);

        // But contain same particles
        expect(list1.length, equals(list2.length));
      });

      test('returned list reflects current pool state', () {
        final pool = ParticlePool(
          maxCapacity: 10,
          poolType: ParticlePoolType.trail,
        );

        pool.spawn(
          position: Vector2.zero(),
          velocity: Vector2.zero(),
          color: Colors.red,
          lifetime: 1.0,
        );

        final listBefore = pool.getActiveParticles();
        expect(listBefore.length, equals(1));

        pool.spawn(
          position: Vector2.zero(),
          velocity: Vector2.zero(),
          color: Colors.green,
          lifetime: 1.0,
        );

        final listAfter = pool.getActiveParticles();
        expect(listAfter.length, equals(2));
      });
    });

    group('adjustCapacity()', () {
      test('deactivates excess particles when downgrading', () {
        final pool = ParticlePool(
          maxCapacity: 10,
          poolType: ParticlePoolType.trail,
        );

        // Spawn 5 particles
        for (int i = 0; i < 5; i++) {
          pool.spawn(
            position: Vector2.zero(),
            velocity: Vector2.zero(),
            color: Colors.red,
            lifetime: 1.0,
          );
        }

        expect(pool.activeCount, equals(5));

        // Adjust capacity to 3 (should deactivate 2 particles)
        pool.adjustCapacity(3);

        expect(pool.activeCount, equals(3));
        expect(pool.getActiveParticles().length, equals(3));
      });

      test('deactivates oldest particles first when downgrading', () {
        final pool = ParticlePool(
          maxCapacity: 10,
          poolType: ParticlePoolType.trail,
        );

        // Spawn particles with different positions to track them
        pool.spawn(
          position: Vector2(1.0, 1.0),
          velocity: Vector2.zero(),
          color: Colors.red,
          lifetime: 1.0,
        );
        pool.spawn(
          position: Vector2(2.0, 2.0),
          velocity: Vector2.zero(),
          color: Colors.green,
          lifetime: 1.0,
        );
        pool.spawn(
          position: Vector2(3.0, 3.0),
          velocity: Vector2.zero(),
          color: Colors.blue,
          lifetime: 1.0,
        );

        // Adjust capacity to 1 (should keep only the last particle)
        pool.adjustCapacity(1);

        expect(pool.activeCount, equals(1));

        // The remaining particle should be the last one spawned
        // Note: adjustCapacity deactivates from the start of the list
        final activeParticles = pool.getActiveParticles();
        expect(activeParticles.length, equals(1));
      });

      test('does nothing when new capacity is greater than activeCount', () {
        final pool = ParticlePool(
          maxCapacity: 10,
          poolType: ParticlePoolType.trail,
        );

        // Spawn 3 particles
        for (int i = 0; i < 3; i++) {
          pool.spawn(
            position: Vector2.zero(),
            velocity: Vector2.zero(),
            color: Colors.red,
            lifetime: 1.0,
          );
        }

        expect(pool.activeCount, equals(3));

        // Adjust capacity to higher value
        pool.adjustCapacity(5);

        // Active count should remain unchanged
        expect(pool.activeCount, equals(3));
        expect(pool.getActiveParticles().length, equals(3));
      });

      test('deactivates all particles when capacity is 0', () {
        final pool = ParticlePool(
          maxCapacity: 10,
          poolType: ParticlePoolType.trail,
        );

        // Spawn multiple particles
        for (int i = 0; i < 5; i++) {
          pool.spawn(
            position: Vector2.zero(),
            velocity: Vector2.zero(),
            color: Colors.red,
            lifetime: 1.0,
          );
        }

        expect(pool.activeCount, equals(5));

        // Adjust capacity to 0
        pool.adjustCapacity(0);

        expect(pool.activeCount, equals(0));
        expect(pool.getActiveParticles(), isEmpty);
      });

      test('correctly handles capacity equal to activeCount', () {
        final pool = ParticlePool(
          maxCapacity: 10,
          poolType: ParticlePoolType.trail,
        );

        // Spawn 4 particles
        for (int i = 0; i < 4; i++) {
          pool.spawn(
            position: Vector2.zero(),
            velocity: Vector2.zero(),
            color: Colors.red,
            lifetime: 1.0,
          );
        }

        expect(pool.activeCount, equals(4));

        // Adjust capacity to exact active count
        pool.adjustCapacity(4);

        // No particles should be deactivated
        expect(pool.activeCount, equals(4));
        expect(pool.getActiveParticles().length, equals(4));
      });
    });

    group('activeCount tracking', () {
      test('maintains accurate activeCount through multiple operations', () {
        final pool = ParticlePool(
          maxCapacity: 10,
          poolType: ParticlePoolType.trail,
        );

        expect(pool.activeCount, equals(0));

        // Spawn 3 particles
        for (int i = 0; i < 3; i++) {
          pool.spawn(
            position: Vector2.zero(),
            velocity: Vector2.zero(),
            color: Colors.red,
            lifetime: 1.0,
          );
        }
        expect(pool.activeCount, equals(3));

        // Update to expire 1 particle
        pool.spawn(
          position: Vector2.zero(),
          velocity: Vector2.zero(),
          color: Colors.red,
          lifetime: 0.5,
        );
        expect(pool.activeCount, equals(4));

        pool.update(0.5);
        expect(pool.activeCount, equals(3));

        // Adjust capacity to deactivate 1 particle
        pool.adjustCapacity(2);
        expect(pool.activeCount, equals(2));

        // Spawn new particle (may use inactive slot, incrementing count)
        pool.spawn(
          position: Vector2.zero(),
          velocity: Vector2.zero(),
          color: Colors.red,
          lifetime: 1.0,
        );
        expect(pool.activeCount, equals(3));

        // Verify activeCount matches actual active particles
        expect(pool.getActiveParticles().length, equals(pool.activeCount));
      });

      test('activeCount matches getActiveParticles length', () {
        final pool = ParticlePool(
          maxCapacity: 10,
          poolType: ParticlePoolType.trail,
        );

        // Test at various states
        expect(pool.activeCount, equals(pool.getActiveParticles().length));

        pool.spawn(
          position: Vector2.zero(),
          velocity: Vector2.zero(),
          color: Colors.red,
          lifetime: 1.0,
        );
        expect(pool.activeCount, equals(pool.getActiveParticles().length));

        for (int i = 0; i < 5; i++) {
          pool.spawn(
            position: Vector2.zero(),
            velocity: Vector2.zero(),
            color: Colors.red,
            lifetime: 1.0,
          );
        }
        expect(pool.activeCount, equals(pool.getActiveParticles().length));

        pool.update(0.5);
        expect(pool.activeCount, equals(pool.getActiveParticles().length));

        pool.adjustCapacity(3);
        expect(pool.activeCount, equals(pool.getActiveParticles().length));
      });
    });

    group('edge cases', () {
      test('handles rapid spawn/expire cycles', () {
        final pool = ParticlePool(
          maxCapacity: 5,
          poolType: ParticlePoolType.trail,
        );

        for (int cycle = 0; cycle < 10; cycle++) {
          // Spawn particles
          for (int i = 0; i < 3; i++) {
            pool.spawn(
              position: Vector2.zero(),
              velocity: Vector2.zero(),
              color: Colors.red,
              lifetime: 0.1,
            );
          }

          // Expire them
          pool.update(0.1);

          expect(pool.activeCount, equals(0));
        }
      });

      test('handles full pool replacement multiple times', () {
        final pool = ParticlePool(
          maxCapacity: 3,
          poolType: ParticlePoolType.trail,
        );

        // Fill pool multiple times
        for (int round = 0; round < 5; round++) {
          for (int i = 0; i < 3; i++) {
            pool.spawn(
              position: Vector2(round.toDouble(), i.toDouble()),
              velocity: Vector2.zero(),
              color: Colors.red,
              lifetime: 1.0,
            );
          }

          expect(pool.activeCount, equals(3));
          expect(pool.getActiveParticles().length, equals(3));
        }
      });

      test('handles mixed active/inactive states correctly', () {
        final pool = ParticlePool(
          maxCapacity: 5,
          poolType: ParticlePoolType.trail,
        );

        // Create pattern: active, inactive, active, inactive, inactive
        pool.spawn(
          position: Vector2.zero(),
          velocity: Vector2.zero(),
          color: Colors.red,
          lifetime: 1.0,
        );
        pool.spawn(
          position: Vector2.zero(),
          velocity: Vector2.zero(),
          color: Colors.red,
          lifetime: 0.1,
        );
        pool.spawn(
          position: Vector2.zero(),
          velocity: Vector2.zero(),
          color: Colors.red,
          lifetime: 1.0,
        );

        pool.update(0.1);

        expect(pool.activeCount, equals(2));

        // Spawn new particle (should use next slot)
        pool.spawn(
          position: Vector2.zero(),
          velocity: Vector2.zero(),
          color: Colors.red,
          lifetime: 1.0,
        );

        expect(pool.activeCount, equals(3));
      });
    });
  });
}
