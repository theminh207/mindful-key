# Agent Brief — Dự án `mindful-keyboard` (HIẾN CHƯƠNG)

> Đây là hiến chương (constitution) của dự án. Mọi quyết định kỹ thuật và thiết kế đều phải quy chiếu về nó.
> `CLAUDE.md` trích các điều bất khả xâm phạm; bản đầy đủ nằm ở đây.

---

## 0. Vai trò của Agent

Bạn là **kỹ sư trưởng kiêm người giữ nhận diện** của `mindful-keyboard` — **bộ gõ Tiếng Việt chánh niệm cho macOS** (sau đó Windows & Linux), fork lõi xử lý từ **OpenKey** (Mai Vũ Tuyên).

Nguyên tắc:
- **Chánh niệm trước, tính năng sau.** Phục vụ triết lý GNH: *quan sát, không phán xét*.
- **Kế thừa có kiểm soát.** Tái dùng engine OpenKey, ghi rõ nguồn, tuân thủ giấy phép gốc.
- **macOS là công dân hạng nhất.** Ship macOS trước, thật tốt, rồi mới port. Không làm loãng chất lượng macOS để chạy đua đa nền tảng.
- Khi mơ hồ, **hỏi người chủ dự án** thay vì tự quyết những thứ chạm nhận diện hoặc pháp lý.

## 1. Bản sắc sản phẩm
- **Tên:** mindful-keyboard (tên hiển thị tinh chỉnh sau; slug/repo giữ nguyên).
- **Định vị:** "Bộ gõ Tiếng Việt giúp bạn gõ trong tỉnh thức."
- **Nền tảng ưu tiên:** macOS (Apple Silicon + Intel, universal) → Windows → Linux.
- **Lõi kế thừa:** engine gõ Tiếng Việt OpenKey (Telex/VNI/VIQR, bảng mã, kiểm tra chính tả).
- **Khác biệt:** một lớp "chánh niệm" phủ lên trải nghiệm gõ — nhắc nhịp thở, quan sát trạng thái tâm, không gamification, không phán xét.

## 2. NGUYÊN TẮC NHẬN DIỆN — bắt buộc tuyệt đối

### 2.1 Ẩn dụ gốc: "Tâm như mặt nước"
Biểu tượng là **con sóng `~` (dấu ngã)**, *biến hình* theo trạng thái tâm:
- Mặt hồ lặng ↔ tâm tĩnh (sóng phẳng, biên độ thấp).
- Mặt hồ dậy sóng ↔ tâm động (sóng gợn mạnh, biên độ cao).
Cùng MỘT biểu tượng, biến thiên theo biên độ — không thêm mặt cười/mếu, không ký hiệu cảm xúc phụ.

### 2.2 ĐIỀU TỐI KỴ — không bao giờ vi phạm
- ❌ KHÔNG đèn giao thông đỏ/xanh lá mã hóa cảm xúc (đỏ=xấu, xanh=tốt) — ngôn ngữ phán xét.
- ❌ KHÔNG mặt cười/mếu/emoji cảm xúc chấm điểm người dùng.
- ❌ KHÔNG gamification kiểu streak/điểm/huy hiệu tạo áp lực.
- ❌ KHÔNG copy khiển trách ("Bạn đang tệ", "Hãy cố lên").

### 2.3 Thay thế đúng tinh thần
- ✅ Dùng **biên độ sóng** và **sắc độ trung tính** (thang xanh-nước/xám-đá, không bão hòa) để diễn tả trạng thái — mô tả, không đánh giá.
- ✅ Copy quan sát: "Mặt hồ đang gợn sóng", "Hơi thở đang ngắn" — nêu hiện tượng, để người dùng tự nhận biết.
- ✅ Icon app: giữ mạch `~`/dấu-ngã làm dấu ấn thị giác chủ đạo (thay vai chữ "V" trong About OpenKey bằng con sóng của mình).

> Tự kiểm mọi đề xuất UI: *"Cái này đang mô tả hay đang phán xét?"* Nếu phán xét → loại bỏ.

## 3. Kiến trúc & cấu trúc thư mục

### 3.1 Kế thừa lõi OpenKey
```
Sources/OpenKey/
├── engine/     # Lõi gõ Tiếng Việt — dùng chung mọi nền tảng (tài sản chính, giữ gần nguyên)
├── macOS/      # Lớp tích hợp macOS (IMK, menu, About)
├── win32/      # Lớp Windows
└── linux/      # Lớp Linux
```
Giữ `engine/` gần nguyên vẹn; viết lại lớp nền tảng + toàn bộ lớp trải nghiệm/nhận diện.

### 3.2 Cấu trúc đích — học theo `sonpiaz/haynoi`
```
mindful-keyboard/
├── .github/workflows/     # CI/CD: build → codesign → notarize → .dmg → release
├── Sources/MindfulKeyboard/
│   ├── engine/            # Lõi kế thừa OpenKey (ghi rõ nguồn)
│   ├── macOS/             # Ưu tiên 1
│   ├── win32/             # Ưu tiên 2
│   └── linux/             # Ưu tiên 3
├── Tests/                 # Unit test engine + logic chánh niệm
├── brand/                 # Nhận diện: icon, sóng ~, token màu, hướng dẫn
├── Resources/             # Asset app (.icns, About, chuỗi đa ngữ)
├── scripts/               # Script phát hành, đóng gói, changelog
├── site/                  # Landing page (nếu có) — đồng bộ brand/
├── project.yml            # XcodeGen: sinh .xcodeproj, tránh conflict
├── appcast.xml            # Sparkle auto-update feed
├── version.env            # Nguồn phiên bản duy nhất
├── Makefile               # Lệnh build/test/release chuẩn hoá
├── run.sh                 # Chạy nhanh bản dev
├── CHANGELOG.md           # Keep a Changelog
├── CONTRIBUTING.md
├── LICENSE                # Xem mục 6
└── README.md
```

### 3.3 Quy ước "vibe code chuẩn" bắt buộc
- **XcodeGen (`project.yml`)** thay vì commit `.xcodeproj`.
- **Sparkle + `appcast.xml`** cho tự cập nhật.
- **Universal binary** macOS: `arm64 + x86_64`, phát hành `.dmg`, `-universal.zip`, `-universal.dSYM.zip`.
- **Conventional Commits**: `feat/fix/chore(release)/docs`.
- **SemVer** với `version.env` là nguồn duy nhất.
- **CHANGELOG** cập nhật trong cùng PR phát hành.

## 4. Lộ trình nền tảng (không đảo thứ tự)
1. **macOS (MVP → hoàn thiện):** engine qua IMK, About/menu theo nhận diện sóng, pipeline release ký + notarize + DMG chạy đầu-cuối. Chỉ khi macOS ổn định mới sang bước 2.
2. **Windows:** port `win32/`, giữ nguyên `engine/`, tái dùng token nhận diện.
3. **Linux:** port `linux/` (IBus/Fcitx), tái dùng `engine/` + nhận diện.
Engine dùng chung, **không fork logic gõ** cho từng OS.

## 5. Chuẩn kỹ thuật & chất lượng
- **Test:** mọi thay đổi engine phải có test hồi quy (Telex/VNI/VIQR, bảng mã, tổ hợp dấu). Không sửa engine "mù".
- **CI phải xanh** trước merge: build macOS + test + lint.
- **Không silent-drop:** bỏ qua nền tảng/kịch bản nào phải log rõ.
- **Riêng tư mặc định:** KHÔNG gửi nội dung gõ đi đâu; analytics (nếu có) chỉ số lượng/thời lượng ẩn danh, không nội dung. Nêu rõ trong README + UI.
- **Đa ngữ:** chuỗi UI tách khỏi code, mặc định Tiếng Việt, sẵn sàng English.

## 6. Pháp lý & ghi nhận nguồn
- Đọc & xác định giấy phép OpenKey TRƯỚC dòng kế thừa đầu tiên. Chọn giấy phép `mindful-keyboard` **tương thích** và tuân thủ đầy đủ (giữ thông báo bản quyền, nêu thay đổi, kế thừa điều khoản nếu copyleft).
- Ghi nhận **Mai Vũ Tuyên / OpenKey** trong `LICENSE`, `README.md`, màn About.
- Không gỡ credit gốc; phần của mình ghi rõ "based on OpenKey".
- Giấy phép gốc không rõ → **dừng và hỏi**.
- **Kết luận đã xác minh (2026-07-08):** OpenKey = **GPL v3** → `mindful-keyboard` **phải là GPL v3**. Cần thêm `LICENSE` (GPLv3) ở root + credit (hiện chưa có).

## 7. Khởi động (những bước đầu)
1. Xác nhận giấy phép OpenKey + ghi lại kết luận (mục 6). ✅ (GPLv3 — xong)
2. Dựng khung repo theo 3.2 (project.yml, version.env, Makefile, CHANGELOG, CI skeleton) — đúng bố cục trước.
3. Đưa `engine/` OpenKey vào `Sources/MindfulKeyboard/engine/` kèm ghi nguồn.
4. Dựng lớp `macOS/` tối thiểu chạy được (Telex qua IMK).
5. Áp nhận diện sóng `~` vào icon + About, tự kiểm "mô tả hay phán xét".
6. Bật CI build macOS; xanh mới bàn release pipeline ký/notarize.
7. Chốt macOS ổn định → mở nhánh Windows.

Ở mỗi bước, ưu tiên **đúng tinh thần** hơn **nhiều tính năng**.
