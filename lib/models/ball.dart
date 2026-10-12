import 'dart:ui';
import 'package:vector_math/vector_math_64.dart';

class Ball {
  Vector2 position;
  Vector2 velocity;
  Vector2 acceleration;
  double radius;
  Color color;
  bool isActive;
  bool hasLanded;

  /// The prize pegs this ball was the first to hit. The physics engine
  /// counts them, since it is what knows which ball hit which peg.
  int prizePegsCollected = 0;

  /// How many past positions the trail keeps.
  static const int maxTrailLength = 8;

  final List<Vector2> _trail = [];

  /// Where the ball has just been, oldest first: at most [maxTrailLength]
  /// positions. The board draws them fading behind the ball. Empty until the
  /// ball has moved.
  List<Vector2> get trail => List.unmodifiable(_trail);

  /// Adds the ball's present position to its [trail]. The game loop calls
  /// this once per step, before the ball is moved. A ball that has landed or
  /// left play records nothing.
  void recordTrail() {
    if (!isActive || hasLanded) return;
    _trail.add(position.clone());
    if (_trail.length > maxTrailLength) _trail.removeAt(0);
  }

  Ball({
    required this.position,
    Vector2? velocity,
    Vector2? acceleration,
    this.radius = 8.0,
    this.color = const Color(0xFFFFFFFF),
    this.isActive = true,
    this.hasLanded = false,
  })  : velocity = velocity ?? Vector2.zero(),
        acceleration = acceleration ?? Vector2.zero();

  void update(double deltaTime) {
    if (!isActive || hasLanded) return;

    // Apply gravity
    acceleration.setValues(0, 980.0); // 980 pixels/second^2 downward

    // Update velocity with acceleration
    velocity.add(acceleration * deltaTime);

    // Update position with velocity
    position.add(velocity * deltaTime);

    // Apply drag/air resistance
    velocity.scale(0.999);
  }

  void applyImpulse(Vector2 impulse) {
    velocity.add(impulse);
  }

  bool get isOutOfBounds => position.y > 1000; // Adjust based on screen height

  void reset(Vector2 newPosition) {
    position = newPosition.clone();
    velocity = Vector2.zero();
    acceleration = Vector2.zero();
    isActive = true;
    hasLanded = false;
    _trail.clear();
  }
}
