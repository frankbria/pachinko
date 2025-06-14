import 'dart:ui';
import 'package:vector_math/vector_math_64.dart';

class Slot {
  Vector2 position;
  double width;
  double height;
  int pointValue;
  Color color;
  int ballCount;
  
  Slot({
    required this.position,
    required this.width,
    required this.height,
    required this.pointValue,
    Color? color,
    this.ballCount = 0,
  }) : color = color ?? _getColorForPoints(pointValue);

  static Color _getColorForPoints(int points) {
    if (points >= 1000) {
      return const Color(0xFFFF5722); // Red for high points
    } else if (points >= 500) {
      return const Color(0xFFFF9800); // Orange for medium-high points
    } else if (points >= 100) {
      return const Color(0xFFFFC107); // Amber for medium points
    } else {
      return const Color(0xFF4CAF50); // Green for low points
    }
  }

  bool containsPoint(Vector2 point) {
    return point.x >= position.x - width / 2 &&
           point.x <= position.x + width / 2 &&
           point.y >= position.y - height / 2 &&
           point.y <= position.y + height / 2;
  }

  void addBall() {
    ballCount++;
  }

  void reset() {
    ballCount = 0;
  }

  Rect get bounds => Rect.fromCenter(
    center: Offset(position.x, position.y),
    width: width,
    height: height,
  );

  double get centerX => position.x;
  double get centerY => position.y;
  double get left => position.x - width / 2;
  double get right => position.x + width / 2;
  double get top => position.y - height / 2;
  double get bottom => position.y + height / 2;
}