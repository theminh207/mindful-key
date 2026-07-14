//
//  MoodWatchMac.mm
//  ModernKey
//
//  [MINDFUL] macOS shell for mood watching.
//  The engine callback runs on the CGEventTap path, so this file immediately
//  dispatches work to a serial background queue and returns.
//

#import <Cocoa/Cocoa.h>
#include <map>
#include <cmath>
#include <algorithm>
#include "Engine.h"
#include "MoodBuffer.h"
#include "MoodWatchMac.h"
#include "BellMac.h"
#include "NudgeCoordinatorMac.h"
#import "MoodStoreMac.h"

using namespace std;

int vMoodWatch = 1;

struct MoodLex {
    const wchar_t* word;
    int score;
    const wchar_t* category;
};

static MoodBuffer g_buffer(15);
static dispatch_queue_t g_moodQueue;
static NSTimeInterval g_lastWarn = 0;
static BOOL g_popupShowing = NO;
static NSMutableArray *g_activeAlerts = nil;
static double g_lastSendRisk = 0.0;

// [MINDFUL] Thu hẹp bài toán: không còn phân loại "đang cảm xúc gì", chỉ còn 1 câu hỏi —
// "câu này mà GỬI cho người khác thì hại tới đâu?" -> 1 điểm số trong [0,1].
// "giận" (thù địch, hướng ra ngoài) gần như quyết định risk; "buồn/mệt/lo" (trạng thái riêng)
// chỉ đóng góp một phần nhỏ; "+" (tích cực) kéo risk xuống. Cùng công thức với
// prototype/mood_demo.cpp — xem docs/SEND-RISK-MODEL-SPEC.md để thay bằng PhoBERT ONNX sau này.
static const double kSendRiskThreshold = 0.5;

// [MINDFUL] Bước 7 — chuông data-driven: rung sau 1 CHUỖI câu căng thẳng liên tiếp, không chỉ
// theo lịch cố định. Ngưỡng thấp hơn kSendRiskThreshold có chủ đích — đây là phát hiện "đang
// dồn nén dần", không phải "chuẩn bị gửi thứ gây hại", nên bắt sớm hơn hợp lý.
static int g_tenseStreak = 0;

static double g_sampleSum = 0.0;
static int g_sampleCount = 0;
static NSTimeInterval g_sampleLastTime = 0;
static dispatch_source_t g_sampleTimer = nil;

static double categoryWeight(const wstring& cat) {
    if (cat == L"giận") return 1.0;
    if (cat == L"+")    return 0.6;
    return 0.35;
}

static const MoodLex LEX[] = {
    { L"buồn", -2, L"buồn" }, { L"buồn bã", -2, L"buồn" },
    { L"chán", -2, L"buồn" }, { L"chán đời", -3, L"buồn" },
    { L"tuyệt vọng", -3, L"buồn" }, { L"bế tắc", -2, L"buồn" },
    { L"cô đơn", -2, L"buồn" }, { L"khóc", -2, L"buồn" },

    { L"giận", -2, L"giận" }, { L"tức", -2, L"giận" },
    { L"tức giận", -3, L"giận" }, { L"bực", -2, L"giận" },
    { L"bực mình", -2, L"giận" }, { L"cáu", -2, L"giận" },
    { L"khó chịu", -2, L"giận" }, { L"ghét", -2, L"giận" },

    { L"mệt", -1, L"mệt" }, { L"mệt mỏi", -2, L"mệt" },
    { L"stress", -2, L"mệt" }, { L"áp lực", -2, L"mệt" },
    { L"căng thẳng", -2, L"mệt" }, { L"kiệt sức", -3, L"mệt" },

    { L"lo", -1, L"lo" }, { L"lo lắng", -2, L"lo" },
    { L"sợ", -1, L"lo" }, { L"sợ hãi", -2, L"lo" },

    { L"đm", -4, L"giận" }, { L"dm", -4, L"giận" },
    { L"đcm", -4, L"giận" }, { L"dcm", -4, L"giận" },
    { L"đéo", -3, L"giận" }, { L"vl", -2, L"giận" },

    { L"vui", 2, L"+" }, { L"vui vẻ", 2, L"+" },
    { L"hạnh phúc", 3, L"+" }, { L"yêu", 2, L"+" },
    { L"thích", 1, L"+" }, { L"tuyệt vời", 3, L"+" },
    { L"ổn", 1, L"+" }, { L"bình an", 2, L"+" },
    { L"cảm ơn", 2, L"+" }, { L"thoải mái", 2, L"+" },
};

static const wchar_t* LEX_SUB[] = {
    L"địt", L"cặc", L"buồi", L"đụmẹ", L"địtmẹ",
    L"vcl", L"vkl", L"clgt", L"fuck", L"shit", L"bitch",
};

static wstring collapseRuns(const wstring& in) {
    wstring out;
    out.reserve(in.size());
    size_t i = 0;
    while (i < in.size()) {
        wchar_t c = in[i];
        size_t j = i;
        while (j < in.size() && in[j] == c) j++;
        size_t run = j - i;
        if (run >= 3)
            out += c;
        else
            out.append(run, c);
        i = j;
    }
    return out;
}

static wstring lowerText(const wstring& in) {
    NSString *s = [[NSString alloc] initWithBytes:in.data()
                                          length:in.size() * sizeof(wchar_t)
                                        encoding:NSUTF32LittleEndianStringEncoding];
    NSString *lower = [s lowercaseString];
    wstring out;
    for (NSUInteger i = 0; i < [lower length]; i++) {
        unichar ch = [lower characterAtIndex:i];
        out.push_back((wchar_t)ch);
    }
    return out;
}

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

        if ([NSUserNotificationCenter class]) {
            NSUserNotification *note = [[NSUserNotification alloc] init];
            note.title = @"Nhắc tâm - Mindful Keyboard";
            note.informativeText = message;
            note.soundName = NSUserNotificationDefaultSoundName;
            [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:note];
            g_popupShowing = NO;
            return;
        }

        if (g_activeAlerts == nil)
            g_activeAlerts = [[NSMutableArray alloc] init];

        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Nhắc tâm - Mindful Keyboard";
        alert.informativeText = message;
        [alert addButtonWithTitle:@"OK"];
        [g_activeAlerts addObject:alert];
        [alert.window setLevel:NSStatusWindowLevel];
        [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowWillCloseNotification
                                                          object:alert.window
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification *note) {
            [g_activeAlerts removeObject:alert];
            g_popupShowing = NO;
        }];
        [alert.window makeKeyAndOrderFront:nil];
    });
}

static void analyzeRecentTextAsync(const wstring& word) {
    dispatch_async(g_moodQueue, ^{
        if (!vMoodWatch)
            return;

        g_buffer.pushWord(word);
        wstring s = L" " + lowerText(g_buffer.recentText()) + L" ";
        s = collapseRuns(s);

        double raw = 0.0;
        bool hardHit = false;
        map<wstring, int> negativeByCategory;

        for (size_t i = 0; i < sizeof(LEX) / sizeof(LEX[0]); i++) {
            wstring needle = wstring(L" ") + LEX[i].word + L" ";
            if (s.find(needle) != wstring::npos) {
                double magnitude = std::abs((double)LEX[i].score) * categoryWeight(LEX[i].category);
                raw += (LEX[i].score < 0) ? magnitude : -magnitude; // âm (xấu) tăng risk; dương (tích cực) giảm risk
                if (LEX[i].score < 0)
                    negativeByCategory[LEX[i].category] += -LEX[i].score;
            }
        }

        for (size_t i = 0; i < sizeof(LEX_SUB) / sizeof(LEX_SUB[0]); i++) {
            if (s.find(LEX_SUB[i]) != wstring::npos) {
                negativeByCategory[L"giận"] += 4;
                hardHit = true;
            }
        }

        if (raw < 0) raw = 0;
        if (hardHit) raw = std::max(raw, 9.0); // chửi thề/xúc phạm nặng -> luôn đẩy risk lên cao
        // Hàm bão hòa 1 - e^(-raw/K): raw=0 -> risk=0, tăng dần, không bao giờ chạm hẳn 1
        // (không nhắm độ chính xác tuyệt đối — xem docs/PRD.md).
        double risk = 1.0 - std::exp(-raw / 5.0);
        if (risk > 1.0) risk = 1.0;
        g_lastSendRisk = risk;

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

        wstring top;
        int best = 0;
        for (map<wstring, int>::iterator it = negativeByCategory.begin(); it != negativeByCategory.end(); ++it) {
            if (it->second > best) {
                best = it->second;
                top = it->first;
            }
        }

        showMindfulPrompt(warningForCategory(top));
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

    if (g_sampleTimer == nil) {
        g_sampleTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, g_moodQueue);
        dispatch_source_set_timer(g_sampleTimer, dispatch_time(DISPATCH_TIME_NOW, 60 * NSEC_PER_SEC), 60 * NSEC_PER_SEC, 1 * NSEC_PER_SEC);
        dispatch_source_set_event_handler(g_sampleTimer, ^{
            NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
            if (g_sampleLastTime == 0) g_sampleLastTime = now;
            
            extern int vBellInterval;
            int intervalMins = vBellInterval > 0 ? vBellInterval : 60;
            if (now - g_sampleLastTime >= intervalMins * 60.0) {
                if (g_sampleCount > 0) {
                    double avg = g_sampleSum / g_sampleCount;
                    MoodStoreMac_LogSampleEvent(avg);
                    g_sampleSum = 0.0;
                    g_sampleCount = 0;
                }
                g_sampleLastTime = now;
            }
        });
        dispatch_resume(g_sampleTimer);
    }
}

void MoodWatchMac_SetEnabled(int enabled) {
    vMoodWatch = enabled ? 1 : 0;
    [[NSUserDefaults standardUserDefaults] setInteger:vMoodWatch forKey:@"vMoodWatch"];
    if (!enabled) {
        dispatch_async(g_moodQueue, ^{
            g_buffer.clear();
        });
    }
}

int MoodWatchMac_IsEnabled() {
    return vMoodWatch != 0 ? 1 : 0;
}
