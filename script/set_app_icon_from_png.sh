#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 /path/to/icon.png" >&2
  exit 2
fi

SOURCE_PNG="$1"
if [[ ! -f "$SOURCE_PNG" ]]; then
  echo "icon png not found: $SOURCE_PNG" >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ASSETS_DIR="$ROOT_DIR/assets"
ICONSET="$ASSETS_DIR/AppIcon.iconset"
BASE_PNG="$ASSETS_DIR/AppIcon-1024.png"
NORMALIZED_PNG="$ASSETS_DIR/AppIcon-1024-normalized.png"
SOURCE_COPY="$ASSETS_DIR/AppIcon-source.png"
ICNS="$ASSETS_DIR/AppIcon.icns"

mkdir -p "$ASSETS_DIR"
rm -rf "$ICONSET"
mkdir -p "$ICONSET"

if [[ "$(cd "$(dirname "$SOURCE_PNG")" && pwd)/$(basename "$SOURCE_PNG")" != "$SOURCE_COPY" ]]; then
  cp "$SOURCE_PNG" "$SOURCE_COPY"
fi

/usr/bin/swift "$ROOT_DIR/script/normalize_app_icon.swift" "$SOURCE_COPY" "$NORMALIZED_PNG"
/usr/bin/sips -s format png -z 1024 1024 "$NORMALIZED_PNG" --out "$BASE_PNG" >/dev/null

declare -a NAMES=(
  "icon_16x16.png:16"
  "icon_16x16@2x.png:32"
  "icon_32x32.png:32"
  "icon_32x32@2x.png:64"
  "icon_128x128.png:128"
  "icon_128x128@2x.png:256"
  "icon_256x256.png:256"
  "icon_256x256@2x.png:512"
  "icon_512x512.png:512"
  "icon_512x512@2x.png:1024"
)

for item in "${NAMES[@]}"; do
  name="${item%%:*}"
  size="${item##*:}"
  /usr/bin/sips -z "$size" "$size" "$BASE_PNG" --out "$ICONSET/$name" >/dev/null
done

/usr/bin/iconutil -c icns "$ICONSET" -o "$ICNS"

"$ROOT_DIR/script/build_and_run.sh" --install

echo "Installed icon from $SOURCE_PNG"
echo "Source copy: $SOURCE_COPY"
echo "App icon: /Applications/拾影.app"
