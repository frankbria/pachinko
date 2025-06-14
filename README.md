# Pachinko Game

A modern graphical Pachinko idle game built with Flutter. Features authentic pachinko machine mechanics with realistic ball launching, physics simulation, and strategic scoring.

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