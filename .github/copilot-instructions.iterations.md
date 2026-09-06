# Critic Loop — 15 Iterations Log

This file documents 15 quick critique+fix iterations applied to `.github/copilot-instructions.md`.

1) Iteration 1 — Add explicit DB migration caution. (Added sentence: require migration plan & tests before bumping DB version.)
2) Iteration 2 — Add `flutter run -d windows` as a platform example. (Developer workflows section)
3) Iteration 3 — Add programmatic DB reset snippet. (Testing & debugging tips)
4) Iteration 4 — Add scheduling force-run snippet. (Testing & debugging tips)
5) Iteration 5 — Clarify `preferences` is single-row and `id` usage. (Key patterns)
6) Iteration 6 — Recommend linking `lib/models/task.dart` for model shape reference.
7) Iteration 7 — Emphasize ISO time storage and local-time expectations.
8) Iteration 8 — Add a short note about priority scale being 1–9 (already present) and not to change it.
9) Iteration 9 — Add a short example of how locked tasks are handled by the scheduler.
10) Iteration 10 — Add explicit mention of 5-minute slot granularity (already present but reinforced).
11) Iteration 11 — Add PR checklist item to reference modified files and behavioral note.
12) Iteration 12 — Tighten wording and remove ambiguity around `deleteDatabase()` use in production.
13) Iteration 13 — Add note to run `flutter pub get` before `flutter analyze` and `flutter test` to avoid analyzer errors.
14) Iteration 14 — Minor wording polish for brevity and clarity.
15) Iteration 15 — Final pass: consolidate changes and ensure nothing conflicts with source code; produce final updated `copilot-instructions.md`.

All iterations were applied as small, non-breaking documentation edits. If you want a different focus for the critic loop (more code edits, tests, or examples), tell me which iterations to re-run with code changes.
