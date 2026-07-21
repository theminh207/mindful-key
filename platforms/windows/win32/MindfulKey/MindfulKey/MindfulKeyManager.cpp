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
#include "MindfulKeyManager.h"
#include <shlobj.h>

static vector<LPCTSTR> _inputType = {
	_T("Telex"),
	_T("VNI"),
	_T("Simple Telex"),
};

static vector<LPCTSTR> _tableCode = {
	_T("Unicode"),
	_T("TCVN3 (ABC)"),
	_T("VNI Windows"),
	_T("Unicode Tổ hợp"),
	_T("Vietnamese Locale CP 1258")
};

/*-----------------------------------------------------------------------*/

extern void MindfulKeyInit();
extern void MindfulKeyFree();

unsigned short  MindfulKeyManager::_lastKeyCode = 0;

vector<LPCTSTR>& MindfulKeyManager::getInputType() {
	return _inputType;
}

vector<LPCTSTR>& MindfulKeyManager::getTableCode() {
	return _tableCode;
}

void MindfulKeyManager::initEngine() {
	MindfulKeyInit();
}

void MindfulKeyManager::freeEngine() {
	MindfulKeyFree();
}

// [MINDFUL] 2026-07-17 — chủ dự án chốt: nút "Kiểm tra bản mới" mở thẳng trang Releases.
//
// Bản trước hỏng ở BA tầng, không tầng nào lộ ra lúc build:
//   1. Nó tải https://raw.githubusercontent.com/tuyenvm/MindfulKey/master/version.json — repo của
//      MindfulKey GỐC. App của ta đi hỏi phiên bản của người khác, rồi đem so với chính mình.
//   2. So với cái gì? VERSIONINFO trong .rc ghi 2.0.5.0 — cũng là số của MindfulKey (version.env
//      của dự án là 0.2.1). Hai số sai đem so nhau.
//   3. Người dùng bấm "có, cập nhật" -> chạy MindfulKeyUpdate.exe, tệp mà bộ cài KHÔNG kèm. Nếu có
//      thì nó tải về... bản MindfulKey.
// Cộng thêm: một cú gọi mạng ra repo bên thứ ba mỗi lần khởi động (nếu bật vCheckNewVersion).
//
// Nay: không gọi mạng, không so phiên bản, không updater. Mở trang Releases để người dùng tự
// nhìn bản mới nhất — thành thật về thứ ta thật sự biết.
void MindfulKeyManager::openReleasesPage() {
	ShellExecute(NULL, _T("open"), _T("https://github.com/theminh207/mindful-key/releases"), NULL, NULL, SW_SHOWNORMAL);
}


void MindfulKeyManager::createDesktopShortcut() {
	CoInitialize(NULL);
	IShellLink* pShellLink = NULL;
	HRESULT hres;
	hres = CoCreateInstance(CLSID_ShellLink, NULL, CLSCTX_ALL,
							IID_IShellLink, (void**)&pShellLink);
	if (SUCCEEDED(hres)) {
		wstring path = MindfulKeyHelper::getFullPath();
		pShellLink->SetPath(path.c_str());
		pShellLink->SetDescription(_T("MindfulKey - Bộ gõ Tiếng Việt"));
		pShellLink->SetIconLocation(path.c_str(), 0);

		IPersistFile* pPersistFile;
		hres = pShellLink->QueryInterface(IID_IPersistFile, (void**)&pPersistFile);

		if (SUCCEEDED(hres)) {
			wchar_t desktopPath[MAX_PATH + 1];
			wchar_t savePath[MAX_PATH + 10];
			SHGetFolderPath(NULL, CSIDL_DESKTOP, NULL, 0, desktopPath);
			wsprintf(savePath, _T("%s\\MindfulKey.lnk"), desktopPath);
			hres = pPersistFile->Save(savePath, TRUE);
			pPersistFile->Release();
			pShellLink->Release();
		}
	}
}
