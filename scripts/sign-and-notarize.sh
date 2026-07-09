#!/usr/bin/env bash
# Ký thật (Developer ID Application) + notarize + staple.
#
# Cách dùng:
#   scripts/sign-and-notarize.sh app  /path/to/MindfulKey.app
#   scripts/sign-and-notarize.sh dmg  /path/to/MindfulKey.dmg
#
# "app" và "dmg" cần chạy TÁCH RIÊNG theo đúng thứ tự trong release.sh: ký+notarize+staple
# cái .app trước, RỒI mới đóng .dmg (để .dmg chứa sẵn .app đã staple), RỒI notarize+staple
# thêm chính file .dmg (Gatekeeper kiểm ticket của bản thân file .dmg khi mount, không tự suy
# ra từ ticket của .app bên trong).
#
# Biến môi trường bắt buộc (không hardcode bí mật trong script hay commit vào repo):
#   APPLE_SIGNING_IDENTITY   "Developer ID Application: Ten Cong Ty (TEAMID)"
#                            — lấy bằng: security find-identity -v -p codesigning
#   APPLE_TEAM_ID            Team ID 10 ký tự trên developer.apple.com
#
# Xác thực với notarytool — CHỌN 1 TRONG 2 cách:
#   Cách A (khuyên dùng — App Store Connect API Key, không lo hết hạn app-specific password):
#     APPLE_API_KEY_ID       Key ID
#     APPLE_API_ISSUER_ID    Issuer ID
#     APPLE_API_KEY_PATH     đường dẫn file .p8 tải từ App Store Connect
#   Cách B (Apple ID + app-specific password, tạo tại appleid.apple.com):
#     APPLE_ID               email Apple ID
#     APPLE_APP_SPECIFIC_PASSWORD
#
# Xem checklist đầy đủ (kể cả phần chỉ làm được thủ công, VD lấy cert): docs/RELEASE.md
set -euo pipefail

MODE="${1:?Cần chỉ định 'app' hoặc 'dmg'}"
TARGET="${2:?Cần đường dẫn tới .app hoặc .dmg}"

: "${APPLE_SIGNING_IDENTITY:?Thiếu APPLE_SIGNING_IDENTITY (VD: 'Developer ID Application: X (TEAMID)')}"
: "${APPLE_TEAM_ID:?Thiếu APPLE_TEAM_ID}"

if [[ ! -e "$TARGET" ]]; then
  echo "Không tìm thấy: $TARGET" >&2
  exit 1
fi

notarytool_auth_args() {
  if [[ -n "${APPLE_API_KEY_ID:-}" ]]; then
    : "${APPLE_API_ISSUER_ID:?Thiếu APPLE_API_ISSUER_ID (đi kèm APPLE_API_KEY_ID)}"
    : "${APPLE_API_KEY_PATH:?Thiếu APPLE_API_KEY_PATH (đi kèm APPLE_API_KEY_ID)}"
    echo "--key" "$APPLE_API_KEY_PATH" "--key-id" "$APPLE_API_KEY_ID" "--issuer" "$APPLE_API_ISSUER_ID"
  elif [[ -n "${APPLE_ID:-}" ]]; then
    : "${APPLE_APP_SPECIFIC_PASSWORD:?Thiếu APPLE_APP_SPECIFIC_PASSWORD (đi kèm APPLE_ID)}"
    echo "--apple-id" "$APPLE_ID" "--password" "$APPLE_APP_SPECIFIC_PASSWORD" "--team-id" "$APPLE_TEAM_ID"
  else
    echo "Thiếu thông tin xác thực notarytool — cần APPLE_API_KEY_ID (+ ISSUER + PATH) HOẶC APPLE_ID (+ APPLE_APP_SPECIFIC_PASSWORD)." >&2
    exit 1
  fi
}

submit_and_wait() {
  local submit_path="$1"
  local auth
  read -r -a auth <<< "$(notarytool_auth_args)"
  echo "==> Nộp notarize: $submit_path"
  xcrun notarytool submit "$submit_path" "${auth[@]}" --wait
}

case "$MODE" in
  app)
    echo "==> Ký (hardened runtime, timestamp): $TARGET"
    codesign --deep --force --options runtime --timestamp \
      --sign "$APPLE_SIGNING_IDENTITY" "$TARGET"

    echo "==> Verify chữ ký"
    codesign --verify --deep --strict --verbose=2 "$TARGET"

    ZIP_PATH="$(mktemp -d)/$(basename "$TARGET" .app)-for-notarize.zip"
    echo "==> Nén tạm để nộp notarize: $ZIP_PATH"
    ditto -c -k --keepParent "$TARGET" "$ZIP_PATH"

    submit_and_wait "$ZIP_PATH"
    rm -f "$ZIP_PATH"

    echo "==> Staple vé notarize vào .app"
    xcrun stapler staple "$TARGET"
    xcrun stapler validate "$TARGET"
    ;;

  dmg)
    submit_and_wait "$TARGET"
    echo "==> Staple vé notarize vào .dmg"
    xcrun stapler staple "$TARGET"
    xcrun stapler validate "$TARGET"
    ;;

  *)
    echo "MODE phải là 'app' hoặc 'dmg', nhận: $MODE" >&2
    exit 1
    ;;
esac

echo "OK -> $TARGET đã ký + notarize + staple."
