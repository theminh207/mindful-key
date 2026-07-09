//
// Bell.cpp — [MINDFUL] Chuông tỉnh thức.
// Dùng SetTimer(NULL,...) (timer toàn cục, chạy qua message loop sẵn có của app) — không cần tạo window.
// Khi tới giờ: hiện lời nhắc tỉnh thức trên LUỒNG RIÊNG (MessageBox), không đụng luồng gõ.
//
#include "stdafx.h"        // windows.h + APP_GET_DATA/APP_SET_DATA
#include "Bell.h"
#include "resource.h"

int vBell = 0;             // mặc định TẮT (user tự bật trong cài đặt)
int vBellInterval = 60;    // phút
int vBellFrom = 8;
int vBellTo = 22;

static UINT_PTR g_bellTimer = 0;

static const wchar_t* PROMPTS[] = {
    L"Dừng lại 10 giây.\nHít vào thật sâu... thở ra thật chậm.\nNgay lúc này, bạn đang thấy thế nào?",
    L"Một nhịp nghỉ cho riêng mình.\nThả lỏng vai, buông căng thẳng xuống.\nBạn vẫn ổn chứ?",
    L"Khoan đã — kéo mắt rời màn hình một chút.\nNhìn ra xa, chớp mắt vài cái.\nHít một hơi cho đầu óc nhẹ lại.",
    L"Tỉnh thức.\nBạn đang ngồi đây, đang thở, đang sống.\nCảm nhận hơi thở một nhịp trọn vẹn nhé.",
    L"Nghỉ tay một lát.\nUống một ngụm nước, vươn vai.\nRồi quay lại với tâm thế nhẹ nhõm hơn.",
};
static const int PROMPT_COUNT = sizeof(PROMPTS) / sizeof(PROMPTS[0]);

static DWORD WINAPI bellThread(LPVOID p) {
    int idx = (int)(INT_PTR)p;
    MessageBoxW(NULL, PROMPTS[idx % PROMPT_COUNT], L"Chuông tỉnh thức  -  Mindful",
                MB_OK | MB_ICONINFORMATION | MB_TOPMOST | MB_SETFOREGROUND);
    return 0;
}

static void CALLBACK Bell_TimerProc(HWND hwnd, UINT msg, UINT_PTR id, DWORD t) {
    if (!vBell) return;
    SYSTEMTIME st;
    GetLocalTime(&st);
    int h = st.wHour;
    bool inRange = (vBellFrom <= vBellTo)
        ? (h >= vBellFrom && h < vBellTo)
        : (h >= vBellFrom || h < vBellTo);   // khung giờ vắt qua nửa đêm
    if (!inRange) return;

    static int idx = 0; idx++;
    HANDLE th = CreateThread(NULL, 0, bellThread, (LPVOID)(INT_PTR)idx, 0, NULL);
    if (th) CloseHandle(th);
}

void Bell_ApplySettings() {
    if (g_bellTimer) { KillTimer(NULL, g_bellTimer); g_bellTimer = 0; }
    if (vBell) {
        int mins = vBellInterval;
        if (mins < 1) mins = 1;
        if (mins > 1440) mins = 1440;
        g_bellTimer = SetTimer(NULL, 0, (UINT)mins * 60000, Bell_TimerProc);
    }
}

void Bell_Init() {
    APP_GET_DATA(vBell, 0);
    APP_GET_DATA(vBellInterval, 60);
    APP_GET_DATA(vBellFrom, 8);
    APP_GET_DATA(vBellTo, 22);
    Bell_ApplySettings();
}

static INT_PTR CALLBACK BellDlgProc(HWND hDlg, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_INITDIALOG:
        CheckDlgButton(hDlg, IDC_CHECK_BELL, vBell ? BST_CHECKED : BST_UNCHECKED);
        SetDlgItemInt(hDlg, IDC_EDIT_BELL_INTERVAL, vBellInterval, FALSE);
        SetDlgItemInt(hDlg, IDC_EDIT_BELL_FROM, vBellFrom, FALSE);
        SetDlgItemInt(hDlg, IDC_EDIT_BELL_TO, vBellTo, FALSE);
        return TRUE;
    case WM_COMMAND:
        if (LOWORD(wParam) == IDOK) {
            int en = (IsDlgButtonChecked(hDlg, IDC_CHECK_BELL) == BST_CHECKED) ? 1 : 0;
            BOOL ok;
            int iv = (int)GetDlgItemInt(hDlg, IDC_EDIT_BELL_INTERVAL, &ok, FALSE);
            if (!ok || iv < 1) iv = 60; if (iv > 240) iv = 240;
            int fr = (int)GetDlgItemInt(hDlg, IDC_EDIT_BELL_FROM, &ok, FALSE);
            if (!ok) fr = 8; if (fr < 0) fr = 0; if (fr > 23) fr = 23;
            int to = (int)GetDlgItemInt(hDlg, IDC_EDIT_BELL_TO, &ok, FALSE);
            if (!ok) to = 22; if (to < 0) to = 0; if (to > 23) to = 23;
            APP_SET_DATA(vBell, en);
            APP_SET_DATA(vBellInterval, iv);
            APP_SET_DATA(vBellFrom, fr);
            APP_SET_DATA(vBellTo, to);
            Bell_ApplySettings();
            EndDialog(hDlg, IDOK);
            return TRUE;
        }
        else if (LOWORD(wParam) == IDCANCEL) {
            EndDialog(hDlg, IDCANCEL);
            return TRUE;
        }
        break;
    }
    return FALSE;
}

void Bell_ShowSettings(HWND parent) {
    DialogBoxParam(GetModuleHandle(NULL), MAKEINTRESOURCE(IDD_DIALOG_BELL), parent, BellDlgProc, 0);
}
