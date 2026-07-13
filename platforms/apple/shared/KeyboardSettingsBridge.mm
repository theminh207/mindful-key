//
//  KeyboardSettingsBridge.mm
//  mindful-key — shared (iOS container <-> keyboard extension)
//
//  Xem KeyboardSettingsBridge.h. 2 khoá App Group MỚI — KHÔNG đụng 2 khoá heartbeat của
//  AppGroupBridge.mm hay khoá macroList của MacroBridge.mm.
//

#import "KeyboardSettingsBridge.h"
#import "AppGroupConstants.h"
#include <math.h>

// Chuỗi App Group — gom từ AppGroupConstants.h (xem comment ở đó) thay vì lặp literal riêng,
// đúng tiền lệ MacroBridge.mm.
static NSString *const kSettingsAppGroupSuiteName = kMindfulKeyAppGroupSuiteName;

// Tên khoá riêng cho 2 giá trị cấu hình bàn phím — không trùng bất kỳ khoá nào của
// AppGroupBridge.mm (lastExtensionHeartbeatAt/lastKnownHasFullAccess) hay MacroBridge.mm (macroList).
static NSString *const kKeyInputType = @"keyboardInputType";
static NSString *const kKeyHeightLevel = @"keyboardHeightLevel";

static const KeyboardSettingsInputType kDefaultInputType = KeyboardSettingsInputTypeTelex;
static const double kDefaultHeightLevel = 0.5;

static double mk_clampHeightLevel(double value) {
    if (value < 0.0) return 0.0;
    if (value > 1.0) return 1.0;
    return value;
}

// ===== Lõi thật, tham số hoá theo suite — cả 4 hàm public lẫn 4 biến thể ForTesting đều gọi qua
// đây, chỉ khác nhau ở suite name truyền vào (thật vs giả lập cho test). =====

static KeyboardSettingsInputType mk_readInputType(NSString *suiteName) {
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:suiteName];
    if (shared == nil) {
        return kDefaultInputType; // Suite không mở được (entitlement thiếu/sai) -> mặc định an toàn.
    }
    id raw = [shared objectForKey:kKeyInputType];
    if (![raw isKindOfClass:[NSNumber class]]) {
        return kDefaultInputType; // Chưa từng ghi (AC #1: mặc định Telex).
    }
    NSInteger value = [(NSNumber *)raw integerValue];
    return (value == KeyboardSettingsInputTypeVNI) ? KeyboardSettingsInputTypeVNI
                                                    : KeyboardSettingsInputTypeTelex;
}

static BOOL mk_writeInputType(NSString *suiteName, KeyboardSettingsInputType inputType) {
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:suiteName];
    if (shared == nil) {
        return NO;
    }
    [shared setInteger:inputType forKey:kKeyInputType];
    return YES;
}

static double mk_readHeightLevel(NSString *suiteName) {
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:suiteName];
    if (shared == nil) {
        return kDefaultHeightLevel; // Suite không mở được -> mặc định an toàn.
    }
    id raw = [shared objectForKey:kKeyHeightLevel];
    if (![raw isKindOfClass:[NSNumber class]]) {
        return kDefaultHeightLevel; // Chưa từng ghi (AC #2: mặc định mức giữa).
    }
    double value = [(NSNumber *)raw doubleValue];
    if (value < 0.0 || value > 1.0) {
        return kDefaultHeightLevel; // Dữ liệu hỏng -> fallback an toàn thay vì giá trị rác.
    }
    return value;
}

static BOOL mk_writeHeightLevel(NSString *suiteName, double heightLevel) {
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:suiteName];
    if (shared == nil) {
        return NO;
    }
    [shared setDouble:mk_clampHeightLevel(heightLevel) forKey:kKeyHeightLevel];
    return YES;
}

// ===== API public (suite thật) =====

KeyboardSettingsInputType KeyboardSettingsBridge_ReadInputType(void) {
    return mk_readInputType(kSettingsAppGroupSuiteName);
}

BOOL KeyboardSettingsBridge_WriteInputType(KeyboardSettingsInputType inputType) {
    return mk_writeInputType(kSettingsAppGroupSuiteName, inputType);
}

double KeyboardSettingsBridge_ReadHeightLevel(void) {
    return mk_readHeightLevel(kSettingsAppGroupSuiteName);
}

BOOL KeyboardSettingsBridge_WriteHeightLevel(double heightLevel) {
    return mk_writeHeightLevel(kSettingsAppGroupSuiteName, heightLevel);
}

// heightLevel [0,1] -> bậc 1-5. 0.0->1, 0.25->2, 0.5->3, 0.75->4, 1.0->5 (5 bậc đều nhau).
NSInteger KeyboardSettingsBridge_HeightLevelToStep(double heightLevel) {
    double clamped = mk_clampHeightLevel(heightLevel);
    NSInteger step = (NSInteger)llround(clamped * 4.0) + 1;
    if (step < 1) step = 1;
    if (step > 5) step = 5;
    return step;
}

// ===== TEST-ONLY (suite giả lập truyền vào từ tests/ios) =====

KeyboardSettingsInputType KeyboardSettingsBridge_ReadInputTypeForTesting(NSString *suiteName) {
    return mk_readInputType(suiteName);
}

BOOL KeyboardSettingsBridge_WriteInputTypeForTesting(NSString *suiteName, KeyboardSettingsInputType inputType) {
    return mk_writeInputType(suiteName, inputType);
}

double KeyboardSettingsBridge_ReadHeightLevelForTesting(NSString *suiteName) {
    return mk_readHeightLevel(suiteName);
}

BOOL KeyboardSettingsBridge_WriteHeightLevelForTesting(NSString *suiteName, double heightLevel) {
    return mk_writeHeightLevel(suiteName, heightLevel);
}
