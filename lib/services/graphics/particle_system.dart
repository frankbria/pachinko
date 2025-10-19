import 'dart:math' show cos, sin, pi;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' hide Colors;
import '../../models/particle.dart';

enum ParticlePoolType { trail, collision }

/// Manages a fixed-size pool of reusable particles to avoid GC pressure
class ParticlePool {
  final List<Particle> particles;
  final int maxCapacity;
  final ParticlePoolType poolType;
  int activeCount = 0;
  int _nextIndex = 0;

  ParticlePool({
    required this.maxCapacity,
    required this.poolType,
  }) : particles = List.generate(
          maxCapacity,
          (index) => Particle(
            position: Vector2.zero(),
            velocity: Vector2.zero(),
            color: Colors.white,
            lifetime: 1.0,
            size: 3.0,
            isActive: false,
          ),
        ) {
    if (maxCapacity <= 0 || maxCapacity > 100) {
      throw ArgumentError('maxCapacity must be > 0 and <= 100');
    }
  }

  /// Spawns a particle with the given properties
  /// If pool is full, replaces the oldest particle
  void spawn({
    required Vector2 position,
    required Vector2 velocity,
    required Color color,
    required double lifetime,
    double size = 3.0,
  }) {
    // Deactivate old particle if it was active
    if (particles[_nextIndex].isActive) {
      activeCount--;
    }

    // Create new particle instance to replace old one
    particles[_nextIndex] = Particle(
      position: position.clone(),
      velocity: velocity.clone(),
      color: color,
      lifetime: lifetime,
      age: 0.0,
      size: size,
      opacity: 1.0,
      isActive: true,
    );

    activeCount++;
    _nextIndex = (_nextIndex + 1) % maxCapacity;
  }

  /// Updates all active particles and deactivates expired ones
  void update(double deltaTime) {
    if (deltaTime <= 0 || deltaTime >= 1.0) return;

    for (var particle in particles) {
      if (particle.isActive) {
        particle.update(deltaTime);

        // Deactivate expired particles
        if (particle.age >= particle.lifetime) {
          particle.isActive = false;
          activeCount--;
        }
      }
    }
  }

  /// Returns list of currently active particles for rendering
  List<Particle> getActiveParticles() {
    return particles.where((p) => p.isActive).toList();
  }

  /// Adjusts pool capacity based on quality level
  /// Deactivates excess particles if downgrading
  void adjustCapacity(int newCapacity) {
    if (newCapacity < activeCount) {
      // Deactivate excess particles (oldest first)
      int toDeactivate = activeCount - newCapacity;
      for (var particle in particles) {
        if (toDeactivate <= 0) break;
        if (particle.isActive) {
          particle.isActive = false;
          activeCount--;
          toDeactivate--;
        }
      }
    }
  }
}

enum ParticleQualityLevel { high, medium, low }

/// Orchestrates all particle effects and manages multiple pools
class ParticleSystem {
  late ParticlePool trailPool;
  late ParticlePool collisionPool;
  bool enabled = true;
  ParticleQualityLevel qualityLevel = ParticleQualityLevel.high;

  ParticleSystem({
    int trailCapacity = 100,
    int collisionCapacity = 50,
  }) {
    trailPool = ParticlePool(
      maxCapacity: trailCapacity,
      poolType: ParticlePoolType.trail,
    );
    collisionPool = ParticlePool(
      maxCapacity: collisionCapacity,
      poolType: ParticlePoolType.collision,
    );
  }

  /// Spawns a trail particle following the ball
  void spawnTrailParticle({
    required Vector2 position,
    required Vector2 velocity,
    required Color color,
    double lifetime = 0.5,
  }) {
    if (!enabled) return;

    trailPool.spawn(
      position: position,
      velocity: velocity,
      color: color,
      lifetime: lifetime,
      size: 3.0,
    );
  }

  /// Spawns a burst effect at collision point
  void spawnCollisionBurst({
    required Vector2 position,
    required Color pegColor,
    int particleCount = 8,
  }) {
    if (!enabled) return;

    // Cap particle count at available pool capacity
    final count = particleCount.clamp(1, 20).clamp(1, collisionPool.maxCapacity);

    // Spawn particles in circular pattern
    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 2 * pi;
      final velocity = Vector2(
        100 * cos(angle),
        100 * sin(angle),
      );

      collisionPool.spawn(
        position: position,
        velocity: velocity,
        color: pegColor,
        lifetime: 0.3,
        size: 4.0,
      );
    }
  }

  /// Updates all particle pools
  void update(double deltaTime) {
    if (!enabled) return;

    trailPool.update(deltaTime);
    collisionPool.update(deltaTime);
  }

  /// Adjusts particle limits based on performance
  void adjustQuality(ParticleQualityLevel level) {
    qualityLevel = level;

    switch (level) {
      case ParticleQualityLevel.high:
        trailPool.adjustCapacity(100);
        collisionPool.adjustCapacity(50);
        break;
      case ParticleQualityLevel.medium:
        trailPool.adjustCapacity(50);
        collisionPool.adjustCapacity(25);
        break;
      case ParticleQualityLevel.low:
        trailPool.adjustCapacity(25);
        collisionPool.adjustCapacity(10);
        break;
    }
  }

  /// Gets all active particles for rendering
  List<Particle> getAllActiveParticles() {
    return [
      ...trailPool.getActiveParticles(),
      ...collisionPool.getActiveParticles(),
    ];
  }
}
