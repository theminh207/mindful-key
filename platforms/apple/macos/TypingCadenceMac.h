//
//  TypingCadenceMac.h
//  ModernKey
//
//  [MINDFUL] 2026-08-02 (issue #9) — vỏ macOS nối `core/mood/TypingCadence` (#6) +
//  `core/mood/BellPolicy` (#7) vào mạch chuông. Đường ống MỚI, thay thế hẳn nhánh "chuông theo
//  chuỗi câu căng thẳng" (send-risk) đã gỡ khỏi MoodWatchMac.mm/BellMac.mm:
//
//      hook bàn phím (OpenKey.mm, TỪNG PHÍM MỘT — Q3, chốt 2026-08-01)
//        → TypingCadenceMac_RegisterKeystroke(nowMs)
//        → TypingCadence::registerKeystroke + currentCPM  (RẺ, chạy thẳng trong hook — HĐ-3)
//        → BellPolicy::evaluate(cpm, threshold, nowMs, enabled, snoozed)
//        → true thì đẩy sang main queue: BellMac_RingForFastTyping() (KHÔNG phát tiếng trong hook)
//
//  HĐ-1: API dưới đây CHỈ nhận dấu thời gian — không tham số kiểu chuỗi, cùng luật với
//  core/mood/TypingCadence.h / BellPolicy.h.
//
//  HĐ-4: nơi gọi (OpenKey.mm) PHẢI tự kiểm ô mật khẩu TRƯỚC KHI gọi RegisterKeystroke, fail-closed
//  (không xác định được thì coi LÀ ô mật khẩu, không gọi). File này không biết gì về ô nhập — nó
//  không có cách nào tự kiểm, đúng tinh thần TypingCadence.h ("lớp này cố ý không biết gì về
//  ô nhập, nó không có cách nào biết").
//

#ifndef TypingCadenceMac_h
#define TypingCadenceMac_h

#ifdef __cplusplus
extern "C" {
#endif

// Gọi 1 lần lúc khởi động app (OpenKeyInit, cùng chỗ gọi MoodWatchMac_Init()).
void TypingCadenceMac_Init(void);

// [MINDFUL] HĐ-4 (issue #9) — CỔNG DUY NHẤT kiểm ô mật khẩu. Nơi gọi (OpenKey.mm) PHẢI gọi hàm
// này TRƯỚC MỖI lời gọi RegisterKeystroke và bỏ qua khi nó trả YES — fail-closed, không xác định
// được thì coi LÀ ô mật khẩu. Đặt Ở ĐÂY (không phải ngay trong OpenKey.mm) để có một chỗ ca kiểm
// host chạm tới được: OpenKey.mm kéo theo toàn bộ Engine (vKeyHookState, macro, smart-switch...),
// không link nổi vào test host chạy trên máy CI/dev; TypingCadenceMac chỉ cần Carbon.framework.
//
// IsSecureEventInputEnabled() (Carbon) hỏi thẳng hệ thống "có phiên secure input nào đang bật
// NGAY BÂY GIỜ không" — đây chính là cơ chế mà NSSecureTextField/ô mật khẩu Safari/hệ thống bật
// lên khi nhận focus, và cũng là cơ chế khiến CGEventTap của OpenKey vốn dĩ đã bị macOS chặn không
// cho thấy phím gõ trong nhiều ô mật khẩu chuẩn — cổng này là một lớp phòng thủ THÊM cho các
// trường hợp tap vẫn nhận được sự kiện.
//
// KHÔNG dùng Accessibility (AXUIElementCopyAttributeValue đọc AXTextFieldAttribute của ô đang
// focus): đó là một lời gọi IPC sang tiến trình khác — không "rẻ tới mức chạy trong hook" (HĐ-3),
// khác hẳn API Carbon này vốn chỉ đọc một cờ hệ thống nội bộ, không IPC, không cấp phát.
//
// FAIL-CLOSED (HĐ-4): IsSecureEventInputEnabled() luôn trả một Boolean thật (không có nhánh
// "không xác định được"), nên không cần thêm nhánh mặc định ở đây.
BOOL TypingCadenceMac_IsSecureFieldActive(void);

// [MINDFUL] Gọi TỪ HOOK BÀN PHÍM, TỪNG PHÍM MỘT (Q3). RẺ — TypingCadence và BellPolicy đều KHÔNG
// cấp phát/khoá/ngoại lệ (HĐ-3), nên cả phép ĐO lẫn QUYẾT ĐỊNH reo chuông chạy thẳng trong hook
// được. Chỉ dòng RING (BellMac_RingForFastTyping, việc PHÁT TIẾNG) mới bị đẩy sang main queue BÊN
// TRONG hàm này — không phải việc của nơi gọi.
//
// Nơi gọi PHẢI tự kiểm ô mật khẩu TRƯỚC (HĐ-4, fail-closed) — hàm này không biết gì về ô nhập.
void TypingCadenceMac_RegisterKeystroke(int64_t nowMs);

// [MINDFUL] Ngưỡng tham chiếu hiện hành (CPM) — MỘT nguồn đọc duy nhất, dùng chung cho cả
// BellPolicy::evaluate lẫn CadenceWaveAmplitude (khi #11 nối con sóng), để hai nơi không tự đọc
// UserDefaults rồi trôi lệch (HĐ-6). #10 chưa xây UI chọn ngưỡng nên luôn rơi về
// kCadenceWaveDefaultThresholdCPM (400.0) — HĐ-3 nói rõ đây là mặc định KHỞI ĐIỂM, không phải hằng
// cố định; #10 sẽ đọc/ghi cùng khoá UserDefaults này khi có UI thật.
double TypingCadenceMac_ThresholdCPM(void);

// CPM tại "bây giờ" (cửa sổ trượt kết thúc tại thời điểm gọi) — dùng cho con sóng khi #11 nối dây,
// để tránh dựng một instance TypingCadence thứ hai chỉ để đọc (đúng bẫy HĐ-6 "hai bản logic").
double TypingCadenceMac_CurrentCPM(void);

#ifdef __cplusplus
}
#endif

#endif /* TypingCadenceMac_h */
