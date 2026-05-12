# Release hardening notes

## Decisions

- SwiftData startup must not crash the app when persistent storage fails to open.
- On storage startup failure, Taskies opens a temporary in-memory store and leaves existing data untouched.
- Destructive recovery, such as deleting a SwiftData store, should stay manual until there is a backup flow.
- Note deletion should delete and save data first, then close the window.
- Public non-App-Store releases need Developer ID signing, hardened runtime, notarization, and stapling.
- XCTest runs with `TASKIES_TESTING=1`, so the app uses an in-memory store and skips window restore.
- App icons are generated from `Taskies/Resources/AppIcon.svg` with `scripts/generate-app-icons.sh`.

## Stable DMG commands

```bash
bash scripts/test.sh

CODE_SIGNING_ALLOWED=YES \
CODE_SIGNING_REQUIRED=YES \
CODE_SIGN_STYLE=Manual \
CODE_SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
DEVELOPMENT_TEAM=TEAMID \
bash scripts/build-release.sh

bash scripts/package-dmg.sh

APPLE_ID=you@example.com \
APPLE_TEAM_ID=TEAMID \
APPLE_APP_PASSWORD=app-specific-password \
bash scripts/notarize-dmg.sh
```

GitHub prerelease builds can stay unsigned until signing secrets are configured.

GitHub stable release signing uses these secrets:

- `DEVELOPER_ID_APPLICATION_CERTIFICATE_BASE64`
- `DEVELOPER_ID_APPLICATION_CERTIFICATE_PASSWORD`
- `DEVELOPER_ID_APPLICATION`
- `APPLE_ID`
- `APPLE_TEAM_ID`
- `APPLE_APP_PASSWORD`

## Local verification notes

- On 2026-05-12, local `xcode-select -p` returned `/Library/Developer/CommandLineTools`, so `xcodebuild test` could not run on this machine until full Xcode is selected.
- On 2026-05-12, `curl -L -I https://taskies.kegashin.me` failed DNS resolution from this environment. Recheck the project page before publishing.

## References

- Apple SwiftData `ModelContainer`: https://developer.apple.com/documentation/swiftdata/modelcontainer
- Apple Developer ID: https://developer.apple.com/developer-id/
- Apple Developer ID support: https://developer.apple.com/support/developer-id/
- Apple hardened runtime: https://developer.apple.com/documentation/xcode/configuring-the-hardened-runtime
- Apple notarization: https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution
- Xcode outside-App-Store distribution: https://help.apple.com/xcode/mac/current/en.lproj/dev033e997ca.html
- GitHub Actions `runner.temp`: https://docs.github.com/actions/learn-github-actions/contexts
