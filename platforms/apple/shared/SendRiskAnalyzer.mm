//
//  SendRiskAnalyzer.mm
//  mindful-key — shared (macOS + iOS)
//
//  [MINDFUL] Story 2.2 (Approach B). Bảng `LEX`/`LEX_SUB`, `categoryWeight()`,
//  `collapseRuns()`/`lowerText()` (chuẩn hoá chuỗi), và công thức bão hoà `1 - e^(-raw/5)` RÚT
//  NGUYÊN XI từ platforms/apple/macos/MoodWatchMac.mm dòng 24-89/91-120/213-216 (chỉ ĐỌC để rút —
//  file macOS đó KHÔNG bị sửa 1 dòng). Không PhoBERT/ONNX, không network, không log nội dung câu
//  đã phân tích ra bất kỳ đâu — chỉ con số risk `double` được phép quan sát.
//
//  `lowerText()` dùng NSString (initWithBytes:...NSUTF32LittleEndianStringEncoding) — API
//  Foundation thuần, có sẵn trên iOS không cần đổi gì (đối chiếu MoodWatchMac.mm: import Cocoa.h
//  ở đầu file đó chỉ dùng cho phần popup/NSAlert, không dùng cho lowerText).
//

#import <Foundation/Foundation.h>
#include <algorithm>
#include <cmath>
#include "SendRiskAnalyzer.h"

using namespace std;

struct MoodLex {
    const wchar_t* word;
    int score;
    const wchar_t* category;
};

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

double SendRiskAnalyzer_Analyze(const wstring& recentText) {
    wstring s = L" " + lowerText(recentText) + L" ";
    s = collapseRuns(s);

    double raw = 0.0;
    bool hardHit = false;

    for (size_t i = 0; i < sizeof(LEX) / sizeof(LEX[0]); i++) {
        wstring needle = wstring(L" ") + LEX[i].word + L" ";
        if (s.find(needle) != wstring::npos) {
            double magnitude = std::abs((double)LEX[i].score) * categoryWeight(LEX[i].category);
            raw += (LEX[i].score < 0) ? magnitude : -magnitude; // âm (xấu) tăng risk; dương (tích cực) giảm risk
        }
    }

    for (size_t i = 0; i < sizeof(LEX_SUB) / sizeof(LEX_SUB[0]); i++) {
        if (s.find(LEX_SUB[i]) != wstring::npos) {
            hardHit = true;
        }
    }

    if (raw < 0) raw = 0;
    if (hardHit) raw = std::max(raw, 9.0); // chửi thề/xúc phạm nặng -> luôn đẩy risk lên cao

    // Hàm bão hòa 1 - e^(-raw/K): raw=0 -> risk=0, tăng dần, không bao giờ chạm hẳn 1.
    double risk = 1.0 - std::exp(-raw / 5.0);
    if (risk > 1.0) risk = 1.0;
    return risk;
}
