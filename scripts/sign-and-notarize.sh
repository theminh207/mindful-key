#!/usr/bin/env bash
# Placeholder — ký thật (Developer ID Application) + notarize + staple.
# CHƯA implement: cần Apple Developer Program (chủ dự án chưa đăng ký — xem docs/INSTALL.md
# và AGENT-BRIEF §6/bước 9). Bản hiện tại chỉ ký ad-hoc (CODE_SIGN_IDENTITY="-") qua
# `make build` / project.yml.
#
# Khi có Developer ID:
#   1. codesign --deep --force --options runtime --sign "Developer ID Application: ..." MindfulKey.app
#   2. ditto -c -k --keepParent MindfulKey.app MindfulKey.zip && xcrun notarytool submit ... --wait
#   3. xcrun stapler staple MindfulKey.app
#   4. Đóng gói lại DMG (scripts/build-dmg.sh) sau khi staple.

set -euo pipefail
echo "sign-and-notarize.sh: CHƯA implement — cần Apple Developer Program trước (xem docs/INSTALL.md)." >&2
exit 1
