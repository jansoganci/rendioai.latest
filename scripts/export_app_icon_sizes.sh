#!/bin/zsh
# Usage:
#   scripts/export_app_icon_sizes.sh /absolute/path/to/icon-1024.png /output/folder
# Exports legacy iOS app icon PNG sizes (for tools that still want explicit files).

set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: scripts/export_app_icon_sizes.sh <1024x1024.png> <output_dir>"
  exit 1
fi

SRC="$1"
OUTDIR="$2"

if [[ ! -f "$SRC" ]]; then
  echo "Error: File not found: $SRC"
  exit 1
fi
mkdir -p "$OUTDIR"

# Helper: export size
export_icon() {
  local size="$1"        # pixels (square)
  local name="$2"        # filename
  sips -s format png -z "$size" "$size" "$SRC" --out "$OUTDIR/$name" >/dev/null
  echo "Wrote $OUTDIR/$name"
}

echo "Exporting iOS icon sizes to $OUTDIR ..."

# iPhone/iPad (pt sizes -> px @2x/@3x). These cover typical 20/29/40/60 pt families.
export_icon 40   "Icon-20@2x.png"     # 20pt @2x (Spotlight/Settings)
export_icon 60   "Icon-20@3x.png"     # 20pt @3x
export_icon 58   "Icon-29@2x.png"     # 29pt @2x
export_icon 87   "Icon-29@3x.png"     # 29pt @3x
export_icon 80   "Icon-40@2x.png"     # 40pt @2x
export_icon 120  "Icon-40@3x.png"     # 40pt @3x
export_icon 120  "Icon-60@2x.png"     # 60pt @2x (iPhone icon 120)
export_icon 180  "Icon-60@3x.png"     # 60pt @3x (iPhone icon 180)
export_icon 76   "Icon-76.png"        # iPad
export_icon 152  "Icon-76@2x.png"     # iPad
export_icon 167  "Icon-83.5@2x.png"   # iPad Pro

# App Store / Marketing
export_icon 1024 "Icon-Marketing-1024.png"

echo "Done."


