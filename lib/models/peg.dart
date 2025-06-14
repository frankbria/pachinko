import 'dart:ui';
import 'package:vector_math/vector_math_64.dart';

enum PegType {
  normal,
  special,
  bonus,
}

class Peg {
  Vector2 position;
  double radius;
  PegType type;
  Color color;
  bool isHighlighted;
  bool hasBeenHit;
  
  Peg({
    required this.position,
    this.radius = 12.0,
    this.type = PegType.normal,
    Color? color,
    this.isHighlighted = false,
    this.hasBeenHit = false,
  }) : color = color ?? _getDefaultColor(type);

  static Color _getDefaultColor(PegType type) {
    switch (type) {
      case PegType.normal:
        return const Color(0xFF4CAF50); // Green
      case PegType.special:
        return const Color(0xFFFF9800); // Orange
      case PegType.bonus:
        return const Color(0xFFE91E63); // Pink
    }
  }

  bool checkCollision(Vector2 ballPosition, double ballRadius) {
    final distance = (position - ballPosition).length;
    return distance <= (radius + ballRadius);
  }

  Vector2 getCollisionNormal(Vector2 ballPosition) {
    final direction = ballPosition - position;
    return direction.normalized();
  }

  void onHit() {
    hasBeenHit = true;
    if (type == PegType.special) {
      isHighlighted = false;
    }
  }

  void reset() {
    hasBeenHit = false;
    if (type == PegType.special) {
      isHighlighted = true;
    }
  }

  Color get renderColor {
    if (type == PegType.special && isHighlighted) {
      return Color.lerp(color, const Color(0xFFFFFF00), 0.5)!; // Add yellow glow
    }
    return hasBeenHit ? color.withOpacity(0.6) : color;
  }
}