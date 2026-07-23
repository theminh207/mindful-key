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
#include "AppDelegate.h"

extern void TrayPopover_Init(HINSTANCE hInstance);
extern void TrayPopover_Uninit();

static AppDelegate* _instance;

//see document in Engine.h
int vLanguage = 1;
int vInputType = 0;
int vFreeMark = 0;
int vCodeTable = 0;
int vCheckSpelling = 1;
int vUseModernOrthography = 1;
int vQuickTelex = 0;
#define DEFAULT_SWITCH_STATUS 0x5A00025A //default option + z
int vSwitchKeyStatus = DEFAULT_SWITCH_STATUS;
int vRestoreIfWrongSpelling = 1;
int vFixRecommendBrowser = 0;
int vUseMacro = 1;
int vUseMacroInEnglishMode = 1;
int vAutoCapsMacro = 0;
int vSendKeyStepByStep = 1;
int vUseSmartSwitchKey = 1;
int vUpperCaseFirstChar = 0;
int vTempOffSpelling = 0;
int vAllowConsonantZFWJ = 0;
int vQuickStartConsonant = 0;
int vQuickEndConsonant = 0;
int vOtherLanguage = 1;
int vRememberCode = 1;
int vTempOffMindfulKey = 0;

int vUseGrayIcon = 0;
int vShowOnStartUp = 0;
int vRunWithWindows = 1;

int vSupportMetroApp = 1;
int vCreateDesktopShortcut = 0;
int vRunAsAdmin = 0;
int vCheckNewVersion = 0;
//beta feature
int vFixChromiumBrowser = 0; //new on version 2.0

bool AppDelegate::isDialogMsg(MSG & msg) const {
	return (mainDialog != NULL && IsDialogMessage(mainDialog->getHwnd(), &msg)) ||
		(macroDialog != NULL && IsDialogMessage(macroDialog->getHwnd(), &msg)) || 
		(convertDialog != NULL && IsDialogMessage(convertDialog->getHwnd(), &msg)) || 
		(aboutDialog != NULL && IsDialogMessage(aboutDialog->getHwnd(), &msg));
}

void AppDelegate::checkUpdate() {
	// [MINDFUL] 2026-07-17 — CỐ Ý rỗng, không xoá hàm: `vCheckNewVersion` vẫn còn checkbox trong
	// cửa sổ Điều khiển và onInit() vẫn gọi vào đây.
	//
	// Bản cũ GỌI MẠNG NGẦM lúc khởi động tới repo MindfulKey gốc (raw.githubusercontent.com/tuyenvm/
	// MindfulKey) — app đi hỏi phiên bản của người khác mà người dùng không hề biết. Bỏ hẳn.
	//
	// KHÔNG thay bằng "tự mở trang Releases lúc khởi động": bật trình duyệt khi chưa ai yêu cầu là
	// HỐI THÚC, thứ HIẾN CHƯƠNG cấm. Kiểm bản mới là hành động CHỦ ĐỘNG — người dùng bấm nút trong
	// hộp Giới thiệu.
	//
	// Hệ quả: checkbox "Kiểm tra bản mới" nay không điều khiển gì. Bỏ 1 checkbox khỏi UI là quyết
	// định của chủ dự án, không phải của tôi — đã ghi docs/FRICTION-LOG.md 2026-07-17.
}

AppDelegate::AppDelegate() {
	_instance = this;
}

AppDelegate * AppDelegate::getInstance() {
	return _instance;
}

int AppDelegate::run(HINSTANCE hInstance) {
	this->hInstance = hInstance;

	// [MINDFUL] 2026-07-18 — mutex có TÊN, sống suốt vòng đời tiến trình. KHÔNG dùng để tự kiểm
	// (FindWindow ngay dưới vẫn làm việc đó) — mục đích DUY NHẤT là để bộ cài NHÌN THẤY được app
	// đang chạy: Inno Setup 6 AppMutex (platforms/windows/installer/MindfulKey.iss) kiểm mutex
	// CÙNG TÊN này lúc Setup VÀ Uninstall khởi động, và nếu thấy tồn tại thì CHẶN CỨNG bằng hộp
	// thoại "hãy đóng ứng dụng trước" — khác hẳn FindWindow(APP_CLASS) là thứ Setup không biết soi
	// tới. Audit 2026-07-18 (D3-E) chỉ ra trước khi vá: gỡ cài không có cách nào tự đóng app đang
	// chạy — người dùng "gỡ" mà hook bàn phím vẫn sống, tưởng đã sạch mà chưa. Handle KHÔNG cần tự
	// đóng — hệ điều hành giải phóng mutex khi tiến trình chết, dù chết kiểu gì.
	CreateMutexW(NULL, FALSE, L"MindfulKeyboardAppMutex");

	//check app has already run or not
	HWND previousInstance = FindWindow(APP_CLASS, NULL);
	if (previousInstance) {
		MessageBeep(MB_OK);
		// [MINDFUL] 2026-07-18 (audit DIM1-F) — SendMessage xuyên tiến trình KHÔNG timeout từng
		// đứng ở đây: nếu bản đang chạy vì lý do gì đó không bơm được thông điệp (treo), lệnh gọi
		// này CHỜ VĨNH VIỄN — và lúc đó tiến trình MỚI này chưa có cửa sổ/khay/vòng lặp nào, nên nó
		// treo vô hình y hệt sự cố 0.3.0, chỉ khác nguyên nhân. SendMessageTimeout với
		// SMTO_ABORTIFHUNG đặt trần 3s: bản cũ khoẻ mạnh vẫn nhận được tin nhắn bình thường (đường
		// đi không đổi); bản cũ treo thì sau 3s ta BỎ QUA nó và tự thoát như cũ — không góp thêm
		// một tiến trình treo vô hình vào máy người dùng.
		SendMessageTimeoutW(previousInstance, WM_USER + 2019, 0, 0,
			SMTO_ABORTIFHUNG | SMTO_BLOCK, 3000, NULL);
		PostQuitMessage(0);
		return 0;
	}

	//init MindfulKey Engine
	MindfulKeyManager::initEngine();

	//create system tray
	SystemTrayHelper::createSystemTrayIcon(hInstance);
	TrayPopover_Init(hInstance);
	SystemTrayHelper::updateData();

	// [MINDFUL] Khay đã có -> nhờ luồng cửa sổ cảnh báo nếu MindfulKey gốc đang chạy (hai bộ gõ giẫm
	// phím nhau, chữ sai dấu). Deferred qua PostMessage, KHÔNG chặn khởi động — xem
	// docs/LIFECYCLE-SAFETY-CONTRACT.md. Nhờ APP_CLASS nay đã riêng (stdafx.h), FindWindow ở trên
	// không còn nhầm MindfulKey gốc là "bản thứ 2 của mình" và tự thoát nữa.
	SystemTrayHelper::checkRivalInputMethod();

	//create main control
	if (vShowOnStartUp)
		createMainDialog();
	MessageBeep(MB_OK);

	//check update
	if (vCheckNewVersion)
		checkUpdate();

	MSG msg;
	// Main message loop:
	while (GetMessage(&msg, nullptr, 0, 0))	{
		if (msg.message == WM_KEYDOWN) {
			MindfulKeyManager::_lastKeyCode = (UINT16)msg.wParam;
		}
		if (!isDialogMsg(msg)) {
			TranslateMessage(&msg);
			DispatchMessage(&msg);
		}
	}
	return 0;
}

void AppDelegate::createMainDialog() {
	if (mainDialog == NULL) {
		mainDialog = new MainControlDialog(hInstance, IDD_DIALOG_MAIN);
		mainDialog->show();
	} else {
		mainDialog->bringOnTop();
	}
}

void AppDelegate::closeDialog(BaseDialog * dialog) {
	dialog->closeDialog();
	if (mainDialog == dialog) {
		delete mainDialog;
		mainDialog = NULL;
	} else if (aboutDialog == dialog) {
		delete aboutDialog;
		aboutDialog = NULL;
	} else if (macroDialog == dialog) {
		delete macroDialog;
		macroDialog = NULL;
	} else if (convertDialog == dialog) {
		delete convertDialog;
		convertDialog = NULL;
	}
}

void AppDelegate::onInputMethodChangedFromHotKey() {
	APP_SET_DATA(vLanguage, vLanguage);
	if (mainDialog) {
		mainDialog->fillData();
	}
	SystemTrayHelper::updateData();
}

void AppDelegate::onDefaultConfig() {
	APP_SET_DATA(vLanguage, 1);
	APP_SET_DATA(vInputType, 0);
	vFreeMark = 0;
	APP_SET_DATA(vCodeTable, 0);
	APP_SET_DATA(vCheckSpelling, 1);
	APP_SET_DATA(vUseModernOrthography, 0);
	APP_SET_DATA(vQuickTelex, 0);
	APP_SET_DATA(vSwitchKeyStatus, DEFAULT_SWITCH_STATUS);
	APP_SET_DATA(vRestoreIfWrongSpelling, 1);
	APP_SET_DATA(vFixRecommendBrowser, 1);
	APP_SET_DATA(vUseMacro, 0);
	APP_SET_DATA(vUseMacroInEnglishMode, 0);
	APP_SET_DATA(vSendKeyStepByStep, 1);
	APP_SET_DATA(vUseSmartSwitchKey, 1);
	APP_SET_DATA(vUpperCaseFirstChar, 0);
	APP_SET_DATA(vAllowConsonantZFWJ, 0);
	APP_SET_DATA(vTempOffSpelling, 0);

	APP_SET_DATA(vUseGrayIcon, 0);
	APP_SET_DATA(vShowOnStartUp, 1);
	APP_SET_DATA(vRunWithWindows, 1);

	APP_SET_DATA(vSupportMetroApp, 1);
	APP_SET_DATA(vRememberCode, 1);
	APP_SET_DATA(vOtherLanguage, 1);
	APP_SET_DATA(vTempOffMindfulKey, 0);
	APP_SET_DATA(vFixChromiumBrowser, 0);

	if (mainDialog) {
		mainDialog->fillData();
	}
	SystemTrayHelper::updateData();
}

void AppDelegate::onToggleVietnamese() {
	APP_SET_DATA(vLanguage, vLanguage ? 0 : 1);
	if (mainDialog) {
		mainDialog->fillData();
	}
	
	if (vUseSmartSwitchKey) {
		string& exe = MindfulKeyHelper::getLastAppExecuteName();
		setAppInputMethodStatus(exe, vLanguage | (vCodeTable << 1));
		saveSmartSwitchKeyData();
	}
}

void AppDelegate::onToggleCheckSpelling() {
	APP_SET_DATA(vCheckSpelling, vCheckSpelling ? 0 : 1);
	if (mainDialog) {
		mainDialog->fillData();
	}
	vSetCheckSpelling();
}

void AppDelegate::onToggleUseSmartSwitchKey() {
	APP_SET_DATA(vUseSmartSwitchKey, vUseSmartSwitchKey ? 0 : 1);
	if (mainDialog) {
		mainDialog->fillData();
	}
}

void AppDelegate::onToggleUseMacro() {
	APP_SET_DATA(vUseMacro, vUseMacro ? 0 : 1);
	if (mainDialog) {
		mainDialog->fillData();
	}
}

void AppDelegate::onMacroTable() {
	if (macroDialog == NULL) {
		macroDialog = new MacroDialog(hInstance, IDD_DIALOG_MACRO);
		macroDialog->show();
	} else {
		macroDialog->bringOnTop();
	}
}

void AppDelegate::onConvertTool() {
	if (convertDialog == NULL) {
		convertDialog = new ConvertToolDialog(hInstance, IDD_DIALOG_CONVERT_TOOL);
		convertDialog->show();
	} else {
		convertDialog->bringOnTop();
	}
}

void AppDelegate::onQuickConvert() {
	if (MindfulKeyHelper::quickConvert()) {
		//alert when complete
		if (!convertToolDontAlertWhenCompleted) {
			TCHAR msg[256];
			LoadString(hInstance, IDS_STRING_CONVERT_COMPLETED, msg, 256);
			MessageBox(NULL, msg, _T("Mindful Keyboard"), MB_OK);
		}
	}
}

void AppDelegate::onInputType(const int & type) {
	APP_SET_DATA(vInputType, type);
	if (mainDialog) {
		mainDialog->fillData();
	}
}

void AppDelegate::onTableCode(const int & code) {
	APP_SET_DATA(vCodeTable, code);
	if (mainDialog) {
		mainDialog->fillData();
	}
	if (vRememberCode) {
		setAppInputMethodStatus(MindfulKeyHelper::getFrontMostAppExecuteName(), vLanguage | (vCodeTable << 1));
		saveSmartSwitchKeyData();
	}
}

void AppDelegate::onControlPanel() {
	createMainDialog();
}

void AppDelegate::onMindfulKeyAbout() {
	if (aboutDialog == NULL) {
		aboutDialog = new AboutDialog(hInstance, IDD_ABOUTBOX);
		aboutDialog->show();
	} else {
		aboutDialog->bringOnTop();
	}
}

void AppDelegate::onMindfulKeyExit() {
	TrayPopover_Uninit();
	MindfulKeyManager::freeEngine();
	SystemTrayHelper::removeSystemTray();
	PostQuitMessage(0);
}
