#!/bin/zsh
# Usage:
#   scripts/set_app_icon.sh /absolute/path/to/icon-1024.png
# Copies a 1024x1024 PNG into the Xcode Asset Catalog AppIcon set and updates Contents.json.

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Error: Please provide a 1024x1024 PNG path."
  echo "Example: scripts/set_app_icon.sh /Users/you/Downloads/@Gemini_Generated_Image_aqvabkaqvabkaqva.png"
  exit 1
fi

SRC="$1"
if [[ ! -f "$SRC" ]]; then
  echo "Error: File not found: $SRC"
  exit 1
fi

# Project appiconset directory
APPICON_DIR="/Users/jans./Downloads/RendioAI/RendioAI/RendioAI/Assets.xcassets/AppIcon.appiconset"
DEST_PNG="$APPICON_DIR/AppIcon-1024.png"
CONTENTS_JSON="$APPICON_DIR/Contents.json"

# Ensure PNG is 1024x1024; if not, resize with sips
WIDTH=$(sips -g pixelWidth "$SRC" 2>/dev/null | awk '/pixelWidth/ {print $2}')
HEIGHT=$(sips -g pixelHeight "$SRC" 2>/dev/null | awk '/pixelHeight/ {print $2}')
if [[ "$WIDTH" != "1024" || "$HEIGHT" != "1024" ]]; then
  echo "Resizing to 1024x1024 with sips..."
  sips -s format png -z 1024 1024 "$SRC" --out "$DEST_PNG" >/dev/null
else
  cp "$SRC" "$DEST_PNG"
fi

echo "Wrote $DEST_PNG"

# Update Contents.json to point to the file (keeps existing structure)
TMP_JSON="$(mktemp).json"
cat > "$TMP_JSON" <<'JSON'
{
  "images" : [
    {
      "filename" : "AppIcon-1024.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
JSON

mv "$TMP_JSON" "$CONTENTS_JSON"
echo "Updated $CONTENTS_JSON to reference AppIcon-1024.png"
echo "Done. Open Xcode > General > App Icons and verify 'AppIcon' is selected."


