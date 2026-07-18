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
#pragma once
#include "stdafx.h"

class SystemTrayHelper {
private:
	static void CALLBACK WaitToCreateFakeWindow(HWND hwnd, UINT uMsg, UINT timerId, DWORD dwTime);
	static HWND createFakeWindow(const HINSTANCE& hIns);
	static void createPopupMenu();

	static void _createSystemTrayIcon(const HINSTANCE& hIns);
public:
	static void createSystemTrayIcon(const HINSTANCE& hIns);
	static void updateData();
	// [MINDFUL] GĐ6 — "tâm đang động": icon khay đổi sang sóng biên độ cao rồi tự lắng về sau vài
	// giây (BRAND-ASSETS.md §6). An toàn gọi từ luồng nền.
	static void showWaveAlert();
	// [MINDFUL] Cảnh báo (deferred) nếu OpenKey gốc đang chạy cùng lúc — gọi SAU createSystemTrayIcon.
	static void checkRivalInputMethod();
	static void removeSystemTray();
};

