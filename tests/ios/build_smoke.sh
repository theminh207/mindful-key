#!/usr/bin/env bash
# Build-smoke iOS (story 1.8): chứng minh keyboard extension COMPILE + LINK thật cho iOS Simulator
# — bắt lỗi mà bridge test host (Foundation thuần) KHÔNG bắt được (vd API UIKit chỉ có trên iOS,
# cấu hình project.yml hỏng). KHÔNG cần Simulator boot — chỉ `build`, không `test`/không chạy.
# set -e: xcodebuild trả non-zero khi build lỗi → script exit non-zero → make test-ios gate được.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
APPLE="$HERE/../../platforms/apple"

echo "[build-smoke] xcodegen generate…"
( cd "$APPLE" && xcodegen generate >/dev/null )

echo "[build-smoke] xcodebuild MindfulKeyKeyboard -sdk iphonesimulator (quiet)…"
xcodebuild -project "$APPLE/MindfulKey.xcodeproj" -scheme MindfulKeyKeyboard \
  -sdk iphonesimulator -configuration Debug \
  CODE_SIGNING_ALLOWED=NO -quiet build

echo "[build-smoke] OK — extension build sạch cho iOS Simulator"
