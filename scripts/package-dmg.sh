#!/usr/bin/env bash
set -euo pipefail

app_name="${APP_NAME:-Taskies}"
configuration="${CONFIGURATION:-Release}"
derived_data="${DERIVED_DATA:-${RUNNER_TEMP:-/tmp}/TaskiesDerivedData}"
artifact_dir="${ARTIFACT_DIR:-${RUNNER_TEMP:-/tmp}/TaskiesArtifacts}"
app_path="${APP_PATH:-$derived_data/Build/Products/$configuration/$app_name.app}"
dmg_path="${DMG_PATH:-$artifact_dir/$app_name.dmg}"

mkdir -p "$artifact_dir"

if [[ ! -d "$app_path" ]]; then
  echo "missing app bundle: $app_path" >&2
  exit 1
fi

rm -f "$dmg_path" "$dmg_path.sha256"

hdiutil create \
  -volname "$app_name" \
  -srcfolder "$app_path" \
  -ov \
  -format UDZO \
  "$dmg_path"

shasum -a 256 "$dmg_path" > "$dmg_path.sha256"

echo "$dmg_path"

