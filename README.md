# Pachinko Game 🎮

A modern, graphical Pachinko idle game built with Flutter for Android. Features authentic pachinko machine mechanics with realistic ball physics, strategic scoring, and beautiful visual effects.

## 🚀 Project Status

**Current Release**: v0.1.0 - Playable Prototype
**Active Development Branch**: [`002-graphics-overhaul`](https://github.com/frankbria/pachinko/tree/002-graphics-overhaul) (65% complete)

### What's Working in Master
- ✅ **Authentic Ball Launching** - Bottom-right launch channel with drag-to-charge power meter
- ✅ **Advanced Physics Engine** - 60 FPS realistic ball physics with gravity and collisions
- ✅ **Level System** - 3 distinct levels with varying peg patterns
- ✅ **Special Pegs & Bonuses** - Hit all special pegs to trigger bonus balls
- ✅ **Cross-Platform Ready** - Runs on Linux desktop, configured for Android

### 🔨 In Development (`002-graphics-overhaul` Branch)

The graphics architecture overhaul transforms the prototype into a polished game:

**✅ Completed (Phase 1-5 - 65%)**:
- Particle system with trail and collision effects
- Performance monitoring with adaptive quality
- Animated glow effects on special pegs (pulsing golden halos)
- Enhanced collision particles (12 for special, 16 for bonus)
- 303 tests passing (98.45% graphics coverage)

**🔄 Next (Phase 6-8 - 35%)**:
- UI polish (transitions, score animations, anti-aliasing)
- Performance optimization (quality adjustments, memory)
- Documentation and cross-platform testing

See [DEVELOPMENT.md](./DEVELOPMENT.md) for feature branch workflow details.

## 🎮 Game Features

- **Authentic Pachinko Mechanics**: Ball launches from bottom-right, travels up a channel, curves around, and falls through pegs
- **Advanced Physics Engine**: 60 FPS simulation with realistic collision detection and ball movement
- **Smart Peg Patterns**: Three different layouts (hexagonal, triangle, random) with proper spacing
- **Special Peg Bonuses**: Hit all highlighted pegs to trigger multi-ball bonuses
- **Strategic Scoring**: Inverse probability distribution - edge slots give highest points
- **Level Progression**: Infinite levels with varying patterns and increasing difficulty

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.24.5 or higher)
- Linux development tools (for Linux builds)
- Android Studio (for Android builds)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/frankbria/pachinko.git
cd pachinko
```

2. Install Flutter dependencies:
```bash
flutter pub get
```

3. Run the game:
```bash
# For Linux desktop
flutter run -d linux

# For Android (requires Android Studio)
flutter run -d android

# For web
flutter run -d web-server
```

## 🎯 How to Play

1. **Launch a Ball**: Drag from the bottom-right corner to build launch power
2. **Watch the Power Meter**: Green = low power, Red = high power
3. **Release to Launch**: Ball travels up the channel and enters the peg field
4. **Score Points**: Ball bounces through pegs and lands in scoring slots
5. **Special Bonus**: Hit all orange pegs to spawn bonus balls!

### Scoring System
- **Edge Slots**: 2000 points (hardest to reach)
- **Center Slot**: 1000 points (medium difficulty)
- **Side Slots**: 50-200 points (easiest to reach)

## 🏗️ Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/                      # Game objects (Ball, Peg, Slot, Level)
├── services/                    # Game logic (PhysicsEngine, GameManager)
├── screens/                     # UI screens (Menu, Game)
├── widgets/                     # Custom widgets (PachinkoBoard)
└── utils/                       # Constants and patterns
```

## 📱 Platform Support

- ✅ Linux Desktop (fully tested)
- ✅ Android (ready for deployment)
- ✅ Web (supported)
- ✅ Windows (supported)
- ✅ macOS (supported)
- ✅ iOS (supported)

## 🔧 Development

### Current Status
- Core gameplay mechanics complete
- Physics engine fully functional
- UI and game flow implemented
- Ready for polish and additional features

### Next Features
- Sound effects and music
- Particle effects and animations
- High score system
- Achievement system
- More level variety

## 📝 Documentation

- [Product Requirements](PRD.md)
- [Development Guide](CLAUDE.md)
- [Development Todo List](DEVELOPMENT_TODO.md)
- [AI Handoff Document](AI_HANDOFF.md)

## 📄 License

This project is open source. Feel free to use and modify as needed.

## 🤝 Contributing

Contributions are welcome! Feel free to submit issues and pull requests.

---

Built with ❤️ using Flutter