// Basic Flutter widget test for Pachinko game
//
// Verifies that the application launches with its Provider setup and shows
// the MenuScreen.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pachinko_game/main.dart';
import 'package:pachinko_game/services/game_manager.dart';
import 'package:pachinko_game/screens/menu_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Pachinko app launches with MenuScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const PachinkoApp());
    await tester.pump();

    expect(find.byType(MenuScreen), findsOneWidget);

    final BuildContext context = tester.element(find.byType(MenuScreen));
    expect(Provider.of<GameManager>(context, listen: false), isNotNull);
  });
}
