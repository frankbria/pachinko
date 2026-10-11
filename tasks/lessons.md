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
