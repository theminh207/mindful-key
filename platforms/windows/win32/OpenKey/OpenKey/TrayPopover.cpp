//
// TrayPopover.cpp — [MINDFUL] Cửa sổ Popover bật từ khay hệ thống (mặt tiền của app).
//
#include "stdafx.h"
#include "TrayPopover.h"
#include "BrandPalette.h"
#include "BrandControls.h"
#include "ReflectionScreen.h"
#include "MoodStore.h"
#include "SendGatekeeper.h"
#include <objidl.h>
#include <gdiplus.h>

#pragma comment(lib, "gdiplus.lib")

using namespace std;

static const wchar_t* kPopoverClassName = L"MK_TrayPopover";
static HWND g_hwndPopover = NULL;
static int g_currentTab = 0; // 0: Hôm nay, 1: Chuông, 2: Bộ gõ
static ULONG_PTR g_gdiplusTokenPopover = 0;

static const int kPopoverWidth = 338;
static const int kPopoverHeight = 420;

extern int vMoodWatch;
extern int vSendGatekeeper;

static void PaintPopover(HWND hwnd) {
    PAINTSTRUCT ps;
    HDC hdc = BeginPaint(hwnd, &ps);

    RECT clientRc;
    GetClientRect(hwnd, &clientRc);

    // Dùng Double Buffering để tránh chớp
    HDC memDC = CreateCompatibleDC(hdc);
    HBITMAP memBitmap = CreateCompatibleBitmap(hdc, clientRc.right, clientRc.bottom);
    HBITMAP oldBitmap = (HBITMAP)SelectObject(memDC, memBitmap);

    // Tô nền cardWhite
    BrandControls_FillRect(memDC, clientRc, kBrandPaletteCardWhite);

    // Vẽ Header
    BrandControls_DrawCardHeader(memDC, clientRc.right, L"Mindful Keyboard");

    // Đoạn dưới Header
    int y = 45; // Dưới đường kẻ ngăn

    // Thanh Tab (Segmented)
    RECT segRc = { 18, y + 10, clientRc.right - 18, y + 42 };
    const wchar_t* tabs[] = { L"Hôm nay", L"Chuông", L"Bộ gõ" };
    // Truyền clickPt = (-1, -1) vì ta chỉ vẽ
    POINT pt = { -1, -1 };
    BrandControls_DrawSegmentedControl(memDC, segRc, tabs, 3, g_currentTab, pt, 0);

    y += 50;

    if (g_currentTab == 0) {
        // Tab Hôm nay
        
        // Trạng thái Gác cổng
        SetBkMode(memDC, TRANSPARENT);
        SetTextColor(memDC, MK_COLORREF(kBrandPaletteCharcoal));
        HFONT titleFont = BrandControls_Font(BrandFontTitle);
        HFONT oldFont = (HFONT)SelectObject(memDC, titleFont);
        
        const wchar_t* gkTitle = vSendGatekeeper ? L"Gác cổng đang canh" : L"Gác cổng đang tạm nghỉ";
        RECT titleRc = { 18, y, clientRc.right - 18, y + 25 };
        DrawTextW(memDC, gkTitle, -1, &titleRc, DT_LEFT | DT_VCENTER | DT_SINGLELINE);

        SelectObject(memDC, BrandControls_Font(BrandFontBody));
        SetTextColor(memDC, MK_COLORREF(kBrandPaletteMuted));
        RECT subRc = { 18, y + 25, clientRc.right - 18, y + 60 };
        const wchar_t* gkSub = vSendGatekeeper ? L"Nhịp thở sẽ xuất hiện nếu nhịp phím quá căng." : L"Phím Enter đi thẳng, nhưng nhật ký vẫn ghi.";
        DrawTextW(memDC, gkSub, -1, &subRc, DT_LEFT | DT_TOP | DT_WORDBREAK);
        SelectObject(memDC, oldFont);

        // Biểu đồ cảm xúc (Sông)
        y += 70;
        RECT riverRc = { 18, y, clientRc.right - 18, y + 150 };
        // Background card cho biểu đồ
        BrandControls_DrawCard(memDC, riverRc, true);

        // Gọi GDI+ để vẽ dòng sông
        if (vMoodWatch) {
            std::vector<MoodSample> samples = MoodStore_FetchRecentSamples(3 * 3600); // 3h quá khứ
            double liveHead = -1.0; // Todo: call MoodWatch_LiveAmplitude
            RECT chartRc = { riverRc.left + 5, riverRc.top + 5, riverRc.right - 5, riverRc.bottom - 20 };
            EmotionRiver_Draw(memDC, chartRc, samples, true, liveHead);
        } else {
            // Hiển thị thông báo khi nhắc tâm tắt
            SelectObject(memDC, BrandControls_Font(BrandFontBody));
            SetTextColor(memDC, MK_COLORREF(kBrandPaletteMuted));
            DrawTextW(memDC, L"Nhật ký cảm xúc đang tắt.", -1, &riverRc, DT_CENTER | DT_VCENTER | DT_SINGLELINE);
        }
    } else if (g_currentTab == 1) {
        // Tab Chuông
        SetBkMode(memDC, TRANSPARENT);
        SetTextColor(memDC, MK_COLORREF(kBrandPaletteMuted));
        HFONT font = BrandControls_Font(BrandFontBody);
        HFONT oldFont = (HFONT)SelectObject(memDC, font);
        RECT rc = { 18, y, clientRc.right - 18, clientRc.bottom };
        DrawTextW(memDC, L"Nội dung Chuông... (Phase 3)", -1, &rc, DT_CENTER | DT_VCENTER | DT_SINGLELINE);
        SelectObject(memDC, oldFont);
    } else {
        // Tab Bộ gõ
        SetBkMode(memDC, TRANSPARENT);
        SetTextColor(memDC, MK_COLORREF(kBrandPaletteMuted));
        HFONT font = BrandControls_Font(BrandFontBody);
        HFONT oldFont = (HFONT)SelectObject(memDC, font);
        RECT rc = { 18, y, clientRc.right - 18, clientRc.bottom };
        DrawTextW(memDC, L"Nội dung Bộ gõ... (Phase 3)", -1, &rc, DT_CENTER | DT_VCENTER | DT_SINGLELINE);
        SelectObject(memDC, oldFont);
    }

    // Blit to screen
    BitBlt(hdc, 0, 0, clientRc.right, clientRc.bottom, memDC, 0, 0, SRCCOPY);

    SelectObject(memDC, oldBitmap);
    DeleteObject(memBitmap);
    DeleteDC(memDC);

    EndPaint(hwnd, &ps);
}

static LRESULT CALLBACK PopoverWndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_PAINT:
        PaintPopover(hwnd);
        return 0;

    case WM_LBUTTONUP: {
        int x = GET_X_LPARAM(lParam);
        int y = GET_Y_LPARAM(lParam);
        POINT pt = { x, y };

        // Kiểm tra click vào thanh tab
        RECT clientRc;
        GetClientRect(hwnd, &clientRc);
        RECT segRc = { 18, 55, clientRc.right - 18, 87 };
        const wchar_t* tabs[] = { L"Hôm nay", L"Chuông", L"Bộ gõ" };
        HDC hdc = GetDC(hwnd);
        int clicked = BrandControls_DrawSegmentedControl(hdc, segRc, tabs, 3, g_currentTab, pt, 0);
        ReleaseDC(hwnd, hdc);

        if (clicked != -1 && clicked != g_currentTab) {
            g_currentTab = clicked;
            InvalidateRect(hwnd, NULL, FALSE);
        }
        return 0;
    }

    case WM_ACTIVATE:
        // Đóng popover khi mất focus (click ra ngoài)
        if (LOWORD(wParam) == WA_INACTIVE) {
            ShowWindow(hwnd, SW_HIDE);
        }
        return 0;

    case WM_NCHITTEST:
        return HTCLIENT;
    }
    return DefWindowProc(hwnd, msg, wParam, lParam);
}

void TrayPopover_Init(HINSTANCE hInstance) {
    Gdiplus::GdiplusStartupInput gdiplusStartupInput;
    Gdiplus::GdiplusStartup(&g_gdiplusTokenPopover, &gdiplusStartupInput, NULL);

    WNDCLASSW wc = {};
    wc.lpfnWndProc   = PopoverWndProc;
    wc.hInstance     = hInstance;
    wc.lpszClassName = kPopoverClassName;
    wc.hCursor       = LoadCursor(NULL, IDC_ARROW);
    
    // CS_DROPSHADOW thêm bóng đổ tự nhiên của Windows
    wc.style         = CS_DROPSHADOW;

    RegisterClassW(&wc);

    // Không viền
    DWORD style = WS_POPUP;
    
    g_hwndPopover = CreateWindowExW(
        0, kPopoverClassName, L"Mindful Popover",
        style,
        0, 0, kPopoverWidth, kPopoverHeight,
        NULL, NULL, hInstance, NULL
    );

    if (g_hwndPopover) {
        // Bo góc 11px
        HRGN rgn = CreateRoundRectRgn(0, 0, kPopoverWidth + 1, kPopoverHeight + 1, 22, 22);
        SetWindowRgn(g_hwndPopover, rgn, TRUE);
    }
}

void TrayPopover_Uninit() {
    if (g_hwndPopover) {
        DestroyWindow(g_hwndPopover);
        g_hwndPopover = NULL;
    }
    UnregisterClassW(kPopoverClassName, GetModuleHandle(NULL));
    
    if (g_gdiplusTokenPopover) {
        Gdiplus::GdiplusShutdown(g_gdiplusTokenPopover);
        g_gdiplusTokenPopover = 0;
    }
}

void TrayPopover_Toggle() {
    if (!g_hwndPopover) return;

    if (IsWindowVisible(g_hwndPopover)) {
        ShowWindow(g_hwndPopover, SW_HIDE);
    } else {
        // Lấy vị trí Taskbar để hiển thị gần Tray Icon
        APPBARDATA abd = { sizeof(APPBARDATA) };
        SHAppBarMessage(ABM_GETTASKBARPOS, &abd);
        
        POINT pt;
        GetCursorPos(&pt); // Tạm lấy vị trí chuột lúc click làm mốc
        
        int x = pt.x - kPopoverWidth / 2;
        int y = pt.y - kPopoverHeight - 10;
        
        // Nếu taskbar ở trên/trái/phải thì chỉnh lại
        if (abd.uEdge == ABE_TOP) {
            y = pt.y + 10;
        } else if (abd.uEdge == ABE_LEFT) {
            x = pt.x + 10;
        } else if (abd.uEdge == ABE_RIGHT) {
            x = pt.x - kPopoverWidth - 10;
        }
        
        // Tránh tràn màn hình
        int screenW = GetSystemMetrics(SM_CXSCREEN);
        int screenH = GetSystemMetrics(SM_CYSCREEN);
        if (x < 0) x = 10;
        if (x + kPopoverWidth > screenW) x = screenW - kPopoverWidth - 10;
        if (y < 0) y = 10;
        if (y + kPopoverHeight > screenH) y = screenH - kPopoverHeight - 10;

        SetWindowPos(g_hwndPopover, HWND_TOPMOST, x, y, 0, 0, SWP_NOSIZE);
        ShowWindow(g_hwndPopover, SW_SHOW);
        SetForegroundWindow(g_hwndPopover); // Để bắt WM_ACTIVATE
        
        InvalidateRect(g_hwndPopover, NULL, FALSE);
    }
}

void TrayPopover_Refresh() {
    if (g_hwndPopover && IsWindowVisible(g_hwndPopover)) {
        InvalidateRect(g_hwndPopover, NULL, FALSE);
    }
}
