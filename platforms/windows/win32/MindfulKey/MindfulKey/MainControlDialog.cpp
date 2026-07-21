/*----------------------------------------------------------
MindfulKey - The Cross platform Open source Vietnamese Keyboard application.

Copyright (C) 2019 Mai Vu Tuyen
Contact: maivutuyen.91@gmail.com
Github: https://github.com/tuyenvm/MindfulKey
Fanpage: https://www.facebook.com/MindfulKeyVN

This file is belong to the MindfulKey project, Win32 version
which is released under GPL license.
You can fork, modify, improve this program. If you
redistribute your new version, it MUST be open source.
-----------------------------------------------------------*/
#include "MainControlDialog.h"
#include "AppDelegate.h"
#include "MoodWatch.h"
#include "Bell.h"
#include "BrandControls.h"
#include "ReflectionScreen.h"
#include "MoodStore.h"
#include <Shlobj.h>
#include <Uxtheme.h>

// [MINDFUL] GĐ6 — ImageList_* (icon tab) là HÀM THẬT trong comctl32, phải link. File này lẫn
// stdafx.h đã include <Commctrl.h> từ đời MindfulKey nhưng chưa bao giờ cần lib: TabCtrl_*/ListView_*
// mà code cũ dùng đều là MACRO gói SendMessage, không đụng thư viện. ImageList_* thì khác.
#pragma comment(lib, "comctl32.lib")

#pragma comment(lib, "UxTheme.lib")

static Uint16 _lastKeyCode;

MainControlDialog::MainControlDialog(const HINSTANCE& hInstance, const int& resourceId)
    : BaseDialog(hInstance, resourceId) {
}

MainControlDialog::~MainControlDialog() {
}

void MainControlDialog::initDialog() {
    HINSTANCE hIns = GetModuleHandleW(NULL);
    //dialog icon
    SET_DIALOG_ICON(IDI_APP_ICON);

    //set title version
    TCHAR title[256];
    TCHAR titleBuffer[256];
    LoadString(hIns, IDS_MAIN_DIALOG_TITLE, title, 256);
    wsprintfW(titleBuffer, title, MindfulKeyHelper::getVersionString().c_str());
    SetWindowText(hDlg, titleBuffer);

    // 6-Nav Layout Position
    RECT rc;
    GetClientRect(hDlg, &rc);
    int leftNavWidth = 160;
    rc.left += leftNavWidth;

    // Các thẻ cài đặt (Bộ gõ, Hệ thống, Giới thiệu) giờ đây được vẽ hoàn toàn bằng GDI+
    // Không còn dùng IDD_DIALOG_TAB_... native nữa.
    
    SendDlgItemMessage(hDlg, IDBUTTON_OK, BM_SETIMAGE, IMAGE_ICON, (LPARAM)LoadIcon(hIns, MAKEINTRESOURCEW(IDI_ICON_OK_BUTTON)));
    SendDlgItemMessage(hDlg, ID_BTN_DEFAULT, BM_SETIMAGE, IMAGE_ICON, (LPARAM)LoadIcon(hIns, MAKEINTRESOURCEW(IDI_ICON_DEFAULT_BUTTON)));
    SendDlgItemMessage(hDlg, IDBUTTON_EXIT, BM_SETIMAGE, IMAGE_ICON, (LPARAM)LoadIcon(hIns, MAKEINTRESOURCEW(IDI_ICON_EXIT_BUTTON)));
    fillData();
}

INT_PTR MainControlDialog::eventProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam) {
    switch (uMsg) {
    case WM_INITDIALOG:
        this->hDlg = hDlg;
        initDialog();
        return TRUE;
    case WM_COMMAND: {
        int wmId = LOWORD(wParam);
        switch (wmId) {
        case IDBUTTON_OK:
            AppDelegate::getInstance()->closeDialog(this);
            break;
        case IDBUTTON_EXIT:
            AppDelegate::getInstance()->onMindfulKeyExit();
            break;
        case ID_BTN_DEFAULT: {
            int msgboxID = MessageBox(
                hDlg,
                _T("Bạn có chắc chắn muốn thiết lập lại cài đặt gốc?"),
                _T("Mindful Keyboard"),
                MB_ICONEXCLAMATION | MB_YESNO
            );
            if (msgboxID == IDYES) {
                AppDelegate::getInstance()->onDefaultConfig();
            }
            break;
        }
        case IDC_BUTTON_MACRO_TABLE:
            AppDelegate::getInstance()->onMacroTable();
            break;
        case IDC_BUTTON_CHECK_UPDATE:
            onUpdateButton();
            break;
        case IDC_BUTTON_GO_SOURCE_CODE:
            ShellExecute(NULL, _T("open"), _T("https://github.com/theminh207/mindful-key"), NULL, NULL, SW_SHOWNORMAL);
            break;
        default:
            if (HIWORD(wParam) == CBN_SELCHANGE) {
                this->onComboBoxSelected((HWND)lParam, LOWORD(wParam));
            }
            else if (HIWORD(wParam) == BN_CLICKED) {
                this->onCheckboxClicked((HWND)lParam);
            }
            else if (HIWORD(wParam) == EN_CHANGE) {
                _lastKeyCode = MindfulKeyManager::_lastKeyCode;
                if (_lastKeyCode > 0) {
                    MindfulKeyManager::_lastKeyCode = 0;
                    this->onCharacter((HWND)lParam, _lastKeyCode);
                }
            }
            break;
        }
        break;
    }
    case WM_NOTIFY: {
        switch (((LPNMHDR)lParam)->code) {
        case TCN_SELCHANGE:
            onTabIndexChanged();
            break;
        case NM_CLICK:
        case NM_RETURN: {
            PNMLINK link = (PNMLINK)lParam;
            if (link->hdr.idFrom == IDC_SYSLINK_HOME_PAGE)
                ShellExecute(NULL, _T("open"), _T("https://github.com/theminh207/mindful-key"), NULL, NULL, SW_SHOWNORMAL);
            else if (link->hdr.idFrom == IDC_SYSLINK_FANPAGE)
                ShellExecute(NULL, _T("open"), _T("https://www.facebook.com/MindfulKeyVN"), NULL, NULL, SW_SHOWNORMAL);
            else if (link->hdr.idFrom == IDC_SYSLINK_AUTHOR_EMAIL)
                ShellExecute(NULL, _T("open"), _T("mailto:maivutuyen.91@gmail.com"), NULL, NULL, SW_SHOWNORMAL);
            break;
        }
        }
        break;
    }
    }

    return FALSE;
}

INT_PTR MainControlDialog::tabPageEventProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam) {
    if (uMsg == WM_INITDIALOG) {
#ifdef _WIN64
        SetWindowLongPtr(hDlg, GWLP_USERDATA, lParam);
#else
        SetWindowLong(hDlg, GWL_USERDATA, lParam);
#endif
        return TRUE;
    }
    else if (uMsg == WM_ERASEBKGND) {
        return TRUE;
    }
    else if ((uMsg == WM_CTLCOLORSTATIC || uMsg == WM_CTLCOLORBTN) && IsThemeActive()) {
        SetBkMode((HDC)wParam, TRANSPARENT);
        return (LRESULT)GetStockObject(COLOR_WINDOW + 1);
    }
    else if (uMsg == WM_PAINT && IsThemeActive()) {
        PAINTSTRUCT ps;
        HDC hdc = BeginPaint(hDlg, &ps);

        // All painting occurs here, between BeginPaint and EndPaint.
        RECT clientRc;
        GetClientRect(hDlg, &clientRc);
        
        // Double buffering
        HDC memDC = CreateCompatibleDC(hdc);
        HBITMAP memBitmap = CreateCompatibleBitmap(hdc, clientRc.right, clientRc.bottom);
        HBITMAP oldBitmap = (HBITMAP)SelectObject(memDC, memBitmap);

        // Nền trắng/xám
        FillRect(memDC, &clientRc, (HBRUSH)(COLOR_WINDOW + 1));

        // Vẽ 6-Nav (Cột trái)
        RECT navRc = { 10, 20, 150, 260 };
        const wchar_t* tabs[] = { L"Hôm nay", L"Chuông", L"Bộ gõ", L"Riêng tư", L"Hệ thống", L"Giới thiệu" };
        POINT pt = { -1, -1 };
        // Giả lập Segmented Control dọc hoặc vẽ thẳng
        // Tạm thời gọi hàm DrawSegmentedControl (cần thêm cờ hoặc vẽ tuỳ chỉnh dọc)
        // Thay vì thế, ta vẽ nhanh thủ công ở đây:
        for (int i = 0; i < 6; i++) {
            RECT itemRc = { navRc.left, navRc.top + i * 40, navRc.right, navRc.top + i * 40 + 35 };
            if (i == currentTab) {
                // Background tealLight
                HBRUSH br = CreateSolidBrush(MK_COLORREF(0xDEF0F2)); // tealLight
                FillRect(memDC, &itemRc, br);
                DeleteObject(br);
            }
            SetBkMode(memDC, TRANSPARENT);
            SetTextColor(memDC, MK_COLORREF(i == currentTab ? 0x1D7C91 : 0x4B5563)); // teal vs charcoal
            DrawTextW(memDC, tabs[i], -1, &itemRc, DT_CENTER | DT_VCENTER | DT_SINGLELINE);
        }

        // Nếu là tab Hôm nay / Chuông / Riêng tư, vẽ nội dung GDI+ ở bên phải
        if (currentTab == 0) {
            RECT contentRc = { 160, 0, clientRc.right, clientRc.bottom };
            int y = 20;
            
            // Trạng thái Gác cổng
            const wchar_t* gkTitle = vMoodWatch ? L"Gác cổng đang canh" : L"Gác cổng đang tạm nghỉ";
            RECT titleRc = { contentRc.left + 20, y, contentRc.right - 20, y + 25 };
            SetBkMode(memDC, TRANSPARENT);
            SetTextColor(memDC, MK_COLORREF(kBrandPaletteCharcoal));
            HFONT titleFont = BrandControls_Font(BrandFontTitle);
            HFONT oldFont = (HFONT)SelectObject(memDC, titleFont);
            DrawTextW(memDC, gkTitle, -1, &titleRc, DT_LEFT | DT_VCENTER | DT_SINGLELINE);
            
            RECT subRc = { contentRc.left + 20, y + 25, contentRc.right - 20, y + 60 };
            SetTextColor(memDC, MK_COLORREF(kBrandPaletteMuted));
            SelectObject(memDC, BrandControls_Font(BrandFontBody));
            const wchar_t* gkSub = vMoodWatch ? L"Nhịp thở sẽ xuất hiện nếu nhịp phím quá căng." : L"Phím Enter đi thẳng, nhưng nhật ký vẫn ghi.";
            DrawTextW(memDC, gkSub, -1, &subRc, DT_LEFT | DT_TOP | DT_WORDBREAK);
            SelectObject(memDC, oldFont);

            y += 70;

            // Card Nhận diện
            RECT cardRc = { contentRc.left + 20, y, contentRc.right - 20, y + 65 };
            BrandControls_DrawCard(memDC, cardRc, true);
            
            SetTextColor(memDC, MK_COLORREF(kBrandPaletteStone));
            HFONT eyeFont = BrandControls_Font(BrandFontEyebrow);
            oldFont = (HFONT)SelectObject(memDC, eyeFont);
            RECT cardTitleRc = { cardRc.left + 15, cardRc.top + 15, cardRc.left + 100, cardRc.top + 35 };
            DrawTextW(memDC, L"ĐỘ NHẠY", -1, &cardTitleRc, DT_LEFT | DT_VCENTER | DT_SINGLELINE);
            SelectObject(memDC, oldFont);

            RECT segRc = { cardRc.left + 100, cardRc.top + 15, cardRc.right - 15, cardRc.top + 45 };
            const wchar_t* sensTabs[] = { L"Ít nhạy", L"Vừa", L"Nhạy" };
            int currentSens = MindfulKeyHelper::getRegInt(_T("vBellSensitivity"), 0);
            int clickedSens = BrandControls_DrawSegmentedControl(memDC, segRc, sensTabs, 3, currentSens, pt, 0);
            if (clickedSens != -1 && clickedSens != currentSens) {
                MindfulKeyHelper::setRegInt(_T("vBellSensitivity"), clickedSens);
                SystemTrayHelper::updateData();
            }

            y += 80;

            // Biểu đồ cảm xúc
            RECT riverRc = { contentRc.left + 20, y, contentRc.right - 20, y + 150 };
            BrandControls_DrawCard(memDC, riverRc, true);
            if (vMoodWatch) {
                std::vector<MoodSample> samples = MoodStore_FetchRecentSamples(3 * 3600);
                double liveHead = -1.0; 
                RECT chartRc = { riverRc.left + 5, riverRc.top + 5, riverRc.right - 5, riverRc.bottom - 20 };
                EmotionRiver_Draw(memDC, chartRc, samples, true, liveHead);
            } else {
                SetTextColor(memDC, MK_COLORREF(kBrandPaletteMuted));
                SelectObject(memDC, BrandControls_Font(BrandFontBody));
                DrawTextW(memDC, L"Nhật ký cảm xúc đang tắt.", -1, &riverRc, DT_CENTER | DT_VCENTER | DT_SINGLELINE);
            }
        }
        else if (currentTab == 1) { // Chuông
            RECT contentRc = { 160, 0, clientRc.right, clientRc.bottom };
            int y = 20;
            
            auto DrawLabel = [&](const wchar_t* text, RECT rc, BrandFontType font, uint32_t color, UINT format = DT_LEFT | DT_VCENTER | DT_SINGLELINE) {
                SetTextColor(memDC, MK_COLORREF(color));
                HFONT f = BrandControls_Font(font);
                HFONT old = (HFONT)SelectObject(memDC, f);
                DrawTextW(memDC, text, -1, &rc, format);
                SelectObject(memDC, old);
            };

            bool s_bellEnabled = HAS_BEEP(vSwitchKeyStatus);
            int s_bellInterval = (vBellInterval <= 30) ? 0 : ((vBellInterval <= 60) ? 1 : 2);
            int s_bellSoundIndex = MindfulKeyHelper::getRegInt(_T("vBellSoundIndex"), 0);
            int s_bellVolume = MindfulKeyHelper::getRegInt(_T("vVolume"), 50);

            // Card Trạng thái
            RECT card1Rc = { contentRc.left + 20, y, contentRc.right - 20, y + 60 };
            BrandControls_DrawCard(memDC, card1Rc, true);
            RECT lblTrangThaiRc = { card1Rc.left + 15, card1Rc.top + 15, card1Rc.right - 60, card1Rc.bottom - 15 };
            DrawLabel(L"Phát tiếng gõ", lblTrangThaiRc, BrandFontBody, kBrandPaletteCharcoal);
            RECT sw1Rc = { card1Rc.right - 50, card1Rc.top + 18, card1Rc.right - 14, card1Rc.top + 39 };
            if (pt.x != -1 && PtInRect(&sw1Rc, pt)) {
                if (s_bellEnabled) vSwitchKeyStatus &= ~FLAG_BEEP;
                else vSwitchKeyStatus |= FLAG_BEEP;
                APP_SET_DATA(vSwitchKeyStatus, vSwitchKeyStatus);
                SystemTrayHelper::updateData();
                s_bellEnabled = HAS_BEEP(vSwitchKeyStatus);
            }
            BrandControls_DrawPillSwitch(memDC, sw1Rc, s_bellEnabled);
            y += 75;

            // Card Nhịp
            RECT card2Rc = { contentRc.left + 20, y, contentRc.right - 20, y + 90 };
            BrandControls_DrawCard(memDC, card2Rc, true);
            RECT lblNhipRc = { card2Rc.left + 15, card2Rc.top + 10, card2Rc.right - 15, card2Rc.top + 30 };
            DrawLabel(L"TỐC ĐỘ NHỊP", lblNhipRc, BrandFontEyebrow, kBrandPaletteStone);
            
            RECT seg2Rc = { card2Rc.left + 15, card2Rc.top + 35, card2Rc.right - 15, card2Rc.top + 65 };
            const wchar_t* nhipTabs[] = { L"Nhanh", L"Vừa", L"Chậm" };
            int clickedInt = BrandControls_DrawSegmentedControl(memDC, seg2Rc, nhipTabs, 3, s_bellInterval, pt, 0);
            if (clickedInt != -1 && clickedInt != s_bellInterval) {
                int newMins = (clickedInt == 0) ? 30 : ((clickedInt == 1) ? 60 : 120);
                APP_SET_DATA(vBellInterval, newMins);
                extern void Bell_ApplySettings();
                Bell_ApplySettings();
                SystemTrayHelper::updateData();
            }
            y += 105;

            // Card Âm thanh
            RECT card3Rc = { contentRc.left + 20, y, contentRc.right - 20, y + 110 };
            BrandControls_DrawCard(memDC, card3Rc, true);
            RECT lblAmThanhRc = { card3Rc.left + 15, card3Rc.top + 10, card3Rc.right - 15, card3Rc.top + 30 };
            DrawLabel(L"BỘ TIẾNG", lblAmThanhRc, BrandFontEyebrow, kBrandPaletteStone);
            
            RECT iconGrpRc = { card3Rc.left + 15, card3Rc.top + 35, card3Rc.right - 15, card3Rc.top + 75 };
            int clickedSnd = BrandControls_DrawIconGroup(memDC, iconGrpRc, 4, s_bellSoundIndex, pt);
            if (clickedSnd != -1 && clickedSnd != s_bellSoundIndex) {
                MindfulKeyHelper::setRegInt(_T("vBellSoundIndex"), clickedSnd);
                SystemTrayHelper::updateData();
            }
            
            RECT sliderRc = { card3Rc.left + 15, card3Rc.top + 85, card3Rc.right - 15, card3Rc.top + 100 };
            int clickedVol = BrandControls_DrawSlider(memDC, sliderRc, s_bellVolume, pt);
            if (clickedVol != s_bellVolume) {
                MindfulKeyHelper::setRegInt(_T("vVolume"), clickedVol);
                SystemTrayHelper::updateData();
            }
            y += 125;
        }
        else if (currentTab == 3) { // Riêng tư
            RECT contentRc = { 160, 0, clientRc.right, clientRc.bottom };
            int y = 20;

            auto DrawLabel = [&](const wchar_t* text, RECT rc, BrandFontType font, uint32_t color, UINT format = DT_LEFT | DT_VCENTER | DT_SINGLELINE) {
                SetTextColor(memDC, MK_COLORREF(color));
                HFONT f = BrandControls_Font(font);
                HFONT old = (HFONT)SelectObject(memDC, f);
                DrawTextW(memDC, text, -1, &rc, format);
                SelectObject(memDC, old);
            };

            static int s_privacyRetention = 1; 

            // Card Lưu trữ
            RECT card1Rc = { contentRc.left + 20, y, contentRc.right - 20, y + 90 };
            BrandControls_DrawCard(memDC, card1Rc, true);
            RECT lblLuuRc = { card1Rc.left + 15, card1Rc.top + 10, card1Rc.right - 15, card1Rc.top + 30 };
            DrawLabel(L"THỜI GIAN LƯU TRỮ", lblLuuRc, BrandFontEyebrow, kBrandPaletteStone);
            
            RECT segRc = { card1Rc.left + 15, card1Rc.top + 35, card1Rc.right - 15, card1Rc.top + 65 };
            const wchar_t* retTabs[] = { L"1 Tuần", L"1 Tháng", L"3 Tháng" };
            s_privacyRetention = BrandControls_DrawSegmentedControl(memDC, segRc, retTabs, 3, s_privacyRetention, pt, 0);
            y += 105;

            // Card Xuất dữ liệu
            RECT card2Rc = { contentRc.left + 20, y, contentRc.right - 20, y + 60 };
            BrandControls_DrawCard(memDC, card2Rc, true);
            RECT lblXuatRc = { card2Rc.left + 15, card2Rc.top + 15, card2Rc.right - 60, card2Rc.bottom - 15 };
            DrawLabel(L"Xuất dữ liệu cảm xúc (CSV)", lblXuatRc, BrandFontBody, kBrandPaletteCharcoal);
            
            // Vẽ nút giả "Xuất"
            RECT btnRc = { card2Rc.right - 70, card2Rc.top + 15, card2Rc.right - 15, card2Rc.bottom - 15 };
            HBRUSH btnBr = CreateSolidBrush(MK_COLORREF(0x1D7C91));
            FillRect(memDC, &btnRc, btnBr);
            DeleteObject(btnBr);
            DrawLabel(L"Xuất", btnRc, BrandFontBody, kBrandPaletteWhite, DT_CENTER | DT_VCENTER | DT_SINGLELINE);
        }

        
        else if (currentTab == 2) { // Bộ gõ
            RECT contentRc = { 160, 0, clientRc.right, clientRc.bottom };
            int y = 20;

            auto DrawLabel = [&](const wchar_t* text, RECT rc, BrandFontType font, uint32_t color, UINT format = DT_LEFT | DT_VCENTER | DT_SINGLELINE) {
                SetBkMode(memDC, TRANSPARENT);
                SetTextColor(memDC, MK_COLORREF(color));
                HFONT f = BrandControls_Font(font);
                HFONT old = (HFONT)SelectObject(memDC, f);
                DrawTextW(memDC, text, -1, &rc, format);
                SelectObject(memDC, old);
            };

            // Card 1: Chế độ mặc định
            RECT card1Rc = { contentRc.left + 20, y, contentRc.right - 20, y + 120 };
            BrandControls_DrawCard(memDC, card1Rc, true);
            
            auto DrawRowSwitch = [&](RECT cardRc, int i, const wchar_t* label, bool state) {
                int rowY = cardRc.top + 10 + i * 35;
                RECT labelRc = { cardRc.left + 15, rowY, cardRc.right - 60, rowY + 25 };
                DrawLabel(label, labelRc, BrandFontBody, kBrandPaletteCharcoal);
                RECT switchRc = { cardRc.right - 50, rowY + 2, cardRc.right - 14, rowY + 23 };
                BrandControls_DrawPillSwitch(memDC, switchRc, state);
            };

            DrawRowSwitch(card1Rc, 0, L"Tiếng Việt (mặc định)", vLanguage == 1);
            DrawRowSwitch(card1Rc, 1, L"Viết hoa đầu câu", vUpperCaseFirstChar == 1);
            DrawRowSwitch(card1Rc, 2, L"Tự nhớ bảng mã", vRememberCode == 1);
            
            y += 135;

            // Card 2: Tuỳ chọn chính tả
            RECT card2Rc = { contentRc.left + 20, y, contentRc.right - 20, y + 155 };
            BrandControls_DrawCard(memDC, card2Rc, true);
            DrawRowSwitch(card2Rc, 0, L"Kiểm tra chính tả", vCheckSpelling == 1);
            DrawRowSwitch(card2Rc, 1, L"Khôi phục phím sai", vRestoreIfWrongSpelling == 1);
            DrawRowSwitch(card2Rc, 2, L"Sửa lỗi gợi ý trình duyệt", vFixRecommendBrowser == 1);
            DrawRowSwitch(card2Rc, 3, L"Đặt dấu oà, uý", vUseModernOrthography == 1);

            y += 170;

            // Card 3: Phím tắt & Nâng cao
            RECT card3Rc = { contentRc.left + 20, y, contentRc.right - 20, y + 120 };
            BrandControls_DrawCard(memDC, card3Rc, true);
            DrawRowSwitch(card3Rc, 0, L"Sử dụng Macro (Gõ tắt)", vUseMacro == 1);
            DrawRowSwitch(card3Rc, 1, L"Gõ tắt cả khi tiếng Anh", vUseMacroInEnglishMode == 1);
            DrawRowSwitch(card3Rc, 2, L"Cho phép phụ âm z, w, j, f", vAllowConsonantZFWJ == 1);
        }
        else if (currentTab == 4) { // Hệ thống
            RECT contentRc = { 160, 0, clientRc.right, clientRc.bottom };
            int y = 20;

            auto DrawLabel = [&](const wchar_t* text, RECT rc, BrandFontType font, uint32_t color, UINT format = DT_LEFT | DT_VCENTER | DT_SINGLELINE) {
                SetBkMode(memDC, TRANSPARENT);
                SetTextColor(memDC, MK_COLORREF(color));
                HFONT f = BrandControls_Font(font);
                HFONT old = (HFONT)SelectObject(memDC, f);
                DrawTextW(memDC, text, -1, &rc, format);
                SelectObject(memDC, old);
            };

            // Card Hệ thống
            RECT card1Rc = { contentRc.left + 20, y, contentRc.right - 20, y + 155 };
            BrandControls_DrawCard(memDC, card1Rc, true);
            
            auto DrawRowSwitch = [&](RECT cardRc, int i, const wchar_t* label, bool state) {
                int rowY = cardRc.top + 10 + i * 35;
                RECT labelRc = { cardRc.left + 15, rowY, cardRc.right - 60, rowY + 25 };
                DrawLabel(label, labelRc, BrandFontBody, kBrandPaletteCharcoal);
                RECT switchRc = { cardRc.right - 50, rowY + 2, cardRc.right - 14, rowY + 23 };
                BrandControls_DrawPillSwitch(memDC, switchRc, state);
            };

            DrawRowSwitch(card1Rc, 0, L"Khởi động cùng Windows", vRunWithWindows == 1);
            DrawRowSwitch(card1Rc, 1, L"Hiện hộp thoại lúc khởi động", vShowOnStartUp == 1);
            DrawRowSwitch(card1Rc, 2, L"Biểu tượng khay xám (Đen/Trắng)", vUseGrayIcon == 1);
            DrawRowSwitch(card1Rc, 3, L"Chạy quyền Admin", vRunAsAdmin == 1);

            y += 170;

            // Card Nâng cao
            RECT card2Rc = { contentRc.left + 20, y, contentRc.right - 20, y + 120 };
            BrandControls_DrawCard(memDC, card2Rc, true);
            DrawRowSwitch(card2Rc, 0, L"Hỗ trợ ứng dụng Metro (Windows 8+)", vSupportMetroApp == 1);
            DrawRowSwitch(card2Rc, 1, L"Sử dụng Clipboard gửi phím", vSendKeyStepByStep == 0);
            DrawRowSwitch(card2Rc, 2, L"Sửa lỗi nháy chữ Chromium", vFixChromiumBrowser == 1);
        }
        else if (currentTab == 5) { // Giới thiệu
            RECT contentRc = { 160, 0, clientRc.right, clientRc.bottom };
            int y = 50;

            auto DrawLabel = [&](const wchar_t* text, RECT rc, BrandFontType font, uint32_t color, UINT format = DT_LEFT | DT_VCENTER | DT_SINGLELINE) {
                SetBkMode(memDC, TRANSPARENT);
                SetTextColor(memDC, MK_COLORREF(color));
                HFONT f = BrandControls_Font(font);
                HFONT old = (HFONT)SelectObject(memDC, f);
                DrawTextW(memDC, text, -1, &rc, format);
                SelectObject(memDC, old);
            };

            RECT logoRc = { contentRc.left + (contentRc.right - contentRc.left)/2 - 50, y, contentRc.left + (contentRc.right - contentRc.left)/2 + 50, y + 100 };
            // Draw an icon or just title
            DrawLabel(L"MINDFUL KEYBOARD", logoRc, BrandFontTitle, kBrandPaletteCharcoal, DT_CENTER | DT_VCENTER | DT_SINGLELINE);
            y += 60;
            
            RECT verRc = { contentRc.left, y, contentRc.right, y + 30 };
            wchar_t buffer[256];
            wsprintfW(buffer, L"Phiên bản %s", MindfulKeyHelper::getVersionString().c_str());
            DrawLabel(buffer, verRc, BrandFontBody, kBrandPaletteMuted, DT_CENTER | DT_VCENTER | DT_SINGLELINE);
            y += 60;

            // Nút Kiểm tra cập nhật
            RECT btnRc = { contentRc.left + (contentRc.right - contentRc.left)/2 - 80, y, contentRc.left + (contentRc.right - contentRc.left)/2 + 80, y + 40 };
            HBRUSH btnBr = CreateSolidBrush(MK_COLORREF(0x1D7C91));
            FillRect(memDC, &btnRc, btnBr);
            DeleteObject(btnBr);
            DrawLabel(L"Kiểm tra cập nhật", btnRc, BrandFontBody, kBrandPaletteWhite, DT_CENTER | DT_VCENTER | DT_SINGLELINE);
        }

        BitBlt(hdc, 0, 0, clientRc.right, clientRc.bottom, memDC, 0, 0, SRCCOPY);

        SelectObject(memDC, oldBitmap);
        DeleteObject(memBitmap);
        DeleteDC(memDC);

        EndPaint(hDlg, &ps);

        return 0;
    }
    else if (uMsg == WM_LBUTTONUP) {
        int x = GET_X_LPARAM(lParam);
        int y = GET_Y_LPARAM(lParam);
        POINT pt = { x, y };

        RECT navRc = { 10, 20, 150, 260 };
        
        if (currentTab == 2) {
            RECT contentRc = { 160, 0, clientRc.right, clientRc.bottom };
            int y = 20;
            RECT card1Rc = { contentRc.left + 20, y, contentRc.right - 20, y + 120 };
            y += 135;
            RECT card2Rc = { contentRc.left + 20, y, contentRc.right - 20, y + 155 };
            y += 170;
            RECT card3Rc = { contentRc.left + 20, y, contentRc.right - 20, y + 120 };

            auto CheckSwitch = [&](RECT cardRc, int i, POINT p) {
                int rowY = cardRc.top + 10 + i * 35;
                RECT switchRc = { cardRc.right - 50, rowY + 2, cardRc.right - 14, rowY + 23 };
                return PtInRect(&switchRc, p);
            };

            bool changed = false;
            if (CheckSwitch(card1Rc, 0, pt)) { APP_SET_DATA(vLanguage, vLanguage ? 0 : 1); changed = true; }
            if (CheckSwitch(card1Rc, 1, pt)) { APP_SET_DATA(vUpperCaseFirstChar, vUpperCaseFirstChar ? 0 : 1); changed = true; }
            if (CheckSwitch(card1Rc, 2, pt)) { APP_SET_DATA(vRememberCode, vRememberCode ? 0 : 1); changed = true; }

            if (CheckSwitch(card2Rc, 0, pt)) { APP_SET_DATA(vCheckSpelling, vCheckSpelling ? 0 : 1); changed = true; }
            if (CheckSwitch(card2Rc, 1, pt)) { APP_SET_DATA(vRestoreIfWrongSpelling, vRestoreIfWrongSpelling ? 0 : 1); changed = true; }
            if (CheckSwitch(card2Rc, 2, pt)) { APP_SET_DATA(vFixRecommendBrowser, vFixRecommendBrowser ? 0 : 1); changed = true; }
            if (CheckSwitch(card2Rc, 3, pt)) { APP_SET_DATA(vUseModernOrthography, vUseModernOrthography ? 0 : 1); changed = true; }

            if (CheckSwitch(card3Rc, 0, pt)) { APP_SET_DATA(vUseMacro, vUseMacro ? 0 : 1); changed = true; }
            if (CheckSwitch(card3Rc, 1, pt)) { APP_SET_DATA(vUseMacroInEnglishMode, vUseMacroInEnglishMode ? 0 : 1); changed = true; }
            if (CheckSwitch(card3Rc, 2, pt)) { APP_SET_DATA(vAllowConsonantZFWJ, vAllowConsonantZFWJ ? 0 : 1); changed = true; }

            if (changed) {
                SystemTrayHelper::updateData();
                InvalidateRect(hDlg, NULL, FALSE);
            }
        }
        else if (currentTab == 4) {
            RECT contentRc = { 160, 0, clientRc.right, clientRc.bottom };
            int y = 20;
            RECT card1Rc = { contentRc.left + 20, y, contentRc.right - 20, y + 155 };
            y += 170;
            RECT card2Rc = { contentRc.left + 20, y, contentRc.right - 20, y + 120 };

            auto CheckSwitch = [&](RECT cardRc, int i, POINT p) {
                int rowY = cardRc.top + 10 + i * 35;
                RECT switchRc = { cardRc.right - 50, rowY + 2, cardRc.right - 14, rowY + 23 };
                return PtInRect(&switchRc, p);
            };

            bool changed = false;
            if (CheckSwitch(card1Rc, 0, pt)) {
                APP_SET_DATA(vRunWithWindows, vRunWithWindows ? 0 : 1);
                changed = true;
                MindfulKeyHelper::registerRunOnStartup(vRunWithWindows);
            }
            if (CheckSwitch(card1Rc, 1, pt)) { APP_SET_DATA(vShowOnStartUp, vShowOnStartUp ? 0 : 1); changed = true; }
            if (CheckSwitch(card1Rc, 2, pt)) { APP_SET_DATA(vUseGrayIcon, vUseGrayIcon ? 0 : 1); changed = true; }
            if (CheckSwitch(card1Rc, 3, pt)) {
                APP_SET_DATA(vRunAsAdmin, vRunAsAdmin ? 0 : 1);
                changed = true;
                requestRestartAsAdmin();
            }

            if (CheckSwitch(card2Rc, 0, pt)) { APP_SET_DATA(vSupportMetroApp, vSupportMetroApp ? 0 : 1); changed = true; }
            if (CheckSwitch(card2Rc, 1, pt)) { APP_SET_DATA(vSendKeyStepByStep, vSendKeyStepByStep ? 0 : 1); changed = true; }
            if (CheckSwitch(card2Rc, 2, pt)) { APP_SET_DATA(vFixChromiumBrowser, vFixChromiumBrowser ? 0 : 1); changed = true; }

            if (changed) {
                SystemTrayHelper::updateData();
                InvalidateRect(hDlg, NULL, FALSE);
            }
        }
        else if (currentTab == 5) {
            RECT contentRc = { 160, 0, clientRc.right, clientRc.bottom };
            int y = 50 + 60 + 60;
            RECT btnRc = { contentRc.left + (contentRc.right - contentRc.left)/2 - 80, y, contentRc.left + (contentRc.right - contentRc.left)/2 + 80, y + 40 };
            if (PtInRect(&btnRc, pt)) {
                MindfulKeyManager::openReleasesPage();
            }
        }

        if (PtInRect(&navRc, pt)) {
            int clickedTab = (pt.y - navRc.top) / 40;
            if (clickedTab >= 0 && clickedTab < 6 && clickedTab != currentTab) {
                currentTab = clickedTab;
                onTabIndexChanged(); // cập nhật Show/Hide child dialogs
                InvalidateRect(hDlg, NULL, FALSE);
            }
        }
    }

#ifdef _WIN64
    LONG_PTR attr = GetWindowLongPtr(hDlg, GWLP_USERDATA);
#else
    long attr = GetWindowLong(hDlg, GWL_USERDATA);
#endif
    if (attr != 0) {
        return ((MainControlDialog*)attr)->eventProc(hDlg, uMsg, wParam, lParam);
    }
    return FALSE;
}

void MainControlDialog::fillData() {
    SendMessage(comboBoxInputType, CB_SETCURSEL, vInputType, 0);
    SendMessage(comboBoxTableCode, CB_SETCURSEL, vCodeTable, 0);

    SendMessage(checkCtrl, BM_SETCHECK, HAS_CONTROL(vSwitchKeyStatus) ? 1 : 0, 0);
    SendMessage(checkAlt, BM_SETCHECK, HAS_OPTION(vSwitchKeyStatus) ? 1 : 0, 0);
    SendMessage(checkWin, BM_SETCHECK, HAS_COMMAND(vSwitchKeyStatus) ? 1 : 0, 0);
    SendMessage(checkShift, BM_SETCHECK, HAS_SHIFT(vSwitchKeyStatus) ? 1 : 0, 0);
    setSwitchKeyText(textSwitchKey, (vSwitchKeyStatus >> 24) & 0xFF);
    SendMessage(checkBeep, BM_SETCHECK, HAS_BEEP(vSwitchKeyStatus) ? 1 : 0, 0);

    SendMessage(checkVietnamese, BM_SETCHECK, vLanguage, 0);
    SendMessage(checkEnglish, BM_SETCHECK, !vLanguage, 0);

    SendMessage(checkModernOrthorgraphy, BM_SETCHECK, vUseModernOrthography ? 1 : 0, 0);
    SendMessage(checkFixRecommendBrowser, BM_SETCHECK, vFixRecommendBrowser ? 1 : 0, 0);
    SendMessage(checkShowOnStartup, BM_SETCHECK, vShowOnStartUp ? 1 : 0, 0);
    SendMessage(checkRunWithWindows, BM_SETCHECK, vRunWithWindows ? 1 : 0, 0);
    SendMessage(checkSpelling, BM_SETCHECK, vCheckSpelling ? 1 : 0, 0);
    SendMessage(checkMoodWatch, BM_SETCHECK, vMoodWatch ? 1 : 0, 0);
    SendMessage(checkRestoreIfWrongSpelling, BM_SETCHECK, vRestoreIfWrongSpelling ? 1 : 0, 0);
    SendMessage(checkModernIcon, BM_SETCHECK, vUseGrayIcon ? 1 : 0, 0);
    SendMessage(checkAllowZWJF, BM_SETCHECK, vAllowConsonantZFWJ ? 1 : 0, 0);
    SendMessage(checkTempOffSpelling, BM_SETCHECK, vTempOffSpelling ? 1 : 0, 0);
    SendMessage(checkQuickStartConsonant, BM_SETCHECK, vQuickStartConsonant ? 1 : 0, 0);
    SendMessage(checkQuickEndConsonant, BM_SETCHECK, vQuickEndConsonant ? 1 : 0, 0);
    SendMessage(checkRememberTableCode, BM_SETCHECK, vRememberCode ? 1 : 0, 0);
    SendMessage(checkAllowOtherLanguages, BM_SETCHECK, vOtherLanguage ? 1 : 0, 0);
    SendMessage(checkTempOffMindfulKey, BM_SETCHECK, vTempOffMindfulKey ? 1 : 0, 0);

    SendMessage(checkSmartSwitchKey, BM_SETCHECK, vUseSmartSwitchKey ? 1 : 0, 0);
    SendMessage(checkCapsFirstChar, BM_SETCHECK, vUpperCaseFirstChar ? 1 : 0, 0);
    SendMessage(checkQuickTelex, BM_SETCHECK, vQuickTelex ? 1 : 0, 0);
    SendMessage(checkUseMacro, BM_SETCHECK, vUseMacro ? 1 : 0, 0);
    SendMessage(checkUseMacroInEnglish, BM_SETCHECK, vUseMacroInEnglishMode ? 1 : 0, 0);

    SendMessage(checkMacroAutoCaps, BM_SETCHECK, vAutoCapsMacro ? 1 : 0, 0);
    SendMessage(checkSupportMetroApp, BM_SETCHECK, vSupportMetroApp ? 1 : 0, 0);
    SendMessage(checkCreateDesktopShortcut, BM_SETCHECK, vCreateDesktopShortcut ? 1 : 0, 0);
    SendMessage(checkRunAsAdmin, BM_SETCHECK, vRunAsAdmin ? 1 : 0, 0);
    SendMessage(checkCheckNewVersion, BM_SETCHECK, vCheckNewVersion ? 1 : 0, 0);
    SendMessage(checkUseClipboard, BM_SETCHECK, vSendKeyStepByStep ? 0 : 1, 0);
    SendMessage(checkFixChromium, BM_SETCHECK, vFixChromiumBrowser ? 1 : 0, 0);

    EnableWindow(checkRestoreIfWrongSpelling, vCheckSpelling);
    EnableWindow(checkAllowZWJF, vCheckSpelling);
    EnableWindow(checkTempOffSpelling, vCheckSpelling);
    EnableWindow(checkFixChromium, vFixRecommendBrowser);

    //tab info
    wchar_t buffer[256];
    wsprintfW(buffer, _T("Phiên bản %s cho Windows - Ngày cập nhật: %s"), MindfulKeyHelper::getVersionString().c_str(), _T(__DATE__));
    SendDlgItemMessage(hTabPage4, IDC_STATIC_APP_VERSION_INFO, WM_SETTEXT, 0, LPARAM(buffer));
}

void MainControlDialog::setSwitchKey(const unsigned short& code) {
    vSwitchKeyStatus &= 0xFFFFFF00;
    vSwitchKeyStatus |= code;
    vSwitchKeyStatus &= 0x00FFFFFF;
    vSwitchKeyStatus |= ((unsigned int)code << 24);
    APP_SET_DATA(vSwitchKeyStatus, vSwitchKeyStatus);
}

void MainControlDialog::onComboBoxSelected(const HWND& hCombobox, const int& comboboxId) {
    if (hCombobox == comboBoxInputType) {
        APP_SET_DATA(vInputType, (int)SendMessage(hCombobox, CB_GETCURSEL, 0, 0));
    }
    else if (hCombobox == comboBoxTableCode) {
        APP_SET_DATA(vCodeTable, (int)SendMessage(hCombobox, CB_GETCURSEL, 0, 0));
        if (vRememberCode) {
            setAppInputMethodStatus(MindfulKeyHelper::getFrontMostAppExecuteName(), vLanguage | (vCodeTable << 1));
            saveSmartSwitchKeyData();
        }
    }
    SystemTrayHelper::updateData();
}

void MainControlDialog::onCheckboxClicked(const HWND& hWnd) {
    int val = 0;
    if (hWnd == checkCtrl) {
        val = (int)SendMessage(checkCtrl, BM_GETCHECK, 0, 0);
        vSwitchKeyStatus &= (~0x100);
        vSwitchKeyStatus |= val << 8;
        APP_SET_DATA(vSwitchKeyStatus, vSwitchKeyStatus);
    }
    else if (hWnd == checkAlt) {
        val = (int)SendMessage(checkAlt, BM_GETCHECK, 0, 0);
        vSwitchKeyStatus &= (~0x200);
        vSwitchKeyStatus |= val << 9;
        APP_SET_DATA(vSwitchKeyStatus, vSwitchKeyStatus);
    }
    else if (hWnd == checkWin) {
        val = (int)SendMessage(checkWin, BM_GETCHECK, 0, 0);
        vSwitchKeyStatus &= (~0x400);
        vSwitchKeyStatus |= val << 10;
        APP_SET_DATA(vSwitchKeyStatus, vSwitchKeyStatus);
    }
    else if (hWnd == checkShift) {
        val = (int)SendMessage(checkShift, BM_GETCHECK, 0, 0);
        vSwitchKeyStatus &= (~0x800);
        vSwitchKeyStatus |= val << 11;
        APP_SET_DATA(vSwitchKeyStatus, vSwitchKeyStatus);
    }
    else if (hWnd == checkBeep) {
        val = (int)SendMessage(checkBeep, BM_GETCHECK, 0, 0);
        vSwitchKeyStatus &= (~0x8000);
        vSwitchKeyStatus |= val << 15;
        APP_SET_DATA(vSwitchKeyStatus, vSwitchKeyStatus);
    }
    else if (hWnd == checkVietnamese) {
        val = (int)SendMessage(checkVietnamese, BM_GETCHECK, 0, 0);
        APP_SET_DATA(vLanguage, val ? 1 : 0);
        if (vUseSmartSwitchKey) {
            setAppInputMethodStatus(MindfulKeyHelper::getFrontMostAppExecuteName(), vLanguage | (vCodeTable << 1));
            saveSmartSwitchKeyData();
        }
    }
    else if (hWnd == checkEnglish) {
        val = (int)SendMessage(checkVietnamese, BM_GETCHECK, 0, 0);
        APP_SET_DATA(vLanguage, val ? 1 : 0);
        if (vUseSmartSwitchKey) {
            setAppInputMethodStatus(MindfulKeyHelper::getFrontMostAppExecuteName(), vLanguage | (vCodeTable << 1));
            saveSmartSwitchKeyData();
        }
    }
    else if (hWnd == checkModernOrthorgraphy) {
        val = (int)SendMessage(hWnd, BM_GETCHECK, 0, 0);
        APP_SET_DATA(vUseModernOrthography, val ? 1 : 0);
    }
    else if (hWnd == checkFixRecommendBrowser) {
        val = (int)SendMessage(hWnd, BM_GETCHECK, 0, 0);
        APP_SET_DATA(vFixRecommendBrowser, val ? 1 : 0);
        EnableWindow(checkFixChromium, vFixRecommendBrowser);
    }
    else if (hWnd == checkShowOnStartup) {
        val = (int)SendMessage(hWnd, BM_GETCHECK, 0, 0);
        APP_SET_DATA(vShowOnStartUp, val ? 1 : 0);
    }
    else if (hWnd == checkRunWithWindows) {
        val = (int)SendMessage(hWnd, BM_GETCHECK, 0, 0);
        APP_SET_DATA(vRunWithWindows, val ? 1 : 0);
        MindfulKeyHelper::registerRunOnStartup(vRunWithWindows);
    }
    else if (hWnd == checkSpelling) {
        val = (int)SendMessage(hWnd, BM_GETCHECK, 0, 0);
        APP_SET_DATA(vCheckSpelling, val ? 1 : 0);
        vSetCheckSpelling();
        EnableWindow(checkRestoreIfWrongSpelling, vCheckSpelling);
        EnableWindow(checkAllowZWJF, vCheckSpelling);
        EnableWindow(checkTempOffSpelling, vCheckSpelling);
    }
    else if (hWnd == checkMoodWatch) {
        val = (int)SendMessage(hWnd, BM_GETCHECK, 0, 0);
        // Bật qua checkbox cũng phải qua đúng cổng cảnh báo như menu khay — không thì có 1 đường
        // vòng bật được lớp cảm xúc mà không ai nói cho người dùng biết chuyện ô mật khẩu.
        if (val && !vMoodWatch && !MoodWatch_ConfirmEnable(hDlg)) {
            SendMessage(checkMoodWatch, BM_SETCHECK, 0, 0);   // trả checkbox về đúng sự thật
            return;
        }
        APP_SET_DATA(vMoodWatch, val ? 1 : 0);
    }
    else if (hWnd == checkRestoreIfWrongSpelling) {
        val = (int)SendMessage(hWnd, BM_GETCHECK, 0, 0);
        APP_SET_DATA(vRestoreIfWrongSpelling, val ? 1 : 0);
    }
    else if (hWnd == checkUseClipboard) {
        val = (int)SendMessage(hWnd, BM_GETCHECK, 0, 0);
        APP_SET_DATA(vSendKeyStepByStep, val ? 0 : 1);
    }
    else if (hWnd == checkSmartSwitchKey) {
        val = (int)SendMessage(hWnd, BM_GETCHECK, 0, 0);
        APP_SET_DATA(vUseSmartSwitchKey, val ? 1 : 0);
    }
    else if (hWnd == checkCapsFirstChar) {
        val = (int)SendMessage(hWnd, BM_GETCHECK, 0, 0);
        APP_SET_DATA(vUpperCaseFirstChar, val ? 1 : 0);
    }
    else if (hWnd == checkQuickTelex) {
        val = (int)SendMessage(hWnd, BM_GETCHECK, 0, 0);
        APP_SET_DATA(vQuickTelex, val ? 1 : 0);
    }
    else if (hWnd == checkUseMacro) {
        val = (int)SendMessage(hWnd, BM_GETCHECK, 0, 0);
        APP_SET_DATA(vUseMacro, val ? 1 : 0);
    }
    else if (hWnd == checkUseMacroInEnglish) {
        val = (int)SendMessage(hWnd, BM_GETCHECK, 0, 0);
        APP_SET_DATA(vUseMacroInEnglishMode, val ? 1 : 0);
    }
    else if (hWnd == checkModernIcon) {
        val = (int)SendMessage(hWnd, BM_GETCHECK, 0, 0);
        APP_SET_DATA(vUseGrayIcon, val ? 1 : 0);
    }
    else if (hWnd == checkAllowZWJF) {
        val = (int)SendMessage(hWnd, BM_GETCHECK, 0, 0);
        APP_SET_DATA(vAllowConsonantZFWJ, val ? 1 : 0);
    }
    else if (hWnd == checkTempOffSpelling) {
        val = (int)SendMessage(hWnd, BM_GETCHECK, 0, 0);
        APP_SET_DATA(vTempOffSpelling, val ? 1 : 0);
    }
    else if (hWnd == checkQuickStartConsonant) {
        val = (int)SendMessage(hWnd, BM_GETCHECK, 0, 0);
        APP_SET_DATA(vQuickStartConsonant, val ? 1 : 0);
    }
    else if (hWnd == checkQuickEndConsonant) {
        val = (int)SendMessage(hWnd, BM_GETCHECK, 0, 0);
        APP_SET_DATA(vQuickEndConsonant, val ? 1 : 0);
    }
    else if (hWnd == checkSupportMetroApp) {
        val = (int)SendMessage(hWnd, BM_GETCHECK, 0, 0);
        APP_SET_DATA(vSupportMetroApp, val ? 1 : 0);
    }
    else if (hWnd == checkMacroAutoCaps) {
        val = (int)SendMessage(hWnd, BM_GETCHECK, 0, 0);
        APP_SET_DATA(vAutoCapsMacro, val ? 1 : 0);
    }
    else if (hWnd == checkCreateDesktopShortcut) {
        val = (int)SendMessage(hWnd, BM_GETCHECK, 0, 0);
        APP_SET_DATA(vCreateDesktopShortcut, val ? 1 : 0);
        //create desktop shortcut
        if (val)
            MindfulKeyManager::createDesktopShortcut();
    }
    else if (hWnd == checkRunAsAdmin) {
        val = (int)SendMessage(hWnd, BM_GETCHECK, 0, 0);
        APP_SET_DATA(vRunAsAdmin, val ? 1 : 0);
        requestRestartAsAdmin();
    }
    else if (hWnd == checkCheckNewVersion) {
        val = (int)SendMessage(hWnd, BM_GETCHECK, 0, 0);
        APP_SET_DATA(vCheckNewVersion, val ? 1 : 0);
    }
    else if (hWnd == checkRememberTableCode) {
        val = (int)SendMessage(hWnd, BM_GETCHECK, 0, 0);
        APP_SET_DATA(vRememberCode, val ? 1 : 0);
    }
    else if (hWnd == checkAllowOtherLanguages) {
        val = (int)SendMessage(hWnd, BM_GETCHECK, 0, 0);
        APP_SET_DATA(vOtherLanguage, val ? 1 : 0);
    }
    else if (hWnd == checkTempOffMindfulKey) {
        val = (int)SendMessage(hWnd, BM_GETCHECK, 0, 0);
        APP_SET_DATA(vTempOffMindfulKey, val ? 1 : 0);
    }
    else if (hWnd == checkFixChromium) {
        val = (int)SendMessage(hWnd, BM_GETCHECK, 0, 0);
        APP_SET_DATA(vFixChromiumBrowser, val ? 1 : 0);
    }
    SystemTrayHelper::updateData();
}

void MainControlDialog::onCharacter(const HWND& hWnd, const UINT16& keyCode) {
    if (keyCode == 0) return;
    if (hWnd == textSwitchKey) {
        UINT16 code = GET_SWITCH_KEY(vSwitchKeyStatus);
        if (keyCode == VK_DELETE || keyCode == VK_BACK) {
            code = 0xFE;
        }
        else if (keyCodeToCharacter(keyCode) != 0) {
            code = keyCode;
        }
        setSwitchKey(code);
        setSwitchKeyText(hWnd, code);
    }
}

void MainControlDialog::setSwitchKeyText(const HWND& hWnd, const UINT16& keyCode) {
    if (keyCode == KEY_SPACE) {
        SetWindowText(hWnd, _T("Space"));
    }
    else if (keyCode == 0xFE) {
        SetWindowText(hWnd, _T(""));
    }
    else {
        Uint16 key[] = { keyCode, 0 };
        SetWindowText(hWnd, (LPCWSTR)&key);
    }
}

void MainControlDialog::onTabIndexChanged() {
    // 6-Nav: 0: Hôm nay, 1: Chuông, 2: Bộ gõ, 3: Riêng tư, 4: Hệ thống, 5: Giới thiệu
    // Giờ đây tất cả các tab đều được vẽ bằng GDI+ trong WM_PAINT.
    InvalidateRect(hDlg, NULL, FALSE);
}

void MainControlDialog::onUpdateButton() {
	// Xem AboutDialog::onUpdateButton() / MindfulKeyManager::openReleasesPage().
	MindfulKeyManager::openReleasesPage();
}


void MainControlDialog::requestRestartAsAdmin() {
    MindfulKeyHelper::registerRunOnStartup(false);
    if (vRunAsAdmin && !IsUserAnAdmin()) {
        int msgboxID = MessageBox(
            hDlg,
            _T("Bạn cần phải khởi động lại Mindful Keyboard để kích hoạt chế độ Admin!\nBạn có muốn khởi động lại Mindful Keyboard không?"),
            _T("Mindful Keyboard"),
            MB_ICONEXCLAMATION | MB_YESNO
        );
        if (msgboxID == IDYES) {
            PostQuitMessage(0);
            ShellExecute(0, L"runas", MindfulKeyHelper::getFullPath().c_str(), 0, 0, SW_SHOWNORMAL);
        }
    }
    else {
        MindfulKeyHelper::registerRunOnStartup(vRunWithWindows);
    }
}
