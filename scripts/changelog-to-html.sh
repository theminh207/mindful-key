#!/usr/bin/env bash
# Cắt đúng 1 mục trong CHANGELOG.md (theo version) và đổi Markdown -> HTML đơn giản,
# dùng làm release notes (GitHub Release body, hoặc <description> trong appcast sau này).
#
# Cách dùng:
#   scripts/changelog-to-html.sh              # dùng VERSION trong version.env
#   scripts/changelog-to-html.sh 0.1.0         # cắt đúng "## [0.1.0]"
#   scripts/changelog-to-html.sh Unreleased    # cắt "## [Unreleased]" (trước khi release.sh
#                                               # đổi tên mục này thành số version thật)
#
# Không tìm thấy mục đúng version -> fallback "## [Unreleased]" (cảnh báo ra stderr), vì
# CHANGELOG.md hiện tại của mindful-key mới chỉ có mục Unreleased (chưa cắt bản release nào).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHANGELOG="$ROOT/CHANGELOG.md"

VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
  source "$ROOT/version.env"   # đặt VERSION từ nguồn phiên bản duy nhất
fi

if [[ ! -f "$CHANGELOG" ]]; then
  echo "Không tìm thấy $CHANGELOG" >&2
  exit 1
fi

extract_section() {
  local heading="$1"
  awk -v heading="## [$heading]" '
    BEGIN { found = 0 }
    index($0, heading) == 1 { found = 1; next }
    found && index($0, "## [") == 1 { exit }
    found { print }
  ' "$CHANGELOG"
}

BODY="$(extract_section "$VERSION")"
if [[ -z "$(echo "$BODY" | tr -d '[:space:]')" ]]; then
  echo "Không thấy '## [$VERSION]' trong CHANGELOG.md — dùng tạm '## [Unreleased]'." >&2
  BODY="$(extract_section "Unreleased")"
fi

if [[ -z "$(echo "$BODY" | tr -d '[:space:]')" ]]; then
  echo "CHANGELOG.md không có mục '## [$VERSION]' lẫn '## [Unreleased]' — không có gì để cắt." >&2
  exit 1
fi

# RAW=1: in thẳng Markdown gốc, không đổi HTML — dùng cho GitHub Release body (GitHub tự
# render Markdown). Không có RAW: đổi HTML — dùng cho appcast Sparkle sau này (Sparkle
# <description> cần HTML, không nhận Markdown thô).
if [[ "${RAW:-0}" == "1" ]]; then
  echo "$BODY"
  exit 0
fi

echo "$BODY" | awk '
  function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }

  # Markdown inline -> HTML: `code`, **bold** — đủ dùng cho văn phong CHANGELOG hiện tại,
  # không cần cả bộ Markdown parser cho việc này.
  function inline(s) {
    gsub(/&/, "\\&amp;", s)
    gsub(/</, "\\&lt;", s)
    gsub(/>/, "\\&gt;", s)
    while (match(s, /\*\*[^*]+\*\*/)) {
      inner = substr(s, RSTART + 2, RLENGTH - 4)
      s = substr(s, 1, RSTART - 1) "<strong>" inner "</strong>" substr(s, RSTART + RLENGTH)
    }
    while (match(s, /`[^`]+`/)) {
      inner = substr(s, RSTART + 1, RLENGTH - 2)
      s = substr(s, 1, RSTART - 1) "<code>" inner "</code>" substr(s, RSTART + RLENGTH)
    }
    return s
  }

  function flush_li() {
    if (li_open) { print "<li>" inline(trim(li_buf)) "</li>"; li_open = 0; li_buf = "" }
  }
  function flush_ul() {
    flush_li()
    if (ul_open) { print "</ul>"; ul_open = 0 }
  }

  /^### / {
    flush_ul()
    print "<h3>" inline(trim(substr($0, 5))) "</h3>"
    next
  }
  /^- / {
    if (!ul_open) { print "<ul>"; ul_open = 1 }
    flush_li()
    li_buf = substr($0, 3)
    li_open = 1
    next
  }
  /^[ \t]*$/ {
    flush_ul()
    next
  }
  {
    if (li_open) { li_buf = li_buf " " trim($0) }
    else { flush_ul(); print "<p>" inline(trim($0)) "</p>" }
  }
  END { flush_ul() }
'
