//
// MoodWatch.h — [MINDFUL] lớp "nghe lén cảm xúc" cho bản Windows.
// File MỚI của dự án mindful-keyboard (không thuộc OpenKey gốc).
//
#pragma once
#include <string>

// Cờ bật/tắt nhận diện cảm xúc (lưu vào registry, đổi qua menu khay). 1=bật, 0=tắt.
extern int vMoodWatch;

// Bật lớp cảm xúc: đăng ký listener với engine. Gọi 1 lần lúc app khởi động.
void MoodWatch_Init();

// Đảo bật/tắt + lưu cài đặt (gọi từ menu khay).
void MoodWatch_Toggle();

// Được engine gọi mỗi khi một TỪ vừa hoàn chỉnh (qua con trỏ vOnWordCommitted).
// CHẠY TRÊN LUỒNG HOOK BÀN PHÍM — chỉ xếp hàng rồi trả về ngay, không phân tích tại chỗ.
void MoodWatch_OnWord(const std::wstring& word);

// Điểm send-risk [0,1] của câu gần nhất; -1.0 khi chưa phân tích lần nào.
// Đối ứng của MoodWatchMac_LastSendRisk(). Gác cổng gửi tin (GĐ2) sẽ đọc cái này.
double MoodWatch_LastSendRisk();
