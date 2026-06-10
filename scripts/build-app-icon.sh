#!/bin/bash
set -euo pipefail

ICONSET="${SRCROOT}/ClaudeRTL/Assets.xcassets/AppIcon.appiconset"
WORK="${DERIVED_FILE_DIR}/AppIcon.iconset"
DEST="${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/AppIcon.icns"

if [ ! -d "$ICONSET" ]; then
  echo "warning: AppIcon.appiconset not found at $ICONSET"
  exit 0
fi

mkdir -p "$WORK"
cp "${ICONSET}"/icon_*.png "$WORK/"
iconutil -c icns "$WORK" -o "$DEST"
echo "Built complete AppIcon.icns → $DEST ($(wc -c < "$DEST") bytes)"
