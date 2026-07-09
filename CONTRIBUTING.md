# Đóng góp cho mindful-key

> Đọc `docs/AGENT-BRIEF.md` (hiến chương) trước. Ưu tiên **đúng tinh thần chánh niệm** hơn nhiều tính năng.

## Quy ước
- **Conventional Commits:** `feat(...)`, `fix(...)`, `docs(...)`, `chore(release): ...`.
- **SemVer:** phiên bản ở `version.env` (nguồn duy nhất); cập nhật `CHANGELOG.md` trong cùng PR.
- **Nhận diện:** mọi UI/màu/copy phải qua bài tự kiểm *"mô tả hay phán xét?"* (AGENT-BRIEF §2). KHÔNG đỏ/xanh-lá/mặt cười/gamification.
- **Engine:** `core/engine/` là LÕI BẤT KHẢ XÂM PHẠM — không sửa "mù". Mọi thay đổi phải có
  test hồi quy (`tests/engine/`, Telex/VNI/VIQR, bảng mã, tổ hợp dấu) và `diff -r` với bản
  OpenKey gốc phải giải thích được từng dòng khác biệt.
- **Riêng tư:** không log/gửi nội dung gõ. Chỉ số liệu ẩn danh nếu cần.
- **Rebrand:** đổi chuỗi hiển thị được, nhưng KHÔNG đổi tên class/hàm/biến/file kế thừa từ
  OpenKey (`OpenKeyManager`, `OpenKeyCallback`, `vTempOffOpenKey`...) hay bundle-id allow-list
  app chat trong `SendGatekeeperMac.mm` — đổi nhầm là vỡ tương thích ngược/logic gác cổng.

## Build & test (macOS)
```bash
make generate  # xcodegen generate (platforms/apple/project.yml -> MindfulKey.xcodeproj)
make test      # regression engine core (tests/engine, 5/5)
make build     # generate + xcodebuild app macOS (ký ad-hoc, Debug)
make brand     # xuất lại brand-asset từ SVG nguồn
make run       # build rồi mở app dev
```

## Harness
Việc liên quan engine/mood/platform: dùng skill `mindful-keyboard-harness` để điều phối đúng chuyên gia (`openkey-engine` / `mood-sentiment-layer` / `platform-porting`). Không sửa `core/engine/` để vá lỗi riêng 1 OS.
