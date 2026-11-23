import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/game_manager.dart';
import 'services/audio_service.dart';
import 'services/music_service.dart';
import 'services/haptics_service.dart';
import 'services/storage_service.dart';
import 'services/achievement_service.dart';
import 'services/daily_leaderboard.dart';
import 'screens/menu_screen.dart';
import 'utils/constants.dart';
import 'utils/game_theme.dart';
import 'widgets/achievement_toast_overlay.dart';
import 'models/achievement.dart';

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
  final MusicService _music = MusicService();
  late final AppLifecycleListener _lifecycleListener;
  final HapticsService _haptics = HapticsService();
  StorageService? _storageService;
  AchievementService? _achievementService;
  final GlobalKey<AchievementToastOverlayState> _toastOverlayKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Create and initialize AudioService (non-blocking for Linux compatibility)
    _audioService = AudioService();
    _audioService.initialize(); // No await - UI renders immediately
    _music.initialize();
    // The music pauses whatever screen is showing when the app is hidden,
    // and carries on when it returns; the game itself stays paused
    _lifecycleListener = AppLifecycleListener(
      onHide: () => _music.setAppHidden(true),
      onShow: () => _music.setAppHidden(false),
    );

    // Initialize StorageService and AchievementService asynchronously
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    final prefs = await SharedPreferences.getInstance();
    final storageService = StorageService(prefs: prefs);
    final achievementService = await AchievementService.create(prefs);

    // Set up achievement unlock callback
    achievementService.onAchievementUnlocked = _onAchievementUnlocked;

    if (mounted) {
      setState(() {
        _storageService = storageService;
        _achievementService = achievementService;
      });
    }
  }

  /// Handle achievement unlock by showing toast notification
  void _onAchievementUnlocked(Achievement achievement) {
    // Use a post-frame callback to ensure the overlay is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _toastOverlayKey.currentState?.showAchievementToast(achievement);
    });
  }

  @override
  void dispose() {
    // Dispose AudioService to free resources
    _audioService.dispose();
    _music.dispose();
    _lifecycleListener.dispose();
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
        ChangeNotifierProvider<AchievementService?>.value(
            value: _achievementService),
        // GameManager is created the first time something asks for it, which
        // can be before storage has loaded. The proxy hands it each service
        // when that service arrives, so the saved settings are applied and
        // scores are saved whichever came first
        ChangeNotifierProxyProvider2<StorageService?, AchievementService?,
            GameManager>(
          create: (context) => GameManager(
            audioService: _audioService,
            music: _music,
            haptics: _haptics,
            storageService: _storageService,
            achievementService: _achievementService,
            leaderboard:
                PlayGamesLeaderboard.fromId(GameConstants.dailyLeaderboardId),
          ),
          update: (context, storageService, achievementService, gameManager) =>
              gameManager!
                ..attachServices(
                  storageService: storageService,
                  achievementService: achievementService,
                ),
        ),
      ],
      child: MaterialApp(
        title: GameStrings.appName,
        theme: buildGameTheme(),
        // Overlay sits above the Navigator so toasts show over every route
        builder: (context, child) => AchievementToastOverlay(
          key: _toastOverlayKey,
          child: child!,
        ),
        home: const MenuScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
