# Pachinko Game - Development Reference

## Project Overview
A modern graphical Pachinko idle game for Android. Features authentic pachinko machine mechanics with realistic ball launching, physics simulation, and strategic scoring.

## Current Status: ✅ PLAYABLE PROTOTYPE
- ✅ Authentic ball launching system (bottom-right launch channel)
- ✅ Advanced physics engine with collision detection
- ✅ Organized peg patterns with proper spacing
- ✅ Complete UI with power meter and visual feedback
- ✅ Level progression system with varying patterns
- ✅ Special peg bonus mechanics
- ✅ Cross-platform (Linux desktop, Android-ready)

## Technology Stack
- **Framework:** Flutter 3.24.5
- **Language:** Dart 3.5.4
- **Physics:** Custom physics engine (60 FPS)
- **State Management:** Provider pattern
- **Storage:** Shared Preferences (ready)
- **Graphics:** Custom Canvas painting
- **Platform:** Linux (current), Android (configured)

## Project Structure
```
lib/
├── main.dart                    # App entry point with Provider setup
├── models/
│   ├── ball.dart               # Ball physics and properties
│   ├── ball_launcher.dart      # ✨ NEW: Authentic launch system
│   ├── peg.dart                # Peg collision and types
│   ├── slot.dart               # Scoring slots at bottom
│   ├── level.dart              # Level generation and management
│   └── game_state.dart         # Global game state management
├── services/
│   ├── physics_engine.dart     # Ball physics and collision detection
│   └── game_manager.dart       # Main game loop and coordination
├── screens/
│   ├── game_screen.dart        # Main gameplay screen
│   └── menu_screen.dart        # Main menu with level selection
├── widgets/
│   └── pachinko_board.dart     # Custom Canvas game board renderer
└── utils/
    ├── constants.dart          # Game configuration and styling
    └── peg_patterns.dart       # ✨ NEW: Organized peg layouts
```

## Key Commands
- `export PATH="/home/frankbria/projects/pachinko/tools/flutter/bin:$PATH"` - Set Flutter path
- `flutter run` - Run the game
- `flutter build apk` - Build Android APK
- `flutter test` - Run tests
- `flutter analyze` - Check code quality
- `flutter doctor` - Check Flutter installation

## Current Implementation Status

### ✅ COMPLETED (Phases 1-3)
1. **✅ Setup & Core Structure** - Complete Flutter project with clean architecture
2. **✅ Physics Engine** - Advanced ball physics with realistic collision detection
3. **✅ Authentic Launch System** - Real pachinko-style launch channel with power meter
4. **✅ Game Board Rendering** - Custom Canvas painting with organized peg patterns
5. **✅ Basic Game Logic** - Level system, scoring, special peg mechanics implemented

### 🚧 READY FOR DEVELOPMENT (Phases 4-6)
6. **UI/UX Enhancements** - Animations, sound effects, particle effects
7. **Advanced Features** - High scores, achievements, more level types
8. **Polish & Testing** - Performance optimization, Android deployment
9. **Release Preparation** - App store assets, final testing

## Key Game Mechanics (IMPLEMENTED)
- **Authentic Launch**: Ball starts bottom-right, travels up channel, curves into peg field
- **Smart Peg Spacing**: 35px minimum spacing prevents overlap, ensures smooth ball flow
- **Pattern Variety**: Hexagonal, Triangle, and Random patterns cycle through levels
- **Physics Simulation**: 60 FPS with gravity, air resistance, realistic bouncing
- **Special Pegs**: 2-4 highlighted pegs per level trigger 5+ bonus balls
- **Inverse Scoring**: Edge slots = 2000pts, center = 1000pts, sides = 50-200pts
- **Power System**: Drag-to-charge launcher with visual power meter