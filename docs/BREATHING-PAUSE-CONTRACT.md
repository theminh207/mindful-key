# Design note: hợp đồng "nhịp thở" (Breathing Pause)

> Trạng thái: **hợp đồng C++ (bước 3) VÀ UI macOS thật (bước 5) đã implement.**
> Hợp đồng: `OpenKey/Sources/OpenKey/engine/BreathingPause.h` + `.cpp`.
> UI + phát hiện "sắp gửi": `OpenKey/Sources/OpenKey/macOS/ModernKey/SendGatekeeperMac.h` + `.mm`
> (wire vào `OpenKeyCallback` trong `OpenKey.mm`, ngay sau check "đừng xử lý sự kiện tự tạo").

## 1. Vì sao cần 1 hợp đồng riêng, tách khỏi MoodWatchMac hiện có

`MoodWatchMac.mm` (bước 2) đã có cơ chế cảnh báo, nhưng đó là **cảnh báo thụ động ngay lúc gõ
xong 1 câu** (giai đoạn Sense→Remind trong vòng lặp `docs/PRD.md` §2). Feature #1 của sản phẩm —
"gác cổng trước khi GỬI" — là một khoảnh khắc **khác**: chỉ xảy ra khi vỏ macOS phát hiện người
dùng bấm Enter/nút Gửi trong 1 app chat (bước 5). Hai khoảnh khắc này:
- Có thể dùng cùng con số send-risk (từ `MoodWatchMac_LastSendRisk()`),
- Nhưng KHÔNG được gộp code, vì UI khác nhau (NSAlert/notification thụ động vs. `NSPanel` nổi
  ngay tại điểm gửi) và có thể cần ngưỡng/hành vi khác nhau sau này khi có dữ liệu thật.

`BreathingPause.h` định nghĩa hợp đồng cho khoảnh khắc thứ hai — **thuần C++, không phụ thuộc
Cocoa** — để vỏ macOS (rồi Windows sau này) implement UI riêng mà không phải đoán API.

## 2. Hợp đồng

```cpp
bool BreathingPause_Evaluate(double sendRisk, BreathingPausePrompt* outPrompt);
void BreathingPause_ReportChoice(BreathingPauseChoice choice);
```

- Vỏ gọi `BreathingPause_Evaluate` tại đúng khoảnh khắc "sắp gửi" (không phải mỗi lần gõ xong 1
  câu — chỉ khi vỏ đã tự phát hiện Enter/nút Gửi trong app allow-list, việc của bước 5).
- Trả `false` → vỏ không làm gì cả (không có "overlay rỗng").
- Trả `true` → `outPrompt` có sẵn câu chữ + thời lượng gợi ý; vỏ tự vẽ `NSPanel` (bước 5).
- `BreathingPauseChoice` (SendAnyway / Wait / Dismissed) dùng để nuôi success metrics ở bước 6 —
  KHÔNG bắt buộc vỏ phải gọi lại nếu UI chưa xong.

## 3. Cam kết không chặn cứng (điều khoản quan trọng nhất)

`BreathingPause_Evaluate` trả `true` **không có nghĩa nút Gửi bị khóa**. Đây thuần là dữ liệu để
vỏ quyết định hiển thị gì — bản thân hợp đồng không có cơ chế nào ngăn hành động gửi. Trách
nhiệm giữ đúng nguyên tắc "ma sát mềm" (`docs/PRD.md` §3 non-goals) nằm ở phía vỏ khi implement
UI thật: overlay chỉ được che tạm, nút "Vẫn gửi" luôn phải hoạt động ngay lập tức.

## 4. Câu chữ (copy) cho cộng đồng chánh niệm

Câu mặc định hiện tại: *"Khoan đã — câu này nghe có thể làm tổn thương nếu gửi. Đợi một chút,
hay vẫn gửi?"* — cố ý:
- Không phán xét ("bạn đang giận" → thay bằng "câu này nghe có thể...", nói về CÂU chứ không
  chụp mũ NGƯỜI).
- Không cảnh cáo/đe dọa hậu quả.
- Câu hỏi mở, hai lựa chọn ngang nhau (không có lựa chọn nào bị làm cho "đúng hơn").
- Sẽ cần review lại với người dùng thật cộng đồng chánh niệm ở bước 10 (beta) — copy này là bản
  nháp đầu, không phải bản chốt.

## 5. Bước 5 — implementation thật (đã xong)

File: `SendGatekeeperMac.h`/`.mm`. Cơ chế:

1. **Phát hiện "sắp gửi"** — KHÔNG dùng AX semantic "tìm nút Gửi" (dễ vỡ giữa nhiều app, đúng
   rủi ro #3 đã lường trong roadmap). Thay vào đó: bắt phím Enter/Return **không Shift** ngay
   trong `OpenKeyCallback` (CGEventTap có sẵn) + `[[NSWorkspace sharedWorkspace]
   frontmostApplication].bundleIdentifier` để biết app đang focus có nằm trong allow-list không.
2. **Allow-list hiện tại:** CHỈ 2 app đã cài & xác minh bundle id thật trên máy dev — Zalo
   (`com.vng.zalo`) và Discord (`com.hnc.Discord`, dùng để test). Messenger/Telegram (mục tiêu
   thật của sản phẩm) CHƯA cài trên máy dev nên CHƯA thêm — tránh đoán bundle id sai.
3. **Nuốt & gửi lại:** khi điều kiện đủ, `OpenKeyCallback` trả `NULL` (nuốt đúng phím Enter đó),
   hiện `NSPanel` (non-activating, không cướp focus khỏi app chat). Nếu người dùng bấm "Vẫn
   gửi" → tạo lại 1 cặp sự kiện Enter thật, gắn `myEventSource` (nguồn riêng của OpenKey) rồi
   `CGEventPost` — nhờ gắn đúng nguồn, `OpenKeyCallback` tự bỏ qua nó ở check đầu tiên, không
   lặp vô hạn tự chặn chính phím mình vừa tạo ra.
4. **Hạn chế đã biết, không giấu:** vị trí chèn check là NGAY ĐẦU `OpenKeyCallback`, TRƯỚC khi
   engine xử lý ký tự Enter đó. Nếu từ cuối cùng của câu chưa có dấu cách/dấu câu đứng trước
   (nên chưa kịp "chốt từ" qua `vOnWordCommitted`), điểm send-risk tại thời điểm bấm Enter có
   thể CHƯA tính từ đó. Đây là đánh đổi có chủ đích để không đụng vào 900+ dòng logic xử lý
   tiếng Việt hiện có trong `OpenKeyCallback` (rủi ro hồi quy quá cao so với lợi ích của việc
   xử lý hoàn hảo trường hợp biên này). Fast-follow nếu cần: để engine chốt từ cuối trước, rồi
   mới chặn ở bước gửi thực sự ra OS — phức tạp hơn nhiều, chưa cần cho MVP.
