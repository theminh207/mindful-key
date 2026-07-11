//
//  AppGroupBridge.mm
//  mindful-key — shared (macOS + iOS)
//
//  Xem AppGroupBridge.h. Chỉ 2 khoá App Group, đều là dữ liệu vận hành (timestamp + bool),
//  KHÔNG bao giờ chứa nội dung gõ.
//

#import "AppGroupBridge.h"

// Chuỗi App Group đã CHỐT (Q7, 2026-07-11). PHẢI trùng byte-for-byte với chuỗi khai trong
// CẢ 2 file .entitlements (MindfulKeyiOS + KeyboardExtension) — sai 1 ký tự là
// initWithSuiteName: trả nil âm thầm, heartbeat chết lặng (không crash, không warning).
static NSString *const kAppGroupSuiteName = @"group.vn.gnh.mindfulkey";

// Tên khoá CHÍNH XÁC theo Data Model tech-spec — không tự đặt tên khác.
static NSString *const kKeyHeartbeatAt   = @"lastExtensionHeartbeatAt";   // NSDate
static NSString *const kKeyHasFullAccess = @"lastKnownHasFullAccess";     // BOOL

void KeyboardExtension_WriteHeartbeat(BOOL hasFullAccess) {
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:kAppGroupSuiteName];
    if (shared == nil) {
        // Suite không mở được (entitlement thiếu/sai) → im lặng bỏ qua. Container sẽ tự
        // fallback về hướng dẫn kích hoạt. GIỚI HẠN đã ghi ở header: không có tín hiệu ngược.
        return;
    }
    [shared setObject:[NSDate date] forKey:kKeyHeartbeatAt];
    [shared setBool:hasFullAccess forKey:kKeyHasFullAccess];
}

AppGroupKeyboardStatus AppGroupBridge_DeriveStatus(NSDate *heartbeatAt, BOOL hasFullAccess) {
    if (heartbeatAt == nil) {
        return AppGroupKeyboardStatusNeverRan;
    }
    return hasFullAccess ? AppGroupKeyboardStatusRanWithFullAccess
                         : AppGroupKeyboardStatusRanNoFullAccess;
}

AppGroupKeyboardStatus ContainerApp_ReadKeyboardStatus(void) {
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:kAppGroupSuiteName];
    if (shared == nil) {
        // Fallback an toàn: coi như chưa từng chạy (AC #6) thay vì crash.
        return AppGroupKeyboardStatusNeverRan;
    }
    id raw = [shared objectForKey:kKeyHeartbeatAt];
    NSDate *heartbeatAt = [raw isKindOfClass:[NSDate class]] ? (NSDate *)raw : nil;
    BOOL hasFullAccess = [shared boolForKey:kKeyHasFullAccess];
    return AppGroupBridge_DeriveStatus(heartbeatAt, hasFullAccess);
}
