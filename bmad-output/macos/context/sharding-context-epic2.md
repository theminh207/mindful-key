# Sharding context — Epic 2 "Áo mới v2 — diện mạo macOS"

> Context CHUNG cho các agent compile story 2.x. Mỗi agent đọc file này + nguồn được trích,
> rồi viết đúng 1 file `bmad-output/macos/stories/{id}.{slug}.story.md` theo template
> `story.template.md`. **Chỉ PLAN — KHÔNG viết code, không chạy test/build.** Ngôn ngữ: **Tiếng Việt**
> (định danh code/file/hàm giữ tiếng Anh). Track: BMad Method.

## 0. Luật tối cao — HIẾN CHƯƠNG (mọi story phải nhúng làm acceptance)
- KHÔNG đèn đỏ/xanh cảm xúc · KHÔNG emoji/mặt cười chấm điểm · KHÔNG gamification (streak/điểm/huy hiệu) · KHÔNG copy khiển trách.
- Nhận diện = con sóng `~` **1 hue teal, chỉ đổi biên độ**; sắc độ trung tính, không bão hòa; copy **quan sát không phán xét** ("Mặt hồ đang gợn sóng", KHÔNG "bạn đang nóng nảy").
- Riêng tư mặc định: nhật ký mã hoá at-rest (AES-256 + khoá Keychain), **không bao giờ lưu chữ đã gõ** (chỉ số điểm gợn + mốc giờ), có nút xoá + tự xoá định kỳ, consent-gate hỏi 1 lần (không hỏi giữa lúc căng).
- GPL v3, giữ credit "Mai Vũ Tuyên" byte-identical (§6).
- Mỗi story chạm copy trạng thái PHẢI có acceptance: *"gate: mô tả hay phán xét?"*.
- Chạm nhận diện/pháp lý/riêng tư mơ hồ → story ghi rõ "DỪNG-HỎI chủ dự án" ở Dev Notes, không tự quyết.
- KHÔNG đụng `core/` (bộ não C++ dùng chung — iOS đóng băng cùng). Chỉ `platforms/apple/macos/`.

## 1. Nguồn để TRÍCH (Dev Notes phải cite các mục này)
- `bmad-output/decision-log.md` entry **2026-07-13 "Diện mạo mới v2"** — 9 quyết định:
  1. Popover chia 3 tab (Hôm nay·Chuông·Bộ gõ), bỏ scroll-list.
  2. Cửa sổ quản lý 6 mục nav trái (Hôm nay·Chuông·Bộ gõ·Riêng tư·**Hệ thống**·Giới thiệu); menu tray co gọn.
  3. Cảm xúc = "dòng sông" 1 trục phẳng↔gợn, 1 hue, đổi biên độ. KHÔNG tốt/xấu, KHÔNG streak/số.
  4. Lấy mẫu: để ý liên tục trong RAM → ghi **1 số trung bình mỗi nhịp chuông** (30/60'); quãng không gõ để **TRỐNG** (không vẽ phẳng lặng giả). *(chạm riêng tư — đã đồng thuận)*
  5. Chuông = nhịp lấy mẫu (mỗi ngân = 1 điểm lên sông); **độ nhạy dùng chung** gác cổng + chuông; icon menu-bar CHỈ báo VN bật/tắt, KHÔNG báo cảm xúc.
  6. Ba chân kiềng: sóng chữ (auto) + khoảnh khắc gác cổng + **check-in 1 chạm** (3 mức sóng, tự nguyện, tự ẩn, bỏ qua vẫn ghi auto) — dùng lại 2 cột `checkin` sẵn có trong `MoodStoreMac`. *(chạm riêng tư — đã đồng thuận)*
  7. Độ nhạy = lớp diễn giải: điểm gợn thô ghi nhật ký KHÔNG đổi khi đổi độ nhạy; gác cổng có **SÀN**, không tắt hẳn. Bảng khởi hành: "gợn" khi điểm ≥ 0.6/0.5/0.4 (Ít nhạy/Vừa/Nhạy); chuông sau 5/3/2 câu gợn liên tiếp; gác cổng hỏi khi ≥ 0.6/0.5/0.45.
  8. Màn Soi lại: 4 phép tính (dòng sông · đỉnh gợn [cần ≥2 câu/nhịp] · quãng lặng dài nhất · "lặng lại" kể-thành-câu) + 4 nhịp (Nhận ra→Cho phép→Soi→Nuôi dưỡng); **câu hỏi là trung tâm** (bộ câu hỏi xoay vòng không lặp 2 ngày liền, tối đa 1 gợi ý hành động); ngày gõ ít → "hồ chưa đủ nét", không bịa.
  9. Thi công 6 bước tuần tự, mỗi bước qua cổng + chủ dự án duyệt kết quả thật.
- `bmad-output/macos/mockups-v2/ao-moi-mindful-key.html` — plan tổng thể: mockup cửa sổ 6 mục (`.screen` nav trái), bảng **"Nút cũ về chỗ ở mới"** (Điều khiển 4 tab / Gõ tắt / Chuyển mã / Thông tin → về đâu), thuật toán lấy mẫu + độ nhạy + Soi lại, cảnh báo "3 cặp nút trùng UserDefaults" + "1 bug outlet nút 'Tắt tiếng Việt khi…'".
- `bmad-output/macos/mockups-v2/mockup-v2-tabbed.html` — spec popover 3 tab (px/màu/chữ chính xác, biến JS `T.today/T.bell/T.input`).
- `bmad-output/macos/mockups-v2/soi-lai-mockup.html` — vòng Soi lại 4 nhịp.
- `bmad-output/macos/sprint-status.yaml` khối `v2_roadmap`.
- `bmad-output/macos/epics.md` → **Epic 2** (map + owned scope + thứ tự).
- Format tham chiếu: story cũ `bmad-output/macos/stories/1.4.gatekeeper-card.story.md`.

## 2. Kiến trúc THẬT (điểm chạm — cite khi viết Dev Notes)
- `PanelViewController.{h,mm}` — popover 3 tab (đã có, story 2.1).
- `SettingsWindowController` — **CHƯA có**, tạo mới ở 2.2 (cửa sổ 6 mục nav trái).
- Cửa sổ cũ tái dùng làm pane: `ViewController` (Main.storyboard, 4 tab), `MacroViewController`, `ConvertToolViewController`, `AboutViewController`. Mở qua `AppDelegate` (`onControlPanelSelected`/`onMacroSelected`/`onConvertTool`/`onAboutSelected`).
- `MoodStoreMac.{h,mm}` — SQLite mã hoá; đã có 2 cột `checkin`. Schema lấy mẫu (event_type 'sample'/'checkin') = story 2.3.
- `MoodWatchMac.mm` — đọc send-risk cuối câu; vòng lấy mẫu theo nhịp = 2.3.
- `NudgeCoordinatorMac.{h,mm}` — có `NudgeCoordinatorMac_TenseStreakTrigger()` đọc `vBellSensitivity` nhưng đang **hardcode "3"** — nối đúng độ nhạy = 2.3.
- `BellMac.{h,mm}` / `BellSettingsView.{h,mm}` — chuông + cấu hình (đã có `BellMac_PreviewSound`, `kBellSoundMuteName`, `BellMac_MinutesUntilNextRing`). Chuông chi tiết + tải tiếng = 2.5.
- `EmotionRiverView.{h,mm}` — đã có (2.1) với `setSamples:` chờ dữ liệu; nhồi dữ liệu thật = 2.4.
- `ReflectionScreenMac.{h,mm}` — màn Soi lại (đã có `FetchTodaySummary`); 4 nhịp mới = 2.4.
- `AppDelegate.m` — tray menu + wiring popover/cửa sổ.

## 3. Owned File/Module Scope theo story (khai báo CHÍNH XÁC — đây là đòn bẩy tránh chồng)
- **2.1** (done): PanelViewController, GatekeeperCardView, BellSettingsView, InputMethodCardView, EmotionRiverView, BrandControls, BellMac. *(không compile lại — chỉ ghi done)*
- **2.2**: `SettingsWindowController.{h,mm}` (mới), `AppDelegate.m` (tray + wiring "Cài đặt đầy đủ"), có thể chạm nhẹ Main.storyboard (tối thiểu). KHÔNG viết lại UI/logic của ViewController/Macro/Convert/About — chỉ nhúng.
- **2.3**: `MoodStoreMac.{h,mm}` (schema sample/checkin), `MoodWatchMac.mm` (vòng lấy mẫu), `NudgeCoordinatorMac.{h,mm}` (độ nhạy), phần độ-nhạy/check-in trong `BellSettingsView.mm`/`PanelViewController.mm`.
- **2.4**: `EmotionRiverView.mm` (nhồi dữ liệu), `ReflectionScreenMac.{h,mm}` (4 nhịp), pane "Hôm nay" trong `SettingsWindowController` + `PanelViewController`.
- **2.5**: `BellMac.{h,mm}`, `BellSettingsView.mm` (chuông chi tiết + tải tiếng), có thể thêm resource âm thanh.
- **2.6**: `MoodStoreMac.{h,mm}` (xuất CSV + tự xoá), pane "Riêng tư" trong `SettingsWindowController`.
> Các story **chồng file** (BellSettingsView 2.1/2.3/2.5; MoodStoreMac 2.3/2.6; cửa sổ 2.2/2.4/2.6) → **CHỦ Ý tuần tự** 2.2→2.3→2.4→2.5→2.6, KHÔNG song song. Ghi rõ Blocked-by trong Dependency Map.

## 4. Sizing + split
- Mỗi story ~1 dev-day (2-8h). **2.3 và 2.4 nếu vượt → chẻ đôi** ở tầng story (vd 2.3 → 2.3 store+lấy-mẫu / thêm story mới cho check-in+độ-nhạy). Nếu chẻ, ghi rõ ở đầu story + báo về orchestrator (đừng tự đặt ID trùng — orchestrator cấp ID).

## 5. Testing strategy (dự án C++/ObjC — KHÔNG có unit-test UI)
- Verify = `make build` sạch (0 warning mới) + `make test-core` xanh (chứng minh không phá bộ não) + `make brand-lint` 0 vi phạm + **mở app thật bấm-thử** (nếu sandbox thiếu quyền → NHỜ chủ dự án bấm xác nhận). Ghi rõ trong mục Testing của mỗi story. KHÔNG chạy test trong lúc PLAN — chỉ mô tả chiến lược.

## 6. Cổng chất lượng (nhúng vào Testing/AC mỗi story)
`make test-core` xanh · `xcodebuild`/`make build` 0 error + 0 warning mới · `make brand-lint` 0 · debt delta 0 · KHÔNG đụng `core/` · soát HIẾN CHƯƠNG §2.2/§2.3 · commit checkpoint (KHÔNG push).
