# Lessons

Patterns learned the hard way on this repo. Add an entry after any correction.

## 2026-10-10 — PR #8 (issue #1, verification baseline)

- **Regenerate mocks whenever a mocked class's public API changes.** The suite went from green to 84 failures because `GameState` gained members and the committed `*.mocks.dart` files were not regenerated; generated mocks throw on unknown members. Run `dart run build_runner build --delete-conflicting-outputs` and commit the result in the same pull request.
- **Run the whole suite, not just the tests for the file you touched.** The breakage went unnoticed for months because only targeted test files were run after each feature.
- **`flutter_test`'s `group()` has no `tags` parameter; `testWidgets()` does.** Tag individual tests. A plan written without a toolchain got this wrong.
- **A plan that was never executed against a real toolchain is a prediction.** The plan for issue #1 was written by reading code only. It was right about the cause and wrong about one API detail. Measure before trusting it.
- **Untracking a file with `git rm --cached` deletes it from every other checkout on the next pull.** For a file people need locally (for example `.claude/settings.local.json`), say so in the pull request and give the restore command.
- **Goldens that render time-dependent state cannot gate CI.** Special-peg shimmer reads `DateTime.now()` during paint, so two golden tests fail on every run. Inject a clock before relying on them.
