#!/usr/bin/env bash
# Regression test cho core/mood/CadenceWaveAmplitude (biên độ con sóng `~`, dùng chung 3 vỏ).
# Không đụng core/engine — chỉ biên dịch với test_cadence_wave.cpp qua -I.
#
# Như bell_policy_build.sh: file này KHÔNG cần core/engine (chỉ nhận cpm/thresholdCpm truyền vào),
# nên không cần -DLINUX / platforms shim.
#
# -Wall -Wextra bật ngay từ đầu, cùng lý do các script test core khác đã ghi: đây là file core
# mới, bật muộn thì không ai dọn warning cũ.
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
MOOD="$HERE/../../core/mood"

g++ -std=c++14 -Wall -Wextra -I "$MOOD" "$HERE/test_cadence_wave.cpp" "$MOOD/CadenceWaveAmplitude.cpp" -o "$HERE/test_cadence_wave"
echo "OK -> $HERE/test_cadence_wave"
