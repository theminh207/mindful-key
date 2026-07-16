#!/usr/bin/env bash
# Regression test cho core/mood/SendRiskAnalyzer (bộ não chấm điểm dùng chung 3 vỏ).
# Không đụng core/ — chỉ biên dịch nó với test_send_risk.cpp qua -I.
#
# Khác test_engine.cpp: file này KHÔNG cần core/engine (không gõ phím, chỉ chấm 1 chuỗi),
# nên không cần -DLINUX / platforms shim.
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
MOOD="$HERE/../../core/mood"

g++ -std=c++14 -I "$MOOD" "$HERE/test_send_risk.cpp" "$MOOD/SendRiskAnalyzer.cpp" -o "$HERE/test_send_risk"
echo "OK -> $HERE/test_send_risk"
