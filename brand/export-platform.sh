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

# [MINDFUL] 2026-07-17 — icon KHAY + nút cho vỏ Windows.
#
# Trước đó script này CHỈ sinh AppIcon.ico, nên vỏ Windows vẫn chạy nguyên bộ icon OpenKey 2019
# (chữ "V"), kể cả icon khay — thứ người dùng nhìn NHIỀU NHẤT, cả ngày. SVG nguồn đã có sẵn đúng
# những hình cần (Status/StatusEng/OK/ExitButton/StartConvert), chỉ chưa ai nối sang .ico.
#
# BẢN XÁM (`vUseGrayIcon` -> *10.ico): macOS làm bằng `setTemplate:YES` — hệ thống TỰ chuyển sang
# đơn sắc thích ứng thanh menu sáng/tối. Windows KHÔNG có gì tương đương, khay cần pixel thật. Nên
# ta tô lại bằng token `stone` (#8A9BA0) — sắc độ trung tính của chính brand, đọc được trên cả khay
# sáng lẫn tối. ĐÂY LÀ CÁCH ĐỌC BRAND, chưa phải quyết định của chủ dự án — xem docs/FRICTION-LOG.md
# 2026-07-17. Tên "*10" là di sản OpenKey và NÓI DỐI: nó không phải "kiểu Windows 10", nó là bản
# xám (SystemTrayHelper.cpp:288). Giữ tên vì đổi = đụng resource.h + .rc, ngoài phạm vi.
STONE="#8A9BA0"
TRAY_SIZES=(16 20 24 32 48 64 256)
BTN_SIZES=(16 24 32 48)

ico_from_svg() {   # $1=svg nguồn  $2=.ico đích  $3=màu thay thế (rỗng = giữ nguyên)  $4..=cỡ
  local svg="$1" out="$2" recolor="$3"; shift 3
  local tmpsvg="$svg" pngs=()
  if [ -n "$recolor" ]; then
    tmpsvg="$(mktemp -t mkicon).svg"
    sed -E "s/(stroke|fill)=\"#[0-9A-Fa-f]{6}\"/\1=\"$recolor\"/g" "$svg" > "$tmpsvg"
  fi
  for s in "$@"; do
    local png="$OUT/windows/png/tmp-$s.png"
    rsvg-convert -w "$s" -h "$s" "$tmpsvg" -o "$png"
    pngs+=("$png")
  done
  python3 "$ROOT/brand/pack-ico.py" "$out" "${pngs[@]}"
  rm -f "${pngs[@]}"
  # if/fi chứ KHÔNG `[ ... ] && rm`: recolor rỗng -> biểu thức trả non-zero -> `set -e` giết
  # script ngay tại đây, và nó chết SAU khi đã sinh xong file đầu nên nhìn như lỗi SVG.
  if [ -n "$recolor" ]; then rm -f "$tmpsvg"; fi
}

echo "== Windows: icon khay (con sóng ~) =="
ico_from_svg "$SVG/Status.svg"       "$OUT/windows/StatusViet.ico"   ""       "${TRAY_SIZES[@]}"
ico_from_svg "$SVG/StatusEng.svg"    "$OUT/windows/StatusEng.ico"    ""       "${TRAY_SIZES[@]}"
ico_from_svg "$SVG/Status.svg"       "$OUT/windows/StatusViet10.ico" "$STONE" "${TRAY_SIZES[@]}"
ico_from_svg "$SVG/StatusEng.svg"    "$OUT/windows/StatusEng10.ico"  "$STONE" "${TRAY_SIZES[@]}"
# Sóng biên độ CAO — "tâm đang động". Teal, KHÔNG cam: nhận diện là BIÊN ĐỘ, không phải màu cảnh
# báo (BRAND-ASSETS §4/§5, HIẾN CHƯƠNG §2.3). Asset này brand vẽ sẵn từ lâu, §6 ghi "cần wire" —
# và tới 2026-07-17 thì CẢ macOS lẫn Windows đều chưa nối. Windows nối trước.
ico_from_svg "$SVG/StatusAlert.svg"  "$OUT/windows/StatusAlert.ico"  ""       "${TRAY_SIZES[@]}"

echo "== Windows: icon nút =="
ico_from_svg "$SVG/OK.svg"           "$OUT/windows/OKButton.ico"     ""       "${BTN_SIZES[@]}"
ico_from_svg "$SVG/ExitButton.svg"   "$OUT/windows/ExitButton.ico"   ""       "${BTN_SIZES[@]}"
ico_from_svg "$SVG/StartConvert.svg" "$OUT/windows/StartConvert.ico" ""       "${BTN_SIZES[@]}"

# Icon 4 tab cửa sổ Điều khiển. Brand vẽ sẵn đúng 4 tab Windows đang có, ĐÚNG THỨ TỰ
# (MainControlDialog.cpp: Bộ gõ · Gõ tắt · Hệ thống · Thông tin) — chưa ai nối.
echo "== Windows: icon tab =="
ico_from_svg "$SVG/ui-tab-bogo.svg"     "$OUT/windows/TabBoGo.ico"     "" "${BTN_SIZES[@]}"
ico_from_svg "$SVG/ui-tab-gotat.svg"    "$OUT/windows/TabGoTat.ico"    "" "${BTN_SIZES[@]}"
ico_from_svg "$SVG/ui-tab-hethong.svg"  "$OUT/windows/TabHeThong.ico"  "" "${BTN_SIZES[@]}"
ico_from_svg "$SVG/ui-tab-thongtin.svg" "$OUT/windows/TabThongTin.ico" "" "${BTN_SIZES[@]}"

# Icon 4 bộ tiếng chuông (popover + tab Chuông). Brand vẽ sẵn 3 tiếng + 1 tuỳ chỉnh; trước 2026-07-23
# UI Windows hiện chữ giả A/B/C/D (BrandControls_DrawIconGroup fallback) — nay nối sang .ico thật.
echo "== Windows: icon bộ tiếng chuông =="
ico_from_svg "$SVG/bell_temple.svg"  "$OUT/windows/BellTemple.ico"  "" "${BTN_SIZES[@]}"
ico_from_svg "$SVG/bell_chime.svg"   "$OUT/windows/BellChime.ico"   "" "${BTN_SIZES[@]}"
ico_from_svg "$SVG/bell_wind.svg"    "$OUT/windows/BellWind.ico"    "" "${BTN_SIZES[@]}"
ico_from_svg "$SVG/bell-custom.svg"  "$OUT/windows/BellCustom.ico"  "" "${BTN_SIZES[@]}"

echo "== Windows: icon app =="
ico_from_svg "$SVG/AppIcon.svg"      "$OUT/windows/icon.ico"         ""       16 20 24 32 48 64 128 256

# DefaultButton.ico ("Cài đặt gốc") CỐ Ý không sinh: brand chưa có hình cho hành động này, và bịa
# một cái là tự chế nhận diện. Vỏ Windows giữ icon OpenKey gốc cho nút đó — xem FRICTION-LOG.

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
