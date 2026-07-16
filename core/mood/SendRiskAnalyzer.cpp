//
//  SendRiskAnalyzer.cpp
//  mindful-key — core/mood (C++ THUẦN, dùng chung mọi vỏ)
//
//  Bảng LEX/LEX_SUB, categoryWeight(), collapseRuns(), luật khớp và công thức bão hoà
//  1 - e^(-raw/5) RÚT NGUYÊN XI từ platforms/apple/macos/MoodWatchMac.mm (bản macOS là CHUẨN
//  HÀNH VI). Không diễn giải lại, không "cải tiến" — mọi khác biệt số học so với bản macOS đều
//  là lỗi của file này.
//

#include "SendRiskAnalyzer.h"

#include <cmath>
#include <cstdlib>
#include <map>

using namespace std;

struct MoodLex {
    const wchar_t* word;
    int score;
    const wchar_t* category;
};

// "giận" (thù địch, hướng RA NGOÀI người khác) gần như quyết định risk — đó là thứ gửi đi thì
// gây hại. "buồn/mệt/lo" là trạng thái RIÊNG của mình, gửi đi ít hại hơn nhiều nên chỉ đóng góp
// một phần. "+" (tích cực) kéo risk xuống.
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

// Chửi thề nặng: khớp DÍNH LIỀN ở bất cứ đâu (không cần dấu cách 2 bên).
static const wchar_t* LEX_SUB[] = {
    L"địt", L"cặc", L"buồi", L"đụmẹ", L"địtmẹ",
    L"vcl", L"vkl", L"clgt", L"fuck", L"shit", L"bitch",
};

// Hạ chữ thường MỘT đơn vị mã. Chỉ phủ ASCII + chữ tiếng Việt dựng sẵn — đủ và đúng phạm vi,
// vì lexicon trên chỉ gồm tiếng Việt và vài từ tiếng Anh. Chữ hệ khác không hạ được thì cũng
// không khớp từ nào, nên không đổi kết quả.
static wchar_t toLowerVi(wchar_t c) {
    if (c >= L'A' && c <= L'Z')
        return (wchar_t)(c + 32);

    // Latin-1 Supplement: À-Þ -> à-þ. U+00D7 là dấu nhân (×), không phải chữ.
    if (c >= 0x00C0 && c <= 0x00DE && c != 0x00D7)
        return (wchar_t)(c + 0x20);

    // Chữ tiếng Việt nằm rải ở Latin Extended-A/B — chỉ liệt kê đúng 6 chữ dự án cần,
    // không quét cả dải (các dải đó có ngoại lệ không theo luật chẵn/lẻ).
    if (c == 0x0102) return 0x0103;  // Ă -> ă
    if (c == 0x0110) return 0x0111;  // Đ -> đ
    if (c == 0x0128) return 0x0129;  // Ĩ -> ĩ
    if (c == 0x0168) return 0x0169;  // Ũ -> ũ
    if (c == 0x01A0) return 0x01A1;  // Ơ -> ơ
    if (c == 0x01AF) return 0x01B0;  // Ư -> ư

    // Latin Extended Additional U+1EA0..U+1EF9: toàn bộ chữ Việt có dấu (Ạ ạ Ả ả Ấ ấ ... Ỹ ỹ).
    // Dải này xếp thành cặp CHẴN=hoa / LẺ=thường liên tiếp, nên chẵn -> +1 là đủ.
    if (c >= 0x1EA0 && c <= 0x1EF9 && (c % 2 == 0))
        return (wchar_t)(c + 1);

    return c;
}

std::wstring SendRiskAnalyzer_Normalize(const wstring& text) {
    wstring out;
    out.reserve(text.size());
    for (size_t i = 0; i < text.size(); i++) {
        wchar_t c = text[i];
        // Dấu câu -> dấu cách, để "giận." vẫn khớp needle " giận ". Giữ đúng danh sách của
        // MoodWatchMac.mm:121 — KHÔNG mở rộng thêm.
        if (c == L',' || c == L'.' || c == L'?' || c == L'!' ||
            c == L';' || c == L':' || c == L'\n' || c == L'\r') {
            out.push_back(L' ');
        } else {
            out.push_back(toLowerVi(c));
        }
    }
    return out;
}

// Bóp ký tự lặp >= 3 lần về 1 ("đmmmm" -> "đm"). Giữ nguyên cặp đôi để không phá "stress".
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

SendRiskResult SendRiskAnalyzer_Analyze(const wstring& recentText) {
    SendRiskResult result;
    result.risk = 0.0;

    wstring s = L" " + SendRiskAnalyzer_Normalize(recentText) + L" ";
    s = collapseRuns(s);

    double raw = 0.0;
    bool hardHit = false;
    map<wstring, int> negativeByCategory;

    // Tầng 1: khớp NGUYÊN TỪ (cần dấu cách 2 bên) -> an toàn, ít báo nhầm.
    for (size_t i = 0; i < sizeof(LEX) / sizeof(LEX[0]); i++) {
        wstring needle = wstring(L" ") + LEX[i].word + L" ";
        if (s.find(needle) != wstring::npos) {
            double magnitude = std::abs((double)LEX[i].score) * categoryWeight(LEX[i].category);
            raw += (LEX[i].score < 0) ? magnitude : -magnitude;  // âm tăng risk; dương giảm risk
            if (LEX[i].score < 0)
                negativeByCategory[LEX[i].category] += -LEX[i].score;
        }
    }

    // Tầng 2: chửi thề nặng, khớp dính liền. Cố ý KHÔNG cộng vào raw — nó ép sàn raw ở dưới.
    for (size_t i = 0; i < sizeof(LEX_SUB) / sizeof(LEX_SUB[0]); i++) {
        if (s.find(LEX_SUB[i]) != wstring::npos) {
            negativeByCategory[L"giận"] += 4;
            hardHit = true;
        }
    }

    if (raw < 0) raw = 0;
    if (hardHit && raw < 9.0) raw = 9.0;  // chửi thề nặng -> luôn đẩy risk lên cao

    // Bão hoà 1 - e^(-raw/K): raw=0 -> 0, tăng dần, không bao giờ chạm hẳn 1.
    // Không nhắm độ chính xác tuyệt đối — xem docs/PRD.md.
    double risk = 1.0 - std::exp(-raw / 5.0);
    if (risk > 1.0) risk = 1.0;
    result.risk = risk;

    int best = 0;
    for (map<wstring, int>::iterator it = negativeByCategory.begin();
         it != negativeByCategory.end(); ++it) {
        if (it->second > best) {
            best = it->second;
            result.topCategory = it->first;
        }
    }

    return result;
}
