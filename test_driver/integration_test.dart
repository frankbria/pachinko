import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

/// The host side of `integration_test/screenshots.dart`: saves each screenshot
/// the app sends back as `build/screenshots/<name>.png`.
Future<void> main() => integrationDriver(
      onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
        File('build/screenshots/$name.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(bytes);
        return true;
      },
    );
