#!/usr/bin/env bash
# Claude PostToolUse hook — soi file vừa Edit/Write theo nhận diện NOW BRAND OS.
# Exit 2 = CHẶN (báo lại cho agent để tự sửa). Chỉ soi file UI/brand.
ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
f="$(python3 -c 'import sys,json; print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))' 2>/dev/null || true)"
[ -z "$f" ] && exit 0
case "$f" in
  *.m|*.mm|*.swift|*.h|*.html|*.css|*.js|*.ts|*.tsx|*.kt|*.xml|*.storyboard|*.xib|*.svg) ;;
  *) exit 0 ;;
esac
out="$(python3 "$ROOT/scripts/brand_lint.py" "$f" 2>&1)"; code=$?
if [ "$code" -ne 0 ]; then
  { echo "⛔ BRAND-LINT chặn (nhận diện NOW BRAND OS — HIẾN CHƯƠNG §2, brand/tokens.json):"; echo "$out"; } >&2
  exit 2
fi
exit 0
