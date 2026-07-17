//
// SendGatekeeper.cpp — [MINDFUL] Feature #1: người gác cổng gửi tin, bản Windows.
// Xem SendGatekeeper.h + docs/BREATHING-PAUSE-CONTRACT.md.
//
#include "stdafx.h"
#include "SendGatekeeper.h"
#include "MoodWatch.h"
#include "MoodStore.h"
#include "../../../../../core/mood/BreathingPause.h"
#include <vector>
#include <mutex>
#include <thread>

using namespace std;

// Danh sách app đang gác, ngăn bằng ';' — vd "Zalo.exe;Discord.exe". Lưu registry để còn qua
// lần chạy sau. RỖNG mặc định (xem SendGatekeeper.h: không bịa tên tiến trình).
static LPCTSTR kAppsRegKey = _T("vGatekeeperApps");

static mutex          g_mutex;
static vector<wstring> g_apps;          // đọc từ luồng hook -> phải khoá khi đổi
static volatile LONG  g_pauseShowing = 0;

// Đánh dấu phím Enter do CHÍNH MÌNH gửi lại. keyboardHookProcess bỏ qua mọi phím có
// dwExtraInfo != 0 (OpenKey.cpp:499) — cùng vai trò `myEventSource` bên macOS: không có nó thì
// gatekeeper tự chặn đúng phím Enter mà nó vừa tạo ra, thành vòng lặp vô tận.
static const ULONG_PTR kSelfSentTag = 1;

static vector<wstring> SplitList(const wstring& s) {
    vector<wstring> out;
    size_t start = 0;
    while (start <= s.size()) {
        size_t pos = s.find(L';', start);
        if (pos == wstring::npos) pos = s.size();
        wstring item = s.substr(start, pos - start);
        if (!item.empty())
            out.push_back(item);
        if (pos == s.size()) break;
        start = pos + 1;
    }
    return out;
}

static wstring JoinList(const vector<wstring>& v) {
    wstring s;
    for (size_t i = 0; i < v.size(); i++) {
        if (i) s += L';';
        s += v[i];
    }
    return s;
}

// So tên app KHÔNG phân biệt hoa/thường: Windows không phân biệt, và người dùng gõ tay thì
// "zalo.exe" với "Zalo.exe" phải là một.
static bool EqualsNoCase(const wstring& a, const wstring& b) {
    return a.size() == b.size() && _wcsicmp(a.c_str(), b.c_str()) == 0;
}

void SendGatekeeper_Init() {
    wstring raw = OpenKeyHelper::getRegString(kAppsRegKey, _T(""));
    lock_guard<mutex> lock(g_mutex);
    g_apps = SplitList(raw);
}

static bool IsFrontmostAppWatched() {
    // getFrontMostAppExecuteName() trả UTF-8; danh sách của ta là wstring -> đổi 1 lần ở đây.
    string utf8 = OpenKeyHelper::getFrontMostAppExecuteName();
    if (utf8.empty())
        return false;
    wstring name = utf8ToWideString(utf8);

    lock_guard<mutex> lock(g_mutex);
    for (size_t i = 0; i < g_apps.size(); i++) {
        if (EqualsNoCase(g_apps[i], name))
            return true;
    }
    return false;
}

bool SendGatekeeper_ShouldIntercept(WPARAM wParam, const KBDLLHOOKSTRUCT* key) {
    if (wParam != WM_KEYDOWN && wParam != WM_SYSKEYDOWN)
        return false;
    if (key->vkCode != VK_RETURN)
        return false;
    // Shift+Enter = xuống dòng trong hầu hết app chat, không phải gửi.
    if (GetKeyState(VK_SHIFT) & 0x8000)
        return false;
    if (g_pauseShowing)
        return false;   // đã có nhịp thở đang hiện -> để phím Enter đi bình thường
    if (!IsFrontmostAppWatched())
        return false;

    return MoodWatch_LastSendRisk() >= kBreathingPauseRiskThreshold;
}

// ── Hộp nhịp thở ──

static wstring g_pauseMessage;

static INT_PTR CALLBACK PauseDialogProc(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam) {
    switch (message) {
    case WM_INITDIALOG:
        SetDlgItemTextW(hDlg, IDC_STATIC_PAUSE_MSG, g_pauseMessage.c_str());
        // lParam = số mili-giây tự đóng (GỢI Ý từ BreathingPause, KHÔNG phải thời gian khoá:
        // người dùng bấm được nút bất cứ lúc nào).
        if (lParam > 0)
            SetTimer(hDlg, 1, (UINT)lParam, NULL);
        return TRUE;
    case WM_TIMER:
        KillTimer(hDlg, 1);
        // Hết giờ mà không chọn = Dismissed. KHÔNG suy thành Send hay Wait (BreathingPause.h).
        EndDialog(hDlg, (INT_PTR)BreathingPauseChoice::Dismissed);
        return TRUE;
    case WM_COMMAND:
        if (LOWORD(wParam) == IDC_BUTTON_PAUSE_SEND) {
            EndDialog(hDlg, (INT_PTR)BreathingPauseChoice::SendAnyway);
            return TRUE;
        }
        if (LOWORD(wParam) == IDC_BUTTON_PAUSE_WAIT || LOWORD(wParam) == IDCANCEL) {
            EndDialog(hDlg, (INT_PTR)BreathingPauseChoice::Wait);
            return TRUE;
        }
        break;
    }
    return FALSE;
}

static DWORD WINAPI pauseThread(LPVOID p) {
    BreathingPausePrompt* prompt = (BreathingPausePrompt*)p;
    double seconds = prompt->durationSeconds > 0 ? prompt->durationSeconds : 3.0;
    g_pauseMessage = prompt->message;
    delete prompt;

    // Chụp risk + app NGAY BÂY GIỜ, trước khi hộp thoại mở: người dùng có thể ngồi vài giây rồi
    // mới bấm, lúc đó app đang-trước-mặt đã là hộp thoại của chính ta.
    double risk = MoodWatch_LastSendRisk();
    wstring app = SendGatekeeper_LastAppName();

    INT_PTR result = DialogBoxParam(GetModuleHandle(NULL), MAKEINTRESOURCE(IDD_DIALOG_PAUSE),
                                    NULL, PauseDialogProc, (LPARAM)(int)(seconds * 1000));
    BreathingPauseChoice choice = (BreathingPauseChoice)result;
    BreathingPause_ReportChoice(choice);

    // Ghi lại (nếu đã đồng ý): CHỈ điểm risk + tên app + lựa chọn. KHÔNG câu chữ.
    const wchar_t* label = choice == BreathingPauseChoice::SendAnyway ? L"send_anyway"
                         : choice == BreathingPauseChoice::Wait       ? L"wait"
                                                                      : L"dismissed";
    MoodStore_LogGatekeeperEvent(risk, app, label);

    if (choice == BreathingPauseChoice::SendAnyway) {
        // Gửi lại đúng 1 phím Enter THẬT, gắn kSelfSentTag để hook bỏ qua (không tự chặn lại).
        INPUT in[2] = {};
        in[0].type = INPUT_KEYBOARD;
        in[0].ki.wVk = VK_RETURN;
        in[0].ki.dwExtraInfo = kSelfSentTag;
        in[1] = in[0];
        in[1].ki.dwFlags = KEYEVENTF_KEYUP;
        SendInput(2, in, sizeof(INPUT));
    }
    // Wait / Dismissed -> không làm gì. Tin nhắn vẫn CHƯA gửi; người dùng tự quyết bước tiếp.

    InterlockedExchange(&g_pauseShowing, 0);
    return 0;
}

void SendGatekeeper_ShowPause() {
    if (InterlockedCompareExchange(&g_pauseShowing, 1, 0) != 0)
        return;

    BreathingPausePrompt* prompt = new BreathingPausePrompt();
    if (!BreathingPause_Evaluate(MoodWatch_LastSendRisk(), prompt)) {
        delete prompt;
        InterlockedExchange(&g_pauseShowing, 0);
        return;   // chưa tới ngưỡng -> KHÔNG có "overlay rỗng" (BreathingPause.h)
    }

    HANDLE h = CreateThread(NULL, 0, pauseThread, prompt, 0, NULL);
    if (h) {
        CloseHandle(h);
    } else {
        delete prompt;
        InterlockedExchange(&g_pauseShowing, 0);
    }
}

// ── Menu khay ──

wstring SendGatekeeper_LastAppName() {
    string utf8 = OpenKeyHelper::getLastAppExecuteName();
    return utf8.empty() ? wstring() : utf8ToWideString(utf8);
}

bool SendGatekeeper_IsAppWatched(const wstring& exeName) {
    lock_guard<mutex> lock(g_mutex);
    for (size_t i = 0; i < g_apps.size(); i++) {
        if (EqualsNoCase(g_apps[i], exeName))
            return true;
    }
    return false;
}

void SendGatekeeper_ToggleLastApp() {
    wstring name = SendGatekeeper_LastAppName();
    if (name.empty())
        return;

    wstring joined;
    {
        lock_guard<mutex> lock(g_mutex);
        bool removed = false;
        for (size_t i = 0; i < g_apps.size(); i++) {
            if (EqualsNoCase(g_apps[i], name)) {
                g_apps.erase(g_apps.begin() + i);
                removed = true;
                break;
            }
        }
        if (!removed)
            g_apps.push_back(name);
        joined = JoinList(g_apps);
    }
    OpenKeyHelper::setRegString(kAppsRegKey, joined.c_str());
}
