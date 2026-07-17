//
// ReflectionScreen.cpp — [MINDFUL] màn "Soi lại hôm nay" + dòng sông cảm xúc. Bản Windows.
// File MỚI của dự án mindful-keyboard (không thuộc OpenKey gốc).
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
static REAL XFractionOf(long long ts, time_t startOfDay) {
    double secs = (double)(ts - (long long)startOfDay);
    if (secs < 0) secs = 0;
    if (secs > 86400.0) secs = 86400.0;
    return (REAL)(secs / 86400.0);
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

static void DrawRiver(Graphics& g, const RectF& area) {
    if (g_samples.empty())
        return;   // trống thật — KHÔNG vẽ đường/chấm giả (luật 1)
    if (area.Width <= 0)
        return;

    time_t now = time(NULL);
    struct tm lt;
    localtime_s(&lt, &now);
    lt.tm_hour = 0; lt.tm_min = 0; lt.tm_sec = 0;
    time_t startOfDay = mktime(&lt);

    vector<REAL> xs, ys;
    for (size_t i = 0; i < g_samples.size(); i++) {
        xs.push_back(XFractionOf(g_samples[i].ts, startOfDay));
        ys.push_back((REAL)g_samples[i].value);
    }

    int interval = vBellInterval > 0 ? vBellInterval : 60;
    REAL gapXf = (REAL)((interval * 60.0 * 2.0) / 86400.0);   // 2 nhịp

    REAL midY = area.Y + area.Height / 2.0f;
    REAL maxWaveH = area.Height * kMaxWaveFrac;
    REAL w = area.Width;

    g.SetSmoothingMode(SmoothingModeAntiAlias);

    // Trục thời gian: nét đứt, stone mờ. LÀ TRỤC, KHÔNG phải mặt nước (luật 3).
    Pen axisPen(Color((ARGB)(0x80000000 | kBrandPaletteStone)), 1.0f);
    REAL dash[2] = { 2.0f, 4.0f };
    axisPen.SetDashPattern(dash, 2);
    g.DrawLine(&axisPen, area.X, midY, area.X + w, midY);

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
        // GDI+ có trục Y hướng XUỐNG (Cocoa hướng lên) nên công thức này là ảnh gương dọc của bản
        // macOS. Không sao: sin dao động đối xứng quanh midY, hình con sóng y hệt.
        seg.push_back(PointF(area.X + x, midY - amp * maxWaveH * (REAL)sin(x * kWaveFreq)));
    }
    if (seg.size() >= 2) g.DrawLines(&wavePen, &seg[0], (INT)seg.size());

    // Chấm: 1 nhịp = 1 điểm ghi. Tô TEAL ĐẶC — bản macOS từng tô trắng trên nền thẻ cũng gần
    // trắng nên gần như tàng hình, caption hứa "vòng tròn" mà mắt không thấy (vá 2026-07-16).
    SolidBrush dotBrush(Color(MK_ARGB(kBrandPaletteTeal)));
    for (size_t i = 0; i < xs.size(); i++) {
        REAL mx = xs[i] * w;
        REAL my = midY - ys[i] * maxWaveH * (REAL)sin(mx * kWaveFreq);
        g.FillEllipse(&dotBrush, area.X + mx - kDotDiameter / 2, my - kDotDiameter / 2,
                      kDotDiameter, kDotDiameter);
    }

    // Nhãn buổi — ranh giới LẤY TỪ core/mood/MoodPhrasing (nguồn duy nhất). Tự đặt số ở đây là
    // trục và câu chữ nói ngược nhau trên cùng màn hình.
    FontFamily ff(L"Segoe UI");
    Font font(&ff, 8, FontStyleRegular, UnitPoint);
    SolidBrush textBrush(Color((ARGB)(0xB0000000 | kBrandPaletteMuted)));
    StringFormat fmt;
    fmt.SetAlignment(StringAlignmentCenter);
    const int kAxisHour[4] = { 8, 12, 15, 21 };   // giữa mỗi buổi: sáng 5-11 · trưa 11-13 · chiều 13-18 · tối 18-24
    for (int i = 0; i < 4; i++) {
        long long ts = (long long)startOfDay + kAxisHour[i] * 3600;
        wstring label = MoodPhrasingCore_TimeOfDayLabel(ts);
        if (label.rfind(L"buổi ", 0) == 0) label = label.substr(5);   // "buổi sáng" -> "sáng"
        REAL cx = area.X + (REAL)(kAxisHour[i] / 24.0) * w;
        g.DrawString(label.c_str(), -1, &font, PointF(cx, area.Y + area.Height + 2), &fmt, &textBrush);
    }
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
    case WM_INITDIALOG: {
        SetWindowTextW(hDlg, TodayTitle().c_str());

        double threshold = NudgeCoordinator_RippleThreshold();
        SetDlgItemTextW(hDlg, IDC_STATIC_REFLECT_OBSERVE,
                        MoodPhrasingCore_DayShapeSentence(g_samples, threshold).c_str());

        // CÂU HỎI là trọng tâm màn này; số liệu chỉ là bối cảnh phụ. Cố ý KHÔNG biểu đồ và
        // KHÔNG gamify — xem HIẾN CHƯƠNG §2.2 cho danh sách cụ thể những gì bị cấm.
        // (Không liệt kê ra đây: brand-lint bắt chính những từ đó, kể cả trong câu PHỦ ĐỊNH chúng.
        //  Báo nhầm đã biết — xem docs/FRICTION-LOG.md 2026-07-17.)
        MoodDayShape shape = MoodPhrasingCore_DayShapeOf(g_summary.peakRisk,
                                                         g_summary.gatekeeperCount, threshold);
        time_t now = time(NULL);
        struct tm lt; localtime_s(&lt, &now);
        SetDlgItemTextW(hDlg, IDC_STATIC_REFLECT_QUESTION,
                        MoodPhrasingCore_ReflectionQuestion(shape, lt.tm_yday).c_str());

        wstring ctx;
        if (g_summary.gatekeeperCount > 0) {
            wchar_t b[128];
            swprintf_s(b, L"Hôm nay có %d lần bạn dừng lại trước khi gửi.", g_summary.gatekeeperCount);
            ctx = b;
        } else if (g_summary.sampleCount == 0) {
            ctx = L"Chưa có nhịp nào được ghi hôm nay.";
        }
        SetDlgItemTextW(hDlg, IDC_STATIC_REFLECT_CONTEXT, ctx.c_str());
        return TRUE;
    }
    case WM_DRAWITEM: {
        LPDRAWITEMSTRUCT di = (LPDRAWITEMSTRUCT)lParam;
        if (di->CtlID != IDC_STATIC_REFLECT_RIVER)
            break;
        Graphics g(di->hDC);
        SolidBrush bg(Color(MK_ARGB(kBrandPaletteCardWhite)));
        RectF full((REAL)di->rcItem.left, (REAL)di->rcItem.top,
                   (REAL)(di->rcItem.right - di->rcItem.left),
                   (REAL)(di->rcItem.bottom - di->rcItem.top));
        g.FillRectangle(&bg, full);
        RectF area(full.X, full.Y, full.Width, full.Height - 14);   // chừa chỗ nhãn buổi
        DrawRiver(g, area);
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
