//
//  BellScheduleSettingsBridge.mm
//  mindful-key — shared (iOS container <-> keyboard extension)
//
//  Xem BellScheduleSettingsBridge.h. 6 khoá App Group MỚI — KHÔNG đụng khoá của
//  BellReminderSettingsBridge.mm, KeyboardSettingsBridge.mm, MacroBridge.mm hay AppGroupBridge.mm.
//

#import "BellScheduleSettingsBridge.h"
#import "AppGroupConstants.h"

static NSString *const kBellScheduleAppGroupSuiteName = kMindfulKeyAppGroupSuiteName;

static NSString *const kKeyBellSoundChoice = @"bellSoundChoice";   // NSInteger (BellScheduleSound)
static NSString *const kKeyBellPeriodicOn  = @"bellPeriodicOn";    // BOOL
static NSString *const kKeyBellNaturalOn   = @"bellNaturalOn";     // BOOL
static NSString *const kKeyBellReminderOn  = @"bellReminderOn";    // BOOL
static NSString *const kKeyBellHourlyOn    = @"bellHourlyOn";      // BOOL
static NSString *const kKeyBellQuietHoursOn = @"bellQuietHoursOn"; // BOOL

static const BellScheduleSound kDefaultBellSoundChoice = BellScheduleSoundBig;
static const BOOL kDefaultBellPeriodicOn = NO;
static const BOOL kDefaultBellNaturalOn = NO;
static const BOOL kDefaultBellReminderOn = NO;
static const BOOL kDefaultBellHourlyOn = NO;
static const BOOL kDefaultBellQuietHoursOn = YES;

// ===== Lõi thật, tham số hoá theo suite — public + ForTesting đều gọi qua đây. =====

static BOOL mk_readBool(NSString *suiteName, NSString *key, BOOL defaultValue) {
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:suiteName];
    if (shared == nil) {
        return defaultValue; // Suite không mở được -> mặc định an toàn.
    }
    id raw = [shared objectForKey:key];
    if (![raw isKindOfClass:[NSNumber class]]) {
        return defaultValue; // Chưa từng ghi -> mặc định.
    }
    return [(NSNumber *)raw boolValue];
}

static BOOL mk_writeBool(NSString *suiteName, NSString *key, BOOL value) {
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:suiteName];
    if (shared == nil) {
        return NO;
    }
    [shared setBool:value forKey:key];
    return YES;
}

static BellScheduleSound mk_readSoundChoice(NSString *suiteName) {
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:suiteName];
    if (shared == nil) {
        return kDefaultBellSoundChoice;
    }
    id raw = [shared objectForKey:kKeyBellSoundChoice];
    if (![raw isKindOfClass:[NSNumber class]]) {
        return kDefaultBellSoundChoice;
    }
    NSInteger value = [(NSNumber *)raw integerValue];
    return (value == BellScheduleSoundSmall) ? BellScheduleSoundSmall : BellScheduleSoundBig;
}

static BOOL mk_writeSoundChoice(NSString *suiteName, BellScheduleSound choice) {
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:suiteName];
    if (shared == nil) {
        return NO;
    }
    BellScheduleSound clamped = (choice == BellScheduleSoundSmall) ? BellScheduleSoundSmall : BellScheduleSoundBig;
    [shared setInteger:clamped forKey:kKeyBellSoundChoice];
    return YES;
}

// ===== API public (suite thật) =====

BellScheduleSound BellScheduleSettingsBridge_ReadSoundChoice(void) {
    return mk_readSoundChoice(kBellScheduleAppGroupSuiteName);
}

BOOL BellScheduleSettingsBridge_WriteSoundChoice(BellScheduleSound choice) {
    return mk_writeSoundChoice(kBellScheduleAppGroupSuiteName, choice);
}

BOOL BellScheduleSettingsBridge_IsPeriodicOn(void) {
    return mk_readBool(kBellScheduleAppGroupSuiteName, kKeyBellPeriodicOn, kDefaultBellPeriodicOn);
}

BOOL BellScheduleSettingsBridge_SetPeriodicOn(BOOL on) {
    return mk_writeBool(kBellScheduleAppGroupSuiteName, kKeyBellPeriodicOn, on);
}

BOOL BellScheduleSettingsBridge_IsNaturalOn(void) {
    return mk_readBool(kBellScheduleAppGroupSuiteName, kKeyBellNaturalOn, kDefaultBellNaturalOn);
}

BOOL BellScheduleSettingsBridge_SetNaturalOn(BOOL on) {
    return mk_writeBool(kBellScheduleAppGroupSuiteName, kKeyBellNaturalOn, on);
}

BOOL BellScheduleSettingsBridge_IsReminderOn(void) {
    return mk_readBool(kBellScheduleAppGroupSuiteName, kKeyBellReminderOn, kDefaultBellReminderOn);
}

BOOL BellScheduleSettingsBridge_SetReminderOn(BOOL on) {
    return mk_writeBool(kBellScheduleAppGroupSuiteName, kKeyBellReminderOn, on);
}

BOOL BellScheduleSettingsBridge_IsHourlyOn(void) {
    return mk_readBool(kBellScheduleAppGroupSuiteName, kKeyBellHourlyOn, kDefaultBellHourlyOn);
}

BOOL BellScheduleSettingsBridge_SetHourlyOn(BOOL on) {
    return mk_writeBool(kBellScheduleAppGroupSuiteName, kKeyBellHourlyOn, on);
}

BOOL BellScheduleSettingsBridge_IsQuietHoursOn(void) {
    return mk_readBool(kBellScheduleAppGroupSuiteName, kKeyBellQuietHoursOn, kDefaultBellQuietHoursOn);
}

BOOL BellScheduleSettingsBridge_SetQuietHoursOn(BOOL on) {
    return mk_writeBool(kBellScheduleAppGroupSuiteName, kKeyBellQuietHoursOn, on);
}

// ===== TEST-ONLY (suite giả lập truyền vào từ tests/ios) =====

BellScheduleSound BellScheduleSettingsBridge_ReadSoundChoiceForTesting(NSString *suiteName) {
    return mk_readSoundChoice(suiteName);
}

BOOL BellScheduleSettingsBridge_WriteSoundChoiceForTesting(NSString *suiteName, BellScheduleSound choice) {
    return mk_writeSoundChoice(suiteName, choice);
}

BOOL BellScheduleSettingsBridge_IsPeriodicOnForTesting(NSString *suiteName) {
    return mk_readBool(suiteName, kKeyBellPeriodicOn, kDefaultBellPeriodicOn);
}

BOOL BellScheduleSettingsBridge_SetPeriodicOnForTesting(NSString *suiteName, BOOL on) {
    return mk_writeBool(suiteName, kKeyBellPeriodicOn, on);
}

BOOL BellScheduleSettingsBridge_IsNaturalOnForTesting(NSString *suiteName) {
    return mk_readBool(suiteName, kKeyBellNaturalOn, kDefaultBellNaturalOn);
}

BOOL BellScheduleSettingsBridge_SetNaturalOnForTesting(NSString *suiteName, BOOL on) {
    return mk_writeBool(suiteName, kKeyBellNaturalOn, on);
}

BOOL BellScheduleSettingsBridge_IsReminderOnForTesting(NSString *suiteName) {
    return mk_readBool(suiteName, kKeyBellReminderOn, kDefaultBellReminderOn);
}

BOOL BellScheduleSettingsBridge_SetReminderOnForTesting(NSString *suiteName, BOOL on) {
    return mk_writeBool(suiteName, kKeyBellReminderOn, on);
}

BOOL BellScheduleSettingsBridge_IsHourlyOnForTesting(NSString *suiteName) {
    return mk_readBool(suiteName, kKeyBellHourlyOn, kDefaultBellHourlyOn);
}

BOOL BellScheduleSettingsBridge_SetHourlyOnForTesting(NSString *suiteName, BOOL on) {
    return mk_writeBool(suiteName, kKeyBellHourlyOn, on);
}

BOOL BellScheduleSettingsBridge_IsQuietHoursOnForTesting(NSString *suiteName) {
    return mk_readBool(suiteName, kKeyBellQuietHoursOn, kDefaultBellQuietHoursOn);
}

BOOL BellScheduleSettingsBridge_SetQuietHoursOnForTesting(NSString *suiteName, BOOL on) {
    return mk_writeBool(suiteName, kKeyBellQuietHoursOn, on);
}
