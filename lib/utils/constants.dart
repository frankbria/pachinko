import 'dart:ui';

/// The look of a band of levels: its felt, lit and in shade, and the colour
/// its rail glows in and its level sign is written in.
class LevelBand {
  final String name;
  final Color felt;
  final Color feltShade;
  final Color rim;

  const LevelBand({
    required this.name,
    required this.felt,
    required this.feltShade,
    required this.rim,
  });
}

class GameConstants {
  // Physics constants
  static const double gravity = 980.0; // pixels/second^2
  /// The share of a ball's speed kept over each 1/60 s: the physics applies
  /// it per second of play, so it does not change with the step.
  static const double airResistance = 0.999;
  static const double bounceDamping = 0.7;
  static const double minVelocity = 10.0;

  // Ball constants
  static const double ballRadius = 8.0;
  static const double ballMass = 1.0;

  // Peg constants
  static const double pegRadiusMin = 8.0;
  static const double pegRadiusMax = 15.0;
  static const double specialPegRadius = 15.0;

  /// Smallest gap, edge to edge, between two pegs or between a peg and a
  /// field wall. A gap narrower than a ball is a pocket the ball rests in.
  static const double minPegGap = ballRadius * 2 + 2.0;

  // Board constants
  static const double boardWidth = 400.0;
  static const double boardHeight = 600.0;
  static const double launchAreaHeight = 80.0;
  static const double slotAreaHeight = 80.0;

  // Launch channel constants
  static const double launchChannelWidth = 30.0;
  static const double launchChannelStartX =
      boardWidth - launchChannelWidth - 10.0;
  static const double launchChannelStartY = boardHeight - slotAreaHeight - 50.0;
  static const double launchChannelEndY = 110.0;

  /// Where the channel's inner wall stops. It must not rise to
  /// [launchChannelEndY]: the mouth under the dome then looks too narrow for
  /// a ball (the owner's decision on the visual overhaul, #22).
  static const double launchChannelInnerWallTopY = 135.0;
  static const double ballLaunchX =
      launchChannelStartX + launchChannelWidth / 2;
  static const double ballLaunchY = launchChannelStartY;

  /// How fast a ball leaves the top of the launch channel, moving straight
  /// up, at no power and at full power. From there the physics has it: it
  /// meets the dome and rides it for as long as its speed presses it there.
  /// The least must carry a ball out of the channel's mouth into the field;
  /// the most must carry it over the top of the dome to the far side (#96)
  static const double launchSpeedMin = 350.0;
  static const double launchSpeedMax = 850.0;

  // Field boundary constants (playfield area where balls interact with pegs/slots)
  // Left boundary slightly inside the board to align near leftmost slot
  static const double fieldLeftBoundaryX = 25.0;

  /// How wide each of the two edge (2,000) slots is. The row of slots lies
  /// between the field walls; the edge slots are just wider than the ball,
  /// so that they stay the hardest to hit and are drawn exactly as they can
  /// be reached. Set from the scoring simulation by the owner (#92): at 22
  /// about one ball in nine lands in a 2,000 slot
  static const double edgeSlotWidth = 22.0;
  // Right boundary at left edge of launch channel (blocks entry from playfield)
  static const double fieldRightBoundaryX = launchChannelStartX; // 360.0

  /// The curved top boundary of the board: a quadratic bezier from the start
  /// point through the control point to the end point. The physics bounces
  /// balls off it, the painter draws it, and the peg generators keep clear of it.
  static const double topCurveStartX = 30.0;
  static const double topCurveStartY = 110.0;
  static const double topCurveControlX = 210.0;
  static const double topCurveControlY =
      -100.0; // Above the board, so the curve bows upward
  static const double topCurveEndX = 390.0;
  static const double topCurveEndY = 110.0;

  // Game constants
  static const int ballsPerRound = 20;

  /// The prize pegs on every level. With all of them to collect, the bonus
  /// comes in 35 to 50% of rounds on every band of levels, measured with
  /// `tool/scoring_simulation_test.dart` (#113).
  static const int prizePegsPerLevel = 5;

  /// Where prize pegs are placed: a zigzag column down the middle of the
  /// field, low down, the first at [prizeColumnTopY] and each next one
  /// [prizeColumnStep] lower and on the other side of [prizeColumnX] by
  /// [prizeColumnSway], moved by up to [prizeColumnJitter] either way. A ball
  /// that reaches one has usually been turned aside by the one above it,
  /// which is what makes collecting them all rare; set with
  /// `tool/scoring_simulation_test.dart` (#113).
  static const double prizeColumnX = boardWidth / 2;
  static const double prizeColumnTopY = 340.0;
  static const double prizeColumnStep = 41.0;
  static const double prizeColumnSway = 25.0;
  static const double prizeColumnJitter = 8.0;

  /// How much a slot pays during the fever that follows the bonus.
  static const int feverMultiplier = 2;

  /// How long the fever lasts, in seconds of play: it runs down only while a
  /// ball is in play, so neither pausing nor waiting to launch uses it up.
  static const double feverSeconds = 8.0;
  static const int bonusBallsBase = 5;

  /// The most balls a bonus drops. The bonus grows with the level and
  /// reaches this at level 20; without it a high level dropped more balls
  /// than the player launches (owner's decision, #72)
  static const int bonusBallsMax = 15;

  /// The balls dropped when every prize peg on [levelNumber] is collected.
  static int bonusBallsFor(int levelNumber) {
    final grown = bonusBallsBase + levelNumber ~/ 2;
    return grown < bonusBallsMax ? grown : bonusBallsMax;
  }

  // Board features (#114): which levels have which is Level.featureKindsFor.
  // Where they stand and how they behave were set with
  // `tool/scoring_simulation_test.dart`, so that the bonus still comes in 35
  // to 50% of rounds on every band of levels.

  /// A tulip's body, and where the two stand: in the pins, one each side of
  /// the prize column. Lower down they stood in the two streams of balls
  /// down the sides and knocked them inwards onto the prize pegs, and the
  /// bonus came in four rounds out of five. Each tulip's trigger pin is
  /// [tulipTriggerOffsetX] outwards and [tulipTriggerRise] up from it, so a
  /// ball can still fall into its mouth from straight above.
  static const double tulipRadius = 12.0;
  static const double tulipLeftX = 110.0;
  static const double tulipRightX = 290.0;
  static const double tulipY = 250.0;
  static const double tulipTriggerOffsetX = 22.0;
  static const double tulipTriggerRise = 42.0;
  static const double tulipTriggerRadius = 9.5;

  /// How long a tulip stays open after its trigger pin is hit, in seconds of
  /// play, unless it catches a ball first.
  static const double tulipOpenSeconds = 0.6;

  /// How far from straight up, in radians, a ball can meet an open tulip and
  /// still fall into its mouth.
  static const double tulipMouthHalfAngle = 0.4;

  /// The balls a tulip pays for each ball it catches: about four a round on
  /// a level with tulips. Paid balls are more chances at the prize pegs, so
  /// this moves the bonus rate.
  static const int tulipPayoutBalls = 2;

  /// A windmill: four blades of [windmillBladeLength] from a hub at
  /// ([windmillX], [windmillY]), turning at [windmillSpin] radians a second
  /// of play. It turns anticlockwise, so its top throws balls out towards
  /// the wall and not in towards the prize pegs.
  static const double windmillX = 100.0;
  static const double windmillY = 320.0;
  static const double windmillBladeLength = 24.0;
  static const int windmillBlades = 4;
  static const double windmillSpin = -3.0;

  /// Half the thickness of a windmill blade and of the centre gate's bar.
  static const double featureBarHalfThickness = 2.5;

  /// The centre gate: a bar of half length [centreGateHalfLength] that
  /// rocks about a pivot at the mouth of the centre slot, [centreGateY]
  /// down, up to [centreGateSwing] radians either way of level and back
  /// every [centreGatePeriod] seconds of play. Level, it turns balls away
  /// from the slot; steep, it guides them down its length into it.
  static const double centreGateY = 530.0;
  static const double centreGateHalfLength = 18.0;
  static const double centreGateSwing = 1.05;
  static const double centreGatePeriod = 3.2;

  /// The step down the prize column on a level with the centre gate, in
  /// place of [prizeColumnStep]: shorter, so that the lowest prize peg leaves
  /// a ball room past the gate. Lifting the whole column instead made the
  /// bonus come in seven rounds out of ten on those levels.
  static const double centreGateColumnStep = 32.0;

  // Bonus balls drop from the top of the playfield, above the first peg row
  static const double bonusBallSpawnY = 70.0;
  static const double bonusBallSpawnMinX = 120.0;
  static const double bonusBallSpawnMaxX = 300.0;

  // Palette: every colour in the game comes from this set
  static const Color goldColor = Color(0xFFFFD34D);
  static const Color magentaColor = Color(0xFFFF3D9A);
  static const Color violetColor = Color(0xFFA77BFF);
  static const Color blueColor = Color(0xFF3FA9FF);
  static const Color slateColor = Color(0xFF7C89B8);
  static const Color cyanColor = Color(0xFF2DE2E6);
  static const Color brassColor = Color(0xFFD9A441);
  static const Color chromeColor = Color(0xFFE9EEF8);
  static const Color cabinetColor = Color(0xFF0A0C16);
  static const Color feltColor = Color(0xFF1D2760);
  static const Color feltShadeColor = Color(0xFF0B0F24);
  static const Color inkColor = Color(0xFFF2F5FB);
  static const Color mutedColor = Color(0xFF8E98B3);

  // Roles: what each colour means on screen. Gold is score and bonus only,
  // brass never glows (a glowing peg is always a prize), and slot tiers run
  // cool to hot.
  static const Color backgroundColor = cabinetColor;
  static const Color boardColor = feltColor;
  static const Color ballColor = chromeColor;
  static const Color normalPegColor = brassColor;
  static const Color specialPegColor = goldColor;
  static const Color bonusBallColor = goldColor;
  static const Color slot2000Color = magentaColor;
  static const Color slot1000Color = violetColor;
  static const Color slot200Color = blueColor;
  static const Color slot50Color = slateColor;

  /// How many levels share a look before it changes.
  static const int levelsPerBand = 5;

  /// The bands of levels, in order. Each felt is dark enough for every role
  /// colour to stand out on it, and no rim is gold or brass: gold is score
  /// and prizes, brass is pins. A test checks both.
  static const List<LevelBand> levelBands = [
    LevelBand(
        name: 'Midnight',
        felt: feltColor,
        feltShade: feltShadeColor,
        rim: primaryColor),
    LevelBand(
      name: 'Lagoon',
      felt: Color(0xFF0E3B3F),
      feltShade: Color(0xFF061A1D),
      rim: Color(0xFF6BF2B5),
    ),
    LevelBand(
      name: 'Plum',
      felt: Color(0xFF36194F),
      feltShade: Color(0xFF160A22),
      rim: Color(0xFFD7DCFF),
    ),
    LevelBand(
      name: 'Ember',
      felt: Color(0xFF4A1626),
      feltShade: Color(0xFF1F090F),
      rim: Color(0xFFFF7A66),
    ),
  ];

  /// The band [levelNumber] belongs to. Beyond the last band they come round
  /// again, so the look keeps changing however far the player goes.
  static LevelBand bandForLevel(int levelNumber) {
    final index = levelNumber < 1 ? 0 : (levelNumber - 1) ~/ levelsPerBand;
    return levelBands[index % levelBands.length];
  }

  // UI Colors
  static const Color primaryColor = cyanColor;
  static const Color onPrimaryColor = Color(0xFF06262A);
  static const Color secondaryColor = goldColor;
  static const Color surfaceColor = Color(0xFF171C36);
  static const Color errorColor = Color(0xFFCF6679);

  // Debug options
  static const bool showPegSpacing = false;

  /// How many fixed physics steps make a second of play, whatever the
  /// display's frame rate. Small enough steps that the fastest ball moves
  /// less than a pin and a ball across in one.
  static const int physicsStepsPerSecond = 120;

  /// The length of one physics step, in seconds.
  static const double physicsTimeStep = 1.0 / physicsStepsPerSecond;

  /// The most physics steps one frame runs. A frame later than this (the app
  /// was hidden, or the device stalled) loses the rest of its time instead of
  /// catching up on it.
  static const int maxPhysicsIterations = 5;

  // Scoring
  static const Map<int, int> slotPointValues = {
    0: 2000, // Edge slots (hardest to reach)
    1: 200, // Second slots
    2: 50, // Third slots (easiest to reach)
    3: 1000, // Center slot (medium difficulty)
    4: 50, // Third slots (easiest to reach)
    5: 200, // Second slots
    6: 2000, // Edge slots (hardest to reach)
  };

  // Level progression
  static const int additionalPegsPerLevel = 5;

  // Audio
  static const double sfxVolume = 0.8;
}

class GameStrings {
  static const String appName = 'Pachinko Game';
  static const String launchHintReady = 'Drag the plunger to launch';
  static const String launchHintCharging = 'Release to launch';
  static const String howToPlay = 'How to Play';

  /// The callout shown at the first prize peg hit, for a level with
  /// [prizePegs] of them.
  static String prizePegHint(int prizePegs) =>
      'Hit all $prizePegs for bonus balls';

  static const String settings = 'Settings';
  static const String singleBallLaunch = 'One ball at a time';
  static const String singleBallLaunchHint =
      'Wait for the ball in play to land before launching the next. Turn off to launch as many as you like.';
  static const String soundEffects = 'Sound effects';
  static const String volume = 'Volume';
  static const String vibration = 'Vibration';
  static const String vibrationHint =
      'A tick for a pin, stronger for a prize peg, a high slot and the bonus';
  static const String reducedMotion = 'Reduced motion';
  static const String reducedMotionHint =
      'No confetti or shimmer, and a short trail behind the ball. Follows the system until changed.';

  static const String leftHanded = 'Left-handed launcher';
  static const String leftHandedHint =
      'The launcher on the left, so your hand does not cover the board';

  /// What a screen reader hears when a ball lands: "1,000 points, centre
  /// slot". [points] is already written with its thousands grouped.
  static String ballLanded(String points, String slotName) =>
      '$points points, $slotName slot';
  static const String back = 'Back';
  static const String play = 'Play';
  static const String pause = 'Pause';
  static const String resume = 'Resume';
  static const String restart = 'Restart';
  static const String nextLevel = 'Next Level';
  static const String replay = 'Replay';
  static const String menu = 'Menu';
  static const String newBest = 'New best for this level';
  static const String prizePegs = 'Prize pegs';
  static const String bonusBalls = 'Bonus balls';
  static const String feverPoints = 'Fever ×${GameConstants.feverMultiplier}';
  static const String levelComplete = 'Level Complete!';
  static const String gameOver = 'Game Over';
  static const String score = 'Score';
  static const String level = 'Level';
  static const String ballsRemaining = 'Balls';
  static const String ballsLeft = 'Balls left';
  static const String specialBonus = 'Special Bonus!';
  static const String ballsAdded = 'Bonus Balls Added!';
}
