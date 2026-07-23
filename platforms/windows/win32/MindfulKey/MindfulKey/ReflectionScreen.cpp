//
// ReflectionScreen.cpp — [MINDFUL] màn "Soi lại hôm nay" + dòng sông cảm xúc. Bản Windows.
// File MỚI của dự án mindful-keyboard (không thuộc MindfulKey gốc).
//
// Đối ứng của platforms/apple/macos/{ReflectionScreenMac,EmotionRiverView}.mm — macOS là CHUẨN
// HÀNH VI. Phần "nói gì" (hình dạng ngày, câu hỏi, câu quan sát) đã nằm ở core/mood/MoodPhrasing
// nên file này chỉ lo "vẽ ra sao" — đúng ranh giới: vỏ không chép logic bộ não.
//
// ── BA LUẬT VẼ, ĐỪNG "CẢI TIẾN" MẤT ──
//
// 1. KHÔNG CÓ MẪU = KHÔNG VẼ GÌ (decision-log dec.4). Không đường giả, không chấm giả. Mặt nước
//    phẳng vẽ ra sẽ nói dối rằng "đã đo, thấy bình yên" — trong khi sự thật là không có dữ liệu.
//
// 2. VỊ TRÍ NGANG TÍNH TỪ GIỜ THẬT, không từ thứ tự mẫu. Bản macOS từng dùng `mx = m/(k-1)*w` nên
//    chấm cuối LUÔN dính mép phải, tức luôn nằm dưới nhãn "Tối" kể cả khi nó ghi lúc 10h sáng.
//    Máy chủ dự án có 7 mẫu trong 48 phút buổi sáng mà sông vẽ ra như trọn một ngày — nhãn
//    Sáng/Trưa/Chiều/Tối thành ra nói dối, và cãi luôn màn Soi lại (vá 2026-07-16). Đừng lặp lại.
//
// 3. TRỤC THỜI GIAN ≠ MẶT NƯỚC. Nét đứt, màu stone mờ, chạy suốt ngày để mắt nối sáng→tối thành
//    MỘT dòng. Nó là TRỤC (cùng họ với nhãn buổi), không phải nước "phẳng lặng". Nước teal đặc +
//    chấm vẫn CHỈ ở chỗ có mẫu thật.
//
// Trục dọc = CƯỜNG ĐỘ, không phải valence. Không có tốt/xấu, không đỏ/xanh (HIẾN CHƯƠNG §2.3).
//
#include "stdafx.h"
#include "ReflectionScreen.h"
#include "MoodStore.h"
#include "NotesHistory.h"   // [MINDFUL] F5 — link "Những dòng đã viết →" mở cửa sổ lịch sử
#include "AppDelegate.h"    // [MINDFUL] F5 — link "Chỉnh chuông…" mở Cài đặt → Chuông (onBellSettings)
#include "NudgeCoordinator.h"
#include "Bell.h"
#include "BrandPalette.h"
#include "BrandControls.h"   // [MINDFUL] BrandControls_FillRect/DrawCardHeader/Font + enum BrandFontRole — dùng ở DrawRiver/panel, thiếu là MSVC báo "not declared"
#include "../../../../../core/mood/MoodPhrasing.h"
#include <objidl.h>    // PHẢI đứng TRƯỚC gdiplus.h: GdiplusHeaders/GdiplusImaging dùng kiểu COM
                      // (PROPID, IStream, IImageBytes) mà WIN32_LEAN_AND_MEAN trong stdafx.h cắt
                      // khỏi windows.h. Thiếu nó thì lỗi nổ ra TRONG header của Microsoft, nhìn
                      // như SDK hỏng — thật ra là thiếu include của mình. Lần thứ 3 cờ này cắn
                      // trong cùng 1 phiên (trước đó: mmsystem.h cho chuông, commdlg.h cho hộp
                      // chọn tệp). ĐỪNG "dọn cho gọn".
#include <gdiplus.h>
#include <commctrl.h>   // [MINDFUL] F5 — EM_SETCUEBANNER (placeholder ô ghi)
#include <vector>
#include <string>
#include <cmath>

#pragma comment(lib, "gdiplus.lib")

using namespace std;
using namespace Gdiplus;

// Hằng vẽ — khớp EmotionRiverView.mm.
static const REAL kWaveStepX   = 3.0f;    // bước lấy mẫu khi vẽ đường
static const REAL kWaveFreq    = 0.19f;   // sin(x * 0.19) — nhịp gợn theo PIXEL, không theo số mẫu,
                                          // nên gợn không đổi khi mẫu thưa/dày
static const REAL kWaveLineW   = 2.2f;
static const REAL kDotDiameter = 6.6f;
static const REAL kMaxWaveFrac = 0.42f;   // biên độ tối đa = 42% chiều cao vùng vẽ

static ULONG_PTR g_gdiplusToken = 0;
static vector<MoodSample> g_samples;
static MoodTodaySummary   g_summary;

// [MINDFUL] 2026-07-23 — đồng bộ macOS (EmotionRiverView.mm, MKWaveSide): VẪN 1 trục biên độ
// (KHÔNG thêm nghĩa tích cực/tiêu cực, decision-log 2026-07-20 "giữ 1 trục"), chỉ đổi CÁCH VẼ để
// dáng sóng lên/xuống tự nhiên thay vì luôn nhô 1 chiều. Chiều lên/xuống CHỈ trang trí — tính từ
// timestamp TUYỆT ĐỐI của chính điểm đó, KHÔNG dựa vào thứ tự trong mảng/số điểm lân cận (tránh
// lặp lại đúng bug "sóng nhảy mỗi lần refresh" đã vá — index chẵn/lẻ từng quyết định nhô/chìm).
// Biên độ (khoảng lệch trục) vẫn = ĐÚNG risk thật, KHÔNG co theo pha — câu càng căng vẫn luôn lệch
// trục rõ, chỉ khác chiều lệch. `kTwoPi` viết literal (không dùng M_PI — MSVC cần _USE_MATH_DEFINES
// trước <cmath>, tránh phụ thuộc macro thêm cho một hằng số).
static const double kWaveCyclePeriodSeconds = 3.0 * 3600.0;
static const double kTwoPi = 6.283185307179586;

static REAL WaveSide(long long ts) {
    double phase = kTwoPi * ((double)ts / kWaveCyclePeriodSeconds);
    return (sin(phase) >= 0.0) ? 1.0f : -1.0f;
}

// ── Dòng sông ──

// Vị trí ngang 0..1 của một mẫu = GIỜ THẬT trong ngày. Xem luật 2 ở đầu file.
static REAL XFractionOf(long long ts, time_t originSec, double spanSec, REAL maxFrac) {
    double secs = (double)(ts - (long long)originSec);
    if (secs < 0) secs = 0;
    if (secs > spanSec) secs = spanSec;
    return (REAL)((secs / spanSec) * maxFrac);
}

// Có nước ở vị trí xf không, và biên độ bao nhiêu? false = quãng trống.
// Trống ở: trước mẫu đầu, sau mẫu cuối, và giữa 2 mẫu cách nhau QUÁ XA về thời gian.
//
// "Quá xa" = hơn 2 nhịp chuông. KHÔNG phải con số tôi bịa: kho chỉ ghi 1 mẫu khi nhịp đó CÓ gõ,
// nên 2 mẫu cách nhau >2 nhịp nghĩa là ở giữa có ít nhất 1 nhịp trọn vẹn không gõ gì. Nối nước
// qua đó là bịa — đúng thứ dec.4 cấm.
static bool AmpAt(REAL xf, const vector<REAL>& xs, const vector<REAL>& ys, REAL gapXf, REAL* outAmp) {
    if (xs.empty()) return false;
    if (xf < xs.front() || xf > xs.back()) return false;

    for (size_t i = 0; i + 1 < xs.size(); i++) {
        if (xf < xs[i] || xf > xs[i + 1]) continue;
        if (xs[i + 1] - xs[i] > gapXf) return false;   // quãng trống — KHÔNG nội suy qua
        REAL span = xs[i + 1] - xs[i];
        if (span <= 0) { *outAmp = ys[i]; return true; }
        *outAmp = ys[i] + (ys[i + 1] - ys[i]) * ((xf - xs[i]) / span);
        return true;
    }
    *outAmp = ys.back();
    return true;
}

static void DrawRiver(Graphics& g, const RectF& area, const vector<MoodSample>& samples, bool recentMode, double liveHead) {
    // [MINDFUL] G3 (2026-07-24) — BỎ early-return khi trống ở chế độ full-day. Trước đây màn Soi lại
    // không có mẫu vẽ ra HỘP RỖNG (ảnh chủ dự án). TRỤC (nét đứt + nhãn Sáng/Trưa/Chiều/Tối) là
    // KHUNG, không phải nước giả — macOS vẫn vẽ khung khi trống. Nước teal + chấm VẪN chỉ ở chỗ có
    // mẫu thật (guard `if (xs.empty()) return` bên dưới) nên luật 1 "không vẽ nước giả" vẫn giữ.
    if (area.Width <= 0)
        return;

    time_t now = time(NULL);
    time_t originSec;
    double spanSec;
    REAL maxFrac;
    
    if (recentMode) {
        spanSec = 3.0 * 3600.0; // 3 giờ quá khứ
        originSec = now - (time_t)spanSec;
        maxFrac = 0.75f; // 1/4 còn lại cho tương lai
    } else {
        struct tm lt;
        localtime_s(&lt, &now);
        lt.tm_hour = 0; lt.tm_min = 0; lt.tm_sec = 0;
        originSec = mktime(&lt);
        spanSec = 86400.0;
        maxFrac = 1.0f;
    }

    vector<REAL> xs, ys;
    for (size_t i = 0; i < samples.size(); i++) {
        if (recentMode && samples[i].ts < originSec) continue; // Bỏ qua mẫu cũ ngoài cửa sổ
        xs.push_back(XFractionOf(samples[i].ts, originSec, spanSec, maxFrac));
        ys.push_back(WaveSide(samples[i].ts) * (REAL)samples[i].value);   // trang trí — xem WaveSide phía trên
    }
    if (recentMode && liveHead >= 0.0) {
        xs.push_back(maxFrac);
        ys.push_back(WaveSide((long long)now) * (REAL)liveHead);
    }

    int interval = vBellInterval > 0 ? vBellInterval : 60;
    REAL gapXf = (REAL)((interval * 60.0 * 2.0) / spanSec * maxFrac);   // 2 nhịp

    REAL midY = area.Y + area.Height / 2.0f;
    REAL maxWaveH = area.Height * kMaxWaveFrac;
    REAL w = area.Width;

    g.SetSmoothingMode(SmoothingModeAntiAlias);

    // Trục thời gian: nét đứt, stone mờ. LÀ TRỤC, KHÔNG phải mặt nước (luật 3).
    Pen axisPen(Color((ARGB)(0x80000000 | kBrandPaletteStone)), 1.0f);
    REAL dash[2] = { 2.0f, 4.0f };
    axisPen.SetDashPattern(dash, 2);
    g.DrawLine(&axisPen, area.X, midY, area.X + w, midY);

    // [MINDFUL] P4 — nhãn trục vẽ TRƯỚC early-return: không data vẫn thấy khung 3h/2h/1h
    // (mirror macOS tách nhãn khỏi sóng). dec.4: chỉ khung trục, KHÔNG bịa nước khi rỗng.
    // Nhãn trục ngang
    FontFamily ff(L"Segoe UI");
    Font font(&ff, 8, FontStyleRegular, UnitPoint);
    SolidBrush textBrush(Color((ARGB)(0xB0000000 | kBrandPaletteMuted)));
    StringFormat fmt;
    
    if (recentMode) {
        fmt.SetAlignment(StringAlignmentNear); // Canh trái mép
        // 3 nhãn: "3 giờ trước", "2 giờ", "1 giờ", "bây giờ"
        const wchar_t* labels[] = { L"3 giờ trước", L"2 giờ", L"1 giờ", L"bây giờ" };
        REAL fracs[] = { 0.0f, maxFrac / 3.0f, maxFrac * 2.0f / 3.0f, maxFrac };
        for (int i = 0; i < 4; i++) {
            if (i == 3) fmt.SetAlignment(StringAlignmentFar);
            else if (i > 0) fmt.SetAlignment(StringAlignmentCenter);
            REAL cx = area.X + fracs[i] * w;
            g.DrawString(labels[i], -1, &font, PointF(cx, area.Y + area.Height + 2), &fmt, &textBrush);
        }
    } else {
        fmt.SetAlignment(StringAlignmentCenter);
        const int kAxisHour[4] = { 8, 12, 15, 21 };
        for (int i = 0; i < 4; i++) {
            long long ts = (long long)originSec + kAxisHour[i] * 3600;
            wstring label = MoodPhrasingCore_TimeOfDayLabel(ts);
            if (label.rfind(L"buổi ", 0) == 0) label = label.substr(5);
            REAL cx = area.X + (REAL)(kAxisHour[i] / 24.0) * w;
            g.DrawString(label.c_str(), -1, &font, PointF(cx, area.Y + area.Height + 2), &fmt, &textBrush);
        }
    }

    if (xs.empty()) return; // Không có nước (chỉ có trục)

    // Thu thập các phân đoạn liên tục (không bị ngăn cách bởi gap)
    vector<vector<PointF>> segments;
    vector<PointF> currentSeg;

    for (size_t i = 0; i < xs.size(); i++) {
        REAL mx = xs[i] * w;
        // [MINDFUL] 2026-07-23 — độ LỆCH TRỤC mỗi điểm = ĐÚNG biên độ của nó (ys[i] đã mang dấu
        // trang trí từ WaveSide() phía trên; GDI+ trục Y hướng xuống nên "lên" = midY - value).
        // Trước đây (bug đã vá) điểm chẵn nhô, điểm lẻ chìm theo THỨ TỰ trong mảng → thêm/bớt một
        // điểm là đảo nhô-chìm mọi điểm sau nó, mỗi lần refresh sông "nhảy" một kiểu. Nay vị trí một
        // điểm chỉ phụ thuộc GIÁ TRỊ + thời điểm thật của chính nó — chiều lên/xuống không mang
        // valence. Chấm (vòng dưới) dùng lại chính toạ độ này nên khớp.
        PointF p(area.X + mx, midY - ys[i] * maxWaveH);

        currentSeg.push_back(p);
        
        // Cắt phân đoạn nếu gap > gapXf
        if (i + 1 < xs.size() && (xs[i + 1] - xs[i] > gapXf)) {
            segments.push_back(currentSeg);
            currentSeg.clear();
        }
    }
    if (!currentSeg.empty()) {
        segments.push_back(currentSeg);
    }

    // Nước: teal đặc, CHỈ ở chỗ có mẫu thật.
    Pen wavePen(Color(MK_ARGB(kBrandPaletteTeal)), kWaveLineW);
    wavePen.SetStartCap(LineCapRound);
    wavePen.SetEndCap(LineCapRound);
    wavePen.SetLineJoin(LineJoinRound);

    // Vẽ đường sóng qua các điểm
    for (size_t s = 0; s < segments.size(); s++) {
        const auto& pts = segments[s];
        if (pts.empty()) continue;
        if (pts.size() == 1) continue; // 1 điểm không vẽ đường được
        
        vector<PointF> bezierPts;
        bezierPts.push_back(pts[0]);
        
        for (size_t i = 1; i < pts.size(); i++) {
            PointF pPrev = pts[i - 1];
            PointF pCurr = pts[i];
            
            // Bezier cong mượt với tiếp tuyến ngang
            PointF cp1(pPrev.X + (pCurr.X - pPrev.X) * 0.5f, pPrev.Y);
            PointF cp2(pCurr.X - (pCurr.X - pPrev.X) * 0.5f, pCurr.Y);
            
            bezierPts.push_back(cp1);
            bezierPts.push_back(cp2);
            bezierPts.push_back(pCurr);
        }
        
        g.DrawBeziers(&wavePen, bezierPts.data(), (INT)bezierPts.size());
    }

    // Chấm: 1 nhịp = 1 điểm ghi. Tô TEAL ĐẶC.
    SolidBrush dotBrush(Color(MK_ARGB(kBrandPaletteTeal)));
    SolidBrush whiteBrush(Color(255, 255, 255, 255)); // Tô nền cho check-in
    Pen dotPen(Color(MK_ARGB(kBrandPaletteTeal)), 1.8f);

    for (size_t s = 0; s < segments.size(); s++) {
        for (size_t i = 0; i < segments[s].size(); i++) {
            PointF p = segments[s][i];
            
            // [MINDFUL] Điểm liveHead (chấm cuối cùng nếu có) ở recentMode không phải checkin, tô đặc.
            // Vì bản Windows không truyền cờ checkin vào hàm này, mặc định tô đặc hết (như code cũ)
            // hoặc để sau mở rộng MoodSample. Hiện tại ta tô đặc toàn bộ như cũ.
            g.FillEllipse(&dotBrush, p.X - kDotDiameter / 2, p.Y - kDotDiameter / 2,
                          kDotDiameter, kDotDiameter);
        }
    }

}

void EmotionRiver_Draw(HDC hdc, const RECT& rect, const std::vector<MoodSample>& samples, bool recentMode, double liveHead) {
    Graphics g(hdc);
    RectF area((REAL)rect.left, (REAL)rect.top, (REAL)(rect.right - rect.left), (REAL)(rect.bottom - rect.top));
    DrawRiver(g, area, samples, recentMode, liveHead);
}


// ── Hộp thoại ──

static wstring TodayTitle() {
    time_t now = time(NULL);
    struct tm lt;
    localtime_s(&lt, &now);
    static const wchar_t* kWeekday[] = { L"Chủ Nhật", L"Thứ Hai", L"Thứ Ba", L"Thứ Tư",
                                         L"Thứ Năm", L"Thứ Sáu", L"Thứ Bảy" };
    wchar_t buf[64];
    swprintf_s(buf, L"Soi lại · %s %02d·%02d", kWeekday[lt.tm_wday], lt.tm_mday, lt.tm_mon + 1);
    return buf;
}

// [MINDFUL] F5/F4 (2026-07-23) — đại tu màn Soi lại theo bản macOS (ReflectionScreenMac.mm): 3 nhịp
// NHẬN RA / SOI / NUÔI DƯỠNG, có sóng full-day trong thẻ, ô ghi cảm nhận (child EDIT), link "Những
// dòng đã viết →" + "Chỉnh chuông…". "Nói gì" (quan sát/câu hỏi/hình dạng ngày) vẫn lấy từ bộ não
// chung MoodPhrasingCore; chỉ GỢI Ý (nuôi dưỡng) để inline như macOS (core cố ý chỉ giữ quan sát +
// câu hỏi). Cỡ cửa sổ tính động rồi SetWindowPos (bỏ 350×240 DLU của .rc) để layout theo pixel.

static const int kReflectClientW = 480;

// Nội dung tính sẵn 1 lần trong _Show, để INITDIALOG (đặt ô EDIT) / WM_PAINT (vẽ) / WM_LBUTTONUP
// (bấm) đọc CÙNG một layout — tránh lệch vùng vẽ vs vùng bấm (bài học A2/A3 tab Chuông).
static wstring g_observeStr, g_questionStr, g_gkStr, g_sugStr;
static int     g_bellHour = -1;
static bool    g_showBellLink = false;
static bool    g_showNote = false;
static bool    g_showNotesLink = false;
static HWND    g_noteEdit = NULL;
static bool    g_openBellAfterClose = false;
// [MINDFUL] G3 (2026-07-24) — chiều cao THẬT của 3 khối chữ dài (đo 1 lần ở _Show). Trước đây cao
// cố định 40/52/34 nên câu 2-3 dòng bị cắt (thẻ Nuôi dưỡng mất chữ "đóng máy" trong ảnh) + đẩy lệch
// các dòng dưới. Đo trước rồi layout theo -> không cắt, không lệch.
static int     g_obsH = 40, g_qH = 52, g_sugH = 34;

// Đo chiều cao chữ khi bọc trong `width` (DT_CALCRECT). DC màn hình đủ để đo (không cần DC cửa sổ).
static int MeasureTextH(HFONT font, const wstring& s, int width) {
    if (s.empty()) return 0;
    HDC hdc = GetDC(NULL);
    HFONT old = (HFONT)SelectObject(hdc, font);
    RECT r = { 0, 0, width, 0 };
    DrawTextW(hdc, s.c_str(), -1, &r, DT_WORDBREAK | DT_CALCRECT);
    SelectObject(hdc, old);
    ReleaseDC(NULL, hdc);
    return r.bottom - r.top;
}

// Gợi ý nhỏ theo hình dạng ngày — mirror TinySuggestionsFor (macOS). Ngày êm thì không "khắc phục",
// gợi ý là giữ lấy cái đang tốt. Chọn theo NGÀY (index), không bốc lại mỗi lần mở.
static const wchar_t* SuggestionFor(MoodDayShape shape, int index) {
    static const wchar_t* gated[] = {
        L"Nhắn cho chính mình 1 câu nhẹ nhàng, như cách bạn sẽ an ủi một người bạn.",
        L"Trước khi trả lời một tin nhắn khó, thử đọc lại một lượt rồi mới bấm gửi.",
        L"Uống một ly nước, hít thở sâu 3 lần trước khi đóng máy tối nay.",
    };
    static const wchar_t* rippled[] = {
        L"Lúc thấy gợn lên, thử đứng dậy đi vài bước trước khi gõ tiếp.",
        L"Uống một ly nước, hít thở sâu 3 lần trước khi đóng máy tối nay.",
        L"Ngày mai, thử để điện thoại xa tay hơn quanh khung giờ dễ căng nhất.",
    };
    static const wchar_t* calm[] = {
        L"Trước khi ngủ, thử viết 1 câu về điều bạn biết ơn hôm nay.",
        L"Ngày êm là lúc dễ tập thở nhất — thử 3 hơi thật sâu trước khi đóng máy.",
        L"Nếu ngày mai bận hơn, thử giữ lại một quãng trống giống hôm nay.",
    };
    const wchar_t** arr = (shape == MoodDayShapeGated) ? gated
                        : (shape == MoodDayShapeRippled) ? rippled : calm;
    return arr[((index % 3) + 3) % 3];
}

struct ReflectLayout {
    RECT eb1, riverCard, river, observe, gk, div1;
    RECT eb2, question, qcap, note, hint, notesLink, div2;
    RECT eb3, card, sugText, bellLink, closeBtn;
    int  totalH;
};

// Cộng dồn TỪ ĐỈNH XUỐNG, một nguồn duy nhất — như ReflY() bên macOS. showNote/… đọc từ g_* tính sẵn.
static ReflectLayout ComputeLayout(int clientW) {
    const int pad = 20;
    const int contentW = clientW - 2 * pad;
    ReflectLayout L = {};
    int y = 16;
    auto slot = [&](RECT& r, int h) {
        r.left = pad; r.top = y; r.right = pad + contentW; r.bottom = y + h; y += h;
    };

    slot(L.eb1, 15);        y += 8;
    slot(L.riverCard, 96);  y += 10;
    L.river = { L.riverCard.left + 10, L.riverCard.top + 10, L.riverCard.right - 10, L.riverCard.bottom - 6 };
    slot(L.observe, g_obsH); y += 6;
    slot(L.gk, 18);         y += 16;
    slot(L.div1, 1);        y += 16;

    slot(L.eb2, 15);        y += 8;
    slot(L.question, g_qH); y += 6;
    slot(L.qcap, 15);       y += 12;
    if (g_showNote) {
        slot(L.note, 26);   y += 6;
        slot(L.hint, 15);   y += (g_showNotesLink ? 8 : 16);
        if (g_showNotesLink) { slot(L.notesLink, 16); y += 16; }
    }
    slot(L.div2, 1);        y += 16;

    slot(L.eb3, 15);        y += 8;
    int cardH = 14 * 2 + g_sugH + (g_showBellLink ? (8 + 18) : 0);
    slot(L.card, cardH);    y += 16;
    L.sugText  = { L.card.left + 14, L.card.top + 14, L.card.right - 14, L.card.top + 14 + g_sugH };
    if (g_showBellLink)
        L.bellLink = { L.card.left + 14, L.card.bottom - 14 - 18, L.card.right - 14, L.card.bottom - 14 };

    slot(L.closeBtn, 28);   y += 14;
    L.closeBtn.left = L.closeBtn.right - 90;   // nút Đóng canh phải

    L.totalH = y;
    return L;
}

// Lưu chữ đang gõ (no-op nếu chưa consent). Gọi ở WM_DESTROY (mọi lối đóng) + trước khi mở lịch sử.
static void SaveNoteFromEdit() {
    if (!g_noteEdit) return;
    wchar_t buf[1024] = { 0 };
    GetWindowTextW(g_noteEdit, buf, 1024);
    MoodStore_SaveNoteForToday(buf, g_questionStr);
}

static INT_PTR CALLBACK ReflectDlgProc(HWND hDlg, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_INITDIALOG: {
        SetWindowTextW(hDlg, TodayTitle().c_str());   // ngày đầy đủ ở title bar (khớp macOS)
        // Clip child (ô EDIT) khỏi BitBlt của WM_PAINT — không thì nền đè lên ô mỗi lần vẽ lại.
        SetWindowLongPtr(hDlg, GWL_STYLE, GetWindowLongPtr(hDlg, GWL_STYLE) | WS_CLIPCHILDREN);

        ReflectLayout L = ComputeLayout(kReflectClientW);

        // Định cỡ CỬA SỔ theo client cố định + căn giữa màn hình.
        RECT wr = { 0, 0, kReflectClientW, L.totalH };
        AdjustWindowRectEx(&wr, (DWORD)GetWindowLongPtr(hDlg, GWL_STYLE), FALSE,
                           (DWORD)GetWindowLongPtr(hDlg, GWL_EXSTYLE));
        int ww = wr.right - wr.left, wh = wr.bottom - wr.top;
        int sx = GetSystemMetrics(SM_CXSCREEN), sy = GetSystemMetrics(SM_CYSCREEN);
        SetWindowPos(hDlg, NULL, (sx - ww) / 2, (sy - wh) / 2, ww, wh, SWP_NOZORDER);

        if (g_showNote) {
            g_noteEdit = CreateWindowExW(0, L"EDIT", L"",
                WS_CHILD | WS_VISIBLE | WS_BORDER | ES_AUTOHSCROLL,
                L.note.left, L.note.top, L.note.right - L.note.left, L.note.bottom - L.note.top,
                hDlg, NULL, GetModuleHandle(NULL), NULL);
            SendMessageW(g_noteEdit, WM_SETFONT, (WPARAM)BrandControls_Font(BrandFontBody), TRUE);
            SendMessageW(g_noteEdit, EM_SETLIMITTEXT, 500, 0);
            SendMessageW(g_noteEdit, EM_SETCUEBANNER, TRUE, (LPARAM)L"Nếu muốn, ghi lại một dòng cho hôm nay…");
            // Nạp chữ đã ghi CHỈ khi đã consent: nếu chưa, ô trống để lần gõ ĐẦU mới hỏi consent
            // (tránh EN_CHANGE giả lúc nạp text làm bật hộp hỏi khi người dùng chưa gõ gì).
            if (MoodStore_HasNoteConsent()) {
                wstring existing = MoodStore_FetchNoteForToday();
                if (!existing.empty()) SetWindowTextW(g_noteEdit, existing.c_str());
            }
        }
        return TRUE;
    }

    case WM_PAINT: {
        PAINTSTRUCT ps;
        HDC hdc = BeginPaint(hDlg, &ps);
        RECT clientRc; GetClientRect(hDlg, &clientRc);
        ReflectLayout L = ComputeLayout(clientRc.right);

        HDC memDC = CreateCompatibleDC(hdc);
        HBITMAP memBm = CreateCompatibleBitmap(hdc, clientRc.right, clientRc.bottom);
        HBITMAP oldBm = (HBITMAP)SelectObject(memDC, memBm);
        BrandControls_FillRect(memDC, clientRc, kBrandPaletteCardWhite);
        SetBkMode(memDC, TRANSPARENT);

        auto eyebrow = [&](const wchar_t* t, const RECT& r) {
            SetTextColor(memDC, MK_COLORREF(kBrandPaletteStone));
            HFONT o = (HFONT)SelectObject(memDC, BrandControls_Font(BrandFontEyebrow));
            RECT rr = r; DrawTextW(memDC, t, -1, &rr, DT_LEFT | DT_VCENTER | DT_SINGLELINE);
            SelectObject(memDC, o);
        };
        auto text = [&](const wstring& t, const RECT& r, unsigned color, BrandFontRole f, UINT fmt) {
            SetTextColor(memDC, MK_COLORREF(color));
            HFONT o = (HFONT)SelectObject(memDC, BrandControls_Font(f));
            RECT rr = r; DrawTextW(memDC, t.c_str(), -1, &rr, fmt);
            SelectObject(memDC, o);
        };

        // NHẬN RA — sóng full-day trong thẻ + câu quan sát + dòng gác cổng.
        eyebrow(L"NHẬN RA", L.eb1);
        BrandControls_DrawCard(memDC, L.riverCard, true);
        {
            Graphics g(memDC);
            RectF area((REAL)L.river.left, (REAL)L.river.top,
                       (REAL)(L.river.right - L.river.left), (REAL)(L.river.bottom - L.river.top - 14));
            DrawRiver(g, area, g_samples, false, -1.0);
        }
        text(g_observeStr, L.observe, kBrandPaletteCharcoal, BrandFontBody, DT_LEFT | DT_TOP | DT_WORDBREAK);
        text(g_gkStr, L.gk, kBrandPaletteMuted, BrandFontBody, DT_LEFT | DT_TOP | DT_SINGLELINE);
        BrandControls_FillRect(memDC, L.div1, kBrandPaletteDivider);

        // SOI — câu hỏi + caption + ô ghi (child EDIT) + link lịch sử.
        eyebrow(L"SOI", L.eb2);
        text(g_questionStr, L.question, kBrandPaletteCharcoal, BrandFontTitle, DT_LEFT | DT_TOP | DT_WORDBREAK);
        text(L"Không cần trả lời ngay — mang câu hỏi theo cũng đủ.", L.qcap,
             kBrandPaletteStone, BrandFontBody, DT_LEFT | DT_TOP | DT_SINGLELINE);
        if (g_showNote) {
            text(L"Chỉ nằm trên máy · đã mã hoá · xoá được bất cứ lúc nào.", L.hint,
                 kBrandPaletteStone, BrandFontBody, DT_LEFT | DT_TOP | DT_SINGLELINE);
            if (g_showNotesLink)
                text(L"Những dòng đã viết →", L.notesLink, kBrandPaletteOrange, BrandFontBody,
                     DT_LEFT | DT_VCENTER | DT_SINGLELINE);
        }
        BrandControls_FillRect(memDC, L.div2, kBrandPaletteDivider);

        // NUÔI DƯỠNG — thẻ nền cam nhạt (lớp CTA/khoảnh khắc người, KHÔNG mã hoá cảm xúc) + gợi ý.
        eyebrow(L"NUÔI DƯỠNG", L.eb3);
        BrandControls_FillRect(memDC, L.card, kBrandPaletteOrangeLight);
        text(g_sugStr, L.sugText, kBrandPaletteCharcoal, BrandFontBody, DT_LEFT | DT_TOP | DT_WORDBREAK);
        if (g_showBellLink) {
            wchar_t bl[64];
            swprintf_s(bl, L"Chỉnh chuông quanh %dh →", g_bellHour);
            text(bl, L.bellLink, kBrandPaletteOrange, BrandFontBody, DT_LEFT | DT_VCENTER | DT_SINGLELINE);
        }

        BrandControls_FillRect(memDC, L.closeBtn, kBrandPaletteOrange);
        text(L"Đóng", L.closeBtn, kBrandPaletteCardWhite, BrandFontBody, DT_CENTER | DT_VCENTER | DT_SINGLELINE);

        BitBlt(hdc, 0, 0, clientRc.right, clientRc.bottom, memDC, 0, 0, SRCCOPY);
        SelectObject(memDC, oldBm);
        DeleteObject(memBm);
        DeleteDC(memDC);
        EndPaint(hDlg, &ps);
        return TRUE;
    }

    case WM_LBUTTONUP: {
        POINT pt = { (short)LOWORD(lParam), (short)HIWORD(lParam) };
        RECT clientRc; GetClientRect(hDlg, &clientRc);
        ReflectLayout L = ComputeLayout(clientRc.right);

        if (PtInRect(&L.closeBtn, pt)) { EndDialog(hDlg, IDOK); return TRUE; }
        if (g_showNote && g_showNotesLink && PtInRect(&L.notesLink, pt)) {
            SaveNoteFromEdit();               // lưu dòng vừa gõ TRƯỚC khi mở lịch sử
            NotesHistory_Show(hDlg);
            return TRUE;
        }
        if (g_showBellLink && PtInRect(&L.bellLink, pt)) {
            g_openBellAfterClose = true;      // đóng Soi lại rồi mới mở Chuông (không lồng modal)
            EndDialog(hDlg, IDOK);
            return TRUE;
        }
        return TRUE;
    }

    case WM_COMMAND:
        // Ô ghi — hỏi consent đúng lúc người dùng LẦN ĐẦU gõ (không hỏi trước, §3.2). Từ chối = ô
        // biến mất phiên này, không hỏi lại lần sau (showNote đã lọc ở _Show).
        if (g_noteEdit && (HWND)lParam == g_noteEdit && HIWORD(wParam) == EN_CHANGE) {
            if (!MoodStore_HasAskedNoteConsent()) {
                int r = MessageBoxW(hDlg,
                    L"Chữ bạn viết sẽ được lưu ngay trên máy này, đã mã hoá, và chỉ mình bạn đọc được. "
                    L"Không gửi đi đâu, không dùng để phân tích hay chấm điểm. Xoá được bất cứ lúc nào.",
                    L"Giữ lại dòng bạn vừa viết?", MB_YESNO | MB_ICONQUESTION);
                MoodStore_SetNoteConsent(r == IDYES);
                if (r != IDYES) {
                    SetWindowTextW(g_noteEdit, L"");
                    ShowWindow(g_noteEdit, SW_HIDE);
                    g_showNote = false; g_showNotesLink = false;
                    InvalidateRect(hDlg, NULL, FALSE);
                }
            }
            return TRUE;
        }
        if (LOWORD(wParam) == IDOK || LOWORD(wParam) == IDCANCEL) {
            EndDialog(hDlg, LOWORD(wParam));
            return TRUE;
        }
        break;

    case WM_DESTROY:
        SaveNoteFromEdit();   // mọi lối đóng (nút Đóng / X / Esc) đều qua đây; no-op nếu chưa consent
        g_noteEdit = NULL;
        return TRUE;
    }
    return FALSE;
}

void ReflectionScreen_Show(HWND parent) {
    if (!MoodStore_HasConsent()) {
        MessageBoxW(parent,
            L"Nhật ký cảm xúc đang tắt nên chưa có gì để soi lại.\n\n"
            L"Bật lại ở tab Riêng tư (hoặc menu khay) nếu bạn muốn cuối ngày nhìn lại một chút.",
            L"Mindful Keyboard", MB_OK);
        return;
    }

    g_samples = MoodStore_FetchTodaySamples();
    g_summary = MoodStore_FetchTodaySummary();

    // Tính sẵn "nói gì" 1 lần — dùng chung cho INITDIALOG/PAINT/hit-test.
    double threshold = NudgeCoordinator_RippleThreshold();
    g_observeStr = MoodPhrasingCore_DayShapeSentence(g_samples, threshold);
    MoodDayShape shape = MoodPhrasingCore_DayShapeOf(g_summary.peakRisk, g_summary.gatekeeperCount, threshold);
    time_t now = time(NULL); struct tm lt; localtime_s(&lt, &now);
    g_questionStr = MoodPhrasingCore_ReflectionQuestion(shape, lt.tm_yday);
    g_sugStr = SuggestionFor(shape, lt.tm_yday + 1);   // +1: gợi ý không dính cứng vào câu hỏi

    if (g_summary.gatekeeperCount > 0) {
        wchar_t b[160];
        swprintf_s(b, L"Gác cổng đã cùng bạn dừng lại %d lần hôm nay.", g_summary.gatekeeperCount);
        g_gkStr = b;
    } else {
        g_gkStr = L"Gác cổng chưa cần dừng bạn lần nào hôm nay.";
    }

    // [MINDFUL] G3 — đo chiều cao THẬT 3 khối chữ dài (rộng nội dung 440; gợi ý trong thẻ hẹp hơn
    // 28px). Kẹp sàn để dòng đơn không bẹp. Layout dưới đọc g_obsH/g_qH/g_sugH -> không cắt/lệch.
    const int contentW = kReflectClientW - 40;
    int oh = MeasureTextH(BrandControls_Font(BrandFontBody),  g_observeStr,  contentW);
    int qh = MeasureTextH(BrandControls_Font(BrandFontTitle), g_questionStr, contentW);
    int sh = MeasureTextH(BrandControls_Font(BrandFontBody),  g_sugStr,      contentW - 28);
    g_obsH = oh < 18 ? 18 : oh;
    g_qH   = qh < 24 ? 24 : qh;
    g_sugH = sh < 18 ? 18 : sh;

    // Ngày phẳng lặng không có "giờ đỉnh" đáng canh -> không mời chỉnh chuông (mirror macOS).
    g_bellHour = g_summary.peakHour;
    g_showBellLink = (shape != MoodDayShapeCalm) && (g_bellHour >= 0);

    // Ô ghi: ẩn HẲN nếu đã hỏi consent mà bị từ chối (không hỏi lại, không chỗ trống — §2.4).
    g_showNote = !(MoodStore_HasAskedNoteConsent() && !MoodStore_HasNoteConsent());
    g_showNotesLink = g_showNote && NotesHistory_HasAny();
    g_noteEdit = NULL;
    g_openBellAfterClose = false;

    // GDI+ khởi động/tắt quanh ĐÚNG lần mở này: màn Soi lại là chỗ DUY NHẤT của app cần vẽ. Giữ
    // GDI+ sống suốt đời tiến trình chỉ để dùng vài giây/ngày là phí RAM của một bộ gõ chạy nền.
    GdiplusStartupInput gdiplusStartupInput;
    if (GdiplusStartup(&g_gdiplusToken, &gdiplusStartupInput, NULL) != Ok)
        return;

    DialogBoxParam(GetModuleHandle(NULL), MAKEINTRESOURCE(IDD_DIALOG_REFLECT), parent,
                   ReflectDlgProc, 0);

    GdiplusShutdown(g_gdiplusToken);
    g_gdiplusToken = 0;
    g_samples.clear();

    // Mở Chuông SAU khi Soi lại đóng (link "Chỉnh chuông…") — tránh lồng modal trong modal.
    if (g_openBellAfterClose) {
        g_openBellAfterClose = false;
        AppDelegate::getInstance()->onBellSettings();
    }
}
