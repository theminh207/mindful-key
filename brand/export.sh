#!/usr/bin/env bash
# Xuất bộ brand-asset (NOW BRAND OS) từ SVG nguồn -> PNG/.icns cho vỏ macOS ModernKey.
# Yêu cầu: rsvg-convert (brew install librsvg), iconutil, sips (có sẵn trên macOS).
# Chạy:  bash brand/export.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SVG="$ROOT/brand/svg"
RES="$ROOT/platforms/apple/Resources"
MACOS_UI="$ROOT/platforms/apple/macos"
PREVIEW="$ROOT/brand/png"
BACKUP="$ROOT/brand/backup-original"

command -v rsvg-convert >/dev/null || { echo "Thiếu rsvg-convert -> brew install librsvg"; exit 1; }
command -v iconutil     >/dev/null || { echo "Thiếu iconutil (macOS only)"; exit 1; }

mkdir -p "$PREVIEW"

# 0) Backup bản gốc MỘT LẦN (không ghi đè backup nếu đã có)
if [ ! -d "$BACKUP" ]; then
  mkdir -p "$BACKUP"
  cp "$RES"/*.png "$RES"/Icon.icns "$BACKUP"/ 2>/dev/null || true
  echo "Đã backup icon gốc -> brand/backup-original/"
fi

png() { rsvg-convert -w "$2" -h "$2" "$SVG/$1.svg" -o "$3"; }          # vuông
pngwh() { rsvg-convert -w "$2" -h "$3" "$SVG/$1.svg" -o "$4"; }        # chữ nhật

echo "== Menu bar (22 / 44) =="
for n in Status StatusEng StatusHighlighted StatusHighlightedEng StatusAlert; do
  png "$n" 22 "$RES/$n.png"
  png "$n" 44 "$RES/$n@2x.png"
done

echo "== Nút trong app (50 / 100) =="
for n in OK ThumbUp StartConvert ExitButton; do
  png "$n" 50  "$RES/$n.png"
  png "$n" 100 "$RES/$n@2x.png"
done

echo "== App icon -> Icon.icns =="
ICONSET="$(mktemp -d)/Icon.iconset"; mkdir -p "$ICONSET"
for s in 16 32 128 256 512; do
  png AppIcon "$s"            "$ICONSET/icon_${s}x${s}.png"
  png AppIcon "$((s*2))"      "$ICONSET/icon_${s}x${s}@2x.png"
done
iconutil -c icns "$ICONSET" -o "$RES/Icon.icns"

echo "== Icon 'Bộ tiếng' — ô thứ 4 'tiếng của bạn' (48 / 96) =="
# [MINDFUL] 2026-07-17 — nút thứ 4 ở thẻ Bộ tiếng (BellSettingsView.mm) nạp qua
# `[NSImage imageNamed:@"bell-custom"]`, nên hình PHẢI nằm cạnh 3 icon chuông kia trong
# platforms/apple/macos/ (thư mục đó cũng được XcodeGen copy vào bundle như Resources/).
# Bản đầu dùng `bell-idle` (hình chuông trơn) — chủ dự án nhìn app thật rồi bác: trùng icon với ô
# "Chuông gió" bên cạnh. Nay là nốt nhạc `bell-custom.svg`, xem decision-log 2026-07-17.
# ⚠️ Lệch pha đã biết: 3 icon bell_temple/bell_chime/bell_wind có SVG nguồn trong brand/svg/
# nhưng KHÔNG do file này sinh ra (ai đó xuất tay) — xem FRICTION-LOG 2026-07-17.
png bell-custom 48 "$MACOS_UI/bell-custom.png"
png bell-custom 96 "$MACOS_UI/bell-custom@2x.png"

echo "== Preview: chuông + thang mặt hồ (chưa wire vào code, để dùng cho HUD/biểu đồ) =="
png bell-idle 64 "$PREVIEW/bell-idle.png"
png bell-ring 64 "$PREVIEW/bell-ring.png"
for n in mood-1-an mood-2-nhe mood-3-gon mood-4-song mood-5-cuon; do
  pngwh "$n" 120 80 "$PREVIEW/$n.png"
done

echo "XONG. Icon Resources đã thay theo NOW BRAND OS. Bản gốc ở brand/backup-original/."
echo "Lưu ý: StatusAlert.png là asset MỚI (trạng thái cảnh báo) — cần wire trong AppDelegate.m khi làm bước gác cổng."
