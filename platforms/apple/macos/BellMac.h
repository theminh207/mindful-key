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

void BellMac_Init();
void BellMac_ApplySettings();
void BellMac_ShowSettings();

// [MINDFUL] Bước 7 — chuông data-driven. Gọi từ MoodWatchMac khi phát hiện 1 chuỗi câu căng
// thẳng liên tiếp (không chờ tới lịch cố định). Tự tôn trọng cooldown dùng chung với nhắc thụ
// động (xem NudgeCoordinatorMac) và trạng thái snooze.
void BellMac_RingForTenseStreak(void);

// Tạm hoãn chuông (kể cả rung theo lịch lẫn theo chuỗi căng thẳng) trong N phút — "dễ tắt tạm".
void BellMac_Snooze(int minutes);

// [MINDFUL] Story 1.5 — nghe thử âm chuông đang chọn (âm + âm lượng đọc tươi từ UserDefaults:
// vBellSoundName / vBellVolume). Dùng cho "nghe thử khi chọn" ở BellSettingsView (EXPERIENCE Journey B).
void BellMac_PreviewSound(void);

#ifdef __cplusplus
}
#endif

#endif /* BellMac_h */
