#!/usr/bin/env bash
# Test tự động cho cầu nối iOS (KeyboardBridge) — build + chạy trên HOST macOS (như tests/core).
# KHÔNG cần Simulator: đây là unit test logic bridge (Foundation thuần), không phải UI test.
# KHÔNG đụng core/engine/ — chỉ biên dịch nó cùng bridge + EngineKeyMap qua -I.
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$HERE/../.."
ENGINE="$ROOT/core/engine"
SHARED="$ROOT/platforms/apple/shared"
IOSEXT="$ROOT/platforms/apple/ios/KeyboardExtension"

ENGINE_SRC=("$ENGINE/Engine.cpp" "$ENGINE/Vietnamese.cpp" "$ENGINE/Macro.cpp" \
            "$ENGINE/SmartSwitchKey.cpp" "$ENGINE/ConvertTool.cpp")

# .mm -> Objective-C++, .cpp -> C++ (clang tự nhận theo đuôi). DataType.h rơi nhánh #else -> mac.h
# (host macOS) nên KEY_x + EngineKeyMap khớp nhau. -fobjc-arc cho các file .mm (bridge dùng ARC).
clang++ -std=c++14 -fobjc-arc \
  -I "$ENGINE" -I "$SHARED" -I "$IOSEXT" \
  "$HERE/bridge_test.mm" "$SHARED/EngineKeyMap.mm" "$IOSEXT/KeyboardBridge.mm" "${ENGINE_SRC[@]}" \
  -framework Foundation \
  -o "$HERE/bridge_test"
echo "OK -> $HERE/bridge_test"
