//
//  BellReminderSettingsBridge.h
//  mindful-key — shared (iOS container <-> keyboard extension, story 2.6)
//
//  Cầu nối App Group cho 2 GIÁ TRỊ CẤU HÌNH của chuông nhắc nghỉ (story 2.6): bật/tắt +
//  tạm hoãn. TÁCH BIỆT khỏi AppGroupBridge.h (chỉ 2 khoá heartbeat vận hành, sở hữu bởi
//  story 1.6 — KHÔNG sửa file đó) và KeyboardSettingsBridge.h (kiểu gõ/chiều cao, story 2.3) —
//  đúng tiền lệ "1 bridge = 1 mối quan tâm" đã áp dụng liên tiếp trong repo này.
//
//  LÝ DO tách RIÊNG khỏi NudgeCoordinatorIOS (đếm số câu căng liên tiếp + rung, sống ở
//  platforms/apple/ios/KeyboardExtension/ — chỉ compile vào target extension): màn Cài đặt
//  (SettingsViewController, target MindfulKeyiOS — CONTAINER app) cần đọc/ghi 2 khoá này nhưng
//  KHÔNG được kéo theo phần "hiệu ứng thật" (UIImpactFeedbackGenerator + AudioServicesPlaySystemSound)
//  của NudgeCoordinatorIOS.mm vào target container (dễ vỡ: link thiếu framework AudioToolbox nếu
//  không cẩn thận, và về mặt kiến trúc container app không nên biết gì về haptic/âm của bàn phím).
//  File NÀY (Foundation thuần, không UIKit) là điểm gặp chung — cả 2 target `shared/` đều compile
//  được, NudgeCoordinatorIOS.mm (bên extension) gọi qua đây để đọc cấu hình thay vì tự làm I/O
//  App Group riêng.
//
//  Giá trị lưu tuyệt đối KHÔNG được là nội dung gõ — chỉ BOOL (enabled) và NSDate (snoozeUntil) —
//  đúng ràng buộc riêng tư chung cho MỌI khoá App Group.
//
//  KHÔNG import UIKit/AppKit — thuần Foundation, để tests/ios chạy được trên host và để file dùng
//  chung được cho cả vỏ macOS lẫn iOS mà không lệ thuộc API riêng OS.
//

#ifndef BellReminderSettingsBridge_h
#define BellReminderSettingsBridge_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Mặc định YES nếu chưa từng lưu (Tasks story 2.6: "bellReminderEnabled BOOL, default YES").
FOUNDATION_EXPORT BOOL BellReminderSettingsBridge_IsEnabled(void);
FOUNDATION_EXPORT BOOL BellReminderSettingsBridge_SetEnabled(BOOL enabled);

// "Tạm hoãn" N phút kể từ bây giờ (mirror hành vi macOS "Tạm hoãn chuông 1 giờ",
// BellMac_Snooze(60) — AppDelegate.m dòng 602). Trả NO nếu suite không mở được.
FOUNDATION_EXPORT BOOL BellReminderSettingsBridge_SnoozeForMinutes(NSInteger minutes);

// YES nếu còn đang trong thời gian hoãn tại thời điểm `now`. Dùng [NSDate date] ở call site thật;
// tham số hoá theo `now` để test được với đồng hồ giả lập.
FOUNDATION_EXPORT BOOL BellReminderSettingsBridge_IsSnoozedAt(NSDate *now);

// ===== TEST-ONLY (tests/ios) =====
// Biến thể lấy TÊN SUITE làm tham số — tránh ghi vào App Group thật lúc chạy test tự động, đúng
// pattern KeyboardSettingsBridge_*ForTesting / MoodBridge_FlushForTesting.
FOUNDATION_EXPORT BOOL BellReminderSettingsBridge_IsEnabledForTesting(NSString *suiteName);
FOUNDATION_EXPORT BOOL BellReminderSettingsBridge_SetEnabledForTesting(NSString *suiteName, BOOL enabled);
FOUNDATION_EXPORT BOOL BellReminderSettingsBridge_SnoozeForMinutesForTesting(NSString *suiteName, NSInteger minutes);
FOUNDATION_EXPORT BOOL BellReminderSettingsBridge_IsSnoozedAtForTesting(NSString *suiteName, NSDate *now);

NS_ASSUME_NONNULL_END

#endif /* BellReminderSettingsBridge_h */
