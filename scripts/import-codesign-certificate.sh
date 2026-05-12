#!/usr/bin/env bash
set -euo pipefail

: "${DEVELOPER_ID_APPLICATION_CERTIFICATE_BASE64:?Set DEVELOPER_ID_APPLICATION_CERTIFICATE_BASE64}"
: "${DEVELOPER_ID_APPLICATION_CERTIFICATE_PASSWORD:?Set DEVELOPER_ID_APPLICATION_CERTIFICATE_PASSWORD}"

runner_temp="${RUNNER_TEMP:-/tmp}"
certificate_path="$runner_temp/taskies-developer-id-application.p12"
keychain_path="$runner_temp/taskies-signing.keychain-db"
keychain_password="${KEYCHAIN_PASSWORD:-taskies-signing-keychain}"

printf '%s' "$DEVELOPER_ID_APPLICATION_CERTIFICATE_BASE64" | base64 --decode > "$certificate_path"

security create-keychain -p "$keychain_password" "$keychain_path"
security set-keychain-settings -lut 21600 "$keychain_path"
security unlock-keychain -p "$keychain_password" "$keychain_path"
security import "$certificate_path" \
  -P "$DEVELOPER_ID_APPLICATION_CERTIFICATE_PASSWORD" \
  -A \
  -t cert \
  -f pkcs12 \
  -k "$keychain_path"
security list-keychains -d user -s "$keychain_path"
security default-keychain -s "$keychain_path"
security set-key-partition-list \
  -S apple-tool:,apple: \
  -s \
  -k "$keychain_password" \
  "$keychain_path"
