#!/usr/bin/env bash
# Đóng gói MindfulKey.app (macOS) thành DMG thử nghiệm — chuyển thể từ package-dmg.sh
# ở repo mindful-keyboard, trỏ lại đường dẫn build mới (platforms/apple, XcodeGen scheme MindfulKey).
#
# Usage:
#   ./scripts/build-dmg.sh
#   ./scripts/build-dmg.sh /path/to/MindfulKey.app
#
# Optional environment:
#   APP_PATH=/path/to/MindfulKey.app ./scripts/build-dmg.sh
#   DMG_NAME=MyBuild.dmg ./scripts/build-dmg.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DMG_NAME="${DMG_NAME:-MindfulKey_Beta.dmg}"
DMG_PATH="$ROOT/$DMG_NAME"
VOLUME_NAME="${VOLUME_NAME:-Mindful Keyboard Beta}"
STAGING_DIR="$ROOT/.dmg-staging"

find_app() {
  if [[ $# -gt 0 && -n "${1:-}" ]]; then
    printf '%s\n' "$1"
    return
  fi

  if [[ -n "${APP_PATH:-}" ]]; then
    printf '%s\n' "$APP_PATH"
    return
  fi

  local candidates=(
    "$ROOT/platforms/apple/build/Release/MindfulKey.app"
    "$ROOT/platforms/apple/build/Debug/MindfulKey.app"
  )

  local app
  for app in "${candidates[@]}"; do
    if [[ -d "$app" ]]; then
      printf '%s\n' "$app"
      return
    fi
  done

  # xcodebuild không dùng -derivedDataPath tùy chỉnh (make build mặc định) -> sản phẩm nằm ở
  # ~/Library/Developer/Xcode/DerivedData/MindfulKey-<hash>/Build/Products/<config>/.
  local dd="$HOME/Library/Developer/Xcode/DerivedData"
  if [[ -d "$dd" ]]; then
    local found
    found="$(find "$dd" -maxdepth 1 -iname "MindfulKey-*" -exec find {} -maxdepth 4 -type d -path "*/Build/Products/Release/MindfulKey.app" \; 2>/dev/null | xargs -I{} stat -f "%m %N" {} 2>/dev/null | sort -rn | head -n 1 | cut -d' ' -f2-)"
    if [[ -n "$found" ]]; then
      printf '%s\n' "$found"
      return
    fi
    found="$(find "$dd" -maxdepth 1 -iname "MindfulKey-*" -exec find {} -maxdepth 4 -type d -path "*/Build/Products/Debug/MindfulKey.app" \; 2>/dev/null | xargs -I{} stat -f "%m %N" {} 2>/dev/null | sort -rn | head -n 1 | cut -d' ' -f2-)"
    if [[ -n "$found" ]]; then
      printf '%s\n' "$found"
      return
    fi
  fi
}

cleanup() {
  rm -rf "$STAGING_DIR"
}

trap cleanup EXIT

APP_SOURCE="$(find_app "${1:-}")"

if [[ -z "$APP_SOURCE" || ! -d "$APP_SOURCE" ]]; then
  cat >&2 <<EOF
Không tìm thấy MindfulKey.app để đóng gói.

Cách dùng:
  ./scripts/build-dmg.sh /path/to/MindfulKey.app

Hoặc:
  APP_PATH=/path/to/MindfulKey.app ./scripts/build-dmg.sh
EOF
  exit 1
fi

cleanup
rm -f "$DMG_PATH"
mkdir -p "$STAGING_DIR"

APP_BUNDLE="$(basename "$APP_SOURCE")"
cp -R "$APP_SOURCE" "$STAGING_DIR/$APP_BUNDLE"
ln -s /Applications "$STAGING_DIR/Applications"

echo "== Packaging =="
echo "App: $APP_SOURCE"
echo "DMG: $DMG_PATH"

if command -v create-dmg >/dev/null 2>&1; then
  echo "== Using create-dmg =="
  create-dmg \
    --volname "$VOLUME_NAME" \
    --window-pos 200 120 \
    --window-size 640 400 \
    --icon-size 96 \
    --icon "$APP_BUNDLE" 170 190 \
    --app-drop-link 470 190 \
    --no-internet-enable \
    "$DMG_PATH" \
    "$STAGING_DIR"
else
  echo "== create-dmg not found; using pure hdiutil fallback =="
  echo "Tip: brew install create-dmg for a nicer drag-and-drop window layout."

  hdiutil create \
    -volname "$VOLUME_NAME" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH"
fi

cleanup

echo "OK -> $DMG_PATH"
