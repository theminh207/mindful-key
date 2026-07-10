#!/usr/bin/env bash
# Nhạc trưởng: universal build -> ký+notarize .app -> đóng .dmg -> ký+notarize .dmg ->
# xuất dSYM + zip -> cắt changelog. Output đủ 4 loại asset để đăng GitHub Release (giống
# cấu trúc haynoi — xem docs/RELEASE.md): <ver>.dmg, universal.zip, universal.dSYM.zip,
# release-notes.html.
#
# Cách dùng:
#   bash scripts/release.sh
#
# Cần đủ biến môi trường ký/notarize (xem scripts/sign-and-notarize.sh) TRỪ khi chạy với
# SKIP_SIGN=1 (build + đóng gói ad-hoc để tự test cục bộ, không notarize — không dùng để
# phát hành công khai).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
source version.env

OUT_DIR="$ROOT/release-out"
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

echo "======================================================"
echo " Release MindfulKey v$VERSION"
echo "======================================================"

echo ""
echo "==> [1/6] Regression engine (lưới an toàn trước khi phát hành)"
bash tests/core/build.sh
./tests/core/test_engine

echo ""
echo "==> [2/6] Universal build (arm64 + x86_64)"
ARCHES="arm64 x86_64" bash scripts/package_app.sh release
APP_PATH="$ROOT/platforms/apple/build/Release/MindfulKey.app"

echo ""
echo "==> [3/6] Xuất dSYM universal (dán lipo 2 kiến trúc, cần để đọc crash report sau này)"
ARCHIVE_DIR="$ROOT/platforms/apple/build/archive"
DSYM_OUT="$OUT_DIR/MindfulKey-$VERSION-universal.dSYM"
rm -rf "$DSYM_OUT"
cp -R "$ARCHIVE_DIR/MindfulKey-arm64.xcarchive/dSYMs/MindfulKey.app.dSYM" "$DSYM_OUT"
if [[ -d "$ARCHIVE_DIR/MindfulKey-x86_64.xcarchive" ]]; then
  lipo -create -output "$DSYM_OUT/Contents/Resources/DWARF/MindfulKey" \
    "$ARCHIVE_DIR/MindfulKey-arm64.xcarchive/dSYMs/MindfulKey.app.dSYM/Contents/Resources/DWARF/MindfulKey" \
    "$ARCHIVE_DIR/MindfulKey-x86_64.xcarchive/dSYMs/MindfulKey.app.dSYM/Contents/Resources/DWARF/MindfulKey"
fi
DSYM_ZIP="$OUT_DIR/MindfulKey-$VERSION-universal.dSYM.zip"
ditto -c -k --keepParent "$DSYM_OUT" "$DSYM_ZIP"
rm -rf "$DSYM_OUT"

if [[ "${SKIP_SIGN:-0}" == "1" ]]; then
  echo ""
  echo "==> [4/6] SKIP_SIGN=1 — bỏ qua ký thật/notarize (chỉ ad-hoc từ build, KHÔNG phát hành công khai bản này)"
else
  echo ""
  echo "==> [4/6] Ký + notarize .app"
  bash scripts/sign-and-notarize.sh app "$APP_PATH"
fi

echo ""
echo "==> [5/6] Đóng .dmg + zip .app (2 asset song song, giống haynoi)"
APP_ZIP="$OUT_DIR/MindfulKey-$VERSION-universal.zip"
ditto -c -k --keepParent "$APP_PATH" "$APP_ZIP"

DMG_NAME="MindfulKey-$VERSION.dmg" VOLUME_NAME="Mindful Keyboard $VERSION" bash scripts/build-dmg.sh "$APP_PATH"
mv "$ROOT/MindfulKey-$VERSION.dmg" "$OUT_DIR/"

if [[ "${SKIP_SIGN:-0}" != "1" ]]; then
  bash scripts/sign-and-notarize.sh dmg "$OUT_DIR/MindfulKey-$VERSION.dmg"
fi

# Bản tên ổn định "MindfulKey.dmg" — link tải "bản mới nhất" không đổi qua từng version,
# giống 2 file trùng nội dung "Haynoi-0.3.7.dmg" + "Haynoi.dmg" trong ảnh tham chiếu.
cp "$OUT_DIR/MindfulKey-$VERSION.dmg" "$OUT_DIR/MindfulKey.dmg"

echo ""
echo "==> [6/6] Cắt release notes từ CHANGELOG.md"
# .md (Markdown thô) -> dùng làm GitHub Release body. .html -> để dành appcast Sparkle sau này.
RAW=1 bash scripts/changelog-to-html.sh "$VERSION" > "$OUT_DIR/release-notes.md" \
  || RAW=1 bash scripts/changelog-to-html.sh Unreleased > "$OUT_DIR/release-notes.md"
bash scripts/changelog-to-html.sh "$VERSION" > "$OUT_DIR/release-notes.html" \
  || bash scripts/changelog-to-html.sh Unreleased > "$OUT_DIR/release-notes.html"

echo ""
echo "======================================================"
echo " XONG — asset ở $OUT_DIR:"
echo "======================================================"
ls -lh "$OUT_DIR"
