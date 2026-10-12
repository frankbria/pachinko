import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pachinko_game/models/level.dart';
import 'package:pachinko_game/utils/constants.dart';
import 'package:pachinko_game/widgets/board_static_layer.dart';

/// Levels are grouped into bands, each with its own felt and rim colour, so
/// that the player can see how far they have come.
void main() {
  const bands = GameConstants.levelBands;
  const perBand = GameConstants.levelsPerBand;

  group('The band of a level', () {
    test('given the first and last level of each band, then each maps to its own band', () {
      for (int band = 0; band < bands.length; band++) {
        final first = band * perBand + 1;
        final last = (band + 1) * perBand;
        expect(GameConstants.bandForLevel(first), same(bands[band]), reason: 'level $first');
        expect(GameConstants.bandForLevel(last), same(bands[band]), reason: 'level $last');
      }
    });

    test('given the level after a band\'s last, then the band changes', () {
      for (int band = 0; band < bands.length - 1; band++) {
        final last = (band + 1) * perBand;
        expect(GameConstants.bandForLevel(last + 1), isNot(same(GameConstants.bandForLevel(last))));
      }
    });

    test('given levels beyond the last band, then the bands come round again', () {
      final beyond = bands.length * perBand;

      expect(GameConstants.bandForLevel(beyond + 1), same(bands.first));
      expect(GameConstants.bandForLevel(beyond + perBand), same(bands.first));
      expect(GameConstants.bandForLevel(beyond + perBand + 1), same(bands[1]));
      expect(GameConstants.bandForLevel(beyond * 3 + 1), same(bands.first));
    });

    test('given a level number below 1, then it is the first band', () {
      expect(GameConstants.bandForLevel(0), same(bands.first));
      expect(GameConstants.bandForLevel(-7), same(bands.first));
    });

    test('the first band is the look the game has always had', () {
      expect(bands.first.felt, GameConstants.feltColor);
      expect(bands.first.feltShade, GameConstants.feltShadeColor);
      expect(bands.first.rim, GameConstants.primaryColor);
    });
  });

  group('Role colours on every band', () {
    /// WCAG contrast ratio between two opaque colours.
    double contrast(Color a, Color b) {
      final la = a.computeLuminance();
      final lb = b.computeLuminance();
      return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
    }

    const roles = {
      'gold': GameConstants.goldColor,
      'brass': GameConstants.brassColor,
      'the 50 tier': GameConstants.slot50Color,
      'the 200 tier': GameConstants.slot200Color,
      'the 1000 tier': GameConstants.slot1000Color,
      'the 2000 tier': GameConstants.slot2000Color,
      'cyan': GameConstants.cyanColor,
      'ink': GameConstants.inkColor,
    };

    test('given any band, then every role colour stands out from its felt, lit or shaded', () {
      for (final band in bands) {
        roles.forEach((name, colour) {
          expect(contrast(colour, band.felt), greaterThanOrEqualTo(3.0), reason: '$name on ${band.name} felt');
          expect(contrast(colour, band.feltShade), greaterThanOrEqualTo(3.0), reason: '$name on ${band.name} shade');
        });
      }
    });

    test('given any two bands, then their felts and their rims differ', () {
      expect(bands.map((band) => band.felt).toSet(), hasLength(bands.length));
      expect(bands.map((band) => band.rim).toSet(), hasLength(bands.length));
    });

    test('no band takes gold or brass for its rim', () {
      // Gold is score and prizes; brass is pins
      for (final band in bands) {
        expect(band.rim, isNot(GameConstants.goldColor));
        expect(band.rim, isNot(GameConstants.brassColor));
      }
    });
  });

  group('The board in a band\'s colours', () {
    Level level(int number) => Level.generate(number, GameConstants.boardWidth, GameConstants.boardHeight);
    int rgb(Color colour) => colour.toARGB32() & 0xFFFFFF;

    test('given a level, then the rail glows in its band\'s rim colour', () {
      for (int band = 0; band < bands.length; band++) {
        final canvas = TestRecordingCanvas();
        paintBoardStaticLayer(canvas, level(band * perBand + 1));

        final glows = canvas.invocations
            .map((entry) => entry.invocation)
            .where((call) => call.memberName == #drawPath)
            .map((call) => call.positionalArguments[1] as Paint)
            .where((paint) => paint.shader == null);
        expect(glows, isNotEmpty);
        expect(glows.map((paint) => rgb(paint.color)).toSet(), {rgb(bands[band].rim)}, reason: bands[band].name);
      }
    });

    testWidgets('given a level, then the felt is its band\'s colour', (tester) async {
      /// The colour of the felt at a point with no peg, slot, rail or sign on it.
      Future<Color> feltAt(int levelNumber) async {
        final recorder = ui.PictureRecorder();
        paintBoardStaticLayer(Canvas(recorder), level(levelNumber));
        final picture = recorder.endRecording();
        final pixel = await tester.runAsync(() async {
          final image = await picture.toImage(400, 600);
          final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
          image.dispose();
          const at = (455 * 400 + 200) * 4;
          return Color.fromARGB(255, data.getUint8(at), data.getUint8(at + 1), data.getUint8(at + 2));
        });
        picture.dispose();
        return pixel!;
      }

      double distance(Color a, Color b) => math.sqrt(
          math.pow(a.r - b.r, 2).toDouble() + math.pow(a.g - b.g, 2).toDouble() + math.pow(a.b - b.b, 2).toDouble());

      for (int band = 0; band < bands.length; band++) {
        final felt = await feltAt(band * perBand + 1);
        // Between the band's felt and its shade, and nearer to them than to any other band's
        final own = math.min(distance(felt, bands[band].felt), distance(felt, bands[band].feltShade));
        for (int other = 0; other < bands.length; other++) {
          if (other == band) continue;
          final theirs = math.min(distance(felt, bands[other].felt), distance(felt, bands[other].feltShade));
          expect(own, lessThan(theirs), reason: '${bands[band].name} against ${bands[other].name}');
        }
      }
    });
  });
}
