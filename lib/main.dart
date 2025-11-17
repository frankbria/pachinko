import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/game_manager.dart';
import 'services/audio_service.dart';
import 'services/storage_service.dart';
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

  @override
  void initState() {
    super.initState();
    // Create and initialize AudioService
    _audioService = AudioService();
    _audioService.initialize();

    // Initialize StorageService asynchronously
    _initializeStorageService();
  }

  Future<void> _initializeStorageService() async {
    final storageService = await StorageService.initialize();
    if (mounted) {
      setState(() {
        _storageService = storageService;
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
        // GameManager provider with ChangeNotifier support and service injection
        ChangeNotifierProvider(
          create: (context) => GameManager(
            audioService: _audioService,
            storageService: _storageService,
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
