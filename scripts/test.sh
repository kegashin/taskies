#!/usr/bin/env bash
set -euo pipefail

project="${PROJECT:-Taskies.xcodeproj}"
scheme="${SCHEME:-Taskies}"
configuration="${CONFIGURATION:-Debug}"
derived_data="${DERIVED_DATA:-${RUNNER_TEMP:-/tmp}/TaskiesTestDerivedData}"
destination="${DESTINATION:-platform=macOS}"
code_signing_allowed="${CODE_SIGNING_ALLOWED:-NO}"

xcodebuild \
  -project "$project" \
  -scheme "$scheme" \
  -configuration "$configuration" \
  -derivedDataPath "$derived_data" \
  -destination "$destination" \
  "CODE_SIGNING_ALLOWED=$code_signing_allowed" \
  test
