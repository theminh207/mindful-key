# tests/macos/

**Sở hữu:** đội macOS — test riêng vỏ macOS (`platforms/apple/macos/`). Không đụng `tests/core/`.

**Chạy:** `make test-macos` (hoặc `make test` chạy chung cả core/macos/ios).

## Test hiện có

### `mood_pipeline_build.sh` / `mood_pipeline_test.mm` — E2E tầng dữ liệu chuỗi nhịp lấy mẫu (2026-07-16)

Chuỗi thật mà popover "Ngay bây giờ" + "Hôm nay" tiêu thụ:

```
gõ từ (MoodWatchMac_OnWord) → nhịp chung (kMKMoodBeatNotification, BellMac)
→ ghi mẫu (MoodStoreMac_LogSampleEvent) → đọc lại (FetchSamplesSince/FetchTodaySamples)
```

Link **file thật** (`MoodWatchMac.mm`, `MoodStoreMac.mm`, `BellMac.mm`, `NudgeCoordinatorMac.mm`,
`core/mood/MoodBuffer.cpp`) — không stub logic, chỉ cô lập môi trường:

- **Kho:** `-DMK_TEST_STORE_DIR_ENV` + env `MK_TEST_STORE_DIR` trỏ thư mục tạm. KHÔNG dùng được
  env `HOME` như tests/ios — `NSHomeDirectory`/`URLForDirectory:` trên macOS lấy home qua
  `getpwuid`, phớt lờ `$HOME` (verify thực nghiệm 2026-07-16, xem `docs/FRICTION-LOG.md`).
- **Keychain:** đổi tên `SecItemCopyMatching`/`SecItemAdd`/`SecItemDelete` bằng `-D` macro lúc
  biên dịch → khóa AES test cố định, không đụng item thật + không bật hộp thoại xin quyền.
- Test tự **abort** nếu env không trỏ vào thư mục tạm `mk-e2e-store` (cổng an toàn 2 lớp).

8 ca: consent gate (không consent = không ghi, **không tạo file**) · nhịp chay không bịa mẫu ·
gõ êm → 1 mẫu biên độ thấp · quãng lặng giữ nguyên · từ căng → biên độ cao hơn · Flush lúc thoát ·
mã hóa at-rest (header file ≠ SQLite trần) · `BellMac_ApplySettings` lên lịch nhịp gốc.

Ca 0 tóm được bug thật ngay lần chạy đầu: các hàm ĐỌC (`FetchTodaySamples`…) tạo kho rỗng +
khóa Keychain dù chưa consent — đã vá tại `OpenWorkingDB` (MoodStoreMac.mm).

## Chưa phủ (đừng hiểu nhầm là "đã test")

- NSTimer của BellMac tick đúng `vBellInterval` phút thật (cần chờ ≥1 phút — mới chỉ kiểm timer
  đã được lên lịch qua `BellMac_NextRingDate`).
- Vẽ `EmotionRiverView` / mở popover thật / gõ qua CGEventTap thật — cần app chạy + mắt người,
  theo `bmad-output/macos/TEST-PLAN-macos-control-panel.md` và `docs/TEST_MATRIX.md`.
