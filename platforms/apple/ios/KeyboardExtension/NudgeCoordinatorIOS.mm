//
//  NudgeCoordinatorIOS.mm
//  mindful-key — iOS keyboard extension (Round 2, story 2.6)
//
//  Xem NudgeCoordinatorIOS.h cho hợp đồng đầy đủ (mirror macOS, nơi gọi, thread safety).
//

#import "NudgeCoordinatorIOS.h"
#import "BellReminderSettingsBridge.h"   // cấu hình bật/tắt + tạm hoãn (shared, xem NudgeCoordinatorIOS.h)
#include <TargetConditionals.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#endif

// === Hằng số mirror macOS — copy nguyên giá trị, KHÔNG tự chế (xem header) ===
const double NudgeCoordinatorIOS_TenseThreshold = 0.35;          // MoodWatchMac.mm dòng 47
const int NudgeCoordinatorIOS_ConsecutiveTenseTrigger = 3;       // MoodWatchMac.mm dòng 48
const NSTimeInterval NudgeCoordinatorIOS_CooldownSeconds = 45.0; // NudgeCoordinatorMac.mm dòng 11

// State production — CHỈ được ghi/đọc từ g_moodQueue của MoodBridge (xem Dev Notes thread safety
// ở header) — plain static, KHÔNG khoá, đúng y hệt g_tenseStreak bên MoodWatchMac.mm.
static int g_consecutiveTense = 0;
static NSTimeInterval g_lastNudgeAt = 0; // 0 = chưa từng nhắc

#pragma mark - Hiệu ứng thật (haptic + âm) — CHỈ biên dịch trên iOS, no-op khi build host test macOS

static void mk_triggerRingEffect(void) {
#if TARGET_OS_IPHONE
    dispatch_async(dispatch_get_main_queue(), ^{
        UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
        [generator prepare];
        [generator impactOccurred];
        // [Inference] 1104 = system sound ID thường được cộng đồng iOS dev dùng cho 1 tiếng "tick"
        // nhẹ (KHÔNG có enum chính thức từ Apple cho ID này, chưa tự nghe-verify được trong sandbox
        // này) — nếu nghe sai/không đúng ý lúc test Simulator thật (xem Testing story 2.6 mục
        // Manual), đổi 1 số này KHÔNG đụng logic đếm/gate ở dưới.
        AudioServicesPlaySystemSound((SystemSoundID)1104);
    });
#endif
}

#pragma mark - Đếm số câu căng liên tiếp + cooldown (lõi thuần)

// KHÔNG side-effect ngoài 2 tham số state truyền vào theo con trỏ — dùng CHUNG bởi cả production
// (NudgeCoordinatorIOS_RegisterSentenceRisk, state = 2 biến static ở trên) lẫn test
// (NudgeCoordinatorIOS_RegisterSentenceRiskForTesting, CÙNG 2 biến static đó — xem
// NudgeCoordinatorIOS_ResetStateForTesting để dọn giữa các ca).
static BOOL mk_step(int *consecutiveTense, NSTimeInterval *lastNudgeAt,
                     double risk, BOOL enabled, BOOL snoozed, NSTimeInterval now) {
    // Câu dịu lại (risk thấp) reset về 0 NGAY — "liên tiếp" nghĩa là LIÊN TỤC, không cộng dồn
    // qua câu dịu (mirror MoodWatchMac.mm dòng 219-225).
    if (risk >= NudgeCoordinatorIOS_TenseThreshold) {
        (*consecutiveTense)++;
    } else {
        *consecutiveTense = 0;
    }

    if (*consecutiveTense < NudgeCoordinatorIOS_ConsecutiveTenseTrigger) {
        return NO;
    }

    // Đạt ngưỡng: reset NGAY LẬP TỨC trước khi xét có rung thật hay không (mirror MoodWatchMac.mm
    // dòng 227 "reset ngay để không rung lại liên tục cho cùng 1 đợt căng thẳng") — nghĩa là dù
    // gate dưới đây chặn (chưa hết cooldown/đang hoãn/đang tắt), việc đếm vẫn bắt đầu lại từ 0.
    *consecutiveTense = 0;

    // Gate order y hệt BellMac_RingForTenseStreak (đọc trực tiếp macOS): (a) toggle OFF -> return,
    // (b) đang hoãn -> return, (c) cooldown chưa đủ -> return, (d) đủ điều kiện -> rung + đánh dấu.
    if (!enabled) {
        return NO;
    }
    if (snoozed) {
        return NO;
    }
    BOOL cooldownOk = (*lastNudgeAt == 0) || (now - *lastNudgeAt >= NudgeCoordinatorIOS_CooldownSeconds);
    if (!cooldownOk) {
        return NO;
    }

    *lastNudgeAt = now;
    return YES;
}

void NudgeCoordinatorIOS_RegisterSentenceRisk(double risk) {
    BOOL enabled = BellReminderSettingsBridge_IsEnabled();
    NSDate *now = [NSDate date];
    BOOL snoozed = BellReminderSettingsBridge_IsSnoozedAt(now);
    NSTimeInterval nowReference = [now timeIntervalSinceReferenceDate]; // đơn vị đồng hồ giống macOS (NudgeCoordinatorMac.mm)
    BOOL shouldRing = mk_step(&g_consecutiveTense, &g_lastNudgeAt, risk, enabled, snoozed, nowReference);
    if (shouldRing) {
        mk_triggerRingEffect();
    }
}

#pragma mark - CHỈ DÙNG TRONG TEST

void NudgeCoordinatorIOS_ResetStateForTesting(void) {
    g_consecutiveTense = 0;
    g_lastNudgeAt = 0;
}

BOOL NudgeCoordinatorIOS_RegisterSentenceRiskForTesting(double risk, BOOL enabled, BOOL snoozed, NSTimeInterval now) {
    return mk_step(&g_consecutiveTense, &g_lastNudgeAt, risk, enabled, snoozed, now);
}
