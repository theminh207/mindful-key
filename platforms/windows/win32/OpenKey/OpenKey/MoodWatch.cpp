//
// MoodWatch.cpp — [MINDFUL] lớp "nghe lén cảm xúc" cho bản Windows.
// File MỚI của dự án mindful-keyboard (không thuộc OpenKey gốc).
//
// Nhận từng từ engine commit -> đẩy sang LUỒNG RIÊNG -> gom câu bằng core/mood/MoodBuffer ->
// chấm send-risk bằng core/mood/SendRiskAnalyzer -> risk đủ cao thì hiện lời nhắc.
//
// ĐÃ VIẾT LẠI 2026-07-17 (GĐ1, docs/ROADMAP-WINDOWS.md). Bản trước:
//   1. TỰ gom câu bằng mảng g_words riêng -> chép lại việc của MoodBuffer, phạm lằn ranh
//      "vỏ KHÔNG chép logic bộ não".
//   2. TỰ giữ một bản lexicon riêng -> bản photo thứ 3, đúng thứ vừa phải đi hợp nhất về core.
//   3. Quyết định bằng DÁN NHÃN cảm xúc ("đang GIẬN" viết hoa) -> nghịch HIẾN CHƯƠNG §2.2:
//      nhận diện là MỘT trục phẳng↔gợn, không phân loại, không phán xét.
//   4. Quét lexicon NGAY TRÊN luồng hook bàn phím.
// Nay: gọi core, chấm điểm 0..1, dùng đúng giọng bản macOS (MoodWatchMac.mm là chuẩn hành vi).
//
// VÌ SAO PHẢI CÓ LUỒNG RIÊNG (khác bản trước, và khác cả comment cũ vốn cho là quét RAM thì an
// toàn): `MoodWatch_OnWord` chạy trên luồng của `SetWindowsHookEx(WH_KEYBOARD_LL)`. Windows đo
// thời gian hook chạy; quá `LowLevelHooksTimeout` (mặc định 300ms) nó ÂM THẦM GỠ HOOK — bộ gõ
// chết câm, không báo lỗi, người dùng chỉ thấy "tự nhiên hết gõ được dấu". Không được phép cược
// mạch gõ vào việc quét lexicon nhanh hay chậm. Bản macOS cũng đẩy sang serial queue.
//
#include "stdafx.h"        // windows.h + Engine.h + OpenKeyHelper.h (APP_SET_DATA)
#include "MoodWatch.h"
#include "Bell.h"
#include "NudgeCoordinator.h"
#include "SecureField.h"   // [MINDFUL] P1 — cổng ô mật khẩu, xem SecureField.h
#include "MoodStore.h"     // consent hỏi lúc BẬT (MoodWatch_Toggle), không phải lúc khởi động
#include "../../../../../core/mood/MoodBuffer.h"
#include "../../../../../core/mood/SendRiskAnalyzer.h"
#include "../../../../../core/mood/EmotionWaveAmplitude.h"
#include "SystemTrayHelper.h"
#include <thread>
#include <mutex>
#include <condition_variable>
#include <deque>

using namespace std;

// [MINDFUL] 2026-07-17 — TẮT mặc định trên Windows (macOS/iOS bật). KHÔNG phải chọn tuỳ tiện:
// `WH_KEYBOARD_LL` thấy MỌI phím, kể cả ô mật khẩu, và Windows KHÔNG có cơ chế nào chặn hook như
// Secure Input Mode của macOS.
//
// ĐÃ VÁ (cùng ngày, xem SecureField.h/.cpp): `MoodWatch_OnWord` nay hỏi `SecureField_IsActive()`
// trước khi xếp hàng bất kỳ từ nào — ô mật khẩu không còn vào MoodBuffer nữa. NHƯNG mặc định VẪN
// TẮT: máy dev là macOS, KHÔNG chạy được Windows thật để tự mắt xác nhận UI Automation phủ đủ mọi
// loại ô mật khẩu (Win32 gốc chắc chắn được — lớp rẻ không cần UIA; Chrome/UWP phụ thuộc app đó có
// làm accessibility tử tế hay không, kể cả Electron còn CHƯA rõ). Bật mặc định là quyết định của
// chủ dự án, sau khi có người kiểm trên Windows thật (docs/QA-WINDOWS.md ca P1) — xem
// docs/FRICTION-LOG.md 2026-07-17 "CHẶN PHÁT HÀNH".
int vMoodWatch = 0;

// Khớp MoodWatchMac.mm: risk >= 0.5 mới nhắc, và 15 giây nghỉ giữa 2 lần nhắc.
static const double kSendRiskThreshold = 0.5;
static const DWORD  kWarnCooldownMs    = 15000;

// CHỈ luồng worker được chạm g_buffer -> không cần khoá cho nó.
static MoodBuffer g_buffer(15);
static double     g_lastSendRisk = -1.0;
static int        g_tenseStreak = 0;   // chỉ worker chạm -> không cần khoá
// Gom mẫu: worker CỘNG, luồng timer XẢ -> hai luồng khác nhau, phải khoá.
static mutex      g_sampleMutex;
static double     g_sampleSum = 0.0;
static int        g_sampleCount = 0;
static DWORD      g_lastWarn = 0;
static volatile LONG g_popupShowing = 0;

// Hàng đợi từ hook -> worker.
static mutex              g_mutex;
static condition_variable g_cv;
static deque<wstring>     g_queue;
static bool               g_clearRequested = false;
static bool               g_workerStarted = false;

// Danh mục CHỈ để chọn CHỮ cho lời nhắc — KHÔNG dán nhãn lên người dùng, và KHÔNG quyết định có
// nhắc hay không (việc đó thuộc về `risk`). Câu chữ lấy nguyên từ MoodWatchMac.mm: viết thường,
// quan sát không phán xét (HIẾN CHƯƠNG §2.2).
static const wchar_t* warningForCategory(const wstring& category) {
    if (category == L"giận")
        return L"Câu bạn vừa gõ nghe đang giận. Khoan gửi đã, hít thở 10 giây rồi hãy quyết định nhé.";
    if (category == L"buồn")
        return L"Nghe có vẻ bạn đang buồn. Có chắc muốn gửi ngay không, hay để lòng dịu lại một chút?";
    if (category == L"mệt")
        return L"Nghe bạn đang mệt hoặc căng thẳng. Nghỉ tay vài phút, uống nước rồi quay lại nhé.";
    if (category == L"lo")
        return L"Nghe có vẻ bạn đang lo lắng. Thử gọi tên điều đang lo trước khi trả lời.";
    return L"Trạng thái đang hơi tiêu cực. Dừng một nhịp, hít thở rồi tiếp tục nhé.";
}

// MessageBoxW chặn luồng gọi nó tới khi người dùng bấm OK. Chạy trên worker thì worker đứng im,
// các từ gõ tiếp dồn hàng đợi -> phải có luồng riêng cho hộp thoại.
static DWORD WINAPI msgThread(LPVOID p) {
    const wchar_t* msg = (const wchar_t*)p;   // trỏ tới hằng chuỗi, không cần giải phóng
    MessageBoxW(NULL, msg, L"Nhắc tâm - Mindful Keyboard",
                MB_OK | MB_ICONINFORMATION | MB_TOPMOST | MB_SETFOREGROUND);
    InterlockedExchange(&g_popupShowing, 0);
    return 0;
}

static void showMindfulPrompt(const wchar_t* message) {
    if (InterlockedCompareExchange(&g_popupShowing, 1, 0) != 0)
        return;   // đang có 1 hộp thoại -> không chồng thêm
    HANDLE h = CreateThread(NULL, 0, msgThread, (LPVOID)message, 0, NULL);
    if (h)
        CloseHandle(h);
    else
        InterlockedExchange(&g_popupShowing, 0);
}

static void analyzeOnWorker(const wstring& word) {
    g_buffer.pushWord(word);
    SendRiskResult scored = SendRiskAnalyzer_Analyze(g_buffer.recentText());
    g_lastSendRisk = scored.risk;

    {
        lock_guard<mutex> lock(g_sampleMutex);
        g_sampleSum += scored.risk;
        g_sampleCount++;
    }

    // [MINDFUL] GĐ6 — "tâm đang động": icon khay đổi sang sóng biên độ cao rồi tự lắng về sau vài
    // giây (BRAND-ASSETS.md §6). Nhận diện là BIÊN ĐỘ, không phải màu — icon vẫn teal, không cam.
    //
    // NGƯỠNG KHÔNG PHẢI SỐ TỰ NGHĨ. §6 nói "khi MoodWatcher báo mức 4-5"; §5 neo nghĩa 2 mức đó
    // vào chính cơ chế đang chạy: mức 4 "Sóng" = "chuông có thể ngân mời" (ngưỡng gợn của
    // NudgeCoordinator), mức 5 "Cuộn" = "kích hoạt lớp nhịp thở" (gác cổng). Nên mức 4-5 bắt đầu
    // đúng ở ngưỡng gợn — và như vậy nó tự tôn trọng lựa chọn Độ nhạy của người dùng.
    //
    // Còn EmotionWaveAmplitude() lo phần dead-zone 0.3 + dâng mượt: dưới đó mặt hồ PHẲNG TUYỆT ĐỐI,
    // không rung rinh vì một chữ hơi nặng.
    if (EmotionWaveAmplitude(scored.risk) > 0.0 &&
        scored.risk >= NudgeCoordinator_RippleThreshold()) {
        SystemTrayHelper::showWaveAlert();   // an toàn từ luồng worker: nó chỉ PostMessage
    }

    // [MINDFUL] GĐ4 — đếm chuỗi câu căng LIÊN TIẾP, độc lập với ngưỡng nhắc thụ động bên dưới.
    // Đặt ĐÚNG chỗ macOS đặt (MoodWatchMac.mm: ngay sau khi gán g_lastSendRisk). Ngưỡng "gợn"
    // thấp hơn kSendRiskThreshold có chủ đích: đây là phát hiện "đang dồn nén dần", không phải
    // "sắp gửi thứ gây hại" -> bắt sớm hơn. Câu dịu lại thì reset — "chuỗi" nghĩa là LIÊN TỤC.
    if (scored.risk >= NudgeCoordinator_RippleThreshold())
        g_tenseStreak++;
    else
        g_tenseStreak = 0;
    if (g_tenseStreak >= NudgeCoordinator_TenseStreakTrigger()) {
        g_tenseStreak = 0;   // reset NGAY, không thì rung lại liên tục cho cùng 1 đợt căng
        Bell_RingForTenseStreak();
    }

    if (scored.risk < kSendRiskThreshold)
        return;

    DWORD now = GetTickCount();
    if (g_lastWarn != 0 && (now - g_lastWarn) < kWarnCooldownMs)
        return;
    g_lastWarn = now;

    showMindfulPrompt(warningForCategory(scored.topCategory));
    g_buffer.clear();
}

static void workerLoop() {
    for (;;) {
        wstring word;
        {
            unique_lock<mutex> lock(g_mutex);
            g_cv.wait(lock, [] { return !g_queue.empty() || g_clearRequested; });
            if (g_clearRequested) {
                g_clearRequested = false;
                g_buffer.clear();
            }
            if (g_queue.empty())
                continue;
            word = g_queue.front();
            g_queue.pop_front();
        }
        if (!vMoodWatch)
            continue;     // user tắt giữa chừng -> bỏ từ đã xếp hàng
        analyzeOnWorker(word);
    }
}

double MoodWatch_LastSendRisk() {
    return g_lastSendRisk;
}

bool MoodWatch_DrainSampleAverage(double* outAvg) {
    lock_guard<mutex> lock(g_sampleMutex);
    if (g_sampleCount <= 0)
        return false;   // nhịp này không gõ gì -> để TRỐNG, không ghi 0 (0 nghĩa là "đã đo, thấy phẳng")
    if (outAvg)
        *outAvg = g_sampleSum / g_sampleCount;
    g_sampleSum = 0.0;
    g_sampleCount = 0;
    return true;
}

void MoodWatch_OnWord(const wstring& word) {
    if (!vMoodWatch || word.empty())
        return;

    // [MINDFUL] P1 CHẶN PHÁT HÀNH (docs/FRICTION-LOG.md 2026-07-17) — đang ở ô mật khẩu, HOẶC
    // chưa chắc là không (fail-closed). Đọc cờ này KHÔNG chạy UIA tại chỗ — chỉ đọc 1 biến đã có
    // sẵn (xem SecureField.h), nên an toàn trên luồng hook. Dọn sạch MoodBuffer NGAY và giữ nó
    // rỗng suốt lúc ở ô mật khẩu, để chữ gõ TRƯỚC lúc vào ô mật khẩu không lẫn với chữ gõ SAU khi
    // rời khỏi (gọi lại mỗi từ bị chặn — idempotent, worker chỉ xoá một buffer vốn đã rỗng).
    if (SecureField_IsActive()) {
        lock_guard<mutex> lock(g_mutex);
        g_queue.clear();
        g_clearRequested = true;
        g_cv.notify_one();
        return;
    }

    {
        lock_guard<mutex> lock(g_mutex);
        // Chống phình nếu worker kẹt ở hộp thoại: bỏ từ CŨ NHẤT, giữ từ mới (câu gần đây mới là
        // thứ đáng đọc). 64 = rộng hơn nhiều so với cửa sổ 15 từ của MoodBuffer.
        if (g_queue.size() >= 64)
            g_queue.pop_front();
        // push_back COPY chuỗi ngay tại đây, khi vẫn còn trên luồng hook và `word` còn sống.
        // BẮT BUỘC: `vOnWordCommitted` truyền tham chiếu tới biến CỤC BỘ của emitCommittedWord()
        // (Engine.cpp:463) — nó chết ngay khi callback return. Vỏ iOS và macOS đều đã ngã đúng hố
        // này; macOS crash 10 lần đêm 2026-07-16 (push_back trên chuỗi đã chết -> length_error ->
        // abort). Xem docs/FRICTION-LOG.md 2026-07-16. ĐỪNG đổi thành đẩy con trỏ/tham chiếu.
        g_queue.push_back(word);
    }
    g_cv.notify_one();
}

// Nói THẲNG cái đang đánh đổi, ngay lúc người ta quyết định — không giấu trong tài liệu mà không
// ai đọc. Trả về true nếu sau lời này lớp cảm xúc được BẬT.
bool MoodWatch_ConfirmEnable(HWND parent) {
    // [MINDFUL] Copy này PHẢI khớp đúng thứ SecureField.cpp đang làm — xem MoodWatch.cpp đầu file
    // + docs/FRICTION-LOG.md 2026-07-17 "CHẶN PHÁT HÀNH". Giọng quan sát, không phán xét (HIẾN
    // CHƯƠNG §2.2): nói thẳng cơ chế đang chạy VÀ giới hạn còn lại, không tô hồng cũng không doạ.
    return MessageBoxW(parent,
        L"Bật lớp cảm xúc?\n\n"
        L"Nó đọc những từ bạn gõ (chỉ trong máy, không gửi đi đâu) để biết khi nào mặt hồ đang gợn.\n\n"
        L"Ô mật khẩu được tự động bỏ qua: bộ gõ dùng UI Automation của Windows để nhận ra ô mật "
        L"khẩu, và khi CHƯA CHẮC (vừa đổi focus, chưa kịp hỏi xong) thì luôn coi như đang ở ô mật "
        L"khẩu — thà bỏ sót vài trăm mili-giây còn hơn đọc nhầm.\n\n"
        L"Còn một giới hạn CHƯA kiểm chứng hết: cách này chắc chắn nhận ra ô mật khẩu chuẩn của "
        L"Windows, nhưng với ô mật khẩu tự vẽ trong một số trình duyệt/ứng dụng thì phụ thuộc vào "
        L"việc app đó có khai báo đúng cho Windows biết hay không — chưa có ai xác nhận đủ trên máy "
        L"Windows thật cho từng loại.",
        L"Mindful Keyboard", MB_YESNO | MB_ICONWARNING) == IDYES;
}

void MoodWatch_Toggle() {
    if (!vMoodWatch && !MoodWatch_ConfirmEnable(NULL))
        return;   // muốn bật nhưng đọc xong đổi ý -> giữ nguyên tắt
    APP_SET_DATA(vMoodWatch, !vMoodWatch);   // đảo + lưu registry
    if (!vMoodWatch) {
        lock_guard<mutex> lock(g_mutex);
        g_queue.clear();
        g_clearRequested = true;             // để worker tự dọn MoodBuffer (chỉ nó được chạm)
        g_cv.notify_one();
    } else {
        // Hỏi ghi nhật ký NGAY SAU khi người dùng bật lớp cảm xúc — đây là chỗ câu hỏi mới có
        // nghĩa: từ giây này mới có thứ để ghi. Trước 2026-07-17 nó nằm trong OpenKeyInit() và
        // treo cứng khởi động (xem OpenKey.cpp) — đừng đưa nó về đó.
        // An toàn để modal ở đây: Toggle() chạy trên luồng giao diện, vốn đã có vòng lặp thông điệp
        // và một cửa sổ để hộp thoại bám vào. Hai câu hỏi liên tiếp là CỐ Ý — đọc (sóng) và ghi
        // (nhật ký) là hai quyền khác nhau, đồng ý cái này không kéo theo cái kia.
        MoodStore_AskConsentIfNeeded();
    }
}

void MoodWatch_Init() {
    if (!g_workerStarted) {
        g_workerStarted = true;
        // detach: worker sống suốt đời tiến trình, y như serial queue bên macOS. Không join lúc
        // thoát — nó chỉ chờ trên condition_variable, không giữ file/khoá nào.
        thread(workerLoop).detach();
    }
    vOnWordCommitted = MoodWatch_OnWord;
}
