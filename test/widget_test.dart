// Basic Flutter widget test for Pachinko game
//
// This test verifies that the application launches correctly with proper
// Provider setup and MenuScreen initialization.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pachinko_game/main.dart';
import 'package:pachinko_game/services/game_manager.dart';
import 'package:pachinko_game/services/audio_service.dart';
import 'package:pachinko_game/screens/menu_screen.dart';

void main() {
  testWidgets('Pachinko app launches with MenuScreen', (WidgetTester tester) async {
    // Build our app and trigger a frame
    final audioService = AudioService();
    await audioService.initialize();
    await tester.pumpWidget(PachinkoApp(audioService: audioService));

    // Verify that MenuScreen is displayed
    expect(find.byType(MenuScreen), findsOneWidget);

    // Verify that GameManager Provider is available
    final BuildContext context = tester.element(find.byType(MenuScreen));
    expect(Provider.of<GameManager>(context, listen: false), isNotNull);

    audioService.dispose();
  });

  testWidgets('PachinkoApp provides GameManager through Provider', (WidgetTester tester) async {
    // Build the app
    final audioService = AudioService();
    await audioService.initialize();
    await tester.pumpWidget(PachinkoApp(audioService: audioService));

    // Verify Provider setup by accessing GameManager
    final BuildContext context = tester.element(find.byType(MaterialApp));
    final gameManager = Provider.of<GameManager>(context, listen: false);

    expect(gameManager, isNotNull);
    expect(gameManager, isA<GameManager>());

    audioService.dispose();
  });
}
