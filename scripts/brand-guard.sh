#!/usr/bin/env bash
# Claude PostToolUse hook — soi file vừa Edit/Write theo nhận diện NOW BRAND OS.
# Exit 2 = CHẶN (báo lại cho agent để tự sửa). Chỉ soi file UI/brand.
ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
f="$(python3 -c 'import sys,json; print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))' 2>/dev/null || true)"
[ -z "$f" ] && exit 0
# CỐ Ý không lọc đuôi file ở đây: brand_lint.py (UI_EXT) là nguồn DUY NHẤT quyết định file nào là
# bề mặt nhận diện — file không phải UI thì nó tự bỏ qua và trả 0. Trước 2026-07-17 script này
# giữ danh sách riêng, và cả nó lẫn brand_lint.py đều thiếu .cpp -> vỏ Windows lọt lưới. Ba bản
# danh sách phải-tự-nhớ-giữ-khớp là đúng mô hình đã đẻ ra bug lexicon.
out="$(python3 "$ROOT/scripts/brand_lint.py" "$f" 2>&1)"; code=$?
if [ "$code" -ne 0 ]; then
  { echo "⛔ BRAND-LINT chặn (nhận diện NOW BRAND OS — HIẾN CHƯƠNG §2, brand/tokens.json):"; echo "$out"; } >&2
  exit 2
fi
exit 0
