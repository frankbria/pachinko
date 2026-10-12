// Basic Flutter widget test for Pachinko game
//
// Verifies that the application launches with its Provider setup and shows
// the MenuScreen.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pachinko_game/main.dart';
import 'package:pachinko_game/services/achievement_service.dart';
import 'package:pachinko_game/services/game_manager.dart';
import 'package:pachinko_game/screens/menu_screen.dart';
import 'package:pachinko_game/widgets/achievement_toast.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Pachinko app launches with MenuScreen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const PachinkoApp());
    await tester.pump();

    expect(find.byType(MenuScreen), findsOneWidget);

    final BuildContext context = tester.element(find.byType(MenuScreen));
    expect(Provider.of<GameManager>(context, listen: false), isNotNull);
  });

  testWidgets(
      'given running app, when an achievement unlocks, then a toast is shown',
      (WidgetTester tester) async {
    await tester.pumpWidget(const PachinkoApp());
    // Let the async service initialisation in PachinkoApp finish
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }

    final context = tester.element(find.byType(MenuScreen));
    final service = Provider.of<AchievementService?>(context, listen: false);
    expect(service, isNotNull);

    // 'first_launch' unlocks on the first ball launched
    service!.trackBallLaunched();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(AchievementToast), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 3500));
    await tester.pumpAndSettle();
  });
}
