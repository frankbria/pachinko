import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/game_manager.dart';
import 'services/audio_service.dart';
import 'services/storage_service.dart';
import 'services/achievement_service.dart';
import 'screens/menu_screen.dart';
import 'utils/constants.dart';

void main() {
  runApp(const PachinkoApp());
}

class PachinkoApp extends StatefulWidget {
  const PachinkoApp({super.key});

  @override
  State<PachinkoApp> createState() => _PachinkoAppState();
}

class _PachinkoAppState extends State<PachinkoApp> {
  late final AudioService _audioService;
  StorageService? _storageService;
  AchievementService? _achievementService;

  @override
  void initState() {
    super.initState();
    // Create and initialize AudioService
    _audioService = AudioService();
    _audioService.initialize();

    // Initialize StorageService and AchievementService asynchronously
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    final prefs = await SharedPreferences.getInstance();
    final storageService = StorageService(prefs: prefs);
    final achievementService = await AchievementService.create(prefs);

    if (mounted) {
      setState(() {
        _storageService = storageService;
        _achievementService = achievementService;
      });
    }
  }

  @override
  void dispose() {
    // Dispose AudioService to free resources
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // AudioService provider (non-ChangeNotifier)
        Provider<AudioService>.value(value: _audioService),
        // StorageService provider (nullable until initialized)
        Provider<StorageService?>.value(value: _storageService),
        // AchievementService provider (nullable until initialized, with ChangeNotifier)
        ChangeNotifierProvider<AchievementService?>.value(value: _achievementService),
        // GameManager provider with ChangeNotifier support and service injection
        ChangeNotifierProvider(
          create: (context) => GameManager(
            audioService: _audioService,
            storageService: _storageService,
            achievementService: _achievementService,
          ),
        ),
      ],
      child: MaterialApp(
        title: GameStrings.appName,
        theme: ThemeData(
          colorScheme: const ColorScheme.dark(
            primary: GameConstants.primaryColor,
            primaryContainer: GameConstants.primaryVariantColor,
            secondary: GameConstants.secondaryColor,
            surface: GameConstants.surfaceColor,
            error: GameConstants.errorColor,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: const MenuScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
