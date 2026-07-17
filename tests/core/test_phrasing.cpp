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

    if (gFail == 0)
        printf("\n=== XONG — TẤT CẢ PASS ===\n");
    else
        printf("\n=== XONG — %d CA SAI (make test sẽ đỏ) ===\n", gFail);
    return gFail == 0 ? 0 : 1;
}
