#!/usr/bin/env bash
# Đóng gói MindfulKey.app dạng UNIVERSAL (1 file chạy được cả máy chip M lẫn máy Intel) —
# chuyển thể từ ref/haynoi-main/scripts/package_app.sh, đổi đường dẫn cho khớp cấu trúc
# platforms/apple/ của mindful-key.
#
# Phần build này KHÔNG cần tài khoản Apple Developer Program — code signing bị TẮT hẳn khi
# build (ký ad-hoc/thật là việc của sign-and-notarize.sh, để dành tới Bước 9 — xem README.md
# trong thư mục này).
#
# Cách dùng:
#   bash scripts/package_app.sh                       # chỉ build kiến trúc của máy đang chạy
#   ARCHES="arm64 x86_64" bash scripts/package_app.sh  # build cả 2, dán lại thành bản universal
#
# Output: platforms/apple/build/<Release|Debug>/MindfulKey.app — build-dmg.sh tự tìm thấy.
set -euo pipefail

CONF=${1:-release}
# macOS đi kèm bash 3.2 — bản bash cũ này không có ${CONF^} để viết hoa chữ đầu.
case "$CONF" in
  release) CONF_TITLE="Release" ;;
  debug)   CONF_TITLE="Debug" ;;
  *)       CONF_TITLE="$CONF" ;;
esac

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"
source "$ROOT/version.env"

ARCH_LIST=( ${ARCHES:-} )
if [[ ${#ARCH_LIST[@]} -eq 0 ]]; then
  HOST_ARCH=$(uname -m)
  case "$HOST_ARCH" in
    arm64) ARCH_LIST=(arm64) ;;
    x86_64) ARCH_LIST=(x86_64) ;;
    *) ARCH_LIST=("$HOST_ARCH") ;;
  esac
fi

echo "==> Sinh Xcode project (XcodeGen)"
(cd "$ROOT/platforms/apple" && xcodegen generate -q)

echo "==> Build MindfulKey cho kiến trúc: ${ARCH_LIST[*]}"
XCODEPROJ="$ROOT/platforms/apple/MindfulKey.xcodeproj"
SCHEME=MindfulKey
ARCHIVE_DIR="$ROOT/platforms/apple/build/archive"
rm -rf "$ARCHIVE_DIR"
mkdir -p "$ARCHIVE_DIR"

# Build riêng từng kiến trúc thành 1 "xcarchive", lát nữa dán lại bằng lipo.
for ARCH in "${ARCH_LIST[@]}"; do
  xcodebuild archive \
    -project "$XCODEPROJ" \
    -scheme "$SCHEME" \
    -configuration "$CONF_TITLE" \
    -archivePath "$ARCHIVE_DIR/MindfulKey-${ARCH}.xcarchive" \
    -arch "$ARCH" \
    ONLY_ACTIVE_ARCH=NO \
    CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
    MARKETING_VERSION="$VERSION" \
    | grep -E "error:|warning:|BUILD" || true
done

APP_DIR="$ROOT/platforms/apple/build/$CONF_TITLE/MindfulKey.app"
rm -rf "$APP_DIR"
mkdir -p "$(dirname "$APP_DIR")"
cp -R "$ARCHIVE_DIR/MindfulKey-${ARCH_LIST[0]}.xcarchive/Products/Applications/MindfulKey.app" "$APP_DIR"

if [[ ${#ARCH_LIST[@]} -gt 1 ]]; then
  echo "==> Dán các bản kiến trúc lại thành 1 file universal (lipo)"
  BINARY="$APP_DIR/Contents/MacOS/MindfulKey"
  LIPO_INPUTS=()
  for ARCH in "${ARCH_LIST[@]}"; do
    LIPO_INPUTS+=("$ARCHIVE_DIR/MindfulKey-${ARCH}.xcarchive/Products/Applications/MindfulKey.app/Contents/MacOS/MindfulKey")
  done
  lipo -create -output "$BINARY" "${LIPO_INPUTS[@]}"
  echo "  lipo info: $(lipo -info "$BINARY")"
fi

# Đóng dấu số phiên bản vào Info.plist — phòng khi build setting không resolve đúng vào bản
# archive. version.env là nguồn duy nhất; chưa tách riêng BUILD_NUMBER (chưa cần — số build
# riêng chỉ có ích khi gắn Sparkle tự-cập-nhật, việc đó đang hoãn, xem scripts/README.md).
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP_DIR/Contents/Info.plist"

# Ký lại ad-hoc SAU khi đã sửa Info.plist (và dán lipo nếu universal) — bắt buộc, vì sửa
# Info.plist/binary sau khi archive đã ký (ad-hoc tự động của linker arm64) làm hỏng seal chữ
# ký cũ. Chữ ký hỏng khiến macOS không nhận diện đúng identity của app ở lần chạy sau, làm
# TCC "quên" quyền Accessibility/Input Monitoring đã cấp trước đó dù chưa từng bị thu hồi
# (đã xác nhận qua thực nghiệm: app tự thoát lặp lại dù TCC.db báo auth_value=2 cho tới khi
# ký lại). Không dùng identity thật (chưa có Developer ID) nên vẫn ký "-" (ad-hoc).
codesign --force --deep -s - "$APP_DIR"

echo "==> Đã build xong: $APP_DIR"
echo "    phiên bản: $VERSION"
