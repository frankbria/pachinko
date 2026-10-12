import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
// The platform interface is the seam for a store that answers late
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/types.dart';
import 'package:pachinko_game/main.dart';
import 'package:pachinko_game/screens/menu_screen.dart';
import 'package:pachinko_game/services/game_manager.dart';
import 'package:pachinko_game/services/storage_service.dart';

/// A preferences store that does not answer until the test lets it, to
/// stand for a phone whose storage loads after the first frame.
class _GatedStore extends InMemorySharedPreferencesStore {
  _GatedStore(super.data) : super.withData();

  final Completer<void> gate = Completer<void>();

  @override
  Future<Map<String, Object>> getAll() async {
    await gate.future;
    return super.getAll();
  }

  @override
  Future<Map<String, Object>> getAllWithParameters(GetAllParameters parameters) async {
    await gate.future;
    return super.getAllWithParameters(parameters);
  }
}

/// The app loads storage after its first frame, and the game manager is
/// created the first time something asks for it. Whichever comes first, the
/// manager has to end up with the stored settings and somewhere to save.
void main() {
  group('A game manager created before storage has loaded', () {
    testWidgets('given a saved choice, when storage arrives, then the manager takes it and saves through it',
        (tester) async {
      final store = _GatedStore({'flutter.setting_single_ball_launch': false});
      SharedPreferencesStorePlatform.instance = store;
      SharedPreferences.resetStatic();

      await tester.pumpWidget(const PachinkoApp());
      final manager = Provider.of<GameManager>(tester.element(find.byType(MenuScreen)), listen: false);
      expect(manager.gameState.singleBallLaunch, isTrue, reason: 'storage has not answered: the default');

      // The settings screen is already open when storage answers
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isTrue);

      store.gate.complete();
      await tester.pumpAndSettle();

      expect(manager.gameState.singleBallLaunch, isFalse, reason: 'the saved choice, once storage has answered');
      expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isFalse,
          reason: 'the open screen follows');
      await manager.setSingleBallLaunch(true);
      expect((await SharedPreferences.getInstance()).getBool('setting_single_ball_launch'), isTrue);
    });
  });

  group('attachServices', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({'setting_single_ball_launch': false});
      prefs = await SharedPreferences.getInstance();
    });

    test('given a manager without storage, when storage is attached, then the saved choice is applied', () {
      final manager = GameManager();
      addTearDown(manager.dispose);
      expect(manager.gameState.singleBallLaunch, isTrue);

      manager.attachServices(storageService: StorageService(prefs: prefs));

      expect(manager.gameState.singleBallLaunch, isFalse);
    });

    test('given the same storage attached again, then a choice made since is not overwritten', () async {
      final storage = StorageService(prefs: prefs);
      final manager = GameManager(storageService: storage);
      addTearDown(manager.dispose);
      manager.gameState.singleBallLaunch = true;

      manager.attachServices(storageService: storage);

      expect(manager.gameState.singleBallLaunch, isTrue, reason: 'attached already: nothing to re-read');
    });

    test('given a choice made before storage arrived, when storage is attached, then the choice stands and is saved',
        () async {
      // The stored value says off; the player has since switched it on
      final manager = GameManager();
      addTearDown(manager.dispose);
      await manager.setSingleBallLaunch(true);

      manager.attachServices(storageService: StorageService(prefs: prefs));
      await Future<void>.delayed(Duration.zero);

      expect(manager.gameState.singleBallLaunch, isTrue);
      expect(prefs.getBool('setting_single_ball_launch'), isTrue);
    });

    test('given listeners, when late storage changes the setting, then they are told, just after the call', () async {
      // The call arrives while widgets are being built, when nothing may be marked for rebuild
      final manager = GameManager();
      addTearDown(manager.dispose);
      int told = 0;
      manager.addListener(() => told++);

      manager.attachServices(storageService: StorageService(prefs: prefs));
      expect(told, 0, reason: 'not during the call');
      await Future<void>.delayed(Duration.zero);

      expect(told, 1);
    });

    test('given late storage that agrees with the setting, then nobody is told', () async {
      SharedPreferences.setMockInitialValues({});
      final manager = GameManager();
      addTearDown(manager.dispose);
      int told = 0;
      manager.addListener(() => told++);

      manager.attachServices(storageService: StorageService(prefs: await SharedPreferences.getInstance()));
      await Future<void>.delayed(Duration.zero);

      expect(told, 0);
    });

    test('given a manager disposed before the news goes out, then nothing is thrown', () async {
      final manager = GameManager();
      manager.attachServices(storageService: StorageService(prefs: prefs));

      manager.dispose();

      await Future<void>.delayed(Duration.zero);
    });

    test('given no storage yet, when attached with nothing, then the manager keeps what it has', () {
      final storage = StorageService(prefs: prefs);
      final manager = GameManager(storageService: storage);
      addTearDown(manager.dispose);

      manager.attachServices();

      expect(manager.gameState.singleBallLaunch, isFalse);
    });
  });
}
