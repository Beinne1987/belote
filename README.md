# Belote — Desktop build (Windows + macOS)

A trimmed mirror of the Belote Flutter client, used **only** to build the
desktop binaries on GitHub-hosted Windows and macOS runners (Flutter refuses
`build windows`/`build macos` on Linux).

- `app/` — the Flutter client (same `lib/` that builds the Android app).
- `packages/belote_engine/` — the Dart rules engine (`path` dependency of `app`).
- `.github/workflows/` — Windows and macOS release workflows. Each builds a
  release binary and uploads it as an artifact (`belote-windows.zip`,
  `belote-macos.dmg`).

Android/iOS folders and all signing material are intentionally excluded — this
repo is public and builds desktop targets only. The engine is mirrored from the
canonical source at `/var/www/belote`; edit rules there, not here.
