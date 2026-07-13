//
//  MoodBridge.mm
//  mindful-key — iOS keyboard extension (Round 2, story 2.2)
//
//  Xem MoodBridge.h cho hợp đồng đầy đủ (async hand-off, cổng ô bảo mật, riêng tư).
//

#import "MoodBridge.h"
#include <atomic>
#include "Engine.h"
#include "MoodBuffer.h"
#include "SendRiskAnalyzer.h"

using namespace std;

// Cửa sổ trượt 15 từ — khớp đúng giá trị macOS đang dùng (MoodWatchMac.mm: MoodBuffer g_buffer(15)).
static MoodBuffer g_moodBuffer(15);
static dispatch_queue_t g_moodQueue;

// std::atomic thay vì biến thường: cờ ô bảo mật được GHI từ main thread (KeyboardViewController,
// mỗi lần chạm phím) và ĐỌC từ cùng main thread bên trong callback đồng bộ của engine — nhưng
// risk lại được GHI từ serial queue riêng và có thể ĐỌC từ nơi khác gọi MoodBridge_LastSendRisk()
// sau này (story 2.5/2.6, chưa rõ thread). atomic tránh data race không cần khoá tường minh.
static std::atomic<bool> g_secureFieldActive{false};
static std::atomic<double> g_lastSendRisk{0.0};

// Callback engine gọi (vOnWordCommitted) — chạy ĐỒNG BỘ, SÂU bên trong vKeyHandleEvent(), trên
// cùng thread gọi letterKeyTapped:/spaceKeyTapped: (main thread của extension, không có
// CGEventTap trên iOS như macOS). Việc TỐI THIỂU duy nhất được phép ở đây: đọc 1 cờ đã cache rồi
// hoặc return ngay, hoặc dispatch_async. KHÔNG BAO GIỜ gom buffer/chạy lexicon tại đây (AC#2).
static void MoodBridge_OnWordCommitted(const wstring& word) {
    if (g_secureFieldActive.load(std::memory_order_relaxed))
        return; // AC#3: bỏ qua hoàn toàn — không buffer, không phân tích, không cập nhật risk
    if (word.empty())
        return;
    if (vLanguage != 1)
        return; // gate "bộ gõ tiếng Việt" — đối xứng vMoodWatch bên macOS (R2 chưa có công tắc riêng cho MoodBridge)

    // Copy TRƯỚC khi tạo block: `word` là tham chiếu (const wstring&) do engine truyền vào lúc
    // gọi đồng bộ — capture trực tiếp 1 tham chiếu C++ trong block Objective-C KHÔNG đáng tin
    // (verify bằng test thật: recentText() rỗng nếu capture thẳng `word`, dù OnWordCommitted vẫn
    // nhận đúng nội dung). Copy 1 wstring cục bộ rồi capture bản copy đó — an toàn kể cả khi tham
    // chiếu gốc hết hiệu lực sau khi hàm này return, TRƯỚC khi block chạy trên serial queue.
    wstring wordCopy = word;
    dispatch_async(g_moodQueue, ^{
        // Từ đây trở đi chạy trên serial queue riêng — KHÔNG BAO GIỜ trên thread xử lý phím.
        g_moodBuffer.pushWord(wordCopy);
        double risk = SendRiskAnalyzer_Analyze(g_moodBuffer.recentText());
        g_lastSendRisk.store(risk, std::memory_order_relaxed);
    });
}

void MoodBridge_Init(void) {
    if (g_moodQueue == nil)
        g_moodQueue = dispatch_queue_create("mindful.keyboard.ios.moodbridge", DISPATCH_QUEUE_SERIAL);
    vOnWordCommitted = MoodBridge_OnWordCommitted;
}

void MoodBridge_SetSecureFieldActive(BOOL active) {
    g_secureFieldActive.store(active ? true : false, std::memory_order_relaxed);
}

double MoodBridge_LastSendRisk(void) {
    return g_lastSendRisk.load(std::memory_order_relaxed);
}

// Test-only — xem MoodBridge.h. dispatch_sync 1 block rỗng vào g_moodQueue: vì đây là hàng đợi
// SERIAL, block rỗng chỉ được thực thi sau khi mọi block đã xếp hàng trước nó (từ
// MoodBridge_OnWordCommitted) chạy xong -> khi dispatch_sync trả về, mọi cập nhật risk tính tới
// lúc gọi đã ghi xong vào g_lastSendRisk.
void MoodBridge_FlushForTesting(void) {
    if (g_moodQueue == nil)
        return;
    dispatch_sync(g_moodQueue, ^{});
}
