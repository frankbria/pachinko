# Lessons

Patterns learned the hard way on this repo. Add an entry after any correction.

## 2026-10-10 — PR #8 (issue #1, verification baseline)

- **Regenerate mocks whenever a mocked class's public API changes.** The suite went from green to 84 failures because `GameState` gained members and the committed `*.mocks.dart` files were not regenerated; generated mocks throw on unknown members. Run `dart run build_runner build --delete-conflicting-outputs` and commit the result in the same pull request.
- **Run the whole suite, not just the tests for the file you touched.** The breakage went unnoticed for months because only targeted test files were run after each feature.
- **`flutter_test`'s `group()` has no `tags` parameter; `testWidgets()` does.** Tag individual tests. A plan written without a toolchain got this wrong.
- **A plan that was never executed against a real toolchain is a prediction.** The plan for issue #1 was written by reading code only. It was right about the cause and wrong about one API detail. Measure before trusting it.
- **Untracking a file with `git rm --cached` deletes it from every other checkout on the next pull.** For a file people need locally (for example `.claude/settings.local.json`), say so in the pull request and give the restore command.
- **Goldens that render time-dependent state cannot gate CI.** Special-peg shimmer reads `DateTime.now()` during paint, so two golden tests fail on every run. Inject a clock before relying on them.

## 2026-10-11 — PR #12 (issue #2, achievement toasts)

- **Reproduce every defect a plan lists before fixing it.** The plan for issue #2 named four defects. Three were real. The fourth (`_dismiss` calling `onDismissed` twice) did not reproduce: a second `AnimationController.reverse()` cancels the first one's future, which then never completes. A probe test that counted callbacks settled it in a minute.
- **Do not match short numeric text with `find.textContaining`.** `find.textContaining('1/2')` also matched the unlock date `10/11/2026`, so the test failed only on some calendar dates and only in CI's time zone. Use `find.text` for an exact label. To reproduce a date-dependent CI failure locally, run the test with `TZ=UTC`.
- **Never run `rm` with a wildcard, even in a git-ignored scratch directory.** Write to new file names, or delete files by explicit name. (Correction from Frank during this run.)
- **Bare `flutter analyze` is unusable locally.** It also analyzes the SDK checkout in `tools/flutter` and reports about 11,500 issues. Run `flutter analyze --no-fatal-infos --no-fatal-warnings lib test` until issue #10 adds an exclude.
- **A reviewer told "do not modify tracked files" may still run a code generator.** The cross-family reviewer ran `build_runner`, which rewrote the committed mocks; it restored them, but only by regenerating. Name `build_runner`, formatters and fixers explicitly in the review prompt, and check `git status` after every review.
- **The app can be demoed without a desktop toolchain.** This machine cannot build the Linux target. `flutter build web --no-tree-shake-icons`, serve `build/web` on localhost, and drive it with `agent-browser mouse move/down/up` by coordinates (Flutter web paints to a canvas, so there are no elements to click). Saved state lives in the browser's `localStorage` under `flutter.achievements` and can be seeded to set up a scenario.

## 2026-10-11 — PR #17 (issue #3, bonus ball spawn)

- **Simulate a gameplay change across many levels, not only the one in the plan.** The plan's tests check where bonus balls appear. Stepping the real `PhysicsEngine` over levels 1–30 showed something neither the plan nor the tests could: balls come to rest between pegs (2.4% of launched balls, 23% on level 5), and bonus balls now meet that bug because they finally touch pegs. Filed as #16. Ask what a fix newly exposes, not only whether it does what the issue says.
- **A probe test does not have to live in the repo.** From the package directory, `flutter test /absolute/path/probe_test.dart` resolves `package:pachinko_game/...` imports. Keep probes in a scratch directory: the tree stays clean, the full suite does not pick them up, and the same file runs against `master` in the main checkout for a before-and-after.
- **A state that cannot be reached by playing can still be shown.** Pump the real `PachinkoBoard` in a throwaway widget test, set up the state through `GameState`, and write a PNG with `matchesGoldenFile('<absolute path>')` under `--update-goldens`. Text is drawn as blocks by the test font; shapes and colours are real.
- **`flutter test` needs `-r failures-only` or `-r expanded` when its output is piped.** The default reporter rewrites one line with carriage returns, so `grep` returns the whole run as a single line.
- **`command | tail; echo $?` reports `tail`'s exit code.** Redirect the output to a file and read `$?` straight after the command when the exit code is the thing being checked.

## 2026-10-11 — PR #19 (issue #4, restart resets launcher)

- **Compile a plan's test code before trusting it.** The plan's two `GameState` tests used `Colors.white`, which is ambiguous in any file that imports both `flutter/material.dart` and `vector_math_64.dart` (both export `Colors`). Use `const Color(0xFF...)` there, as the rest of `game_state_test.dart` does. A compile error in one test file also hides that file's other tests from the RED run, so read the load errors before counting failures.
- **Target mutations by line number, not by "the nth occurrence of this text".** Deleting the first `_ballCountHighlighted = false;` removed the field declaration (a compile error that looks like a killed mutant), and the third `_ballLauncher.reset();` was the pre-existing one in `_updatePhysics`. Run `grep -n` first and confirm each mutation lands on a line the branch added.
- **Ask what a fix un-hides.** Resetting the launcher on `selectLevel`/`nextLevel` turned a soft-lock into a ball that carries over into the new level, because `loadLevel()` never cleared balls in play. A real-object probe run on the branch and on `master` showed both behaviours. Filed as #20.
- **The game screen's buttons move while a ball is in play.** At a 420x800 viewport the bottom row is Back (138) and Restart (281) when ready, and Back (102), Pause (210), Restart (317) while playing, all at y=764. The launcher is at (377, 590) and Play on the menu at (210, 304). A tap aimed at the ready-state Restart lands between two buttons during play.
- **Do a warm-up launch before a demo that reads the ball counter.** The first launch on a fresh origin unlocks "First Launch", and its toast covers the header for 3.5 seconds (issue #13). Each port is its own origin, so a second build served on another port starts with empty `localStorage`.
- **`pkill -f <pattern>` kills the shell that runs it when the pattern appears in that shell's own command line.** It took out the rest of a compound command and left one of two servers running. Find the pid with `ss -ltnp` and `kill` it.
- **A stale `.git/index.lock` in the main checkout can outlive a cross-family review.** The reviewer worked in its own copy under `/tmp/opencode` and left the worktree clean, but an empty lock dated inside its run blocked the post-merge `git pull`. Check `pgrep -x git` and the lock's mtime, then remove that one file.
- **Search for a method's callers by bare name, not with parentheses.** `grep "nextLevel()"` found no UI caller, and issue #20 and PR #19 said so. The Next Level button uses a tear-off, `onPressed: gameManager.nextLevel`, which has no parentheses. Both texts were corrected on 2026-10-10. (Correction found during the graphics review, #22.)
- **When an issue limits which files may change, documentation goes in the follow-up docs pull request.** The new rule for `CLAUDE.md` (transitions reset the launcher, effects are cleared in `_clearEffects()`) was held back from PR #19 and lands with these lessons, as in #15 and #18.

## 2026-10-10 — graphics review (issue #22)

- **Take a mock-up's geometry from the painter, not from a similarly named constant.** The neon parlor mock-up drew the launch channel's inner wall up to `launchChannelEndY` (110). The painter stops that wall at y = 135, and Frank rejected the mock-up because the mouth under the dome looked too narrow for a ball. Read the `draw*` method before drawing anything it draws. (Correction from Frank.)
- **Take a layout percentage from the pixels, and say what it measures.** Issue #22 first said the board uses about 57% of the screen height. Scanning one column of the screenshot for colour changes gave 68% for the board panel; 57% was the span from the dome to the top of the slots. The pegs span 24%. Name both ends of any measurement in the text.

## 2026-10-10 — PR #34 (issue #25, colour roles and the Oxanium font)

- **`FontWeight` does not drive a variable font's weight axis.** A probe test measured the same text width at w400 and w800 with the variable Oxanium file, and a different one only with `FontVariation('wght', 800)`. Existing code sets weight with `fontWeight:`, so the fix was to ship static instances: `uvx --from fonttools fonttools varLib.instancer <font> wght=700 --update-name-table`, declared with `weight: 700` in `pubspec.yaml`. Check the licence for a reserved font name before renaming or instancing a font.
- **Do not edit the working tree while a cross-family review is running.** The reviewer gets the diff inline but also reads the files, and it reported fixes made during its run as "stranded uncommitted". Commit first, or hold the edits until it finishes. Run mutation checks in a separate detached worktree (`git worktree add --detach`) for the same reason.
- **Make a mutation script match exact text and assert it occurs once.** A script that takes (file, exact text, replacement, test file) for each mutation, restores the file in a `finally`, and prints the survivors ran twelve mutations unattended with no wrong-line hits.
- **A wider font moves everything below it.** Under Oxanium the menu title wrapped to two lines and the Play button moved 93 px, so a scripted tap missed and two screenshots came out identical. Compare file sizes or look at the first capture before trusting a scripted sequence.
- **Wait about 20 seconds after `adb install` before the first screenshot.** Eight seconds caught the splash screen.
- **`gh` cannot attach an image to a pull request.** Screenshots go on the `pr-assets` branch, which holds no code, and the description links them by raw URL. The branch can be deleted once the pull requests that use it are merged.
- **Give the exact command with any analyzer count.** The description said "96 issues, down from 98"; the reviewer ran a different invocation and counted 107. The local command is `flutter analyze --no-fatal-infos --no-fatal-warnings lib test`.
- **Check that an acceptance criterion belongs to the slice before filing it.** Issue #25 first asked for the screens' literal text sizes to move onto the type scale, which is #32's work. It was corrected before implementation started.

## 2026-10-11 — PR #36 (issue #5, per-level score accounting)

- **A level past the first may not be finishable on a device.** Three attempts at level 2 on the emulator each ended with a ball at rest on a peg (#16). Show what happens at the end of a level with a probe test through the real services instead: `SharedPreferences.setMockInitialValues({})`, a real `StorageService`, `AchievementService.create(prefs)` and a real `GameManager`. Spend each ball with `gameState.launchBall(ball)` then `removeBall(ball)` and wait 40 ms for a loop tick; call `manager.resumeGame()` after `nextLevel()` to restart the loop. Run the same file from the main checkout for the behaviour on `master`.
- **Do not detect a stopped ball by comparing two screenshots.** Prize pegs shimmer, so the frames always differ. Time how long the Pause button stays on screen; a ball in play for more than 30 seconds has stopped.
- **Launch power is the length of the drag.** With `adb shell input swipe`, 70 to 120 px is a weak launch and 300 px or more is full power. Different powers reach different pegs, so vary it when one launch keeps ending in the same place.
- **Borrow a generated mock from another test's mocks file.** `import '../screens/high_scores_screen_test.mocks.dart' show MockStorageService;` gave `game_manager_test.dart` a storage mock without adding the class to its own `@GenerateMocks` list and regenerating.
- **Update the audit index when an issue closes.** The table in #7 still listed #4 as TODO a day after it merged. Change the row in the same step that files the loose ends.
- **Label an issue `needs-owner` when it waits on a product decision.** The label did not exist until #37 needed it. Issue discovery skips it and reports the issue as gated.
