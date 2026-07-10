//
//  NudgeCoordinatorMac.mm
//  ModernKey
//
//  [MINDFUL] Xem NudgeCoordinatorMac.h.
//

#import <Foundation/Foundation.h>
#include "NudgeCoordinatorMac.h"

static const NSTimeInterval kCooldownSeconds = 45.0;
static NSTimeInterval g_lastNudgeAt = 0;

BOOL NudgeCoordinatorMac_ShouldNudge(void) {
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    return (g_lastNudgeAt == 0) || (now - g_lastNudgeAt >= kCooldownSeconds);
}

void NudgeCoordinatorMac_MarkNudged(void) {
    g_lastNudgeAt = [NSDate timeIntervalSinceReferenceDate];
}

// [MINDFUL] Story 1.5 — xem hợp đồng ở NudgeCoordinatorMac.h. Default 3 khi chưa từng lưu
// vBellSensitivity để giữ nguyên hành vi hiện tại (kTenseStreakTrigger=3 ở MoodWatchMac.mm).
int NudgeCoordinatorMac_TenseStreakTrigger(void) {
    NSInteger sensitivity = [[NSUserDefaults standardUserDefaults] integerForKey:@"vBellSensitivity"];
    switch (sensitivity) {
        case 1:  return 4;   // Ít nhạy — cần chuỗi dài hơn mới rung
        case 3:  return 2;   // Nhạy — rung sớm hơn
        case 2:              // Vừa
        default: return 3;   // gồm cả trường hợp chưa từng lưu (integerForKey trả 0)
    }
}
