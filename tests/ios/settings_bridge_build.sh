#!/usr/bin/env bash
# Test tự động cho KeyboardSettingsBridge (story 2.3: kiểu gõ + chiều cao bàn phím) — build + chạy
# trên HOST macOS, y hệt mood_bridge_build.sh (không cần Simulator). Bridge này thuần Foundation
# (không đụng core/engine) nên không cần link engine sources.
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$HERE/../.."
SHARED="$ROOT/platforms/apple/shared"

clang++ -std=c++14 -fobjc-arc \
  -I "$SHARED" \
  "$HERE/settings_bridge_test.mm" "$SHARED/KeyboardSettingsBridge.mm" \
  -framework Foundation \
  -o "$HERE/settings_bridge_test"
echo "OK -> $HERE/settings_bridge_test"
