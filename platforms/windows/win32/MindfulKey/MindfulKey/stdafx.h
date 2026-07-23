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

// stdafx.h : include file for standard system include files,
// or project specific include files that are used frequently, but
// are changed infrequently
//

#pragma once

#include "targetver.h"

#define WIN32_LEAN_AND_MEAN             // Exclude rarely-used stuff from Windows headers

// Windows Header Files
#include <windows.h>

// C RunTime Header Files
#include <stdlib.h>
#include <malloc.h>
#include <memory.h>
#include <tchar.h>
#include <string>
#include <vector>

#include <shellapi.h>
#include <Commctrl.h>
#include <psapi.h>

#include "resource.h"

#include "../../../../../core/engine/Engine.h"

#include "MindfulKeyManager.h"
#include "MindfulKeyHelper.h"
#include "SystemTrayHelper.h"

using namespace std;

extern wchar_t _logBuffer[1024];
#define LOG(...)  wsprintfW(_logBuffer, __VA_ARGS__); \
					OutputDebugString(_logBuffer);

#define APP_SET_DATA(KEY, VAL) KEY = VAL; MindfulKeyHelper::setRegInt(_T(#KEY), KEY)
#define APP_GET_DATA(KEY, DEFAULT_VAL) KEY = MindfulKeyHelper::getRegInt(_T(#KEY), DEFAULT_VAL)

// [MINDFUL] Tên lớp cửa sổ PHẢI khác OpenKey gốc. Bản gốc (Mai Vũ Tuyên) đăng ký cửa sổ ẩn với
// đúng chuỗi "OpenKeyVietnameseInputMethod"; fork này thừa hưởng y hệt, nên FindWindow(APP_CLASS)
// lúc khởi động (AppDelegate.cpp) BẮT trúng cửa sổ của OpenKey gốc, tưởng "mình đã chạy rồi" rồi
// tự thoát — trên MỌI máy đang chạy OpenKey, MindfulKey lặng lẽ không mở được (audit 2026-07-18,
// win-ime-conflict-1). Đổi sang chuỗi riêng của fork. Chuỗi cũ giữ lại làm dấu NHẬN DIỆN OpenKey
// gốc đang chạy (SystemTrayHelper cảnh báo giẫm phím) — xem RIVAL_MINDFULKEY_CLASS.
#define APP_CLASS          _T("MindfulKeyVietnameseInputMethod")
#define RIVAL_MINDFULKEY_CLASS _T("OpenKeyVietnameseInputMethod")

extern void saveSmartSwitchKeyData();

extern int vLanguage;
extern int vInputType;
extern int vFreeMark;
extern int vCodeTable;
extern int vCheckSpelling;
extern int vUseModernOrthography;
extern int vQuickTelex;
extern int vSwitchKeyStatus;
extern int vRestoreIfWrongSpelling;
extern int vFixRecommendBrowser;
extern int vUseMacro;
extern int vUseMacroInEnglishMode;
extern int vAutoCapsMacro;
extern int vSendKeyStepByStep;
extern int vUseSmartSwitchKey;
extern int vUpperCaseFirstChar;
extern int vUseGrayIcon;
extern int vShowOnStartUp;
extern int vRunWithWindows;
extern int vSupportMetroApp;
extern int vCreateDesktopShortcut;
extern int vRunAsAdmin;
extern int vCheckNewVersion;
extern int vRememberCode;
extern int vOtherLanguage;
extern int vTempOffMindfulKey;
extern int vFixChromiumBrowser;