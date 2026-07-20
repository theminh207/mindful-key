#!/usr/bin/env bash
# [MINDFUL] 2026-07-20 — Tạo MỘT chứng chỉ tự ký CỐ ĐỊNH để ký bản dev (make build/run/install).
#
# Vì sao: ký ad-hoc ("-") đổi "vân tay" (cdhash) mỗi lần build → macOS cấp quyền Trợ năng/Giám sát
# nhập liệu theo vân tay nên lần build sau mất quyền → phải cấp lại + gõ tiếng Việt chết. Ký bằng
# chứng chỉ CỐ ĐỊNH thì vân tay (danh tính ký) KHÔNG đổi giữa các lần build → cấp quyền MỘT lần
# dùng mãi.
#
# Phạm vi: CHỈ máy dev này. CI (GitHub Actions) không có cert → Makefile tự dò, không thấy thì rơi
# về ad-hoc như cũ. KHÔNG liên quan Developer ID / notarize (đó là chuyện PHÁT HÀNH cho máy người
# lạ, cần Apple Developer Program $99 — xem docs/RELEASE.md). Cert này KHÔNG giúp bản .dmg thoát
# "damaged"; nó chỉ để bản dev ở máy mình giữ quyền.
#
# Gỡ bỏ khi cần: Keychain Access → login → xoá chứng chỉ "MindfulKey Dev". Rồi make build tự về ad-hoc.
set -euo pipefail

NAME="MindfulKey Dev"
KEYCHAIN="$HOME/Library/Keychains/login.keychain-db"

# Dò bằng `find-identity` KHÔNG có -v: cert tự ký là CSSMERR_TP_NOT_TRUSTED nên `-v` (chỉ liệt kê
# cái "hợp lệ"/trusted) sẽ bỏ sót — nhưng codesign vẫn ký được và vân tay vẫn ổn định (đã kiểm).
if security find-identity 2>/dev/null | grep -Fq "$NAME"; then
  echo "✓ Đã có chứng chỉ \"$NAME\" trong keychain — không tạo lại."
  security find-identity 2>/dev/null | grep -F "$NAME" || true
  exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/req.cnf" <<'CNF'
[req]
distinguished_name = dn
x509_extensions    = v3
prompt             = no
[dn]
CN = MindfulKey Dev
[v3]
basicConstraints     = critical, CA:false
keyUsage             = critical, digitalSignature
extendedKeyUsage     = critical, codeSigning
CNF

echo "==> Tạo khoá + chứng chỉ tự ký (RSA 2048, hạn 10 năm)…"
openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
  -keyout "$TMP/key.pem" -out "$TMP/cert.pem" -config "$TMP/req.cnf" >/dev/null 2>&1

openssl pkcs12 -export -out "$TMP/cert.p12" -inkey "$TMP/key.pem" -in "$TMP/cert.pem" \
  -name "$NAME" -passout pass:mkdev >/dev/null 2>&1

echo "==> Nạp vào login keychain, cho phép codesign dùng khoá…"
# -T /usr/bin/codesign: thêm codesign vào ACL của khoá để lần ký không bị hỏi mật khẩu keychain.
security import "$TMP/cert.p12" -k "$KEYCHAIN" -P mkdev -T /usr/bin/codesign -T /usr/bin/security

echo ""
echo "✓ Đã tạo. Kiểm tra (hiện kèm 'CSSMERR_TP_NOT_TRUSTED' là BÌNH THƯỜNG — codesign vẫn ký được,"
echo "  vân tay bám cert nên ổn định; dòng đó chỉ nói cert chưa được tin cho Gatekeeper, mà bản dev"
echo "  local KHÔNG cần Gatekeeper):"
security find-identity 2>/dev/null | grep -F "$NAME" || { echo "✗ KHÔNG thấy — có gì đó sai."; exit 1; }
echo ""
echo "→ Bước tiếp: chạy 'make run'. Nếu macOS hỏi \"codesign muốn dùng khoá lưu trong keychain\","
echo "  bấm \"Always Allow\" (nhập mật khẩu máy) MỘT lần — sau đó không hỏi nữa."
