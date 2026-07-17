// test_phrasing.cpp
// Khoá hành vi của core/mood/MoodPhrasing — kể hình dạng một ngày thành câu, DÙNG CHUNG 3 vỏ.
//
// CÁC CÂU MONG ĐỢI KHÔNG PHẢI TỰ NGHĨ RA. Chúng lấy từ một lần chạy đối chiếu thật (2026-07-17):
// biên dịch bản core CẠNH bản đang chạy của macOS (platforms/apple/macos/MoodPhrasingMac.mm) trong
// cùng 1 binary rồi cho kể cùng một ngày — **18/18 ca trùng khít**, gồm cả ca đúng biên ngưỡng.
//
// BẪY MÚI GIỜ: KHÔNG hardcode epoch. CI chạy UTC, máy dev UTC+7 — cùng một epoch rơi vào buổi
// khác nhau, test sẽ đỏ ở CI mà xanh ở máy. Mọi mốc dựng từ GIỜ ĐỊA PHƯƠNG qua mktime().
//
// Build: xem tests/core/phrasing_build.sh

#include <cstdio>
#include <ctime>
#include <string>
#include <vector>
#include "MoodPhrasing.h"

using namespace std;

static int gFail = 0;

// Cùng lý do như test_send_risk.cpp: printf("%ls") gặp chữ Việt trong locale "C" là câm giữa
// chừng, nuốt luôn dòng báo ❌ -> test đỏ mà không ai đọc được đỏ ở đâu.
static string toUtf8(const wstring& in) {
    string s;
    for (size_t i = 0; i < in.size(); i++) {
        unsigned int cp = (unsigned int)in[i];
        if (cp < 0x80) s += (char)cp;
        else if (cp < 0x800) { s += (char)(0xC0|(cp>>6)); s += (char)(0x80|(cp&0x3F)); }
        else { s += (char)(0xE0|(cp>>12)); s += (char)(0x80|((cp>>6)&0x3F)); s += (char)(0x80|(cp&0x3F)); }
    }
    return s;
}

// Epoch của "hôm nay lúc H giờ 30, giờ địa phương".
static long long atHour(int h) {
    time_t now = time(NULL);
    struct tm lt;
#ifdef _WIN32
    localtime_s(&lt, &now);
#else
    localtime_r(&now, &lt);
#endif
    lt.tm_hour = h; lt.tm_min = 30; lt.tm_sec = 0;
    return (long long)mktime(&lt);
}

static void checkShape(const char* label, vector<MoodSample> samples, const wchar_t* expect) {
    wstring got = MoodPhrasingCore_DayShapeSentence(samples, 0.5);
    bool ok = (got == wstring(expect));
    if (!ok) gFail++;
    printf("  %-26s \"%s\"  [mong đợi: \"%s\"]  %s\n",
           label, toUtf8(got).c_str(), toUtf8(expect).c_str(), ok ? "✅" : "❌ SAI");
}

static void checkLabel(int hour, const wchar_t* expect) {
    wstring got = MoodPhrasingCore_TimeOfDayLabel(atHour(hour));
    bool ok = (got == wstring(expect));
    if (!ok) gFail++;
    printf("  %2dh giờ địa phương -> \"%s\"  [mong đợi: \"%s\"]  %s\n",
           hour, toUtf8(got).c_str(), toUtf8(expect).c_str(), ok ? "✅" : "❌ SAI");
}


static void checkShapeOf(const char* label, double peak, int gk, MoodDayShape expect) {
    MoodDayShape got = MoodPhrasingCore_DayShapeOf(peak, gk, 0.5);
    bool ok = (got == expect);
    if (!ok) gFail++;
    static const char* names[] = {"Calm","Rippled","Gated"};
    printf("  %-30s %-8s [mong đợi: %-8s] %s\n", label, names[got], names[expect], ok ? "✅" : "❌ SAI");
}

int main() {
    printf("=== MOOD PHRASING (core/mood — dùng chung 3 vỏ) ===\n");

    printf("\n--- Loại 1: thật thà khi KHÔNG có dữ liệu ---\n");
    // Ràng buộc hiến chương: im lặng của bàn phím KHÔNG phải bằng chứng của sự bình yên.
    checkShape("không có mẫu nào", {}, L"Chưa có nhịp nào hôm nay");

    printf("\n--- Loại 2: hình dạng ngày ---\n");
    checkShape("toàn êm",        {{atHour(8),0.1},{atHour(14),0.2}}, L"Hôm nay tới giờ vẫn êm");
    checkShape("1 buổi gợn",     {{atHour(8),0.9}}, L"Sáng có gợn");
    checkShape("2 buổi gợn",     {{atHour(8),0.9},{atHour(14),0.7}}, L"Sáng và chiều có gợn");
    checkShape("3 buổi gợn",     {{atHour(8),0.9},{atHour(12),0.8},{atHour(14),0.7}},
                                 L"Sáng, trưa và chiều có gợn");
    checkShape("cả 4 buổi gợn",  {{atHour(8),0.9},{atHour(12),0.8},{atHour(14),0.7},{atHour(20),0.6}},
                                 L"Sáng, trưa, chiều và tối có gợn");

    printf("\n--- Loại 3: \"phần lớn êm\" chỉ nói khi ĐÚNG là phần lớn ---\n");
    // 1 gợn / 3 êm -> êm chiếm đa số -> được nói
    checkShape("1 gợn, 3 êm",    {{atHour(8),0.9},{atHour(9),0.1},{atHour(10),0.1},{atHour(11),0.2}},
                                 L"Sáng có gợn, phần lớn êm");
    // 2 gợn / 2 êm -> KHÔNG đa số -> KHÔNG được nói. Nói bừa cho dịu tai là phán xét trá hình.
    checkShape("2 gợn, 2 êm (hoà)", {{atHour(8),0.9},{atHour(9),0.9},{atHour(10),0.1},{atHour(11),0.1}},
                                 L"Sáng có gợn");

    printf("\n--- Loại 4: biên ngưỡng (>= là gợn) ---\n");
    checkShape("đúng 0.5",       {{atHour(8),0.5}},    L"Sáng có gợn");
    checkShape("0.4999",         {{atHour(8),0.4999}}, L"Hôm nay tới giờ vẫn êm");

    printf("\n--- Loại 5: ranh giới buổi (PHẢI khớp kAxisHour* của dòng sông) ---\n");
    checkLabel(0,  L"buổi tối");
    checkLabel(4,  L"buổi tối");
    checkLabel(5,  L"buổi sáng");
    checkLabel(10, L"buổi sáng");
    checkLabel(11, L"buổi trưa");
    checkLabel(12, L"buổi trưa");
    checkLabel(13, L"buổi chiều");
    checkLabel(17, L"buổi chiều");
    checkLabel(18, L"buổi tối");
    checkLabel(23, L"buổi tối");


    printf("\n--- Loại 6: hình dạng ngày (gác cổng thắng mọi thứ) ---\n");
    checkShapeOf("êm cả ngày",                 0.2, 0, MoodDayShapeCalm);
    checkShapeOf("có gợn, chưa gác lần nào",   0.9, 0, MoodDayShapeRippled);
    checkShapeOf("gác 1 lần dù đỉnh thấp",     0.1, 1, MoodDayShapeGated);
    checkShapeOf("đúng biên 0.5 -> có gợn",    0.5, 0, MoodDayShapeRippled);

    printf("\n--- Loại 7: RỔ CÂU HỎI khớp hình dạng (ràng buộc hiến chương) ---\n");
    // Ngày êm KHÔNG BAO GIỜ được hỏi về cơn nóng không hề xảy ra. Đây là cả điểm của bản v2.1:
    // trước đó mọi câu bốc từ 1 rổ chung nên ngày phẳng lặng vẫn bị hỏi "điều gì khiến bạn dễ nóng
    // lên nhất?" — câu hỏi cãi thẳng cái quan sát nằm ngay trên nó.
    {
        bool calmClean = true, gatedRight = true;
        for (int i = 0; i < 8; i++) {   // 8 > 4 -> kiểm luôn việc quay vòng
            wstring q = MoodPhrasingCore_ReflectionQuestion(MoodDayShapeCalm, i);
            if (q.find(L"nóng") != wstring::npos || q.find(L"căng thẳng") != wstring::npos ||
                q.find(L"dừng lại trước khi gửi") != wstring::npos)
                calmClean = false;
            if (q.empty()) calmClean = false;
        }
        for (int i = 0; i < 8; i++) {
            wstring q = MoodPhrasingCore_ReflectionQuestion(MoodDayShapeGated, i);
            if (q.empty()) gatedRight = false;
        }
        if (!calmClean) gFail++;
        if (!gatedRight) gFail++;
        printf("  %-30s %s\n", "ngày êm không bị hỏi về cơn nóng", calmClean ? "✅" : "❌ SAI");
        printf("  %-30s %s\n", "rổ Gated quay vòng, không rỗng", gatedRight ? "✅" : "❌ SAI");

        // 3 rổ phải KHÁC nhau — cùng rổ nghĩa là phân loại hình dạng chẳng để làm gì.
        bool distinct = MoodPhrasingCore_ReflectionQuestion(MoodDayShapeCalm, 0) !=
                        MoodPhrasingCore_ReflectionQuestion(MoodDayShapeGated, 0) &&
                        MoodPhrasingCore_ReflectionQuestion(MoodDayShapeCalm, 0) !=
                        MoodPhrasingCore_ReflectionQuestion(MoodDayShapeRippled, 0);
        if (!distinct) gFail++;
        printf("  %-30s %s\n", "3 rổ khác nhau thật", distinct ? "✅" : "❌ SAI");
    }

    if (gFail == 0)
        printf("\n=== XONG — TẤT CẢ PASS ===\n");
    else
        printf("\n=== XONG — %d CA SAI (make test sẽ đỏ) ===\n", gFail);
    return gFail == 0 ? 0 : 1;
}
