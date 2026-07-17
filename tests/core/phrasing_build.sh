#!/usr/bin/env bash
# Regression test cho core/mood/MoodPhrasing (kể hình dạng ngày — dùng chung 3 vỏ).
# Không đụng core/ — chỉ biên dịch nó với test_phrasing.cpp qua -I.
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
MOOD="$HERE/../../core/mood"

g++ -std=c++14 -I "$MOOD" "$HERE/test_phrasing.cpp" "$MOOD/MoodPhrasing.cpp" -o "$HERE/test_phrasing"
echo "OK -> $HERE/test_phrasing"
