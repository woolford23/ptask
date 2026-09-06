# Copilot / Agent Instructions for pTask

Purpose: Quickly orient AI coding agents so they can make safe, focused changes in this Flutter app.

**Big picture:** pTask is a local-first Flutter scheduler. Core responsibilities:
- persistence: `lib/database/database_helper.dart` (sqflite, tables: `tasks`, `blocking_periods`, `preferences`)
- scheduling logic: `lib/services/scheduling_service.dart` (priority-first, 5-minute slots, buffer handling)
- data models: `lib/models/*` (`task.dart`, `blocking_period.dart`, `preferences.dart`)
- UI & flows: `lib/screens/*` (examples: `add_task_view.dart` triggers scheduling after insert)

**Key patterns & conventions** (follow these precisely):
- DB is a singleton: use `DatabaseHelper.instance` for reads/writes.
- Time fields are stored as ISO strings (use `toIso8601String()` / `DateTime.parse`). Times are expected to be local DateTime values unless noted.
- Priority: integer 1–9 (9 = highest). Do NOT change this scale without a project-wide update.
- Durations are minutes (integer). Scheduling uses 5-minute slot granularity.
- Task statuses used in code: `unscheduled`, `scheduled`, `complete`, `missed` (strings).
- Preferences is a single-row table (primary key `id`); `getPreferences()` inserts defaults on DB create.

**Scheduling specifics (important for algorithm/code edits):**
- Scheduling merges already-scheduled tasks with unscheduled ones and sorts by: locked start time → priority → createdAt.
- Locked start times are honored if they fall on the target date; if they cannot fit, they become conflicts and remain unscheduled.
- Buffer between tasks is driven by `Preferences.addBufferBetweenTasks` (1 slot = 5 minutes).
- Overflow handling options in `SchedulingService.handleOverflow`: `push_next_day`, `unscheduled_section`, `prompt`.

**Useful files to inspect / change**
- `lib/database/database_helper.dart` — schema, CRUD, test helpers (`deleteDatabase()`), DB `version` lives in `_initDB`.
- `lib/services/scheduling_service.dart` — scheduling algorithm, `TimeSlot` model, and `ScheduleResult`.
- `lib/screens/add_task_view.dart` — task creation flow and when scheduling is triggered.
- `lib/models/task.dart` — canonical `Task` fields and `toMap()/fromMap()` shapes; quick reference for field names.
- `pubspec.yaml` — external deps (notably `sqflite`, `intl`).

**Developer workflows & commands**
- Install deps: `flutter pub get` (run this first to ensure analyzer and tests work)
- Static analysis: `flutter analyze`
- Run tests: `flutter test`
- Run app locally: `flutter run` (example for Windows desktop: `flutter run -d windows`)
- Build APK (Android): `flutter build apk`

**Testing & debugging tips**
- Reset local DB during dev/tests (debug-only):

  ```dart
  // test or debug helper
  await DatabaseHelper.instance.deleteDatabase();
  ```

- Force-run scheduling for a given date (dev/testing):

  ```dart
  final svc = SchedulingService();
  await svc.scheduleTasks(DateTime.now());
  ```

- When changing DB schema: do NOT bump the DB `version` in `_initDB` without a migration strategy and tests. If you must change schema, add migration logic and document reset steps.

**What agents must not do without human review**
- Auto-migrate the DB to a new schema without a migration strategy, tests, and maintainer approval.
- Change canonical status values (`unscheduled`, `scheduled`, `complete`, `missed`) or the priority scale (1–9) without an explicit, repo-wide code update.

**Pull request checklist for agents**
- Run `flutter pub get`, then `flutter analyze` and `flutter test` locally before submitting changes.
- If altering persistence, include migration notes or instructions to reset the DB in the PR description.
- Reference modified files in the PR description and include a short note about behavioral changes (scheduling, DB shape, preferences, or timezone assumptions).

If anything here is unclear or you want additional examples (unit tests, migration patterns, or UI flows), tell me which area to expand.
