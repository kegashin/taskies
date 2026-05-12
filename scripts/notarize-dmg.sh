#!/usr/bin/env bash
set -euo pipefail

app_name="${APP_NAME:-Taskies}"
artifact_dir="${ARTIFACT_DIR:-${RUNNER_TEMP:-/tmp}/TaskiesArtifacts}"
dmg_path="${DMG_PATH:-$artifact_dir/$app_name.dmg}"

: "${APPLE_ID:?Set APPLE_ID to the Apple ID used for notarization}"
: "${APPLE_TEAM_ID:?Set APPLE_TEAM_ID to your Apple Developer Team ID}"
: "${APPLE_APP_PASSWORD:?Set APPLE_APP_PASSWORD to an app-specific password}"

if [[ ! -f "$dmg_path" ]]; then
  echo "missing dmg: $dmg_path" >&2
  exit 1
fi

xcrun notarytool submit "$dmg_path" \
  --apple-id "$APPLE_ID" \
  --team-id "$APPLE_TEAM_ID" \
  --password "$APPLE_APP_PASSWORD" \
  --wait

xcrun stapler staple "$dmg_path"
xcrun stapler validate "$dmg_path"
spctl -a -vv --type open "$dmg_path"
