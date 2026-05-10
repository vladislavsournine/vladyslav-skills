# Stack: Flutter

This fragment is composed into the `init-project` subagent prompt when the user selects Flutter as a frontend/mobile stack.

## Directories

Create:

```
flutter/
```

The actual Flutter app skeleton (lib/, test/, pubspec.yaml, …) is **not** scaffolded by `init-project`. The user is expected to run `flutter create .` inside `flutter/` themselves once they want to start the app — this avoids carrying a Flutter SDK dependency in the plugin and keeps the chosen Flutter version under the user's control.

Leave a `flutter/.gitkeep` so the empty directory is committed.

## .gitignore additions

Append to `.gitignore`:

```
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
*.iml
.metadata
```

## Files

None at this stage. The user runs `flutter create .` after `init-project` finishes.
