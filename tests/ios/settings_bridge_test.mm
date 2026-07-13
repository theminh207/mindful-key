//
//  settings_bridge_test.mm
//  mindful-key — test tự động cho KeyboardSettingsBridge (story 2.3: kiểu gõ + chiều cao bàn phím).
//
//  2 phần:
//   1) Hàm THUẦN KeyboardSettingsBridge_HeightLevelToStep — quy đổi double liên tục sang bậc 1-5
//      cho VoiceOver ("mức N/5", AC #5), không cần I/O.
//   2) Round-trip ghi/đọc qua NSUserDefaults suite GIẢ LẬP (KHÔNG phải group.vn.gnh.mindfulkey
//      thật — dùng biến thể *ForTesting để tránh ghi vào App Group thật lúc chạy test tự động,
//      đúng yêu cầu Testing của story 2.3) — chứng minh mặc định (chưa từng ghi -> Telex/mức
//      giữa, AC #1/#2) và ghi-rồi-đọc-lại khớp giá trị vừa ghi (AC #4).
//
//  Chạy trên HOST (macOS) — không cần Simulator. Xem settings_bridge_build.sh.

#import <Foundation/Foundation.h>
#include <math.h>
#import "KeyboardSettingsBridge.h"

static int gFail = 0;

static void expectEqualInt(const char *label, long got, long want) {
    BOOL ok = (got == want);
    if (!ok) gFail++;
    printf("  %-58s got=%ld  want=%ld  %s\n", label, got, want, ok ? "OK" : "SAI <<<");
}

static void expectNear(const char *label, double got, double want, double eps) {
    BOOL ok = fabs(got - want) <= eps;
    if (!ok) gFail++;
    printf("  %-58s got=%.4f  want=%.4f (+-%.4f)  %s\n", label, got, want, eps, ok ? "OK" : "SAI <<<");
}

// ===== Phần 1: KeyboardSettingsBridge_HeightLevelToStep (hàm thuần) =====
static void testHeightLevelToStepPure(void) {
    printf("\n-- Phần 1: KeyboardSettingsBridge_HeightLevelToStep() thuần --\n");
    expectEqualInt("0.0 -> bậc 1 (thấp nhất)", KeyboardSettingsBridge_HeightLevelToStep(0.0), 1);
    expectEqualInt("0.25 -> bậc 2", KeyboardSettingsBridge_HeightLevelToStep(0.25), 2);
    expectEqualInt("0.5 (mặc định) -> bậc 3 (mức giữa)", KeyboardSettingsBridge_HeightLevelToStep(0.5), 3);
    expectEqualInt("0.75 -> bậc 4", KeyboardSettingsBridge_HeightLevelToStep(0.75), 4);
    expectEqualInt("1.0 -> bậc 5 (cao nhất)", KeyboardSettingsBridge_HeightLevelToStep(1.0), 5);
    // Edge case: giá trị hỏng ngoài [0,1] -> kẹp về biên trước khi quy đổi, không crash/rác.
    expectEqualInt("-0.4 (ngoài biên dưới) -> kẹp về bậc 1", KeyboardSettingsBridge_HeightLevelToStep(-0.4), 1);
    expectEqualInt("1.9 (ngoài biên trên) -> kẹp về bậc 5", KeyboardSettingsBridge_HeightLevelToStep(1.9), 5);
}

// ===== Phần 2: round-trip qua suite giả lập =====
static void testRoundTripViaFakeSuite(void) {
    printf("\n-- Phần 2: round-trip ghi/đọc qua suite giả lập (KHÔNG phải App Group thật) --\n");
    // Suite riêng cho lần chạy test này (KHÔNG group.vn.gnh.mindfulkey thật) — tránh ghi vào App
    // Group thật trong lúc test tự động (yêu cầu Fixtures/mocks của story 2.3).
    NSString *fakeSuite = [NSString stringWithFormat:@"vn.gnh.mindfulkey.tests.settingsbridge.%d",
                                                       (int)[NSProcessInfo processInfo].processIdentifier];
    // Dọn sạch trước khi test — suite có thể còn rác từ lần chạy trước bị crash giữa chừng (hiếm,
    // nhưng an toàn hơn không dọn).
    NSUserDefaults *precleanup = [[NSUserDefaults alloc] initWithSuiteName:fakeSuite];
    [precleanup removePersistentDomainForName:fakeSuite];

    // AC #1/#2: mở màn lần đầu tiên (chưa từng ghi) -> mặc định Telex + mức giữa, KHÔNG rác.
    KeyboardSettingsInputType defaultInputType = KeyboardSettingsBridge_ReadInputTypeForTesting(fakeSuite);
    expectEqualInt("chưa từng ghi -> đọc inputType mặc định Telex",
                    (long)defaultInputType, (long)KeyboardSettingsInputTypeTelex);
    double defaultHeight = KeyboardSettingsBridge_ReadHeightLevelForTesting(fakeSuite);
    expectNear("chưa từng ghi -> đọc heightLevel mặc định 0.5 (mức giữa)", defaultHeight, 0.5, 1e-9);

    // AC #4: ghi VNI + mức cao (0.9) -> đọc lại đúng giá trị vừa ghi (không reset về mặc định).
    BOOL wroteInput = KeyboardSettingsBridge_WriteInputTypeForTesting(fakeSuite, KeyboardSettingsInputTypeVNI);
    if (!wroteInput) gFail++;
    printf("  %-58s %s\n", "ghi inputType VNI", wroteInput ? "OK" : "SAI <<<");
    BOOL wroteHeight = KeyboardSettingsBridge_WriteHeightLevelForTesting(fakeSuite, 0.9);
    if (!wroteHeight) gFail++;
    printf("  %-58s %s\n", "ghi heightLevel 0.9", wroteHeight ? "OK" : "SAI <<<");

    KeyboardSettingsInputType readBackInput = KeyboardSettingsBridge_ReadInputTypeForTesting(fakeSuite);
    expectEqualInt("đọc lại inputType khớp VNI vừa ghi", (long)readBackInput, (long)KeyboardSettingsInputTypeVNI);
    double readBackHeight = KeyboardSettingsBridge_ReadHeightLevelForTesting(fakeSuite);
    expectNear("đọc lại heightLevel khớp 0.9 vừa ghi", readBackHeight, 0.9, 1e-9);

    // Ghi giá trị ngoài [0,1] -> phải bị KẸP lại trước khi lưu (không lưu rác).
    KeyboardSettingsBridge_WriteHeightLevelForTesting(fakeSuite, 1.7);
    double clampedHeight = KeyboardSettingsBridge_ReadHeightLevelForTesting(fakeSuite);
    expectNear("ghi 1.7 (ngoài biên) -> đọc lại bị kẹp về 1.0", clampedHeight, 1.0, 1e-9);

    // Đổi về Telex -> đọc lại đúng Telex (round-trip cả 2 chiều, không dính giá trị cũ).
    KeyboardSettingsBridge_WriteInputTypeForTesting(fakeSuite, KeyboardSettingsInputTypeTelex);
    KeyboardSettingsInputType backToTelex = KeyboardSettingsBridge_ReadInputTypeForTesting(fakeSuite);
    expectEqualInt("đổi lại Telex -> đọc lại đúng Telex", (long)backToTelex, (long)KeyboardSettingsInputTypeTelex);

    // Dọn dẹp suite giả lập sau test — không để lại rác trên máy dev.
    NSUserDefaults *fake = [[NSUserDefaults alloc] initWithSuiteName:fakeSuite];
    [fake removePersistentDomainForName:fakeSuite];
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        printf("=== TEST KeyboardSettingsBridge (story 2.3: kiểu gõ + chiều cao bàn phím) ===\n");
        testHeightLevelToStepPure();
        testRoundTripViaFakeSuite();

        if (gFail == 0) {
            printf("\n=== XONG — TẤT CẢ PASS ===\n");
        } else {
            printf("\n=== XONG — %d CA SAI (make test-ios sẽ đỏ) ===\n", gFail);
        }
    }
    return gFail == 0 ? 0 : 1;
}
