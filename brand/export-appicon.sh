#!/usr/bin/env bash
# Xuất App Icon cho iOS + macOS (light & dark) từ SVG nguồn.
# Chạy: bash brand/export-appicon.sh   → ra brand/appicon/{ios,macos,png}
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SVG="$ROOT/brand/svg"; OUT="$ROOT/brand/appicon"
command -v rsvg-convert >/dev/null || { echo "Thiếu rsvg-convert → brew install librsvg"; exit 1; }
mkdir -p "$OUT/png" "$OUT/ios/AppIcon.appiconset" "$OUT/macos/AppIcon.appiconset"

echo "== Master 1024 =="
rsvg-convert -w 1024 -h 1024 "$SVG/AppIcon.svg"            -o "$OUT/png/macos-teal-1024.png"
rsvg-convert -w 1024 -h 1024 "$SVG/AppIcon-light.svg"      -o "$OUT/png/macos-light-1024.png"
rsvg-convert -w 1024 -h 1024 "$SVG/AppIcon-ios-light.svg"  -o "$OUT/png/ios-light-1024.png"
rsvg-convert -w 1024 -h 1024 "$SVG/AppIcon-ios-dark.svg"   -o "$OUT/png/ios-dark-1024.png"
rsvg-convert -w 1024 -h 1024 "$SVG/AppIcon-ios-tinted.svg" -o "$OUT/png/ios-tinted-1024.png"

echo "== iOS AppIcon.appiconset (1 cỡ 1024 + light/dark/tinted) =="
cp "$OUT/png/ios-light-1024.png"  "$OUT/ios/AppIcon.appiconset/icon-light.png"
cp "$OUT/png/ios-dark-1024.png"   "$OUT/ios/AppIcon.appiconset/icon-dark.png"
cp "$OUT/png/ios-tinted-1024.png" "$OUT/ios/AppIcon.appiconset/icon-tinted.png"
cat > "$OUT/ios/AppIcon.appiconset/Contents.json" <<'JSON'
{
  "images" : [
    { "filename" : "icon-light.png", "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" },
    { "appearances" : [ { "appearance" : "luminosity", "value" : "dark" } ], "filename" : "icon-dark.png", "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" },
    { "appearances" : [ { "appearance" : "luminosity", "value" : "tinted" } ], "filename" : "icon-tinted.png", "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
JSON

echo "== macOS AppIcon.appiconset (thang 16→1024, nền ngọc bích) =="
for s in 16 32 128 256 512; do
  rsvg-convert -w "$s"        -h "$s"        "$SVG/AppIcon.svg" -o "$OUT/macos/AppIcon.appiconset/icon_${s}x${s}.png"
  rsvg-convert -w "$((s*2))"  -h "$((s*2))"  "$SVG/AppIcon.svg" -o "$OUT/macos/AppIcon.appiconset/icon_${s}x${s}@2x.png"
done
cat > "$OUT/macos/AppIcon.appiconset/Contents.json" <<'JSON'
{
  "images" : [
    { "size":"16x16","idiom":"mac","filename":"icon_16x16.png","scale":"1x" },
    { "size":"16x16","idiom":"mac","filename":"icon_16x16@2x.png","scale":"2x" },
    { "size":"32x32","idiom":"mac","filename":"icon_32x32.png","scale":"1x" },
    { "size":"32x32","idiom":"mac","filename":"icon_32x32@2x.png","scale":"2x" },
    { "size":"128x128","idiom":"mac","filename":"icon_128x128.png","scale":"1x" },
    { "size":"128x128","idiom":"mac","filename":"icon_128x128@2x.png","scale":"2x" },
    { "size":"256x256","idiom":"mac","filename":"icon_256x256.png","scale":"1x" },
    { "size":"256x256","idiom":"mac","filename":"icon_256x256@2x.png","scale":"2x" },
    { "size":"512x512","idiom":"mac","filename":"icon_512x512.png","scale":"1x" },
    { "size":"512x512","idiom":"mac","filename":"icon_512x512@2x.png","scale":"2x" }
  ],
  "info" : { "author":"xcode","version":1 }
}
JSON

echo "== .icns (macOS, ngọc bích) =="
if command -v iconutil >/dev/null; then
  iconutil -c icns "$OUT/macos/AppIcon.appiconset" -o "$OUT/macos/Icon.icns" 2>/dev/null || \
  { TMP="$(mktemp -d)/AppIcon.iconset"; mkdir -p "$TMP"; cp "$OUT/macos/AppIcon.appiconset/"icon_*.png "$TMP/"; iconutil -c icns "$TMP" -o "$OUT/macos/Icon.icns"; }
fi

echo "XONG → $OUT"
echo "  iOS  : kéo brand/appicon/ios/AppIcon.appiconset vào Assets.xcassets của target iOS"
echo "  macOS: kéo brand/appicon/macos/AppIcon.appiconset (hoặc dùng Icon.icns) cho target macOS"
