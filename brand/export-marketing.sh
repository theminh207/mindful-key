#!/usr/bin/env bash
# Xuất asset truyền thông: wordmark, nền .dmg, social preview, README hero.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SVG="$ROOT/brand/svg"; OUT="$ROOT/brand/marketing"
command -v rsvg-convert >/dev/null || { echo "Thiếu rsvg-convert → brew install librsvg"; exit 1; }
mkdir -p "$OUT"

# wordmark (teal + white), @1x + @2x
rsvg-convert -w 1480 "$SVG/wordmark.svg"        -o "$OUT/wordmark.png"
rsvg-convert -w 2960 "$SVG/wordmark.svg"        -o "$OUT/wordmark@2x.png"
rsvg-convert -w 1480 "$SVG/wordmark-white.svg"  -o "$OUT/wordmark-white.png"
rsvg-convert -w 2960 "$SVG/wordmark-white.svg"  -o "$OUT/wordmark-white@2x.png"

# nền .dmg (660x420) + @2x
rsvg-convert -w 640  -h 400 "$SVG/dmg-background.svg" -o "$OUT/dmg-background.png"
rsvg-convert -w 1280 -h 800 "$SVG/dmg-background.svg" -o "$OUT/dmg-background@2x.png"

# GitHub social preview (đúng 1280x640) + README hero (1280x400)
rsvg-convert -w 1280 -h 640 "$SVG/social-preview.svg" -o "$OUT/social-preview.png"
rsvg-convert -w 1280 -h 400 "$SVG/readme-hero.svg"    -o "$OUT/readme-hero.png"

echo "XONG → $OUT"
ls -1 "$OUT"
