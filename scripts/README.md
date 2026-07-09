# scripts/ — đóng gói & phát hành

Chủ dự án đã có Apple Developer Program (dùng chung tài khoản với repo tham chiếu
`github.com/sonpiaz/haynoi`), nên dây chuyền phát hành **ký thật (Developer ID) + notarize**
đã lên hàng — không còn là "để dành tới Bước 9" nữa. Việc còn thiếu duy nhất là **auto-update
qua Sparkle** (`make_appcast.sh`), vì app chưa gắn Sparkle SDK — xem mục cuối.

## Đang có

| Script | Làm gì |
|---|---|
| `package_app.sh` | Build **universal binary** (arm64 + x86_64, dán bằng `lipo`). Tắt code signing lúc build xcodebuild — chữ ký ad-hoc thật sự chỉ được gắn ở bước ký lại cuối script (bắt buộc, vì sửa `Info.plist`/`lipo` sau khi archive đã ký sẽ làm hỏng seal — xem comment trong file). |
| `build-dmg.sh` | Đóng 1 `.app` (đường dẫn truyền vào hoặc tự dò trong `platforms/apple/build/`) thành `.dmg`. |
| `sign-and-notarize.sh` | Ký thật (Developer ID Application, hardened runtime) + nộp notarize (App Store Connect API Key hoặc Apple ID) + staple. Chạy 2 lần tách biệt trong `release.sh`: 1 lần cho `.app`, 1 lần cho `.dmg` (mỗi loại cần vé staple riêng). |
| `changelog-to-html.sh` | Cắt đúng mục `## [version]` trong `CHANGELOG.md`. Mặc định in HTML (dành cho `<description>` appcast Sparkle sau này); `RAW=1` in thẳng Markdown gốc (dùng làm GitHub Release body). |
| `release.sh` | Nhạc trưởng: test engine → build universal → xuất+dán dSYM → ký/notarize `.app` → đóng `.dmg` → ký/notarize `.dmg` → cắt changelog. Output vào `release-out/`. `SKIP_SIGN=1` để build+đóng gói ad-hoc test cục bộ, không notarize (không dùng bản này để phát hành công khai). |

`.github/workflows/release.yml` gọi `release.sh` tự động khi gắn tag `v*` rồi đăng GitHub
Release — xem checklist secrets cần cấu hình ở đầu file đó (hoặc `docs/RELEASE.md`).

## Còn thiếu — auto-update Sparkle

`make_appcast.sh` (đổ `<item>` đã ký EdDSA vào `appcast.xml`) **chưa port** — không phải vì
thiếu tiền/quyền như trước, mà vì **app chưa gắn Sparkle SDK vào `project.yml`**. Sinh
appcast bây giờ sẽ là artifact chết, không ai đọc. Khi nào cắm Sparkle vào app xong, port
`make_appcast.sh` từ `github.com/sonpiaz/haynoi` (đổi `Haynoi`→`MindfulKey`) và nối vào cuối
`release.sh`.

## KHÔNG mang qua (không hợp mindful-key)

- `deploy-site.sh` — deploy trang `haynoi.com` lên Cloudflare Pages (hard-code project "haynoi"
  + `wrangler`). mindful-key chưa có thư mục `site/`.
- `generate_sounds.py` — sinh hiệu ứng âm thanh bằng DSP cho một app đọc chính tả khác.
  mindful-key báo bằng `NSBeep`, không có `Resources/Sounds/`.

## Đọc thêm

- Checklist đầy đủ để chạy release thật (lấy cert, cấu hình secrets GitHub): `docs/RELEASE.md`.
- Bối cảnh trước khi có Developer Program: `docs/INSTALL.md`, `docs/PRD.md §6`.
- Đích của cả dây chuyền (universal binary + Sparkle appcast): §3.3 trong `docs/AGENT-BRIEF.md`.
