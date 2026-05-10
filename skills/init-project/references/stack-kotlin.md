# Stack: Kotlin (Android)

This fragment is composed into the `init-project` subagent prompt when the user selects Kotlin as a frontend/mobile stack.

## Directories

Create:

```
kotlin/
```

The Android app skeleton (settings.gradle.kts, app/, build.gradle.kts, …) is **not** scaffolded by `init-project`. Android Studio's "New Project" wizard or `gradle init` is the canonical way to start an Android project — `init-project` only reserves the directory and `.gitignore` slot.

Leave a `kotlin/.gitkeep` so the empty directory is committed.

## .gitignore additions

Append to `.gitignore`:

```
.gradle/
out/
build/
local.properties
*.iml
```

## Files

None at this stage. The user starts the Android project under `kotlin/` using their preferred tool.
