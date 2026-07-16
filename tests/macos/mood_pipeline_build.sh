#!/usr/bin/env bash
# Build + chạy test E2E tầng dữ liệu cho chuỗi nhịp lấy mẫu macOS (xem đầu mood_pipeline_test.mm).
# Link FILE THẬT của vỏ macOS + core/mood — không stub logic, chỉ cô lập môi trường:
#   · -DSecItem*=MKTestSecItem* : đổi tên 3 hàm Keychain ngay lúc biên dịch để MoodStoreMac dùng
#     khóa test cố định — KHÔNG đụng item thật "com.mindfulkeyboard.moodstore" (tránh cả hộp
#     thoại xin quyền keychain làm treo phiên không tương tác).
#   · -DMK_TEST_STORE_DIR_ENV + env MK_TEST_STORE_DIR=thư mục tạm : mood.enc rơi vào thư mục
#     tạm, không đụng kho thật của người dùng (env HOME KHÔNG dùng được — NSHomeDirectory/
#     URLForDirectory lấy home qua getpwuid, phớt lờ $HOME). Binary app thật không định nghĩa
#     macro nên không có nhánh env này. Test tự abort nếu env không trỏ vào thư mục tạm.
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$HERE/../.."
MAC="$ROOT/platforms/apple/macos"
CORE="$ROOT/core"

clang++ -std=c++14 -fobjc-arc \
  -I "$MAC" -I "$CORE/engine" -I "$CORE/mood" \
  -DMK_TEST_STORE_DIR_ENV \
  -DDEBUG=1 \
  -DSecItemCopyMatching=MKTestSecItemCopyMatching \
  -DSecItemAdd=MKTestSecItemAdd \
  -DSecItemDelete=MKTestSecItemDelete \
  "$HERE/mood_pipeline_test.mm" \
  "$MAC/MoodWatchMac.mm" \
  "$MAC/MoodStoreMac.mm" \
  "$MAC/BellMac.mm" \
  "$MAC/NudgeCoordinatorMac.mm" \
  "$CORE/mood/MoodBuffer.cpp" "$CORE/mood/SendRiskAnalyzer.cpp" \
  -framework Cocoa -framework Security -lsqlite3 \
  -o "$HERE/mood_pipeline_test"
echo "OK -> $HERE/mood_pipeline_test"

TMPSTORE="$(mktemp -d "${TMPDIR:-/tmp}/mk-e2e-store.XXXXXX")"
trap 'rm -rf "$TMPSTORE"' EXIT
MK_TEST_STORE_DIR="$TMPSTORE" "$HERE/mood_pipeline_test"
