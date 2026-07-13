//
//  BellScheduleSettingsBridge.h
//  mindful-key — shared (iOS container <-> keyboard extension)
//
//  Cầu nối App Group cho các LỰA CHỌN LỊCH của màn "Chuông tỉnh thức" (tab Chuông, design
//  handoff `tabChuong`): tiếng chuông (lớn/nhỏ) + 4 công tắc lịch (Định kỳ, Thưa nhặt tự nhiên,
//  Hẹn một khắc, Đầu mỗi giờ) + Giờ tĩnh lặng. TÁCH BIỆT khỏi BellReminderSettingsBridge.h (chỉ lo
//  "bật/tắt tổng + tạm hoãn" của chuông nhắc nghỉ, story 2.6 — KHÔNG sửa file đó) — đúng tiền lệ
//  "1 bridge = 1 mối quan tâm" đã áp dụng liên tiếp trong repo này (KeyboardSettingsBridge,
//  MacroBridge, BellReminderSettingsBridge).
//
//  Giá trị lưu tuyệt đối KHÔNG được là nội dung gõ — chỉ NSInteger (soundChoice 0/1) và BOOL —
//  đúng ràng buộc riêng tư chung cho MỌI khoá App Group.
//
//  THÀNH THẬT (Owned Scope của việc này): các công tắc lịch ở đây CHỈ LƯU LỰA CHỌN của người
//  dùng. Bàn phím (keyboard extension) CHƯA thật sự ngân chuông theo các lịch này — không có
//  scheduler nào đọc các khoá này để rung chuông thật. Việc dây lịch thật vào NudgeCoordinatorIOS
//  là công việc TIẾP THEO chưa có story riêng (mirror tình trạng "chưa dây thật" đã ghi nhận ở
//  KeyboardSettingsBridge.h cho kiểu gõ/chiều cao).
//
//  KHÔNG import UIKit/AppKit — thuần Foundation, để tests/ios chạy được trên host và để file dùng
//  chung được cho cả vỏ macOS lẫn iOS mà không lệ thuộc API riêng OS.
//

#ifndef BellScheduleSettingsBridge_h
#define BellScheduleSettingsBridge_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// 0 = "Chuông lớn" (Ngân sâu, lắng), 1 = "Chuông nhỏ" (Trong, nhẹ) — khớp 2 pill trong design
// `tabChuong` (`selBig`/`selSmall`). Mặc định Big nếu chưa từng chọn (khớp state gốc `bell: 'big'`
// trong design handoff).
typedef NS_ENUM(NSInteger, BellScheduleSound) {
    BellScheduleSoundBig = 0,
    BellScheduleSoundSmall = 1,
};

// ===== Tiếng chuông =====
FOUNDATION_EXPORT BellScheduleSound BellScheduleSettingsBridge_ReadSoundChoice(void);
FOUNDATION_EXPORT BOOL BellScheduleSettingsBridge_WriteSoundChoice(BellScheduleSound choice);

// ===== Lịch ngân chuông — cả 4 mặc định TẮT (design handoff: `pOn/rOn/remSet/hOn` khởi tạo false) =====

// "Định kỳ" — ngân đều theo khoảng thời gian cố định.
FOUNDATION_EXPORT BOOL BellScheduleSettingsBridge_IsPeriodicOn(void);
FOUNDATION_EXPORT BOOL BellScheduleSettingsBridge_SetPeriodicOn(BOOL on);

// "Thưa nhặt tự nhiên" — cách quãng ngẫu nhiên, không đều.
FOUNDATION_EXPORT BOOL BellScheduleSettingsBridge_IsNaturalOn(void);
FOUNDATION_EXPORT BOOL BellScheduleSettingsBridge_SetNaturalOn(BOOL on);

// "Hẹn một khắc" — vào giờ người dùng chọn trong ngày.
FOUNDATION_EXPORT BOOL BellScheduleSettingsBridge_IsReminderOn(void);
FOUNDATION_EXPORT BOOL BellScheduleSettingsBridge_SetReminderOn(BOOL on);

// "Đầu mỗi giờ" — ngân chuông lớn đầu mỗi giờ.
FOUNDATION_EXPORT BOOL BellScheduleSettingsBridge_IsHourlyOn(void);
FOUNDATION_EXPORT BOOL BellScheduleSettingsBridge_SetHourlyOn(BOOL on);

// ===== Yên tĩnh =====

// "Giờ tĩnh lặng · 22:00–06:00" — mặc định BẬT (design handoff: `qOn: true`).
FOUNDATION_EXPORT BOOL BellScheduleSettingsBridge_IsQuietHoursOn(void);
FOUNDATION_EXPORT BOOL BellScheduleSettingsBridge_SetQuietHoursOn(BOOL on);

// ===== TEST-ONLY (tests/ios) =====
// Biến thể lấy TÊN SUITE làm tham số — tránh ghi vào App Group thật lúc chạy test tự động, đúng
// pattern BellReminderSettingsBridge_*ForTesting / KeyboardSettingsBridge_*ForTesting.
FOUNDATION_EXPORT BellScheduleSound BellScheduleSettingsBridge_ReadSoundChoiceForTesting(NSString *suiteName);
FOUNDATION_EXPORT BOOL BellScheduleSettingsBridge_WriteSoundChoiceForTesting(NSString *suiteName, BellScheduleSound choice);

FOUNDATION_EXPORT BOOL BellScheduleSettingsBridge_IsPeriodicOnForTesting(NSString *suiteName);
FOUNDATION_EXPORT BOOL BellScheduleSettingsBridge_SetPeriodicOnForTesting(NSString *suiteName, BOOL on);

FOUNDATION_EXPORT BOOL BellScheduleSettingsBridge_IsNaturalOnForTesting(NSString *suiteName);
FOUNDATION_EXPORT BOOL BellScheduleSettingsBridge_SetNaturalOnForTesting(NSString *suiteName, BOOL on);

FOUNDATION_EXPORT BOOL BellScheduleSettingsBridge_IsReminderOnForTesting(NSString *suiteName);
FOUNDATION_EXPORT BOOL BellScheduleSettingsBridge_SetReminderOnForTesting(NSString *suiteName, BOOL on);

FOUNDATION_EXPORT BOOL BellScheduleSettingsBridge_IsHourlyOnForTesting(NSString *suiteName);
FOUNDATION_EXPORT BOOL BellScheduleSettingsBridge_SetHourlyOnForTesting(NSString *suiteName, BOOL on);

FOUNDATION_EXPORT BOOL BellScheduleSettingsBridge_IsQuietHoursOnForTesting(NSString *suiteName);
FOUNDATION_EXPORT BOOL BellScheduleSettingsBridge_SetQuietHoursOnForTesting(NSString *suiteName, BOOL on);

NS_ASSUME_NONNULL_END

#endif /* BellScheduleSettingsBridge_h */
