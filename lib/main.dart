import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/game_manager.dart';
import 'screens/menu_screen.dart';
import 'utils/constants.dart';

void main() {
  runApp(const PachinkoApp());
}

class PachinkoApp extends StatelessWidget {
  const PachinkoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => GameManager(),
      child: MaterialApp(
        title: GameStrings.appName,
        theme: ThemeData(
          colorScheme: ColorScheme.dark(
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
