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

// Removed virtual state variables to map directly to real global variables.

static const int kPopoverWidth = 338;
static const int kPopoverHeight = 520; // Tăng chiều cao để chứa đủ nội dung

extern int vMoodWatch;
extern int vSendGatekeeper;
extern int vBellInterval;

// Helper vẽ Text đơn giản
static void DrawLabel(HDC hdc, const wchar_t* text, RECT rc, BrandFontRole role, unsigned colorHex, UINT format = DT_LEFT | DT_VCENTER | DT_SINGLELINE) {
    SetBkMode(hdc, TRANSPARENT);
    SetTextColor(hdc, MK_COLORREF(colorHex));
    HFONT font = BrandControls_Font(role);
    HFONT oldFont = (HFONT)SelectObject(hdc, font);
    DrawTextW(hdc, text, -1, &rc, format);
    SelectObject(hdc, oldFont);
}

// Draw/Click Logic
static void ProcessTabToday(HDC hdc, int& y, RECT clientRc, POINT clickPt) {
    // Trạng thái Gác cổng
    const wchar_t* gkTitle = vSendGatekeeper ? L"Gác cổng đang canh" : L"Gác cổng đang tạm nghỉ";
    RECT titleRc = { 18, y, clientRc.right - 18, y + 25 };
    DrawLabel(hdc, gkTitle, titleRc, BrandFontTitle, kBrandPaletteCharcoal);
    
    RECT subRc = { 18, y + 25, clientRc.right - 18, y + 60 };
    const wchar_t* gkSub = vSendGatekeeper ? L"Nhịp thở sẽ xuất hiện nếu nhịp phím quá căng." : L"Phím Enter đi thẳng, nhưng nhật ký vẫn ghi.";
    DrawLabel(hdc, gkSub, subRc, BrandFontBody, kBrandPaletteMuted, DT_LEFT | DT_TOP | DT_WORDBREAK);

    y += 70;

    // Card "Nhận diện" (Độ nhạy)
    RECT cardRc = { 18, y, clientRc.right - 18, y + 65 };
    BrandControls_DrawCard(hdc, cardRc, true);
    RECT cardTitleRc = { cardRc.left + 15, cardRc.top + 15, cardRc.left + 100, cardRc.top + 35 };
    DrawLabel(hdc, L"ĐỘ NHẠY", cardTitleRc, BrandFontEyebrow, kBrandPaletteStone);
    
    RECT segRc = { cardRc.left + 100, cardRc.top + 15, cardRc.right - 15, cardRc.top + 45 };
    const wchar_t* sensTabs[] = { L"Ít nhạy", L"Vừa", L"Nhạy" };
    int currentSens = MindfulKeyHelper::getRegInt(_T("vBellSensitivity"), 0);
    int clickedSens = BrandControls_DrawSegmentedControl(hdc, segRc, sensTabs, 3, currentSens, clickPt, 0);
    if (clickedSens != -1 && clickedSens != currentSens) {
        MindfulKeyHelper::setRegInt(_T("vBellSensitivity"), clickedSens);
        SystemTrayHelper::updateData();
    }

    y += 80;

    // Biểu đồ cảm xúc
    RECT riverRc = { 18, y, clientRc.right - 18, y + 150 };
    BrandControls_DrawCard(hdc, riverRc, true);
    if (vMoodWatch) {
        std::vector<MoodSample> samples = MoodStore_FetchRecentSamples(3 * 3600);
        double liveHead = -1.0; 
        RECT chartRc = { riverRc.left + 5, riverRc.top + 5, riverRc.right - 5, riverRc.bottom - 20 };
        EmotionRiver_Draw(hdc, chartRc, samples, true, liveHead);
    } else {
        DrawLabel(hdc, L"Nhật ký cảm xúc đang tắt.", riverRc, BrandFontBody, kBrandPaletteMuted, DT_CENTER | DT_VCENTER | DT_SINGLELINE);
    }
}

static void ProcessTabBell(HDC hdc, int& y, RECT clientRc, POINT clickPt) {
    // Trạng thái chuông
    RECT card1Rc = { 18, y, clientRc.right - 18, y + 50 };
    BrandControls_DrawCard(hdc, card1Rc, true);
    RECT label1Rc = { card1Rc.left + 15, card1Rc.top, card1Rc.right - 60, card1Rc.bottom };
    DrawLabel(hdc, L"Bật chuông tỉnh thức", label1Rc, BrandFontBody, kBrandPaletteCharcoal);
    RECT switch1Rc = { card1Rc.right - 50, card1Rc.top + 14, card1Rc.right - 14, card1Rc.top + 35 };
    bool isBellEnabled = HAS_BEEP(vSwitchKeyStatus);
    if (clickPt.x != -1 && PtInRect(&switch1Rc, clickPt)) {
        if (isBellEnabled) vSwitchKeyStatus &= ~FLAG_BEEP;
        else vSwitchKeyStatus |= FLAG_BEEP;
        APP_SET_DATA(vSwitchKeyStatus, vSwitchKeyStatus);
        SystemTrayHelper::updateData();
        isBellEnabled = HAS_BEEP(vSwitchKeyStatus);
    }
    BrandControls_DrawPillSwitch(hdc, switch1Rc, isBellEnabled);
    y += 65;

    // Nhịp
    RECT card2Rc = { 18, y, clientRc.right - 18, y + 110 };
    BrandControls_DrawCard(hdc, card2Rc, true);
    RECT label2Rc = { card2Rc.left + 15, card2Rc.top + 10, card2Rc.right - 15, card2Rc.top + 30 };
    DrawLabel(hdc, L"NHỊP", label2Rc, BrandFontEyebrow, kBrandPaletteStone);
    
    RECT seg2Rc = { card2Rc.left + 15, card2Rc.top + 35, card2Rc.right - 15, card2Rc.top + 65 };
    const wchar_t* intervalTabs[] = { L"30 phút", L"60 phút", L"Tùy chỉnh" };
    int currentInt = (vBellInterval <= 30) ? 0 : ((vBellInterval <= 60) ? 1 : 2);
    int clickedInt = BrandControls_DrawSegmentedControl(hdc, seg2Rc, intervalTabs, 3, currentInt, clickPt, 0);
    if (clickedInt != -1 && clickedInt != currentInt) {
        int newMins = (clickedInt == 0) ? 30 : ((clickedInt == 1) ? 60 : 120);
        APP_SET_DATA(vBellInterval, newMins);
        extern void Bell_ApplySettings();
        Bell_ApplySettings();
        SystemTrayHelper::updateData();
        currentInt = clickedInt;
    }
    
    if (currentInt == 2) {
        RECT editRc = { card2Rc.left + 15, card2Rc.top + 75, card2Rc.left + 80, card2Rc.top + 95 };
        BrandControls_DrawTextBoxFrame(hdc, editRc);
        wchar_t buf[32];
        wsprintfW(buf, L"%d", vBellInterval);
        DrawLabel(hdc, buf, editRc, BrandFontBody, kBrandPaletteCharcoal, DT_CENTER | DT_VCENTER | DT_SINGLELINE);
        RECT labelPhutRc = { editRc.right + 10, editRc.top, editRc.right + 50, editRc.bottom };
        DrawLabel(hdc, L"phút", labelPhutRc, BrandFontBody, kBrandPaletteCharcoal);
    }
    y += 125;

    // Âm thanh
    RECT card3Rc = { 18, y, clientRc.right - 18, y + 110 };
    BrandControls_DrawCard(hdc, card3Rc, true);
    RECT label3Rc = { card3Rc.left + 15, card3Rc.top + 10, card3Rc.right - 15, card3Rc.top + 30 };
    DrawLabel(hdc, L"BỘ TIẾNG", label3Rc, BrandFontEyebrow, kBrandPaletteStone);
    
    RECT iconGrpRc = { card3Rc.left + 15, card3Rc.top + 35, card3Rc.right - 15, card3Rc.top + 75 };
    int currentSnd = MindfulKeyHelper::getRegInt(_T("vBellSoundIndex"), 0);
    int clickedSnd = BrandControls_DrawIconGroup(hdc, iconGrpRc, 4, currentSnd, clickPt);
    if (clickedSnd != -1 && clickedSnd != currentSnd) {
        MindfulKeyHelper::setRegInt(_T("vBellSoundIndex"), clickedSnd);
        SystemTrayHelper::updateData();
    }
    
    RECT sliderRc = { card3Rc.left + 15, card3Rc.top + 85, card3Rc.right - 15, card3Rc.top + 100 };
    int currentVol = MindfulKeyHelper::getRegInt(_T("vVolume"), 50);
    int clickedVol = BrandControls_DrawSlider(hdc, sliderRc, currentVol, clickPt);
    if (clickedVol != currentVol) {
        MindfulKeyHelper::setRegInt(_T("vVolume"), clickedVol);
        SystemTrayHelper::updateData();
    }
    y += 125;
}

static void ProcessTabKeyboard(HDC hdc, int& y, RECT clientRc, POINT clickPt) {
    // Kiểu gõ
    RECT card1Rc = { 18, y, clientRc.right - 18, y + 90 };
    BrandControls_DrawCard(hdc, card1Rc, true);
    
    RECT labelKieuGoRc = { card1Rc.left + 15, card1Rc.top + 15, card1Rc.left + 100, card1Rc.top + 35 };
    DrawLabel(hdc, L"Kiểu gõ", labelKieuGoRc, BrandFontBody, kBrandPaletteCharcoal);
    RECT comboKieuGoRc = { card1Rc.right - 120, card1Rc.top + 10, card1Rc.right - 15, card1Rc.top + 40 };
    BrandControls_DrawTextBoxFrame(hdc, comboKieuGoRc);
    DrawLabel(hdc, L"Telex", comboKieuGoRc, BrandFontBody, kBrandPaletteCharcoal, DT_CENTER | DT_VCENTER | DT_SINGLELINE);

    RECT labelBangMaRc = { card1Rc.left + 15, card1Rc.top + 55, card1Rc.left + 100, card1Rc.top + 75 };
    DrawLabel(hdc, L"Bảng mã", labelBangMaRc, BrandFontBody, kBrandPaletteCharcoal);
    RECT comboBangMaRc = { card1Rc.right - 120, card1Rc.top + 50, card1Rc.right - 15, card1Rc.top + 80 };
    BrandControls_DrawTextBoxFrame(hdc, comboBangMaRc);
    DrawLabel(hdc, L"Unicode", comboBangMaRc, BrandFontBody, kBrandPaletteCharcoal, DT_CENTER | DT_VCENTER | DT_SINGLELINE);

    y += 105;

    // Tuỳ chọn
    RECT card2Rc = { 18, y, clientRc.right - 18, y + 130 };
    BrandControls_DrawCard(hdc, card2Rc, true);

    auto DrawRowSwitch = [&](int i, const wchar_t* label, int& stateFlag) {
        int rowY = card2Rc.top + 10 + i * 35;
        RECT labelRc = { card2Rc.left + 15, rowY, card2Rc.right - 60, rowY + 25 };
        DrawLabel(hdc, label, labelRc, BrandFontBody, kBrandPaletteCharcoal);
        RECT switchRc = { card2Rc.right - 50, rowY + 2, card2Rc.right - 14, rowY + 23 };
        bool state = (stateFlag == 1);
        if (clickPt.x != -1 && PtInRect(&switchRc, clickPt)) {
            stateFlag = state ? 0 : 1;
            // The global variables are just externs here, but we need to APP_SET_DATA to save them.
            // Since we can't do macro easily without the string name, we will handle it explicitly below.
            state = (stateFlag == 1);
            SystemTrayHelper::updateData();
        }
        BrandControls_DrawPillSwitch(hdc, switchRc, state);
    };

    int oldLang = vLanguage;
    DrawRowSwitch(0, L"Gõ tiếng Việt", vLanguage);
    if (oldLang != vLanguage) APP_SET_DATA(vLanguage, vLanguage);

    int oldSpell = vCheckSpelling;
    DrawRowSwitch(1, L"Kiểm tra chính tả", vCheckSpelling);
    if (oldSpell != vCheckSpelling) APP_SET_DATA(vCheckSpelling, vCheckSpelling);

    int oldCap = vUpperCaseFirstChar;
    DrawRowSwitch(2, L"Viết hoa đầu câu", vUpperCaseFirstChar);
    if (oldCap != vUpperCaseFirstChar) APP_SET_DATA(vUpperCaseFirstChar, vUpperCaseFirstChar);

    y += 145;
}

static void PaintPopover(HWND hwnd) {
    PAINTSTRUCT ps;
    HDC hdc = BeginPaint(hwnd, &ps);

    RECT clientRc;
    GetClientRect(hwnd, &clientRc);

    HDC memDC = CreateCompatibleDC(hdc);
    HBITMAP memBitmap = CreateCompatibleBitmap(hdc, clientRc.right, clientRc.bottom);
    HBITMAP oldBitmap = (HBITMAP)SelectObject(memDC, memBitmap);

    // Tô nền cardWhite
    BrandControls_FillRect(memDC, clientRc, kBrandPaletteCardWhite);

    // Vẽ Header
    BrandControls_DrawCardHeader(memDC, clientRc.right, L"Mindful Keyboard");

    int y = 45; // Dưới đường kẻ ngăn

    // Thanh Tab (Segmented)
    RECT segRc = { 18, y + 10, clientRc.right - 18, y + 42 };
    const wchar_t* tabs[] = { L"Hôm nay", L"Chuông", L"Bộ gõ" };
    POINT pt = { -1, -1 };
    BrandControls_DrawSegmentedControl(memDC, segRc, tabs, 3, g_currentTab, pt, 0);

    y += 50;

    if (g_currentTab == 0) ProcessTabToday(memDC, y, clientRc, pt);
    else if (g_currentTab == 1) ProcessTabBell(memDC, y, clientRc, pt);
    else ProcessTabKeyboard(memDC, y, clientRc, pt);

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

    case WM_LBUTTONDOWN:
    case WM_LBUTTONUP:
    case WM_MOUSEMOVE: {
        int x = GET_X_LPARAM(lParam);
        int y = GET_Y_LPARAM(lParam);
        POINT pt = { x, y };
        
        // Hạn chế drag update quá nhiều, chỉ xử lý LBUTTONUP và LBUTTONDOWN để drag slider
        if (msg == WM_MOUSEMOVE && !(wParam & MK_LBUTTON)) break;

        RECT clientRc;
        GetClientRect(hwnd, &clientRc);
        HDC hdc = GetDC(hwnd);
        
        if (msg == WM_LBUTTONUP) {
            RECT segRc = { 18, 55, clientRc.right - 18, 87 };
            const wchar_t* tabs[] = { L"Hôm nay", L"Chuông", L"Bộ gõ" };
            int clicked = BrandControls_DrawSegmentedControl(hdc, segRc, tabs, 3, g_currentTab, pt, 0);
            if (clicked != -1 && clicked != g_currentTab) {
                g_currentTab = clicked;
                InvalidateRect(hwnd, NULL, FALSE);
                ReleaseDC(hwnd, hdc);
                return 0;
            }
        }

        // Process clicks/drags in current tab
        int drawY = 95;
        if (g_currentTab == 0) ProcessTabToday(hdc, drawY, clientRc, pt);
        else if (g_currentTab == 1) ProcessTabBell(hdc, drawY, clientRc, pt);
        else ProcessTabKeyboard(hdc, drawY, clientRc, pt);

        ReleaseDC(hwnd, hdc);
        InvalidateRect(hwnd, NULL, FALSE); // Redraw sau khi update state
        return 0;
    }

    case WM_ACTIVATE:
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
