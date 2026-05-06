# Taskies

Taskies is a small native macOS app for keeping tasks in sticky notes.

It is inspired by Apple Stickies, but focused on simple todo lists.

Project page: https://taskies.kegashin.me

## Features

- Sticky-note windows for desktop tasks.
- Todo rows with checkboxes and inline editing.
- Collapsible notes with editable titles.
- Done section for completed tasks.
- Classic Stickies-style colors.
- Float on top and translucent window modes.
- Text import and export.
- Local persistence with SwiftData.

## Requirements

- macOS 14 or newer.
- Xcode 15 or newer.

## Download

Download the latest DMG from GitHub Releases:

https://github.com/kegashin/taskies/releases

Open the DMG and drag `Taskies.app` into Applications.

Early GitHub builds are unsigned and not notarized yet. macOS may warn when
opening downloaded builds.

## Build

Open `Taskies.xcodeproj` in Xcode, choose the `Taskies` scheme, and run the app on
`My Mac`.

Command-line build:

```bash
xcodebuild -project Taskies.xcodeproj -scheme Taskies -configuration Debug build
```

Release build:

```bash
bash scripts/build-release.sh
```

Package a local DMG:

```bash
bash scripts/package-dmg.sh
```

## CI

GitHub Actions builds Taskies on every push to `main` and every pull request.
The CI workflow uploads a short-lived unsigned `Taskies.dmg` artifact that can
be downloaded from the workflow run page.

Release tags create a GitHub Release with a downloadable DMG:

```bash
git tag v0.1.0
git push origin v0.1.0
```

The release workflow creates a GitHub Release and uploads:

- `Taskies.dmg`
- `Taskies.dmg.sha256`

## Release Checklist

- Confirm `MARKETING_VERSION` matches the release tag.
- Run a local Debug build.
- Test creating, editing, completing, archiving, and restoring tasks.
- Test note colors, collapse, translucency, float-on-top, import, and export.
- Push a version tag like `v0.1.0`.
- Download the DMG from GitHub Releases and test it from Applications.

Before a stable public release outside the Mac App Store, Taskies should use
Developer ID signing and Apple notarization.

## Project Structure

```text
Taskies.xcodeproj
Taskies/
  App/          App entry point and application commands
  App/Menus/    Custom macOS menu controllers
  Model/        SwiftData models
  Persistence/  Storage and text import/export
  Note/         Sticky note UI and task interactions
  Windowing/    AppKit windows, panels, geometry, and state
  Support/      Shared utilities
  Resources/    Asset catalogs and app resources
```

## Privacy

Taskies stores notes locally on the device. It does not require an account and
does not send task data to a server.

## License

Taskies is licensed under the Apache License 2.0. See `LICENSE`.
