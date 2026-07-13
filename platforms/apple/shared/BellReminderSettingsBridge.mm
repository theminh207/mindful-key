//
//  BellReminderSettingsBridge.mm
//  mindful-key — shared (iOS container <-> keyboard extension, story 2.6)
//
//  Xem BellReminderSettingsBridge.h. 2 khoá App Group MỚI — KHÔNG đụng khoá heartbeat của
//  AppGroupBridge.mm, khoá macroList của MacroBridge.mm, hay 2 khoá của KeyboardSettingsBridge.mm.
//

#import "BellReminderSettingsBridge.h"
#import "AppGroupConstants.h"

// Chuỗi App Group — gom từ AppGroupConstants.h (KHÔNG lặp literal riêng), đúng tiền lệ
// KeyboardSettingsBridge.mm/MacroBridge.mm.
static NSString *const kBellReminderAppGroupSuiteName = kMindfulKeyAppGroupSuiteName;

static NSString *const kKeyBellReminderEnabled = @"bellReminderEnabled"; // BOOL
static NSString *const kKeyBellSnoozeUntil = @"bellSnoozeUntil";         // NSDate, nil = không hoãn

static const BOOL kDefaultBellReminderEnabled = YES;

// ===== Lõi thật, tham số hoá theo suite — public + ForTesting đều gọi qua đây. =====

static BOOL mk_readEnabled(NSString *suiteName) {
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:suiteName];
    if (shared == nil) {
        return kDefaultBellReminderEnabled; // Suite không mở được -> mặc định an toàn.
    }
    id raw = [shared objectForKey:kKeyBellReminderEnabled];
    if (![raw isKindOfClass:[NSNumber class]]) {
        return kDefaultBellReminderEnabled; // Chưa từng ghi -> mặc định YES.
    }
    return [(NSNumber *)raw boolValue];
}

static BOOL mk_writeEnabled(NSString *suiteName, BOOL enabled) {
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:suiteName];
    if (shared == nil) {
        return NO;
    }
    [shared setBool:enabled forKey:kKeyBellReminderEnabled];
    return YES;
}

static NSDate *mk_readSnoozeUntil(NSString *suiteName) {
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:suiteName];
    if (shared == nil) {
        return nil;
    }
    id raw = [shared objectForKey:kKeyBellSnoozeUntil];
    return [raw isKindOfClass:[NSDate class]] ? (NSDate *)raw : nil;
}

static BOOL mk_writeSnoozeUntil(NSString *suiteName, NSInteger minutes) {
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:suiteName];
    if (shared == nil) {
        return NO;
    }
    if (minutes < 0) minutes = 0;
    [shared setObject:[NSDate dateWithTimeIntervalSinceNow:(minutes * 60.0)] forKey:kKeyBellSnoozeUntil];
    return YES;
}

static BOOL mk_isSnoozedAt(NSDate *snoozeUntil, NSDate *now) {
    return snoozeUntil != nil && [now compare:snoozeUntil] == NSOrderedAscending;
}

// ===== API public (suite thật) =====

BOOL BellReminderSettingsBridge_IsEnabled(void) {
    return mk_readEnabled(kBellReminderAppGroupSuiteName);
}

BOOL BellReminderSettingsBridge_SetEnabled(BOOL enabled) {
    return mk_writeEnabled(kBellReminderAppGroupSuiteName, enabled);
}

BOOL BellReminderSettingsBridge_SnoozeForMinutes(NSInteger minutes) {
    return mk_writeSnoozeUntil(kBellReminderAppGroupSuiteName, minutes);
}

BOOL BellReminderSettingsBridge_IsSnoozedAt(NSDate *now) {
    return mk_isSnoozedAt(mk_readSnoozeUntil(kBellReminderAppGroupSuiteName), now);
}

// ===== TEST-ONLY (suite giả lập truyền vào từ tests/ios) =====

BOOL BellReminderSettingsBridge_IsEnabledForTesting(NSString *suiteName) {
    return mk_readEnabled(suiteName);
}

BOOL BellReminderSettingsBridge_SetEnabledForTesting(NSString *suiteName, BOOL enabled) {
    return mk_writeEnabled(suiteName, enabled);
}

BOOL BellReminderSettingsBridge_SnoozeForMinutesForTesting(NSString *suiteName, NSInteger minutes) {
    return mk_writeSnoozeUntil(suiteName, minutes);
}

BOOL BellReminderSettingsBridge_IsSnoozedAtForTesting(NSString *suiteName, NSDate *now) {
    return mk_isSnoozedAt(mk_readSnoozeUntil(suiteName), now);
}
