import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4, Vector2, Vector3;
import 'package:pachinko_game/models/ball.dart';
import 'package:pachinko_game/models/ball_launcher.dart';
import 'package:pachinko_game/models/game_settings.dart';
import 'package:pachinko_game/models/level.dart';
import 'package:pachinko_game/models/peg.dart';
import 'package:pachinko_game/services/game_manager.dart';
import 'package:pachinko_game/services/storage_service.dart';
import 'package:pachinko_game/utils/constants.dart';
import 'package:pachinko_game/widgets/board_static_layer.dart';
import 'package:pachinko_game/widgets/first_round_hints.dart';
import 'package:pachinko_game/widgets/pachinko_board.dart';

/// The left-handed launcher (#109): the board is drawn reflected, with the
/// launch channel and the plunger on the left, and touches are reflected
/// back. The physics, the level and the scores are those of the right-handed
/// board, so the existing dome, spacing and stuck-ball tests hold for both
/// sides; these check the reflected drawing and the touch.
///
/// The drawing is read from a recording canvas. Its calls are replayed
/// through a stack of transforms, so that each text and each sphere can be
/// checked for being drawn reflected: a transform with a negative
/// determinant reverses whatever is drawn under it.
void main() {
  /// Each recorded call with the transform in force when it was made.
  List<(Invocation, Matrix4)> withTransforms(TestRecordingCanvas canvas) {
    final stack = [Matrix4.identity()];
    final calls = <(Invocation, Matrix4)>[];
    for (final recorded in canvas.invocations) {
      final call = recorded.invocation;
      final arguments = call.positionalArguments;
      double argument(int index) => (arguments[index] as num).toDouble();
      switch (call.memberName) {
        case #save || #saveLayer:
          stack.add(stack.last.clone());
        case #restore:
          stack.removeLast();
        case #translate:
          stack.last.translateByDouble(argument(0), argument(1), 0, 1);
        case #scale:
          final sx = argument(0);
          final sy =
              arguments.length > 1 && arguments[1] != null ? argument(1) : sx;
          stack.last.scaleByDouble(sx, sy, 1, 1);
        case #rotate:
          stack.last.rotateZ(argument(0));
        case #transform:
          stack.last
              .multiply(Matrix4.fromFloat64List(arguments[0] as Float64List));
      }
      calls.add((call, stack.last.clone()));
    }
    return calls;
  }

  bool reflects(Matrix4 transform) =>
      transform.entry(0, 0) * transform.entry(1, 1) -
          transform.entry(0, 1) * transform.entry(1, 0) <
      0;

  /// Where [local] is drawn on the screen under [transform].
  Offset onScreen(Matrix4 transform, Offset local) {
    final point = transform.transformed3(Vector3(local.dx, local.dy, 0));
    return Offset(point.x, point.y);
  }

  Future<GameManager> leftHandedGame(WidgetTester tester) async {
    final manager = GameManager()..startGame();
    addTearDown(manager.dispose);
    await manager
        .updateSettings((current) => current.copyWith(leftHanded: true));
    await tester.pumpWidget(ChangeNotifierProvider<GameManager>.value(
      value: manager,
      child: const MaterialApp(home: Scaffold(body: PachinkoBoard())),
    ));
    await tester.pump(const Duration(milliseconds: 50));
    return manager;
  }

  CustomPainter boardPainter(WidgetTester tester) => tester
      .widget<CustomPaint>(find.descendant(
          of: find.byType(PachinkoBoard), matching: find.byType(CustomPaint)))
      .painter!;

  /// The board painted now, at its own size, call by call.
  List<(Invocation, Matrix4)> paintBoard(WidgetTester tester) {
    final canvas = TestRecordingCanvas();
    boardPainter(tester).paint(canvas, const Size(400, 600));
    return withTransforms(canvas);
  }

  group('the drawing', () {
    testWidgets(
        'the launch channel, the plunger and the resting ball are on the left',
        (tester) async {
      final manager = await leftHandedGame(tester);
      final calls = paintBoard(tester);

      final restingBall = calls.where((call) =>
          call.$1.memberName == #drawCircle &&
          call.$1.positionalArguments[0] ==
              Offset(manager.gameState.currentLevel!.launchX,
                  manager.gameState.currentLevel!.launchY));
      expect(restingBall, isNotEmpty);
      final drawnAt = onScreen(restingBall.first.$2,
          restingBall.first.$1.positionalArguments[0] as Offset);
      expect(drawnAt.dx,
          closeTo(GameConstants.boardWidth - GameConstants.ballLaunchX, 0.01));
      expect(drawnAt.dx, lessThan(GameConstants.boardWidth / 2));
    });

    testWidgets(
        'no text is drawn reversed: a slot count and value, a popup, the bonus and the launch power',
        (tester) async {
      final manager = await leftHandedGame(tester);
      final state = manager.gameState;
      final slot = state.currentLevel!.slots[1];
      slot.addBall();
      state.lightSlot(slot);
      state.addFloatingText('+200', const Offset(120, 400), slot.color);
      state.triggerSpecialBonus();
      manager.startLaunchCharging();
      manager.updateLaunchPower(60);
      await tester.pump();

      final texts = paintBoard(tester)
          .where((call) => call.$1.memberName == #drawParagraph)
          .toList();

      // The hint is left out while charging; the count, the lit slot's
      // value, the popup, the two words of the bonus and the percentage
      expect(texts.length, greaterThanOrEqualTo(6));
      expect(texts.where((call) => reflects(call.$2)), isEmpty);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('the launch hint reads the right way round, under the plunger',
        (tester) async {
      await leftHandedGame(tester);

      final hint = paintBoard(tester).where((call) =>
          call.$1.memberName == #drawParagraph &&
          (call.$1.positionalArguments[1] as Offset).dy ==
              GameConstants.launchChannelStartY + 25);

      expect(hint, hasLength(1));
      expect(reflects(hint.single.$2), isFalse);
      expect(
          onScreen(hint.single.$2,
                  hint.single.$1.positionalArguments[1] as Offset)
              .dx,
          lessThan(GameConstants.boardWidth / 2));
    });

    testWidgets('every ball and prize peg is still lit from the upper left',
        (tester) async {
      final manager = await leftHandedGame(tester);
      final ball = Ball(position: Vector2(150, 300));
      manager.gameState.launchBall(ball);

      final calls = paintBoard(tester);
      final centres = [
        Offset(ball.position.x, ball.position.y),
        for (final prize in manager.gameState.currentLevel!.specialPegs)
          Offset(prize.position.x, prize.position.y),
      ];
      for (final centre in centres) {
        // The shaded passes of the sphere; a prize peg's rings are plain
        // circles, the same either way round
        final sphere = calls.where((call) =>
            call.$1.memberName == #drawCircle &&
            call.$1.positionalArguments[0] == centre &&
            (call.$1.positionalArguments[2] as Paint).shader != null);
        expect(sphere, isNotEmpty, reason: '$centre');
        expect(sphere.where((call) => reflects(call.$2)), isEmpty,
            reason: '$centre');
      }
      manager.stopLoop();
    });

    testWidgets(
        'every tulip, windmill hub and gate pivot is still lit from the upper left',
        (tester) async {
      final manager = await leftHandedGame(tester);
      // Level 30 has all three kinds of feature (#114)
      manager.startGame(level: 30);
      await tester.pump();
      final features = manager.gameState.currentLevel!.features;
      expect(features, hasLength(4));

      final calls = paintBoard(tester);
      for (final feature in features) {
        final centre = Offset(feature.centre.x, feature.centre.y);
        final sphere = calls.where((call) =>
            call.$1.memberName == #drawCircle &&
            call.$1.positionalArguments[0] == centre &&
            (call.$1.positionalArguments[2] as Paint).shader != null);
        expect(sphere, isNotEmpty, reason: '${feature.runtimeType}');
        expect(sphere.where((call) => reflects(call.$2)), isEmpty,
            reason: '${feature.runtimeType}');
      }
      manager.stopLoop();
    });

    test(
        'the static layer: the level sign and slot values read the right way round, and the pins are lit from the upper left',
        () {
      final level = Level.generate(7, 400, 600);
      final canvas = TestRecordingCanvas();
      mirrorBoard(canvas);

      paintBoardStaticLayer(canvas, level, mirrored: true);

      final calls = withTransforms(canvas);
      final texts = calls.where((call) => call.$1.memberName == #drawParagraph);
      expect(texts, hasLength(1 + level.slots.length));
      expect(texts.where((call) => reflects(call.$2)), isEmpty);
      for (final pin in level.pegs.where((peg) => peg.type == PegType.normal)) {
        final centre = Offset(pin.position.x, pin.position.y);
        final drawn = calls.where((call) =>
            call.$1.memberName == #drawCircle &&
            call.$1.positionalArguments[0] == centre);
        expect(drawn, isNotEmpty);
        expect(drawn.where((call) => reflects(call.$2)), isEmpty);
      }
    });

    test('the static layer is recorded again when the side changes', () {
      final level = Level.generate(1, 400, 600);
      final layer = BoardStaticLayer();
      addTearDown(layer.dispose);
      final builds = BoardStaticLayer.debugBuildCount;

      final right = layer.pictureFor(level);
      expect(layer.pictureFor(level), same(right));
      layer.pictureFor(level, mirrored: true);

      expect(BoardStaticLayer.debugBuildCount - builds, 2);
    });

    test(
        'every peg is drawn a ball\'s gap from the walls and the dome as they are drawn',
        () {
      // The reflection is the same for the pegs and the walls, so the gaps of
      // the right-handed board (level_test) are the gaps on screen
      double left(double x) => boardXOnScreen(x, mirrored: true);
      final rightWallOnScreen = left(GameConstants.fieldLeftBoundaryX);
      final leftWallOnScreen = left(GameConstants.fieldRightBoundaryX);
      for (int n = 1; n <= 100; n++) {
        for (final peg in Level.generate(n, 400, 600).pegs) {
          final x = left(peg.position.x);
          expect(x - peg.radius - leftWallOnScreen,
              greaterThanOrEqualTo(GameConstants.minPegGap),
              reason: 'level $n');
          expect(rightWallOnScreen - x - peg.radius,
              greaterThanOrEqualTo(GameConstants.minPegGap),
              reason: 'level $n');
        }
      }
    });
  });

  group('the touch', () {
    /// Where the plunger is on the screen, the board drawn at its own size.
    Offset plungerOnScreen({required bool mirrored}) => Offset(
        boardXOnScreen(GameConstants.ballLaunchX, mirrored: mirrored),
        GameConstants.launchChannelStartY);

    testWidgets('a drag on the plunger at the left charges the launcher',
        (tester) async {
      tester.view.physicalSize = const Size(400, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final manager = await leftHandedGame(tester);

      final drag = await tester.startGesture(plungerOnScreen(mirrored: true));
      await drag.moveBy(const Offset(0, 30));
      await drag.moveBy(const Offset(0, 30));
      await tester.pump();
      expect(manager.ballLauncher.phase, LaunchPhase.charging);
      await drag.up();
      await tester.pump();
      expect(manager.gameState.activeBalls, hasLength(1));
      manager.stopLoop();
    });

    testWidgets('a drag where the plunger is on a right-handed board does not',
        (tester) async {
      tester.view.physicalSize = const Size(400, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final manager = await leftHandedGame(tester);

      await tester.dragFrom(
          plungerOnScreen(mirrored: false), const Offset(0, 60));
      await tester.pump();

      expect(manager.gameState.activeBalls, isEmpty);
      expect(manager.ballLauncher.phase, LaunchPhase.ready);
    });
  });

  group('the first-round hints', () {
    /// [hint] laid over a board drawn at its own size.
    Future<void> showOnBoard(WidgetTester tester, Widget hint) =>
        tester.pumpWidget(MaterialApp(
            home: Scaffold(
                body: SizedBox(
                    width: 400, height: 600, child: Stack(children: [hint])))));

    testWidgets('the ghost hand is a left hand on the plunger at the left',
        (tester) async {
      await showOnBoard(tester, const GhostHand(scale: 1, mirrored: true));

      final hand = tester.getRect(find.byIcon(Icons.touch_app));
      const plungerX = GameConstants.boardWidth - GameConstants.ballLaunchX;
      // The fingertip is 0.42 of the way across a right hand, from its left
      expect(hand.right - hand.width * 0.42, closeTo(plungerX, 0.5));
      expect(
          tester
              .widget<Transform>(find
                  .ancestor(
                      of: find.byIcon(Icons.touch_app),
                      matching: find.byType(Transform))
                  .first)
              .transform
              .entry(0, 0),
          -1,
          reason: 'reflected: a left hand');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets(
        'the prize peg callout is where it is on a right-handed board, reflected',
        (tester) async {
      Future<double> calloutCentreX({required bool mirrored}) async {
        await showOnBoard(
            tester,
            PrizePegCallout(
                key: UniqueKey(),
                scale: 1,
                mirrored: mirrored,
                prizePegs: 3,
                onFinished: () {}));
        return tester.getCenter(find.text(GameStrings.prizePegHint(3))).dx;
      }

      final right = await calloutCentreX(mirrored: false);
      final left = await calloutCentreX(mirrored: true);

      expect(left, closeTo(GameConstants.boardWidth - right, 0.5));
      expect(left, lessThan(right));
      await tester.pump(PrizePegCallout.duration);
    });

    testWidgets('the hints layer passes the side on from the settings',
        (tester) async {
      // A fresh install, so the ghost hand is due
      SharedPreferences.setMockInitialValues({});
      final manager = GameManager(
          storageService:
              StorageService(prefs: await SharedPreferences.getInstance()));
      addTearDown(manager.dispose);
      await manager
          .updateSettings((current) => current.copyWith(leftHanded: true));
      await tester.pumpWidget(ChangeNotifierProvider<GameManager>.value(
        value: manager,
        child: const MaterialApp(
            home: Stack(children: [FirstRoundHints(scale: 1)])),
      ));

      expect(tester.widget<GhostHand>(find.byType(GhostHand)).mirrored, isTrue);
      await tester.pumpWidget(const SizedBox());
    });
  });

  testWidgets('the left-handed board matches its golden', (tester) async {
    final manager = await leftHandedGame(tester);
    manager.gameState.launchBall(Ball(position: Vector2(150, 300)));
    await tester.pump(const Duration(milliseconds: 250));

    await expectLater(find.byType(PachinkoBoard),
        matchesGoldenFile('goldens/pachinko_board_left_handed.png'));
    manager.stopLoop();
  }, tags: ['golden']);

  test('a new install has the launcher on the right', () {
    expect(const GameSettings().leftHanded, isFalse);
  });
}
