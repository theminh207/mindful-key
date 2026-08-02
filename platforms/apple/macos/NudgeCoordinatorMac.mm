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

// [MINDFUL] 2026-08-02 (issue #9) — xem hợp đồng ở NudgeCoordinatorMac.h. Còn sống chỉ cho
// MoodPhrasingMac/ReflectionScreenMac (nhật ký send-risk cũ), KHÔNG còn liên quan chuông.
double NudgeCoordinatorMac_RippleThreshold(void) {
    NSInteger sensitivity = [[NSUserDefaults standardUserDefaults] integerForKey:@"vBellSensitivity"];
    switch (sensitivity) {
        case 1:  return 0.6; // Ít nhạy
        case 3:  return 0.4; // Nhạy
        case 2:
        default: return 0.5; // Vừa
    }
}
