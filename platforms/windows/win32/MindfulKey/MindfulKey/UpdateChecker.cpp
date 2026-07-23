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
    outBody.clear();
    // [MINDFUL] review (HIGH) — PHẢI phân biệt "lỗi mạng giữa chừng" (InternetReadFile trả FALSE) với
    // "EOF sạch" (trả TRUE + read==0). Vòng cũ `while(InternetReadFile(...) && read>0)` coi CẢ HAI là
    // dừng bình thường → body cụt vẫn bị coi như tải xong. Nay lỗi đọc = thất bại thật.
    bool ok = true;
    for (;;) {
        DWORD read = 0;
        if (!InternetReadFile(hUrl, buf, sizeof(buf), &read)) { ok = false; break; }
        if (read == 0) break;   // EOF thật
        outBody.append(buf, read);
        if (outBody.size() > 2 * 1024 * 1024) break;   // trần an toàn 2MB — JSON release thật nhỏ hơn nhiều
    }
    InternetCloseHandle(hUrl);
    InternetCloseHandle(hInternet);
    return ok && !outBody.empty();
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
    // [MINDFUL] review (HIGH) — CRITICAL cho luồng tự-chạy-file: lỗi mạng giữa chừng KHÔNG được coi là
    // tải xong. Vòng cũ chỉ đổi ok=false khi WriteFile lỗi; InternetReadFile trả FALSE (rớt mạng) thì
    // thoát êm với ok=true → .exe cụt/rỗng vẫn được ShellExecute chạy. Nay: lỗi đọc = thất bại; file
    // rỗng (totalWritten==0) cũng = thất bại — KHÔNG BAO GIỜ chạy một file cài dở/trống.
    bool ok = true;
    DWORD totalWritten = 0;
    for (;;) {
        DWORD read = 0;
        if (!InternetReadFile(hUrl, buf, sizeof(buf), &read)) { ok = false; break; }
        if (read == 0) break;   // EOF thật
        DWORD written = 0;
        if (!WriteFile(hFile, buf, read, &written, NULL) || written != read) { ok = false; break; }
        totalWritten += written;
    }
    CloseHandle(hFile);
    InternetCloseHandle(hUrl);
    InternetCloseHandle(hInternet);
    if (!ok || totalWritten == 0) { DeleteFileW(destPath.c_str()); return false; }
    return true;
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
    // [MINDFUL] SECURITY (review) — tag phiên bản THẬT rất ngắn ("v0.4.17"). Dài bất thường = JSON
    // lỗi/bị chèn độc → CHẶN. Đây là hàng rào chống TRÀN BUFFER: tag đi thẳng vào wsprintfW ghép URL/
    // đường dẫn/thông báo trên stack, mà wsprintfW KHÔNG tự kiểm cỡ buffer. Chặn ở nguồn là chắc nhất.
    if (tag.empty() || tag.size() > 40) return false;
    outTag.assign(tag.begin(), tag.end());   // tag GitHub chỉ gồm ASCII (vd "v0.4.17")
    return true;
}

// Parse "X.Y.Z" ra 3 số (bỏ hậu tố sau số thứ 3, vd "-beta"). KHÔNG dùng swscanf: MSVC coi nó C4996
// (unsafe CRT) = LỖI build, còn mingw không bắt (khe hở proxy). Tự tách thủ công chạy giống nhau mọi
// trình biên dịch + không dính rủi ro CRT-security. Trả false nếu không đủ 3 nhóm số.
static bool ParseVersion(const wstring& s, int out[3]) {
    out[0] = out[1] = out[2] = 0;
    int idx = 0;
    bool sawDigit = false;
    for (size_t i = 0; i < s.size() && idx < 3; i++) {
        wchar_t c = s[i];
        if (c >= L'0' && c <= L'9') {
            out[idx] = out[idx] * 10 + (c - L'0');
            sawDigit = true;
        } else if (c == L'.') {
            if (!sawDigit) return false;   // dấu chấm dẫn đầu hoặc ".."
            idx++;
            sawDigit = false;
        } else {
            break;   // ký tự khác (hậu tố "-beta"...) -> dừng, giữ những gì đã parse
        }
    }
    return idx == 2 && sawDigit;   // đủ 3 nhóm: 2 dấu chấm + nhóm cuối có chữ số
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
    // [MINDFUL] review (MEDIUM) — nếu ĐỌC version cục bộ lỗi, getVersionString trả "0.0.0". Đừng đem
    // 0.0.0 đi so (mọi bản đều "mới hơn" → báo NHẦM có cập nhật, tải bừa). Không đọc được thì mở trang
    // để người dùng tự nhìn, KHÔNG đoán.
    int lv[3] = { 0, 0, 0 };
    if (!ParseVersion(localVer, lv) || (lv[0] == 0 && lv[1] == 0 && lv[2] == 0)) {
        MindfulKeyManager::openReleasesPage();
        return;
    }
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
    DWORD tlen = GetTempPathW(MAX_PATH, tempDir);
    if (tlen == 0 || tlen > MAX_PATH) {   // [MINDFUL] review — thất bại thì tempDir là rác chưa khởi tạo
        MindfulKeyManager::openReleasesPage();
        return;
    }
    wchar_t destPath[MAX_PATH + 64];   // [MINDFUL] review — tempDir(≤MAX_PATH) + tên tệp có thể vượt MAX_PATH
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
