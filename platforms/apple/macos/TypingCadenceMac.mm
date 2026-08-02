//
//  TypingCadenceMac.mm
//  ModernKey
//
//  [MINDFUL] Xem TypingCadenceMac.h.
//

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#include "TypingCadenceMac.h"
#include "TypingCadence.h"
#include "BellPolicy.h"
#include "CadenceWaveAmplitude.h"
#include "BellMac.h"

// [MINDFUL] Cooldown lấy từ `kBellPolicyDefaultCooldownMs` (core/mood/BellPolicy.h), KHÔNG viết
// `45000` ở đây. Q10 đã chốt tạm 2026-08-02: 45 giây, và **dùng chung cả ba vỏ** — không có lý do
// kỹ thuật nào để macOS/Windows/iOS lệch số nhau (CPM là phép đo thuần, không phụ thuộc OS), mà
// lệch số thì đúng là bẫy "ba bản chép tay trôi lệch" README §6 cảnh báo. Vỏ vẫn là nơi TRUYỀN giá
// trị vào (core không tự đọc settings) — chỉ con số mặc định là dùng chung.

// [MINDFUL] MỘT bản duy nhất mỗi lớp (HĐ-6) — dựng LƯỜI (lazy) trong Init() thay vì static object
// ở file scope, cùng phong cách phòng thủ với MoodWatchMac_Init()/g_moodQueue: tránh phụ thuộc vào
// thứ tự khởi tạo static xuyên translation unit (HĐ-5 "khởi động an toàn" — lớp lỗi này đã cắn dự
// án 2 lần ở 2 vỏ khác nhau, không dựng thêm một đường tương tự).
static TypingCadence *g_cadence = NULL;
static BellPolicy *g_bellPolicy = NULL;

// [MINDFUL] Xem hợp đồng đầy đủ ở TypingCadenceMac.h — HĐ-4, fail-closed.
BOOL TypingCadenceMac_IsSecureFieldActive(void) {
    return IsSecureEventInputEnabled();
}

void TypingCadenceMac_Init(void) {
    if (g_cadence == NULL) {
        g_cadence = new TypingCadence(kTypingCadenceDefaultWindowMs);
    }
    if (g_bellPolicy == NULL) {
        g_bellPolicy = new BellPolicy(kBellPolicyDefaultCooldownMs);
    }
}

double TypingCadenceMac_ThresholdCPM(void) {
    NSNumber *stored = [[NSUserDefaults standardUserDefaults] objectForKey:@"vBellThresholdCPM"];
    return stored ? [stored doubleValue] : kCadenceWaveDefaultThresholdCPM;
}

double TypingCadenceMac_CurrentCPM(void) {
    if (g_cadence == NULL) return 0.0;
    int64_t nowMs = (int64_t)([[NSDate date] timeIntervalSince1970] * 1000.0);
    return g_cadence->currentCPM(nowMs);
}

void TypingCadenceMac_RegisterKeystroke(int64_t nowMs) {
    // [MINDFUL] Cùng bất biến với MoodWatchMac_Flush/SetEnabled ("Vá lỗi B") — gọi trước Init()
    // (không nên xảy ra thật, nhưng rẻ để thủ chắc) phải sống sót, không crash cả bàn phím.
    if (g_cadence == NULL || g_bellPolicy == NULL)
        return;

    g_cadence->registerKeystroke(nowMs);
    double cpm = g_cadence->currentCPM(nowMs);
    double threshold = TypingCadenceMac_ThresholdCPM();
    BOOL enabled = vBell != 0;
    BOOL snoozed = BellMac_IsSnoozed();

    // [MINDFUL] HĐ-2 — evaluate() trả true chỉ được dẫn tới ĐÚNG MỘT lệnh phát tiếng. Gọi evaluate
    // MỖI PHÍM (không gate bằng `enabled` ở đây) để BellPolicy tự giữ đúng bất biến "tắt/tạm hoãn
    // KHÔNG tiêu lượt vũ trang" — nếu ta tự ý bỏ qua lời gọi evaluate() khi !enabled, state chống
    // rung bên trong BellPolicy sẽ KHÔNG được cập nhật, sai với hợp đồng.
    if (g_bellPolicy->evaluate(cpm, threshold, nowMs, enabled, snoozed)) {
        // HĐ-3: phát tiếng chuông KHÔNG được chạy trong hook bàn phím — đẩy sang main queue.
        dispatch_async(dispatch_get_main_queue(), ^{
            BellMac_RingForFastTyping();
        });
    }
}
