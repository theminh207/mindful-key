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

# Số build (CFBundleVersion) = số commit trong lịch sử git — tăng đơn điệu, không cần nhớ bump
# tay (báo cáo 0.2.1 mục 6.6: đứng yên ở 1 thì không phân biệt được các bản build, và Sparkle
# sau này so bản mới/cũ bằng đúng con số này). CI phải checkout ĐỦ lịch sử (fetch-depth: 0 —
# release.yml đã set); checkout nông sẽ đếm ra 1 nên chặn luôn cho khỏi phát hành số sai.
BUILD_NUMBER=$(git -C "$ROOT" rev-list --count HEAD 2>/dev/null || echo 0)
if [[ "${CI:-}" == "true" && "$BUILD_NUMBER" -le 1 ]]; then
  echo "LỖI: BUILD_NUMBER=$BUILD_NUMBER trên CI — checkout nông hoặc không phải git repo." >&2
  echo "     Thêm fetch-depth: 0 vào bước checkout của job release." >&2
  exit 1
fi

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
    CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
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

# Đóng dấu số phiên bản + số build vào Info.plist — phòng khi build setting không resolve đúng
# vào bản archive. version.env là nguồn duy nhất cho VERSION; BUILD_NUMBER đếm từ git (ở trên).
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP_DIR/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$APP_DIR/Contents/Info.plist"

# Ký lại ad-hoc SAU khi đã sửa Info.plist (và dán lipo nếu universal) — bắt buộc, vì sửa
# Info.plist/binary sau khi archive đã ký (ad-hoc tự động của linker arm64) làm hỏng seal chữ
# ký cũ. Chữ ký hỏng khiến macOS không nhận diện đúng identity của app ở lần chạy sau, làm
# TCC "quên" quyền Accessibility/Input Monitoring đã cấp trước đó dù chưa từng bị thu hồi
# (đã xác nhận qua thực nghiệm: app tự thoát lặp lại dù TCC.db báo auth_value=2 cho tới khi
# ký lại). Không dùng identity thật (chưa có Developer ID) nên vẫn ký "-" (ad-hoc).
codesign --force --deep -s - "$APP_DIR"

echo "==> Đã build xong: $APP_DIR"
echo "    phiên bản: $VERSION"
