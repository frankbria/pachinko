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
  
  // Board constants
  static const double boardWidth = 400.0;
  static const double boardHeight = 600.0;
  static const double launchAreaHeight = 80.0;
  static const double slotAreaHeight = 80.0;
  
  // Launch channel constants
  static const double launchChannelWidth = 30.0;
  static const double launchChannelStartX = boardWidth - launchChannelWidth - 70.0; // Moved 60px left to expose rightmost slot
  static const double launchChannelStartY = boardHeight - slotAreaHeight - 50.0;
  static const double launchChannelEndY = 60.0;
  static const double ballLaunchX = launchChannelStartX + launchChannelWidth / 2;
  static const double ballLaunchY = launchChannelStartY;
  
  // Game constants
  static const int ballsPerRound = 20;
  static const int minSpecialPegs = 2;
  static const int maxSpecialPegs = 4;
  static const int bonusBallsBase = 5;
  
  // Colors
  static const Color backgroundColor = Color(0xFF1A1A2E);
  static const Color boardColor = Color(0xFF16213E);
  static const Color ballColor = Color(0xFFFFFFFF);
  static const Color normalPegColor = Color(0xFF4CAF50);
  static const Color specialPegColor = Color(0xFFFF9800);
  static const Color bonusPegColor = Color(0xFFE91E63);
  static const Color bonusBallColor = Color(0xFFFFD700);
  
  // Slot colors based on point values
  static const Color highPointSlotColor = Color(0xFFFF5722);
  static const Color mediumHighPointSlotColor = Color(0xFFFF9800);
  static const Color mediumPointSlotColor = Color(0xFFFFC107);
  static const Color lowPointSlotColor = Color(0xFF4CAF50);
  
  // UI Colors
  static const Color primaryColor = Color(0xFF6200EE);
  static const Color primaryVariantColor = Color(0xFF3700B3);
  static const Color secondaryColor = Color(0xFF03DAC6);
  static const Color surfaceColor = Color(0xFF2D2D2D);
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

  // Graphics - Particle System
  static const int maxTrailParticles = 100;
  static const int maxCollisionParticles = 50;
  static const double particleTrailLifetime = 0.5; // seconds
  static const double particleCollisionLifetime = 0.3; // seconds
  static const double particleTrailSize = 3.0; // pixels
  static const double particleCollisionSize = 4.0; // pixels

  // Graphics - Performance
  static const double targetFPS = 60.0;
  static const double targetFrameTime = 16.67; // milliseconds (1000/60)
  static const double fpsThresholdHigh = 60.0;
  static const double fpsThresholdMedium = 55.0;
  static const double fpsThresholdLow = 50.0;
  static const int performanceBufferSize = 60; // 1 second window at 60 FPS

  // Graphics - Animation
  static const double glowAnimationDuration = 2.0; // seconds
  static const double fadeAnimationDuration = 0.3; // seconds
  static const double glowBlurRadius = 10.0; // pixels
  static const double glowIntensityMin = 0.3;
  static const double glowIntensityMax = 1.0;

  // Graphics - Rendering
  static const bool antiAliasingEnabled = true;
  static const double defaultStrokeWidth = 2.0;
  static const int collisionBurstParticleCount = 8;
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