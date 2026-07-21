//
// ReflectionScreen.h — [MINDFUL] màn "Soi lại hôm nay". Bản Windows.
// File MỚI của dự án mindful-keyboard (không thuộc OpenKey gốc).
//
// Đối ứng của platforms/apple/macos/ReflectionScreenMac.{h,mm} + EmotionRiverView.mm.
// Xem .cpp cho 3 luật vẽ bất khả xâm phạm.
//
// Thiết kế để TỰ NHẬN RA, không phải thống kê cho vui: câu hỏi phản chiếu là trọng tâm, số liệu
// chỉ là bối cảnh phụ. Cố ý không biểu đồ.
//
#pragma once
#include <windows.h>
#include <vector>
#include "MoodStore.h"

// Mở màn Soi lại. Tự báo nhẹ nếu nhật ký đang tắt (không có gì để soi).
void ReflectionScreen_Show(HWND parent);

// [MINDFUL] Vẽ dòng sông cảm xúc vào HDC.
// recentMode = true: Chế độ "Ngay bây giờ" (cửa sổ trượt 3h quá khứ, 1h tương lai) cho Popover.
// recentMode = false: Chế độ "Hôm nay" (cả ngày) cho Soi lại.
void EmotionRiver_Draw(HDC hdc, const RECT& rect, const std::vector<MoodSample>& samples, bool recentMode, double liveHead);
