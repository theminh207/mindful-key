#!/usr/bin/env bash
# Test tự động cho NudgeCoordinatorIOS (story 2.6: chuông nhắc nghỉ) — build + chạy trên HOST
# macOS, y hệt settings_bridge_build.sh (không cần Simulator). NudgeCoordinatorIOS.mm tự né UIKit
# qua TARGET_OS_IPHONE nên link được thẳng trên host chỉ với Foundation, không cần AudioToolbox.
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$HERE/../.."
SHARED="$ROOT/platforms/apple/shared"
IOSEXT="$ROOT/platforms/apple/ios/KeyboardExtension"

clang++ -std=c++14 -fobjc-arc \
  -I "$SHARED" -I "$IOSEXT" \
  "$HERE/nudge_coordinator_ios_test.mm" \
  "$IOSEXT/NudgeCoordinatorIOS.mm" "$SHARED/BellReminderSettingsBridge.mm" \
  -framework Foundation \
  -o "$HERE/nudge_coordinator_ios_test"
echo "OK -> $HERE/nudge_coordinator_ios_test"
