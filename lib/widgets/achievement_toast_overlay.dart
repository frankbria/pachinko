import 'package:flutter/material.dart';
import '../models/achievement.dart';
import 'achievement_toast.dart';

/// Manages achievement toast queue and display
///
/// Wraps the app to provide achievement toast notifications.
/// Ensures only one toast is visible at a time by queueing multiple toasts.
/// Toasts are displayed below the game screen's score header, so the score,
/// ball count and level stay readable while one is showing.
class AchievementToastOverlay extends StatefulWidget {
  final Widget child;

  const AchievementToastOverlay({
    super.key,
    required this.child,
  });

  /// Find the nearest AchievementToastOverlayState ancestor
  static AchievementToastOverlayState? of(BuildContext context) {
    return context.findAncestorStateOfType<AchievementToastOverlayState>();
  }

  @override
  State<AchievementToastOverlay> createState() =>
      AchievementToastOverlayState();
}

class AchievementToastOverlayState extends State<AchievementToastOverlay> {
  /// Distance from the top safe area to the toast: the height of the game
  /// screen's score header. The overlay sits above the Navigator, so the same
  /// offset applies on every screen.
  static const double _topOffset = 112;

  final List<Achievement> _toastQueue = [];
  Achievement? _currentToast;

  /// Show achievement toast notification
  ///
  /// If a toast is already showing, the new toast is queued.
  /// Toasts are displayed sequentially to avoid overlap.
  void showAchievementToast(Achievement achievement) {
    setState(() {
      if (_currentToast == null) {
        _currentToast = achievement;
      } else {
        // Queue toast if one is already showing
        _toastQueue.add(achievement);
      }
    });
  }

  void _onToastDismissed() {
    setState(() {
      if (_toastQueue.isNotEmpty) {
        // Show next toast from queue
        _currentToast = _toastQueue.removeAt(0);
      } else {
        _currentToast = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_currentToast != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + _topOffset,
            left: 0,
            right: 0,
            // Transparent Material: above the Navigator there is no Scaffold
            child: Material(
              type: MaterialType.transparency,
              // Keyed so each queued toast gets a fresh State (animation + timer)
              child: AchievementToast(
                key: ValueKey(_currentToast!.id),
                achievement: _currentToast!,
                onDismissed: _onToastDismissed,
              ),
            ),
          ),
      ],
    );
  }
}
