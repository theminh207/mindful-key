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
#include "NudgeCoordinatorMac.h"

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
    TypingCadenceMac_ReloadThreshold();
}

// [MINDFUL] HĐ-3 — NGƯỠNG PHẢI ĐƯỢC CACHE, KHÔNG ĐỌC UserDefaults MỖI PHÍM.
//
// Bản đầu của #9 gọi `[[NSUserDefaults standardUserDefaults] objectForKey:]` ngay trong
// RegisterKeystroke, tức mỗi keydown. Ba lý do khiến đó là lỗi thật, không phải tối ưu sớm:
//   1. Hook chạy trên MAIN THREAD — `OpenKeyManager.m` gắn tap source bằng
//      `CFRunLoopAddSource(CFRunLoopGetCurrent(), ...)`. Prefs I/O ở đây chặn cả UI lẫn đường phím.
//   2. `NSUserDefaults` có cache trong tiến trình, nhưng cache bị vô hiệu khi tiến trình khác ghi
//      prefs — lần đọc kế tiếp là một XPC round-trip ĐỒNG BỘ sang `cfprefsd`, đơn vị mili-giây khi
//      daemon bận. Nó cũng lấy khoá CFPrefs mỗi lần.
//   3. CGEventTap có timeout: callback quá hạn thì macOS TỰ TẮT TAP
//      (`kCGEventTapDisabledByTimeout`) — bộ gõ chết câm cho tới khi có ai bật lại.
// Trái thẳng docs/01-intent.md §7 ("không có báo cáo giật hay khựng gõ do lớp đo gây ra").
//
// Nạp một lần ở Init(), làm mới ở BellMac_ApplySettings() (nơi đã đọc lại toàn bộ prefs chuông).
// Đường nóng nay chỉ đọc một `double`.
static double g_thresholdCPM = 400.0;   // giá trị thật nạp ở Init(); xem TypingCadenceMac_ReloadThreshold

void TypingCadenceMac_ReloadThreshold(void) {
    NSNumber *stored = [[NSUserDefaults standardUserDefaults] objectForKey:@"vBellThresholdCPM"];
    double v = stored ? [stored doubleValue] : kCadenceWaveDefaultThresholdCPM;
    // Giá trị hỏng (0/âm) rơi về mặc định: `thresholdCpm <= 0` là tiền điều kiện BellPolicy.h cấm
    // — truyền 0 vào sẽ khoá chuông vĩnh viễn (cổng chống rung `cpm < 0` không bao giờ đúng).
    g_thresholdCPM = (v > 0.0) ? v : kCadenceWaveDefaultThresholdCPM;
}

double TypingCadenceMac_ThresholdCPM(void) {
    return g_thresholdCPM;
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

    // [MINDFUL] HĐ-2/HĐ-6 — CHỈ ĐƯỢC CÓ MỘT COOLDOWN, VÀ NÓ PHẢI NẰM TRƯỚC evaluate().
    //
    // `NudgeCoordinatorMac_ShouldNudge()` là cổng phối hợp giữa MỌI loại nhắc (chuông theo lịch của
    // bellTick, nhắc thụ động, và nay là chuông nhịp gõ) — nó giữ riêng một cooldown 45 giây.
    // Bản đầu của #9 để cổng đó nằm BÊN TRONG BellMac_RingForFastTyping, tức SAU evaluate(). Hỏng
    // thật: evaluate() trả true đã ghi xong `_armed = false` + `_lastRungMs = nowMs`, rồi
    // RingForFastTyping lặng lẽ `return` vì còn trong cooldown của NudgeCoordinator. Tiếng chuông
    // bị NUỐT nhưng lượt vũ trang ĐÃ TIÊU — người dùng gõ nhanh liên tục 5 phút cũng không nghe gì,
    // vì phải chờ CPM tụt dưới 0.9×ngưỡng mới được vũ trang lại. Đúng kiểu lỗi mà BellPolicy.h khai
    // là lý do gộp ShouldRing+NoteRung thành một hàm ("báo lại mà không thực sự phát tiếng").
    //
    // Cách sửa đúng ngữ nghĩa: gộp vào `snoozed`. Cổng 5 của BellPolicy KHÔNG tiêu lượt vũ trang —
    // nghĩa là khi cooldown phối hợp hết hạn, cơ hội reo vẫn còn nguyên, đúng thứ ta cần.
    BOOL snoozed = BellMac_IsSnoozed() || !NudgeCoordinatorMac_ShouldNudge();

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
