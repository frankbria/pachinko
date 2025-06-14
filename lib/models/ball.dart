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
  
  Ball({
    required this.position,
    Vector2? velocity,
    Vector2? acceleration,
    this.radius = 8.0,
    this.color = const Color(0xFFFFFFFF),
    this.isActive = true,
    this.hasLanded = false,
  }) : velocity = velocity ?? Vector2.zero(),
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
  }
}