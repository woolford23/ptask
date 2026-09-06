# Worker Agent Instructions — pTask

Purpose: Guide the `Worker` agent to rebuild and verify the app, make small safe fixes, and iterate with the `Critic` until readiness.

Responsibilities:
- Run build and verification steps: `flutter pub get`, `flutter analyze`, `flutter test`, `flutter build` (platform-specific).
- Apply small, non-destructive fixes to code and docs (typos, clearer error messages, additional null-safety guards), but do NOT change DB schema `version` or canonical status values without maintainer approval.
- Add or update unit tests that validate scheduling behavior (5-minute slot granularity, locked-task precedence) when feasible.
- After each change, run analyzer and tests; produce a short change summary and hand off to `Critic` for review.

Constraints and safety:
- NEVER auto-migrate the database or change the `version` in `_initDB` without an explicit migration strategy and tests.
- Do not change the priority scale (1–9) or status strings (`unscheduled`, `scheduled`, `complete`, `missed`).
- Keep changes minimal and focused; prefer documentation or tests over behavior changes unless a bug is clearly safe to fix.

Iteration workflow (repeat per iteration):
1. Pull latest docs and source files (`lib/**`, `test/**`).
2. Run `flutter pub get` then `flutter analyze` and `flutter test`.
3. If analyzer or tests fail, make the smallest possible fix to resolve the issue.
4. Run analyzer/tests again. If green, commit small change and produce a 1-paragraph summary.
5. Send changes and summary to `Critic` for feedback.

Deliverables per iteration:
- Short summary of commands run and outputs (analyzer/test results).
- Files changed (if any) with brief rationale.
- New or updated tests added.

If a change requires broader architectural work (DB migration, scheduling overhaul), STOP and create a detailed plan for maintainer review.
