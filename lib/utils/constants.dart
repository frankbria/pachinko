import 'dart:ui';

class GameConstants {
  // Physics constants
  static const double gravity = 980.0; // pixels/second^2
  static const double airResistance = 0.999;
  static const double bounceDamping = 0.7;
  static const double minVelocity = 10.0;
  
  // Ball constants
  static const double ballRadius = 8.0;
  static const double ballMass = 1.0;
  static const double launchForceMin = 300.0;
  static const double launchForceMax = 800.0;
  
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
  static const double launchChannelStartX = boardWidth - launchChannelWidth - 10.0;
  static const double launchChannelStartY = boardHeight - slotAreaHeight - 50.0;
  static const double launchChannelEndY = 110.0;
  static const double ballLaunchX = launchChannelStartX + launchChannelWidth / 2;
  static const double ballLaunchY = launchChannelStartY;

  // Field boundary constants (playfield area where balls interact with pegs/slots)
  // Left boundary slightly inside the board to align near leftmost slot
  static const double fieldLeftBoundaryX = 25.0;
  // Right boundary at left edge of launch channel (blocks entry from playfield)
  static const double fieldRightBoundaryX = launchChannelStartX; // 360.0

  /// The curved top boundary of the board: a quadratic bezier from the start
  /// point through the control point to the end point. The physics bounces
  /// balls off it, the painter draws it, and the peg generators keep clear of it.
  static const double topCurveStartX = 30.0;
  static const double topCurveStartY = 110.0;
  static const double topCurveControlX = 210.0;
  static const double topCurveControlY = -100.0; // Above the board, so the curve bows upward
  static const double topCurveEndX = 390.0;
  static const double topCurveEndY = 110.0;

  // Game constants
  static const int ballsPerRound = 20;
  static const int minSpecialPegs = 2;
  static const int maxSpecialPegs = 4;
  static const int bonusBallsBase = 5;
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

  // UI Colors
  static const Color primaryColor = cyanColor;
  static const Color onPrimaryColor = Color(0xFF06262A);
  static const Color secondaryColor = goldColor;
  static const Color surfaceColor = Color(0xFF171C36);
  static const Color errorColor = Color(0xFFCF6679);
  
  // Animation durations (in milliseconds)
  static const int launchAnimationDuration = 300;
  static const int pegHitAnimationDuration = 200;
  static const int scoreAnimationDuration = 500;
  static const int ballLandAnimationDuration = 150;
  
  // Debug options
  static const bool showDebugGrid = false;
  static const bool showPegSpacing = false;
  
  // Physics time step
  static const double physicsTimeStep = 1.0 / 60.0; // 60 FPS
  static const int maxPhysicsIterations = 5;
  
  // Scoring
  static const Map<int, int> slotPointValues = {
    0: 2000, // Edge slots (hardest to reach)
    1: 200,  // Second slots
    2: 50,   // Third slots (easiest to reach)
    3: 1000, // Center slot (medium difficulty)
    4: 50,   // Third slots (easiest to reach)
    5: 200,  // Second slots
    6: 2000, // Edge slots (hardest to reach)
  };
  
  // Level progression
  static const int baseLegsPerLevel = 40;
  static const int additionalPegsPerLevel = 5;
  static const double pegDensityIncrease = 0.1;
  
  // Audio
  static const double masterVolume = 0.7;
  static const double sfxVolume = 0.8;
  static const double musicVolume = 0.5;
}

class GameStrings {
  static const String appName = 'Pachinko Game';
  static const String play = 'Play';
  static const String pause = 'Pause';
  static const String resume = 'Resume';
  static const String restart = 'Restart';
  static const String nextLevel = 'Next Level';
  static const String levelComplete = 'Level Complete!';
  static const String gameOver = 'Game Over';
  static const String score = 'Score';
  static const String level = 'Level';
  static const String ballsRemaining = 'Balls Remaining';
  static const String specialBonus = 'Special Bonus!';
  static const String ballsAdded = 'Bonus Balls Added!';
}