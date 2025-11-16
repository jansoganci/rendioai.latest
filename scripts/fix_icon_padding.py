#!/usr/bin/env python3
"""
Usage:
  python3 scripts/fix_icon_padding.py --input /abs/path/logo.png --output /abs/path/logo_padded.png \
    --canvas 1024 --margin_pct 12.5 --bg_color #0B0F1A

Creates a square canvas and fits the input image inside with the given margin.
This prevents iOS rounded mask from clipping glows/edges and avoids white seams.
"""
import argparse
from PIL import Image, ImageColor

def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument("--input", required=True)
    p.add_argument("--output", required=True)
    p.add_argument("--canvas", type=int, default=1024)
    p.add_argument("--margin_pct", type=float, default=12.5)
    p.add_argument("--bg_color", type=str, default="#0B0F1A")
    return p.parse_args()

def main():
    args = parse_args()
    canvas_size = args.canvas
    margin = max(0.0, min(45.0, args.margin_pct)) / 100.0
    inset = int(round(canvas_size * (1.0 - 2.0 * margin)))

    bg = Image.new("RGBA", (canvas_size, canvas_size), ImageColor.getcolor(args.bg_color, "RGBA"))
    im = Image.open(args.input).convert("RGBA")

    # Fit into inset square while preserving aspect.
    scale = min(inset / im.width, inset / im.height)
    new_w = max(1, int(round(im.width * scale)))
    new_h = max(1, int(round(im.height * scale)))
    im_resized = im.resize((new_w, new_h), Image.LANCZOS)

    # Center paste
    x = (canvas_size - new_w) // 2
    y = (canvas_size - new_h) // 2
    bg.alpha_composite(im_resized, dest=(x, y))

    # Save as standard sRGB PNG
    bg.save(args.output, format="PNG", optimize=True)

if __name__ == "__main__":
    main()


