//
//  emotion_wave_test.mm
//  mindful-key — test tự động cho đường cong biên độ sóng ambient (story 2.5, Q1) — CHỈ phần
//  TÍNH (EmotionWaveAmplitude, thuần C, không UIKit) — build + chạy trên HOST macOS, không cần
//  Simulator, đúng pattern tests/ios/bridge_test.mm / mood_bridge_test.mm.
//
//  Phần VẼ (CAShapeLayer trong SuggestionBarView) KHÔNG test được ở đây (cần UIKit thật) — xem
//  Testing story 2.5 mục 2-6 (kịch bản thủ công trên Simulator/thiết bị).

#import <Foundation/Foundation.h>
#include <cmath>
#include "EmotionWaveAmplitude.h"

static int gFail = 0;
static const double kEps = 1e-9;

static void expectEqual(double got, double want, const char *label) {
    BOOL ok = fabs(got - want) < kEps;
    if (!ok) gFail++;
    printf("  %-42s got=%.6f  want=%.6f  %s\n", label, got, want, ok ? "OK" : "SAI <<<");
}

static void expectTrue(BOOL cond, const char *label) {
    if (!cond) gFail++;
    printf("  %-42s %s\n", label, cond ? "OK" : "SAI <<<");
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        printf("=== TEST đường cong biên độ sóng ambient (EmotionWaveAmplitude, story 2.5 AC#1) ===\n\n");

        // Dead-zone: risk < 0.3 -> biên độ = 0 tuyệt đối (mặt hồ phẳng).
        expectEqual(EmotionWaveAmplitude(0.0),  0.0, "risk=0.0 -> 0");
        expectEqual(EmotionWaveAmplitude(0.1),  0.0, "risk=0.1 -> 0");
        expectEqual(EmotionWaveAmplitude(0.29), 0.0, "risk=0.29 -> 0");
        expectEqual(EmotionWaveAmplitude(0.30), 0.0, "risk=0.30 (đúng ngưỡng) -> 0");

        // Trên ngưỡng: tăng đơn điệu, liên tục, không bậc thang.
        double a30  = EmotionWaveAmplitude(0.30);
        double a301 = EmotionWaveAmplitude(0.301);
        double a31  = EmotionWaveAmplitude(0.31);
        double a50  = EmotionWaveAmplitude(0.5);
        double a70  = EmotionWaveAmplitude(0.7);
        double a100 = EmotionWaveAmplitude(1.0);

        // Không nhảy cấp ngay tại/quanh ngưỡng 0.3 — sample dày lân cận, không chỉ 2 đầu mút.
        expectTrue(fabs(a301 - a30) < 0.01, "risk 0.30->0.301: không bước nhảy đột ngột");
        expectTrue(a31 > a301, "risk 0.31 > 0.301 (đơn điệu ngay sát ngưỡng)");

        expectTrue(a50 < a70, "amplitude(0.5) < amplitude(0.7) — đơn điệu");
        expectTrue(a70 < a100, "amplitude(0.7) < amplitude(1.0) — đơn điệu");
        expectEqual(a100, 1.0, "risk=1.0 -> biên độ tối đa (chuẩn hoá 1.0)");

        // Liên tục ở giữa khoảng (0.3, 1.0) — không có bước nhảy giữa 2 mốc risk gần nhau.
        double prev = EmotionWaveAmplitude(0.30);
        double maxJump = 0.0;
        for (double r = 0.30; r <= 1.0 + kEps; r += 0.01) {
            double cur = EmotionWaveAmplitude(r);
            double jump = fabs(cur - prev);
            if (jump > maxJump) maxJump = jump;
            prev = cur;
        }
        // Bước lấy mẫu 0.01 trên tổng khoảng 0.7 -> mỗi bước tối đa hợp lý dưới hẳn 0.05 nếu hàm
        // mượt (smoothstep có đạo hàm cực đại 1.5 tại t=0.5, tương ứng bước ~0.021 cho delta_r=0.01
        // sau khi chuẩn hoá theo khoảng 0.7) — ngưỡng 0.05 đủ chặt để bắt lỗi "bậc thang" thật sự,
        // đủ rộng để không false-positive vì sai số dấu phẩy động.
        expectTrue(maxJump < 0.05, "không có bước nhảy > 0.05 giữa 2 mốc risk cách nhau 0.01 trong [0.3, 1.0]");

        // Clamp: risk ngoài [0,1] không crash/NaN.
        double aNeg = EmotionWaveAmplitude(-0.5);
        double aOver = EmotionWaveAmplitude(1.5);
        expectTrue(!isnan(aNeg) && !isnan(aOver), "risk ngoài khoảng hợp lệ -> không NaN");
        expectEqual(aNeg, 0.0, "risk=-0.5 (âm) -> clamp về 0 (vùng chết)");
        expectEqual(aOver, 1.0, "risk=1.5 (>1) -> clamp về biên độ tối đa 1.0");

        if (gFail == 0) {
            printf("\n=== XONG — TẤT CẢ PASS (đường cong Q1: ngưỡng chết + dâng mượt, không bậc thang) ===\n");
        } else {
            printf("\n=== XONG — %d CA SAI (make test-ios sẽ đỏ) ===\n", gFail);
        }
    }
    return gFail == 0 ? 0 : 1;
}
