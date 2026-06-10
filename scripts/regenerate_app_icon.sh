#!/bin/bash
# Regenerate AppIcon.appiconset PNGs from the master source (claude-ai-icon.png).
# Run from repo root: ./scripts/regenerate_app_icon.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="${ROOT}/ClaudeRTL/Resources/claude-ai-icon.png"
ICONSET="${ROOT}/ClaudeRTL/Assets.xcassets/AppIcon.appiconset"

if [ ! -f "$SOURCE" ]; then
  echo "error: master icon not found at $SOURCE" >&2
  exit 1
fi

cd "$ICONSET"
sips -z 16 16     "$SOURCE" --out icon_16x16.png
sips -z 32 32     "$SOURCE" --out icon_16x16@2x.png
sips -z 32 32     "$SOURCE" --out icon_32x32.png
sips -z 64 64     "$SOURCE" --out icon_32x32@2x.png
sips -z 128 128   "$SOURCE" --out icon_128x128.png
sips -z 256 256   "$SOURCE" --out icon_128x128@2x.png
sips -z 256 256   "$SOURCE" --out icon_256x256.png
sips -z 512 512   "$SOURCE" --out icon_256x256@2x.png
sips -z 512 512   "$SOURCE" --out icon_512x512.png
sips -z 1024 1024 "$SOURCE" --out icon_512x512@2x.png

echo "Regenerated 10 AppIcon sizes in $ICONSET"
