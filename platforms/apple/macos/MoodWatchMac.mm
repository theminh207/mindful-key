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

void MoodWatchMac_OnWord(const wstring& word) {
    if (!vMoodWatch || word.empty())
        return;
    analyzeRecentTextAsync(word);
}

void MoodWatchMac_Init() {
    if (g_moodQueue == nil)
        g_moodQueue = dispatch_queue_create("mindful.keyboard.moodwatch", DISPATCH_QUEUE_SERIAL);
    vOnWordCommitted = MoodWatchMac_OnWord;

    // [MINDFUL] 2026-07-16 — TỪNG có `g_sampleTimer` riêng ở đây: dispatch_source đập mỗi 60 giây,
    // tự đếm xem đã đủ vBellInterval chưa, mốc bắt đầu là lúc MoodWatchMac_Init() chạy. Chuông thì
    // đếm từ lúc BellMac_Init() chạy, khung chấm nhịp đếm từ lúc PanelViewController init — BA mốc
    // khác nhau nên chúng trôi lệch nhau vài phút, dù màn Chuông hứa "Một nhịp, hai vai".
    // Nay LẮNG NGHE nhịp chung do BellMac điểm (kMKMoodBeatNotification) thay vì tự đếm.
    // Nhịp đó bắn kể cả khi chuông tắt/hoãn/ngoài giờ, nên nhật ký vẫn ghi như trước — đúng hành vi
    // cũ của g_sampleTimer (nó chưa bao giờ phụ thuộc vBell).
    [[NSNotificationCenter defaultCenter] addObserverForName:kMKMoodBeatNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
        // Về đúng g_moodQueue mới chạm g_sampleSum/g_sampleCount — 2 biến này chỉ được đọc/ghi ở
        // hàng đợi đó (analyzeRecentTextAsync), đọc từ luồng khác là đua dữ liệu.
        dispatch_async(g_moodQueue, ^{
            if (g_sampleCount > 0) {
                double avg = g_sampleSum / g_sampleCount;
                g_sampleSum = 0.0;
                g_sampleCount = 0;
                MoodStoreMac_LogSampleEvent(avg);   // vẫn gọi trên g_moodQueue, y như bản cũ
            }
        });
    }];
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
