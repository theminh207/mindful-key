# scripts/ — đóng gói & phát hành

Thư mục này **cố ý chỉ có 3 script** (không tính script này). Không phải mang thiếu — đây là
quyết định có chủ đích: mindful-key hiện phát hành bản **ad-hoc** (tự cài/tự test trên máy
mình), chưa ký thật với Apple. Cả dây chuyền phát hành "xịn" (ký Developer ID + notarize +
tự cập nhật) để dành tới **Bước 9** trong roadmap, khi có Apple Developer Program mới làm
thật được.

> Ví như bếp nhà: giờ mới nấu ăn cho mình nên chỉ cần dao với thớt. Bộ nồi tiệc 10 món cất
> trên gác, lấy xuống khi có khách (Bước 9). Cất gọn, không phải là quên.
 
## Đang có (chạy được với bản ad-hoc, KHÔNG cần tài khoản Apple trả phí)

| Script | Làm gì |
|---|---|
| `package_app.sh` | Build **universal binary** (chạy được cả máy chip M lẫn Intel) — build arm64 + x86_64 riêng rồi dán lại bằng `lipo`. Tắt hẳn code signing khi build nên KHÔNG cần Developer ID. Chạy: `make universal` hoặc `ARCHES="arm64 x86_64" bash scripts/package_app.sh`. |
| `build-dmg.sh` | Đóng `MindfulKey.app` (đã build) thành file `.dmg` để cài. Adapt từ `package-dmg.sh` gốc, trỏ vào đường dẫn build của XcodeGen. Tự tìm thấy app do `package_app.sh` build ra. |
| `sign-and-notarize.sh` | **Placeholder** — chạy là `exit 1` kèm hướng dẫn các bước ký thật + notarize. Chờ có Developer ID mới điền ruột. |

> **Lưu ý:** `package_app.sh` ở đây chỉ port đúng phần "build universal" trong bản haynoi gốc
> (phần không đụng tới tài khoản Apple) — KHÔNG bao gồm phần ký/notarize (bản gốc gộp chung,
> ở đây tách riêng ra `sign-and-notarize.sh` cho đúng ranh giới "cái gì cần tiền, cái gì không").

## Để dành tới Bước 9 (bản mẫu: repo haynoi)

Bản mẫu đầy đủ ở repo tham chiếu **`github.com/sonpiaz/haynoi`** (thư mục `scripts/`) — cái
mà HIẾN CHƯƠNG §3.2 nói "học theo". Khi bắt đầu ký thật, port thêm 3 script này qua (đổi
`Haynoi`→`MindfulKey`, đổi đường dẫn cho khớp cấu trúc `platforms/apple/`):

| Script | Làm gì |
|---|---|
| `make_appcast.sh` | Đổ một `<item>` (đã ký EdDSA) vào `appcast.xml` để app tự cập nhật qua Sparkle. Rào cản KHÁC hẳn 2 dòng dưới: không phải thiếu tiền mà thiếu công cụ `generate_appcast`, chỉ có sau khi gắn thư viện Sparkle vào project (việc riêng, miễn phí). |
| `changelog-to-html.sh` | Cắt phần version tương ứng trong `CHANGELOG.md` → HTML làm release-notes cho Sparkle. Không cần tiền, không cần Sparkle — nhưng đứng một mình thì vô dụng vì không ai gọi nó (make_appcast.sh gọi). |
| `release.sh` | Nhạc trưởng: gọi lần lượt package → sign/notarize → dmg (bản haynoi có ký+notarize+trang trí đẹp) → appcast. |

> **Vì sao `appcast.xml` ở gốc repo đang rỗng?** Chính vì `make_appcast.sh` — thứ đổ dữ liệu
> vào nó — nằm trong nhóm hoãn này. Cái khung có sẵn, cái máy bơm để dành. Không phải lỗi.

## KHÔNG mang qua (không hợp mindful-key)

- `deploy-site.sh` — deploy trang `haynoi.com` lên Cloudflare Pages (hard-code project "haynoi"
  + `wrangler`). mindful-key chưa có thư mục `site/`.
- `generate_sounds.py` — sinh hiệu ứng âm thanh bằng DSP cho một app đọc chính tả khác.
  mindful-key báo bằng `NSBeep`, không có `Resources/Sounds/`.

## Đọc thêm

- Bối cảnh ký / notarize / vì sao đang ad-hoc: `docs/INSTALL.md`, `docs/PRD.md §6`.
- Đích của cả dây chuyền (universal binary + Sparkle appcast): §3.3 trong `docs/AGENT-BRIEF.md`.
