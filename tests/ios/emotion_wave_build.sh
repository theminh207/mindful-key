#!/usr/bin/env bash
# Test tự động cho đường cong biên độ sóng ambient iOS (story 2.5: EmotionWaveAmplitude) — build +
# chạy trên HOST macOS, y hệt tests/ios/mood_bridge_build.sh (không cần Simulator). File MỚI,
# không sửa build.sh/mood_bridge_build.sh hiện có (script riêng, đúng tiền lệ story 2.2).
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
IOSEXT="$HERE/../../platforms/apple/ios/KeyboardExtension"

# EmotionWaveAmplitude.{h,cpp} là hàm THUẦN (không UIKit/Foundation) — chỉ cần chính nó + test,
# không cần link engine/mood/bridge như bridge_test/mood_bridge_test.
clang++ -std=c++14 -fobjc-arc \
  -I "$IOSEXT" \
  "$HERE/emotion_wave_test.mm" "$IOSEXT/EmotionWaveAmplitude.cpp" \
  -framework Foundation \
  -o "$HERE/emotion_wave_test"
echo "OK -> $HERE/emotion_wave_test"
