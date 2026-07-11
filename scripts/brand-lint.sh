#!/usr/bin/env bash
# Ràng buộc nhận diện NOW BRAND OS. Dùng: scripts/brand-lint.sh [file ...]
# Không tham số = quét toàn repo. Exit 1 nếu có vi phạm cứng.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec python3 "$ROOT/scripts/brand_lint.py" "$@"
