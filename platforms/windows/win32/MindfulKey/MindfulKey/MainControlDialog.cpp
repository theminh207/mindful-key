/*----------------------------------------------------------
MindfulKey - The Cross platform Open source Vietnamese Keyboard application.

Copyright (C) 2019 Mai Vu Tuyen
Contact: maivutuyen.91@gmail.com
Github: https://github.com/tuyenvm/OpenKey
Fanpage: https://www.facebook.com/OpenKeyVN

This file is belong to the MindfulKey project, Win32 version
which is released under GPL license.
You can fork, modify, improve this program. If you
redistribute your new version, it MUST be open source.
-----------------------------------------------------------*/
#include "MainControlDialog.h"
#include "AppDelegate.h"
#include "UpdateChecker.h"
#include <windowsx.h>
#include <cstdint>   // [MINDFUL] uint32_t (tham số màu của lambda DrawLabel) — MSVC lấy được qua include gián tiếp nhưng khai rõ cho chắc + portable

#define FLAG_BEEP 0x8000
#include "MoodWatch.h"
#include "Bell.h"
#include "BrandControls.h"
#include "BrandPalette.h"
#include "ReflectionScreen.h"
#include "MoodStore.h"
#include "NotesHistory.h"   // [MINDFUL] H4 — pane "Nhật Ký Tâm" mở cửa sổ đầy đủ + đọc danh sách note
#include <Shlobj.h>
#include <Uxtheme.h>
#include <commdlg.h>   // [MINDFUL] B6 — GetOpenFileName/OPENFILENAME (chọn .wav riêng). stdafx bật
                       // WIN32_LEAN_AND_MEAN nên windows.h KHÔNG tự kéo commdlg — phải khai rõ.
#pragma comment(lib, "comdlg32.lib")   // B8 — chuyển từ Bell.cpp sang (chọn .wav nay ở tab Chuông đây)

// [MINDFUL] GĐ6 — ImageList_* (icon tab) là HÀM THẬT trong comctl32, phải link. File này lẫn
// stdafx.h đã include <Commctrl.h> từ đời MindfulKey nhưng chưa bao giờ cần lib: TabCtrl_*/ListView_*
// mà code cũ dùng đều là MACRO gói SendMessage, không đụng thư viện. ImageList_* thì khác.
#pragma comment(lib, "comctl32.lib")

#pragma comment(lib, "UxTheme.lib")

static Uint16 _lastKeyCode;

// [MINDFUL] G2 (2026-07-24) — trạng thái cho 2 control mới ở cửa Cài đặt, đồng bộ với popover.
static int g_settingsBellDraft  = 0;   // G2a — số nháp stepper nhịp tùy chỉnh (0=chưa init)
static int g_settingsRiverView  = 0;   // G2b — 0=Ngay bây giờ (3h sống), 1=Hôm nay (24h)

// [MINDFUL] G1 — chuỗi phím tắt bật/tắt tiếng Việt (kiểu chữ Windows). TWIN ở TrayPopover.cpp —
// đổi ở đây thì đổi luôn bản kia (helper hiển thị nhỏ, cố ý không kéo thêm phụ thuộc chung).
static std::wstring SwitchHotkeyText() {
    extern int vSwitchKeyStatus;
    int hk = vSwitchKeyStatus;
    std::wstring s;
    if (hk & 0x100) s += L"Ctrl + ";
    if (hk & 0x200) s += L"Alt + ";
    if (hk & 0x400) s += L"Win + ";
    if (hk & 0x800) s += L"Shift + ";
    int ch = (hk >> 24) & 0xFF;
    if (ch == 32) s += L"Space";
    else if (ch > 0) s += (wchar_t)((ch >= 'a' && ch <= 'z') ? ch - 32 : ch);
    if (s.size() >= 3 && s.compare(s.size() - 3, 3, L" + ") == 0) s.erase(s.size() - 3);  // chỉ modifier
    return s;
}

MainControlDialog::MainControlDialog(const HINSTANCE& hInstance, const int& resourceId)
    : BaseDialog(hInstance, resourceId) {
}

MainControlDialog::~MainControlDialog() {
}

void MainControlDialog::initDialog() {
    HINSTANCE hIns = GetModuleHandleW(NULL);
    // [MINDFUL] CP5 — chạy dọn dẹp tự động (giữ N ngày gần nhất) mỗi lần mở cửa Cài đặt. Idempotent +
    // rẻ (chỉ ghi lại nếu thật sự có dòng quá hạn). Mirror macOS gọi lúc pane Riêng tư init.
    MoodStore_RunAutoPurgeIfNeeded();
    // [MINDFUL] G2 — re-sync nháp/chế-độ-xem mỗi lần mở (mirror popover reset lúc show): tránh giá
    // trị nháp cũ còn lại từ lần mở trước hiện sai so với vBellInterval thật.
    g_settingsBellDraft = 0;
    g_settingsRiverView = 0;
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
    // [MINDFUL] blank-window fix: the entire main window (left 6-nav + tab content + clicks) is
    // rendered by tabPageEventProc, which is NEVER installed as a window/dialog procedure. This
    // dialog's real proc is BaseDialog::DialogProc -> eventProc, which has no WM_PAINT handler, so
    // the window painted only the empty IDD_DIALOG_MAIN template = blank gray. Delegate paint and
    // mouse messages to tabPageEventProc; GWLP_USERDATA already holds `this` (set by DialogProc),
    // which is exactly what tabPageEventProc reads back.
    if (uMsg == WM_PAINT || uMsg == WM_ERASEBKGND || uMsg == WM_LBUTTONUP) {
        return tabPageEventProc(hDlg, uMsg, wParam, lParam);
    }
    switch (uMsg) {
    case WM_INITDIALOG:
        this->hDlg = hDlg;
        initDialog();
        return TRUE;
    // [MINDFUL] C1 — cửa sổ nay kéo giãn được (WS_THICKFRAME). Nội dung vẽ tay theo GetClientRect nên
    // resize = vẽ lại toàn client (nền tô kín ở tabPageEventProc WM_PAINT nên không cụt/không rác).
    case WM_SIZE:
        InvalidateRect(hDlg, NULL, FALSE);
        return TRUE;
    // [MINDFUL] C1b — chặn thu nhỏ dưới cỡ vừa đủ nội dung (tab Chuông cao nhất). Đây là cách gọn thay
    // cho viewport cuộn: không cho co dưới ngưỡng thì nội dung không bao giờ bị cắt. (Số px 96-DPI;
    // C2 sẽ nhân theo DPI.) Ghi FRICTION-LOG: chọn min-clamp thay vì (a) cuộn / (b) co tỉ lệ.
    case WM_GETMINMAXINFO: {
        MINMAXINFO* mmi = (MINMAXINFO*)lParam;
        // [MINDFUL] CP3 nới hàng giờ yên lặng (rộng tới ~529px client) + CP4 thêm thẻ Công cụ vào tab
        // Bộ gõ (cao tới ~545px) → nâng ngưỡng để nội dung rộng/cao nhất không bị cắt lúc thu nhỏ.
        mmi->ptMinTrackSize.x = 560;
        mmi->ptMinTrackSize.y = 590;
        return TRUE;
    }
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
                ShellExecute(NULL, _T("open"), _T("https://key.bketech.xyz"), NULL, NULL, SW_SHOWNORMAL);
            else if (link->hdr.idFrom == IDC_SYSLINK_FANPAGE)
                ShellExecute(NULL, _T("open"), _T("https://www.facebook.com/OpenKeyVN"), NULL, NULL, SW_SHOWNORMAL);
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
    MainControlDialog* pThis = nullptr;
    if (uMsg == WM_INITDIALOG) {
#ifdef _WIN64
        SetWindowLongPtr(hDlg, GWLP_USERDATA, lParam);
#else
        SetWindowLong(hDlg, GWL_USERDATA, lParam);
#endif
        pThis = (MainControlDialog*)lParam;
        return TRUE;
    } else {
#ifdef _WIN64
        pThis = (MainControlDialog*)GetWindowLongPtr(hDlg, GWLP_USERDATA);
#else
        pThis = (MainControlDialog*)GetWindowLong(hDlg, GWL_USERDATA);
#endif
    }
    if (!pThis) return FALSE;

    int& currentTab = pThis->currentTab;

    if (uMsg == WM_ERASEBKGND) {
        return TRUE;
    }
    if ((uMsg == WM_CTLCOLORSTATIC || uMsg == WM_CTLCOLORBTN) && IsThemeActive()) {
        SetBkMode((HDC)wParam, TRANSPARENT);
        return (LRESULT)GetStockObject(COLOR_WINDOW + 1);
    }
    if (uMsg == WM_PAINT) {  // [MINDFUL] removed `&& IsThemeActive()`: Classic/high-contrast/theme-off (some RDP) sessions were skipping ALL painting -> blank window even when wired
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
        // [MINDFUL] H4 (2026-07-24) — nav 7 mục (thêm "Nhật Ký Tâm"). Thứ tự HIỂN THỊ khác chỉ số
        // pane: navTabIndex map vị-trí-nav -> currentTab, để "Nhật Ký Tâm" (pane MỚI = 6) đứng thứ 2
        // mà KHÔNG phải đánh số lại 5 pane cũ (đánh số lại = dễ lệch click ở owner-draw).
        RECT navRc = { 10, 20, 150, 300 };
        const wchar_t* tabs[] = { L"Hôm nay", L"Nhật Ký Tâm", L"Chuông", L"Bộ gõ", L"Riêng tư", L"Hệ thống", L"Giới thiệu" };
        static const int navTabIndex[] = { 0, 6, 1, 2, 3, 4, 5 };
        POINT pt = { -1, -1 };
        for (int i = 0; i < 7; i++) {
            RECT itemRc = { navRc.left, navRc.top + i * 40, navRc.right, navRc.top + i * 40 + 35 };
            bool sel = (navTabIndex[i] == currentTab);
            if (sel) {
                HBRUSH br = CreateSolidBrush(MK_COLORREF(0xDEF0F2)); // tealLight
                FillRect(memDC, &itemRc, br);
                DeleteObject(br);
            }
            SetBkMode(memDC, TRANSPARENT);
            SetTextColor(memDC, MK_COLORREF(sel ? 0x1D7C91 : 0x4B5563)); // teal vs charcoal
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

            // [MINDFUL] A3 — click thật xử ở WM_LBUTTONUP (currentTab==0), KHÔNG còn ở đây (pt=-1,-1
            // lúc WM_PAINT nên khối if cũ không bao giờ khớp — tab Hôm nay tê liệt cùng nguyên nhân).
            RECT segRc = { cardRc.left + 100, cardRc.top + 15, cardRc.right - 15, cardRc.top + 45 };
            const wchar_t* sensTabs[] = { L"Ít nhạy", L"Vừa", L"Nhạy" };
            // [MINDFUL] A8 — vBellSensitivity lưu theo thang NudgeCoordinator.h (1=ít·2=vừa·3=nhạy,
            // chưa lưu=vừa), KHÁC chỉ số 0-based mà segmented control cần để vẽ selectedIndex.
            int storedSens = MindfulKeyHelper::getRegInt(_T("vBellSensitivity"), 2);
            int currentSens = (storedSens >= 1 && storedSens <= 3) ? (storedSens - 1) : 1;
            BrandControls_DrawSegmentedControl(memDC, segRc, sensTabs, 3, currentSens, pt, 0);

            y += 80;

            // [MINDFUL] G2b (2026-07-24) — toggle "Ngay bây giờ / Hôm nay" (mirror popover P5). Click
            // thật xử ở WM_LBUTTONUP (RECT dựng lại y hệt). g_settingsRiverView: 0=3h sống, 1=24h.
            RECT viewSegRc = { contentRc.left + 20, y, contentRc.right - 20, y + 30 };
            const wchar_t* viewTabs[] = { L"Ngay bây giờ", L"Hôm nay" };
            BrandControls_DrawSegmentedControl(memDC, viewSegRc, viewTabs, 2, g_settingsRiverView, pt, 0);
            y += 38;

            // Biểu đồ cảm xúc
            RECT riverRc = { contentRc.left + 20, y, contentRc.right - 20, y + 150 };
            BrandControls_DrawCard(memDC, riverRc, true);
            if (vMoodWatch) {
                RECT chartRc = { riverRc.left + 5, riverRc.top + 5, riverRc.right - 5, riverRc.bottom - 20 };
                if (g_settingsRiverView == 1) {
                    // Hôm nay (24h): mẫu cả ngày, trục Sáng/Trưa/Chiều/Tối (recentMode=false).
                    std::vector<MoodSample> samples = MoodStore_FetchTodaySamples();
                    EmotionRiver_Draw(memDC, chartRc, samples, false, -1.0);
                } else {
                    // [MINDFUL] B3 — Ngay bây giờ (3h): vệt dày + đầu sóng sống thật.
                    std::vector<MoodSample> samples = MoodWatch_FetchLiveTrace(3 * 3600);
                    double liveHead = MoodWatch_LiveAmplitude();
                    EmotionRiver_Draw(memDC, chartRc, samples, true, liveHead);
                }
            } else {
                // [MINDFUL] A7 — nút "Bật nhật ký" tại chỗ. Click thật xử ở WM_LBUTTONUP
                // (currentTab==0, đã có sẵn từ A3) — nhánh vẽ dưới đây CHỈ vẽ.
                RECT msgRc = { riverRc.left + 10, riverRc.top + 15, riverRc.right - 10, riverRc.top + 65 };
                SetTextColor(memDC, MK_COLORREF(kBrandPaletteMuted));
                SelectObject(memDC, BrandControls_Font(BrandFontBody));
                DrawTextW(memDC, L"Nhật ký cảm xúc đang tắt.", -1, &msgRc, DT_CENTER | DT_VCENTER | DT_SINGLELINE);

                RECT btnEnableRc = { riverRc.left + (riverRc.right - riverRc.left) / 2 - 70, riverRc.top + 95,
                                      riverRc.left + (riverRc.right - riverRc.left) / 2 + 70, riverRc.top + 123 };
                HBRUSH btnBr = CreateSolidBrush(MK_COLORREF(kBrandPaletteTeal));
                FillRect(memDC, &btnEnableRc, btnBr);
                DeleteObject(btnBr);
                SetTextColor(memDC, MK_COLORREF(kBrandPaletteCardWhite));
                SelectObject(memDC, BrandControls_Font(BrandFontBody));
                DrawTextW(memDC, L"Bật nhật ký", -1, &btnEnableRc, DT_CENTER | DT_VCENTER | DT_SINGLELINE);
            }

            // [MINDFUL] G2b — link "Soi lại hôm nay →" (mirror popover P6). Chỉ khi đang canh (có gì
            // để soi). Cam = lớp CTA, brand ghi rõ KHÔNG mã hoá cảm xúc. Click thật ở WM_LBUTTONUP.
            if (vMoodWatch) {
                y += 160;
                RECT reflectRc = { contentRc.left + 20, y, contentRc.right - 20, y + 24 };
                SetTextColor(memDC, MK_COLORREF(kBrandPaletteOrange));
                oldFont = (HFONT)SelectObject(memDC, BrandControls_Font(BrandFontBody));
                DrawTextW(memDC, L"Soi lại hôm nay →", -1, &reflectRc, DT_LEFT | DT_VCENTER | DT_SINGLELINE);
                SelectObject(memDC, oldFont);
            }
        }
        else if (currentTab == 1) { // Chuông
            RECT contentRc = { 160, 0, clientRc.right, clientRc.bottom };
            int y = 20;
            
            auto DrawLabel = [&](const wchar_t* text, RECT rc, BrandFontRole font, uint32_t color, UINT format = DT_LEFT | DT_VCENTER | DT_SINGLELINE) {
                SetTextColor(memDC, MK_COLORREF(color));
                HFONT f = BrandControls_Font(font);
                HFONT old = (HFONT)SelectObject(memDC, f);
                DrawTextW(memDC, text, -1, &rc, format);
                SelectObject(memDC, old);
            };

            // [MINDFUL] A2 — đọc ĐÚNG biến chuông thật (vBell), không phải FLAG_BEEP (tiếng bíp đổi
            // Việt/Anh của OpenKey). Tiếng/âm lượng đọc đúng khoá Bell.cpp dùng (vBellSoundName chuỗi
            // id, vBellVolume 0..100) — trước đây ghi vào 2 khoá Bell.cpp không hề đọc (khoá chết).
            bool s_bellEnabled = (vBell != 0);
            // [MINDFUL] G2a — SO SÁNH BẰNG (không <=): nhịp tùy chỉnh (vd 45') phải đứng ở "Tùy
            // chỉnh", không bị xếp nhầm vào 60 (mirror popover P1).
            int s_bellInterval = (vBellInterval == 30) ? 0 : ((vBellInterval == 60) ? 1 : 2);
            std::wstring s_bellSoundName = MindfulKeyHelper::getRegString(_T("vBellSoundName"), _T("temple"));
            int s_bellSoundIndex = (s_bellSoundName == L"chime") ? 1 : (s_bellSoundName == L"wind") ? 2 : (s_bellSoundName == L"custom") ? 3 : 0;
            int s_bellVolume = MindfulKeyHelper::getRegInt(_T("vBellVolume"), 60);

            // Card Trạng thái — [MINDFUL] F3 (2026-07-23) card cao hơn (60→74) để nhét dòng "Dự
            // kiến reo lúc HH:MM (còn N phút)" ngay dưới nhãn, mirror popover B5 + card macOS. Ẩn
            // dòng khi chuông tắt/đang hoãn (Bell_MinutesUntilNextRing trả -1) — không vẽ chỗ trống.
            RECT card1Rc = { contentRc.left + 20, y, contentRc.right - 20, y + 74 };
            BrandControls_DrawCard(memDC, card1Rc, true);
            RECT lblTrangThaiRc = { card1Rc.left + 15, card1Rc.top + 13, card1Rc.right - 60, card1Rc.top + 35 };
            DrawLabel(L"Bật chuông tỉnh thức", lblTrangThaiRc, BrandFontBody, kBrandPaletteCharcoal);
            int nextMin = Bell_MinutesUntilNextRing();
            if (nextMin >= 0) {
                SYSTEMTIME st;
                GetLocalTime(&st);
                int total = st.wHour * 60 + st.wMinute + nextMin;
                int hh = (total / 60) % 24, mm = total % 60;
                wchar_t nextLine[96];
                wsprintfW(nextLine, L"Dự kiến reo lúc %02d:%02d (còn %d phút)", hh, mm, nextMin);
                RECT nextRc = { card1Rc.left + 15, card1Rc.top + 38, card1Rc.right - 60, card1Rc.top + 58 };
                DrawLabel(nextLine, nextRc, BrandFontBody, kBrandPaletteMuted, DT_LEFT | DT_VCENTER | DT_SINGLELINE);
            }
            // [MINDFUL] A2 — click thật xử ở WM_LBUTTONUP (currentTab==1), KHÔNG còn ở đây (pt=-1,-1
            // lúc WM_PAINT nên khối if cũ không bao giờ khớp — đúng nguyên nhân tab Chuông tê liệt).
            RECT sw1Rc = { card1Rc.right - 50, card1Rc.top + 26, card1Rc.right - 14, card1Rc.top + 47 };
            BrandControls_DrawPillSwitch(memDC, sw1Rc, s_bellEnabled);
            y += 89;

            // Card Nhịp — [MINDFUL] G2a (2026-07-24): ĐỒNG BỘ với popover — "30 phút / 60 phút / Tùy
            // chỉnh" + stepper tùy chỉnh, thay "Nhanh/Vừa/Chậm". Card cao 90→110 để chứa stepper.
            RECT card2Rc = { contentRc.left + 20, y, contentRc.right - 20, y + 110 };
            BrandControls_DrawCard(memDC, card2Rc, true);
            RECT lblNhipRc = { card2Rc.left + 15, card2Rc.top + 10, card2Rc.right - 15, card2Rc.top + 30 };
            DrawLabel(L"NHỊP", lblNhipRc, BrandFontEyebrow, kBrandPaletteStone);

            RECT seg2Rc = { card2Rc.left + 15, card2Rc.top + 35, card2Rc.right - 15, card2Rc.top + 65 };
            const wchar_t* nhipTabs[] = { L"30 phút", L"60 phút", L"Tùy chỉnh" };
            BrandControls_DrawSegmentedControl(memDC, seg2Rc, nhipTabs, 3, s_bellInterval, pt, 0);

            // Stepper "− NN phút +" + "Đặt" — chỉ khi đang "Tùy chỉnh" (mirror popover P1). Bước 5,
            // kẹp 15..240; "Đặt" mới chốt. Bấm thật xử ở WM_LBUTTONUP (RECT dựng lại y hệt dưới).
            if (s_bellInterval == 2) {
                if (g_settingsBellDraft <= 0) g_settingsBellDraft = vBellInterval;
                RECT stepRc = { card2Rc.left + 15, card2Rc.top + 72, card2Rc.left + 150, card2Rc.top + 98 };
                HBRUSH stepBg = CreateSolidBrush(MK_COLORREF(kBrandPaletteTealLight));
                FillRect(memDC, &stepRc, stepBg);
                DeleteObject(stepBg);
                RECT sDecRc = { stepRc.left, stepRc.top, stepRc.left + 28, stepRc.bottom };
                RECT sValRc = { stepRc.left + 28, stepRc.top, stepRc.right - 28, stepRc.bottom };
                RECT sIncRc = { stepRc.right - 28, stepRc.top, stepRc.right, stepRc.bottom };
                DrawLabel(L"-", sDecRc, BrandFontButton, kBrandPaletteTeal, DT_CENTER | DT_VCENTER | DT_SINGLELINE);
                DrawLabel(L"+", sIncRc, BrandFontButton, kBrandPaletteTeal, DT_CENTER | DT_VCENTER | DT_SINGLELINE);
                wchar_t sBuf[32];
                wsprintfW(sBuf, L"%d phút", g_settingsBellDraft);
                DrawLabel(sBuf, sValRc, BrandFontBody, kBrandPaletteCharcoal, DT_CENTER | DT_VCENTER | DT_SINGLELINE);
                RECT sSetRc = { stepRc.right + 10, stepRc.top, stepRc.right + 74, stepRc.bottom };
                HBRUSH sSetBg = CreateSolidBrush(MK_COLORREF(kBrandPaletteTeal));
                FillRect(memDC, &sSetRc, sSetBg);
                DeleteObject(sSetBg);
                DrawLabel(L"Đặt", sSetRc, BrandFontButton, kBrandPaletteCardWhite, DT_CENTER | DT_VCENTER | DT_SINGLELINE);
            }
            y += 125;

            // Card Âm thanh
            RECT card3Rc = { contentRc.left + 20, y, contentRc.right - 20, y + 110 };
            BrandControls_DrawCard(memDC, card3Rc, true);
            RECT lblAmThanhRc = { card3Rc.left + 15, card3Rc.top + 10, card3Rc.left + 120, card3Rc.top + 30 };
            DrawLabel(L"BỘ TIẾNG", lblAmThanhRc, BrandFontEyebrow, kBrandPaletteStone);

            // [MINDFUL] B4 — nút "Nghe thử" (Bell_PreviewSound bỏ mọi cổng, phát ngay). Click xử ở
            // WM_LBUTTONUP. RECT khớp nhánh WM_LBUTTONUP.
            RECT btnPreviewRc = { card3Rc.right - 90, card3Rc.top + 8, card3Rc.right - 15, card3Rc.top + 30 };
            HBRUSH brPreview = CreateSolidBrush(MK_COLORREF(kBrandPaletteTeal));
            FillRect(memDC, &btnPreviewRc, brPreview);
            DeleteObject(brPreview);
            DrawLabel(L"Nghe thử", btnPreviewRc, BrandFontButton, kBrandPaletteCardWhite, DT_CENTER | DT_VCENTER | DT_SINGLELINE);

            RECT iconGrpRc = { card3Rc.left + 15, card3Rc.top + 35, card3Rc.right - 15, card3Rc.top + 75 };
            static const int kBellIconIds[] = { IDI_ICON_BELL_TEMPLE, IDI_ICON_BELL_CHIME, IDI_ICON_BELL_WIND, IDI_ICON_BELL_CUSTOM };
            BrandControls_DrawIconGroup(memDC, iconGrpRc, 4, s_bellSoundIndex, pt, kBellIconIds);

            // [MINDFUL] A2 — s_bellVolume ở thang 0..100 (khớp vBellVolume), DrawSlider nhận thumbPos
            // 0..1 để vẽ đúng vị trí; click thật xử ở WM_LBUTTONUP.
            RECT sliderRc = { card3Rc.left + 15, card3Rc.top + 85, card3Rc.right - 15, card3Rc.top + 100 };
            BrandControls_DrawSlider(memDC, sliderRc, (float)s_bellVolume / 100.0f, pt);
            y += 125;

            // [MINDFUL] B6 — Card Giờ yên lặng + tiếng .wav riêng + tạm hoãn (port từ hộp chuông cũ
            // IDD_DIALOG_BELL để chuẩn bị bỏ nó ở B8). Bell.cpp CÓ SẴN logic (isInBellRange /
            // Bell_InstallCustomSound / Bell_Snooze) — đây chỉ là đường vào UI owner-draw. vBellFrom/
            // vBellTo là GLOBAL (Bell.h), đọc thẳng; APP_SET_DATA ghi đúng khóa Bell.cpp đọc lại.
            // [MINDFUL] F2 (2026-07-23) — card cao hơn (105→116) + giãn khoảng cách tiêu đề→hàng
            // giờ (ry +36→+44) + nới/tách 2 stepper cho rõ, vì chủ dự án phản hồi khung giờ chật,
            // đọc dính vào tiêu đề "GIỜ YÊN LẶNG".
            RECT card4Rc = { contentRc.left + 20, y, contentRc.right - 20, y + 116 };
            BrandControls_DrawCard(memDC, card4Rc, true);
            RECT lblYenLangRc = { card4Rc.left + 15, card4Rc.top + 10, card4Rc.right - 15, card4Rc.top + 30 };
            DrawLabel(L"GIỜ YÊN LẶNG", lblYenLangRc, BrandFontEyebrow, kBrandPaletteStone);

            int ry = card4Rc.top + 44;
            RECT lblFromRc = { card4Rc.left + 15, ry, card4Rc.left + 100, ry + 28 };
            DrawLabel(L"Không reo từ", lblFromRc, BrandFontBody, kBrandPaletteCharcoal);
            // [MINDFUL] CP3/F2 — box 100px để "NN giờ" thoáng; 2 stepper cách nhau qua chữ "đến".
            RECT fromBox = { card4Rc.left + 102, ry, card4Rc.left + 202, ry + 28 };
            RECT lblDenRc = { card4Rc.left + 208, ry, card4Rc.left + 238, ry + 28 };
            DrawLabel(L"đến", lblDenRc, BrandFontBody, kBrandPaletteCharcoal, DT_CENTER | DT_VCENTER | DT_SINGLELINE);
            RECT toBox = { card4Rc.left + 242, ry, card4Rc.left + 342, ry + 28 };
            // Stepper "− HH giờ +" — không dùng ô nhập native (tab này vẽ tay hết), bấm −/+ đổi giờ.
            auto DrawHourStepper = [&](RECT box, int hourVal) {
                HBRUSH bg = CreateSolidBrush(MK_COLORREF(kBrandPaletteTealLight));
                FillRect(memDC, &box, bg);
                DeleteObject(bg);
                RECT decRc = { box.left, box.top, box.left + 24, box.bottom };
                RECT valRc = { box.left + 24, box.top, box.right - 24, box.bottom };
                RECT incRc = { box.right - 24, box.top, box.right, box.bottom };
                DrawLabel(L"-", decRc, BrandFontButton, kBrandPaletteTeal, DT_CENTER | DT_VCENTER | DT_SINGLELINE);
                DrawLabel(L"+", incRc, BrandFontButton, kBrandPaletteTeal, DT_CENTER | DT_VCENTER | DT_SINGLELINE);
                wchar_t hh[16];
                wsprintfW(hh, L"%d giờ", hourVal);
                DrawLabel(hh, valRc, BrandFontBody, kBrandPaletteCharcoal, DT_CENTER | DT_VCENTER | DT_SINGLELINE);
            };
            DrawHourStepper(fromBox, vBellFrom);
            DrawHourStepper(toBox, vBellTo);

            // [MINDFUL] F1 (2026-07-23) — GỠ nút "Chọn tiếng .wav của bạn…" ở đây: icon nốt nhạc
            // trong "BỘ TIẾNG" (CP2) đã mở đúng hộp chọn .wav rồi, nút này là lối thứ hai thừa.
            // Giữ "Tạm hoãn 1 giờ" (không trùng chức năng nào khác trên tab).
            int by = card4Rc.top + 82;
            RECT btnSnoozeRc = { card4Rc.right - 130, by, card4Rc.right - 15, by + 26 };
            HBRUSH brSnooze = CreateSolidBrush(MK_COLORREF(kBrandPaletteTealLight));
            FillRect(memDC, &btnSnoozeRc, brSnooze);
            DeleteObject(brSnooze);
            DrawLabel(L"Tạm hoãn 1 giờ", btnSnoozeRc, BrandFontButton, kBrandPaletteTeal, DT_CENTER | DT_VCENTER | DT_SINGLELINE);
            y += 131;
        }
        else if (currentTab == 3) { // Riêng tư
            // [MINDFUL] CP5 — 4 nhóm THẬT (backend đã thêm: consent/DeleteAll có sẵn + ExportCSV +
            // purge mới). A4 (2026-07-23) từng gỡ 2 nút giả vì thiếu backend — nay đã đủ, không còn giả.
            RECT contentRc = { 160, 0, clientRc.right, clientRc.bottom };
            int y = 20;
            auto DrawLabel = [&](const wchar_t* text, RECT rc, BrandFontRole font, uint32_t color, UINT format = DT_LEFT | DT_VCENTER | DT_SINGLELINE) {
                SetBkMode(memDC, TRANSPARENT);
                SetTextColor(memDC, MK_COLORREF(color));
                HFONT f = BrandControls_Font(font);
                HFONT old = (HFONT)SelectObject(memDC, f);
                DrawTextW(memDC, text, -1, &rc, format);
                SelectObject(memDC, old);
            };

            // Card 1 — Nhật ký cảm xúc (consent)
            RECT p1Rc = { contentRc.left + 20, y, contentRc.right - 20, y + 78 };
            BrandControls_DrawCard(memDC, p1Rc, true);
            RECT p1Eb = { p1Rc.left + 15, p1Rc.top + 10, p1Rc.left + 220, p1Rc.top + 28 };
            DrawLabel(L"NHẬT KÝ CẢM XÚC", p1Eb, BrandFontEyebrow, kBrandPaletteStone);
            RECT p1Lbl = { p1Rc.left + 15, p1Rc.top + 30, p1Rc.right - 60, p1Rc.top + 52 };
            DrawLabel(L"Lưu điểm gợn cục bộ", p1Lbl, BrandFontBody, kBrandPaletteCharcoal);
            RECT p1Sw = { p1Rc.right - 50, p1Rc.top + 32, p1Rc.right - 14, p1Rc.top + 53 };
            // [MINDFUL] CP5 review — pill phản ánh vMoodWatch (watcher đang chạy = thứ THẬT SỰ ghi
            // nhật ký), KHÔNG chỉ MoodStore consent. Trước đây đọc consent riêng → bật consent mà
            // watcher tắt = công tắc chết câm (không ghi gì). Nay công tắc này bật/tắt CẢ hai (đồng bộ).
            BrandControls_DrawPillSwitch(memDC, p1Sw, vMoodWatch != 0);
            RECT p1Note = { p1Rc.left + 15, p1Rc.top + 54, p1Rc.right - 15, p1Rc.top + 74 };
            DrawLabel(L"Tắt sẽ xóa sạch mọi dữ liệu đã lưu.", p1Note, BrandFontBody, kBrandPaletteMuted);
            y += 93;

            // Card 2 — Cầm trịch dữ liệu (Xuất CSV)
            RECT p2Rc = { contentRc.left + 20, y, contentRc.right - 20, y + 72 };
            BrandControls_DrawCard(memDC, p2Rc, true);
            RECT p2Eb = { p2Rc.left + 15, p2Rc.top + 10, p2Rc.left + 220, p2Rc.top + 28 };
            DrawLabel(L"CẦM TRỊCH DỮ LIỆU", p2Eb, BrandFontEyebrow, kBrandPaletteStone);
            RECT btnCsvRc = { p2Rc.left + 15, p2Rc.top + 34, p2Rc.left + 155, p2Rc.top + 60 };
            HBRUSH brCsv = CreateSolidBrush(MK_COLORREF(kBrandPaletteTealLight));
            FillRect(memDC, &btnCsvRc, brCsv);
            DeleteObject(brCsv);
            DrawLabel(L"Xuất CSV…", btnCsvRc, BrandFontButton, kBrandPaletteTeal, DT_CENTER | DT_VCENTER | DT_SINGLELINE);
            RECT p2Note = { p2Rc.left + 165, p2Rc.top + 34, p2Rc.right - 15, p2Rc.top + 60 };
            DrawLabel(L"Bản sao gọn, không chứa chữ gõ.", p2Note, BrandFontBody, kBrandPaletteMuted, DT_LEFT | DT_VCENTER | DT_SINGLELINE);
            y += 87;

            // Card 3 — Tự động dọn dẹp (retention)
            RECT p3Rc = { contentRc.left + 20, y, contentRc.right - 20, y + 92 };
            BrandControls_DrawCard(memDC, p3Rc, true);
            RECT p3Eb = { p3Rc.left + 15, p3Rc.top + 10, p3Rc.left + 220, p3Rc.top + 28 };
            DrawLabel(L"TỰ ĐỘNG DỌN DẸP", p3Eb, BrandFontEyebrow, kBrandPaletteStone);
            RECT p3Lbl = { p3Rc.left + 15, p3Rc.top + 32, p3Rc.right - 15, p3Rc.top + 50 };
            DrawLabel(L"Tự xóa nhật ký cũ hơn:", p3Lbl, BrandFontBody, kBrandPaletteCharcoal);
            RECT segPurgeRc = { p3Rc.left + 15, p3Rc.top + 56, p3Rc.right - 15, p3Rc.top + 84 };
            const wchar_t* purgeTabs[] = { L"30 ngày", L"60 ngày", L"90 ngày", L"Không" };
            int pd = MoodStore_GetPurgeDays();
            int purgeIdx = (pd == 30) ? 0 : ((pd == 60) ? 1 : ((pd == 90) ? 2 : 3));
            BrandControls_DrawSegmentedControl(memDC, segPurgeRc, purgeTabs, 4, purgeIdx, pt, 0);
            y += 107;

            // Card 4 — Xóa bỏ
            RECT p4Rc = { contentRc.left + 20, y, contentRc.right - 20, y + 72 };
            BrandControls_DrawCard(memDC, p4Rc, true);
            RECT p4Eb = { p4Rc.left + 15, p4Rc.top + 10, p4Rc.left + 220, p4Rc.top + 28 };
            DrawLabel(L"XÓA BỎ", p4Eb, BrandFontEyebrow, kBrandPaletteStone);
            RECT btnDelRc = { p4Rc.left + 15, p4Rc.top + 34, p4Rc.left + 185, p4Rc.top + 60 };
            HBRUSH brDel = CreateSolidBrush(MK_COLORREF(kBrandPaletteTealLight));
            FillRect(memDC, &btnDelRc, brDel);
            DeleteObject(brDel);
            DrawLabel(L"Xóa toàn bộ nhật ký", btnDelRc, BrandFontButton, kBrandPaletteTeal, DT_CENTER | DT_VCENTER | DT_SINGLELINE);
        }

        
        else if (currentTab == 2) { // Bộ gõ
            RECT contentRc = { 160, 0, clientRc.right, clientRc.bottom };
            int y = 20;

            auto DrawLabel = [&](const wchar_t* text, RECT rc, BrandFontRole font, uint32_t color, UINT format = DT_LEFT | DT_VCENTER | DT_SINGLELINE) {
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
            // [MINDFUL] G1 — chip phím tắt bật/tắt trên hàng Tiếng Việt (khớp popover). Read-only,
            // giải mã vSwitchKeyStatus; canh phải sát toggle.
            {
                RECT hkRc = { card1Rc.right - 170, card1Rc.top + 10, card1Rc.right - 56, card1Rc.top + 35 };
                DrawLabel(SwitchHotkeyText().c_str(), hkRc, BrandFontBody, kBrandPaletteStone, DT_RIGHT | DT_VCENTER | DT_SINGLELINE);
            }
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

            y += 135;

            // [MINDFUL] CP4 — thẻ "CÔNG CỤ": mở bảng Gõ tắt (macro) + Công cụ chuyển mã. 2 dialog đã có
            // sẵn (onMacroTable/onConvertTool). Mirror macOS Gõ tắt/Chuyển mã — Windows mở cửa riêng.
            RECT card4Rc = { contentRc.left + 20, y, contentRc.right - 20, y + 80 };
            BrandControls_DrawCard(memDC, card4Rc, true);
            RECT lblToolRc = { card4Rc.left + 15, card4Rc.top + 8, card4Rc.right - 15, card4Rc.top + 26 };
            DrawLabel(L"CÔNG CỤ", lblToolRc, BrandFontEyebrow, kBrandPaletteStone);
            RECT macroLinkRc = { card4Rc.left + 15, card4Rc.top + 30, card4Rc.right - 15, card4Rc.top + 52 };
            DrawLabel(L"Bảng gõ tắt ▸", macroLinkRc, BrandFontBody, kBrandPaletteTeal, DT_LEFT | DT_VCENTER | DT_SINGLELINE);
            RECT convLinkRc = { card4Rc.left + 15, card4Rc.top + 54, card4Rc.right - 15, card4Rc.top + 76 };
            DrawLabel(L"Công cụ chuyển mã ▸", convLinkRc, BrandFontBody, kBrandPaletteTeal, DT_LEFT | DT_VCENTER | DT_SINGLELINE);
        }
        else if (currentTab == 4) { // Hệ thống
            RECT contentRc = { 160, 0, clientRc.right, clientRc.bottom };
            int y = 20;

            auto DrawLabel = [&](const wchar_t* text, RECT rc, BrandFontRole font, uint32_t color, UINT format = DT_LEFT | DT_VCENTER | DT_SINGLELINE) {
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

            auto DrawLabel = [&](const wchar_t* text, RECT rc, BrandFontRole font, uint32_t color, UINT format = DT_LEFT | DT_VCENTER | DT_SINGLELINE) {
                SetBkMode(memDC, TRANSPARENT);
                SetTextColor(memDC, MK_COLORREF(color));
                HFONT f = BrandControls_Font(font);
                HFONT old = (HFONT)SelectObject(memDC, f);
                DrawTextW(memDC, text, -1, &rc, format);
                SelectObject(memDC, old);
            };

            // [MINDFUL] CP6 — đồng bộ About với macOS: icon + tên (đúng hoa/thường) + tagline GNH +
            // version+ngày + credit OpenKey (GPL) + trang chủ + nút cam "Kiểm tra bản mới" + copyright GNH.
            int cx = contentRc.left + (contentRc.right - contentRc.left) / 2;

            HICON hIcon = (HICON)LoadImageW(GetModuleHandleW(NULL), MAKEINTRESOURCEW(IDI_APP_ICON), IMAGE_ICON, 48, 48, LR_DEFAULTCOLOR);
            if (hIcon) {
                DrawIconEx(memDC, cx - 24, 26, hIcon, 48, 48, 0, NULL, DI_NORMAL);
                DestroyIcon(hIcon);
            }

            RECT titleRc = { contentRc.left, 82, contentRc.right, 110 };
            DrawLabel(L"Mindful Keyboard", titleRc, BrandFontTitle, kBrandPaletteCharcoal, DT_CENTER | DT_VCENTER | DT_SINGLELINE);

            RECT taglineRc = { contentRc.left, 112, contentRc.right, 132 };
            DrawLabel(L"Bộ gõ Tiếng Việt chánh niệm • Một sản phẩm GNH", taglineRc, BrandFontBody, kBrandPaletteMuted, DT_CENTER | DT_VCENTER | DT_SINGLELINE);

            wchar_t verBuf[256];
            wsprintfW(verBuf, L"Phiên bản %s — Ngày cập nhật %s", MindfulKeyHelper::getVersionString().c_str(), _T(__DATE__));
            RECT verRc = { contentRc.left, 134, contentRc.right, 152 };
            DrawLabel(verBuf, verRc, BrandFontBody, kBrandPaletteMuted, DT_CENTER | DT_VCENTER | DT_SINGLELINE);

            RECT creditRc = { contentRc.left, 156, contentRc.right, 174 };
            DrawLabel(L"Dựa trên OpenKey — Mai Vũ Tuyên (GPL v3)", creditRc, BrandFontBody, kBrandPaletteMuted, DT_CENTER | DT_VCENTER | DT_SINGLELINE);

            RECT homeRc = { cx - 110, 182, cx + 110, 202 };
            DrawLabel(L"Trang chủ: key.bketech.xyz", homeRc, BrandFontBody, kBrandPaletteTeal, DT_CENTER | DT_VCENTER | DT_SINGLELINE);

            RECT btnRc = { cx - 90, 214, cx + 90, 250 };
            HBRUSH btnBr = CreateSolidBrush(MK_COLORREF(kBrandPaletteOrange));
            FillRect(memDC, &btnRc, btnBr);
            DeleteObject(btnBr);
            DrawLabel(L"Kiểm tra bản mới...", btnRc, BrandFontButton, kBrandPaletteCardWhite, DT_CENTER | DT_VCENTER | DT_SINGLELINE);

            RECT copyRc = { contentRc.left, 266, contentRc.right, 286 };
            DrawLabel(L"© 2026 GNH — Lan tỏa điều tử tế", copyRc, BrandFontBody, kBrandPaletteMuted, DT_CENTER | DT_VCENTER | DT_SINGLELINE);
        }
        else if (currentTab == 6) { // [MINDFUL] H4 — Nhật Ký Tâm (các dòng đã viết)
            RECT contentRc = { 160, 0, clientRc.right, clientRc.bottom };
            int left = contentRc.left + 20, right = contentRc.right - 20;
            auto DrawLabel = [&](const wchar_t* text, RECT rc, BrandFontRole font, uint32_t color, UINT format = DT_LEFT | DT_VCENTER | DT_SINGLELINE) {
                SetBkMode(memDC, TRANSPARENT);
                SetTextColor(memDC, MK_COLORREF(color));
                HFONT f = BrandControls_Font(font);
                HFONT old = (HFONT)SelectObject(memDC, f);
                DrawTextW(memDC, text, -1, &rc, format);
                SelectObject(memDC, old);
            };
            auto dateStr = [](long long ts) -> std::wstring {
                time_t t = (time_t)ts; struct tm lt; localtime_s(&lt, &t);
                static const wchar_t* wd[] = { L"CHỦ NHẬT", L"THỨ HAI", L"THỨ BA", L"THỨ TƯ", L"THỨ NĂM", L"THỨ SÁU", L"THỨ BẢY" };
                wchar_t b[48]; swprintf_s(b, L"%s %02d·%02d", wd[lt.tm_wday], lt.tm_mday, lt.tm_mon + 1); return b;
            };

            int y = 20;
            DrawLabel(L"Nhật Ký Tâm", { left, y, right, y + 28 }, BrandFontTitle, kBrandPaletteCharcoal);
            y += 30;
            DrawLabel(L"Những dòng bạn đã viết", { left, y, right, y + 20 }, BrandFontBody, kBrandPaletteMuted);
            y += 34;

            // Danh sách note (mới nhất trước). Pane không cuộn được nên chỉ XEM TRƯỚC vài dòng +
            // link mở cửa sổ "Những dòng bạn đã viết" (cuộn đầy đủ). Link giữ nguyên trong Soi lại.
            std::vector<MoodNote> notes = MoodStore_FetchAllNotes();
            if (notes.empty()) {
                RECT emptyRc = { left, y, right, y + 60 };
                DrawLabel(L"Chưa có dòng nào. Ô ghi nằm ở cuối màn \"Soi lại hôm nay\" — khi muốn, ghi lại một dòng cho hôm nay.",
                          emptyRc, BrandFontBody, kBrandPaletteMuted, DT_LEFT | DT_TOP | DT_WORDBREAK);
            } else {
                const int kMaxPreview = 5;
                int shown = (int)notes.size() < kMaxPreview ? (int)notes.size() : kMaxPreview;
                for (int i = 0; i < shown; i++) {
                    DrawLabel(dateStr(notes[i].ts).c_str(), { left, y, right, y + 16 }, BrandFontEyebrow, kBrandPaletteStone);
                    y += 18;
                    DrawLabel(notes[i].text.c_str(), { left, y, right, y + 22 }, BrandFontBody, kBrandPaletteCharcoal, DT_LEFT | DT_TOP | DT_SINGLELINE | DT_END_ELLIPSIS);
                    y += 26;
                    RECT div = { left, y, right, y + 1 };
                    BrandControls_FillRect(memDC, div, kBrandPaletteDivider);
                    y += 12;
                }
                wchar_t moreBuf[64];
                if ((int)notes.size() > kMaxPreview) wsprintfW(moreBuf, L"Xem tất cả (%d) →", (int)notes.size());
                else wcscpy_s(moreBuf, L"Xem trong cửa sổ riêng →");
                DrawLabel(moreBuf, { left, y, right, y + 24 }, BrandFontBody, kBrandPaletteOrange, DT_LEFT | DT_VCENTER | DT_SINGLELINE);
            }

            RECT footRc = { left, contentRc.bottom - 34, right, contentRc.bottom - 14 };
            DrawLabel(L"Chỉ nằm trên máy · đã mã hoá · xoá được bất cứ lúc nào.", footRc, BrandFontEyebrow, kBrandPaletteStone, DT_LEFT | DT_VCENTER | DT_SINGLELINE);
        }

        BitBlt(hdc, 0, 0, clientRc.right, clientRc.bottom, memDC, 0, 0, SRCCOPY);

        SelectObject(memDC, oldBitmap);
        DeleteObject(memBitmap);
        DeleteDC(memDC);

        EndPaint(hDlg, &ps);

        return 0;
    }
    else if (uMsg == WM_LBUTTONUP) {
        RECT clientRc;
        GetClientRect(hDlg, &clientRc);
        int x = GET_X_LPARAM(lParam);
        int y = GET_Y_LPARAM(lParam);
        POINT pt = { x, y };

        RECT navRc = { 10, 20, 150, 300 };   // [MINDFUL] H4 — 7 mục (khớp WM_PAINT)

        if (currentTab == 0) {
            // [MINDFUL] A3 — RECT dựng lại Y HỆT nhánh WM_PAINT (currentTab==0, dòng ~224-281):
            // cùng y ban đầu + cùng +offset (title/subtitle cao 70), để vùng bấm không trôi khỏi vẽ.
            RECT contentRc = { 160, 0, clientRc.right, clientRc.bottom };
            int y = 20;
            y += 70;
            RECT cardRc = { contentRc.left + 20, y, contentRc.right - 20, y + 65 };
            RECT segRc = { cardRc.left + 100, cardRc.top + 15, cardRc.right - 15, cardRc.top + 45 };

            // [MINDFUL] A8 — ghi ĐÚNG thang NudgeCoordinator.h đọc (1=ít·2=vừa·3=nhạy). `cs` là chỉ
            // số 0-based của segmented control (0/1/2) — cộng 1 trước khi lưu registry.
            int cs = BrandControls_HitSegmented(segRc, 3, pt);
            if (cs != -1) {
                MindfulKeyHelper::setRegInt(_T("vBellSensitivity"), cs + 1);
                SystemTrayHelper::updateData();
                InvalidateRect(hDlg, NULL, FALSE);
            }

            // [MINDFUL] A7 — nút "Bật nhật ký" (chỉ hiện/bấm được khi đang tắt — RECT khớp nhánh vẽ).
            // [MINDFUL] G2b — dựng lại Y HỆT WM_PAINT: sau card ĐỘ NHẠY (+80) là viewSeg (+38) rồi
            // river (150). y advance KHÔNG còn trong if(!vMoodWatch) — WM_PAINT advance vô điều kiện.
            y += 80;
            RECT viewSegRc = { contentRc.left + 20, y, contentRc.right - 20, y + 30 };
            int vv = BrandControls_HitSegmented(viewSegRc, 2, pt);
            if (vv != -1 && vv != g_settingsRiverView) {
                g_settingsRiverView = vv;
                InvalidateRect(hDlg, NULL, FALSE);
            }
            y += 38;

            RECT riverRc = { contentRc.left + 20, y, contentRc.right - 20, y + 150 };
            if (!vMoodWatch) {
                RECT btnEnableRc = { riverRc.left + (riverRc.right - riverRc.left) / 2 - 70, riverRc.top + 95,
                                      riverRc.left + (riverRc.right - riverRc.left) / 2 + 70, riverRc.top + 123 };
                if (PtInRect(&btnEnableRc, pt)) {
                    MoodWatch_Toggle();
                    InvalidateRect(hDlg, NULL, FALSE);
                }
            } else {
                // Link "Soi lại hôm nay →" — RECT y hệt WM_PAINT (y += 160 sau river).
                RECT reflectRc = { contentRc.left + 20, y + 160, contentRc.right - 20, y + 160 + 24 };
                if (PtInRect(&reflectRc, pt)) {
                    ReflectionScreen_Show(hDlg);
                }
            }
        }

        if (currentTab == 1) {
            // [MINDFUL] A2 — RECT dựng lại Y HỆT nhánh WM_PAINT (currentTab==1, dòng ~282-338):
            // cùng y ban đầu + cùng +offset, để vùng bấm không bao giờ trôi khỏi vùng vẽ.
            RECT contentRc = { 160, 0, clientRc.right, clientRc.bottom };
            int y = 20;
            // [MINDFUL] F3 — card1 60→74 + sw1 dời tâm theo, y sau card1 75→89 (khớp WM_PAINT).
            RECT card1Rc = { contentRc.left + 20, y, contentRc.right - 20, y + 74 };
            RECT sw1Rc = { card1Rc.right - 50, card1Rc.top + 26, card1Rc.right - 14, card1Rc.top + 47 };
            y += 89;

            // [MINDFUL] G2a — card2 90→110 + y 105→125 (khớp WM_PAINT: NHỊP + stepper tùy chỉnh).
            RECT card2Rc = { contentRc.left + 20, y, contentRc.right - 20, y + 110 };
            RECT seg2Rc = { card2Rc.left + 15, card2Rc.top + 35, card2Rc.right - 15, card2Rc.top + 65 };
            y += 125;

            RECT card3Rc = { contentRc.left + 20, y, contentRc.right - 20, y + 110 };
            RECT btnPreviewRc = { card3Rc.right - 90, card3Rc.top + 8, card3Rc.right - 15, card3Rc.top + 30 };
            RECT iconGrpRc = { card3Rc.left + 15, card3Rc.top + 35, card3Rc.right - 15, card3Rc.top + 75 };
            RECT sliderRc = { card3Rc.left + 15, card3Rc.top + 85, card3Rc.right - 15, card3Rc.top + 100 };

            bool changed = false;

            // [MINDFUL] B4 — "Nghe thử": phát ngay, không đổi state nên không cần `changed`.
            if (PtInRect(&btnPreviewRc, pt)) {
                Bell_PreviewSound();
            }

            // Pill "Bật chuông tỉnh thức" — nối ĐÚNG vBell (không phải FLAG_BEEP của OpenKey).
            if (PtInRect(&sw1Rc, pt)) {
                APP_SET_DATA(vBell, vBell ? 0 : 1);
                Bell_ApplySettings();   // BẬT/tắt đồng hồ chuông thật
                changed = true;
            }

            // [MINDFUL] G2a — segmented "NHỊP" 30/60/Tùy chỉnh (mirror popover). ci==2 = Tùy chỉnh:
            // đặt tạm 120' + mở stepper; dec/inc/Đặt xử ngay dưới.
            int ci = BrandControls_HitSegmented(seg2Rc, 3, pt);
            if (ci != -1) {
                int curInt2 = (vBellInterval == 30) ? 0 : ((vBellInterval == 60) ? 1 : 2);
                if (ci != curInt2) {
                    int newMins = (ci == 0) ? 30 : ((ci == 1) ? 60 : 120);
                    APP_SET_DATA(vBellInterval, newMins);
                    Bell_ApplySettings();
                    g_settingsBellDraft = 0;
                    changed = true;
                }
            }
            // Stepper tùy chỉnh — RECT dựng lại Y HỆT WM_PAINT (khi đang ở "Tùy chỉnh").
            if (((vBellInterval == 30) ? 0 : ((vBellInterval == 60) ? 1 : 2)) == 2) {
                if (g_settingsBellDraft <= 0) g_settingsBellDraft = vBellInterval;
                RECT stepRc = { card2Rc.left + 15, card2Rc.top + 72, card2Rc.left + 150, card2Rc.top + 98 };
                RECT sDecRc = { stepRc.left, stepRc.top, stepRc.left + 28, stepRc.bottom };
                RECT sIncRc = { stepRc.right - 28, stepRc.top, stepRc.right, stepRc.bottom };
                RECT sSetRc = { stepRc.right + 10, stepRc.top, stepRc.right + 74, stepRc.bottom };
                if (PtInRect(&sDecRc, pt)) { g_settingsBellDraft -= 5; if (g_settingsBellDraft < 15) g_settingsBellDraft = 15; changed = true; }
                else if (PtInRect(&sIncRc, pt)) { g_settingsBellDraft += 5; if (g_settingsBellDraft > 240) g_settingsBellDraft = 240; changed = true; }
                else if (PtInRect(&sSetRc, pt)) { APP_SET_DATA(vBellInterval, g_settingsBellDraft); Bell_ApplySettings(); changed = true; }
            }

            // [MINDFUL] CP2 — mở hộp chọn .wav, DÙNG CHUNG cho icon nốt nhạc + nút "Chọn tiếng .wav"
            // (gom lambda tránh copy-paste trôi dạt — code-review §7).
            auto PickCustomWav = [&]() {
                TCHAR file[MAX_PATH] = { 0 };
                OPENFILENAME ofn = { 0 };
                ofn.lStructSize = sizeof(ofn);
                ofn.hwndOwner = hDlg;
                ofn.lpstrFilter = _T("Tệp âm thanh (*.wav)\0*.wav\0");
                ofn.lpstrFile = file;
                ofn.nMaxFile = MAX_PATH;
                ofn.Flags = OFN_FILEMUSTEXIST | OFN_PATHMUSTEXIST;
                if (GetOpenFileName(&ofn)) {
                    std::wstring err;
                    if (Bell_InstallCustomSound(file, &err)) {
                        MindfulKeyHelper::setRegString(_T("vBellSoundName"), _T("custom"));
                        Bell_PreviewSound();
                        changed = true;
                    } else {
                        MessageBoxW(hDlg, err.c_str(), L"Mindful Keyboard", MB_OK);
                    }
                }
            };

            // "BỘ TIẾNG" — ghi ĐÚNG chuỗi id mà Bell.cpp SoundIdFromStored chấp nhận. CP2: bấm nốt nhạc
            // (cs==3 "custom") LUÔN mở hộp chọn .wav (mirror macOS onBellClick + popover P2) — tách khỏi
            // nhánh ghi tên thường để bấm lại vẫn cho đổi tệp.
            int cs = BrandControls_HitIconGroup(iconGrpRc, 4, pt);
            if (cs == 3) {
                PickCustomWav();
            } else if (cs != -1) {
                static const wchar_t* kBellSoundIds[] = { L"temple", L"chime", L"wind", L"custom" };
                MindfulKeyHelper::setRegString(_T("vBellSoundName"), kBellSoundIds[cs]);
                changed = true;
            }

            // Slider âm lượng — ghi ĐÚNG vBellVolume (không phải vVolume — khoá đó không ai đọc).
            float vp;
            if (BrandControls_HitSlider(sliderRc, pt, &vp)) {
                MindfulKeyHelper::setRegInt(_T("vBellVolume"), (int)(vp * 100));
                changed = true;
            }

            // [MINDFUL] B6 — card Giờ yên lặng: RECT dựng lại Y HỆT nhánh WM_PAINT (y sau card3 = +125).
            y += 125;
            // [MINDFUL] F1/F2 — khớp Y HỆT khối vẽ: card4 116, ry +44, box 100px cách qua "đến",
            // GỠ btnCustom (nút .wav thừa), giữ Tạm hoãn.
            RECT card4Rc = { contentRc.left + 20, y, contentRc.right - 20, y + 116 };
            int ry = card4Rc.top + 44;
            RECT fromBox = { card4Rc.left + 102, ry, card4Rc.left + 202, ry + 28 };
            RECT toBox = { card4Rc.left + 242, ry, card4Rc.left + 342, ry + 28 };
            int by = card4Rc.top + 82;
            RECT btnSnoozeRc = { card4Rc.right - 130, by, card4Rc.right - 15, by + 26 };
            // Stepper: bấm − lùi 1 giờ, + tiến 1 giờ (vòng 0-23). Trả về giờ mới, -1 nếu không trúng.
            auto HitStepper = [&](RECT box, int cur) -> int {
                RECT decRc = { box.left, box.top, box.left + 24, box.bottom };
                RECT incRc = { box.right - 24, box.top, box.right, box.bottom };
                if (PtInRect(&decRc, pt)) return (cur + 23) % 24;
                if (PtInRect(&incRc, pt)) return (cur + 1) % 24;
                return -1;
            };
            int nf = HitStepper(fromBox, vBellFrom);
            if (nf != -1) { APP_SET_DATA(vBellFrom, nf); Bell_ApplySettings(); changed = true; }
            int nt = HitStepper(toBox, vBellTo);
            if (nt != -1) { APP_SET_DATA(vBellTo, nt); Bell_ApplySettings(); changed = true; }

            if (PtInRect(&btnSnoozeRc, pt)) {
                Bell_Snooze(60);
            }

            if (changed) {
                SystemTrayHelper::updateData();
                InvalidateRect(hDlg, NULL, FALSE);
            }
        }

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

            // [MINDFUL] CP4 — thẻ CÔNG CỤ: RECT dựng lại Y HỆT khối vẽ. Mở cửa riêng nên không cần changed.
            y += 135;
            RECT card4Rc = { contentRc.left + 20, y, contentRc.right - 20, y + 80 };
            RECT macroLinkRc = { card4Rc.left + 15, card4Rc.top + 30, card4Rc.right - 15, card4Rc.top + 52 };
            RECT convLinkRc = { card4Rc.left + 15, card4Rc.top + 54, card4Rc.right - 15, card4Rc.top + 76 };
            if (PtInRect(&macroLinkRc, pt)) AppDelegate::getInstance()->onMacroTable();
            else if (PtInRect(&convLinkRc, pt)) AppDelegate::getInstance()->onConvertTool();

            if (changed) {
                SystemTrayHelper::updateData();
                InvalidateRect(hDlg, NULL, FALSE);
            }
        }
        else if (currentTab == 3) {
            // [MINDFUL] CP5 — hit-test tab Riêng tư (khối này TRƯỚC ĐÂY THIẾU HẲN). RECT dựng lại Y HỆT
            // khối vẽ. 4 nhóm: consent toggle, Xuất CSV, retention segmented, Xóa toàn bộ.
            RECT contentRc = { 160, 0, clientRc.right, clientRc.bottom };
            int y = 20;
            RECT p1Rc = { contentRc.left + 20, y, contentRc.right - 20, y + 78 };
            RECT p1Sw = { p1Rc.right - 50, p1Rc.top + 32, p1Rc.right - 14, p1Rc.top + 53 };
            y += 93;
            RECT p2Rc = { contentRc.left + 20, y, contentRc.right - 20, y + 72 };
            RECT btnCsvRc = { p2Rc.left + 15, p2Rc.top + 34, p2Rc.left + 155, p2Rc.top + 60 };
            y += 87;
            RECT p3Rc = { contentRc.left + 20, y, contentRc.right - 20, y + 92 };
            RECT segPurgeRc = { p3Rc.left + 15, p3Rc.top + 56, p3Rc.right - 15, p3Rc.top + 84 };
            y += 107;
            RECT p4Rc = { contentRc.left + 20, y, contentRc.right - 20, y + 72 };
            RECT btnDelRc = { p4Rc.left + 15, p4Rc.top + 34, p4Rc.left + 185, p4Rc.top + 60 };

            bool changed = false;
            // [MINDFUL] CP5 review — công tắc này bật/tắt CẢ watcher (vMoodWatch — thứ ghi nhật ký) LẪN
            // consent lưu trữ, để không còn "công tắc chết câm". Đồng bộ với popover "Bật nhật ký"
            // (cùng đọc vMoodWatch). Tắt = tắt watcher (MoodWatch_Toggle tự dọn state sông sống) + XÓA
            // SẠCH (SetConsent(false) gọi DeleteAll). Bật = bật watcher + cho phép lưu (bật ở đây LÀ đồng ý).
            if (PtInRect(&p1Sw, pt)) {
                if (vMoodWatch) {
                    if (MessageBoxW(hDlg, L"Tắt nhật ký sẽ XÓA SẠCH mọi dữ liệu cảm xúc đã lưu. Tiếp tục?",
                            L"Mindful Keyboard", MB_YESNO | MB_ICONQUESTION) == IDYES) {
                        MoodWatch_Toggle();            // vMoodWatch=1 -> 0 + dọn sạch state sông sống
                        MoodStore_SetConsent(false);   // xóa dữ liệu đã lưu
                        changed = true;
                    }
                } else {
                    APP_SET_DATA(vMoodWatch, 1);        // bật watcher trực tiếp (không modal — đây LÀ đồng ý)
                    MoodStore_SetConsent(true);         // cho phép lưu
                    changed = true;
                }
            }
            // Xuất CSV (GetSaveFileName → MoodStore_ExportCSV).
            if (PtInRect(&btnCsvRc, pt)) {
                if (!MoodStore_HasConsent()) {
                    MessageBoxW(hDlg, L"Chưa có nhật ký để xuất (nhật ký đang tắt).", L"Mindful Keyboard", MB_OK);
                } else {
                    TCHAR file[MAX_PATH] = _T("mindful-mood.csv");
                    OPENFILENAME ofn = { 0 };
                    ofn.lStructSize = sizeof(ofn);
                    ofn.hwndOwner = hDlg;
                    ofn.lpstrFilter = _T("Tệp CSV (*.csv)\0*.csv\0");
                    ofn.lpstrFile = file;
                    ofn.nMaxFile = MAX_PATH;
                    ofn.lpstrDefExt = _T("csv");
                    ofn.Flags = OFN_OVERWRITEPROMPT | OFN_PATHMUSTEXIST;
                    if (GetSaveFileName(&ofn)) {
                        MessageBoxW(hDlg, MoodStore_ExportCSV(file) ? L"Đã xuất nhật ký ra file CSV." : L"Xuất CSV không thành công.",
                            L"Mindful Keyboard", MB_OK);
                    }
                }
            }
            // Retention: 30/60/90/Không.
            int ps = BrandControls_HitSegmented(segPurgeRc, 4, pt);
            if (ps != -1) {
                int days = (ps == 0) ? 30 : ((ps == 1) ? 60 : ((ps == 2) ? 90 : 0));
                MoodStore_SetPurgeDays(days);
                changed = true;
            }
            // Xóa toàn bộ.
            if (PtInRect(&btnDelRc, pt)) {
                if (MessageBoxW(hDlg, L"Xóa toàn bộ nhật ký cảm xúc trên máy này?\nKhông thể lấy lại.",
                        L"Mindful Keyboard", MB_YESNO | MB_ICONQUESTION) == IDYES) {
                    MoodStore_DeleteAll();
                    changed = true;
                }
            }
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
                pThis->requestRestartAsAdmin();
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
            // [MINDFUL] CP6 — RECT dựng lại Y HỆT khối vẽ (toạ độ tuyệt đối). Trang chủ + nút cập nhật.
            RECT contentRc = { 160, 0, clientRc.right, clientRc.bottom };
            int cx = contentRc.left + (contentRc.right - contentRc.left) / 2;
            RECT homeRc = { cx - 110, 182, cx + 110, 202 };
            RECT btnRc = { cx - 90, 214, cx + 90, 250 };
            if (PtInRect(&homeRc, pt)) {
                ShellExecute(NULL, _T("open"), _T("https://key.bketech.xyz"), NULL, NULL, SW_SHOWNORMAL);
            } else if (PtInRect(&btnRc, pt)) {
                pThis->onUpdateButton();   // tự kiểm + tự tải + tự mở bộ cài (UpdateChecker)
            }
        }
        else if (currentTab == 6) {   // [MINDFUL] H4 — Nhật Ký Tâm: link "Xem tất cả/riêng →" mở cửa sổ đầy đủ
            RECT contentRc = { 160, 0, clientRc.right, clientRc.bottom };
            int left = contentRc.left + 20, right = contentRc.right - 20;
            std::vector<MoodNote> notes = MoodStore_FetchAllNotes();
            if (!notes.empty()) {
                int shown = (int)notes.size() < 5 ? (int)notes.size() : 5;
                int linkY = 84 + shown * 56;   // khớp WM_PAINT: 20+30+34 + shown*(18+26+12)
                RECT linkRc = { left, linkY, right, linkY + 24 };
                if (PtInRect(&linkRc, pt)) {
                    NotesHistory_Show(hDlg);
                }
            }
        }

        if (PtInRect(&navRc, pt)) {
            int row = (pt.y - navRc.top) / 40;
            static const int navTabIndex[] = { 0, 6, 1, 2, 3, 4, 5 };   // [MINDFUL] H4 — khớp WM_PAINT
            if (row >= 0 && row < 7 && navTabIndex[row] != currentTab) {
                currentTab = navTabIndex[row];
                pThis->onTabIndexChanged(); // cập nhật Show/Hide child dialogs
                InvalidateRect(hDlg, NULL, FALSE);
            }
        }
    }

    // [MINDFUL] blank-window fix: tabPageEventProc is now reached ONLY via eventProc's delegation
    // of WM_PAINT/WM_ERASEBKGND/WM_LBUTTONUP. It must NOT forward back to eventProc, or WM_LBUTTONUP
    // would recurse forever (eventProc re-delegates it straight back here). WM_COMMAND/WM_NOTIFY
    // already reach eventProc directly since that is the dialog's real proc.
    return FALSE;
}

void MainControlDialog::selectTab(int tab) {
    currentTab = tab;
    HWND h = getHwnd();
    if (h) InvalidateRect(h, NULL, FALSE);   // tab vẽ tay (owner-draw) — invalidate là repaint đúng tab
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
	// Xem AboutDialog::onUpdateButton() cho lịch sử/lý do đầy đủ. Tự kiểm + tự tải + tự mở bộ cài.
	UpdateChecker_CheckAndUpdate(hDlg);
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
