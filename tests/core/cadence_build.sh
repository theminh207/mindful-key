#!/usr/bin/env bash
# Regression test cho core/mood/TypingCadence (phép đo nhịp gõ dùng chung 3 vỏ).
# Không đụng core/ — chỉ biên dịch nó với test_cadence.cpp qua -I.
#
# Như send_risk_build.sh: file này KHÔNG cần core/engine (không gõ phím thật, chỉ đếm dấu
# thời gian truyền vào), nên không cần -DLINUX / platforms shim.
#
# -Wall -Wextra CỐ Ý bật ở đây dù hai script test cũ không bật: đây là file core mới, và cổng
# chất lượng của issue #6 ghi rõ "không thêm warning compiler mới". Bật ngay từ đầu thì rẻ;
# bật sau khi đã có warning thì không ai dọn.
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
MOOD="$HERE/../../core/mood"

g++ -std=c++14 -Wall -Wextra -I "$MOOD" "$HERE/test_cadence.cpp" "$MOOD/TypingCadence.cpp" -o "$HERE/test_cadence"
echo "OK -> $HERE/test_cadence"
