//
// MoodStore.cpp — [MINDFUL] xem MoodStore.h cho hợp đồng đầy đủ + 2 khác biệt so với macOS.
//
#include "stdafx.h"
#include "MoodStore.h"
#include <shlobj.h>
#include <wincrypt.h>
#include <vector>
#include <sstream>
#include <mutex>

#pragma comment(lib, "crypt32.lib")

using namespace std;

static LPCTSTR kRegConsent      = _T("vMoodStoreConsent");
static LPCTSTR kRegAskedConsent = _T("vMoodStoreAskedConsent");

// Dòng đầu tệp. Đổi schema về sau -> tăng số, đọc số này để biết cách phân giải dòng cũ.
// macOS phải ALTER TABLE khi thêm cột (xem MoodStoreMac.mm "MIGRATION ĐẦU TIÊN"); tệp phẳng thì
// chỉ cần dòng thiếu trường = trường rỗng, nhưng vẫn cần số hiệu để biết mình đang đọc đời nào.
static const wchar_t* kFileHeader = L"mindful-key mood v1";

// Ghi/đọc nối tiếp: nhịp lấy mẫu (luồng timer) và gác cổng (luồng hộp thoại) đều ghi.
static mutex g_mutex;

// ── Đường dẫn ──

static wstring StorePath() {
    TCHAR appData[MAX_PATH];
    if (FAILED(SHGetFolderPath(NULL, CSIDL_LOCAL_APPDATA, NULL, 0, appData)))
        return wstring();
    wstring dir = wstring(appData) + _T("\\MindfulKeyboard");
    CreateDirectory(dir.c_str(), NULL);
    return dir + _T("\\mood.enc");
}

// ── Mã hoá (DPAPI) ──

static bool Protect(const wstring& plain, vector<BYTE>& out) {
    DATA_BLOB in, blob;
    in.pbData = (BYTE*)plain.c_str();
    in.cbData = (DWORD)((plain.size() + 1) * sizeof(wchar_t));
    // Mô tả hiện trong hộp thoại DPAPI của Windows nếu có — đặt tên nói thật.
    // CRYPTPROTECT_UI_FORBIDDEN: KHÔNG hiện hộp thoại nào. Hàm này chạy từ luồng nền (nhịp lấy
    // mẫu) — bật hộp thoại ở đó là treo app mà người dùng không hiểu vì sao.
    if (!CryptProtectData(&in, L"Mindful Keyboard - nhat ky cam xuc", NULL, NULL, NULL,
                          CRYPTPROTECT_UI_FORBIDDEN, &blob))
        return false;
    out.assign(blob.pbData, blob.pbData + blob.cbData);
    LocalFree(blob.pbData);
    return true;
}

static bool Unprotect(const vector<BYTE>& cipher, wstring& out) {
    if (cipher.empty()) return false;
    DATA_BLOB in, blob;
    in.pbData = (BYTE*)&cipher[0];
    in.cbData = (DWORD)cipher.size();
    if (!CryptUnprotectData(&in, NULL, NULL, NULL, NULL, CRYPTPROTECT_UI_FORBIDDEN, &blob))
        return false;   // tệp của tài khoản/máy khác -> đọc không được. Đúng thiết kế.
    out.assign((wchar_t*)blob.pbData, blob.cbData / sizeof(wchar_t));
    while (!out.empty() && out.back() == L'\0')
        out.pop_back();
    LocalFree(blob.pbData);
    return true;
}

// ── Đọc/ghi cả tệp ──
// CỐ Ý mã hoá TOÀN TỆP rồi ghi đè, thay vì mã hoá từng dòng rồi nối đuôi:
//   - DPAPI gắn ~200 byte header cho MỖI blob. Mỗi dòng ~50 byte -> phí gấp 5 lần dữ liệu thật.
//   - Nhịp ghi rất thưa (mỗi 15-60 phút 1 mẫu + vài lần gác cổng/ngày), tệp cả năm cũng chỉ
//     vài trăm KB -> đọc-sửa-ghi cả tệp là rẻ.
// Đổi lại phải ghi NGUYÊN TỬ, xem WriteAll().

static bool ReadAll(wstring& out) {
    wstring path = StorePath();
    if (path.empty()) return false;
    HANDLE f = CreateFile(path.c_str(), GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING,
                          FILE_ATTRIBUTE_NORMAL, NULL);
    if (f == INVALID_HANDLE_VALUE) return false;   // chưa có tệp = chưa ghi gì, không phải lỗi
    DWORD size = GetFileSize(f, NULL);
    vector<BYTE> cipher;
    bool ok = false;
    if (size != INVALID_FILE_SIZE && size > 0 && size < 100u * 1024 * 1024) {
        cipher.resize(size);
        DWORD read = 0;
        ok = ReadFile(f, &cipher[0], size, &read, NULL) && read == size;
    }
    CloseHandle(f);
    return ok && Unprotect(cipher, out);
}

static bool WriteAll(const wstring& plain) {
    wstring path = StorePath();
    if (path.empty()) return false;
    vector<BYTE> cipher;
    if (!Protect(plain, cipher) || cipher.empty()) return false;

    // Ghi ra tệp tạm rồi mới thay: mất điện giữa chừng thì mất bản GHI, không mất cả NHẬT KÝ.
    // Ghi đè thẳng là có cửa sổ tệp cụt = mất sạch dữ liệu cũ.
    wstring tmp = path + _T(".tmp");
    HANDLE f = CreateFile(tmp.c_str(), GENERIC_WRITE, 0, NULL, CREATE_ALWAYS,
                          FILE_ATTRIBUTE_NORMAL, NULL);
    if (f == INVALID_HANDLE_VALUE) return false;
    DWORD written = 0;
    bool ok = WriteFile(f, &cipher[0], (DWORD)cipher.size(), &written, NULL) &&
              written == cipher.size();
    FlushFileBuffers(f);   // đẩy xuống đĩa TRƯỚC khi thay, không thì "nguyên tử" chỉ là danh nghĩa
    CloseHandle(f);
    if (!ok) {
        DeleteFile(tmp.c_str());
        return false;
    }
    if (!MoveFileEx(tmp.c_str(), path.c_str(), MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH)) {
        DeleteFile(tmp.c_str());
        return false;
    }
    return true;
}

// ── Consent ──

bool MoodStore_HasConsent() {
    return MindfulKeyHelper::getRegInt(kRegConsent, 0) != 0;
}

bool MoodStore_HasAskedConsent() {
    return MindfulKeyHelper::getRegInt(kRegAskedConsent, 0) != 0;
}

void MoodStore_SetConsent(bool granted) {
    MindfulKeyHelper::setRegInt(kRegConsent, granted ? 1 : 0);
    MindfulKeyHelper::setRegInt(kRegAskedConsent, 1);
    if (!granted)
        MoodStore_DeleteAll();   // rút lại đồng ý = xoá thật, không chỉ ngừng ghi
}

void MoodStore_AskConsentIfNeeded() {
    if (MoodStore_HasAskedConsent())
        return;   // hỏi MỘT lần trong đời, không hỏi lại mỗi lần khởi động

    int r = MessageBoxW(NULL,
        L"Mindful Keyboard có thể ghi lại một nhật ký cảm xúc nhỏ, để cuối ngày bạn nhìn lại.\n\n"
        L"Nhật ký này KHÔNG chứa nội dung bạn gõ — không câu chữ, không tin nhắn. Chỉ có: thời "
        L"điểm, một điểm số 0-1, và tên ứng dụng.\n\n"
        L"Nó nằm trên máy bạn, được Windows mã hoá theo tài khoản đang đăng nhập, và không gửi đi "
        L"đâu cả. Bạn xoá sạch được bất cứ lúc nào ở menu khay.\n\n"
        L"Bật nhật ký cảm xúc?",
        L"Mindful Keyboard", MB_YESNO | MB_ICONQUESTION);
    MoodStore_SetConsent(r == IDYES);
}

// ── Ghi sự kiện ──

// Một dòng TSV. Trường trống = rỗng. Tên/thứ tự trường BẤT BIẾN, khớp cột macOS:
//   ts, event_type, send_risk, app_bundle_id, choice, mood_label, intensity
static void AppendEvent(const wstring& eventType, double sendRisk,
                        const wstring& app, const wstring& choice) {
    if (!MoodStore_HasConsent())
        return;

    lock_guard<mutex> lock(g_mutex);

    wstring all;
    if (!ReadAll(all) || all.empty())
        all = wstring(kFileHeader) + L"\n";

    // Tab là dấu ngăn -> tên app chứa tab sẽ phá dòng. Tên tiến trình Windows không có tab, nhưng
    // đừng tin: thay cho chắc.
    wstring safeApp = app;
    for (size_t i = 0; i < safeApp.size(); i++)
        if (safeApp[i] == L'\t' || safeApp[i] == L'\n') safeApp[i] = L' ';

    wostringstream line;
    line << (long long)time(NULL) << L'\t'
         << eventType << L'\t';
    if (sendRisk >= 0) line << sendRisk;
    line << L'\t' << safeApp << L'\t' << choice << L'\t' << L'\t';   // mood_label, intensity: rỗng
    all += line.str() + L"\n";

    WriteAll(all);
}

void MoodStore_LogGatekeeperEvent(double sendRisk, const wstring& appExeName, const wstring& choice) {
    AppendEvent(L"gatekeeper", sendRisk, appExeName, choice);
}

void MoodStore_LogSampleEvent(double avgRisk) {
    AppendEvent(L"sample", avgRisk, L"", L"");
}

// [MINDFUL] C5 — tự thuật "Mặt hồ đang thế nào?" (mirror MoodStoreMac_LogCheckinEvent). waveLevel
// 1=phẳng lặng·2=gợn nhẹ·3=gợn sóng. AppendEvent để 2 cột cuối rỗng nên checkin phải tự viết dòng
// để điền mood_label + intensity (khớp cột macOS: ...,mood_label,intensity).
void MoodStore_LogCheckinEvent(int waveLevel) {
    if (!MoodStore_HasConsent())
        return;
    if (waveLevel < 1) waveLevel = 1;
    if (waveLevel > 3) waveLevel = 3;
    const wchar_t* label = (waveLevel == 2) ? L"ripple" : (waveLevel == 3) ? L"wave" : L"calm";

    lock_guard<mutex> lock(g_mutex);
    wstring all;
    if (!ReadAll(all) || all.empty())
        all = wstring(kFileHeader) + L"\n";
    wostringstream line;
    // cột: ts, event_type, send_risk(rỗng), app(rỗng), choice(rỗng), mood_label, intensity
    line << (long long)time(NULL) << L"\tcheckin\t\t\t\t" << label << L'\t' << waveLevel;
    all += line.str() + L"\n";
    WriteAll(all);
}

// ── Đọc ──

MoodTodaySummary MoodStore_FetchTodaySummary() {
    MoodTodaySummary s;
    if (!MoodStore_HasConsent())
        return s;

    lock_guard<mutex> lock(g_mutex);
    wstring all;
    if (!ReadAll(all))
        return s;

    // Mốc 00:00 hôm nay theo GIỜ ĐỊA PHƯƠNG — không dùng "24 giờ qua": người dùng hiểu "hôm nay"
    // là từ lúc thức dậy, không phải 24h trượt.
    time_t now = time(NULL);
    struct tm lt;
    localtime_s(&lt, &now);
    lt.tm_hour = 0; lt.tm_min = 0; lt.tm_sec = 0;
    time_t startOfDay = mktime(&lt);

    double sum = 0;
    double peakRisk = -1;
    wistringstream in(all);
    wstring line;
    getline(in, line);   // bỏ dòng header
    while (getline(in, line)) {
        if (line.empty()) continue;
        wistringstream f(line);
        wstring tsStr, type, riskStr;
        getline(f, tsStr, L'\t');
        getline(f, type, L'\t');
        getline(f, riskStr, L'\t');
        if (tsStr.empty()) continue;

        time_t ts = (time_t)_wtoi64(tsStr.c_str());
        if (ts < startOfDay) continue;

        if (type == L"gatekeeper") {
            s.gatekeeperCount++;
        } else if (type == L"sample" && !riskStr.empty()) {
            double r = _wtof(riskStr.c_str());
            s.sampleCount++;
            sum += r;
            if (r > peakRisk) {
                peakRisk = r;
                struct tm et;
                localtime_s(&et, &ts);
                s.peakHour = et.tm_hour;
            }
        }
    }
    if (s.sampleCount > 0)
        s.avgRisk = sum / s.sampleCount;
    if (peakRisk > 0)
        s.peakRisk = peakRisk;
    return s;
}

vector<MoodSample> MoodStore_FetchTodaySamples() {
    vector<MoodSample> out;
    if (!MoodStore_HasConsent())
        return out;

    lock_guard<mutex> lock(g_mutex);
    wstring all;
    if (!ReadAll(all))
        return out;

    time_t now = time(NULL);
    struct tm lt;
    localtime_s(&lt, &now);
    lt.tm_hour = 0; lt.tm_min = 0; lt.tm_sec = 0;
    time_t startOfDay = mktime(&lt);

    wistringstream in(all);
    wstring line;
    getline(in, line);   // bỏ header
    while (getline(in, line)) {
        if (line.empty()) continue;
        wistringstream f(line);
        wstring tsStr, type, riskStr;
        getline(f, tsStr, L'\t');
        getline(f, type, L'\t');
        getline(f, riskStr, L'\t');
        if (tsStr.empty() || type != L"sample" || riskStr.empty()) continue;
        MoodSample m;
        m.ts = _wtoi64(tsStr.c_str());
        if ((time_t)m.ts < startOfDay) continue;
        m.value = _wtof(riskStr.c_str());
        out.push_back(m);
    }
    return out;
}

vector<MoodSample> MoodStore_FetchRecentSamples(int pastSeconds) {
    vector<MoodSample> out;
    if (!MoodStore_HasConsent())
        return out;

    lock_guard<mutex> lock(g_mutex);
    wstring all;
    if (!ReadAll(all))
        return out;

    time_t now = time(NULL);
    time_t startOfWindow = now - pastSeconds;

    wistringstream in(all);
    wstring line;
    getline(in, line);   // bỏ header
    while (getline(in, line)) {
        if (line.empty()) continue;
        wistringstream f(line);
        wstring tsStr, type, riskStr;
        getline(f, tsStr, L'\t');
        getline(f, type, L'\t');
        getline(f, riskStr, L'\t');
        if (tsStr.empty()) continue;
        MoodSample m;
        m.ts = _wtoi64(tsStr.c_str());
        if ((time_t)m.ts < startOfWindow) continue;
        if (type == L"sample" && !riskStr.empty()) {
            m.value = _wtof(riskStr.c_str());
        } else if (type == L"checkin") {
            // [MINDFUL] C5 — tự thuật cũng lên sóng: đọc cột intensity (7) rồi quy 3 mức về biên độ.
            // (Windows KHÔNG phân biệt vòng-rỗng/chấm-đặc như macOS — khác biệt cố ý, xem FRICTION-LOG.)
            wstring app, choice, label, intensityStr;
            getline(f, app, L'\t');
            getline(f, choice, L'\t');
            getline(f, label, L'\t');
            getline(f, intensityStr, L'\t');
            int lvl = _wtoi(intensityStr.c_str());
            m.value = (lvl >= 3) ? 0.9 : (lvl == 2) ? 0.5 : 0.15;
        } else {
            continue;
        }
        out.push_back(m);
    }
    return out;
}

void MoodStore_DeleteAll() {
    lock_guard<mutex> lock(g_mutex);
    wstring path = StorePath();
    if (path.empty()) return;
    DeleteFile(path.c_str());
    DeleteFile((path + _T(".tmp")).c_str());   // dọn cả tệp tạm nếu lần ghi trước chết giữa chừng
}

// [MINDFUL] CP5 — XUẤT CSV HẸP (PRIVACY-NOTE §24: chỉ điểm rủi ro + thời điểm + trạng thái cảm xúc;
// BỎ app_bundle_id + choice). Mirror MoodStoreMac_ExportCSVToURL: cột ts,event_type,send_risk,
// mood_label,intensity. Ghi UTF-8 + BOM để Excel đọc đúng tiếng Việt. Các trường đều là số/nhãn ASCII,
// không có dấu phẩy nên không cần escape CSV.
bool MoodStore_ExportCSV(const std::wstring& path) {
    if (!MoodStore_HasConsent())
        return false;
    lock_guard<mutex> lock(g_mutex);
    wstring all;
    if (!ReadAll(all))
        return false;

    wstring csv = L"ts,event_type,send_risk,mood_label,intensity\r\n";
    wistringstream in(all);
    wstring line;
    getline(in, line);   // bỏ header nội bộ
    while (getline(in, line)) {
        if (line.empty()) continue;
        // cột nội bộ: ts, event_type, send_risk, app, choice, mood_label, intensity
        wistringstream f(line);
        wstring ts, type, risk, app, choice, label, intensity;
        getline(f, ts, L'\t');
        getline(f, type, L'\t');
        getline(f, risk, L'\t');
        getline(f, app, L'\t');
        getline(f, choice, L'\t');
        getline(f, label, L'\t');
        getline(f, intensity, L'\t');
        if (ts.empty() || type == L"note") continue;   // BỎ app+choice khi ghép: đúng PRIVACY-NOTE
        csv += ts + L"," + type + L"," + risk + L"," + label + L"," + intensity + L"\r\n";
    }

    int u8len = WideCharToMultiByte(CP_UTF8, 0, csv.c_str(), (int)csv.size(), NULL, 0, NULL, NULL);
    std::string u8((size_t)u8len, '\0');
    WideCharToMultiByte(CP_UTF8, 0, csv.c_str(), (int)csv.size(), &u8[0], u8len, NULL, NULL);

    HANDLE h = CreateFileW(path.c_str(), GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    if (h == INVALID_HANDLE_VALUE)
        return false;
    DWORD written = 0;
    const unsigned char bom[3] = { 0xEF, 0xBB, 0xBF };
    WriteFile(h, bom, 3, &written, NULL);
    WriteFile(h, u8.data(), (DWORD)u8.size(), &written, NULL);
    CloseHandle(h);
    return true;
}

// [MINDFUL] CP5 — tự động dọn dẹp: giữ nhật ký trong N ngày gần nhất (mirror MoodStoreMac auto-purge).
// 0 = giữ tất cả. Mặc định 90 ngày.
static LPCTSTR kRegPurgeDays = _T("vMoodPurgeDays");

int MoodStore_GetPurgeDays() {
    return MindfulKeyHelper::getRegInt(kRegPurgeDays, 90);
}

void MoodStore_RunAutoPurgeIfNeeded() {
    int days = MoodStore_GetPurgeDays();
    if (days <= 0 || !MoodStore_HasConsent())
        return;
    lock_guard<mutex> lock(g_mutex);
    wstring all;
    if (!ReadAll(all))
        return;
    time_t cutoff = time(NULL) - (time_t)days * 86400;
    wistringstream in(all);
    wstring line;
    wostringstream kept;
    getline(in, line);   // header
    kept << (line.empty() ? wstring(kFileHeader) : line) << L"\n";
    bool trimmed = false;
    while (getline(in, line)) {
        if (line.empty()) continue;
        size_t tab = line.find(L'\t');   // ts là cột đầu
        if (tab == wstring::npos) continue;
        long long ts = _wtoi64(line.substr(0, tab).c_str());
        if ((time_t)ts >= cutoff) kept << line << L"\n";
        else trimmed = true;
    }
    if (trimmed) WriteAll(kept.str());   // chỉ ghi lại nếu THẬT SỰ có dòng bị bỏ (tránh ghi thừa)
}

void MoodStore_SetPurgeDays(int days) {
    MindfulKeyHelper::setRegInt(kRegPurgeDays, days);
    MoodStore_RunAutoPurgeIfNeeded();   // áp ngay khi đổi
}

// [MINDFUL] P8 — TIỆN ÍCH DEV, chỉ bản _DEBUG. Seed dữ liệu mẫu (sample backdate 24h + vài checkin)
// để test khung sóng/nhật ký NGAY, không phải chờ gõ hàng giờ. KHÔNG lọt vào bản Release người dùng
// (bọc #ifdef _DEBUG cả .h lẫn .cpp lẫn mục menu). KHÔNG sửa đường ghi/đọc thật — chỉ thêm hàm mới.
// Đánh dấu mọi dòng seed bằng kSeedMarker ở cột app_bundle_id (reader 'sample'/'checkin' bỏ cột này)
// để MoodStore_DeleteSimulatedData dọn sạch riêng phần giả, không đụng dữ liệu thật.
#ifdef _DEBUG
static const wchar_t* kSeedMarker = L"__mk_seed_fake__";

void MoodStore_DevSeed() {
    if (!MoodStore_HasConsent())
        return;
    lock_guard<mutex> lock(g_mutex);
    wstring all;
    if (!ReadAll(all) || all.empty())
        all = wstring(kFileHeader) + L"\n";

    time_t now = time(NULL);
    wostringstream out;

    // 'sample' rải 24h qua, bước 8 phút. Đi bộ ngẫu nhiên TẤT ĐỊNH theo idx (LCG nhỏ) — tái lập được,
    // không cần srand/time. Cột: ts, sample, send_risk, app=marker, choice(rỗng), mood_label(rỗng), intensity(rỗng).
    double risk = 0.35;
    long long span = 24LL * 3600;
    long long step = 8 * 60;
    int idx = 0;
    for (long long t = now - span; t <= now; t += step, idx++) {
        unsigned h = (unsigned)(idx * 1103515245u + 12345u);
        double delta = (double)((h >> 16) & 0xFF) / 255.0 - 0.5;   // -0.5..0.5
        risk += delta * 0.24;
        if (risk < 0.05) risk = 0.05;
        if (risk > 0.85) risk = 0.85;
        out << t << L"\tsample\t" << risk << L'\t' << kSeedMarker << L"\t\t\t\n";
    }

    // Vài 'checkin' ở các mốc giờ quá khứ (mức 1/2/3 luân phiên).
    long long checkAt[] = { now - 20 * 3600, now - 15 * 3600, now - 9 * 3600, now - 4 * 3600, now - 3600 };
    for (int i = 0; i < 5; i++) {
        int lvl = (i % 3) + 1;
        const wchar_t* label = (lvl == 2) ? L"ripple" : (lvl == 3) ? L"wave" : L"calm";
        // Cột: ts, checkin, send_risk(rỗng), app=marker, choice(rỗng), mood_label, intensity.
        out << checkAt[i] << L"\tcheckin\t\t" << kSeedMarker << L"\t\t" << label << L'\t' << lvl << L"\n";
    }

    all += out.str();
    WriteAll(all);
}

void MoodStore_DeleteSimulatedData() {
    lock_guard<mutex> lock(g_mutex);
    wstring all;
    if (!ReadAll(all))
        return;
    wistringstream in(all);
    wstring line;
    wostringstream kept;
    while (getline(in, line)) {
        if (line.find(kSeedMarker) != wstring::npos) continue;   // bỏ mọi dòng seed, giữ dữ liệu thật
        kept << line << L"\n";
    }
    WriteAll(kept.str());
}
#endif // _DEBUG
