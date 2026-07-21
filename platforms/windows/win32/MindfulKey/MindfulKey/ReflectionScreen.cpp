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
#include "NudgeCoordinator.h"
#include "Bell.h"
#include "BrandPalette.h"
#include "../../../../../core/mood/MoodPhrasing.h"
#include <objidl.h>    // PHẢI đứng TRƯỚC gdiplus.h: GdiplusHeaders/GdiplusImaging dùng kiểu COM
                      // (PROPID, IStream, IImageBytes) mà WIN32_LEAN_AND_MEAN trong stdafx.h cắt
                      // khỏi windows.h. Thiếu nó thì lỗi nổ ra TRONG header của Microsoft, nhìn
                      // như SDK hỏng — thật ra là thiếu include của mình. Lần thứ 3 cờ này cắn
                      // trong cùng 1 phiên (trước đó: mmsystem.h cho chuông, commdlg.h cho hộp
                      // chọn tệp). ĐỪNG "dọn cho gọn".
#include <gdiplus.h>
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
    if (samples.empty() && !recentMode)
        return;   // trống thật — KHÔNG vẽ đường/chấm giả (luật 1)
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
        ys.push_back((REAL)samples[i].value);
    }
    if (recentMode && liveHead >= 0.0) {
        xs.push_back(maxFrac);
        ys.push_back((REAL)liveHead);
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

    if (xs.empty()) return; // Không có nước (chỉ có trục)

    // Nước: teal đặc, CHỈ ở chỗ có mẫu thật.
    Pen wavePen(Color(MK_ARGB(kBrandPaletteTeal)), kWaveLineW);
    wavePen.SetStartCap(LineCapRound);
    wavePen.SetEndCap(LineCapRound);
    wavePen.SetLineJoin(LineJoinRound);

    vector<PointF> seg;
    for (REAL x = 0; x <= w; x += kWaveStepX) {
        REAL amp = 0;
        if (!AmpAt(x / w, xs, ys, gapXf, &amp)) {
            if (seg.size() >= 2) g.DrawLines(&wavePen, &seg[0], (INT)seg.size());
            seg.clear();
            continue;
        }
        seg.push_back(PointF(area.X + x, midY - amp * maxWaveH * (REAL)sin(x * kWaveFreq)));
    }
    if (seg.size() >= 2) g.DrawLines(&wavePen, &seg[0], (INT)seg.size());

    // Chấm: 1 nhịp = 1 điểm ghi. Tô TEAL ĐẶC.
    SolidBrush dotBrush(Color(MK_ARGB(kBrandPaletteTeal)));
    for (size_t i = 0; i < xs.size(); i++) {
        // [MINDFUL] Điểm liveHead (chấm cuối cùng nếu có) ở recentMode không phải checkin, tô đặc.
        REAL mx = xs[i] * w;
        REAL my = midY - ys[i] * maxWaveH * (REAL)sin(mx * kWaveFreq);
        g.FillEllipse(&dotBrush, area.X + mx - kDotDiameter / 2, my - kDotDiameter / 2,
                      kDotDiameter, kDotDiameter);
    }

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

static INT_PTR CALLBACK ReflectDlgProc(HWND hDlg, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_INITDIALOG:
        return TRUE;

    case WM_PAINT: {
        PAINTSTRUCT ps;
        HDC hdc = BeginPaint(hDlg, &ps);
        RECT clientRc;
        GetClientRect(hDlg, &clientRc);

        HDC memDC = CreateCompatibleDC(hdc);
        HBITMAP memBm = CreateCompatibleBitmap(hdc, clientRc.right, clientRc.bottom);
        HBITMAP oldBm = (HBITMAP)SelectObject(memDC, memBm);

        // Nền trắng
        BrandControls_FillRect(memDC, clientRc, kBrandPaletteCardWhite);

        // Header
        BrandControls_DrawCardHeader(memDC, clientRc.right, TodayTitle().c_str());

        // Tính toán các câu văn
        double threshold = NudgeCoordinator_RippleThreshold();
        wstring observeStr = MoodPhrasingCore_DayShapeSentence(g_samples, threshold);
        
        MoodDayShape shape = MoodPhrasingCore_DayShapeOf(g_summary.peakRisk, g_summary.gatekeeperCount, threshold);
        time_t now = time(NULL);
        struct tm lt; localtime_s(&lt, &now);
        wstring questionStr = MoodPhrasingCore_ReflectionQuestion(shape, lt.tm_yday);

        wstring contextStr;
        if (g_summary.gatekeeperCount > 0) {
            wchar_t b[128];
            swprintf_s(b, L"Hôm nay có %d lần bạn dừng lại trước khi gửi.", g_summary.gatekeeperCount);
            contextStr = b;
        } else if (g_summary.sampleCount == 0) {
            contextStr = L"Chưa có nhịp nào được ghi hôm nay.";
        }

        // Vẽ Observe
        RECT obsRc = { 20, 30, clientRc.right - 20, 50 };
        SetBkMode(memDC, TRANSPARENT);
        SetTextColor(memDC, MK_COLORREF(kBrandPaletteStone));
        HFONT oldFont = (HFONT)SelectObject(memDC, BrandControls_Font(BrandFontBody));
        DrawTextW(memDC, observeStr.c_str(), -1, &obsRc, DT_LEFT | DT_TOP | DT_WORDBREAK);

        // Vẽ River
        RECT riverRc = { 20, 60, clientRc.right - 20, 140 };
        Graphics g(memDC);
        RectF area((REAL)riverRc.left, (REAL)riverRc.top, (REAL)(riverRc.right - riverRc.left), (REAL)(riverRc.bottom - riverRc.top - 14));
        DrawRiver(g, area, g_samples, false, -1.0);

        // Vẽ Context
        RECT ctxRc = { 20, 150, clientRc.right - 20, 170 };
        SetTextColor(memDC, MK_COLORREF(kBrandPaletteStone));
        DrawTextW(memDC, contextStr.c_str(), -1, &ctxRc, DT_LEFT | DT_TOP | DT_WORDBREAK);

        // Vẽ Question
        RECT qRc = { 20, 175, clientRc.right - 20, 220 };
        SetTextColor(memDC, MK_COLORREF(kBrandPaletteCharcoal));
        SelectObject(memDC, BrandControls_Font(BrandFontTitle));
        DrawTextW(memDC, questionStr.c_str(), -1, &qRc, DT_LEFT | DT_TOP | DT_WORDBREAK);

        // Vẽ Nút Đóng
        RECT btnRc = { clientRc.right - 100, clientRc.bottom - 40, clientRc.right - 20, clientRc.bottom - 15 };
        HBRUSH brBtn = CreateSolidBrush(MK_COLORREF(kBrandPaletteOrange));
        FillRect(memDC, &btnRc, brBtn);
        DeleteObject(brBtn);
        SetTextColor(memDC, MK_COLORREF(kBrandPaletteWhite));
        SelectObject(memDC, BrandControls_Font(BrandFontBody));
        DrawTextW(memDC, L"Đóng", -1, &btnRc, DT_CENTER | DT_VCENTER | DT_SINGLELINE);
        SelectObject(memDC, oldFont);

        BitBlt(hdc, 0, 0, clientRc.right, clientRc.bottom, memDC, 0, 0, SRCCOPY);
        SelectObject(memDC, oldBm);
        DeleteObject(memBm);
        DeleteDC(memDC);

        EndPaint(hDlg, &ps);
        return TRUE;
    }
    
    case WM_LBUTTONUP: {
        POINT pt;
        pt.x = (short)LOWORD(lParam);
        pt.y = (short)HIWORD(lParam);

        RECT clientRc;
        GetClientRect(hDlg, &clientRc);
        RECT btnRc = { clientRc.right - 100, clientRc.bottom - 40, clientRc.right - 20, clientRc.bottom - 15 };

        if (PtInRect(&btnRc, pt)) {
            EndDialog(hDlg, IDOK);
        }
        return TRUE;
    }

    case WM_COMMAND:
        if (LOWORD(wParam) == IDOK || LOWORD(wParam) == IDCANCEL) {
            EndDialog(hDlg, LOWORD(wParam));
            return TRUE;
        }
        break;
    }
    return FALSE;
}

void ReflectionScreen_Show(HWND parent) {
    if (!MoodStore_HasConsent()) {
        MessageBoxW(parent,
            L"Nhật ký cảm xúc đang tắt nên chưa có gì để soi lại.\n\n"
            L"Bật lại ở menu khay nếu bạn muốn cuối ngày nhìn lại một chút.",
            L"Mindful Keyboard", MB_OK);
        return;
    }

    g_samples = MoodStore_FetchTodaySamples();
    g_summary = MoodStore_FetchTodaySummary();

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
}
