//
//  ThemeBridge.mm
//  mindful-key — shared (iOS container <-> keyboard extension, Round 3 Story 3.2 / màn M6)
//
//  Xem ThemeBridge.h. 1 khoá App Group MỚI — KHÔNG đụng khoá heartbeat của AppGroupBridge.mm,
//  khoá macroList của MacroBridge.mm, 2 khoá của KeyboardSettingsBridge.mm, hay 2 khoá của
//  BellReminderSettingsBridge.mm.
//

#import "ThemeBridge.h"
#import "AppGroupConstants.h"

// Chuỗi App Group — gom từ AppGroupConstants.h (KHÔNG lặp literal riêng), đúng tiền lệ
// KeyboardSettingsBridge.mm/BellReminderSettingsBridge.mm.
static NSString *const kThemeAppGroupSuiteName = kMindfulKeyAppGroupSuiteName;

static NSString *const kKeySelectedBackgroundIndex = @"themeSelectedBackgroundIndex"; // NSInteger

static const NSInteger kDefaultSelectedBackgroundIndex = 0;

// ===== Lõi thật, tham số hoá theo suite — public + ForTesting đều gọi qua đây. =====

static NSInteger mk_readSelectedBackgroundIndex(NSString *suiteName) {
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:suiteName];
    if (shared == nil) {
        return kDefaultSelectedBackgroundIndex; // Suite không mở được -> mặc định an toàn.
    }
    id raw = [shared objectForKey:kKeySelectedBackgroundIndex];
    if (![raw isKindOfClass:[NSNumber class]]) {
        return kDefaultSelectedBackgroundIndex; // Chưa từng ghi -> cảnh đầu tiên.
    }
    NSInteger value = [(NSNumber *)raw integerValue];
    if (value < 0) {
        return kDefaultSelectedBackgroundIndex; // Dữ liệu hỏng -> fallback an toàn thay vì giá trị rác.
    }
    return value;
}

static BOOL mk_writeSelectedBackgroundIndex(NSString *suiteName, NSInteger index) {
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:suiteName];
    if (shared == nil) {
        return NO;
    }
    if (index < 0) index = 0;
    [shared setInteger:index forKey:kKeySelectedBackgroundIndex];
    return YES;
}

// ===== API public (suite thật) =====

NSInteger ThemeBridge_SelectedBackgroundIndex(void) {
    return mk_readSelectedBackgroundIndex(kThemeAppGroupSuiteName);
}

BOOL ThemeBridge_SetSelectedBackgroundIndex(NSInteger index) {
    return mk_writeSelectedBackgroundIndex(kThemeAppGroupSuiteName, index);
}

// ===== TEST-ONLY (suite giả lập truyền vào từ tests/ios) =====

NSInteger ThemeBridge_SelectedBackgroundIndexForTesting(NSString *suiteName) {
    return mk_readSelectedBackgroundIndex(suiteName);
}

BOOL ThemeBridge_SetSelectedBackgroundIndexForTesting(NSString *suiteName, NSInteger index) {
    return mk_writeSelectedBackgroundIndex(suiteName, index);
}
