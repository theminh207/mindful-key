//
// UpdateChecker.cpp — xem UpdateChecker.h.
//
// [MINDFUL] Thiết kế an toàn CÓ CHỦ ĐÍCH — đọc trước khi sửa:
// 1. Tải qua HTTPS (WinINet tự bắt TLS theo scheme) từ ĐÚNG domain GitHub — không tự chế endpoint lạ.
// 2. Mở file tải về bằng ShellExecuteW, KHÔNG BAO GIỜ CreateProcess thẳng. ShellExecute đi qua đúng
//    đường Windows Explorer vẫn đi (Mark-of-the-Web + SmartScreen) — TUYỆT ĐỐI không né tránh cảnh
//    báo hệ thống dành cho file tải từ Internet. Một app tự tải-rồi-tự-chạy mà LÁCH kiểm tra này thì
//    hành vi không khác gì malware — đây là ranh giới không được vượt qua dù mục đích là chính đáng.
// 3. Mọi lỗi (mạng rớt, JSON đổi cấu trúc, tải hỏng, mở thất bại) đều lùi về hành vi CŨ (mở trang
//    Releases) — không bao giờ để nút bấm rơi vào im lặng không phản hồi.
// 4. Chưa có SignPath (ký số) — bộ cài .exe tải về vẫn CHƯA có chữ ký, SmartScreen vẫn có thể cảnh
//    báo "Windows đã bảo vệ PC của bạn" lúc mở. Đây là hạn chế THẬT, không phải lỗi code — hết khi
//    D4 (SignPath) xong. Ghi trong docs/FRICTION-LOG.md.
//
#include "stdafx.h"
#include "UpdateChecker.h"
#include "MindfulKeyManager.h"
#include "MindfulKeyHelper.h"
#include <wininet.h>
#include <shellapi.h>

#pragma comment(lib, "wininet.lib")

using namespace std;

static const wchar_t* kApiUrl = L"https://api.github.com/repos/theminh207/mindful-key/releases/latest";
static const wchar_t* kRepoOwner = L"theminh207";
static const wchar_t* kRepoName = L"mindful-key";
static const wchar_t* kUserAgent = L"MindfulKey-UpdateChecker";

// Đọc trọn 1 URL qua HTTP GET, trả nội dung dạng byte thô (JSON là UTF-8/ASCII nên string thường đủ
// dùng — không cần chuyển mã). Trả false nếu bất kỳ bước nào lỗi (DNS, mạng, HTTP status xấu).
static bool HttpGetBody(const wchar_t* url, string& outBody) {
    HINTERNET hInternet = InternetOpenW(kUserAgent, INTERNET_OPEN_TYPE_PRECONFIG, NULL, NULL, 0);
    if (!hInternet) return false;
    HINTERNET hUrl = InternetOpenUrlW(hInternet, url, NULL, 0,
        INTERNET_FLAG_RELOAD | INTERNET_FLAG_NO_CACHE_WRITE | INTERNET_FLAG_SECURE, 0);
    if (!hUrl) { InternetCloseHandle(hInternet); return false; }

    DWORD statusCode = 0, statusSize = sizeof(statusCode);
    HttpQueryInfoW(hUrl, HTTP_QUERY_STATUS_CODE | HTTP_QUERY_FLAG_NUMBER, &statusCode, &statusSize, NULL);
    // statusCode==0: một số cấu hình proxy không lộ status qua handle này dù request thật ra vẫn OK —
    // KHÔNG coi là lỗi cứng, chỉ chặn khi biết chắc status xấu (4xx/5xx).
    if (statusCode != 0 && statusCode != 200) {
        InternetCloseHandle(hUrl);
        InternetCloseHandle(hInternet);
        return false;
    }

    char buf[4096];
    DWORD read = 0;
    outBody.clear();
    while (InternetReadFile(hUrl, buf, sizeof(buf), &read) && read > 0) {
        outBody.append(buf, read);
        if (outBody.size() > 2 * 1024 * 1024) break;   // trần an toàn 2MB — JSON release thật nhỏ hơn nhiều
    }
    InternetCloseHandle(hUrl);
    InternetCloseHandle(hInternet);
    return !outBody.empty();
}

// Tải nhị phân 1 URL xuống file đích. Trả false nếu lỗi ở BẤT KỲ bước nào (tự dọn file dở nếu có).
static bool HttpDownloadFile(const wchar_t* url, const wstring& destPath) {
    HINTERNET hInternet = InternetOpenW(kUserAgent, INTERNET_OPEN_TYPE_PRECONFIG, NULL, NULL, 0);
    if (!hInternet) return false;
    HINTERNET hUrl = InternetOpenUrlW(hInternet, url, NULL, 0,
        INTERNET_FLAG_RELOAD | INTERNET_FLAG_NO_CACHE_WRITE | INTERNET_FLAG_SECURE, 0);
    if (!hUrl) { InternetCloseHandle(hInternet); return false; }

    DWORD statusCode = 0, statusSize = sizeof(statusCode);
    HttpQueryInfoW(hUrl, HTTP_QUERY_STATUS_CODE | HTTP_QUERY_FLAG_NUMBER, &statusCode, &statusSize, NULL);
    if (statusCode != 0 && statusCode != 200) {
        InternetCloseHandle(hUrl);
        InternetCloseHandle(hInternet);
        return false;
    }

    HANDLE hFile = CreateFileW(destPath.c_str(), GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    if (hFile == INVALID_HANDLE_VALUE) {
        InternetCloseHandle(hUrl);
        InternetCloseHandle(hInternet);
        return false;
    }

    char buf[8192];
    DWORD read = 0;
    bool ok = true;
    while (InternetReadFile(hUrl, buf, sizeof(buf), &read) && read > 0) {
        DWORD written = 0;
        if (!WriteFile(hFile, buf, read, &written, NULL) || written != read) { ok = false; break; }
    }
    CloseHandle(hFile);
    InternetCloseHandle(hUrl);
    InternetCloseHandle(hInternet);
    if (!ok) DeleteFileW(destPath.c_str());
    return ok;
}

// Tách "tag_name":"vX.Y.Z" khỏi JSON thô — KHÔNG viết bộ phân tích JSON đầy đủ (tránh kéo thư viện
// ngoài cho 1 giá trị). Chỉ tìm đúng 1 khoá cố định trong response của GitHub — nguồn đáng tin, cấu
// trúc ổn định, không phải dữ liệu người dùng nhập tuỳ ý.
static bool ExtractTagName(const string& json, wstring& outTag) {
    const string key = "\"tag_name\":\"";
    size_t pos = json.find(key);
    if (pos == string::npos) return false;
    pos += key.size();
    size_t end = json.find('"', pos);
    if (end == string::npos) return false;
    string tag = json.substr(pos, end - pos);
    if (tag.empty()) return false;
    outTag.assign(tag.begin(), tag.end());   // tag GitHub chỉ gồm ASCII (vd "v0.4.17")
    return true;
}

static bool ParseVersion(const wstring& s, int out[3]) {
    return swscanf(s.c_str(), L"%d.%d.%d", &out[0], &out[1], &out[2]) == 3;
}

// So theo bộ 3 số, KHÔNG so chuỗi (so chuỗi xếp sai thứ tự "0.4.9" sau "0.4.10"). Parse lỗi -> false
// (coi như không có bản mới — đừng đoán khi không chắc).
static bool IsNewer(wstring remote, const wstring& local) {
    if (!remote.empty() && (remote[0] == L'v' || remote[0] == L'V')) remote.erase(0, 1);
    int rv[3] = { 0, 0, 0 }, lv[3] = { 0, 0, 0 };
    if (!ParseVersion(remote, rv) || !ParseVersion(local, lv)) return false;
    for (int i = 0; i < 3; i++) {
        if (rv[i] != lv[i]) return rv[i] > lv[i];
    }
    return false;
}

void UpdateChecker_CheckAndUpdate(HWND owner) {
    string json;
    if (!HttpGetBody(kApiUrl, json)) {
        // Mạng lỗi / GitHub không phản hồi -> lùi về hành vi cũ, không để người dùng mắc kẹt.
        MindfulKeyManager::openReleasesPage();
        return;
    }

    wstring tag;
    if (!ExtractTagName(json, tag)) {
        MindfulKeyManager::openReleasesPage();
        return;
    }

    wstring localVer = MindfulKeyHelper::getVersionString();
    if (!IsNewer(tag, localVer)) {
        MessageBoxW(owner, L"Bạn đang dùng bản mới nhất.", L"Mindful Keyboard", MB_OK | MB_ICONINFORMATION);
        return;
    }

    wstring versionNoV = tag;
    if (!versionNoV.empty() && (versionNoV[0] == L'v' || versionNoV[0] == L'V')) versionNoV.erase(0, 1);

    wchar_t msg[320];
    wsprintfW(msg,
        L"Có bản cập nhật mới: %s (đang dùng %s).\n\n"
        L"Tải và cài ngay? Mindful Keyboard sẽ đóng lại trong lúc cài, rồi tự mở lại.",
        tag.c_str(), localVer.c_str());
    if (MessageBoxW(owner, msg, L"Mindful Keyboard", MB_YESNO | MB_ICONQUESTION) != IDYES) {
        return;
    }

    // Đường tải: GitHub Releases dùng đúng khuôn cố định "{repo}/releases/download/{tag}/{asset}".
    // Tên asset PHẢI khớp CHÍNH XÁC OutputBaseFilename trong .iss/release.yml — lệch tên là 404.
    wchar_t downloadUrl[512];
    wsprintfW(downloadUrl, L"https://github.com/%s/%s/releases/download/%s/MindfulKey_%s_x64-setup.exe",
        kRepoOwner, kRepoName, tag.c_str(), versionNoV.c_str());

    wchar_t tempDir[MAX_PATH];
    GetTempPathW(MAX_PATH, tempDir);
    wchar_t destPath[MAX_PATH];
    wsprintfW(destPath, L"%sMindfulKey_%s_x64-setup.exe", tempDir, versionNoV.c_str());

    HCURSOR oldCursor = SetCursor(LoadCursor(NULL, IDC_WAIT));
    bool downloaded = HttpDownloadFile(downloadUrl, destPath);
    SetCursor(oldCursor);

    if (!downloaded) {
        MessageBoxW(owner, L"Tải bản cập nhật không thành công. Mở trang tải về để cài thủ công.",
            L"Mindful Keyboard", MB_OK | MB_ICONWARNING);
        MindfulKeyManager::openReleasesPage();
        return;
    }

    // ShellExecute — KHÔNG CreateProcess. Đi đúng đường Explorer vẫn đi (Mark-of-the-Web/SmartScreen
    // xét file tải từ Internet) — xem cảnh báo đầu file. Bộ cài (.iss) tự đóng app đang chạy + gỡ bản
    // cũ + cài mới + tự mở lại app (AppMutex + CloseApplications=yes + [Run] postinstall có sẵn).
    HINSTANCE hExec = ShellExecuteW(owner, L"open", destPath, NULL, tempDir, SW_SHOWNORMAL);
    if ((INT_PTR)hExec <= 32) {
        MessageBoxW(owner, L"Không mở được trình cài đặt. Mở trang tải về để cài thủ công.",
            L"Mindful Keyboard", MB_OK | MB_ICONWARNING);
        MindfulKeyManager::openReleasesPage();
    }
}
