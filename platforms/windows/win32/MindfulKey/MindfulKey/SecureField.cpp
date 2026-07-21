//
// SecureField.cpp — [MINDFUL] cổng ô mật khẩu cho vỏ Windows. Xem SecureField.h cho hợp đồng đầy
// đủ + lý do tồn tại. File MỚI của dự án mindful-keyboard (không thuộc MindfulKey gốc).
//
#include "stdafx.h"
#include "SecureField.h"
#include <objbase.h>
// oleauto.h cho VariantInit/VariantClear: stdafx.h đặt WIN32_LEAN_AND_MEAN nên windows.h KHÔNG kéo
// theo nhóm header OLE. Có thể uiautomation.h kéo gián tiếp, nhưng khai thẳng thứ mình gọi thì
// không phải cược vào đó (header có include guard — thừa cũng vô hại).
#include <oleauto.h>
#include <uiautomation.h>

#pragma comment(lib, "UIAutomationCore.lib")

// 1 = fail-closed (đang ở ô mật khẩu HOẶC chưa xác nhận được), 0 = đã xác nhận KHÔNG phải ô mật
// khẩu. Khởi tạo = 1: trước khi luồng theo dõi kịp chạy vòng đầu tiên (hoặc nếu nó không dựng
// được), toàn bộ vòng đời coi như đang bị che — đúng ý đồ fail-closed, không phải cờ quên khởi.
static volatile LONG g_secureActive = 1;

// Sống suốt đời luồng theo dõi (thread ở dưới không bao giờ thoát trước khi tiến trình thoát).
// NULL nếu CoCreateInstance hỏng -> IsUiaFocusedElementPassword() luôn trả "chưa chắc".
static IUIAutomation* g_uia = NULL;

// ── Lớp rẻ, KHÔNG cần COM: bắt ô Win32 gốc (Notepad, phần lớn dialog desktop cũ, kể cả màn đăng
// nhập Windows dựng bằng control chuẩn). GetGUIThreadInfo lấy đúng control đang giữ input focus
// của luồng sở hữu cửa sổ tiền cảnh — KHÔNG cần AttachThreadInput (khác GetFocus() cross-thread).
// ES_PASSWORD là style chuẩn Win32 gắn cho mọi EDIT control tạo với cờ mật khẩu.
static bool IsWin32PasswordControlFocused() {
    HWND fg = GetForegroundWindow();
    if (!fg)
        return false;

    DWORD pid = 0;
    DWORD tid = GetWindowThreadProcessId(fg, &pid);
    if (tid == 0)
        return false;

    GUITHREADINFO info = { sizeof(GUITHREADINFO) };
    if (!GetGUIThreadInfo(tid, &info) || !info.hwndFocus)
        return false;

    // PHẢI kiểm lớp cửa sổ TRƯỚC khi đọc ES_PASSWORD: bit style không có nghĩa toàn cục, mỗi lớp
    // control tự định nghĩa lại. ES_PASSWORD là 0x0020 — ĐÚNG BIT mà lớp BUTTON gọi là BS_LEFTTEXT
    // (checkbox/radio để chữ bên trái). Đọc bit trần thì một cái checkbox bình thường bị đọc thành
    // "ô mật khẩu": fail-closed nên KHÔNG lộ gì, nhưng lớp cảm xúc sẽ tự câm ở những chỗ vô hại mà
    // không ai hiểu vì sao — mà câm thì sản phẩm vô dụng (docs/QA-WINDOWS.md §1).
    // Control KHÔNG phải EDIT rơi xuống lớp UIA bên dưới và được hỏi tử tế, không mất gì.
    wchar_t cls[16] = { 0 };
    if (!GetClassNameW(info.hwndFocus, cls, ARRAYSIZE(cls)))
        return false;
    if (_wcsicmp(cls, L"Edit") != 0)
        return false;

    return (GetWindowLong(info.hwndFocus, GWL_STYLE) & ES_PASSWORD) != 0;
}

// ── Lớp UIA: phủ control TỰ VẼ (Chrome/Electron dùng accessibility tree riêng, UWP dùng XAML) mà
// lớp Win32 rẻ ở trên không thấy được vì chúng không phải EDIT control gốc.
// Trả về: 1 = đúng ô mật khẩu · 0 = xác nhận KHÔNG phải · -1 = chưa xác định (nơi gọi PHẢI giữ
// fail-closed, không được coi -1 là "không phải mật khẩu").
static int IsUiaFocusedElementPassword() {
    if (!g_uia)
        return -1;   // COM/UIA chưa sẵn sàng hoặc khởi hỏng -> không đoán

    IUIAutomationElement* focused = NULL;
    if (FAILED(g_uia->GetFocusedElement(&focused)) || !focused)
        return -1;

    VARIANT val;
    VariantInit(&val);
    HRESULT hr = focused->GetCurrentPropertyValue(UIA_IsPasswordPropertyId, &val);
    focused->Release();

    // GetCurrentPropertyValue KHÔNG fail khi property không được control đó hỗ trợ — nó trả về
    // một giá trị "reserved not supported" mà kiểu VARIANT thường không phải VT_BOOL. Nhánh dưới
    // tự nhiên fail-closed cho cả 2 trường hợp (lỗi thật + không hỗ trợ), không cần phân biệt.
    if (FAILED(hr) || val.vt != VT_BOOL) {
        VariantClear(&val);
        return -1;
    }

    bool isPassword = (val.boolVal == VARIANT_TRUE);
    VariantClear(&val);
    return isPassword ? 1 : 0;
}

// Chạy trên luồng riêng (SecureFieldThreadProc), mỗi lần focus bàn phím đổi cửa sổ/control.
static void CALLBACK WinEventProc(HWINEVENTHOOK hook, DWORD event, HWND hwnd,
                                   LONG idObject, LONG idChild, DWORD threadId, DWORD eventTime) {
    if (event != EVENT_OBJECT_FOCUS)
        return;

    // FAIL-CLOSED NGAY: hạ cờ xuống "che" trước khi biết gì cả. Nếu lớp Win32/UIA bên dưới chạy
    // chậm (hoặc treo hẳn vì app kia đứng hình), người dùng chỉ bị "mù" thêm — không đọc nhầm.
    InterlockedExchange(&g_secureActive, 1);

    bool isPassword = IsWin32PasswordControlFocused();
    if (!isPassword) {
        int uia = IsUiaFocusedElementPassword();
        if (uia < 0)
            return;   // chưa xác định được -> GIỮ NGUYÊN fail-closed, không hạ cờ
        isPassword = (uia != 0);
    }
    InterlockedExchange(&g_secureActive, isPassword ? 1 : 0);
}

static DWORD WINAPI SecureFieldThreadProc(LPVOID) {
    // COINIT_APARTMENTTHREADED: UIA là COM cross-process, cần message loop bơm trên CHÍNH luồng
    // gọi nó — đúng loại luồng mà vòng lặp GetMessage bên dưới cung cấp.
    HRESULT comHr = CoInitializeEx(NULL, COINIT_APARTMENTTHREADED);
    if (SUCCEEDED(comHr)) {
        CoCreateInstance(CLSID_CUIAutomation, NULL, CLSCTX_INPROC_SERVER,
                          IID_IUIAutomation, (void**)&g_uia);
        // CoCreateInstance hỏng -> g_uia vẫn NULL -> IsUiaFocusedElementPassword() luôn trả -1.
        // Lớp Win32 rẻ ở trên KHÔNG cần COM nên vẫn chạy đúng dù UIA chết hẳn.
    }
    // comHr FAILED -> g_uia chắc chắn NULL (CoCreateInstance không được gọi) -> mù UIA vĩnh viễn,
    // vẫn fail-closed đúng nghĩa (không phải bug, là cái giá đã ghi ở SecureField.h).

    // WINEVENT_SKIPOWNPROCESS: bỏ qua sự kiện focus của chính app này (dialog Nhắc tâm, cửa sổ
    // Điều khiển...) — đỡ gọi UIA vô ích, và không có gì trong UI của CHÍNH mindful-keyboard là ô
    // mật khẩu. Khớp cờ đã dùng cho hSystemEvent trong MindfulKey.cpp.
    HWINEVENTHOOK hHook = SetWinEventHook(EVENT_OBJECT_FOCUS, EVENT_OBJECT_FOCUS, NULL,
                                           WinEventProc, 0, 0,
                                           WINEVENT_OUTOFCONTEXT | WINEVENT_SKIPOWNPROCESS);

    // WINEVENT_OUTOFCONTEXT giao sự kiện qua hàng đợi của luồng này -> BẮT BUỘC có vòng lặp bơm
    // message thì mới nhận được. Luồng này sống suốt đời tiến trình, y như worker của MoodWatch —
    // không có nhánh thoát chủ động, không cần join lúc app đóng.
    MSG msg;
    while (GetMessage(&msg, NULL, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    if (hHook)
        UnhookWinEvent(hHook);
    if (g_uia) {
        g_uia->Release();
        g_uia = NULL;
    }
    if (SUCCEEDED(comHr))
        CoUninitialize();
    return 0;
}

void SecureField_Init() {
    HANDLE h = CreateThread(NULL, 0, SecureFieldThreadProc, NULL, 0, NULL);
    if (h) {
        CloseHandle(h);   // không giữ handle — không cần join, thread tự sống hết đời tiến trình
        return;
    }
    // Dựng luồng thất bại: KHÔNG có nhánh "hạ cờ cho khỏi mù mãi". g_secureActive đã khởi = 1
    // (fail-closed) và không ai hạ nó xuống nữa -> lớp cảm xúc mù vĩnh viễn trên máy này. Đúng ý
    // đồ fail-closed (thà câm còn hơn đọc nhầm mật khẩu), không phải lỗi bỏ sót.
}

bool SecureField_IsActive() {
    // volatile LONG: MSVC đảm bảo đọc/ghi LONG có căn lề là nguyên tử trên x86/x64, và volatile
    // chặn trình biên dịch cache giá trị qua nhiều lần đọc. Ghi luôn qua InterlockedExchange (có
    // hàng rào bộ nhớ đầy đủ) ở WinEventProc — khớp đúng kiểu cờ liên-luồng đã dùng cho
    // g_popupShowing/g_pauseShowing trong MoodWatch.cpp/SendGatekeeper.cpp.
    return g_secureActive != 0;
}
