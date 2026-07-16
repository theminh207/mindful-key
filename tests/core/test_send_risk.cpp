// test_send_risk.cpp
// Khoá hành vi của core/mood/SendRiskAnalyzer — bộ não chấm điểm DÙNG CHUNG cho macOS · iOS ·
// Windows. Nó lệch 1 con số là CẢ BA vỏ lệch theo, và nhật ký/dòng sông giữa các máy hết so được.
//
// CÁC SỐ MONG ĐỢI DƯỚI ĐÂY KHÔNG PHẢI TỰ NGHĨ RA. Chúng lấy từ một lần chạy đối chiếu thật
// (2026-07-16): biên dịch bản này CẠNH bản đang chạy của iOS (platforms/apple/shared/
// SendRiskAnalyzer.mm) trong cùng 1 binary rồi cho chấm cùng input — 25/27 ca trùng khít tới
// 1e-12. Hai ca lệch là hai ca DẤU CÂU, nơi bản iOS sai và bản này theo bản macOS (chuẩn hành vi):
// xem docs/FRICTION-LOG.md 2026-07-16 "hai bản lexicon đã trôi lệch".
//
// Build: xem tests/core/send_risk_build.sh

#include <cmath>
#include <cstdio>
#include <string>
#include "SendRiskAnalyzer.h"

using namespace std;

static int gFail = 0;   // exit code != 0 để make/CI gate được khi có regression

// CẤM dùng printf("%ls") ở đây: gặp chữ tiếng Việt trong locale "C" nó câm GIỮA CHỪNG, nuốt
// luôn cả dòng báo ❌ SAI -> test đỏ mà không ai đọc được đỏ ở đâu. Đổi sang UTF-8 rồi in %s,
// y hệt cách test_engine.cpp đã làm (hàm toUtf8 bên đó).
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

static void checkRisk(const char* label, const wstring& text, double expect) {
    double got = SendRiskAnalyzer_Analyze(text).risk;
    bool ok = fabs(got - expect) < 1e-6;
    if (!ok) gFail++;
    printf("  %-30s risk=%.6f  [mong đợi: %.6f]  %s\n",
           label, got, expect, ok ? "✅" : "❌ SAI");
}

static void checkCategory(const char* label, const wstring& text, const wchar_t* expect) {
    wstring got = SendRiskAnalyzer_Analyze(text).topCategory;
    bool ok = (got == wstring(expect));
    if (!ok) gFail++;
    printf("  %-30s cat=\"%s\"  [mong đợi: \"%s\"]  %s\n",
           label, toUtf8(got).c_str(), toUtf8(expect).c_str(), ok ? "✅" : "❌ SAI");
}

int main() {
    printf("=== SEND-RISK ANALYZER (core/mood — dùng chung 3 vỏ) ===\n");

    printf("\n--- Loại 1: không có gì đáng lo -> risk 0 ---\n");
    checkRisk("chuỗi rỗng",            L"",                  0.0);
    checkRisk("câu trung tính",        L"xin chào các bạn",  0.0);
    checkRisk("câu tích cực",          L"tôi vui",           0.0);   // "+" kéo raw âm -> kẹp về 0
    checkRisk("vui lấn át mệt",        L"tôi vui nhưng hơi mệt", 0.0);

    printf("\n--- Loại 2: công thức bão hoà 1 - e^(-raw/5) ---\n");
    checkRisk("giận (-2 × 1.0)",       L"tôi giận",          0.329680);
    checkRisk("tức + tức giận cộng dồn", L"tôi rất tức giận",  0.753403);
    checkRisk("mệt (-1 × 0.35) nhẹ",   L"mệt quá!",          0.067606);
    checkRisk("mệt + mệt mỏi cộng dồn", L"tôi mệt mỏi",       0.189416);
    checkRisk("chửi nhẹ (-4 × 1.0)",   L"đm",                0.550671);

    printf("\n--- Loại 3: chửi nặng ép sàn raw = 9 (khớp dính liền, khỏi cần dấu cách) ---\n");
    checkRisk("tục nặng tiếng Việt",   L"địt mẹ",            0.834701);
    checkRisk("viết tắt tục",          L"vcl",               0.834701);
    checkRisk("tục tiếng Anh",         L"fuck you",          0.834701);

    printf("\n--- Loại 4: hạ chữ thường TIẾNG VIỆT bằng C++ thuần (không nhờ NSString của Apple) ---\n");
    checkRisk("viết HOA toàn bộ",      L"TÔI GIẬN",          0.329680);
    checkRisk("viết Hoa Đầu Từ",       L"Tôi Giận",          0.329680);
    checkRisk("Đ hoa (Latin Ext-A)",   L"ĐM",                0.550671);
    checkRisk("Ư hoa (Latin Ext-B)",   L"BỰC MÌNH",          0.550671);

    // Đây chính là ca đã phơi ra chuyện 2 bản photo trôi lệch: bản iOS cũ KHÔNG coi dấu câu là
    // dấu tách từ nên "tôi giận." chấm 0.0 (mù hoàn toàn), còn bản macOS chấm 0.329680. Nay iOS
    // đã dời sang dùng chính file này nên hết lệch — ca test ở lại để nó không lệch LẦN NỮA.
    printf("\n--- Loại 5: dấu câu = dấu tách từ ---\n");
    checkRisk("dấu chấm cuối câu",     L"tôi giận.",         0.329680);
    checkRisk("dấu phẩy sau từ",       L"giận, thật",        0.329680);
    checkRisk("xuống dòng",            L"tôi giận\nthật",    0.329680);

    printf("\n--- Loại 6: bóp ký tự lặp >= 3 ---\n");
    checkRisk("kéo dài chữ cuối",      L"đmmmm",             0.550671);
    checkRisk("kéo dài chữ cuối 2",    L"vlllll",            0.329680);
    checkRisk("cặp đôi KHÔNG bị bóp",  L"stress",            0.130642);   // giữ "ss" -> vẫn khớp

    printf("\n--- Loại 7: danh mục nặng nhất (chỉ để CHỌN CHỮ cho câu nhắc, không dán nhãn) ---\n");
    checkCategory("không có gì tiêu cực", L"xin chào",       L"");
    checkCategory("giận",                 L"tôi giận",       L"giận");
    checkCategory("buồn",                 L"cô đơn",         L"buồn");
    checkCategory("mệt",                  L"căng thẳng quá", L"mệt");
    checkCategory("lo",                   L"lo lắng",        L"lo");
    checkCategory("tục nặng -> giận",     L"vcl",            L"giận");

    if (gFail == 0)
        printf("\n=== XONG — TẤT CẢ PASS ===\n");
    else
        printf("\n=== XONG — %d CA SAI (make test sẽ đỏ) ===\n", gFail);
    return gFail == 0 ? 0 : 1;
}
