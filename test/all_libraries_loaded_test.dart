// Imports every file under lib/ so that coverage sees all of them.
//
// `flutter test --coverage` only records the libraries a test loads. A new file
// that no test imports is missing from coverage/lcov.info, and the CI check on
// the coverage of changed lines then skips it instead of counting it as
// uncovered. Loading every library here closes that gap, and the test below
// fails when a file is added to lib/ without being added to this list.
//
// The imports are unused on purpose.
// ignore_for_file: unused_import
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pachinko_game/main.dart';
import 'package:pachinko_game/models/achievement.dart';
import 'package:pachinko_game/models/ball.dart';
import 'package:pachinko_game/models/ball_launcher.dart';
import 'package:pachinko_game/models/confetti_particle.dart';
import 'package:pachinko_game/models/game_state.dart';
import 'package:pachinko_game/models/high_score.dart';
import 'package:pachinko_game/models/level.dart';
import 'package:pachinko_game/models/peg.dart';
import 'package:pachinko_game/models/round_summary.dart';
import 'package:pachinko_game/models/slot.dart';
import 'package:pachinko_game/screens/achievements_screen.dart';
import 'package:pachinko_game/screens/game_screen.dart';
import 'package:pachinko_game/screens/high_scores_screen.dart';
import 'package:pachinko_game/screens/menu_screen.dart';
import 'package:pachinko_game/services/achievement_service.dart';
import 'package:pachinko_game/services/audio_service.dart';
import 'package:pachinko_game/services/game_manager.dart';
import 'package:pachinko_game/services/physics_engine.dart';
import 'package:pachinko_game/services/storage_service.dart';
import 'package:pachinko_game/utils/constants.dart';
import 'package:pachinko_game/utils/game_theme.dart';
import 'package:pachinko_game/utils/peg_patterns.dart';
import 'package:pachinko_game/widgets/achievement_toast.dart';
import 'package:pachinko_game/widgets/achievement_toast_overlay.dart';
import 'package:pachinko_game/widgets/board_effects.dart';
import 'package:pachinko_game/widgets/board_static_layer.dart';
import 'package:pachinko_game/widgets/floating_text.dart';
import 'package:pachinko_game/widgets/pachinko_board.dart';
import 'package:pachinko_game/widgets/round_summary_panel.dart';

void main() {
  test('given the files under lib/, when compared with this file\'s imports, then every one is imported', () {
    final imported = RegExp(r"^import 'package:pachinko_game/(.+)';$", multiLine: true)
        .allMatches(File('test/all_libraries_loaded_test.dart').readAsStringSync())
        .map((match) => match.group(1))
        .toSet();
    final present = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .map((file) => file.path.replaceAll(r'\', '/').substring('lib/'.length))
        .where((path) => path.endsWith('.dart'))
        .toSet();

    expect(present.difference(imported), isEmpty,
        reason: 'Add an import for each of these to test/all_libraries_loaded_test.dart');
    expect(imported.difference(present), isEmpty,
        reason: 'These imports name files that are no longer under lib/');
  });
}
