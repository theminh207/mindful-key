#!/usr/bin/env bash
# Xuất bộ icon UI đơn sắc (tab settings, xin quyền, thông báo, toggle, ngôn ngữ) → brand/png-ui/ (24 + 48px).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SVG="$ROOT/brand/svg"; OUT="$ROOT/brand/png-ui"
command -v rsvg-convert >/dev/null || { echo "Thiếu rsvg-convert → brew install librsvg"; exit 1; }
mkdir -p "$OUT"

ICONS=(
  ui-tab-bogo ui-tab-gotat ui-tab-hethong ui-tab-thongtin
  ui-perm-accessibility ui-perm-inputmonitoring
  ui-notif ui-snooze ui-resume
  ui-toggle-on ui-toggle-off ui-lang-vi ui-lang-en
)
for n in "${ICONS[@]}"; do
  rsvg-convert -w 24 -h 24 "$SVG/$n.svg" -o "$OUT/$n.png"
  rsvg-convert -w 48 -h 48 "$SVG/$n.svg" -o "$OUT/$n@2x.png"
done
echo "XONG → $OUT (${#ICONS[@]} icon × 2 cỡ)"
