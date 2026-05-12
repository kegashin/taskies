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
- Xcode 15 or newer, not only Command Line Tools.

If `xcodebuild` reports that the active developer directory is Command Line
Tools, point it at the full Xcode app:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

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

Run tests:

```bash
bash scripts/test.sh
```

Regenerate app icons from `Taskies/Resources/AppIcon.svg`:

```bash
bash scripts/generate-app-icons.sh
```

Release build:

```bash
bash scripts/build-release.sh
```

Package a local DMG:

```bash
bash scripts/package-dmg.sh
```

Notarize a signed DMG:

```bash
bash scripts/notarize-dmg.sh
```

GitHub Release notarization needs these repository secrets:

- `DEVELOPER_ID_APPLICATION_CERTIFICATE_BASE64`
- `DEVELOPER_ID_APPLICATION_CERTIFICATE_PASSWORD`
- `DEVELOPER_ID_APPLICATION`
- `APPLE_ID`
- `APPLE_TEAM_ID`
- `APPLE_APP_PASSWORD`

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
- Confirm `xcode-select -p` points at `/Applications/Xcode.app/Contents/Developer`.
- Run `bash scripts/test.sh`.
- Run a local Debug build.
- Run `bash scripts/build-release.sh` and `bash scripts/package-dmg.sh`.
- Test downloaded DMGs from Applications with Gatekeeper enabled.
- Verify https://taskies.kegashin.me loads a non-empty project page.
- Push a version tag like `v0.1.0`.
- Download the DMG from GitHub Releases and test it from Applications.

Before a stable public release outside the Mac App Store, Taskies should use
Developer ID signing and Apple notarization.

Manual QA matrix:

- Notes: create, edit title, edit tasks, complete tasks, archive done tasks.
- Data: delete notes, quit and reopen, restore hidden and collapsed notes.
- Files: import text, export one note, export all notes, print dialog opens.
- Window states: collapse, float on top, translucency, color changes, resize.
- Displays: reopen on one monitor and with a previous external monitor missing.

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
