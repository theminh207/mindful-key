//
//  ThemeBridge.h
//  mindful-key — shared (iOS container <-> keyboard extension, Round 3 Story 3.2 / màn M6)
//
//  Cầu nối App Group cho ĐÚNG 1 GIÁ TRỊ CẤU HÌNH: chỉ số nền bàn phím người dùng đã chọn ở màn
//  "Nền bàn phím" (KeyboardBackgroundViewController). TÁCH BIỆT khỏi AppGroupBridge.h (2 khoá
//  heartbeat vận hành, sở hữu bởi story 1.6 — KHÔNG sửa file đó), KeyboardSettingsBridge.h
//  (kiểu gõ/chiều cao, story 2.3), BellReminderSettingsBridge.h (chuông, story 2.6) và
//  MacroBridge.h (macro, story 2.4) — đúng tiền lệ "1 bridge = 1 mối quan tâm" đã áp dụng liên
//  tiếp trong repo này.
//
//  Giá trị lưu tuyệt đối KHÔNG được là nội dung gõ hay chính ảnh nền — CHỈ một NSInteger (chỉ số
//  trong danh sách cảnh nền cố định sẵn trong app) — đúng ràng buộc riêng tư chung cho MỌI khoá
//  App Group. Việc bàn phím THẬT đọc khoá này rồi tự vẽ nền (CAGradientLayer/ảnh) là công việc
//  TIẾP THEO chưa có story riêng — file này CHỈ lo lưu/đọc chỉ số, không đụng
//  KeyboardViewController hay KeyboardExtension.
//
//  KHÔNG import UIKit/AppKit — thuần Foundation, để tests/ios chạy được trên host và để file dùng
//  chung được cho cả vỏ macOS lẫn iOS mà không lệ thuộc API riêng OS.
//

#ifndef ThemeBridge_h
#define ThemeBridge_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Đọc chỉ số nền đã lưu qua App Group group.vn.gnh.mindfulkey. Suite không mở được (entitlement
// thiếu/sai), chưa từng ghi, hoặc dữ liệu âm -> mặc định 0 (cảnh đầu tiên trong lưới).
FOUNDATION_EXPORT NSInteger ThemeBridge_SelectedBackgroundIndex(void);

// Ghi chỉ số nền mới — gọi ngay lúc chạm 1 ô trong lưới (không có nút "Lưu" tổng, đúng tinh thần
// "áp dụng ngay" đã dùng ở KeyboardSettingsBridge/BellReminderSettingsBridge). Giá trị âm bị kẹp
// về 0 trước khi ghi. Suite không mở được -> NO, không crash.
FOUNDATION_EXPORT BOOL ThemeBridge_SetSelectedBackgroundIndex(NSInteger index);

// ===== TEST-ONLY (tests/ios) =====
// Biến thể lấy TÊN SUITE làm tham số — tránh ghi vào App Group thật lúc chạy test tự động, đúng
// pattern KeyboardSettingsBridge_*ForTesting / BellReminderSettingsBridge_*ForTesting.
FOUNDATION_EXPORT NSInteger ThemeBridge_SelectedBackgroundIndexForTesting(NSString *suiteName);
FOUNDATION_EXPORT BOOL ThemeBridge_SetSelectedBackgroundIndexForTesting(NSString *suiteName, NSInteger index);

NS_ASSUME_NONNULL_END

#endif /* ThemeBridge_h */
