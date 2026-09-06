# Running the App Locally

Prerequisites: Flutter SDK installed and configured for your target platform.

Common commands (run from repository root):

1) Install dependencies

```bash
flutter pub get
```

2) Static analysis

```bash
flutter analyze
```

3) Run tests

```bash
flutter test
```

4) Run the app on Windows desktop

```bash
flutter run -d windows
```

5) Build Android APK

```bash
flutter build apk
```

Notes for reviewers:
- To reset the app database during development, use the helper in `lib/database/database_helper.dart` by calling `await DatabaseHelper.instance.deleteDatabase()` from a debug helper or test setup. Do NOT call this in production environments.
- The repository includes added documentation under `.github/` that documents agent workflows and suggested next steps for upgrades or migrations.

PowerShell execution policy (Windows)

On Windows the VS Code terminal or test runners may be blocked by PowerShell execution policy when running scripts. To allow running local development scripts without requiring admin changes, you can set the user-scope policy to `RemoteSigned` (affects only your account):

```powershell
if ((Get-ExecutionPolicy -Scope LocalMachine) -eq 'Undefined' -and (Get-ExecutionPolicy -Scope CurrentUser) -eq 'Undefined') {
	Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
}
```

Notes:
- `RemoteSigned` allows local unsigned scripts and requires signatures for downloaded (remote) scripts.
- This change is non-admin and only affects the current user. To avoid persistence, set it for the session only:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned
```

- Inspect current policies first with:

```powershell
Get-ExecutionPolicy -List
```

- Revert the persistent user change later with:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Restricted
```
