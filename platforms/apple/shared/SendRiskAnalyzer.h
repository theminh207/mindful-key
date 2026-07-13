//
//  SendRiskAnalyzer.h
//  mindful-key — shared (macOS + iOS)
//
//  [MINDFUL] Story 2.2 (Approach B): hàm THUẦN tính send-risk [0,1] cho 1 đoạn văn bản gần đây.
//  Bảng lexicon + công thức RÚT NGUYÊN XI (không diễn giải lại) từ
//  platforms/apple/macos/MoodWatchMac.mm (chỉ ĐỌC để rút — file đó KHÔNG bị sửa 1 dòng). Xem
//  docs/SEND-RISK-MODEL-SPEC.md#1 cho hợp đồng risk (đơn vị [0,1], không phân loại cảm xúc).
//
//  Cố ý CHỈ giữ công thức risk — KHÔNG kèm popup/chuông/đếm-chuỗi-câu-căng/cooldown (đó là chính
//  sách riêng của vỏ macOS ở MoodWatchMac.mm, không phải 1 phần hợp đồng risk dùng chung).
//
//  Thuần Foundation (không AppKit/UIKit) — dùng chung được cho cả target macOS lẫn iOS keyboard
//  extension (platforms/apple/project.yml, cả 2 target đều liệt kê `shared/`), và test được trên
//  host không cần Simulator (theo tiền lệ KeyboardBridge.mm/AppGroupBridge.h).
//
//  Chấp nhận có chủ đích: tồn tại 2 bản lexicon (macOS gốc + bản rút này) cho tới khi đội core
//  hợp nhất vào core/mood — đã ghi FRICTION-LOG (xem story 2.2 Dev Notes).
//

#ifndef SendRiskAnalyzer_h
#define SendRiskAnalyzer_h

#include <string>

// Trả risk [0.0, 1.0] cho `recentText` (cửa sổ trượt các từ gần đây, đã ghép khoảng trắng —
// đúng hình dạng MoodBuffer::recentText()). Hàm THUẦN, không side-effect, không I/O, không log.
// Chuỗi rỗng/không khớp từ nào trong lexicon -> trả đúng 0.0 (raw = 0).
double SendRiskAnalyzer_Analyze(const std::wstring& recentText);

#endif /* SendRiskAnalyzer_h */
