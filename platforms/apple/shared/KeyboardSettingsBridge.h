//
//  KeyboardSettingsBridge.h
//  mindful-key — shared (iOS container <-> keyboard extension)
//
//  Cầu nối App Group cho 2 GIÁ TRỊ CẤU HÌNH bàn phím người dùng tự chỉnh trong màn Cài đặt
//  (story 2.3): kiểu gõ (Telex/VNI) và mức chiều cao bàn phím. TÁCH BIỆT khỏi AppGroupBridge.h
//  (chỉ 2 khoá heartbeat vận hành, sở hữu bởi story 1.6 — KHÔNG sửa file đó) và MacroBridge.h
//  (danh sách macro, story 2.4) — đúng tiền lệ "1 bridge = 1 mối quan tâm" đã áp dụng liên tiếp
//  trong repo này.
//
//  Giá trị lưu tuyệt đối KHÔNG được là nội dung gõ — chỉ int (inputType 0/1) và double
//  (heightLevel 0.0-1.0) — đúng ràng buộc riêng tư chung cho MỌI khoá App Group (xem
//  AppGroupBridge.h "TUYỆT ĐỐI không nhận/ghi bất kỳ NSString nào chứa nội dung người dùng gõ").
//
//  KHÔNG import UIKit/AppKit — thuần Foundation, để tests/ios chạy được trên host và để file
//  dùng chung được cho cả vỏ macOS lẫn iOS mà không lệ thuộc API riêng OS.
//
//  Story 2.3 CHƯA dây 2 khoá này vào bàn phím THẬT (KeyboardViewController vẫn khoá cứng
//  vInputType=Telex + chiều cao 260pt) — xem Owned Scope story 2.3, việc dây thật là công việc
//  TIẾP THEO chưa có story riêng.
//

#ifndef KeyboardSettingsBridge_h
#define KeyboardSettingsBridge_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Khớp giá trị nguyên thuỷ của vInputType bên core/engine (0=Telex, 1=VNI) — KHÔNG include
// Engine.h (container app không link core/engine, xem MacroBridge.h Dev Notes cho lý do tương tự).
typedef NS_ENUM(NSInteger, KeyboardSettingsInputType) {
    KeyboardSettingsInputTypeTelex = 0,
    KeyboardSettingsInputTypeVNI = 1,
};

// Đọc kiểu gõ đã lưu qua App Group group.vn.gnh.mindfulkey. Suite không mở được (entitlement
// thiếu/sai) hoặc chưa từng ghi -> mặc định Telex (AC #1: "mặc định Telex nếu chưa từng chỉnh").
FOUNDATION_EXPORT KeyboardSettingsInputType KeyboardSettingsBridge_ReadInputType(void);

// Ghi kiểu gõ mới — gọi ngay lúc đổi segmented (.valueChanged), không debounce (AC #4). Suite
// không mở được -> NO, không crash.
FOUNDATION_EXPORT BOOL KeyboardSettingsBridge_WriteInputType(KeyboardSettingsInputType inputType);

// Đọc mức chiều cao đã lưu (0.0-1.0). Suite không mở được, chưa từng ghi, hoặc dữ liệu hỏng
// (ngoài [0,1]) -> mặc định 0.5, mức giữa (AC #2: "mặc định = mức giữa nếu chưa từng chỉnh").
FOUNDATION_EXPORT double KeyboardSettingsBridge_ReadHeightLevel(void);

// Ghi mức chiều cao mới — gọi lúc thả tay khỏi slider (.touchUpInside/.touchUpOutside), KHÔNG
// mỗi pixel kéo (AC #3, #4). Giá trị đầu vào bị kẹp về [0,1] trước khi ghi. Suite không mở được
// -> NO.
FOUNDATION_EXPORT BOOL KeyboardSettingsBridge_WriteHeightLevel(double heightLevel);

// Hàm THUẦN: quy đổi heightLevel liên tục (0.0-1.0) sang bậc hiển thị 1-5 cho VoiceOver
// ("mức N/5", AC #5) — tách khỏi I/O thật để test được trên host không cần Simulator/entitlements
// (đúng pattern AppGroupBridge_DeriveStatus). Giá trị ngoài [0,1] bị kẹp về biên gần nhất trước
// khi quy đổi. 0.5 (mặc định) -> bậc 3 (mức giữa của 5 bậc).
FOUNDATION_EXPORT NSInteger KeyboardSettingsBridge_HeightLevelToStep(double heightLevel);

// ===== TEST-ONLY (tests/ios) =====
// Biến thể lấy TÊN SUITE làm tham số thay vì hardcode group.vn.gnh.mindfulkey — để test round-trip
// ghi/đọc thật qua NSUserDefaults mà KHÔNG đụng App Group thật trong lúc chạy test tự động (đúng
// yêu cầu Testing "giả lập suite tên khác, không phải suite thật"). Cùng logic mặc định/kẹp giá
// trị như 4 hàm public ở trên. Đúng pattern MoodBridge_FlushForTesting() (đuôi ForTesting).
FOUNDATION_EXPORT KeyboardSettingsInputType KeyboardSettingsBridge_ReadInputTypeForTesting(NSString *suiteName);
FOUNDATION_EXPORT BOOL KeyboardSettingsBridge_WriteInputTypeForTesting(NSString *suiteName, KeyboardSettingsInputType inputType);
FOUNDATION_EXPORT double KeyboardSettingsBridge_ReadHeightLevelForTesting(NSString *suiteName);
FOUNDATION_EXPORT BOOL KeyboardSettingsBridge_WriteHeightLevelForTesting(NSString *suiteName, double heightLevel);

NS_ASSUME_NONNULL_END

#endif /* KeyboardSettingsBridge_h */
