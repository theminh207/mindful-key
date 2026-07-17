#!/bin/bash
# install-macos.sh — [MINDFUL] cài MindfulKey qua Terminal, KHÔNG dính cảnh báo "damaged".
#
# Vì sao script này tồn tại (docs/INSTALL-MACOS-BETA.md): app beta chưa notarize với Apple.
# Tải .dmg bằng TRÌNH DUYỆT thì browser dán cờ kiểm dịch (com.apple.quarantine) lên file,
# và macOS chặn app ad-hoc có cờ đó bằng thông báo "damaged" (người dùng thật đã dính,
# 2026-07-17). curl KHÔNG dán cờ — nên tải qua script này thì app mở là chạy.
# Đây không phải lách kiểm tra an ninh: chỉ là không bị dán nhầm tem ngay từ đầu.
#
# Override cho test/offline (đừng dùng khi cài thật):
#   MK_DMG_FILE=/path/to/MindfulKey.dmg   — dùng file local thay vì tải
#   MK_INSTALL_DIR=/path/to/dir           — đích cài thay /Applications
#   MK_NO_OPEN=1                          — không mở app sau khi cài
set -euo pipefail

DMG_URL="${MK_DMG_URL:-https://github.com/theminh207/mindful-key/releases/latest/download/MindfulKey.dmg}"
DMG_FILE="${MK_DMG_FILE:-}"
INSTALL_DIR="${MK_INSTALL_DIR:-/Applications}"
APP_NAME="MindfulKey"

if [ -z "$INSTALL_DIR" ]; then
  echo "Thư mục cài (MK_INSTALL_DIR) đang rỗng — dừng để không ghi nhầm chỗ."
  exit 1
fi

WORK_DIR="$(mktemp -d /tmp/mindfulkey-install.XXXXXX)"
MOUNT_POINT="$WORK_DIR/mount"
mkdir -p "$MOUNT_POINT"

# Dọn dẹp trong MỌI đường thoát (kể cả lỗi giữa chừng): tháo mount rồi mới xoá thư mục tạm.
# Tháo VÔ ĐIỀU KIỆN, không kiểm qua bảng mount: /tmp là symlink tới /private/tmp nên đường dẫn
# mình đưa và đường dẫn trong bảng mount KHÔNG khớp chuỗi — kiểm bằng grep là trượt (đã dính
# thật khi test 2026-07-17: mount không được tháo, rm cào vào volume read-only). hdiutil tự
# resolve đúng; chưa mount thì lệnh fail êm qua `|| true`.
cleanup() {
  hdiutil detach "$MOUNT_POINT" -quiet -force >/dev/null 2>&1 || true
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

echo "— MindfulKey · cài đặt qua Terminal —"

if [ -z "$DMG_FILE" ]; then
  DMG_FILE="$WORK_DIR/$APP_NAME.dmg"
  echo "Đang tải bản mới nhất..."
  if ! curl -fSL --progress-bar "$DMG_URL" -o "$DMG_FILE"; then
    echo ""
    echo "Không tải được: $DMG_URL"
    echo "Có thể bản phát hành hiện tại chưa kèm tệp MindfulKey.dmg (link tên cố định chỉ sống"
    echo "từ bản phát hành có tệp đó trở đi), hoặc mạng đang trục trặc. Bạn có thể tải thủ công:"
    echo "  https://github.com/theminh207/mindful-key/releases"
    exit 1
  fi
fi

echo "Đang mở tệp cài..."
hdiutil attach "$DMG_FILE" -nobrowse -readonly -quiet -mountpoint "$MOUNT_POINT"

APP_SRC="$(/usr/bin/find "$MOUNT_POINT" -maxdepth 1 -name '*.app' -print -quit)"
if [ -z "$APP_SRC" ]; then
  echo "Không tìm thấy ứng dụng trong tệp .dmg — tệp có thể hỏng. Dừng, không cài gì."
  exit 1
fi

APP_DEST="$INSTALL_DIR/$(basename "$APP_SRC")"
# Chốt an toàn trước rm -rf: đích PHẢI là một bundle .app — không bao giờ xoá thứ khác.
case "$APP_DEST" in
  *.app) ;;
  *) echo "Đường dẫn đích bất thường ($APP_DEST) — dừng."; exit 1 ;;
esac

# Chỉ đụng tiến trình đang chạy khi cài THẬT vào /Applications — chạy test với
# MK_INSTALL_DIR riêng thì không được phép tắt app thật của người đang dùng máy.
if [ "$INSTALL_DIR" = "/Applications" ] && pgrep -x "$APP_NAME" >/dev/null 2>&1; then
  echo "Đang thoát bản $APP_NAME cũ..."
  osascript -e "tell application \"$APP_NAME\" to quit" >/dev/null 2>&1 || true
  sleep 2
  pkill -x "$APP_NAME" >/dev/null 2>&1 || true
fi

if [ -d "$APP_DEST" ]; then
  rm -rf "$APP_DEST"
fi
echo "Đang chép vào $INSTALL_DIR..."
ditto "$APP_SRC" "$APP_DEST"

# Best-effort: nếu máy này từng có bản tải-bằng-trình-duyệt (đã bị dán cờ) thì gỡ cờ luôn.
xattr -dr com.apple.quarantine "$APP_DEST" 2>/dev/null || true

echo "Xong — đã cài vào $APP_DEST"
if [ -z "${MK_NO_OPEN:-}" ]; then
  open "$APP_DEST"
fi
