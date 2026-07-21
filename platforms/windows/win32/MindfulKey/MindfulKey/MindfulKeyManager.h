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
#pragma once
#include "stdafx.h"

class MindfulKeyManager {
public:
	static unsigned short _lastKeyCode;
	static vector<LPCTSTR>& getInputType();
	static vector<LPCTSTR>& getTableCode();

	static void initEngine();
	static void freeEngine();

	// Mở trang Releases trên GitHub. Thay cho checkUpdate() cũ — xem lý do ở .cpp.
	static void openReleasesPage();

	static void createDesktopShortcut();
};