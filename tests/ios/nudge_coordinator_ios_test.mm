//
//  nudge_coordinator_ios_test.mm
//  mindful-key — test tự động cho NudgeCoordinatorIOS (story 2.6: chuông nhắc nghỉ).
//
//  Theo đúng chiến lược Testing đã khoá ở story 2.6: tách "đếm/gate" (thuần, test host được) khỏi
//  "hiệu ứng thật" (haptic/âm — chỉ verify thủ công trên Simulator/thiết bị, KHÔNG test ở đây).
//
//  2 phần:
//   1) NudgeCoordinatorIOS_RegisterSentenceRiskForTesting — mock clock, KHÔNG chạm App Group thật,
//      KHÔNG chạm hiệu ứng thật (NudgeCoordinatorIOS.mm tự né UIKit qua TARGET_OS_IPHONE khi biên
//      dịch cho host macOS — chạy ĐÚNG hàm production, không phải bản giả lập riêng).
//   2) Round-trip cấu hình (bật/tắt + tạm hoãn) qua suite App Group GIẢ LẬP, đúng pattern
//      settings_bridge_test.mm.
//
//  Chạy trên HOST (macOS) — không cần Simulator. Xem nudge_coordinator_ios_build.sh.

#import <Foundation/Foundation.h>
#include <math.h>
#import "NudgeCoordinatorIOS.h"
#import "BellReminderSettingsBridge.h"

static int gFail = 0;

static void expectTrue(const char *label, BOOL cond) {
    if (!cond) gFail++;
    printf("  %-66s %s\n", label, cond ? "OK" : "SAI <<<");
}

static void expectEqualInt(const char *label, long got, long want) {
    BOOL ok = (got == want);
    if (!ok) gFail++;
    printf("  %-66s got=%ld  want=%ld  %s\n", label, got, want, ok ? "OK" : "SAI <<<");
}

// Ngưỡng/số câu đúng theo hằng số production (KHÔNG hardcode lại 0.35/3 ở đây — đọc thẳng từ
// header để test tự khớp nếu hằng số đổi, đúng tinh thần "copy đúng giá trị macOS, 1 nguồn").
static const double kTense = NudgeCoordinatorIOS_TenseThreshold;      // 0.35
static const double kCalm = 0.10;                                     // rõ ràng dưới ngưỡng

// ===== Phần 1: đếm/gate thuần (mock clock) =====

static void test3ConsecutiveTriggersOnce(void) {
    printf("\n-- Phần 1a: 3 câu căng LIÊN TIẾP -> rung đúng 1 lần --\n");
    NudgeCoordinatorIOS_ResetStateForTesting();
    NSTimeInterval now = 1000.0;

    BOOL r1 = NudgeCoordinatorIOS_RegisterSentenceRiskForTesting(kTense, YES, NO, now);
    BOOL r2 = NudgeCoordinatorIOS_RegisterSentenceRiskForTesting(kTense, YES, NO, now);
    BOOL r3 = NudgeCoordinatorIOS_RegisterSentenceRiskForTesting(kTense, YES, NO, now);

    expectTrue("câu 1/3: chưa rung", !r1);
    expectTrue("câu 2/3: chưa rung", !r2);
    expectTrue("câu 3/3: rung (đạt ngưỡng 3 liên tiếp)", r3);

    // Ngay sau khi rung — 3 câu căng liên tiếp NỮA (đã reset về 0) không được rung lại vì còn
    // trong cooldown (AC#2) — verify ở test riêng bên dưới (test2TriggersWithinCooldown), ở đây
    // chỉ xác nhận đúng 1 lần rung cho ĐỢT ĐẦU, không hơn không kém.
}

static void testLowRiskInterleavedResets(void) {
    printf("\n-- Phần 1b: 1 câu dịu lại xen giữa -> reset về 0, không rung sớm --\n");
    NudgeCoordinatorIOS_ResetStateForTesting();
    NSTimeInterval now = 2000.0;

    BOOL r1 = NudgeCoordinatorIOS_RegisterSentenceRiskForTesting(kTense, YES, NO, now);
    BOOL r2 = NudgeCoordinatorIOS_RegisterSentenceRiskForTesting(kTense, YES, NO, now);
    BOOL rCalm = NudgeCoordinatorIOS_RegisterSentenceRiskForTesting(kCalm, YES, NO, now); // reset
    BOOL r3 = NudgeCoordinatorIOS_RegisterSentenceRiskForTesting(kTense, YES, NO, now);   // chỉ mới 1/3 lại

    expectTrue("câu 1: chưa rung", !r1);
    expectTrue("câu 2: chưa rung", !r2);
    expectTrue("câu dịu xen giữa: không rung", !rCalm);
    expectTrue("câu ngay sau câu dịu (mới 1/3): chưa rung", !r3);

    // Đi tiếp cho đủ 3 liên tiếp TỪ SAU điểm reset để xác nhận việc đếm lại từ đầu hoạt động đúng.
    BOOL r4 = NudgeCoordinatorIOS_RegisterSentenceRiskForTesting(kTense, YES, NO, now);
    BOOL r5 = NudgeCoordinatorIOS_RegisterSentenceRiskForTesting(kTense, YES, NO, now);
    expectTrue("câu 2/3 kể từ sau reset: chưa rung", !r4);
    expectTrue("câu 3/3 kể từ sau reset: rung", r5);
}

static void test2TriggersWithinCooldown(void) {
    printf("\n-- Phần 1c: 2 lần đủ điều kiện trong CÙNG cửa sổ cooldown -> chỉ lần đầu rung (AC#2) --\n");
    NudgeCoordinatorIOS_ResetStateForTesting();
    NSTimeInterval t0 = 5000.0;

    NudgeCoordinatorIOS_RegisterSentenceRiskForTesting(kTense, YES, NO, t0);
    NudgeCoordinatorIOS_RegisterSentenceRiskForTesting(kTense, YES, NO, t0);
    BOOL firstRing = NudgeCoordinatorIOS_RegisterSentenceRiskForTesting(kTense, YES, NO, t0);
    expectTrue("đợt 1: rung", firstRing);

    // Đợt 2 đủ 3 câu căng liên tiếp NGAY SAU đó, still trong cooldown 45s (chỉ mới +10s).
    NSTimeInterval t1 = t0 + 10.0;
    NudgeCoordinatorIOS_RegisterSentenceRiskForTesting(kTense, YES, NO, t1);
    NudgeCoordinatorIOS_RegisterSentenceRiskForTesting(kTense, YES, NO, t1);
    BOOL secondRingBlocked = NudgeCoordinatorIOS_RegisterSentenceRiskForTesting(kTense, YES, NO, t1);
    expectTrue("đợt 2 (còn trong cooldown 45s): BỊ CHẶN, không rung", !secondRingBlocked);

    // Đợt 3, sau khi cooldown đã hết hẳn (t0 + 46s > t0 + 45s).
    NSTimeInterval t2 = t0 + 46.0;
    NudgeCoordinatorIOS_RegisterSentenceRiskForTesting(kTense, YES, NO, t2);
    NudgeCoordinatorIOS_RegisterSentenceRiskForTesting(kTense, YES, NO, t2);
    BOOL thirdRing = NudgeCoordinatorIOS_RegisterSentenceRiskForTesting(kTense, YES, NO, t2);
    expectTrue("đợt 3 (hết cooldown): rung lại được", thirdRing);
}

static void testToggleOffNeverTriggers(void) {
    printf("\n-- Phần 1d: toggle OFF -> KHÔNG BAO GIỜ rung dù risk cao bao nhiêu lần (AC#3) --\n");
    NudgeCoordinatorIOS_ResetStateForTesting();
    NSTimeInterval now = 9000.0;

    BOOL anyRing = NO;
    for (int i = 0; i < 10; i++) {
        if (NudgeCoordinatorIOS_RegisterSentenceRiskForTesting(1.0, /*enabled=*/NO, NO, now)) {
            anyRing = YES;
        }
    }
    expectTrue("10 lần risk=1.0 nhưng enabled=NO -> không lần nào rung", !anyRing);
}

static void testSnoozedBlocksEvenWhenAllElseSatisfied(void) {
    printf("\n-- Phần 1e: đang tạm hoãn -> KHÔNG rung dù đủ mọi điều kiện khác (AC#4) --\n");
    NudgeCoordinatorIOS_ResetStateForTesting();
    NSTimeInterval now = 12000.0;

    NudgeCoordinatorIOS_RegisterSentenceRiskForTesting(kTense, YES, /*snoozed=*/YES, now);
    NudgeCoordinatorIOS_RegisterSentenceRiskForTesting(kTense, YES, YES, now);
    BOOL blocked = NudgeCoordinatorIOS_RegisterSentenceRiskForTesting(kTense, YES, YES, now);
    expectTrue("đủ 3 câu căng liên tiếp NHƯNG đang hoãn -> không rung", !blocked);
}

// Edge case Testing story 2.6: risk sát ngưỡng 0.35 (0.349 vs 0.351) — verify không lệch dấu
// phẩy động gây đếm sai.
static void testThresholdBoundaryPrecision(void) {
    printf("\n-- Phần 1f: edge case biên ngưỡng 0.349 vs 0.351 --\n");
    NudgeCoordinatorIOS_ResetStateForTesting();
    NSTimeInterval now = 20000.0;

    BOOL belowCountsAsCalm = NO;
    {
        // Dưới ngưỡng dù rất sát -> KHÔNG được tính là câu căng, KHÔNG được đóng góp vào chuỗi.
        NudgeCoordinatorIOS_RegisterSentenceRiskForTesting(0.349, YES, NO, now);
        NudgeCoordinatorIOS_RegisterSentenceRiskForTesting(0.349, YES, NO, now);
        BOOL r = NudgeCoordinatorIOS_RegisterSentenceRiskForTesting(0.349, YES, NO, now);
        belowCountsAsCalm = !r;
    }
    expectTrue("0.349 x3 (dưới ngưỡng) -> không rung", belowCountsAsCalm);

    NudgeCoordinatorIOS_ResetStateForTesting();
    NudgeCoordinatorIOS_RegisterSentenceRiskForTesting(0.351, YES, NO, now);
    NudgeCoordinatorIOS_RegisterSentenceRiskForTesting(0.351, YES, NO, now);
    BOOL aboveTriggers = NudgeCoordinatorIOS_RegisterSentenceRiskForTesting(0.351, YES, NO, now);
    expectTrue("0.351 x3 (trên ngưỡng, sát biên) -> rung", aboveTriggers);
}

// ===== Phần 2: round-trip cấu hình (BellReminderSettingsBridge) qua suite App Group GIẢ LẬP =====
// NudgeCoordinatorIOS.mm GỌI SANG BellReminderSettingsBridge để đọc cấu hình (xem
// NudgeCoordinatorIOS.h "CẤU HÌNH... KHÔNG sống ở đây") — test trực tiếp bridge đó, đúng ranh giới
// thật của code, không test lại I/O App Group 2 lần ở 2 nơi.

static void testConfigRoundTripViaFakeSuite(void) {
    printf("\n-- Phần 2: round-trip bật/tắt + tạm hoãn (BellReminderSettingsBridge) qua suite giả lập --\n");
    NSString *fakeSuite = [NSString stringWithFormat:@"vn.gnh.mindfulkey.tests.bellreminder.%d",
                                                       (int)[NSProcessInfo processInfo].processIdentifier];
    NSUserDefaults *precleanup = [[NSUserDefaults alloc] initWithSuiteName:fakeSuite];
    [precleanup removePersistentDomainForName:fakeSuite];

    // Chưa từng ghi -> mặc định YES (bật sẵn, theo Tasks story 2.6).
    expectTrue("chưa từng ghi -> enabled mặc định YES",
               BellReminderSettingsBridge_IsEnabledForTesting(fakeSuite));

    BellReminderSettingsBridge_SetEnabledForTesting(fakeSuite, NO);
    expectTrue("ghi NO -> đọc lại đúng NO", !BellReminderSettingsBridge_IsEnabledForTesting(fakeSuite));
    BellReminderSettingsBridge_SetEnabledForTesting(fakeSuite, YES);
    expectTrue("ghi lại YES -> đọc lại đúng YES", BellReminderSettingsBridge_IsEnabledForTesting(fakeSuite));

    NSDate *now = [NSDate date];
    expectTrue("chưa từng hoãn -> IsSnoozedAtForTesting = NO",
               !BellReminderSettingsBridge_IsSnoozedAtForTesting(fakeSuite, now));

    BellReminderSettingsBridge_SnoozeForMinutesForTesting(fakeSuite, 60);
    NSDate *stillWithinHour = [now dateByAddingTimeInterval:30 * 60.0]; // +30 phút, còn trong 60 phút hoãn
    expectTrue("hoãn 60 phút, kiểm ở +30 phút -> vẫn đang hoãn",
               BellReminderSettingsBridge_IsSnoozedAtForTesting(fakeSuite, stillWithinHour));
    NSDate *afterHour = [now dateByAddingTimeInterval:61 * 60.0]; // +61 phút, đã qua mốc hoãn
    expectTrue("kiểm ở +61 phút -> hết hoãn",
               !BellReminderSettingsBridge_IsSnoozedAtForTesting(fakeSuite, afterHour));

    NSUserDefaults *fake = [[NSUserDefaults alloc] initWithSuiteName:fakeSuite];
    [fake removePersistentDomainForName:fakeSuite];
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        printf("=== TEST NudgeCoordinatorIOS (story 2.6: chuông nhắc nghỉ) ===\n");
        printf("  (hằng số production: ngưỡng=%.2f, số câu liên tiếp=%d, cooldown=%.0fs)\n",
               NudgeCoordinatorIOS_TenseThreshold, NudgeCoordinatorIOS_ConsecutiveTenseTrigger,
               NudgeCoordinatorIOS_CooldownSeconds);
        expectEqualInt("hằng số số câu liên tiếp khớp macOS (3)",
                        (long)NudgeCoordinatorIOS_ConsecutiveTenseTrigger, 3);

        test3ConsecutiveTriggersOnce();
        testLowRiskInterleavedResets();
        test2TriggersWithinCooldown();
        testToggleOffNeverTriggers();
        testSnoozedBlocksEvenWhenAllElseSatisfied();
        testThresholdBoundaryPrecision();
        testConfigRoundTripViaFakeSuite();

        if (gFail == 0) {
            printf("\n=== XONG — TẤT CẢ PASS ===\n");
        } else {
            printf("\n=== XONG — %d CA SAI (make test-ios sẽ đỏ) ===\n", gFail);
        }
    }
    return gFail == 0 ? 0 : 1;
}
