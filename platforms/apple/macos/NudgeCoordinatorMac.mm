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
