import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:pachinko_game/services/graphics/particle_system.dart';

void main() {
  group('ParticleSystem', () {
    late ParticleSystem system;

    setUp(() {
      system = ParticleSystem(
        trailCapacity: 100,
        collisionCapacity: 50,
      );
    });

    group('spawnTrailParticle()', () {
      test('creates trail particle with correct properties', () {
        final position = Vector2(100, 200);
        final velocity = Vector2(10, 20);
        const color = Colors.blue;
        const lifetime = 0.5;

        system.spawnTrailParticle(
          position: position,
          velocity: velocity,
          color: color,
          lifetime: lifetime,
        );

        final activeParticles = system.trailPool.getActiveParticles();
        expect(activeParticles.length, 1);

        final particle = activeParticles.first;
        expect(particle.position, equals(position));
        expect(particle.velocity, equals(velocity));
        expect(particle.color, equals(color));
        expect(particle.lifetime, equals(lifetime));
        expect(particle.size, equals(3.0)); // Default size for trail
        expect(particle.isActive, isTrue);
      });

      test('does not spawn when system is disabled', () {
        system.enabled = false;

        system.spawnTrailParticle(
          position: Vector2(100, 200),
          velocity: Vector2(10, 20),
          color: Colors.blue,
        );

        final activeParticles = system.trailPool.getActiveParticles();
        expect(activeParticles.length, 0);
      });

      test('respects pool capacity by recycling oldest particles', () {
        // Create system with small capacity
        final smallSystem = ParticleSystem(
          trailCapacity: 3,
          collisionCapacity: 10,
        );

        // Spawn 5 particles (exceeds capacity of 3)
        for (int i = 0; i < 5; i++) {
          smallSystem.spawnTrailParticle(
            position: Vector2(i.toDouble(), 0),
            velocity: Vector2.zero(),
            color: Colors.blue,
          );
        }

        final activeParticles = smallSystem.trailPool.getActiveParticles();
        expect(activeParticles.length, 3); // Capped at capacity
      });
    });

    group('spawnCollisionBurst()', () {
      test('creates circular burst pattern with 8 particles', () {
        final position = Vector2(150, 250);
        const color = Colors.red;

        system.spawnCollisionBurst(
          position: position,
          pegColor: color,
          particleCount: 8,
        );

        final activeParticles = system.collisionPool.getActiveParticles();
        expect(activeParticles.length, 8);

        // Verify all particles have correct basic properties
        for (final particle in activeParticles) {
          expect(particle.position, equals(position));
          expect(particle.color, equals(color));
          expect(particle.lifetime, equals(0.3));
          expect(particle.size, equals(4.0)); // Collision particles are larger
          expect(particle.isActive, isTrue);
        }
      });

      test('creates circular velocity pattern', () {
        final position = Vector2(150, 250);

        system.spawnCollisionBurst(
          position: position,
          pegColor: Colors.red,
          particleCount: 8,
        );

        final activeParticles = system.collisionPool.getActiveParticles();
        expect(activeParticles.length, 8);

        // Verify velocities form a circular pattern
        // Check that velocities point in different directions
        final velocities = activeParticles.map((p) => p.velocity).toList();

        // All velocities should have magnitude ~100
        for (final velocity in velocities) {
          final magnitude = velocity.length;
          expect(magnitude, closeTo(100, 0.1));
        }

        // Velocities should be evenly distributed (45 degrees apart for 8 particles)
        // Check first two particles are ~45 degrees apart
        final angle1 = velocities[0].angleToSigned(velocities[1]).abs();
        expect(angle1, closeTo(0.785398, 0.01)); // ~45 degrees in radians
      });

      test('does not spawn when system is disabled', () {
        system.enabled = false;

        system.spawnCollisionBurst(
          position: Vector2(100, 200),
          pegColor: Colors.red,
          particleCount: 8,
        );

        final activeParticles = system.collisionPool.getActiveParticles();
        expect(activeParticles.length, 0);
      });

      test('caps particle count at pool capacity', () {
        // Create system with small capacity
        final smallSystem = ParticleSystem(
          trailCapacity: 10,
          collisionCapacity: 5,
        );

        // Request 8 particles but pool only has capacity for 5
        smallSystem.spawnCollisionBurst(
          position: Vector2(100, 200),
          pegColor: Colors.red,
          particleCount: 8,
        );

        final activeParticles = smallSystem.collisionPool.getActiveParticles();
        expect(activeParticles.length, 5); // Capped at pool capacity
      });

      test('clamps particle count to valid range (1-20)', () {
        // Test minimum clamping
        system.spawnCollisionBurst(
          position: Vector2(100, 200),
          pegColor: Colors.red,
          particleCount: 0, // Invalid, should clamp to 1
        );
        expect(system.collisionPool.getActiveParticles().length, 1);

        // Reset
        system = ParticleSystem(
          trailCapacity: 100,
          collisionCapacity: 50,
        );

        // Test maximum clamping
        system.spawnCollisionBurst(
          position: Vector2(100, 200),
          pegColor: Colors.red,
          particleCount: 25, // Invalid, should clamp to 20
        );
        expect(system.collisionPool.getActiveParticles().length, 20);
      });
    });

    group('update()', () {
      test('updates trail pool particles', () {
        system.spawnTrailParticle(
          position: Vector2(100, 200),
          velocity: Vector2(50, 100),
          color: Colors.blue,
          lifetime: 1.0,
        );

        final particleBefore = system.trailPool.getActiveParticles().first;
        final positionBefore = particleBefore.position.clone();
        final ageBefore = particleBefore.age;

        system.update(0.1); // Update by 0.1 seconds

        final particleAfter = system.trailPool.getActiveParticles().first;
        expect(particleAfter.age, greaterThan(ageBefore));
        expect(particleAfter.position.x, greaterThan(positionBefore.x));
        expect(particleAfter.position.y, greaterThan(positionBefore.y));
      });

      test('updates collision pool particles', () {
        system.spawnCollisionBurst(
          position: Vector2(150, 250),
          pegColor: Colors.red,
          particleCount: 8,
        );

        final particlesBefore = system.collisionPool.getActiveParticles();
        expect(particlesBefore.length, 8);
        final ageBefore = particlesBefore.first.age;

        system.update(0.1); // Update by 0.1 seconds

        final particlesAfter = system.collisionPool.getActiveParticles();
        expect(particlesAfter.length, 8);
        expect(particlesAfter.first.age, greaterThan(ageBefore));
      });

      test('updates both pools simultaneously', () {
        // Spawn trail particle
        system.spawnTrailParticle(
          position: Vector2(100, 200),
          velocity: Vector2(50, 100),
          color: Colors.blue,
          lifetime: 1.0,
        );

        // Spawn collision burst
        system.spawnCollisionBurst(
          position: Vector2(150, 250),
          pegColor: Colors.red,
          particleCount: 4,
        );

        expect(system.trailPool.getActiveParticles().length, 1);
        expect(system.collisionPool.getActiveParticles().length, 4);

        system.update(0.1);

        // Both pools should still have active particles
        expect(system.trailPool.getActiveParticles().length, 1);
        expect(system.collisionPool.getActiveParticles().length, 4);

        // All particles should have aged
        for (final particle in system.getAllActiveParticles()) {
          expect(particle.age, greaterThan(0));
        }
      });

      test('does not update when system is disabled', () {
        system.spawnTrailParticle(
          position: Vector2(100, 200),
          velocity: Vector2(50, 100),
          color: Colors.blue,
          lifetime: 1.0,
        );

        final ageBefore = system.trailPool.getActiveParticles().first.age;

        system.enabled = false;
        system.update(0.1);

        final ageAfter = system.trailPool.getActiveParticles().first.age;
        expect(ageAfter, equals(ageBefore)); // No change
      });

      test('removes expired particles', () {
        system.spawnTrailParticle(
          position: Vector2(100, 200),
          velocity: Vector2.zero(),
          color: Colors.blue,
          lifetime: 0.2, // Short lifetime
        );

        expect(system.trailPool.getActiveParticles().length, 1);

        // Update past lifetime
        system.update(0.3);

        expect(system.trailPool.getActiveParticles().length, 0);
      });
    });

    group('adjustQuality()', () {
      test('sets high quality capacities (100/50)', () {
        system.adjustQuality(ParticleQualityLevel.high);

        // Fill pools to verify capacity
        for (int i = 0; i < 110; i++) {
          system.spawnTrailParticle(
            position: Vector2.zero(),
            velocity: Vector2.zero(),
            color: Colors.blue,
          );
        }

        for (int i = 0; i < 60; i++) {
          system.spawnCollisionBurst(
            position: Vector2.zero(),
            pegColor: Colors.red,
            particleCount: 1,
          );
        }

        // Should be capped at high quality limits
        expect(system.trailPool.activeCount, lessThanOrEqualTo(100));
        expect(system.collisionPool.activeCount, lessThanOrEqualTo(50));
        expect(system.qualityLevel, equals(ParticleQualityLevel.high));
      });

      test('sets medium quality capacities (50/25)', () {
        // First fill pools beyond medium quality limits
        for (int i = 0; i < 100; i++) {
          system.spawnTrailParticle(
            position: Vector2.zero(),
            velocity: Vector2.zero(),
            color: Colors.blue,
          );
        }

        for (int i = 0; i < 50; i++) {
          system.spawnCollisionBurst(
            position: Vector2.zero(),
            pegColor: Colors.red,
            particleCount: 1,
          );
        }

        // Now adjust to medium quality - should deactivate excess particles
        system.adjustQuality(ParticleQualityLevel.medium);

        // Active count should be capped at medium quality limits
        expect(system.trailPool.activeCount, lessThanOrEqualTo(50));
        expect(system.collisionPool.activeCount, lessThanOrEqualTo(25));
        expect(system.qualityLevel, equals(ParticleQualityLevel.medium));
      });

      test('sets low quality capacities (25/10)', () {
        // First fill pools beyond low quality limits
        for (int i = 0; i < 100; i++) {
          system.spawnTrailParticle(
            position: Vector2.zero(),
            velocity: Vector2.zero(),
            color: Colors.blue,
          );
        }

        for (int i = 0; i < 50; i++) {
          system.spawnCollisionBurst(
            position: Vector2.zero(),
            pegColor: Colors.red,
            particleCount: 1,
          );
        }

        // Now adjust to low quality - should deactivate excess particles
        system.adjustQuality(ParticleQualityLevel.low);

        // Active count should be capped at low quality limits
        expect(system.trailPool.activeCount, lessThanOrEqualTo(25));
        expect(system.collisionPool.activeCount, lessThanOrEqualTo(10));
        expect(system.qualityLevel, equals(ParticleQualityLevel.low));
      });

      test('deactivates excess particles when downgrading quality', () {
        // Start with high quality and fill pools
        system.adjustQuality(ParticleQualityLevel.high);

        for (int i = 0; i < 100; i++) {
          system.spawnTrailParticle(
            position: Vector2.zero(),
            velocity: Vector2.zero(),
            color: Colors.blue,
          );
        }

        expect(system.trailPool.activeCount, 100);

        // Downgrade to low quality
        system.adjustQuality(ParticleQualityLevel.low);

        // Should have deactivated excess particles
        expect(system.trailPool.activeCount, lessThanOrEqualTo(25));
      });
    });

    group('getAllActiveParticles()', () {
      test('returns empty list when no particles active', () {
        final allParticles = system.getAllActiveParticles();
        expect(allParticles, isEmpty);
      });

      test('combines particles from trail pool only', () {
        system.spawnTrailParticle(
          position: Vector2(100, 200),
          velocity: Vector2(10, 20),
          color: Colors.blue,
        );

        final allParticles = system.getAllActiveParticles();
        expect(allParticles.length, 1);
      });

      test('combines particles from collision pool only', () {
        system.spawnCollisionBurst(
          position: Vector2(150, 250),
          pegColor: Colors.red,
          particleCount: 4,
        );

        final allParticles = system.getAllActiveParticles();
        expect(allParticles.length, 4);
      });

      test('combines particles from both pools', () {
        // Spawn trail particles
        for (int i = 0; i < 3; i++) {
          system.spawnTrailParticle(
            position: Vector2(i.toDouble(), 0),
            velocity: Vector2.zero(),
            color: Colors.blue,
          );
        }

        // Spawn collision burst
        system.spawnCollisionBurst(
          position: Vector2(150, 250),
          pegColor: Colors.red,
          particleCount: 5,
        );

        final allParticles = system.getAllActiveParticles();
        expect(allParticles.length, 8); // 3 trail + 5 collision
      });

      test('only includes active particles', () {
        // Spawn particle with very short lifetime
        system.spawnTrailParticle(
          position: Vector2(100, 200),
          velocity: Vector2.zero(),
          color: Colors.blue,
          lifetime: 0.1,
        );

        expect(system.getAllActiveParticles().length, 1);

        // Update past lifetime
        system.update(0.2);

        expect(system.getAllActiveParticles().length, 0);
      });
    });

    group('enabled flag', () {
      test('prevents trail particle spawning when false', () {
        system.enabled = false;

        system.spawnTrailParticle(
          position: Vector2(100, 200),
          velocity: Vector2(10, 20),
          color: Colors.blue,
        );

        expect(system.getAllActiveParticles().length, 0);
      });

      test('prevents collision burst spawning when false', () {
        system.enabled = false;

        system.spawnCollisionBurst(
          position: Vector2(150, 250),
          pegColor: Colors.red,
          particleCount: 8,
        );

        expect(system.getAllActiveParticles().length, 0);
      });

      test('prevents updates when false', () {
        // Spawn particles while enabled
        system.spawnTrailParticle(
          position: Vector2(100, 200),
          velocity: Vector2(50, 100),
          color: Colors.blue,
          lifetime: 1.0,
        );

        final ageBefore = system.getAllActiveParticles().first.age;

        // Disable and update
        system.enabled = false;
        system.update(0.1);

        final ageAfter = system.getAllActiveParticles().first.age;
        expect(ageAfter, equals(ageBefore));
      });

      test('allows operations to resume when re-enabled', () {
        system.enabled = false;

        system.spawnTrailParticle(
          position: Vector2(100, 200),
          velocity: Vector2(10, 20),
          color: Colors.blue,
        );

        expect(system.getAllActiveParticles().length, 0);

        // Re-enable
        system.enabled = true;

        system.spawnTrailParticle(
          position: Vector2(100, 200),
          velocity: Vector2(10, 20),
          color: Colors.blue,
        );

        expect(system.getAllActiveParticles().length, 1);
      });
    });

    group('initialization', () {
      test('initializes with custom capacities', () {
        final customSystem = ParticleSystem(
          trailCapacity: 75,
          collisionCapacity: 30,
        );

        expect(customSystem.trailPool.maxCapacity, 75);
        expect(customSystem.collisionPool.maxCapacity, 30);
      });

      test('initializes with default values', () {
        final defaultSystem = ParticleSystem();

        expect(defaultSystem.trailPool.maxCapacity, 100);
        expect(defaultSystem.collisionPool.maxCapacity, 50);
        expect(defaultSystem.enabled, isTrue);
        expect(defaultSystem.qualityLevel, ParticleQualityLevel.high);
      });
    });
  });
}
