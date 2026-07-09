---
name: mood-sentiment-layer
description: Thiết kế/sửa lớp đọc cảm xúc khi gõ — MoodBuffer (gom từ→câu), MoodWatcher (model sentiment + popup), mindful_bell (chuông hỏi tâm trạng), mood_journal (thống kê + gợi ý), và schema mood_log.csv. PHẢI dùng khi việc nhắc tới: bắt cảm xúc lúc gõ, nhật ký tâm trạng, cảnh báo "đang tiêu cực — có nên nhắn tin không?", model sentiment tiếng Việt (lexicon hay PhoBERT ONNX), hoặc quyền riêng tư của dữ liệu cảm xúc. KHÔNG dùng để sửa engine/ hay code riêng từng OS.
---

# Mood & Sentiment Layer

## Luồng dữ liệu (2 nửa, gộp qua 1 nhật ký)
```
BỘ NÃO (callback vOnWordCommitted, xem skill openkey-engine)
   │
   ▼
MoodBuffer (gom từ → câu, dùng chung mọi OS, thuần C++)
   │  khi gặp dấu kết câu (. ! ? / Enter) → onSentenceComplete(sentence) -> risk [0,1]
   ▼
MoodWatcher (tính "send-risk" TRÊN MÁY — hiện lexicon có trọng số, xem docs/SEND-RISK-MODEL-SPEC.md để thay PhoBERT ONNX)
   │  risk ≥ ngưỡng (0.5) → popup native nhẹ ("câu này nghe đang giận, gửi không?")
   ▼
MoodStoreMac (SQLite mã hóa AES-256-CBC, khóa Keychain — KHÔNG đồng bộ cloud ở MVP này)
   │  chỉ ghi nếu đã CONSENT — schema không có cột nào chứa câu chữ (xem docs/PRIVACY-NOTE.md)
   ▼
App chính: mindful_bell (hỏi tâm trạng theo lịch) + mood_journal (thống kê ngày + khuyến nghị)
   (vẫn dùng mood_log.csv plaintext cho demo CLI — bước 7/8 sẽ chuyển sang đọc MoodStoreMac)
```

**Send-risk, không phải phân loại cảm xúc.** Bài toán đã thu hẹp: không còn "đang cảm xúc gì"
(buồn/giận/mệt/lo) mà chỉ còn 1 câu hỏi — "câu này mà GỬI cho người khác thì hại tới đâu?" ->
1 số thực `[0,1]`. Category (giận/buồn/mệt/lo) vẫn tồn tại trong lexicon nhưng giờ chỉ là
**trọng số** đóng góp vào risk (giận≈1.0, buồn/mệt/lo≈0.35, tích cực kéo risk xuống) và để chọn
câu chữ hiển thị — không còn là output chính.

## Trạng thái hiện tại (đã implement, không còn là "phrototype thuần túy")
- **NỬA 1 — bắt lúc gõ, đã cắm vào cả 2 nơi:**
  - `prototype/mood_demo.cpp` (`analyzeSendRisk()`) — demo CLI portable, dùng để kiểm nhanh công thức risk.
  - `OpenKey/Sources/OpenKey/macOS/ModernKey/MoodWatchMac.mm` (`MoodWatchMac_LastSendRisk()`) — chạy trong app macOS thật, đã wire vào `OpenKey.xcodeproj` (xem skill `platform-porting`).
  - Cả hai dùng CHUNG công thức: trọng số theo category + hàm bão hòa `1 - e^(-raw/5)`, hard-hit (chửi thề) luôn đẩy risk lên cao (`raw = max(raw, 9.0)`).
- **Lưu trữ (bước 6, đã implement):** `MoodStoreMac.h/.mm` — SQLite mã hóa AES-256-CBC (khóa 256-bit random trong Keychain, không rời máy), bảng `mood_events` (ts, event_type, send_risk, app_bundle_id, choice, mood_label, intensity — KHÔNG có cột text). Chỉ ghi khi `MoodStoreMac_HasConsent()` — hỏi 1 lần lúc khởi động (`MoodStoreMac_AskConsentIfNeeded()`, gọi từ `AppDelegate.m`), không hỏi giữa lúc căng thẳng. Xóa toàn bộ qua menu "Xóa nhật ký cảm xúc..." hoặc `MoodStoreMac_DeleteAll()`. `SendGatekeeperMac.mm` (bước 5) đã gọi `MoodStoreMac_LogGatekeeperEvent()` mỗi khi 1 lần gác cổng được xử lý xong.
- **NỬA 2 — hỏi/lưu/thống kê** (`prototype/mindful_bell.cpp` + `prototype/mood_journal.cpp`): demo CLI vẫn dùng CSV plaintext riêng — CHƯA chuyển sang `MoodStoreMac` (bảng đã có sẵn cột `event_type='checkin'`, `mood_label`, `intensity` cho việc này khi cần).
- **Chuông data-driven (bước 7, đã implement):** `BellMac_RingForTenseStreak()` — rung khi `MoodWatchMac` phát hiện 3 câu căng thẳng liên tiếp (ngưỡng 0.35, thấp hơn ngưỡng gatekeeper 0.5 có chủ đích), không chỉ theo lịch cố định. Gộp với nhắc thụ động qua `NudgeCoordinatorMac` (cooldown 45s dùng chung — KHÔNG áp dụng cho `SendGatekeeperMac`, đó là Feature #1 luôn phải hiện). Snooze qua menu "Tạm hoãn chuông 1 giờ".
- **Màn soi lại (bước 8, đã implement):** `ReflectionScreenMac.h/.mm` + `MoodStoreMac_FetchTodaySummary()` — đọc tổng hợp trong ngày từ `MoodStoreMac` (đếm, giờ đỉnh điểm, app chủ yếu), hiện qua menu "Soi lại hôm nay...". Trọng tâm là 1 câu hỏi phản chiếu (chọn ngẫu nhiên, không phán xét) + 1 gợi ý nhỏ — số liệu chỉ là bối cảnh phụ, cố ý không làm biểu đồ/gamify.
- Chạy thử: `bash prototype/build.sh` rồi lần lượt `./prototype/mood_demo`, `printf '1\n5\n3\n5\n4\n' | ./prototype/mindful_bell`, `./prototype/mood_journal`. Build app macOS thật: xem skill `platform-porting`.

## Nguyên tắc bắt buộc
1. **On-device, không ngoại lệ.** Bộ gõ thấy MỌI phím người dùng gõ — câu gốc không bao giờ được rời khỏi máy. Chỉ dữ liệu cảm xúc đã tổng hợp (risk score, thống kê) mới đồng bộ cloud — mà MVP này mặc định KHÔNG đồng bộ cloud (zero telemetry, xem `docs/PRD.md`).
2. **Không làm chậm gõ.** Đọc send-risk = bất đồng bộ (dispatch ra khỏi CGEventTap thread, xem `g_moodQueue` trong `MoodWatchMac.mm`) + debounce, chỉ chạy ở cuối câu. Không bao giờ chen vào mạch xử lý phím của engine.
3. **Điểm mù phải nói rõ:** engine chỉ thấy chữ khi bộ gõ bật + đang ở chế độ tiếng Việt (ô mật khẩu, chế độ tiếng Anh = không thấy). Đừng thiết kế tính năng giả định "bắt được 100%".
4. **Nâng cấp model không được phá interface.** `onSentenceComplete(sentence) -> risk[0,1]` là hợp đồng cố định. Kế hoạch thay lexicon bằng PhoBERT ONNX on-device đã có spec đầy đủ ở `docs/SEND-RISK-MODEL-SPEC.md` (chưa implement, chỉ là fast-follow) — khi làm, chỉ đổi bên trong hàm tính risk, không đổi chữ ký.

## Xử lý lỗi
- Model sentiment lỗi/không tải được (khi đã thay PhoBERT) → rơi về lexicon heuristic ngay lập tức, ghi log việc rơi về, không được crash làm gián đoạn gõ phím. Chi tiết: `docs/SEND-RISK-MODEL-SPEC.md` mục 3-4.
- `mood_log.csv` hỏng/thiếu cột → báo lỗi rõ ràng trong `mood_journal`, không suy diễn số liệu giả.

## Phụ thuộc
- Hợp đồng callback `vOnWordCommitted` do skill `openkey-engine` cung cấp — nếu cần đổi chữ ký hoặc thêm điểm bắn, phối hợp qua đó, không tự sửa `engine/`.
