# Critic Report: review of `.github/copilot-instructions.md`

Summary: The instructions are accurate and actionable; they capture the project's main architecture and developer workflows. A few clarifications and additions will make the guidance safer and more complete.

Findings (priority order):

- [A] Safety / Missing constraints (HIGH)
  - Add an explicit caution about DB `version` changes: require a migration plan and tests before bumping `version` in `_initDB`.
  - Call out that `preferences.id` is primary-key-only (single-row table) and `preferences` insertion on create is relied upon.

- [B] Accuracy / Minor clarifications (MEDIUM)
  - Confirmed: scheduling uses 5-minute slots and sorts by locked → priority → createdAt (see `lib/services/scheduling_service.dart`).
  - Confirmed: `DatabaseHelper.instance.deleteDatabase()` exists for test resets.
  - Suggest adding `flutter run -d windows` as an explicit platform example for local testing on Windows.

- [C] Suggested additions (LOW)
  - Provide a short code snippet for forcing scheduling during dev:

    ```dart
    final svc = SchedulingService();
    await svc.scheduleTasks(DateTime.now());
    ```

  - Add example command to clear the DB in dev/tests (call the provided helper in a small script or test).

Recommended edits (patch-style suggestions):

- Insert under "Developer workflows & commands":

  - `flutter run -d windows` — run on Windows desktop during local testing.

- Insert under "Testing & debugging tips":

  - Example: reset DB programmatically in dev/tests:

    ```dart
    // In a debug-only helper or test setup
    await DatabaseHelper.instance.deleteDatabase();
    ```

Notes for maintainers:
- The instruction to avoid auto DB migrations is correct — keep this as a hard rule for automated agents.
- Consider adding a very short example of the `Task` model fields (or link to `lib/models/task.dart`) so agents can quickly see the shape used by code.

If you want, I can apply these small edits to `.github/copilot-instructions.md` and open a follow-up PR patch. Which of the recommended edits should I add now? 
