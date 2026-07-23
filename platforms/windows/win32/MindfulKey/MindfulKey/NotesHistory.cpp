//
// NotesHistory.cpp — [MINDFUL] cửa sổ "Những dòng bạn đã viết" (Windows). Xem NotesHistory.h.
//
// Đối ứng platforms/apple/macos/NotesHistoryMac.mm. macOS dùng NSScrollView + documentView lật;
// Windows tự vẽ owner-draw + cuộn tay (WS_VSCROLL + WM_MOUSEWHEEL), double-buffer chống nháy.
//
// Gate "mô tả hay phán xét?" — mọi copy đã tự soi: tên màn (mô tả nội dung, không khen), ngày
// (dữ kiện), câu hỏi hôm đó (chính chữ app đã hỏi), chân trang (sự thật kỹ thuật). Không câu nào
// chấm điểm/thúc giục. Không sóng, không số, không chuỗi ngày (xem .h).
//
#include "stdafx.h"
#include "NotesHistory.h"
#include "MoodStore.h"
#include "BrandPalette.h"
#include "BrandControls.h"
#include <string>
#include <vector>

using namespace std;

// ── Layout (pixel client) — theo ngôn ngữ thẻ trắng của các màn brand khác ──
static const int kPad       = 24;   // lề trái/phải
static const int kTopPad    = 20;
static const int kBottomPad = 20;
static const int kFooterH   = 34;   // dải chân trang cố định (không cuộn)
static const int kDateH     = 16;   // dòng ngày (eyebrow)
static const int kDateGap   = 6;    // ngày → câu hỏi
static const int kQGap      = 5;    // câu hỏi → chữ
static const int kEntryGap  = 24;   // giữa 2 ghi chú
static const int kRuleGap   = 12;   // chữ → đường ngăn
static const int kLineStep  = 24;   // 1 nấc cuộn bàn phím/nút
static const int kWheelStep = 48;   // 1 nấc lăn chuột

static const wchar_t* kClassName = L"MindfulNotesHistory";

static HWND               g_hwnd = NULL;
static vector<MoodNote>   g_notes;
static int                g_scrollY = 0;

// "THỨ NĂM 16·07" — cùng khuôn tiêu đề cửa sổ Soi lại. Năm chỉ hiện khi KHÁC năm nay (đủ để không
// nhầm, không biến dòng ngày thành mã số). Cố ý KHÔNG "hôm qua"/"3 ngày trước" (khoảng-cách-tới-nay
// là thứ mời người ta đếm mình bỏ bao lâu — §2.4).
static wstring DateLabelFor(long long ts) {
    time_t t = (time_t)ts;
    struct tm lt; localtime_s(&lt, &t);
    static const wchar_t* wd[] = { L"CHỦ NHẬT", L"THỨ HAI", L"THỨ BA", L"THỨ TƯ",
                                   L"THỨ NĂM", L"THỨ SÁU", L"THỨ BẢY" };
    time_t now = time(NULL); struct tm nt; localtime_s(&nt, &now);
    wchar_t buf[64];
    if (lt.tm_year != nt.tm_year)
        swprintf_s(buf, L"%s %02d·%02d·%d", wd[lt.tm_wday], lt.tm_mday, lt.tm_mon + 1, lt.tm_year + 1900);
    else
        swprintf_s(buf, L"%s %02d·%02d", wd[lt.tm_wday], lt.tm_mday, lt.tm_mon + 1);
    return buf;
}

static int MeasureH(HDC hdc, HFONT font, const wstring& s, int width) {
    if (s.empty()) return 0;
    HFONT old = (HFONT)SelectObject(hdc, font);
    RECT r = { 0, 0, width, 0 };
    DrawTextW(hdc, s.c_str(), -1, &r, DT_WORDBREAK | DT_CALCRECT);
    SelectObject(hdc, old);
    return r.bottom - r.top;
}

static void DrawWrapped(HDC hdc, HFONT font, unsigned color, const wstring& s,
                        int x, int y, int width, int height) {
    SetTextColor(hdc, MK_COLORREF(color));
    HFONT old = (HFONT)SelectObject(hdc, font);
    RECT r = { x, y, x + width, y + height };
    DrawTextW(hdc, s.c_str(), -1, &r, DT_WORDBREAK | DT_TOP | DT_LEFT);
    SelectObject(hdc, old);
}

// Duyệt các note, tính vị trí; nếu draw=true thì vẽ (đã trừ scrollY). Trả về TỔNG chiều cao nội
// dung — dùng chung cho WM_PAINT (vẽ) lẫn cập nhật thanh cuộn (chỉ đo). Một nguồn layout duy nhất.
static int LayoutAndMaybeDraw(HDC hdc, int clientW, int scrollY, bool draw) {
    int textW = clientW - 2 * kPad;
    if (textW < 40) textW = 40;
    HFONT fDate = BrandControls_Font(BrandFontEyebrow);
    HFONT fQ    = BrandControls_Font(BrandFontBody);
    HFONT fBody = BrandControls_Font(BrandFontTitle);   // chữ người viết — to/đậm nhất, nhân vật chính

    SetBkMode(hdc, TRANSPARENT);
    int y = kTopPad;
    for (size_t i = 0; i < g_notes.size(); i++) {
        const MoodNote& n = g_notes[i];
        int qh = MeasureH(hdc, fQ, n.question, textW);
        int bh = MeasureH(hdc, fBody, n.text, textW);
        if (bh < 18) bh = 18;

        if (draw) {
            RECT dr = { kPad, y - scrollY, kPad + textW, y - scrollY + kDateH };
            SetTextColor(hdc, MK_COLORREF(kBrandPaletteStone));
            HFONT old = (HFONT)SelectObject(hdc, fDate);
            DrawTextW(hdc, DateLabelFor(n.ts).c_str(), -1, &dr, DT_LEFT | DT_TOP | DT_SINGLELINE);
            SelectObject(hdc, old);
        }
        y += kDateH + kDateGap;

        if (!n.question.empty()) {
            if (draw) DrawWrapped(hdc, fQ, kBrandPaletteStone, n.question, kPad, y - scrollY, textW, qh);
            y += qh + kQGap;
        }

        if (draw) DrawWrapped(hdc, fBody, kBrandPaletteCharcoal, n.text, kPad, y - scrollY, textW, bh);
        y += bh;

        if (i + 1 < g_notes.size()) {
            if (draw) {
                RECT rule = { kPad, y + kRuleGap - scrollY, clientW - kPad, y + kRuleGap - scrollY + 1 };
                BrandControls_FillRect(hdc, rule, kBrandPaletteDivider);
            }
            y += kEntryGap;
        }
    }
    y += kBottomPad;
    return y;
}

static int MaxScrollOf(HWND hwnd, int* totalOut = NULL, int* pageOut = NULL) {
    RECT rc; GetClientRect(hwnd, &rc);
    HDC hdc = GetDC(hwnd);
    int total = LayoutAndMaybeDraw(hdc, rc.right, 0, false);
    ReleaseDC(hwnd, hdc);
    int page = rc.bottom - kFooterH;
    if (page < 1) page = 1;
    int maxScroll = total - page;
    if (maxScroll < 0) maxScroll = 0;
    if (totalOut) *totalOut = total;
    if (pageOut) *pageOut = page;
    return maxScroll;
}

static void UpdateScrollRange(HWND hwnd) {
    int total = 0, page = 0;
    int maxScroll = MaxScrollOf(hwnd, &total, &page);
    if (g_scrollY > maxScroll) g_scrollY = maxScroll;
    if (g_scrollY < 0) g_scrollY = 0;
    SCROLLINFO si = { sizeof(si) };
    si.fMask = SIF_RANGE | SIF_PAGE | SIF_POS;
    si.nMin = 0; si.nMax = total; si.nPage = page; si.nPos = g_scrollY;
    SetScrollInfo(hwnd, SB_VERT, &si, TRUE);
}

static void ScrollTo(HWND hwnd, int pos) {
    int maxScroll = MaxScrollOf(hwnd);
    if (pos < 0) pos = 0;
    if (pos > maxScroll) pos = maxScroll;
    if (pos == g_scrollY) return;
    g_scrollY = pos;
    SCROLLINFO si = { sizeof(si) };
    si.fMask = SIF_POS; si.nPos = pos;
    SetScrollInfo(hwnd, SB_VERT, &si, TRUE);
    InvalidateRect(hwnd, NULL, FALSE);
}

static LRESULT CALLBACK NotesWndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_ERASEBKGND:
        return 1;   // double-buffer lo hết ở WM_PAINT

    case WM_SIZE:
        UpdateScrollRange(hwnd);
        InvalidateRect(hwnd, NULL, FALSE);
        return 0;

    case WM_VSCROLL: {
        SCROLLINFO si = { sizeof(si) };
        si.fMask = SIF_ALL;
        GetScrollInfo(hwnd, SB_VERT, &si);
        int pos = si.nPos;
        switch (LOWORD(wParam)) {
        case SB_LINEUP:   pos -= kLineStep; break;
        case SB_LINEDOWN: pos += kLineStep; break;
        case SB_PAGEUP:   pos -= (int)si.nPage; break;
        case SB_PAGEDOWN: pos += (int)si.nPage; break;
        case SB_THUMBTRACK:
        case SB_THUMBPOSITION: pos = si.nTrackPos; break;
        }
        ScrollTo(hwnd, pos);
        return 0;
    }

    case WM_MOUSEWHEEL: {
        int delta = (short)HIWORD(wParam);   // = GET_WHEEL_DELTA_WPARAM, không cần macro
        ScrollTo(hwnd, g_scrollY - (delta / WHEEL_DELTA) * kWheelStep);
        return 0;
    }

    case WM_PAINT: {
        PAINTSTRUCT ps;
        HDC hdc = BeginPaint(hwnd, &ps);
        RECT rc; GetClientRect(hwnd, &rc);
        int clientW = rc.right, clientH = rc.bottom;

        HDC memDC = CreateCompatibleDC(hdc);
        HBITMAP memBm = CreateCompatibleBitmap(hdc, clientW, clientH);
        HBITMAP oldBm = (HBITMAP)SelectObject(memDC, memBm);

        BrandControls_FillRect(memDC, rc, kBrandPaletteCardWhite);
        LayoutAndMaybeDraw(memDC, clientW, g_scrollY, true);

        // Chân trang cố định (đè lên nội dung cuộn) — cùng lời hứa dưới ô ghi ở màn Soi lại.
        RECT footRc = { 0, clientH - kFooterH, clientW, clientH };
        BrandControls_FillRect(memDC, footRc, kBrandPaletteCardWhite);
        RECT fdiv = { 0, clientH - kFooterH, clientW, clientH - kFooterH + 1 };
        BrandControls_FillRect(memDC, fdiv, kBrandPaletteDivider);
        RECT ftxt = { 0, clientH - kFooterH + 9, clientW, clientH - 6 };
        SetBkMode(memDC, TRANSPARENT);
        SetTextColor(memDC, MK_COLORREF(kBrandPaletteStone));
        HFONT oldF = (HFONT)SelectObject(memDC, BrandControls_Font(BrandFontBody));
        DrawTextW(memDC, L"Chỉ nằm trên máy · đã mã hoá · xoá được bất cứ lúc nào.", -1, &ftxt,
                  DT_CENTER | DT_TOP | DT_SINGLELINE);
        SelectObject(memDC, oldF);

        BitBlt(hdc, 0, 0, clientW, clientH, memDC, 0, 0, SRCCOPY);
        SelectObject(memDC, oldBm);
        DeleteObject(memBm);
        DeleteDC(memDC);
        EndPaint(hwnd, &ps);
        return 0;
    }

    case WM_CLOSE:
        DestroyWindow(hwnd);
        return 0;

    case WM_DESTROY:
        g_hwnd = NULL;   // KHÔNG PostQuitMessage: đây là cửa sổ con của app khay, không phải app chính
        return 0;
    }
    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

static void EnsureClass() {
    static bool registered = false;
    if (registered) return;
    WNDCLASSW wc = { 0 };
    wc.lpfnWndProc = NotesWndProc;
    wc.hInstance = GetModuleHandle(NULL);
    wc.hCursor = LoadCursor(NULL, IDC_ARROW);
    wc.hbrBackground = (HBRUSH)GetStockObject(WHITE_BRUSH);
    wc.lpszClassName = kClassName;
    RegisterClassW(&wc);
    registered = true;
}

bool NotesHistory_HasAny() {
    // FetchAllNotes tự trả rỗng khi chưa consent, nên không cần check consent riêng.
    return !MoodStore_FetchAllNotes().empty();
}

void NotesHistory_Show(HWND parent) {
    g_notes = MoodStore_FetchAllNotes();

    // Không có gì để đọc ⇒ nói thẳng, KHÔNG mở cửa sổ rỗng và KHÔNG rủ "viết đi". Lối vào lẽ ra đã
    // ẩn khi chưa có note (HasAny), nhánh này chỉ chạy khi gọi thẳng — giữ cho chắc.
    if (g_notes.empty()) {
        MessageBoxW(parent,
            L"Ô ghi nằm ở cuối màn Soi lại — nếu có lúc muốn, bạn ghi lại một dòng cho hôm nay.",
            L"Chưa có dòng nào để đọc lại", MB_OK | MB_ICONINFORMATION);
        return;
    }

    if (g_hwnd && IsWindow(g_hwnd)) {
        // Đang mở rồi -> dựng lại nội dung cho tươi (vừa viết thêm ở Soi lại xong) + đưa lên trước.
        g_scrollY = 0;
        UpdateScrollRange(g_hwnd);
        InvalidateRect(g_hwnd, NULL, FALSE);
        SetForegroundWindow(g_hwnd);
        return;
    }

    EnsureClass();
    const int w = 560, h = 620;
    int sx = GetSystemMetrics(SM_CXSCREEN), sy = GetSystemMetrics(SM_CYSCREEN);
    int x = (sx - w) / 2, y = (sy - h) / 2;
    if (x < 0) x = 0;
    if (y < 0) y = 0;
    g_scrollY = 0;
    g_hwnd = CreateWindowExW(0, kClassName, L"Những dòng bạn đã viết",
        WS_OVERLAPPEDWINDOW | WS_VSCROLL,
        x, y, w, h, NULL, NULL, GetModuleHandle(NULL), NULL);
    if (!g_hwnd) return;
    ShowWindow(g_hwnd, SW_SHOW);
    UpdateScrollRange(g_hwnd);
    SetForegroundWindow(g_hwnd);
}
