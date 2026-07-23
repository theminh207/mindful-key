//
// MoodStore.h — [MINDFUL] kho nhật ký cảm xúc cục bộ, mã hoá. Bản Windows.
// File MỚI của dự án mindful-keyboard (không thuộc MindfulKey gốc).
//
// Đối ứng của platforms/apple/macos/MoodStoreMac.{h,mm} — bản macOS là CHUẨN HÀNH VI.
//
// ── HAI KHÁC BIỆT LỚN so với macOS, cả hai do chủ dự án chốt 2026-07-17 ──
//
// 1. KHÔNG SQLite. macOS dùng SQLite + AES-256(CommonCrypto) + khoá Keychain. Chủ dự án chốt
//    "trước mắt chưa cần tới SQLite" — và đúng: nhật ký là GHI THÊM liên tục, ĐỌC một lần cuối
//    ngày. Không có JOIN, không truy vấn phức tạp. SQLite là dao mổ trâu, mà mang nó vào còn là
//    thêm dependency nặng (dự án đã từ chối SQLCipher vì lý do y hệt).
//    Nay: một tệp phẳng, mỗi sự kiện một dòng TSV, mã hoá TOÀN TỆP.
//
// 2. DPAPI thay Keychain. `CryptProtectData` khoá dữ liệu theo TÀI KHOẢN WINDOWS đang đăng nhập.
//    Hệ quả người dùng PHẢI biết, chủ dự án đã xác nhận biết khi chốt:
//      - Ai đăng nhập được vào tài khoản Windows đó thì đọc được nhật ký (Keychain của Mac có thể
//        đòi mật khẩu riêng; DPAPI thì không).
//      - Chép tệp `mood.enc` sang máy khác / tài khoản khác là KHÔNG đọc được. Đây là tính năng
//        (dữ liệu không đi theo tệp), nhưng cũng nghĩa là mất tài khoản = mất nhật ký.
//    Đổi lại: không thêm dependency nào, khoá do Windows quản lý, không có khoá nào nằm trong
//    code hay registry để ai đó moi ra.
//
// ── SCHEMA: BẤT BIẾN, không được tự đổi ──
// Cùng tên trường + cùng `event_type` với macOS/iOS. `bmad-output/_shared/
// SYNC-emotion-mechanism-v2.md §A` chốt điều này để nhật ký 3 vỏ CÙNG DẠNG — lệch là dòng sông
// giữa các máy hết so được.
//
// ── ĐIỀU KHO NÀY KHÔNG BAO GIỜ CHỨA ──
// KHÔNG nội dung gõ. Không câu chữ. Chỉ con số + nhãn ngắn định nghĩa sẵn. Cột trụ riêng tư:
// "không gửi nội dung gõ đi đâu" — kể cả đi vào ổ cứng của chính người dùng.
//
#pragma once
#include <windows.h>
#include <string>
#include <vector>
#include "../../../../../core/mood/MoodPhrasing.h"   // MoodSample

// ── Consent ──
// Hỏi MỘT LẦN lúc khởi động. CỐ Ý không hỏi giữa lúc đang căng thẳng — hỏi đúng lúc người ta
// bực là ép đồng ý, không phải xin phép.
bool MoodStore_HasConsent();
void MoodStore_SetConsent(bool granted);   // false = XOÁ SẠCH mọi thứ đã ghi
bool MoodStore_HasAskedConsent();
void MoodStore_AskConsentIfNeeded();

// ── Ghi ──
// Mọi hàm ghi tự im lặng nếu chưa có consent. Vỏ KHÔNG phải tự kiểm.
// `appExeName`: tên tiến trình (vd "Zalo.exe") — đối ứng app_bundle_id bên macOS.
// `choice`: "send_anyway" | "wait" | "dismissed" — đúng 3 giá trị của BreathingPauseChoice.
void MoodStore_LogGatekeeperEvent(double sendRisk, const std::wstring& appExeName,
                                  const std::wstring& choice);

// Một điểm trên dòng sông: risk TRUNG BÌNH của nhịp vừa qua. Gọi từ nhịp chung (Bell_TimerProc).
void MoodStore_LogSampleEvent(double avgRisk);
void MoodStore_LogCheckinEvent(int waveLevel);   // [MINDFUL] C5 — tự thuật 1=phẳng·2=gợn nhẹ·3=gợn sóng

// ── Đọc / xoá ──
struct MoodTodaySummary {
    int    gatekeeperCount = 0;   // số lần gác cổng hôm nay
    int    sampleCount = 0;
    double avgRisk = 0.0;         // trung bình các sample hôm nay
    double peakRisk = 0.0;        // đỉnh — dùng phân loại hình dạng ngày
    int    peakHour = -1;         // giờ có risk cao nhất; -1 = chưa đủ dữ liệu
};
MoodTodaySummary MoodStore_FetchTodaySummary();

// Mẫu hôm nay, theo thứ tự thời gian. Dòng sông cần TỪNG điểm (kèm giờ thật) chứ không chỉ tổng
// kết — vị trí ngang của mỗi chấm tính từ GIỜ THẬT, không từ thứ tự. Bản macOS từng suy vị trí từ
// chỉ số mẫu và chấm cuối luôn dính mép phải: 7 mẫu trong 48 phút buổi sáng vẽ ra như trọn một
// ngày, nhãn Sáng/Trưa/Chiều/Tối thành ra nói dối (vá 2026-07-16). Đừng lặp lại.
std::vector<MoodSample> MoodStore_FetchTodaySamples();

// [MINDFUL] Đọc các mẫu nhịp trong N giây qua. Trả về rỗng nếu tắt nhắc tâm.
std::vector<MoodSample> MoodStore_FetchRecentSamples(int pastSeconds);

void MoodStore_DeleteAll();       // xoá tệp. Hành động CHỦ ĐỘNG của người dùng, không bao giờ tự động.
