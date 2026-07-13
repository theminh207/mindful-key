#!/usr/bin/env bash
# Test tự động cho lớp cảm xúc iOS (story 2.2: MoodBridge + SendRiskAnalyzer) — build + chạy
# trên HOST macOS, y hệt tests/ios/build.sh (không cần Simulator). File MỚI, không sửa build.sh
# hiện có (đó là script riêng của bridge_test.mm — story 1.2/2.1).
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$HERE/../.."
ENGINE="$ROOT/core/engine"
MOOD="$ROOT/core/mood"
SHARED="$ROOT/platforms/apple/shared"
IOSEXT="$ROOT/platforms/apple/ios/KeyboardExtension"

ENGINE_SRC=("$ENGINE/Engine.cpp" "$ENGINE/Vietnamese.cpp" "$ENGINE/Macro.cpp" \
            "$ENGINE/SmartSwitchKey.cpp" "$ENGINE/ConvertTool.cpp")

# .mm -> Objective-C++, .cpp -> C++ (clang tự nhận theo đuôi). -fobjc-arc cho các file .mm.
# Story 2.6: MoodBridge.mm giờ gọi NudgeCoordinatorIOS_RegisterSentenceRisk() ngay cạnh chỗ tính
# risk (xem NudgeCoordinatorIOS.h "NƠI GỌI") — phải link thêm NudgeCoordinatorIOS.mm (tự né UIKit
# trên host qua TARGET_OS_IPHONE) + BellReminderSettingsBridge.mm (cấu hình bật/tắt + hoãn mà
# NudgeCoordinatorIOS gọi sang), không thì thiếu symbol lúc link.
# Story 3.1: MoodBridge.mm giờ gọi thêm MoodJournalStore_LogTenseMoment() cạnh đó — phải link thêm
# MoodJournalStore.mm (+ -framework Security cho CommonCrypto/Keychain của kho đó).
clang++ -std=c++14 -fobjc-arc \
  -I "$ENGINE" -I "$MOOD" -I "$SHARED" -I "$IOSEXT" \
  "$HERE/mood_bridge_test.mm" \
  "$SHARED/EngineKeyMap.mm" "$SHARED/SendRiskAnalyzer.mm" "$SHARED/BellReminderSettingsBridge.mm" \
  "$SHARED/MoodJournalStore.mm" \
  "$IOSEXT/KeyboardBridge.mm" "$IOSEXT/MoodBridge.mm" "$IOSEXT/NudgeCoordinatorIOS.mm" \
  "$MOOD/MoodBuffer.cpp" \
  "${ENGINE_SRC[@]}" \
  -framework Foundation -framework Security \
  -o "$HERE/mood_bridge_test"
echo "OK -> $HERE/mood_bridge_test"
