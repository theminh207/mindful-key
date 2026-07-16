//
//  BellMac.h
//  ModernKey
//
//  [MINDFUL] macOS mindfulness bell.
//

#ifndef BellMac_h
#define BellMac_h

#ifdef __cplusplus
extern "C" {
#endif

extern int vBell;
extern int vBellInterval;
extern int vBellFrom;
extern int vBellTo;
extern int vBellHotkey;

void BellMac_Init();
void BellMac_ApplySettings();

// [MINDFUL] Bước 7 — chuông data-driven. Gọi từ MoodWatchMac khi phát hiện 1 chuỗi câu căng
// thẳng liên tiếp (không chờ tới lịch cố định). Tự tôn trọng cooldown dùng chung với nhắc thụ
// động (xem NudgeCoordinatorMac) và trạng thái snooze.
void BellMac_RingForTenseStreak(void);

// Tạm hoãn chuông (kể cả rung theo lịch lẫn theo chuỗi căng thẳng) trong N phút — "dễ tắt tạm".
void BellMac_Snooze(int minutes);

// [MINDFUL] Story 1.5 — nghe thử âm chuông đang chọn (âm + âm lượng đọc tươi từ UserDefaults:
// vBellSoundName / vBellVolume). Dùng cho "nghe thử khi chọn" ở BellSettingsView (EXPERIENCE Journey B).
void BellMac_PreviewSound(void);

// [MINDFUL] 2026-07-16 (chủ dự án chỉ đích danh file "Chuông reo.wav") — tiếng báo cho khung CHẤM
// NHỊP ("Mặt hồ đang thế nào?"). CỐ ĐỊNH + nhỏ hơn chuông chính, KHÔNG theo tiếng người dùng chọn:
// đây là việc khác (mời ghi nhận cảm xúc), phải nghe ra ngay là khác tiếng chuông tỉnh thức.
//
// Tôn trọng ĐÚNG mọi cổng chặn của chuông chính (tắt chuông · tạm hoãn · ngoài giờ chuông · chọn
// "Im" · âm lượng 0) — người dùng đã bảo im thì mọi thứ phải im, kêu thêm 1 tiếng là hối thúc.
// Tự bỏ qua, không kêu, nếu bất kỳ cổng nào đóng.
void BellMac_PlayCheckinChime(void);

// [MINDFUL] Áo mới v2 (2026-07-13) — số phút còn lại tới lần chuông kế tiếp, đọc TRỰC TIẾP từ
// NSTimer đang chạy thật (KHÔNG suy đoán/ước lượng). Trả -1 khi: chuông tắt, đang tạm hoãn
// (snooze), hoặc chưa có timer nào — panel dùng -1 để hiện text thật thà ("—") thay vì đếm
// ngược giả (HIẾN CHƯƠNG §2.2: không dữ liệu giả).
int BellMac_MinutesUntilNextRing(void);

#ifdef __cplusplus
}
#endif

#ifdef __OBJC__
#import <Foundation/Foundation.h>
// [MINDFUL] Áo mới v2 — "Im" trong Bộ tiếng segmented (BellSettingsView). KHÔNG phải tên NSSound
// thật; playBellSound() nhận sentinel này và không phát gì (không rơi về "Glass" mặc định).
extern NSString * const kBellSoundMuteName;
NSDate * BellMac_NextRingDate(void);
#endif

#endif /* BellMac_h */
