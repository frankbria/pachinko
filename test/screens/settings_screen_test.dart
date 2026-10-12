import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pachinko_game/screens/menu_screen.dart';
import 'package:pachinko_game/screens/settings_screen.dart';
import 'package:pachinko_game/services/game_manager.dart';
import 'package:pachinko_game/services/storage_service.dart';
import 'package:pachinko_game/utils/game_theme.dart';

/// The settings screen and the one setting on it: whether a ball may only be
/// launched once no ball is in play.
///
/// Real objects throughout, over an in-memory SharedPreferences, so that
/// "survives a restart" can be shown by building a second manager on the
/// same preferences.
void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  GameManager managerOn(SharedPreferences prefs) =>
      GameManager(storageService: StorageService(prefs: prefs));

  Future<void> pump(WidgetTester tester, GameManager manager, Widget home) =>
      tester.pumpWidget(ChangeNotifierProvider<GameManager>.value(
        value: manager,
        child: MaterialApp(theme: buildGameTheme(), home: home),
      ));

  testWidgets('given a first run, then the toggle is on', (tester) async {
    final manager = managerOn(prefs);
    addTearDown(manager.dispose);

    await pump(tester, manager, const SettingsScreen());

    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isTrue);
    expect(manager.gameState.singleBallLaunch, isTrue);
  });

  testWidgets('given the toggle is switched off, then the game follows and the choice survives a restart',
      (tester) async {
    final manager = managerOn(prefs);
    addTearDown(manager.dispose);
    await pump(tester, manager, const SettingsScreen());

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isFalse);
    expect(manager.gameState.singleBallLaunch, isFalse);

    // A restart: a new manager over the same stored preferences
    final restarted = managerOn(prefs);
    addTearDown(restarted.dispose);
    expect(restarted.gameState.singleBallLaunch, isFalse);
    await pump(tester, restarted, const SettingsScreen());
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isFalse);
  });

  testWidgets('given the menu, when Settings is tapped, then the settings screen opens', (tester) async {
    final manager = managerOn(prefs);
    addTearDown(manager.dispose);
    await pump(tester, manager, const MenuScreen());

    await tester.ensureVisible(find.text('Settings'));
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  test('given no storage, when the setting is changed, then the game still follows', () async {
    final manager = GameManager();
    addTearDown(manager.dispose);

    await manager.setSingleBallLaunch(false);

    expect(manager.gameState.singleBallLaunch, isFalse);
  });

  test('the settings screen takes its colours from the theme and the roles', () {
    final source = File('lib/screens/settings_screen.dart').readAsStringSync();

    expect(source, isNot(contains('Colors.')));
    expect(source, isNot(contains(RegExp(r'Color(\.from\w+)?\('))));
  });
}
