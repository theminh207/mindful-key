//
// Bell.cpp — [MINDFUL] Chuông tỉnh thức, bản Windows.
// File MỚI của dự án mindful-keyboard (không thuộc MindfulKey gốc).
//
// ĐÃ VIẾT LẠI 2026-07-17 (GĐ4, docs/ROADMAP-WINDOWS.md). Bản trước KHÔNG phát tiếng nào cả — nó
// chỉ gọi MessageBox với cờ MB_ICONINFORMATION, nên Windows tự kêu tiếng "ding" MẶC ĐỊNH của hệ
// thống. Ba tiếng chuông chủ dự án đã thiết lập (Chuông chùa/gió/reo) chưa từng được dùng.
//
// Đối ứng của platforms/apple/macos/BellMac.mm — bản macOS là CHUẨN HÀNH VI.
//
// TIẾNG CHUÔNG NHÚNG THẲNG VÀO .EXE: MindfulKey.rc trỏ sang chính tệp .wav mà vỏ macOS đang dùng
// (platforms/apple/macos/*.wav) — KHÔNG chép sang thư mục Windows. Chép là tạo bản sao thứ hai
// của tài sản brand, đúng mô hình đã đẻ ra bug lexicon (2 bản trôi lệch trong 3 ngày). Một nguồn
// duy nhất; đổi tệp là cả 2 vỏ đổi theo. Tệp là Microsoft PCM 16-bit — định dạng gốc của Windows.
//
// ÂM LƯỢNG: PlaySound KHÔNG có tham số âm lượng, còn waveOutSetVolume chỉnh âm CẢ THIẾT BỊ (đè
// lên app khác — không được phép). Vì tệp là PCM 16-bit nên tự nhân biên độ mẫu rồi phát bằng
// SND_MEMORY: chỉ đụng tiếng của chính mình, không cần tệp tạm.
//
#include "stdafx.h"
#include "Bell.h"
#include "NudgeCoordinator.h"
#include "MoodWatch.h"
#include "MoodStore.h"
#include <vector>
#include <string>
#include <shlobj.h>
#include <mmsystem.h>   // PlaySound + SND_* — stdafx.h có WIN32_LEAN_AND_MEAN nên windows.h KHÔNG kéo theo
// [MINDFUL] B8 — commdlg.h/comdlg32.lib đã rời sang MainControlDialog.cpp (nơi chọn .wav ở tab Chuông
// nay sống); hộp thoại chuông cũ dùng GetOpenFileName đã bỏ nên Bell.cpp không cần nữa.

#pragma comment(lib, "winmm.lib")

using namespace std;

int vBell = 0;             // mặc định TẮT (user tự bật trong cài đặt)
int vBellInterval = 60;    // phút
int vBellFrom = 8;
int vBellTo = 22;

// Id tiếng chuông — định danh tiếng ANH, khớp BellMac.mm. Nhãn tiếng Việt chỉ ở tầng hiển thị.
static LPCTSTR kSoundIdTemple = _T("temple");
static LPCTSTR kSoundIdChime  = _T("chime");
static LPCTSTR kSoundIdWind   = _T("wind");
static LPCTSTR kSoundIdCustom = _T("custom");
static LPCTSTR kSoundMute     = _T("__silent__");
static LPCTSTR kSoundDefault  = _T("temple");

static LPCTSTR kRegSoundName  = _T("vBellSoundName");
static LPCTSTR kRegVolume     = _T("vBellVolume");        // 0..100. macOS lưu double 0..1 —
                                                          // registry chỉ có DWORD nên dùng phần trăm.
static LPCTSTR kRegCustomPath = _T("vBellCustomSoundPath");

static UINT_PTR g_bellTimer = 0;
static DWORD    g_snoozeUntil = 0;   // GetTickCount lúc hết hoãn; 0 = không hoãn

// ── Nạp + phát tiếng ──

// Id -> resource nhúng trong .exe. Ánh xạ chime->"Chuông gió", wind->"Chuông reo" GIỮ NGUYÊN theo
// BellMac.mm: nhìn thì như ngược, nhưng chủ dự án đã chú thích đổi có chủ đích (changelog
// "swap gio/reo bell icons per owner annotation"). ĐỪNG "sửa cho đúng".
static int ResourceIdForSoundId(const wstring& sid) {
    if (sid == kSoundIdChime) return IDR_WAVE_CHIME;   // Chuông gió
    if (sid == kSoundIdWind)  return IDR_WAVE_WIND;    // Chuông reo
    return IDR_WAVE_TEMPLE;                            // Chuông chùa — mặc định
}

// Đời cũ / rác -> về mặc định. Khớp BellMac_SoundIdFromStored().
static wstring SoundIdFromStored(const wstring& stored) {
    if (stored.empty()) return kSoundDefault;
    if (stored == kSoundMute) return stored;
    if (stored == kSoundIdTemple || stored == kSoundIdChime ||
        stored == kSoundIdWind || stored == kSoundIdCustom)
        return stored;
    // Kho từng lưu thẳng nhãn tiếng Việt (trước 2026-07-17) — cùng lối thoát như macOS.
    if (stored == _T("Chuông chùa")) return kSoundIdTemple;
    if (stored == _T("Chuông gió"))  return kSoundIdChime;
    if (stored == _T("Chuông reo"))  return kSoundIdWind;
    return kSoundDefault;
}

// Nhân biên độ mẫu PCM 16-bit TẠI CHỖ. Đi theo chuỗi chunk RIFF để tìm đúng "data" — KHÔNG nhảy
// cóc 44 byte: header WAV không phải lúc nào cũng đúng 44 byte (có thể có chunk LIST/fact xen
// vào), đoán bừa là nhân nhầm vào header rồi ra tiếng rè.
static bool ScalePcm16InPlace(vector<BYTE>& wav, float vol) {
    if (wav.size() < 12 || memcmp(&wav[0], "RIFF", 4) != 0 || memcmp(&wav[8], "WAVE", 4) != 0)
        return false;

    WORD bitsPerSample = 0;
    size_t pos = 12;
    while (pos + 8 <= wav.size()) {
        char id[5] = { 0 };
        memcpy(id, &wav[pos], 4);
        DWORD chunkSize = *(DWORD*)&wav[pos + 4];
        size_t body = pos + 8;
        if (body + chunkSize > wav.size())
            chunkSize = (DWORD)(wav.size() - body);   // tệp cụt -> xử phần còn đọc được

        if (memcmp(id, "fmt ", 4) == 0 && chunkSize >= 16) {
            bitsPerSample = *(WORD*)&wav[body + 14];
        } else if (memcmp(id, "data", 4) == 0) {
            if (bitsPerSample != 16 || chunkSize < sizeof(short))
                return false;   // không phải 16-bit -> KHÔNG nhân bừa, để nguyên âm lượng gốc
            short* s = (short*)&wav[body];
            size_t n = chunkSize / sizeof(short);
            for (size_t i = 0; i < n; i++) {
                int v = (int)(s[i] * vol);
                if (v > 32767) v = 32767;
                if (v < -32768) v = -32768;   // kẹp biên: tràn số làm tiếng nổ lụp bụp
                s[i] = (short)v;
            }
            return true;
        }
        pos = body + chunkSize + (chunkSize & 1);   // chunk RIFF luôn căn chẵn byte
    }
    return false;
}

static bool LoadResourceWav(int resId, vector<BYTE>& out) {
    HRSRC h = FindResource(NULL, MAKEINTRESOURCE(resId), _T("WAVE"));
    if (!h) return false;
    HGLOBAL g = LoadResource(NULL, h);
    if (!g) return false;
    DWORD size = SizeofResource(NULL, h);
    const BYTE* p = (const BYTE*)LockResource(g);
    if (!p || size == 0) return false;
    out.assign(p, p + size);
    return true;
}

static bool LoadFileWav(LPCTSTR path, vector<BYTE>& out) {
    HANDLE f = CreateFile(path, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING,
                          FILE_ATTRIBUTE_NORMAL, NULL);
    if (f == INVALID_HANDLE_VALUE) return false;
    DWORD size = GetFileSize(f, NULL);
    bool ok = false;
    if (size != INVALID_FILE_SIZE && size > 12 && size < 50u * 1024 * 1024) {
        out.resize(size);
        DWORD read = 0;
        ok = ReadFile(f, &out[0], size, &read, NULL) && read == size;
    }
    CloseHandle(f);
    return ok;
}

// Bộ đệm: nạp lại 2.2MB mỗi lần reo là phí. Khoá gồm CẢ âm lượng vì mẫu đã bị nhân sẵn.
static vector<BYTE> g_soundCache;
static wstring      g_cacheKey;

static void PlayBellWav(const wstring& sid, float vol) {
    wchar_t volTag[16];
    swprintf_s(volTag, L"|%.2f", vol);
    wstring key = sid + volTag;

    if (key != g_cacheKey || g_soundCache.empty()) {
        vector<BYTE> wav;
        bool loaded = false;
        if (sid == kSoundIdCustom) {
            wstring p = MindfulKeyHelper::getRegString(kRegCustomPath, _T(""));
            loaded = !p.empty() && LoadFileWav(p.c_str(), wav);
        }
        if (!loaded)
            loaded = LoadResourceWav(ResourceIdForSoundId(sid), wav);
        // Tiếng riêng mất/hỏng -> rơi về tiếng THIẾT KẾ, KHÔNG rơi về beep hệ thống: mất tệp riêng
        // vẫn phải nghe chuông của app, không nghe tiếng lạ hoắc (y hệt macOS).
        if (!loaded && !LoadResourceWav(ResourceIdForSoundId(kSoundDefault), wav))
            return;
        ScalePcm16InPlace(wav, vol);   // không nhân được (định dạng lạ) -> phát nguyên âm lượng gốc
        g_soundCache.swap(wav);
        g_cacheKey = key;
    }

    // SND_ASYNC: không giữ luồng gọi. SND_MEMORY: phát thẳng từ RAM, không cần tệp tạm.
    // SND_NODEFAULT: hỏng thì IM, KHÔNG rơi về ding hệ thống (ding nghe như báo lỗi).
    PlaySound((LPCTSTR)&g_soundCache[0], NULL, SND_MEMORY | SND_ASYNC | SND_NODEFAULT);
}

// Phát tiếng người dùng CHỌN, ở ÂM LƯỢNG người dùng chọn. Đọc tươi từ registry mỗi lần reo ->
// đổi cài đặt là áp dụng ngay, không cần khởi động lại (khớp macOS).
static void playBellSound() {
    wstring sid = SoundIdFromStored(MindfulKeyHelper::getRegString(kRegSoundName, _T("")));
    if (sid == kSoundMute)
        return;   // "Im" — không phát gì, có chủ đích

    int pct = MindfulKeyHelper::getRegInt(kRegVolume, 60);   // 60% = macOS mặc định 0.6
    if (pct <= 0) return;                                 // kéo về 0 = im lặng, có chủ đích
    if (pct > 100) pct = 100;
    PlayBellWav(sid, pct / 100.0f);
}

bool Bell_InstallCustomSound(LPCTSTR path, wstring* outMessage) {
    // Thử NẠP trước khi nhận: chặn tệp không đọc nổi ngay tại đây, thay vì để chuông câm lúc reo.
    vector<BYTE> probe;
    if (!LoadFileWav(path, probe) || probe.size() < 12 ||
        memcmp(&probe[0], "RIFF", 4) != 0 || memcmp(&probe[8], "WAVE", 4) != 0) {
        if (outMessage)
            *outMessage = _T("Không đọc được tệp này. Bản Windows nhận tệp .wav — thử tệp .wav nhé.");
        return false;
    }

    // Chép vào kho riêng của app: tệp gốc có thể nằm ở USB/Downloads rồi bị xoá.
    TCHAR appData[MAX_PATH];
    if (FAILED(SHGetFolderPath(NULL, CSIDL_LOCAL_APPDATA, NULL, 0, appData))) {
        if (outMessage) *outMessage = _T("Không tìm được thư mục dữ liệu ứng dụng.");
        return false;
    }
    wstring dir = wstring(appData) + _T("\\MindfulKeyboard");
    CreateDirectory(dir.c_str(), NULL);
    wstring dst = dir + _T("\\CustomBell.wav");

    if (!CopyFile(path, dst.c_str(), FALSE)) {
        if (outMessage) *outMessage = _T("Không chép được tệp vào kho của app.");
        return false;
    }

    MindfulKeyHelper::setRegString(kRegCustomPath, dst.c_str());
    MindfulKeyHelper::setRegString(kRegSoundName, kSoundIdCustom);
    g_cacheKey.clear();   // dội đệm: đường dẫn đích luôn y hệt nên khoá cũ vẫn "khớp"
    return true;
}

void Bell_PreviewSound() {
    playBellSound();   // chủ động nghe thử -> bỏ qua snooze/giờ yên lặng/cooldown
}

// ── Lời nhắc ──

// Câu chữ lấy nguyên từ BellMac.mm (chuẩn hành vi) — quan sát, không phán xét.
static LPCTSTR PROMPTS[] = {
    _T("Dừng lại 10 giây. Hít vào thật sâu, thở ra thật chậm. Ngay lúc này, bạn đang thấy thế nào?"),
    _T("Một nhịp nghỉ cho riêng mình. Thả lỏng vai, buông căng thẳng xuống."),
    _T("Khoan đã, kéo mắt rời màn hình một chút. Nhìn ra xa và chớp mắt vài cái."),
    _T("Tỉnh thức. Bạn đang ngồi đây, đang thở, đang sống."),
    _T("Nghỉ tay một lát. Uống một ngụm nước, vươn vai rồi quay lại."),
};
static const int PROMPT_COUNT = sizeof(PROMPTS) / sizeof(PROMPTS[0]);

// Câu RIÊNG cho lúc rung vì phát hiện CHUỖI câu căng — nói thẳng lý do rung, không giả vờ đây là
// chuông định kỳ.
static LPCTSTR PROMPTS_TENSE[] = {
    _T("Nãy giờ có vẻ căng. Một hơi thở chứ? Không cần vội trả lời ai cả."),
    _T("Vài câu gõ gần đây nghe hơi nặng. Dừng một nhịp, để đầu óc dịu lại đã."),
    _T("Có vẻ bạn đang dồn nén. Rời bàn phím 1 phút, quay lại sẽ rõ ràng hơn."),
};
static const int PROMPTS_TENSE_COUNT = sizeof(PROMPTS_TENSE) / sizeof(PROMPTS_TENSE[0]);

static DWORD WINAPI bellThread(LPVOID p) {
    LPCTSTR msg = (LPCTSTR)p;   // trỏ hằng chuỗi, không cần giải phóng
    // CỐ Ý KHÔNG MB_ICONINFORMATION: chính cờ đó khiến Windows tự kêu ding hệ thống — đúng lỗi
    // của bản cũ, và nó sẽ đè lên tiếng chuông ta vừa phát.
    MessageBoxW(NULL, msg, L"Chuông tỉnh thức - Mindful", MB_OK | MB_TOPMOST | MB_SETFOREGROUND);
    return 0;
}

static void showBellPrompt(LPCTSTR message) {
    playBellSound();   // tiếng + âm lượng người dùng đã chọn
    HANDLE h = CreateThread(NULL, 0, bellThread, (LPVOID)message, 0, NULL);
    if (h) CloseHandle(h);
}

static bool isSnoozed() {
    return g_snoozeUntil != 0 && GetTickCount() < g_snoozeUntil;
}

static bool isInBellRange(int hour) {
    if (vBellFrom <= vBellTo)
        return hour >= vBellFrom && hour < vBellTo;
    return hour >= vBellFrom || hour < vBellTo;   // khung giờ vắt qua nửa đêm
}

void Bell_RingForTenseStreak() {
    if (!vBell || isSnoozed())
        return;
    if (!NudgeCoordinator_ShouldNudge())
        return;
    static int idx = 0;
    idx++;
    showBellPrompt(PROMPTS_TENSE[idx % PROMPTS_TENSE_COUNT]);
    NudgeCoordinator_MarkNudged();
}

void Bell_Snooze(int minutes) {
    if (minutes < 0) minutes = 0;
    DWORD until = GetTickCount() + (DWORD)minutes * 60000;
    g_snoozeUntil = (until == 0) ? 1 : until;   // 0 nghĩa là "không hoãn"
}

static void CALLBACK Bell_TimerProc(HWND hwnd, UINT msg, UINT_PTR id, DWORD t) {
    // [MINDFUL] NHỊP trước, TIẾNG sau — khớp hợp đồng BellMac.mm. Ghi nhật ký TRƯỚC mọi cổng
    // chặn: nó phải chạy KỂ CẢ khi người dùng tắt chuông / tạm hoãn / ngoài giờ. Họ tắt TIẾNG,
    // không phải tắt việc ghi nhận — tắt cả hai là âm thầm bỏ dữ liệu mà họ không hề yêu cầu.
    double avg = 0.0;
    if (MoodWatch_DrainSampleAverage(&avg))
        MoodStore_LogSampleEvent(avg);   // tự im nếu chưa có consent

    if (!vBell || isSnoozed())
        return;

    SYSTEMTIME st;
    GetLocalTime(&st);
    if (!isInBellRange(st.wHour))
        return;

    // Gộp 1 mạch với nhắc thụ động — vừa có lời nhắc khác gần đây thì bỏ lượt này, không dồn dập.
    if (!NudgeCoordinator_ShouldNudge())
        return;

    static int idx = 0;
    idx++;
    showBellPrompt(PROMPTS[idx % PROMPT_COUNT]);
    NudgeCoordinator_MarkNudged();
}

void Bell_ApplySettings() {
    if (g_bellTimer) {
        KillTimer(NULL, g_bellTimer);
        g_bellTimer = 0;
    }
    // Sàn 15 / trần 240 phút — chốt 2026-07-15. Sàn tồn tại vì chuông gánh 2 vai: reo dày = HỐI
    // THÚC (hiến chương cấm), và nhịp dày = nhật ký thành dòng thời gian cảm xúc chi tiết, phá
    // trần riêng tư. KHÔNG nới sàn này.
    int mins = vBellInterval;
    if (mins < 15) mins = 15;
    if (mins > 240) mins = 240;
    // CỐ Ý không `if (!vBell) return;`: đồng hồ này là NHỊP chung của app, không phải đồng hồ riêng
    // của tiếng chuông (xem Bell_TimerProc).
    g_bellTimer = SetTimer(NULL, 0, (UINT)mins * 60000, Bell_TimerProc);
}

void Bell_Init() {
    APP_GET_DATA(vBell, 0);
    APP_GET_DATA(vBellInterval, 60);
    APP_GET_DATA(vBellFrom, 8);
    APP_GET_DATA(vBellTo, 22);
    if (vBellInterval <= 0) vBellInterval = 60;
    if (vBellFrom < 0 || vBellFrom > 23) vBellFrom = 8;
    if (vBellTo < 0 || vBellTo > 23) vBellTo = 22;
    Bell_ApplySettings();
}
