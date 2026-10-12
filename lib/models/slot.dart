import 'dart:ui';
import 'package:vector_math/vector_math_64.dart';
import '../utils/constants.dart';

class Slot {
  Vector2 position;
  double width;
  double height;
  int pointValue;
  Color color;
  int ballCount;

  /// How brightly the slot is lit: 1.0 when a ball has just landed, fading to
  /// 0.0 at rest. `GameState` sets and fades it.
  double glow = 0.0;

  /// How long the slot stays lit after a ball lands. A higher value earns a
  /// longer light.
  double get lightSeconds {
    if (pointValue >= 2000) return 1.1;
    if (pointValue >= 1000) return 0.8;
    if (pointValue >= 100) return 0.5;
    return 0.35;
  }
  
  Slot({
    required this.position,
    required this.width,
    required this.height,
    required this.pointValue,
    Color? color,
    this.ballCount = 0,
  }) : color = color ?? colorFor(pointValue);

  /// The tier colour of a slot worth [points].
  static Color colorFor(int points) {
    if (points >= 2000) {
      return GameConstants.slot2000Color;
    } else if (points >= 1000) {
      return GameConstants.slot1000Color;
    } else if (points >= 100) {
      return GameConstants.slot200Color;
    } else {
      return GameConstants.slot50Color;
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
    glow = 0.0;
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