#!/usr/bin/env bash
# Regression test cho core/mood/BellPolicy (chính sách chuông dùng chung 3 vỏ).
# Không đụng core/engine — chỉ biên dịch với test_bell_policy.cpp qua -I.
#
# Như cadence_build.sh: file này KHÔNG cần core/engine (không gõ phím thật, chỉ nhận CPM/ngưỡng/
# thời điểm truyền vào), nên không cần -DLINUX / platforms shim.
#
# -Wall -Wextra bật ngay từ đầu, cùng lý do cadence_build.sh đã ghi: đây là file core mới, bật
# muộn thì không ai dọn warning cũ.
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
MOOD="$HERE/../../core/mood"

g++ -std=c++14 -Wall -Wextra -I "$MOOD" "$HERE/test_bell_policy.cpp" "$MOOD/BellPolicy.cpp" -o "$HERE/test_bell_policy"
echo "OK -> $HERE/test_bell_policy"
