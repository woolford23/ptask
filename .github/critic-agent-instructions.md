# Critic Agent Instructions — pTask

Purpose: Guide an automated “critic” agent that reviews and scores `copilot-instructions.md` for correctness, completeness, and project alignment.

Primary goals:
- Verify factual accuracy vs. source files (`lib/database/database_helper.dart`, `lib/services/scheduling_service.dart`, `lib/screens/add_task_view.dart`, `lib/models/*`).
- Surface missing or risky recommendations (DB migrations, status/value changes, CI/test commands).
- Produce a concise checklist and line-level suggested edits (short patch-style recommendations).

Review steps (do these in order):
1. Parse the instructions file and identify claims about files, DB schema, preferences, and workflows.
2. Open the referenced source files and confirm each claim (example: `Preferences` single-row, `tasks` table columns, `SchedulingService.scheduleTasks` behavior).
3. Validate commands: ensure `flutter pub get`, `flutter analyze`, `flutter test`, `flutter run` are present and accurate; add `flutter run -d windows` as platform example when applicable.
4. Check for missing safety constraints: e.g., avoid auto DB migrations, do not change task status strings or priority scale, require migration strategy when bumping DB version.
5. Look for missing developer conveniences: examples for resetting DB (`DatabaseHelper.instance.deleteDatabase()`), how to force-run scheduling, and where models live.
6. Produce a prioritized list: (A) factual errors, (B) missing-critical-safety, (C) suggested clarifications or examples.

Output format (plain text + small patch suggestions):
- Short summary (1–2 lines).
- Checklist with pass/fail for each key claim (map claim → file/line evidence).
- Actionable edits: for each suggestion, provide a 1–3 line rationale and a proposed replacement or addition (show exact text to insert/replace).

Examples of checks to include:
- Confirm DB `version` value and presence of `_initDB`/`_createDB` in `database_helper.dart`.
- Confirm scheduling uses 5-minute slots and priority sorting (locked first → priority → createdAt).
- Confirm `preferences` table is single-row and default preferences are inserted on create.

Hard stops (do not suggest or perform these):
- Auto-applying DB migrations without human review and tests.
- Changing canonical status values (`'unscheduled'`, `'scheduled'`, `'complete'`, `'missed'`) or priority scale.

Deliverables:
- A short critique report (see `.github/critic-report.md`) with checklist and suggested edits.
- Optional patch snippets for small text fixes to `copilot-instructions.md`.

If any claim cannot be verified (file missing or ambiguous), mark it as *needs human review* and explain what's missing.
