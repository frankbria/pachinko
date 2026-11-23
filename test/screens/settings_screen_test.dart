import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pachinko_game/models/game_settings.dart';
import 'package:pachinko_game/screens/menu_screen.dart';
import 'package:pachinko_game/screens/settings_screen.dart';
import 'package:pachinko_game/services/game_manager.dart';
import 'package:pachinko_game/services/storage_service.dart';
import 'package:pachinko_game/utils/constants.dart';
import 'package:pachinko_game/utils/game_theme.dart';

/// The settings screen: whether a ball may only be launched once no ball is
/// in play, sound, its volume and the music's, vibration, reduced motion,
/// the launcher's side, and the credits.
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

  bool switchValue(WidgetTester tester, String title) => tester
      .widget<SwitchListTile>(find.ancestor(
          of: find.text(title), matching: find.byType(SwitchListTile)))
      .value;

  /// The slider under the setting called [title].
  Finder sliderFor(String title) => find.descendant(
      of: find.ancestor(of: find.text(title), matching: find.byType(ListTile)),
      matching: find.byType(Slider));

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

    expect(switchValue(tester, GameStrings.singleBallLaunch), isTrue);
    expect(manager.gameState.singleBallLaunch, isTrue);
  });

  testWidgets(
      'given the toggle is switched off, then the game follows and the choice survives a restart',
      (tester) async {
    final manager = managerOn(prefs);
    addTearDown(manager.dispose);
    await pump(tester, manager, const SettingsScreen());

    await tester.tap(find.text(GameStrings.singleBallLaunch));
    await tester.pumpAndSettle();

    expect(switchValue(tester, GameStrings.singleBallLaunch), isFalse);
    expect(manager.gameState.singleBallLaunch, isFalse);

    // A restart: a new manager over the same stored preferences
    final restarted = managerOn(prefs);
    addTearDown(restarted.dispose);
    expect(restarted.gameState.singleBallLaunch, isFalse);
    await pump(tester, restarted, const SettingsScreen());
    expect(switchValue(tester, GameStrings.singleBallLaunch), isFalse);
  });

  group('sound, vibration and motion', () {
    testWidgets(
        'given a first run, then sound and vibration are on at full volume and motion follows the system',
        (tester) async {
      final manager = managerOn(prefs);
      addTearDown(manager.dispose);
      await pump(tester, manager, const SettingsScreen());

      expect(switchValue(tester, GameStrings.soundEffects), isTrue);
      expect(tester.widget<Slider>(sliderFor(GameStrings.volume)).value, 1.0);
      expect(
          tester.widget<Slider>(sliderFor(GameStrings.musicVolume)).value, 0.7);
      expect(switchValue(tester, GameStrings.vibration), isTrue);
      expect(switchValue(tester, GameStrings.reducedMotion), isFalse);
      expect(switchValue(tester, GameStrings.leftHanded), isFalse);

      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await tester.pump();
      expect(switchValue(tester, GameStrings.reducedMotion), isTrue,
          reason:
              'the system asks for less motion and the player has not chosen');
    });

    testWidgets(
        'given each setting changed, then the game follows at once and every choice survives a restart',
        (tester) async {
      final manager = managerOn(prefs);
      addTearDown(manager.dispose);
      await pump(tester, manager, const SettingsScreen());

      await tester.drag(sliderFor(GameStrings.volume), const Offset(-2000, 0));
      await tester.drag(
          sliderFor(GameStrings.musicVolume), const Offset(2000, 0));
      await tester.pumpAndSettle();
      expect(manager.settings.soundVolume, 0.0);
      expect(manager.settings.musicVolume, 1.0);
      await tester.tap(find.text(GameStrings.soundEffects));
      await tester.tap(find.text(GameStrings.vibration));
      await tester.tap(find.text(GameStrings.reducedMotion));
      await tester.ensureVisible(find.text(GameStrings.leftHanded));
      await tester.tap(find.text(GameStrings.leftHanded));
      await tester.pumpAndSettle();

      const chosen = GameSettings(
          soundOn: false,
          soundVolume: 0.0,
          musicVolume: 1.0,
          vibrationOn: false,
          reducedMotion: true,
          leftHanded: true);
      expect(manager.settings, chosen);
      expect(tester.widget<Slider>(sliderFor(GameStrings.volume)).onChanged,
          isNull,
          reason: 'the volume is for sound, which is off');
      expect(
          tester.widget<Slider>(sliderFor(GameStrings.musicVolume)).onChanged,
          isNull,
          reason: 'sound off silences the music too');

      final restarted = managerOn(prefs);
      addTearDown(restarted.dispose);
      expect(restarted.settings, chosen);
      await pump(tester, restarted, const SettingsScreen());
      expect(switchValue(tester, GameStrings.soundEffects), isFalse);
      expect(switchValue(tester, GameStrings.vibration), isFalse);
      expect(switchValue(tester, GameStrings.reducedMotion), isTrue);
      expect(switchValue(tester, GameStrings.leftHanded), isTrue);
    });
  });

  testWidgets('the settings screen credits the music and the sounds',
      (tester) async {
    final manager = managerOn(prefs);
    addTearDown(manager.dispose);
    await pump(tester, manager, const SettingsScreen());

    await tester.scrollUntilVisible(find.text(GameStrings.credits), 100);
    expect(find.textContaining('Music by Frank Bria'), findsOneWidget);
    expect(find.textContaining('mokasza'), findsOneWidget);
  });

  testWidgets(
      'given the menu, when Settings is tapped, then the settings screen opens',
      (tester) async {
    final manager = managerOn(prefs);
    addTearDown(manager.dispose);
    await pump(tester, manager, const MenuScreen());

    await tester.ensureVisible(find.text('Settings'));
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  test(
      'given no storage, when the setting is changed, then the game still follows',
      () async {
    final manager = GameManager();
    addTearDown(manager.dispose);

    await manager.setSingleBallLaunch(false);

    expect(manager.gameState.singleBallLaunch, isFalse);
  });

  test('the settings screen takes its colours from the theme and the roles',
      () {
    final source = File('lib/screens/settings_screen.dart').readAsStringSync();

    expect(source, isNot(contains('Colors.')));
    expect(source, isNot(contains(RegExp(r'Color(\.from\w+)?\('))));
  });

  testWidgets('the settings screen matches its golden', (tester) async {
    // A phone's portrait screen, with every setting showing: sound off so
    // the volume sliders are in their disabled state
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    final manager = managerOn(prefs);
    addTearDown(manager.dispose);
    await manager.updateSettings(
        (_) => const GameSettings(soundOn: false, soundVolume: 0.6));
    await pump(tester, manager, const SettingsScreen());

    await expectLater(find.byType(SettingsScreen),
        matchesGoldenFile('../widgets/goldens/settings_screen.png'));
  }, tags: ['golden']);
}
