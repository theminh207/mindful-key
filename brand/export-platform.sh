#!/usr/bin/env bash
# Xuất icon cho Windows / Android / Linux từ SVG nguồn.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SVG="$ROOT/brand/svg"; OUT="$ROOT/brand/platform"
command -v rsvg-convert >/dev/null || { echo "Thiếu rsvg-convert → brew install librsvg"; exit 1; }

echo "== Windows (.ico đa cỡ, nền vuông teal) =="
mkdir -p "$OUT/windows/png"
WSIZES=(16 32 48 64 128 256)
args=()
for s in "${WSIZES[@]}"; do
  rsvg-convert -w "$s" -h "$s" "$SVG/AppIcon-ios-dark.svg" -o "$OUT/windows/png/$s.png"
  args+=("$OUT/windows/png/$s.png")
done
python3 "$ROOT/brand/pack-ico.py" "$OUT/windows/AppIcon.ico" "${args[@]}"

echo "== Android (adaptive icon 432px: foreground / background / monochrome) =="
mkdir -p "$OUT/android"
rsvg-convert -w 432 -h 432 "$SVG/android-foreground.svg" -o "$OUT/android/ic_launcher_foreground.png"
rsvg-convert -w 432 -h 432 "$SVG/android-background.svg" -o "$OUT/android/ic_launcher_background.png"
rsvg-convert -w 432 -h 432 "$SVG/android-monochrome.svg" -o "$OUT/android/ic_launcher_monochrome.png"
# legacy square (mipmap) cho máy cũ
for s in 48 72 96 144 192; do
  rsvg-convert -w "$s" -h "$s" "$SVG/AppIcon-ios-dark.svg" -o "$OUT/android/ic_launcher_${s}.png"
done

echo "== Linux (hicolor theme + scalable) =="
for s in 48 64 128 256 512; do
  d="$OUT/linux/hicolor/${s}x${s}/apps"; mkdir -p "$d"
  rsvg-convert -w "$s" -h "$s" "$SVG/AppIcon.svg" -o "$d/mindful-keyboard.png"
done
mkdir -p "$OUT/linux/hicolor/scalable/apps"
cp "$SVG/AppIcon.svg" "$OUT/linux/hicolor/scalable/apps/mindful-keyboard.svg"

echo "XONG → $OUT"
