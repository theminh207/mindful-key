#!/usr/bin/env bash
# Regression test cho core/engine (bộ não dùng chung) — build trên macOS/Linux (g++/clang).
# Không đụng core/engine/ — chỉ biên dịch nó với test_engine.cpp qua -I.
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
ENGINE="$HERE/../../core/engine"
ENGINE_SRC=("$ENGINE/Engine.cpp" "$ENGINE/Vietnamese.cpp" "$ENGINE/Macro.cpp" "$ENGINE/SmartSwitchKey.cpp" "$ENGINE/ConvertTool.cpp")

# DataType.h: #ifdef LINUX -> linux.h | #elif _WIN32 -> win32.h | #else -> mac.h
# Trên macOS không cần định nghĩa gì thêm (rơi vào nhánh #else); Linux/WSL cần -DLINUX.
FLAG=""
[[ "$(uname)" == "Linux" ]] && FLAG=-DLINUX

g++ $FLAG -std=c++14 -I "$ENGINE" "$HERE/test_engine.cpp" "${ENGINE_SRC[@]}" -o "$HERE/test_engine"
echo "OK -> $HERE/test_engine"
