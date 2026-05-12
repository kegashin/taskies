#!/usr/bin/env bash
set -euo pipefail

project="${PROJECT:-Taskies.xcodeproj}"
scheme="${SCHEME:-Taskies}"
configuration="${CONFIGURATION:-Release}"
derived_data="${DERIVED_DATA:-${RUNNER_TEMP:-/tmp}/TaskiesDerivedData}"
destination="${DESTINATION:-platform=macOS}"
code_signing_allowed="${CODE_SIGNING_ALLOWED:-NO}"
code_signing_required="${CODE_SIGNING_REQUIRED:-NO}"

extra_settings=()
if [[ -n "${CODE_SIGN_STYLE:-}" ]]; then
  extra_settings+=("CODE_SIGN_STYLE=$CODE_SIGN_STYLE")
fi
if [[ -n "${CODE_SIGN_IDENTITY:-}" ]]; then
  extra_settings+=("CODE_SIGN_IDENTITY=$CODE_SIGN_IDENTITY")
fi
if [[ -n "${DEVELOPMENT_TEAM:-}" ]]; then
  extra_settings+=("DEVELOPMENT_TEAM=$DEVELOPMENT_TEAM")
fi

args=(
  -project "$project"
  -scheme "$scheme"
  -configuration "$configuration"
  -derivedDataPath "$derived_data"
  -destination "$destination"
  "CODE_SIGNING_ALLOWED=$code_signing_allowed"
  "CODE_SIGNING_REQUIRED=$code_signing_required"
)

if [[ ${#extra_settings[@]} -gt 0 ]]; then
  args+=("${extra_settings[@]}")
fi

xcodebuild "${args[@]}" build
