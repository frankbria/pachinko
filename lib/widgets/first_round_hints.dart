import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_manager.dart';
import '../utils/constants.dart';
import 'board_effects.dart';

/// The hints of a first round, laid over the board drawn at [scale]: a ghost
/// hand that shows the drag on the plunger, and a callout that says what the
/// prize pegs are for. Neither takes a touch, so the board under them plays
/// as usual. [GameManager] decides when each shows.
class FirstRoundHints extends StatelessWidget {
  /// Screen pixels per board pixel, as the board's painter scales.
  final double scale;

  const FirstRoundHints({super.key, required this.scale});

  @override
  Widget build(BuildContext context) {
    final (showsHand, prizePegs) = context.select<GameManager, (bool, int?)>(
        (manager) => (manager.showsLaunchHint, manager.prizePegHint));
    return IgnorePointer(
      child: Stack(
        children: [
          if (showsHand) GhostHand(scale: scale),
          if (prizePegs != null)
            PrizePegCallout(
              scale: scale,
              prizePegs: prizePegs,
              onFinished: context.read<GameManager>().dismissPrizePegHint,
            ),
        ],
      ),
    );
  }
}

/// A hand that presses the plunger, pulls it down and lets it back, over and
/// over: the gesture that launches a ball.
class GhostHand extends StatefulWidget {
  /// Screen pixels per board pixel.
  final double scale;

  /// The hand's size, in board pixels.
  static const double size = 30.0;

  /// How far down the hand pulls, in board pixels.
  static const double pull = 40.0;

  /// One press, pull and return.
  static const Duration cycle = Duration(milliseconds: 1600);

  const GhostHand({super.key, required this.scale});

  /// How far down the hand is at [progress] (0 to 1) through a [cycle]: at
  /// the plunger at the start and end, and [pull] down half way.
  static double pullAt(double progress) =>
      pull * (1 - math.cos(2 * math.pi * progress)) / 2;

  @override
  State<GhostHand> createState() => _GhostHandState();
}

class _GhostHandState extends State<GhostHand>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion =
      AnimationController(vsync: this, duration: GhostHand.cycle)..repeat();

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    // The fingertip of the touch_app glyph is a little left of its middle,
    // near its top; it rests on the plunger's cap
    return Positioned(
      left: (GameConstants.ballLaunchX - GhostHand.size * 0.42) * scale,
      top: (GameConstants.launchChannelStartY + GameConstants.ballRadius) *
          scale,
      child: AnimatedBuilder(
        animation: _motion,
        builder: (context, hand) => Transform.translate(
          offset: Offset(0, GhostHand.pullAt(_motion.value) * scale),
          child: hand,
        ),
        child: Icon(
          Icons.touch_app,
          size: GhostHand.size * scale,
          color: GameConstants.inkColor.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

/// "Hit all 3 for bonus balls" under the prize lamps, for [duration]: it
/// fades in, stays, fades out and then calls [onFinished].
class PrizePegCallout extends StatefulWidget {
  /// Screen pixels per board pixel.
  final double scale;

  /// The level's number of prize pegs.
  final int prizePegs;

  /// Called once the callout has faded out.
  final VoidCallback onFinished;

  /// How long the callout is on the board.
  static const Duration duration = Duration(seconds: 4);

  const PrizePegCallout({
    super.key,
    required this.scale,
    required this.prizePegs,
    required this.onFinished,
  });

  @override
  State<PrizePegCallout> createState() => _PrizePegCalloutState();
}

class _PrizePegCalloutState extends State<PrizePegCallout>
    with SingleTickerProviderStateMixin {
  late final AnimationController _time =
      AnimationController(vsync: this, duration: PrizePegCallout.duration)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) widget.onFinished();
        })
        ..forward();

  late final Animation<double> _opacity = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 75),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 15),
  ]).animate(_time);

  @override
  void dispose() {
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    // Under the lamps, centred on them as far as the board's width allows
    return Positioned(
      left: 0,
      width: GameConstants.boardWidth * scale,
      top: (prizeLampRowY + 14) * scale,
      child: Align(
        alignment: const Alignment(
            prizeLampCentreX / GameConstants.boardWidth * 2 - 1, 0),
        child: FadeTransition(
          opacity: _opacity,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16 * scale),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: GameConstants.cabinetColor.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: GameConstants.specialPegColor),
            ),
            child: Text(
              GameStrings.prizePegHint(widget.prizePegs),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: GameConstants.inkColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
