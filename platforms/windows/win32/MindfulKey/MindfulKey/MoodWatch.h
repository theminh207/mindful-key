//
// MoodWatch.h — [MINDFUL] lớp "nghe lén cảm xúc" cho bản Windows.
// File MỚI của dự án mindful-keyboard (không thuộc MindfulKey gốc).
//
#pragma once
#include <string>
#include <vector>
#include "../../../../../core/mood/MoodPhrasing.h"   // MoodSample {ts, value}

// Cờ bật/tắt nhận diện cảm xúc (lưu vào registry, đổi qua menu khay). 1=bật, 0=tắt.
extern int vMoodWatch;

// Bật lớp cảm xúc: đăng ký listener với engine. Gọi 1 lần lúc app khởi động.
void MoodWatch_Init();

// Đảo bật/tắt + lưu cài đặt (gọi từ menu khay).
void MoodWatch_Toggle();

// Hỏi + nói thẳng giới hạn ô mật khẩu của bản Windows. true = người dùng đồng ý bật.
// Gọi TRƯỚC khi bật ở BẤT KỲ đường nào (menu khay, checkbox cửa sổ Điều khiển).
bool MoodWatch_ConfirmEnable(HWND parent);

// Được engine gọi mỗi khi một TỪ vừa hoàn chỉnh (qua con trỏ vOnWordCommitted).
// CHẠY TRÊN LUỒNG HOOK BÀN PHÍM — chỉ xếp hàng rồi trả về ngay, không phân tích tại chỗ.
void MoodWatch_OnWord(const std::wstring& word);

// Điểm send-risk [0,1] của câu gần nhất; -1.0 khi chưa phân tích lần nào.
// Đối ứng của MoodWatchMac_LastSendRisk(). Gác cổng gửi tin (GĐ2) sẽ đọc cái này.
double MoodWatch_LastSendRisk();

// [MINDFUL] GĐ3 — nhịp chung (Bell_TimerProc) gọi để LẤY RA rồi XOÁ risk trung bình của nhịp vừa
// qua. true = có mẫu. Mô hình lấy mẫu (SYNC-emotion-mechanism-v2.md §A): để ý liên tục trong RAM,
// ghi 1 số trung bình mỗi nhịp; quãng KHÔNG gõ để TRỐNG (không bịa nước giả lên dòng sông).
bool MoodWatch_DrainSampleAverage(double* outAvg);

// [MINDFUL] B1/B2 — "sông sống": đầu sóng "bây giờ" (biên độ đã làm mượt + phai theo thời gian im).
// Đối ứng MoodWatchMac_LiveAmplitude(). Trả -1.0 khi chưa gõ / đã im ≥5 phút -> KHÔNG vẽ đầu sóng
// (hợp đồng dec.4: idle = mặt hồ lặng, không bịa nước). Ngược lại 0..1.
double MoodWatch_LiveAmplitude();

// Vệt điểm dày trong `windowSeconds` gần nhất cho sông "Ngay bây giờ": trộn vệt RAM (dày, phiên này)
// với mẫu đã lưu (thưa, quá khứ). Đối ứng MoodWatchMac_FetchLiveTrace(). Rỗng nếu tắt nhắc tâm.
std::vector<MoodSample> MoodWatch_FetchLiveTrace(int windowSeconds);
