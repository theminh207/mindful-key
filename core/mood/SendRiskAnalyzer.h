//
//  SendRiskAnalyzer.h
//  mindful-key — core/mood (C++ THUẦN, dùng chung mọi vỏ: macOS · iOS · Windows)
//
//  [MINDFUL] Chấm "send-risk": câu vừa gõ mà GỬI đi thì hại tới đâu? -> 1 điểm [0,1].
//  CỐ Ý không phân loại "đang cảm xúc gì" — một trục PHẲNG ↔ GỢN, đúng HIẾN CHƯƠNG §2.2.
//  Xem docs/SEND-RISK-MODEL-SPEC.md để thay lexicon bằng PhoBERT ONNX sau này.
//
//  VÌ SAO Ở ĐÂY (chủ dự án chốt 2026-07-16): trước đó lexicon+công thức tồn tại HAI bản —
//  platforms/apple/macos/MoodWatchMac.mm (gốc) và platforms/apple/shared/SendRiskAnalyzer.mm
//  (đội iOS buộc phải rút ra khi core đóng băng). Vỏ Windows sắp thành bản thứ BA.
//  bmad-output/_shared/SYNC-emotion-mechanism-v2.md §A cảnh báo: "hai vỏ ra hai điểm khác nhau,
//  sông không so được" — và hai bản đó ĐÃ trôi lệch thật (macOS coi dấu câu là dấu tách từ, iOS
//  thì không). Nay hợp nhất về đây: MỘT bản cho mọi vỏ.
//
//  HỢP ĐỒNG:
//  - THUẦN: không I/O, không mạng, không log, không API riêng OS. Nội dung câu KHÔNG rời khỏi
//    hàm này — chỉ con số risk được phép đi ra ngoài (cột trụ riêng tư).
//  - Chỉ giữ CÔNG THỨC. Popup/chuông/đếm-chuỗi-căng/cooldown là CHÍNH SÁCH RIÊNG của từng vỏ,
//    không thuộc hợp đồng này.
//  - Kể cả hạ chữ thường cũng nằm trong đây (không giao cho vỏ) — giao ra ngoài là 3 vỏ lại
//    trôi lệch lần nữa, đúng cái lỗi vừa phải đi sửa.
//
//  wchar_t rộng 4 byte trên macOS/Linux nhưng chỉ 2 byte trên Windows (MSVC). Toàn bộ chữ
//  tiếng Việt đều nằm trong BMP (<= U+FFFF) nên không có cặp thay thế (surrogate pair) —
//  xử lý theo từng đơn vị mã như dưới đây là an toàn cho CẢ HAI bề rộng.
//

#ifndef SendRiskAnalyzer_h
#define SendRiskAnalyzer_h

#include <string>

struct SendRiskResult {
    // [0,1]. 0 = không khớp từ nào. Hàm bão hoà nên không bao giờ chạm đúng 1.
    double risk;
    // Danh mục tiêu cực NẶNG NHẤT: L"giận" · L"buồn" · L"mệt" · L"lo". Rỗng nếu không có.
    // CHỈ dùng để chọn CHỮ cho câu nhắc — KHÔNG phải để dán nhãn cảm xúc lên người dùng, và
    // KHÔNG tham gia quyết định có nhắc hay không (quyết định đó thuộc về `risk`).
    std::wstring topCategory;
};

// `recentText` = cửa sổ trượt các từ gần đây đã ghép bằng khoảng trắng — đúng hình dạng
// MoodBuffer::recentText(). Chuỗi rỗng / không khớp gì -> risk = 0.0, topCategory rỗng.
SendRiskResult SendRiskAnalyzer_Analyze(const std::wstring& recentText);

// Hạ chữ thường (ASCII + toàn bộ chữ tiếng Việt dựng sẵn) và đổi dấu câu thành dấu cách.
// Phơi ra để tests/core khoá được hành vi — vỏ KHÔNG cần gọi trực tiếp.
std::wstring SendRiskAnalyzer_Normalize(const std::wstring& text);

#endif /* SendRiskAnalyzer_h */
