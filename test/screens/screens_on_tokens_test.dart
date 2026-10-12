import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pachinko_game/models/achievement.dart';
import 'package:pachinko_game/screens/achievements_screen.dart';
import 'package:pachinko_game/screens/high_scores_screen.dart';
import 'package:pachinko_game/screens/menu_screen.dart';
import 'package:pachinko_game/screens/settings_screen.dart';
import 'package:pachinko_game/services/achievement_service.dart';
import 'package:pachinko_game/services/game_manager.dart';
import 'package:pachinko_game/services/storage_service.dart';
import 'package:pachinko_game/utils/constants.dart';
import 'package:pachinko_game/utils/game_theme.dart';
import 'package:pachinko_game/widgets/achievement_toast.dart';

/// The screens around the game, on the design tokens (issue #32).
///
/// Real services over an in-memory SharedPreferences, the real theme, and a
/// Pixel 7 sized screen. The contrast check walks every text and icon that
/// is on screen and compares its colour with whatever is painted behind it.
void main() {
  late SharedPreferences prefs;
  late StorageService storage;
  late AchievementService achievements;
  late GameManager manager;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    storage = StorageService(prefs: prefs);
    achievements = await AchievementService.create(prefs);
    manager =
        GameManager(storageService: storage, achievementService: achievements);
  });

  tearDown(() => manager.dispose());

  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MultiProvider(
      providers: [
        Provider<StorageService?>.value(value: storage),
        ChangeNotifierProvider<AchievementService?>.value(value: achievements),
        ChangeNotifierProvider<GameManager>.value(value: manager),
      ],
      child: MaterialApp(theme: buildGameTheme(), home: home),
    ));
    await tester.pumpAndSettle();
  }

  /// WCAG contrast ratio between two opaque colours.
  double contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  /// The colour painted behind [element]: every fill among its ancestors,
  /// nearest first, blended until one is opaque.
  Color backgroundOf(Element element) {
    final fills = <Color>[];
    element.visitAncestorElements((ancestor) {
      final widget = ancestor.widget;
      Color? fill;
      if (widget is ColoredBox) {
        fill = widget.color;
      } else if (widget is DecoratedBox && widget.decoration is BoxDecoration) {
        final decoration = widget.decoration as BoxDecoration;
        fill = decoration.color ?? decoration.gradient?.colors.first;
      } else if (widget is Material &&
          widget.type != MaterialType.transparency) {
        fill = widget.color;
      }
      if (fill != null && fill.a > 0) {
        fills.add(fill);
        if (fill.a >= 1.0) return false;
      }
      return true;
    });
    Color behind = GameConstants.backgroundColor;
    for (final fill in fills.reversed) {
      behind = Color.alphaBlend(fill, behind);
    }
    return behind;
  }

  /// Every text and icon on screen whose contrast with its background is
  /// below 4.5 to 1, described for a failure message.
  List<String> lowContrast(WidgetTester tester) {
    final failures = <String>[];
    for (final element in find.byType(RichText).evaluate()) {
      final text = (element.widget as RichText).text;
      final colour = text.style?.color;
      if (colour == null) continue;
      final behind = backgroundOf(element);
      final ratio = contrast(Color.alphaBlend(colour, behind), behind);
      if (ratio < 4.5) {
        final label = text.toPlainText();
        failures.add(
            '"${label.length > 30 ? label.substring(0, 30) : label}" at ${ratio.toStringAsFixed(2)} '
            '(${colour.toARGB32().toRadixString(16)} on ${behind.toARGB32().toRadixString(16)})');
      }
    }
    return failures;
  }

  group('Contrast of at least 4.5 to 1', () {
    testWidgets('on the menu', (tester) async {
      await pump(tester, const MenuScreen());
      expect(lowContrast(tester), isEmpty);
    });

    testWidgets('on the level picker, with a level played', (tester) async {
      await storage.saveHighScore(1, 12500);
      await pump(tester, const MenuScreen());
      await tester.tap(find.text('Select Level'));
      await tester.pumpAndSettle();
      expect(find.byType(GridView), findsOneWidget);
      expect(lowContrast(tester), isEmpty);
    });

    testWidgets('on How to Play', (tester) async {
      await pump(tester, const MenuScreen());
      await tester.tap(find.text('How to Play'));
      await tester.pumpAndSettle();
      expect(lowContrast(tester), isEmpty);
    });

    testWidgets('on high scores, empty and filled, and its clear dialog',
        (tester) async {
      await pump(tester, const HighScoresScreen());
      expect(find.textContaining('No high scores yet!'), findsOneWidget);
      expect(lowContrast(tester), isEmpty);

      await storage.saveHighScore(3, 8500);
      await storage.saveHighScore(1, 5000);
      await pump(tester, const SizedBox());
      await pump(tester, const HighScoresScreen());
      expect(find.text('8,500 points'), findsOneWidget);
      expect(lowContrast(tester), isEmpty);

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();
      expect(lowContrast(tester), isEmpty);
    });

    testWidgets('on achievements, all locked and with some unlocked',
        (tester) async {
      await pump(tester, const AchievementsScreen());
      expect(find.textContaining('Locked ('), findsOneWidget);
      expect(lowContrast(tester), isEmpty);

      achievements.trackBallLaunched();
      await pump(tester, const SizedBox());
      await pump(tester, const AchievementsScreen());
      expect(find.textContaining('Unlocked ('), findsOneWidget);
      expect(lowContrast(tester), isEmpty);
    });

    testWidgets('on settings', (tester) async {
      await pump(tester, const SettingsScreen());
      expect(lowContrast(tester), isEmpty);
    });

    testWidgets('on the achievement toast', (tester) async {
      final achievement = Achievement(
        id: 'test',
        name: 'First Launch',
        description: 'Launch a ball',
        icon: Icons.rocket_launch,
        pointValue: 10,
      );
      await pump(
          tester,
          Scaffold(
              body: Center(child: AchievementToast(achievement: achievement))));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('First Launch'), findsOneWidget);
      expect(lowContrast(tester), isEmpty);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });
  });

  group('Menu', () {
    testWidgets(
        'given a Pixel 7 screen, then the title and its glow fit inside it',
        (tester) async {
      await pump(tester, const MenuScreen());

      final title = tester.widget<Text>(find.text(GameStrings.appName));
      final glow = title.style!.shadows!
          .map((shadow) => shadow.blurRadius + shadow.offset.distance)
          .reduce(math.max);
      final box = tester.getRect(find.text(GameStrings.appName));
      final screen =
          Offset.zero & tester.view.physicalSize / tester.view.devicePixelRatio;

      expect(glow, greaterThan(0), reason: 'the sign glows');
      expect(box.left - glow, greaterThanOrEqualTo(screen.left));
      expect(box.right + glow, lessThanOrEqualTo(screen.right));
      expect(box.top - glow, greaterThanOrEqualTo(screen.top));
    });

    testWidgets(
        'given the menu, then it is on the cabinet background with no fill of its own',
        (tester) async {
      await pump(tester, const MenuScreen());

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor,
          anyOf(isNull, GameConstants.backgroundColor));
      expect(
          backgroundOf(
              tester.element(find.text('Physics-based Pachinko Game'))),
          GameConstants.backgroundColor);
    });
  });

  group('Level picker', () {
    testWidgets(
        'given levels 1 and 7 have been played, then their tiles show their best scores and the rest none',
        (tester) async {
      await storage.saveHighScore(1, 12500);
      await storage.saveHighScore(1, 9000);
      await storage.saveHighScore(7, 800);
      await pump(tester, const MenuScreen());

      await tester.tap(find.text('Select Level'));
      await tester.pumpAndSettle();

      Finder tile(int level) => find
          .ancestor(
              of: find.text('$level'), matching: find.byType(GestureDetector))
          .first;
      expect(find.descendant(of: tile(1), matching: find.text('12,500')),
          findsOneWidget);
      expect(find.descendant(of: tile(7), matching: find.text('800')),
          findsOneWidget);
      expect(find.descendant(of: tile(2), matching: find.byType(Text)),
          findsOneWidget,
          reason: 'only its number');
    });

    testWidgets(
        'given the picker, then all twenty levels are on screen without scrolling',
        (tester) async {
      await pump(tester, const MenuScreen());
      await tester.tap(find.text('Select Level'));
      await tester.pumpAndSettle();

      final dialog = tester.getRect(find.byType(AlertDialog));
      for (final level in [1, 5, 16, 20]) {
        expect(dialog.contains(tester.getCenter(find.text('$level'))), isTrue,
            reason: 'level $level');
      }
    });
  });

  group('How to Play', () {
    testWidgets(
        'given the dialog, then it does not mention aiming and has no emoji',
        (tester) async {
      await pump(tester, const MenuScreen());
      await tester.tap(find.text('How to Play'));
      await tester.pumpAndSettle();

      final words = find
          .descendant(of: find.byType(AlertDialog), matching: find.byType(Text))
          .evaluate()
          .map((element) => (element.widget as Text).data ?? '')
          .join('\n');
      expect(words.toLowerCase(), isNot(contains('aim')));
      expect(words, contains('power'));
      // Emoji and pictographs live above U+2190
      expect(words.runes.where((rune) => rune >= 0x2190), isEmpty);
    });
  });

  group('High scores', () {
    testWidgets(
        'given stored scores, then each row shows its rank, score, level and date',
        (tester) async {
      await storage.saveHighScore(3, 8500);
      await storage.saveHighScore(1, 5000);
      await pump(tester, const HighScoresScreen());

      final first = find.ancestor(
          of: find.text('8,500 points'), matching: find.byType(ListTile));
      expect(
          find.descendant(of: first, matching: find.text('1')), findsOneWidget,
          reason: 'rank');
      expect(
          find.descendant(of: first, matching: find.textContaining('Level 3')),
          findsOneWidget);
      final today = DateTime.now();
      expect(
        find.descendant(
            of: first,
            matching: find
                .textContaining('${today.month}/${today.day}/${today.year}')),
        findsOneWidget,
      );
      final second = find.ancestor(
          of: find.text('5,000 points'), matching: find.byType(ListTile));
      expect(find.descendant(of: second, matching: find.text('2')),
          findsOneWidget);
      expect(
          find.descendant(of: second, matching: find.textContaining('Level 1')),
          findsOneWidget);
    });
  });

  group('Achievements', () {
    testWidgets(
        'given one unlocked and the rest locked, then a locked card carries a lock and an unlocked one does not',
        (tester) async {
      achievements.trackBallLaunched();
      await pump(tester, const AchievementsScreen());

      final unlocked = achievements.getUnlockedAchievements().single;
      final unlockedCard = find.ancestor(
          of: find.text(unlocked.name), matching: find.byType(ListTile));
      expect(
          find.descendant(of: unlockedCard, matching: find.byIcon(Icons.lock)),
          findsNothing);

      final locked = achievements.getLockedAchievements().first;
      await tester.scrollUntilVisible(find.text(locked.name), 200,
          scrollable: find.byType(Scrollable).first);
      final lockedCard = find.ancestor(
          of: find.text(locked.name), matching: find.byType(ListTile));
      expect(find.descendant(of: lockedCard, matching: find.byIcon(Icons.lock)),
          findsOneWidget);
    });
  });

  test('these screens name no colour outside the theme and GameConstants', () {
    for (final path in [
      'lib/screens/menu_screen.dart',
      'lib/screens/high_scores_screen.dart',
      'lib/screens/achievements_screen.dart',
      'lib/screens/settings_screen.dart',
      'lib/screens/game_screen.dart',
      'lib/widgets/round_summary_panel.dart',
      'lib/widgets/achievement_toast.dart',
      'lib/widgets/game_card.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source, isNot(contains(RegExp(r'Colors\.(?!transparent)'))),
          reason: path);
      expect(source, isNot(contains(RegExp(r'Color(\.from\w+)?\('))),
          reason: path);
    }
  });
}
