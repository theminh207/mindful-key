//
// TrayPopover.cpp — [MINDFUL] Cửa sổ Popover bật từ khay hệ thống (mặt tiền của app).
//
#include "stdafx.h"
#include "TrayPopover.h"
#include "AppDelegate.h"
#include "SystemTrayHelper.h"
#include "BrandPalette.h"
#include "BrandControls.h"
#include "ReflectionScreen.h"
#include "MoodStore.h"
#include "SendGatekeeper.h"
#include <objidl.h>
#include <windowsx.h>   // [MINDFUL] GET_X_LPARAM / GET_Y_LPARAM (dùng ở WM_LBUTTONUP) — thiếu là MSVC báo identifier không nhận diện
#include <gdiplus.h>
#include "Bell.h"
#include "MoodWatch.h"   // [MINDFUL] B3 — MoodWatch_LiveAmplitude/FetchLiveTrace + vMoodWatch/Toggle

#pragma comment(lib, "gdiplus.lib")

using namespace std;

static const wchar_t* kPopoverClassName = L"MK_TrayPopover";
static HWND g_hwndPopover = NULL;
static int g_currentTab = 0; // 0: Hôm nay, 1: Chuông, 2: Bộ gõ
static ULONG_PTR g_gdiplusTokenPopover = 0;

// Removed virtual state variables to map directly to real global variables.

static const int kPopoverWidth = 338;
static const int kPopoverHeight = 520; // Tăng chiều cao để chứa đủ nội dung

extern int vSendGatekeeper;
// vMoodWatch + MoodWatch_Toggle() nay lấy từ MoodWatch.h (include phía trên) — bỏ extern cục bộ.

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
    // [MINDFUL] A8 — vBellSensitivity lưu theo thang NudgeCoordinator.h (1=ít·2=vừa·3=nhạy, chưa
    // lưu=vừa), KHÁC chỉ số 0-based mà segmented control dùng để vẽ/trả về. Đổi 2 chiều: đọc trừ 1
    // trước khi vẽ, ghi cộng 1 trước khi lưu.
    int storedSens = MindfulKeyHelper::getRegInt(_T("vBellSensitivity"), 2);
    int currentSensIdx = (storedSens >= 1 && storedSens <= 3) ? (storedSens - 1) : 1;
    int clickedSens = BrandControls_DrawSegmentedControl(hdc, segRc, sensTabs, 3, currentSensIdx, clickPt, 0);
    if (clickedSens != -1 && clickedSens != currentSensIdx) {
        MindfulKeyHelper::setRegInt(_T("vBellSensitivity"), clickedSens + 1);
        SystemTrayHelper::updateData();
    }

    y += 80;

    // Biểu đồ cảm xúc
    RECT riverRc = { 18, y, clientRc.right - 18, y + 150 };
    BrandControls_DrawCard(hdc, riverRc, true);
    if (vMoodWatch) {
        // [MINDFUL] B3 — vệt DÀY (trộn RAM + persisted) + đầu sóng SỐNG thật (nhích khi gõ, phai khi
        // im). Trước đây samples chỉ lấy mẫu thưa persisted (≥15') + liveHead=-1 (không đầu sóng) nên
        // gõ xong không thấy gì — đúng "sóng chưa hoạt động" chủ dự án báo.
        std::vector<MoodSample> samples = MoodWatch_FetchLiveTrace(3 * 3600);
        double liveHead = MoodWatch_LiveAmplitude();
        RECT chartRc = { riverRc.left + 5, riverRc.top + 5, riverRc.right - 5, riverRc.bottom - 20 };
        EmotionRiver_Draw(hdc, chartRc, samples, true, liveHead);
    } else {
        // [MINDFUL] A7 — nút "Bật nhật ký" tại chỗ, thay vì bắt người dùng tự tìm menu khay chuột
        // phải. MoodWatch_Toggle() tự lo cả 2 lớp consent (đọc sóng + ghi nhật ký) — không cần thêm
        // gì ở đây. InvalidateRect đã có sẵn ở PopoverWndProc sau mọi dispatch, không gọi lại.
        RECT msgRc = { riverRc.left + 10, riverRc.top + 15, riverRc.right - 10, riverRc.top + 65 };
        DrawLabel(hdc, L"Nhật ký cảm xúc đang tắt.", msgRc, BrandFontBody, kBrandPaletteMuted, DT_CENTER | DT_VCENTER | DT_SINGLELINE);

        RECT btnEnableRc = { riverRc.left + (riverRc.right - riverRc.left) / 2 - 70, riverRc.top + 95,
                              riverRc.left + (riverRc.right - riverRc.left) / 2 + 70, riverRc.top + 123 };
        if (clickPt.x != -1 && PtInRect(&btnEnableRc, clickPt)) {
            MoodWatch_Toggle();
        }
        HBRUSH btnBr = CreateSolidBrush(MK_COLORREF(kBrandPaletteTeal));
        FillRect(hdc, &btnEnableRc, btnBr);
        DeleteObject(btnBr);
        DrawLabel(hdc, L"Bật nhật ký", btnEnableRc, BrandFontBody, kBrandPaletteCardWhite, DT_CENTER | DT_VCENTER | DT_SINGLELINE);
    }
}

static void ProcessTabBell(HDC hdc, int& y, RECT clientRc, POINT clickPt) {
    // Trạng thái chuông
    RECT card1Rc = { 18, y, clientRc.right - 18, y + 50 };
    BrandControls_DrawCard(hdc, card1Rc, true);
    RECT label1Rc = { card1Rc.left + 15, card1Rc.top, card1Rc.right - 60, card1Rc.bottom };
    DrawLabel(hdc, L"Bật chuông tỉnh thức", label1Rc, BrandFontBody, kBrandPaletteCharcoal);
    // [MINDFUL] A6 — nối ĐÚNG vBell (không phải FLAG_BEEP của OpenKey, tiếng bíp đổi Việt/Anh).
    RECT switch1Rc = { card1Rc.right - 50, card1Rc.top + 14, card1Rc.right - 14, card1Rc.top + 35 };
    bool isBellEnabled = (vBell != 0);
    if (clickPt.x != -1 && PtInRect(&switch1Rc, clickPt)) {
        APP_SET_DATA(vBell, vBell ? 0 : 1);
        Bell_ApplySettings();   // BẬT/tắt đồng hồ chuông thật
        SystemTrayHelper::updateData();
        isBellEnabled = (vBell != 0);
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
    RECT label3Rc = { card3Rc.left + 15, card3Rc.top + 10, card3Rc.left + 100, card3Rc.top + 30 };
    DrawLabel(hdc, L"BỘ TIẾNG", label3Rc, BrandFontEyebrow, kBrandPaletteStone);

    // [MINDFUL] B4 — nút "Nghe thử": Bell_PreviewSound() phát NGAY tiếng+âm lượng đang chọn, bỏ qua
    // mọi cổng (snooze/giờ/cooldown) — để test được ngay, không chờ nhịp chuông 15+ phút. Đây là
    // fix trực tiếp phản hồi "chuông không hoạt động" (thật ra chuông chạy, chỉ chưa test nhanh được).
    RECT btnPreviewRc = { card3Rc.right - 90, card3Rc.top + 8, card3Rc.right - 15, card3Rc.top + 30 };
    if (clickPt.x != -1 && PtInRect(&btnPreviewRc, clickPt)) {
        Bell_PreviewSound();
    }
    HBRUSH brPreview = CreateSolidBrush(MK_COLORREF(kBrandPaletteTeal));
    FillRect(hdc, &btnPreviewRc, brPreview);
    DeleteObject(brPreview);
    DrawLabel(hdc, L"Nghe thử", btnPreviewRc, BrandFontButton, kBrandPaletteCardWhite, DT_CENTER | DT_VCENTER | DT_SINGLELINE);
    
    // [MINDFUL] A6 — ghi ĐÚNG chuỗi id mà Bell.cpp SoundIdFromStored chấp nhận (không phải
    // vBellSoundIndex — khoá đó không ai đọc, giống bug A2 ở tab Chuông cửa Cài đặt).
    RECT iconGrpRc = { card3Rc.left + 15, card3Rc.top + 35, card3Rc.right - 15, card3Rc.top + 75 };
    std::wstring currentSndName = MindfulKeyHelper::getRegString(_T("vBellSoundName"), _T("temple"));
    int currentSnd = (currentSndName == L"chime") ? 1 : (currentSndName == L"wind") ? 2 : (currentSndName == L"custom") ? 3 : 0;
    static const int kBellIconIds[] = { IDI_ICON_BELL_TEMPLE, IDI_ICON_BELL_CHIME, IDI_ICON_BELL_WIND, IDI_ICON_BELL_CUSTOM };
    int clickedSnd = BrandControls_DrawIconGroup(hdc, iconGrpRc, 4, currentSnd, clickPt, kBellIconIds);
    if (clickedSnd != -1 && clickedSnd != currentSnd) {
        static const wchar_t* kBellSoundIds[] = { L"temple", L"chime", L"wind", L"custom" };
        MindfulKeyHelper::setRegString(_T("vBellSoundName"), kBellSoundIds[clickedSnd]);
        SystemTrayHelper::updateData();
    }

    // [MINDFUL] A6 — ghi ĐÚNG vBellVolume (không vVolume — khoá chết). Cũng vá lỗi kiểu dữ liệu có
    // sẵn: BrandControls_DrawSlider nhận/trả thumbPos THANG 0..1 (float), nhưng code cũ gán thẳng
    // vào biến int — ép kiểu cắt cụt 0..1 xuống int gần như LUÔN ra 0, nên trước đây bấm vào
    // slider gần như luôn đặt âm lượng về 0 bất kể bấm chỗ nào.
    RECT sliderRc = { card3Rc.left + 15, card3Rc.top + 85, card3Rc.right - 15, card3Rc.top + 100 };
    int currentVol = MindfulKeyHelper::getRegInt(_T("vBellVolume"), 60);
    float clickedVolPos = BrandControls_DrawSlider(hdc, sliderRc, (float)currentVol / 100.0f, clickPt);
    int newVol = (int)(clickedVolPos * 100.0f);
    if (newVol != currentVol) {
        MindfulKeyHelper::setRegInt(_T("vBellVolume"), newVol);
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
    if (oldLang != vLanguage) { APP_SET_DATA(vLanguage, vLanguage); }

    int oldSpell = vCheckSpelling;
    DrawRowSwitch(1, L"Kiểm tra chính tả", vCheckSpelling);
    if (oldSpell != vCheckSpelling) { APP_SET_DATA(vCheckSpelling, vCheckSpelling); }

    int oldCap = vUpperCaseFirstChar;
    DrawRowSwitch(2, L"Viết hoa đầu câu", vUpperCaseFirstChar);
    if (oldCap != vUpperCaseFirstChar) { APP_SET_DATA(vUpperCaseFirstChar, vUpperCaseFirstChar); }

    y += 145;
}

// [MINDFUL] B9 — overlay phần phải header: pill "VN" + nút "⋯" (đối ứng macOS PanelViewController).
// Pill "VN" là NHỊ PHÂN bộ gõ Việt bật/tắt — CHỈ báo ngôn ngữ, KHÔNG BAO GIỜ báo cảm xúc (HIẾN
// CHƯƠNG). "⋯" mở đúng menu khay (SystemTrayHelper::showContextMenu). KHÔNG nhét vào DrawCardHeader
// vì hàm đó dùng chung 4 nơi (Reflection/Gatekeeper cũng gọi). clickPt.x==-1 => chỉ vẽ.
static void ProcessHeaderExtras(HDC hdc, const RECT& clientRc, POINT clickPt) {
    RECT dotsRc = { clientRc.right - 18 - 22, 9, clientRc.right - 18, 31 };
    RECT pillRc = { dotsRc.left - 8 - 34, 11, dotsRc.left - 8, 29 };

    // Hit-test trước — đổi state rồi vẽ theo state mới (giống các control khác trong file).
    if (clickPt.x != -1) {
        if (PtInRect(&pillRc, clickPt)) {
            APP_SET_DATA(vLanguage, vLanguage ? 0 : 1);
        } else if (PtInRect(&dotsRc, clickPt)) {
            SystemTrayHelper::showContextMenu();
            return;  // menu modal đã chạy; popover có thể đã ẩn do mất focus
        }
    }

    // Pill "VN": teal khi bộ gõ Việt bật, xám divider khi tắt.
    bool vnOn = (vLanguage == 1);
    int pillR = pillRc.bottom - pillRc.top;
    HRGN pillRgn = CreateRoundRectRgn(pillRc.left, pillRc.top, pillRc.right + 1, pillRc.bottom + 1, pillR, pillR);
    HBRUSH pillBr = CreateSolidBrush(MK_COLORREF(vnOn ? kBrandPaletteTeal : kBrandPaletteDivider));
    FillRgn(hdc, pillRgn, pillBr);
    DeleteObject(pillBr);
    DeleteObject(pillRgn);
    DrawLabel(hdc, L"VN", pillRc, BrandFontEyebrow, vnOn ? kBrandPaletteCardWhite : kBrandPaletteStone,
              DT_CENTER | DT_VCENTER | DT_SINGLELINE);

    // "⋯" = 3 chấm stone (không dùng glyph font — vẽ tay cho chắc, khớp lối "vẽ mù" của file).
    int cy = (dotsRc.top + dotsRc.bottom) / 2;
    int cx = (dotsRc.left + dotsRc.right) / 2;
    HBRUSH dotBr = CreateSolidBrush(MK_COLORREF(kBrandPaletteStone));
    HBRUSH oldBr = (HBRUSH)SelectObject(hdc, dotBr);
    HPEN oldPen = (HPEN)SelectObject(hdc, (HPEN)GetStockObject(NULL_PEN));
    for (int i = -1; i <= 1; i++) {
        int dx = cx + i * 6;
        Ellipse(hdc, dx - 2, cy - 2, dx + 2, cy + 2);
    }
    SelectObject(hdc, oldPen);
    SelectObject(hdc, oldBr);
    DeleteObject(dotBr);
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
    POINT noHit = { -1, -1 };
    ProcessHeaderExtras(memDC, clientRc, noHit);

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
            // Header extras (pill VN + ⋯) — nằm trên đường kẻ ngăn (y<40), không đè segmented/tab.
            ProcessHeaderExtras(hdc, clientRc, pt);

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

        // [MINDFUL] A5 — chỉ xử ở WM_LBUTTONUP. Trước đây khối này chạy cho CẢ LBUTTONDOWN lẫn
        // LBUTTONUP (và MOUSEMOVE lúc giữ chuột) nên mỗi cú bấm gọi ProcessTabX 2 LẦN — pill switch
        // (PtInRect trong ProcessTabBell/ProcessTabKeyboard) đảo trạng thái ở LBUTTONDOWN rồi đảo
        // NGƯỢC LẠI ở LBUTTONUP, về đúng chỗ cũ = bấm như không. Segmented/slider/icon-group là
        // "đặt tuyệt đối theo vị trí chuột" nên không lộ bug (idempotent), chỉ pill mới lộ.
        // Đánh đổi: slider giờ là "click-để-đặt" (đặt theo điểm thả chuột), không còn kéo-mượt theo
        // chuột lúc đang giữ — đơn giản hơn, và đúng cho mọi control khác trên tab.
        if (msg == WM_LBUTTONUP) {
            int drawY = 95;
            if (g_currentTab == 0) ProcessTabToday(hdc, drawY, clientRc, pt);
            else if (g_currentTab == 1) ProcessTabBell(hdc, drawY, clientRc, pt);
            else ProcessTabKeyboard(hdc, drawY, clientRc, pt);
        }

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
