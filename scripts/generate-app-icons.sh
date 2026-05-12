#!/usr/bin/env bash
set -euo pipefail

source_svg="${SOURCE_SVG:-Taskies/Resources/AppIcon.svg}"
iconset_dir="${ICONSET_DIR:-Taskies/Resources/Assets.xcassets/AppIcon.appiconset}"
base_size=1024
render_size=1254
work_dir="${TMPDIR:-/tmp}/taskies-app-icons.$$"

cleanup() {
  rm -rf "$work_dir"
}
trap cleanup EXIT

if [[ ! -f "$source_svg" ]]; then
  echo "missing source SVG: $source_svg" >&2
  exit 1
fi

if [[ ! -d "$iconset_dir" ]]; then
  echo "missing iconset directory: $iconset_dir" >&2
  exit 1
fi

mkdir -p "$work_dir"

qlmanage -t -s "$base_size" -o "$work_dir" "$source_svg" >/dev/null
rendered_png="$work_dir/$(basename "$source_svg").png"
if [[ ! -f "$rendered_png" ]]; then
  echo "Quick Look did not render $source_svg" >&2
  exit 1
fi

scaled_png="$work_dir/AppIcon-scaled.png"
base_png="$work_dir/AppIcon-base.png"
sips -z "$render_size" "$render_size" "$rendered_png" --out "$scaled_png" >/dev/null
sips -c "$base_size" "$base_size" "$scaled_png" --out "$base_png" >/dev/null

generate_icon() {
  local filename="$1"
  local size="$2"
  local output="$iconset_dir/$filename"

  if [[ "$size" == "$base_size" ]]; then
    cp "$base_png" "$output"
  else
    sips -z "$size" "$size" "$base_png" --out "$output" >/dev/null
  fi
}

generate_icon "icon_16x16.png" 16
generate_icon "icon_16x16@2x.png" 32
generate_icon "icon_32x32.png" 32
generate_icon "icon_32x32@2x.png" 64
generate_icon "icon_128x128.png" 128
generate_icon "icon_128x128@2x.png" 256
generate_icon "icon_256x256.png" 256
generate_icon "icon_256x256@2x.png" 512
generate_icon "icon_512x512.png" 512
generate_icon "icon_512x512@2x.png" 1024

echo "Generated app icons from $source_svg"
