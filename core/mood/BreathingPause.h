//
//  BreathingPause.h
//  OpenKey
//
//  [MINDFUL] Platform-agnostic contract for the "breathing pause" gatekeeper intervention.
//  Pure C++, zero OS UI. The shell (macOS now, Windows later) owns actually drawing the
//  overlay; this header only defines WHEN to trigger it and WHAT to show, so the mood layer
//  and the shell agree on the contract without coupling to any one OS's UI toolkit.
//
//  Không nhầm với cảnh báo thụ động của MoodWatchMac (bắn ngay sau khi gõ xong 1 câu tiêu cực).
//  Đây là chốt chặn ở đúng khoảnh khắc GỬI — chỉ kích hoạt khi vỏ báo "người dùng sắp gửi"
//  trong 1 app chat đã allow-list (xem bước 5 / skill platform-porting).
//

#ifndef BreathingPause_h
#define BreathingPause_h

#include <string>

#ifdef __cplusplus

// Ngưỡng kích hoạt mặc định cho chính khoảnh khắc GỬI. Cố ý tách khỏi ngưỡng cảnh báo thụ động
// trong MoodWatchMac.mm (dù cùng giá trị 0.5 hôm nay) — hai nơi kích hoạt khác nhau trong vòng
// lặp Sense→Pause→Remind→Reflect (xem docs/PRD.md §2), có thể cần tinh chỉnh độc lập sau này.
extern const double kBreathingPauseRiskThreshold;

// Dữ liệu mood-layer đưa cho vỏ khi risk vượt ngưỡng VÀ vỏ báo "sắp gửi".
struct BreathingPausePrompt {
    double sendRisk = 0.0;          // điểm đã tính (từ MoodWatchMac_LastSendRisk() hoặc tương đương), để vỏ log/hiển thị
    std::wstring message;           // câu nhắc hiển thị trên overlay — không phán xét, không cảnh cáo
    double durationSeconds = 3.0;   // GỢI Ý thời lượng overlay tự ẩn nếu không tương tác — KHÔNG PHẢI thời gian khóa
};

// Kết quả người dùng chọn trên overlay. Vỏ báo lại cho mood-layer để dùng cho success metrics
// (docs/PRD.md §4 — "tỷ lệ pause mà người dùng chủ động sửa/không gửi"). KHÔNG bắt buộc gọi:
// nếu vỏ chưa implement UI (đúng phạm vi bước 3 này), không có gì vỡ, chỉ thiếu số liệu.
enum class BreathingPauseChoice {
    SendAnyway,  // "Vẫn gửi" — vỏ PHẢI cho gửi ngay lập tức, không nhánh nào được chặn cứng
    Wait,        // "Đợi chút" — người dùng tự chọn không gửi ngay
    Dismissed,   // overlay tự đóng/hết giờ mà không có lựa chọn rõ ràng — KHÔNG suy diễn thành Send hay Wait
};

// [MINDFUL] Vỏ gọi hàm này khi phát hiện "sắp gửi" (Enter/nút Gửi) trong app đã allow-list.
// Trả về true + điền outPrompt nếu nên hiện overlay; false nếu risk chưa tới ngưỡng (vỏ không
// làm gì cả — KHÔNG có "overlay rỗng"). Hàm này không vẽ gì; vỏ implement UI thật ở bước 5.
//
// CAM KẾT KHÔNG CHẶN CỨNG: dù trả về true, nút Gửi của app KHÔNG được vô hiệu hóa bởi lời gọi
// này — overlay chỉ là ma sát mềm chồng lên trên, người dùng luôn có thể gửi ngay nếu muốn.
bool BreathingPause_Evaluate(double sendRisk, BreathingPausePrompt* outPrompt);

// [MINDFUL] Vỏ gọi hàm này sau khi người dùng chọn (hoặc overlay tự đóng). Không bắt buộc.
void BreathingPause_ReportChoice(BreathingPauseChoice choice);

// [MINDFUL] Chỉ dùng để test/inspect (vd đo trong prototype demo) — không phải API sản phẩm.
BreathingPauseChoice BreathingPause_LastChoice();

#endif /* __cplusplus */

#endif /* BreathingPause_h */
