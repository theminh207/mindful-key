#!/usr/bin/env bash
# Gói bộ nhận diện CÔNG KHAI (tier ③ "brand-cho-public") → release-out/public-brand/,
# sẵn sàng copy sang repo public/release.
#
# Nguồn thật vẫn là brand/svg + brand/tokens.json (SSOT). Script này CHỈ SINH RA bản public,
# không bao giờ sửa nguồn. Chi tiết mô hình "1 nguồn → 3 đích": docs/REPO-TOPOLOGY.md.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/release-out/public-brand"
MKT="$ROOT/brand/marketing"
ICON="$ROOT/brand/appicon/png"

command -v rsvg-convert >/dev/null || { echo "Thiếu rsvg-convert → brew install librsvg"; exit 1; }

echo "① Xuất lại asset marketing từ SVG nguồn (khớp tokens.json mới nhất)…"
bash "$ROOT/brand/export-marketing.sh" >/dev/null

rm -rf "$OUT"; mkdir -p "$OUT/readme" "$OUT/icons"

echo "② Gom bản dùng cho README / trang public…"
for f in readme-hero.png social-preview.png \
         wordmark.png wordmark@2x.png wordmark-white.png wordmark-white@2x.png; do
  cp "$MKT/$f" "$OUT/readme/"
done

echo "③ Gom icon 1024 (badge README / trang store)…"
if compgen -G "$ICON/*-1024.png" >/dev/null; then
  cp "$ICON"/*-1024.png "$OUT/icons/"
else
  echo "  ⚠ Chưa có $ICON/*-1024.png — chạy 'make brand' (export-appicon.sh) trước nếu cần icon."
fi

# Nhắc: đây là bản SINH RA, đừng sửa tay ở đây.
cat > "$OUT/README.txt" <<'EOF'
Bộ nhận diện CÔNG KHAI — SINH RA TỰ ĐỘNG từ brand/ (nguồn: brand/svg + brand/tokens.json).
ĐỪNG sửa tay ở thư mục này. Muốn đổi → sửa nguồn trong repo dev rồi chạy: make public-brand
Copy nguyên thư mục này sang repo public/release (gợi ý đích: assets/brand/).
- readme/social-preview.png  → GitHub repo public › Settings › Social preview (upload, không cần commit)
- readme/readme-hero.png     → chèn đầu README repo public
- readme/wordmark*.png        → logo chữ (bản teal cho nền sáng, -white cho nền tối)
- icons/*-1024.png            → badge/store
EOF

echo
echo "XONG → $OUT"
find "$OUT" -type f | sed "s|$ROOT/||" | sort
echo
echo "Bước tiếp: copy '$OUT/' sang repo public (vd assets/brand/), rồi trỏ README + Social preview."
