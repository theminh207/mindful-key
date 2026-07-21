//
//  MoodWatchMac.mm
//  ModernKey
//
//  [MINDFUL] macOS shell for mood watching.
//  The engine callback runs on the CGEventTap path, so this file immediately
//  dispatches work to a serial background queue and returns.
//

#import <Cocoa/Cocoa.h>
#import <UserNotifications/UserNotifications.h>
#import <os/lock.h>
#include "Engine.h"
#include "MoodBuffer.h"
#include "SendRiskAnalyzer.h"
#include "MoodWatchMac.h"
#include "BellMac.h"
#include "NudgeCoordinatorMac.h"
#import "MoodStoreMac.h"

using namespace std;

int vMoodWatch = 1;

static MoodBuffer g_buffer(15);
static dispatch_queue_t g_moodQueue;
static NSTimeInterval g_lastWarn = 0;
static BOOL g_popupShowing = NO;
static double g_lastSendRisk = -1.0;

// [MINDFUL] Thu hẹp bài toán: không còn phân loại "đang cảm xúc gì", chỉ còn 1 câu hỏi —
// "câu này mà GỬI cho người khác thì hại tới đâu?" -> 1 điểm số trong [0,1].
//
// [MINDFUL] 2026-07-16 — bảng lexicon + công thức TỪNG nằm ngay trong file này, và đội iOS đã
// phải photo lại một bản (platforms/apple/shared/SendRiskAnalyzer.mm) khi core đóng băng; hai bản
// đó trôi lệch thật (bản kia không coi dấu câu là dấu tách từ). Chủ dự án chốt gộp về
// core/mood/SendRiskAnalyzer — C++ thuần, MỘT bản cho macOS · iOS · Windows, khoá bằng
// tests/core/test_send_risk.cpp. File này giữ nguyên hành vi cũ (đã đối chiếu từng con số), chỉ
// còn lo phần CHÍNH SÁCH RIÊNG của vỏ macOS: ngưỡng, cooldown, popup, chuông, lấy mẫu.
static const double kSendRiskThreshold = 0.5;

// [MINDFUL] Bước 7 — chuông data-driven: rung sau 1 CHUỖI câu căng thẳng liên tiếp, không chỉ
// theo lịch cố định. Ngưỡng thấp hơn kSendRiskThreshold có chủ đích — đây là phát hiện "đang
// dồn nén dần", không phải "chuẩn bị gửi thứ gây hại", nên bắt sớm hơn hợp lý.
static int g_tenseStreak = 0;

static double g_sampleSum = 0.0;
static int g_sampleCount = 0;
// [MINDFUL] 2026-07-16 — `g_sampleLastTime`/`g_sampleTimer` đã XOÁ: nhật ký không còn tự đếm giờ,
// nó lắng nghe nhịp chung của BellMac (kMKMoodBeatNotification). Xem MoodWatchMac_Init().

// [MINDFUL] 2026-07-19 — Lớp "sông sống" cho thẻ "Ngay bây giờ" (batch biểu đồ cảm xúc):
//  A2 (đầu sóng thành thật): "bây giờ" = EMA làm mượt vài câu gần nhất, PHAI dần về 0 theo thời
//     gian im lặng (mặt hồ tự lặng khi thôi khuấy). Im đủ lâu = không vẽ đầu sóng.
//  A3 (sông dày chấm): vệt điểm trong RAM (tối đa 1 điểm/30s khi CÓ gõ), giữ 4h gần nhất, KHÔNG
//     lưu đĩa. Idle = không thêm điểm (nhịp không gõ != ghi 0, dec.4).
// Trạng thái này bị ĐỌC từ main (GatekeeperCardView.refresh) và GHI từ g_moodQueue → khoá bằng
// os_unfair_lock (rẻ, không blocking như dispatch_sync vào hàng đợi phân tích đang bận).
static os_unfair_lock g_liveLock = OS_UNFAIR_LOCK_INIT;
static NSMutableArray<NSDictionary *> *g_liveTrace = nil;  // [{ts,value}] cũ->mới, KHÔNG persist
static double g_liveEma = 0.0;            // EMA rủi ro các câu gần đây (làm mượt đầu sóng)
static long long g_lastWordTs = 0;        // epoch giây của từ cuối — dùng để phai
static long long g_liveTraceLastTs = 0;   // chặn dày: tối đa 1 điểm/kLiveSampleSeconds

static const double kLiveEmaAlpha      = 0.4;        // trọng số câu mới trong EMA
static const double kLiveFadeSeconds   = 5 * 60.0;   // phai hết về phẳng lặng sau 5 phút im
static const double kLiveSampleSeconds = 30.0;       // tối đa 1 điểm/30s (đủ dày, không quá tải vẽ)
static const double kLiveTraceMaxAge   = 4 * 3600.0; // giữ 4h (đủ cho cửa sổ 3h + biên tương lai)

static double MKClamp01(double v) { return v < 0 ? 0 : (v > 1 ? 1 : v); }
static double MKSmoothstep(double t) { return t * t * (3.0 - 2.0 * t); }

static NSString* NSStringFromWString(const wstring& text) {
    return [[NSString alloc] initWithBytes:text.data()
                                    length:text.size() * sizeof(wchar_t)
                                  encoding:NSUTF32LittleEndianStringEncoding];
}

static NSString* warningForCategory(const wstring& category) {
    if (category == L"giận")
        return @"Câu bạn vừa gõ nghe đang giận. Khoan gửi đã, hít thở 10 giây rồi hãy quyết định nhé.";
    if (category == L"buồn")
        return @"Nghe có vẻ bạn đang buồn. Có chắc muốn gửi ngay không, hay để lòng dịu lại một chút?";
    if (category == L"mệt")
        return @"Nghe bạn đang mệt hoặc căng thẳng. Nghỉ tay vài phút, uống nước rồi quay lại nhé.";
    if (category == L"lo")
        return @"Nghe có vẻ bạn đang lo lắng. Thử gọi tên điều đang lo trước khi trả lời.";
    return @"Trạng thái đang hơi tiêu cực. Dừng một nhịp, hít thở rồi tiếp tục nhé.";
}

static void showMindfulPrompt(NSString *message) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (g_popupShowing)
            return;
        // [MINDFUL] Bước 7 — gộp vào 1 mạch nhắc chung với chuông: nếu chuông vừa rung gần
        // đây, bỏ qua lời nhắc thụ động này để không dồn dập 2 lời nhắc cho cùng 1 khoảnh khắc.
        if (!NudgeCoordinatorMac_ShouldNudge())
            return;
        g_popupShowing = YES;
        NudgeCoordinatorMac_MarkNudged();

        // [MINDFUL] 2026-07-18 — NSUserNotification (deprecated từ macOS 11) đổi sang
        // UNUserNotificationCenter khi nâng sàn lên 13.0. Nhánh dự phòng NSAlert cũ đã gỡ:
        // nó chỉ chạy khi NSUserNotificationCenter không tồn tại (macOS < 10.8) — chết sẵn
        // từ thời sàn 10.15, giữ lại sau return vô điều kiện là code chết cứng.
        // Best-effort như notifyDidQuitConflictApp: quyền thông báo đã được AppDelegate xin
        // lúc khởi động; người dùng từ chối thì lời nhắc rơi im — chấp nhận, nhắc thụ động
        // không đáng dựng modal chặn tay người ta đang gõ.
        // Tiến trình KHÔNG có app bundle (test harness mood_pipeline_test chạy binary trần) mà
        // gọi UNUserNotificationCenter là ném NSInternalInconsistencyException không bắt được
        // (đã kiểm chứng thật) — API cũ chỉ lặng lẽ no-op. Rào lại để đường prompt test được.
        if ([NSBundle mainBundle].bundleIdentifier == nil) {
            g_popupShowing = NO;
            return;
        }
        UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
        content.title = @"Nhắc tâm - Mindful Keyboard";
        content.body = message;
        content.sound = [UNNotificationSound defaultSound];
        UNNotificationRequest *req = [UNNotificationRequest requestWithIdentifier:@"mindfulkey-mood-nudge"
                                                                          content:content
                                                                          trigger:nil];
        [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:req
                                                               withCompletionHandler:nil];
        g_popupShowing = NO;
    });
}

static void analyzeRecentTextAsync(const wstring& word) {
    // [MINDFUL] 2026-07-16 — Copy TRƯỚC khi tạo block, y như MoodBridge.mm bên iOS đã phải làm.
    // `word` là tham chiếu tới biến cục bộ của emitCommittedWord() (Engine.cpp:463), chết ngay khi
    // callback trả về. Block ObjC++ bắt biến KIỂU THAM CHIẾU bằng chính địa chỉ, KHÔNG sao chép
    // (chỉ biến kiểu giá trị mới được gọi copy ctor) — verify bằng test thật: trong block, &word
    // vẫn là ô nhớ đã chết, size 24 -> 0. Đọc trúng ô chưa bị giành thì chạy đúng, nên lỗi trông
    // như ngẫu nhiên; giành rồi thì hoặc mất chữ (size=0, iOS thấy recentText() rỗng), hoặc size
    // thành rác -> push_back ném length_error -> không ai bắt -> abort() (crash 2026-07-16 01:44).
    wstring wordCopy = word;
    dispatch_async(g_moodQueue, ^{
        if (!vMoodWatch)
            return;

        g_buffer.pushWord(wordCopy);
        SendRiskResult scored = SendRiskAnalyzer_Analyze(g_buffer.recentText());
        double risk = scored.risk;
        g_lastSendRisk = risk;

        // [MINDFUL] 2026-07-19 — cập nhật lớp "sông sống" (A2+A3). Đang trên g_moodQueue; khoá vì
        // main đọc ở LiveAmplitude/FetchLiveTrace. EMA làm mượt; vệt điểm dày tối đa 1/30s.
        long long nowTs = (long long)[NSDate date].timeIntervalSince1970;
        os_unfair_lock_lock(&g_liveLock);
        // [MINDFUL] Kiểm lại vMoodWatch NGAY TRONG khoá: nếu người dùng vừa tắt Nhắc tâm (SetEnabled
        // xoá sạch state dưới cùng khoá này) ngay sau khi block này đã qua check !vMoodWatch ở đầu,
        // thì đừng ghi "dư âm" câu cũ vào state vừa xoá — giữ đúng lời hứa "bật lại là phẳng lặng".
        if (vMoodWatch) {
            g_liveEma = kLiveEmaAlpha * risk + (1.0 - kLiveEmaAlpha) * g_liveEma;
            g_lastWordTs = nowTs;
            if (g_liveTrace == nil) g_liveTrace = [NSMutableArray array];
            if (g_liveTraceLastTs == 0 || (nowTs - g_liveTraceLastTs) >= (long long)kLiveSampleSeconds) {
                // checkin=NO: điểm RAM này luôn tự-đoán từ chữ gõ, không phải tự-thuật (xem
                // FetchLiveTrace bên dưới — nó trộn cùng key với MoodStoreMac_FetchSamplesSince,
                // giờ có thể mang checkin=YES cho phần nền persisted).
                [g_liveTrace addObject:@{@"ts": @(nowTs), @"value": @(g_liveEma), @"checkin": @NO}];
                g_liveTraceLastTs = nowTs;
                // Trim điểm cũ hơn 4h (mảng theo thứ tự thời gian nên cắt từ đầu).
                long long cutoff = nowTs - (long long)kLiveTraceMaxAge;
                NSUInteger drop = 0;
                for (NSDictionary *e in g_liveTrace) {
                    if ([e[@"ts"] longLongValue] < cutoff) drop++; else break;
                }
                if (drop > 0) [g_liveTrace removeObjectsInRange:NSMakeRange(0, drop)];
            }
        }
        os_unfair_lock_unlock(&g_liveLock);

        NSString *nsWord = [[NSString alloc] initWithBytes:wordCopy.data()
                                                    length:wordCopy.size() * sizeof(wchar_t)
                                                  encoding:NSUTF32LittleEndianStringEncoding];
        NSLog(@"[MindfulKey] Từ vừa gõ: %@, Độ rủi ro cảm xúc (risk): %f", nsWord, risk);

        g_sampleSum += risk;
        g_sampleCount++;

        // [MINDFUL] Bước 7 — đếm chuỗi câu căng thẳng liên tiếp, độc lập với ngưỡng cảnh báo
        // thụ động bên dưới. Câu dịu lại (risk thấp) reset chuỗi — "chuỗi" nghĩa là LIÊN TỤC.
        if (risk >= NudgeCoordinatorMac_RippleThreshold()) {
            g_tenseStreak++;
        } else {
            g_tenseStreak = 0;
        }
        if (g_tenseStreak >= NudgeCoordinatorMac_TenseStreakTrigger()) {
            g_tenseStreak = 0; // reset ngay để không rung lại liên tục cho cùng 1 đợt căng thẳng
            dispatch_async(dispatch_get_main_queue(), ^{
                BellMac_RingForTenseStreak();
            });
        }

        if (risk < kSendRiskThreshold)
            return;

        NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
        if (g_lastWarn > 0 && (now - g_lastWarn) < 15)
            return;
        g_lastWarn = now;

        showMindfulPrompt(warningForCategory(scored.topCategory));
        g_buffer.clear();
    });
}

double MoodWatchMac_LastSendRisk(void) {
    return g_lastSendRisk;
}

// [MINDFUL] 2026-07-19 — A2: đầu sóng "bây giờ" đã mượt + phai. Xem hợp đồng ở MoodWatchMac.h.
double MoodWatchMac_LiveAmplitude(void) {
    long long nowTs = (long long)[NSDate date].timeIntervalSince1970;
    os_unfair_lock_lock(&g_liveLock);
    double ema = g_liveEma;
    long long lastTs = g_lastWordTs;
    os_unfair_lock_unlock(&g_liveLock);

    if (lastTs == 0) return -1.0;                  // chưa gõ gì -> không có đầu sóng
    double idle = (double)(nowTs - lastTs);
    if (idle >= kLiveFadeSeconds) return -1.0;     // im đủ lâu -> phai hết, mặt hồ lặng (không vẽ)
    double fade = MKSmoothstep(1.0 - idle / kLiveFadeSeconds);   // 1 (vừa gõ) -> 0 (sắp im hẳn)
    return MKClamp01(ema * fade);
}

// [MINDFUL] 2026-07-19 — A3: vệt điểm dày cho sông "Ngay bây giờ". Trộn nền quá khứ persisted
// (phần TRƯỚC khi vệt RAM phiên này bắt đầu) với vệt RAM dày — tránh 2 lớp chấm chồng cùng 1 quãng.
NSArray<NSDictionary *> *MoodWatchMac_FetchLiveTrace(double windowSeconds) {
    long long nowTs = (long long)[NSDate date].timeIntervalSince1970;
    long long origin = nowTs - (long long)windowSeconds;

    NSArray<NSDictionary *> *live;
    long long firstLiveTs = 0;
    os_unfair_lock_lock(&g_liveLock);
    live = g_liveTrace ? [g_liveTrace copy] : @[];
    if (live.count > 0) firstLiveTs = [live.firstObject[@"ts"] longLongValue];
    os_unfair_lock_unlock(&g_liveLock);

    NSArray<NSDictionary *> *persisted = MoodStoreMac_FetchSamplesSince(windowSeconds);
    NSMutableArray<NSDictionary *> *out = [NSMutableArray array];
    for (NSDictionary *p in persisted) {
        long long ts = [p[@"ts"] longLongValue];
        if (ts < origin) continue;
        if (live.count > 0 && ts >= firstLiveTs) continue;   // vệt RAM đã phủ quãng này
        [out addObject:p];
    }
    for (NSDictionary *l in live) {
        if ([l[@"ts"] longLongValue] >= origin) [out addObject:l];
    }
    [out sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
        long long ta = [a[@"ts"] longLongValue], tb = [b[@"ts"] longLongValue];
        return ta < tb ? NSOrderedAscending : (ta > tb ? NSOrderedDescending : NSOrderedSame);
    }];
    return out;
}

void MoodWatchMac_OnWord(const wstring& word) {
    if (!vMoodWatch || word.empty())
        return;
    analyzeRecentTextAsync(word);
}

void MoodWatchMac_Init() {
    if (g_moodQueue == nil)
        g_moodQueue = dispatch_queue_create("mindful.keyboard.moodwatch", DISPATCH_QUEUE_SERIAL);
    vOnWordCommitted = MoodWatchMac_OnWord;

    // [MINDFUL] 2026-07-20 — KHÔI PHỤC bộ định thời 60 giây (g_sampleTimer).
    // Ở bản trước, ta đã gỡ bỏ nó để lắng nghe nhịp kMKMoodBeatNotification (chỉ đập mỗi 15-60 phút).
    // Nhưng đồ thị "sông cảm xúc" (EmotionRiverView) CẦN các mẫu lấy liên tục mỗi phút để nối thành một dải
    // sóng liền mạch. Nếu mẫu quá thưa (>20 phút), đồ thị sẽ chèn dấu NSNull và làm đứt đoạn hoàn toàn dòng sông.
    // kMKMoodBeatNotification giờ chỉ dùng cho khung hỏi thăm (checkin) ở PanelViewController, còn lưu sample
    // thì vẫn phải chạy độc lập mỗi 60 giây.
    static dispatch_source_t g_sampleTimer = nil;
    if (g_sampleTimer == nil) {
        g_sampleTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, g_moodQueue);
        dispatch_source_set_timer(g_sampleTimer, dispatch_time(DISPATCH_TIME_NOW, 60 * NSEC_PER_SEC),
                                  60 * NSEC_PER_SEC, 5 * NSEC_PER_SEC);
        dispatch_source_set_event_handler(g_sampleTimer, ^{
            if (g_sampleCount > 0) {
                double avg = g_sampleSum / g_sampleCount;
                g_sampleSum = 0.0;
                g_sampleCount = 0;
                MoodStoreMac_LogSampleEvent(avg);
            }
        });
        dispatch_resume(g_sampleTimer);
    }
}

void MoodWatchMac_Flush(void) {
    // [MINDFUL] Vá lỗi B (P0 — segfault) — TRƯỚC: nếu [NSApp terminate:] xảy ra TRƯỚC khi
    // MoodWatchMac_Init() từng chạy (vd cú thoát câm khi phát hiện OpenKey đang chạy, ở
    // AppDelegate.m applicationDidFinishLaunching), applicationWillTerminate: vẫn gọi hàm này,
    // và g_moodQueue lúc đó là NULL -> dispatch_sync(NULL, ...) -> SIGSEGV ở 0x50 (crash log
    // 2026-07-17, lặp 4-5 lần, khớp chính xác). Bất biến đúng: flush một hàng đợi CHƯA TỒN TẠI
    // = không có gì để flush.
    if (!g_moodQueue)
        return;
    dispatch_sync(g_moodQueue, ^{
        if (g_sampleCount > 0) {
            double avgRisk = g_sampleSum / g_sampleCount;
            MoodStoreMac_LogSampleEvent(avgRisk);
            g_sampleSum = 0.0;
            g_sampleCount = 0;
        }
    });
}

void MoodWatchMac_SetEnabled(int enabled) {
    vMoodWatch = enabled ? 1 : 0;
    [[NSUserDefaults standardUserDefaults] setInteger:vMoodWatch forKey:@"vMoodWatch"];
    // [MINDFUL] 2026-07-19 — tắt = xoá vệt "sông sống" trong RAM (đầu sóng + điểm dày), để bật lại
    // là mặt hồ phẳng lặng từ đầu, không còn dư âm câu cũ. Vệt này vốn ephemeral (không persist).
    if (!enabled) {
        os_unfair_lock_lock(&g_liveLock);
        g_liveEma = 0.0;
        g_lastWordTs = 0;
        g_liveTraceLastTs = 0;
        [g_liveTrace removeAllObjects];
        os_unfair_lock_unlock(&g_liveLock);
    }
    // [MINDFUL] Vá lỗi B — cùng bất biến với MoodWatchMac_Flush(): hàm này chạm g_moodQueue nên
    // cũng phải sống sót nếu lỡ được gọi trước MoodWatchMac_Init() (chưa xác nhận có đường gọi
    // thật nào trước Init, nhưng rẻ để thủ chắc thay vì vá mù một chỗ).
    if (!enabled && g_moodQueue) {
        dispatch_async(g_moodQueue, ^{
            g_buffer.clear();
        });
    }
}

int MoodWatchMac_IsEnabled() {
    return vMoodWatch != 0 ? 1 : 0;
}
