import 'package:flutter/material.dart';
import '../models/achievement.dart';
import 'achievement_toast.dart';

/// Manages achievement toast queue and display
///
/// Wraps the app to provide achievement toast notifications.
/// Ensures only one toast is visible at a time by queueing multiple toasts.
/// Toasts are displayed at the top center of the screen, unless a screen has
/// anchored them lower with [AchievementToastOverlayState.anchorToasts].
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
  /// Distance from the top safe area to a toast that no screen has anchored.
  static const double defaultTopOffset = 16;

  // The screen that asked for toasts to start lower, and how far down
  Object? _anchorOwner;
  double? _anchoredTopOffset;

  /// Starts toasts [topOffset] below the top safe area, on behalf of [owner].
  ///
  /// For a screen whose top edge holds something the player has to keep
  /// reading: the game screen passes the height of its score header. The
  /// position holds until the same [owner] calls [releaseToasts].
  void anchorToasts(Object owner, double topOffset) {
    if (_anchorOwner == owner && _anchoredTopOffset == topOffset) return;
    setState(() {
      _anchorOwner = owner;
      _anchoredTopOffset = topOffset;
    });
  }

  /// Returns toasts to the top of the screen, if [owner] still holds the anchor.
  ///
  /// A screen that finishes closing after another one has anchored the
  /// toasts is ignored, so it does not undo the newer screen's position.
  void releaseToasts(Object owner) {
    if (_anchorOwner != owner) return;
    setState(() {
      _anchorOwner = null;
      _anchoredTopOffset = null;
    });
  }

  final List<Achievement> _toastQueue = [];
  Achievement? _currentToast;
  int _toastsDismissed = 0; // Keys each toast, so no two share a State

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
      _toastsDismissed++;
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
            top: MediaQuery.of(context).padding.top +
                (_anchoredTopOffset ?? defaultTopOffset),
            left: 0,
            right: 0,
            // Transparent Material: above the Navigator there is no Scaffold
            child: Material(
              type: MaterialType.transparency,
              // Keyed so each queued toast gets a fresh State (animation + timer).
              // The key counts toasts and is not the achievement's id: the same
              // achievement twice in a row must still be two toasts
              child: AchievementToast(
                key: ValueKey(_toastsDismissed),
                achievement: _currentToast!,
                onDismissed: _onToastDismissed,
              ),
            ),
          ),
      ],
    );
  }
}
