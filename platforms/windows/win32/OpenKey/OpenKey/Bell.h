//
// Bell.h — [MINDFUL] Chuông tỉnh thức: theo lịch, nhắc người dùng dừng lại hít thở.
// File MỚI của dự án mindful-keyboard (không thuộc OpenKey gốc).
//
#pragma once
#include <windows.h>

extern int vBell;          // 0=tắt, 1=bật
extern int vBellInterval;  // nhắc mỗi N phút
extern int vBellFrom;      // giờ bắt đầu (0-23)
extern int vBellTo;        // giờ kết thúc (0-23)

void Bell_Init();                     // nạp cài đặt + bật timer (gọi lúc app khởi động)
void Bell_ApplySettings();            // áp dụng lại timer sau khi đổi cài đặt
void Bell_ShowSettings(HWND parent);  // mở dialog cài đặt chuông
