/*----------------------------------------------------------
OpenKey - The Cross platform Open source Vietnamese Keyboard application.

Copyright (C) 2019 Mai Vu Tuyen
Contact: maivutuyen.91@gmail.com
Github: https://github.com/tuyenvm/OpenKey
Fanpage: https://www.facebook.com/OpenKeyVN

This file is belong to the OpenKey project, Win32 version
which is released under GPL license.
You can fork, modify, improve this program. If you
redistribute your new version, it MUST be open source.
-----------------------------------------------------------*/
#include "SystemTrayHelper.h"
#include "AppDelegate.h"
#include "MoodWatch.h"
#include "SendGatekeeper.h"
#include "MoodStore.h"
#include "ReflectionScreen.h"
#include "Bell.h"

#define WM_TRAYMESSAGE (WM_USER + 1)
// [MINDFUL] GĐ6 — MoodWatch (LUỒNG WORKER) báo "tâm đang động". Phải đi qua PostMessage chứ không
// gọi thẳng: hẹn giờ "lắng về" dùng SetTimer, mà SetTimer cần VÒNG LẶP THÔNG ĐIỆP — worker không
// có, nên gọi thẳng thì icon đổi rồi KẸT LUÔN ở trạng thái động, không bao giờ lắng lại.
#define WM_WAVE_ALERT  (WM_USER + 2)
// [MINDFUL] Cảnh báo bộ gõ đối thủ (OpenKey gốc) đang chạy cùng lúc. CỐ Ý PostMessage chứ không
// Send: hộp thoại chỉ được hiện SAU khi vòng lặp thông điệp đã chạy và cửa sổ đã có chủ — không
// bao giờ chặn lúc dựng app. Đây là hiện thân của docs/LIFECYCLE-SAFETY-CONTRACT.md bất biến #1.
#define WM_MK_RIVAL_WARN (WM_USER + 3)
#define TIMER_WAVE_SETTLE 0xA1

// "rồi lắng về Status sau VÀI GIÂY" (BRAND-ASSETS.md §6). "Vài giây" không phải con số — 3s lấy
// theo mỏ neo có sẵn của chính sản phẩm: BreathingPausePrompt::durationSeconds mặc định 3.0
// (core/mood/BreathingPause.h). Xem docs/FRICTION-LOG.md 2026-07-17.
static const UINT kWaveAlertMs = 3000;
static bool g_waveAlert = false;
#define TRAY_ICONUID 100

#define POPUP_VIET_ON_OFF 900
#define POPUP_SPELLING 901
#define POPUP_SMART_SWITCH 902
#define POPUP_USE_MACRO 903
#define POPUP_MOODWATCH 905
#define POPUP_BELL_SETTINGS 906
#define POPUP_GATEKEEPER_APP 907
#define POPUP_MOOD_DELETE 908
#define POPUP_REFLECT 909

#define POPUP_TELEX 910
#define POPUP_VNI 911
#define POPUP_SIMPLE_TELEX 912

#define POPUP_UNICODE 930
#define POPUP_TCVN3 931
#define POPUP_VNI_WINDOWS 932
#define POPUP_UNICODE_COMPOUND 933
#define POPUP_VN_LOCALE_1258 934

#define POPUP_CONVERT_TOOL 980
#define POPUP_QUICK_CONVERT 981

#define POPUP_MACRO_TABLE 990

#define POPUP_CONTROL_PANEL 1000
#define POPUP_ABOUT_OPENKEY 1010
#define POPUP_OPENKEY_EXIT 2000

#define MODIFY_MENU(MENU, COMMAND, DATA) ModifyMenu(MENU, COMMAND, \
											MF_BYCOMMAND | (DATA ? MF_CHECKED : MF_UNCHECKED), \
											COMMAND, \
											menuData[COMMAND]);

static HMENU popupMenu;
//static HMENU menuInputType;
static HMENU otherCode;

static NOTIFYICONDATA nid;

map<UINT, LPCTSTR> menuData = {
	{POPUP_VIET_ON_OFF, _T("Bật Tiếng Việt")},
	{POPUP_SPELLING, _T("Bật kiểm tra chính tả")},
	{POPUP_SMART_SWITCH, _T("Bật loại trừ ứng dụng thông minh")},
	{POPUP_USE_MACRO, _T("Bật gõ tắt")},
	{POPUP_MOODWATCH, _T("Bật nhắc tâm (cảm xúc)")},
	{POPUP_BELL_SETTINGS, _T("Chuông tỉnh thức...")},
	{POPUP_GATEKEEPER_APP, _T("Gác cổng gửi tin cho app này")},
	{POPUP_REFLECT, _T("Soi lại hôm nay...")},
	{POPUP_MOOD_DELETE, _T("Xóa toàn bộ nhật ký cảm xúc...")},
	{POPUP_TELEX, _T("Kiểu gõ Telex")},
	{POPUP_VNI, _T("Kiểu gõ VNI")},
	{POPUP_SIMPLE_TELEX, _T("Kiểu gõ Simple Telex")},
	{POPUP_UNICODE, _T("Unicode dựng sẵn")},
	{POPUP_TCVN3, _T("TCVN3 (ABC)")},
	{POPUP_VNI_WINDOWS, _T("VNI Windows")},
	{POPUP_UNICODE_COMPOUND, _T("Unicode tổ hợp")},
	{POPUP_VN_LOCALE_1258, _T("Vietnamese locale CP 1258")},
	{POPUP_CONVERT_TOOL, _T("Công cụ chuyển mã...")},
	{POPUP_QUICK_CONVERT, _T("Chuyển mã nhanh")},
	{POPUP_MACRO_TABLE, _T("Cấu hình gõ tắt...")},
	{POPUP_CONTROL_PANEL, _T("Bảng điều khiển...")},
	{POPUP_ABOUT_OPENKEY, _T("Giới thiệu Mindful Keyboard")},
	{POPUP_OPENKEY_EXIT, _T("Thoát")},
};

LRESULT CALLBACK WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam) {
	static UINT taskbarCreated;

	switch (message) {
	case WM_CREATE:
		taskbarCreated = RegisterWindowMessage(_T("TaskbarCreated"));
		break;
	case WM_WAVE_ALERT:
		// Chạy trên luồng CỦA CỬA SỔ -> SetTimer có vòng lặp thông điệp để nổ.
		g_waveAlert = true;
		SystemTrayHelper::updateData();
		KillTimer(hWnd, TIMER_WAVE_SETTLE);          // gợn tiếp trong lúc đang động -> gia hạn,
		SetTimer(hWnd, TIMER_WAVE_SETTLE, kWaveAlertMs, NULL);   // không chồng nhiều hẹn giờ
		return 0;
	case WM_TIMER:
		if (wParam == TIMER_WAVE_SETTLE) {
			KillTimer(hWnd, TIMER_WAVE_SETTLE);
			g_waveAlert = false;
			SystemTrayHelper::updateData();          // lắng về mặt hồ thường
			return 0;
		}
		break;
	case WM_USER+2019:
		AppDelegate::getInstance()->onControlPanel();
		break;
	case WM_MK_RIVAL_WARN: {
		// Chạy trên luồng cửa sổ, đã trong vòng lặp thông điệp -> an toàn để hiện modal có chủ.
		// Giọng quan sát, không phán xét (HIẾN CHƯƠNG §2.2): mô tả hiện tượng "giẫm phím", không
		// đổ lỗi cho bên nào. KHÔNG tự tắt OpenKey — để người dùng chọn, khác macOS (Windows tắt
		// tiến trình bên khác là hành vi nặng); chỉ nói cho biết. §6.3: không để xung đột diễn ra câm.
		HWND rival = FindWindow(RIVAL_OPENKEY_CLASS, NULL);
		if (rival) {
			SetForegroundWindow(hWnd);
			MessageBoxW(hWnd,
				L"OpenKey đang chạy cùng lúc với MindfulKey. Hai bộ gõ cùng bắt phím sẽ giẫm lên "
				L"nhau, chữ gõ ra có thể sai dấu.\n\nHãy tắt một trong hai để gõ ổn định.",
				L"MindfulKey", MB_OK | MB_ICONWARNING);
		}
		return 0;
	}
	case WM_TRAYMESSAGE: {
		if (lParam == WM_LBUTTONDBLCLK) {
			AppDelegate::getInstance()->onControlPanel();
		}
		if (lParam == WM_LBUTTONUP) {
			AppDelegate::getInstance()->onToggleVietnamese();
			SystemTrayHelper::updateData();
		} else if (lParam == WM_RBUTTONDOWN) {
			POINT curPoint;
			GetCursorPos(&curPoint);
			SetForegroundWindow(hWnd);
			UINT commandId = TrackPopupMenu(
				popupMenu,
				TPM_RETURNCMD | TPM_NONOTIFY,
				curPoint.x,
				curPoint.y,
				0,
				hWnd,
				NULL
			);
			switch (commandId) {
			case POPUP_VIET_ON_OFF:
				AppDelegate::getInstance()->onToggleVietnamese();
				break;
			case POPUP_SPELLING:
				AppDelegate::getInstance()->onToggleCheckSpelling();
				break;
			case POPUP_SMART_SWITCH:
				AppDelegate::getInstance()->onToggleUseSmartSwitchKey();
				break;
			case POPUP_USE_MACRO:
				AppDelegate::getInstance()->onToggleUseMacro();
				break;
			case POPUP_MOODWATCH:
				MoodWatch_Toggle();
				break;
			case POPUP_BELL_SETTINGS:
				Bell_ShowSettings(NULL);
				break;
			case POPUP_GATEKEEPER_APP:
				SendGatekeeper_ToggleLastApp();
				break;
			case POPUP_REFLECT:
				ReflectionScreen_Show(NULL);
				break;
			case POPUP_MOOD_DELETE:
				// Hỏi lại trước khi xoá: đây là dữ liệu KHÔNG lấy lại được, và không có bản sao ở
				// đâu cả (không đồng bộ, không đám mây — đó là điểm của sản phẩm).
				if (MessageBoxW(NULL,
						L"Xóa toàn bộ nhật ký cảm xúc trên máy này?\n\n"
						L"Không thể lấy lại — nhật ký chỉ nằm ở đây, không có bản sao nào khác.",
						L"Mindful Keyboard", MB_YESNO | MB_ICONQUESTION) == IDYES) {
					MoodStore_DeleteAll();
					MessageBoxW(NULL, L"Đã xóa sạch nhật ký cảm xúc.", L"Mindful Keyboard", MB_OK);
				}
				break;
			case POPUP_MACRO_TABLE:
				AppDelegate::getInstance()->onMacroTable();
				break;
			case POPUP_CONVERT_TOOL:
				AppDelegate::getInstance()->onConvertTool();
				break;
			case POPUP_QUICK_CONVERT:
				AppDelegate::getInstance()->onQuickConvert();
				break;
			case POPUP_TELEX:
				AppDelegate::getInstance()->onInputType(0);
				break;
			case POPUP_VNI:
				AppDelegate::getInstance()->onInputType(1);
				break;
			case POPUP_SIMPLE_TELEX:
				AppDelegate::getInstance()->onInputType(2);
				break;
			case POPUP_UNICODE:
				AppDelegate::getInstance()->onTableCode(0);
				break;
			case POPUP_TCVN3:
				AppDelegate::getInstance()->onTableCode(1);
				break;
			case POPUP_VNI_WINDOWS:
				AppDelegate::getInstance()->onTableCode(2);
				break;
			case POPUP_UNICODE_COMPOUND:
				AppDelegate::getInstance()->onTableCode(3);
				break;
			case POPUP_VN_LOCALE_1258:
				AppDelegate::getInstance()->onTableCode(4);
				break;
			case POPUP_CONTROL_PANEL:
				AppDelegate::getInstance()->onControlPanel();
				break;
			case POPUP_ABOUT_OPENKEY:
				AppDelegate::getInstance()->onOpenKeyAbout();
				break;
			case POPUP_OPENKEY_EXIT:
				AppDelegate::getInstance()->onOpenKeyExit();
				break;
			}
			SystemTrayHelper::updateData();
		}
	}
	break;
	default:
		// if the taskbar is restarted, add the system tray icon again
		if (message == taskbarCreated) {
			Shell_NotifyIcon(NIM_ADD, &nid);
		}
		return DefWindowProc(hWnd, message, wParam, lParam);
	}
	return 0;
}

HWND SystemTrayHelper::createFakeWindow(const HINSTANCE & hIns) {
	//create fake window
	WNDCLASSEXW wcex;
	wcex.cbSize = sizeof(WNDCLASSEX);
	wcex.style = 0;
	wcex.lpfnWndProc = WndProc;
	wcex.cbClsExtra = 0;
	wcex.cbWndExtra = 0;
	wcex.hInstance = hIns;
	wcex.hIcon = LoadIcon(hIns, MAKEINTRESOURCE(IDI_APP_ICON));
	wcex.hCursor = NULL;
	wcex.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
	wcex.lpszMenuName = NULL;
	wcex.lpszClassName = APP_CLASS;
	wcex.hIconSm = NULL;
	ATOM atom = RegisterClassExW(&wcex);
	HWND hWnd = CreateWindowW(APP_CLASS, _T(""), WS_OVERLAPPEDWINDOW,
		CW_USEDEFAULT, 0, CW_USEDEFAULT, 0, nullptr, nullptr, hIns, nullptr);
	if (!hWnd) {
		return NULL;
	}
	ShowWindow(hWnd, 0);
	UpdateWindow(hWnd);
	return hWnd;
}

void SystemTrayHelper::createPopupMenu() {
	popupMenu = CreatePopupMenu();
	AppendMenu(popupMenu, MF_CHECKED, POPUP_VIET_ON_OFF, menuData[POPUP_VIET_ON_OFF]);
	AppendMenu(popupMenu, MF_SEPARATOR, 0, 0);
	AppendMenu(popupMenu, MF_CHECKED, POPUP_SPELLING, menuData[POPUP_SPELLING]);
	AppendMenu(popupMenu, MF_CHECKED, POPUP_SMART_SWITCH, menuData[POPUP_SMART_SWITCH]);
	AppendMenu(popupMenu, MF_CHECKED, POPUP_USE_MACRO, menuData[POPUP_USE_MACRO]);
	AppendMenu(popupMenu, MF_CHECKED, POPUP_MOODWATCH, menuData[POPUP_MOODWATCH]);
	AppendMenu(popupMenu, MF_STRING, POPUP_BELL_SETTINGS, menuData[POPUP_BELL_SETTINGS]);
	AppendMenu(popupMenu, MF_UNCHECKED, POPUP_GATEKEEPER_APP, menuData[POPUP_GATEKEEPER_APP]);
	AppendMenu(popupMenu, MF_STRING, POPUP_REFLECT, menuData[POPUP_REFLECT]);
	AppendMenu(popupMenu, MF_STRING, POPUP_MOOD_DELETE, menuData[POPUP_MOOD_DELETE]);
	AppendMenu(popupMenu, MF_SEPARATOR, 0, 0);
	AppendMenu(popupMenu, MF_UNCHECKED, POPUP_MACRO_TABLE, menuData[POPUP_MACRO_TABLE]);
	AppendMenu(popupMenu, MF_UNCHECKED, POPUP_CONVERT_TOOL, menuData[POPUP_CONVERT_TOOL]);
	AppendMenu(popupMenu, MF_UNCHECKED, POPUP_QUICK_CONVERT, menuData[POPUP_QUICK_CONVERT]);
	AppendMenu(popupMenu, MF_SEPARATOR, 0, 0);

	//menuInputType = CreatePopupMenu();
	AppendMenu(popupMenu, MF_CHECKED, POPUP_TELEX, menuData[POPUP_TELEX]);
	AppendMenu(popupMenu, MF_CHECKED, POPUP_VNI, menuData[POPUP_VNI]);
	AppendMenu(popupMenu, MF_CHECKED, POPUP_SIMPLE_TELEX, menuData[POPUP_SIMPLE_TELEX]);

	//AppendMenu(popupMenu, MF_POPUP, (UINT_PTR)menuInputType, _T("Kiểu gõ"));
	AppendMenu(popupMenu, MF_SEPARATOR, 0, 0);

	AppendMenu(popupMenu, MF_UNCHECKED, POPUP_UNICODE, menuData[POPUP_UNICODE]);
	AppendMenu(popupMenu, MF_UNCHECKED, POPUP_TCVN3, menuData[POPUP_TCVN3]);
	AppendMenu(popupMenu, MF_UNCHECKED, POPUP_VNI_WINDOWS, menuData[POPUP_VNI_WINDOWS]);

	otherCode = CreatePopupMenu();
	AppendMenu(otherCode, MF_CHECKED, POPUP_UNICODE_COMPOUND, menuData[POPUP_UNICODE_COMPOUND]);
	AppendMenu(otherCode, MF_CHECKED, POPUP_VN_LOCALE_1258, menuData[POPUP_VN_LOCALE_1258]);
	AppendMenu(popupMenu, MF_POPUP, (UINT_PTR)otherCode, _T("Bảng mã khác"));

	AppendMenu(popupMenu, MF_SEPARATOR, 0, 0);

	AppendMenu(popupMenu, MF_STRING, POPUP_CONTROL_PANEL, menuData[POPUP_CONTROL_PANEL]);
	AppendMenu(popupMenu, MF_UNCHECKED, POPUP_ABOUT_OPENKEY, menuData[POPUP_ABOUT_OPENKEY]);
	AppendMenu(popupMenu, MF_SEPARATOR, 0, 0);
	AppendMenu(popupMenu, MF_UNCHECKED, POPUP_OPENKEY_EXIT, menuData[POPUP_OPENKEY_EXIT]);

	SetMenuDefaultItem(popupMenu, POPUP_CONTROL_PANEL, false);
}

static void loadTrayIcon() {
	int icon = 0;
	// Sóng biên độ cao thắng mọi trạng thái khác: lúc tâm đang động thì đó là thứ đáng nói nhất.
	// TEAL, không cam — nhận diện là BIÊN ĐỘ, không phải màu cảnh báo (HIẾN CHƯƠNG §2.3).
	if (g_waveAlert) {
		nid.hIcon = LoadIcon(GetModuleHandle(0), MAKEINTRESOURCE(IDI_ICON_STATUS_ALERT));
		LoadString(GetModuleHandle(0), IDS_TRAY_TITLE_2, nid.szTip, 128);
		return;
	}
	if (vLanguage) {
		icon = vUseGrayIcon ? IDI_ICON_STATUS_VIET_10 : IDI_ICON_STATUS_VIET;
		LoadString(GetModuleHandle(0), IDS_TRAY_TITLE_2, nid.szTip, 128);
	}
	else {
		icon = vUseGrayIcon ? IDI_ICON_STATUS_ENG_10 : IDI_ICON_STATUS_ENG;
		LoadString(GetModuleHandle(0), IDS_TRAY_TITLE, nid.szTip, 128);
	}
	nid.hIcon = LoadIcon(GetModuleHandle(0), MAKEINTRESOURCE(icon));
}

void SystemTrayHelper::updateData() {
	loadTrayIcon();
	Shell_NotifyIcon(NIM_MODIFY, &nid);

	MODIFY_MENU(popupMenu, POPUP_VIET_ON_OFF, vLanguage);
	MODIFY_MENU(popupMenu, POPUP_SPELLING, vCheckSpelling);
	MODIFY_MENU(popupMenu, POPUP_SMART_SWITCH, vUseSmartSwitchKey);
	MODIFY_MENU(popupMenu, POPUP_USE_MACRO, vUseMacro);
	MODIFY_MENU(popupMenu, POPUP_MOODWATCH, vMoodWatch);
	// Dấu tích = app ĐANG DÙNG có đang được gác cổng không. Đọc getLastAppExecuteName() nên
	// nó là app trước khi bấm vào khay, không phải chính bộ gõ.
	MODIFY_MENU(popupMenu, POPUP_GATEKEEPER_APP, SendGatekeeper_IsAppWatched(SendGatekeeper_LastAppName()));
	MODIFY_MENU(popupMenu, POPUP_TELEX, vInputType == 0);
	MODIFY_MENU(popupMenu, POPUP_VNI, vInputType == 1);
	MODIFY_MENU(popupMenu, POPUP_SIMPLE_TELEX, vInputType == 2);
	MODIFY_MENU(popupMenu, POPUP_UNICODE, vCodeTable == 0);
	MODIFY_MENU(popupMenu, POPUP_TCVN3, vCodeTable == 1);
	MODIFY_MENU(popupMenu, POPUP_VNI_WINDOWS, vCodeTable == 2);
	MODIFY_MENU(otherCode, POPUP_UNICODE_COMPOUND, vCodeTable == 3);
	MODIFY_MENU(otherCode, POPUP_VN_LOCALE_1258, vCodeTable == 4);

	wstring hotkey = L"";
	bool hasAdd = false;
	if (convertToolHotKey & 0x100) {
		hotkey += L"Ctrl";
		hasAdd = true;
	}
	if (convertToolHotKey & 0x200) {
		if (hasAdd)
			hotkey += L" + ";
		hotkey += L"Alt";
		hasAdd = true;
	}
	if (convertToolHotKey & 0x400) {
		if (hasAdd)
			hotkey += L" + ";
		hotkey += L"Win";
		hasAdd = true;
	}
	if (convertToolHotKey & 0x800) {
		if (hasAdd)
			hotkey += L" + ";
		hotkey += L"Shift";
		hasAdd = true;
	}

	unsigned short k = ((convertToolHotKey >> 24) & 0xFF);
	if (k != 0xFE) {
		if (hasAdd)
			hotkey += L" + ";
		if (k == VK_SPACE)
			hotkey += L"Space";
		else
			hotkey += (wchar_t)k;
	}

	wstring hotKeyString = menuData[POPUP_QUICK_CONVERT];
	if (hasAdd) {
		hotKeyString += L" - [";
		hotKeyString += hotkey;
		hotKeyString += L"]";
	}
	ModifyMenu(popupMenu, POPUP_QUICK_CONVERT, MF_BYCOMMAND | MF_UNCHECKED, POPUP_QUICK_CONVERT, hotKeyString.c_str());
}

static HINSTANCE ins;
static int recreateCount = 0;

void SystemTrayHelper::_createSystemTrayIcon(const HINSTANCE& hIns) {
	HWND hWnd = createFakeWindow(ins);
	
	if (hWnd == NULL) { //Use timer to create
		if (recreateCount >= 5) {
			// [MINDFUL] Thử 5 lần không tạo được cửa sổ khay -> app không còn mặt nào để hiện. Trước
			// đây thoát CÂM (audit 2026-07-18 win-silent-trayfail-1) — người dùng thấy app "mở rồi
			// biến mất" y hệt lỗi P0 bên macOS. Nói trước khi thoát (§6.3). Giữ nguyên việc thoát.
			MessageBoxW(NULL,
				L"MindfulKey không tạo được biểu tượng ở khay hệ thống nên sẽ thoát. Hãy thử mở lại; "
				L"nếu vẫn vậy, khởi động lại máy thường khắc phục được.",
				L"MindfulKey", MB_OK | MB_ICONWARNING | MB_SETFOREGROUND);
			PostQuitMessage(0);
			return;
		}
		ins = hIns;
		SetTimer(NULL, 0, 1000 * 3, (TIMERPROC)&WaitToCreateFakeWindow);
		++recreateCount;
		return;
	}
	createPopupMenu();

	//create system tray
	nid.cbSize = sizeof(NOTIFYICONDATA);
	nid.hWnd = hWnd;
	nid.uID = TRAY_ICONUID;
	nid.uVersion = NOTIFYICON_VERSION;
	nid.uCallbackMessage = WM_TRAYMESSAGE;
	loadTrayIcon();
	LoadString(ins, IDS_APP_TITLE, nid.szTip, 128);
	nid.uFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP;

	// Shell_NotifyIcon may fail if the system tray icon is not fully initialized
	const int maxRetries = 5;
	for (int attempt = 0; attempt < maxRetries; ++attempt) {
		if (Shell_NotifyIcon(NIM_ADD, &nid)) {
			break;
		}
		Sleep(1000);
	}
}


void CALLBACK SystemTrayHelper::WaitToCreateFakeWindow(HWND hwnd, UINT uMsg, UINT timerId, DWORD dwTime) {
	_createSystemTrayIcon(ins);
	KillTimer(0, timerId);
}

void SystemTrayHelper::createSystemTrayIcon(const HINSTANCE& hIns) {
	_createSystemTrayIcon(hIns);
}

void SystemTrayHelper::removeSystemTray() {
	Shell_NotifyIcon(NIM_DELETE, &nid);
}
// [MINDFUL] GĐ6 — gọi được từ BẤT KỲ luồng nào (MoodWatch gọi từ worker). Chỉ đặt tin nhắn rồi
// về ngay; mọi việc đụng UI xảy ra trên luồng cửa sổ. Xem WM_WAVE_ALERT ở trên.
void SystemTrayHelper::showWaveAlert() {
	if (nid.hWnd)
		PostMessage(nid.hWnd, WM_WAVE_ALERT, 0, 0);
}

// [MINDFUL] Nhờ luồng cửa sổ kiểm "OpenKey gốc đang chạy?" rồi cảnh báo nếu có — CHỈ đặt tin nhắn,
// không tự kiểm/hiện tại đây, để hộp thoại nổ SAU khi vòng lặp thông điệp chạy (xem WM_MK_RIVAL_WARN).
void SystemTrayHelper::checkRivalInputMethod() {
	if (nid.hWnd)
		PostMessage(nid.hWnd, WM_MK_RIVAL_WARN, 0, 0);
}
