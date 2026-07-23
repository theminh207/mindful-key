//
// Bell.h — [MINDFUL] Chuông tỉnh thức: theo lịch, nhắc người dùng dừng lại hít thở.
// File MỚI của dự án mindful-keyboard (không thuộc MindfulKey gốc).
//
#pragma once
#include <windows.h>
#include <string>

extern int vBell;          // 0=tắt, 1=bật
extern int vBellInterval;  // nhắc mỗi N phút
extern int vBellFrom;      // giờ bắt đầu (0-23)
extern int vBellTo;        // giờ kết thúc (0-23)

void Bell_Init();                     // nạp cài đặt + bật timer (gọi lúc app khởi động)
void Bell_ApplySettings();            // áp dụng lại timer sau khi đổi cài đặt
int  Bell_MinutesUntilNextRing();     // [MINDFUL] B5 — số phút tới nhịp kế; -1 khi tắt/hoãn (ẩn dòng)
// [MINDFUL] B8 — Bell_ShowSettings (hộp thoại chuông native cũ IDD_DIALOG_BELL) đã bỏ; cài đặt chuông
// nay nằm ở tab "Chuông" của cửa Cài đặt (mở qua AppDelegate::onBellSettings).

// [MINDFUL] GĐ4 — đối ứng BellMac.mm. Rung vì phát hiện CHUỖI câu căng liên tiếp (khác chuông
// theo lịch): MoodWatch gọi khi chuỗi đủ dài. Đi qua NudgeCoordinator nên không dồn dập.
void Bell_RingForTenseStreak();

void Bell_Snooze(int minutes);   // "tạm hoãn chuông" — dễ tắt tạm
void Bell_PreviewSound();        // nghe thử tiếng+âm lượng đang chọn (bỏ qua mọi cổng chặn)

// Nhận tệp .wav của người dùng làm tiếng chuông riêng. Chép vào kho app rồi mới dùng (tệp gốc có
// thể nằm ở USB/Downloads rồi biến mất). false + outMessage nếu không đọc/chép được.
bool Bell_InstallCustomSound(LPCTSTR path, std::wstring* outMessage);
