// Unit tests for the app theme built from the colour roles in GameConstants.
//
// Contrast is checked with the WCAG formula; 4.5:1 is the minimum for normal
// text. The dialog action colour was about 1.8:1 before the roles existed.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pachinko_game/utils/constants.dart';
import 'package:pachinko_game/utils/game_theme.dart';

/// WCAG contrast ratio between two opaque colours.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  final theme = buildGameTheme();
  final scheme = theme.colorScheme;
  final text = theme.textTheme;

  group('Game theme colours -', () {
    test('given the theme, then its scheme is built from the colour roles', () {
      expect(scheme.primary, equals(GameConstants.primaryColor));
      expect(scheme.onPrimary, equals(GameConstants.onPrimaryColor));
      expect(scheme.secondary, equals(GameConstants.secondaryColor));
      expect(scheme.surface, equals(GameConstants.surfaceColor));
      expect(
          theme.scaffoldBackgroundColor, equals(GameConstants.backgroundColor));
    });

    testWidgets(
        'given a dialog, then its action text is readable on the dialog surface',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: AlertDialog(
          content: const Text('Body'),
          actions: [TextButton(onPressed: () {}, child: const Text('Got it!'))],
        ),
      ));

      final surface = tester
          .widget<Material>(find
              .descendant(
                  of: find.byType(AlertDialog), matching: find.byType(Material))
              .first)
          .color!;
      final action = tester.widget<RichText>(find.descendant(
          of: find.byType(TextButton), matching: find.byType(RichText)));

      expect(contrast(action.text.style!.color!, surface),
          greaterThanOrEqualTo(4.5));
    });

    test('given a control on the primary colour, then its content is readable',
        () {
      expect(contrast(scheme.onPrimary, scheme.primary),
          greaterThanOrEqualTo(4.5));
    });

    test(
        'given body text, then it is readable on the surface and on the background',
        () {
      expect(contrast(scheme.onSurface, scheme.surface),
          greaterThanOrEqualTo(4.5));
      expect(contrast(scheme.onSurface, theme.scaffoldBackgroundColor),
          greaterThanOrEqualTo(4.5));
      expect(contrast(scheme.onSurfaceVariant, scheme.surface),
          greaterThanOrEqualTo(4.5));
    });
  });

  group('Game theme type -', () {
    test(
        'given display, headline, title and label styles, then they use Oxanium',
        () {
      final styles = [
        text.displayLarge,
        text.displayMedium,
        text.displaySmall,
        text.headlineLarge,
        text.headlineMedium,
        text.headlineSmall,
        text.titleLarge,
        text.titleMedium,
        text.titleSmall,
        text.labelLarge,
        text.labelMedium,
        text.labelSmall,
      ];
      for (final style in styles) {
        expect(style!.fontFamily, equals(displayFontFamily));
      }
    });

    test('given body styles, then they stay on Roboto', () {
      for (final style in [text.bodyLarge, text.bodyMedium, text.bodySmall]) {
        expect(style!.fontFamily, equals('Roboto'));
      }
    });

    test(
        'given the project, then Oxanium is bundled in regular and bold with its licence',
        () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('family: $displayFontFamily'));
      for (final name in ['Oxanium-Regular.ttf', 'Oxanium-Bold.ttf']) {
        expect(File('assets/fonts/$name').existsSync(), isTrue, reason: name);
        expect(pubspec, contains('assets/fonts/$name'));
      }
      // Without its weight the bold file would never be picked for FontWeight.bold.
      expect(pubspec, matches(RegExp(r'Oxanium-Bold\.ttf\s+weight: 700')));
      expect(File('assets/fonts/OFL.txt').existsSync(), isTrue);
    });
  });
}
