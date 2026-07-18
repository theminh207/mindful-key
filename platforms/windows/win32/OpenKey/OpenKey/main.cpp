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
#include "stdafx.h"
#include "AppDelegate.h"
#include <Shlobj.h>

int APIENTRY wWinMain(_In_ HINSTANCE hInstance,
						_In_opt_ HINSTANCE hPrevInstance,
						_In_ LPWSTR    lpCmdLine,
						_In_ int       nCmdShow)
{
	UNREFERENCED_PARAMETER(hPrevInstance);
	UNREFERENCED_PARAMETER(lpCmdLine);
	
#if NDEBUG
	//check the program is run as administrator mode
	APP_GET_DATA(vRunAsAdmin, 0);
	if (vRunAsAdmin && !IsUserAnAdmin()) {
		//create admin process
		// [MINDFUL] Nếu người dùng bấm "No" ở hộp UAC (hoặc nâng quyền lỗi), tiến trình đã-nâng-quyền
		// KHÔNG khởi động — mà dòng return 1 dưới đây thoát ngay, nên app "biến mất" không một lời
		// (audit 2026-07-18 win-silent-admin-1, đúng §6.3 "không chết câm"). ShellExecute trả HINSTANCE
		// <= 32 nghĩa là không mở được tiến trình. MessageBox ở đây an toàn: chỉ nổ khi vừa có tương
		// tác UAC (app đang foreground), và app thoát ngay sau — không phải modal chặn lúc dựng UI.
		HINSTANCE elevated = ShellExecute(0, L"runas", OpenKeyHelper::getFullPath().c_str(), 0, 0, SW_SHOWNORMAL);
		if ((INT_PTR)elevated <= 32) {
			MessageBoxW(NULL,
				L"MindfulKey được đặt chạy với quyền quản trị, nhưng lần này chưa được cấp quyền đó "
				L"nên chưa mở lên.\n\nHãy mở lại và chọn \"Yes\" khi Windows hỏi quyền quản trị.",
				L"MindfulKey", MB_OK | MB_ICONINFORMATION | MB_SETFOREGROUND);
		}
		return 1;
	}
#endif
	AppDelegate app;
	return app.run(hInstance);
}