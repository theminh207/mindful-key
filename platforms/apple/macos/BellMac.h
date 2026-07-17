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

// [MINDFUL] 2026-07-16 — NHỊP DUY NHẤT của app. Trước đây có BA đồng hồ rời nhau cùng lấy
// `vBellInterval` nhưng mỗi cái tự đếm từ lúc chủ nó khởi động, nên chúng TRÔI LỆCH nhau vài phút:
//   · g_bellTimer (BellMac)            → reo tiếng
//   · g_checkinTimer (PanelViewController) → hiện khung chấm nhịp
//   · g_sampleTimer (MoodWatchMac)     → ghi điểm lên sông
// Trong khi màn Chuông hứa thẳng với người dùng: "Một nhịp, hai vai."
//
// Nay `g_bellTimer` là nhịp gốc và bắn thông báo này mỗi lần điểm; 2 nơi kia LẮNG NGHE thay vì tự đếm.
//
// ⚠️ Nhịp KHÔNG phụ thuộc chuông có kêu hay không. Tắt chuông / tạm hoãn / ngoài giờ chuông →
// vẫn bắn nhịp, chỉ TIẾNG bị chặn. Tắt chuông ≠ ngừng ghi nhật ký — gộp nhầm 2 thứ này là âm thầm
// tắt nhật ký của người dùng khi họ chỉ muốn yên tĩnh.
extern NSString * const kMKMoodBeatNotification;

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
// thật; playBellSound() nhận sentinel này và không phát gì (không rơi về tiếng mặc định dưới đây).
extern NSString * const kBellSoundMuteName;

// [MINDFUL] 2026-07-17 — ĐỊNH DANH bộ tiếng, tức thứ MÁY đọc (giá trị của khoá UserDefaults
// `vBellSoundName`) nên phải tiếng Anh theo CLAUDE.md "định danh = tiếng Anh, UI = tiếng Việt".
// Trước đây kho lưu thẳng nhãn tiếng Việt ("Chuông chùa") — vừa nghịch luật, vừa kẹt cứng ngay khi
// có chuông của người dùng: tiếng riêng không có "tên" nào để lưu, chỉ có ĐƯỜNG DẪN tệp.
//
// ⚠️ Ba id dưới ánh xạ sang tên FILE .wav (vẫn tiếng Việt) ở ResourceNameForSoundId() trong
// BellMac.mm — đó là chỗ DUY NHẤT biết tên file, đừng rải tên file ra nơi khác.
extern NSString * const kBellSoundIdTemple;   // → "Chuông chùa.wav" (23.8s)
extern NSString * const kBellSoundIdChime;    // → "Chuông gió.wav"  (10.3s)
extern NSString * const kBellSoundIdWind;     // → "Chuông reo.wav"  (2.0s)
extern NSString * const kBellSoundIdCustom;   // → tệp người dùng tự chọn (kBellCustomPathKey)

// Tiếng người CÀI MỚI nghe khi chưa tự chọn gì. MỘT nguồn sự thật cho cả lối PHÁT (playBellSound)
// lẫn lối HIỆN (BellSettingsView refresh): trước 2026-07-17 hai nơi tự đoán mặc định KHÁC nhau nên
// màn Chuông sáng "Chuông chùa" còn tai nghe "Glass" — ping hệ thống macOS, chưa bao giờ là thiết
// kế (3 file .wav vào bundle từ d377eaf nhưng 2 fallback bị bỏ quên, xem TEST_MATRIX.md dòng 73).
//
// ⚠️ PHẢI là 1 trong các id trên, nếu không màn Chuông sẽ sáng nhầm nút so với tiếng thật sự phát.
extern NSString * const kBellSoundDefaultId;

// Khoá UserDefaults chứa ĐƯỜNG DẪN tệp chuông riêng (tệp đã được chép vào kho của app).
extern NSString * const kBellCustomPathKey;

// Đọc giá trị thô trong UserDefaults → id hiện hành. Nuốt luôn dữ liệu ĐỜI CŨ (nhãn tiếng Việt
// "Chuông chùa"…, tên system sound thời placeholder "Glass"/"Tink") nên KHÔNG cần bước migrate
// riêng: giá trị lạ/rỗng đều rơi về kBellSoundDefaultId. Cả lối phát lẫn lối hiện PHẢI gọi hàm này
// thay vì tự so chuỗi — tự so là mở lại đúng cửa bug "mắt một đằng tai một nẻo".
NSString * BellMac_SoundIdFromStored(NSString *stored);

// Đường dẫn tệp chuông riêng đang dùng, hoặc nil nếu chưa chọn / tệp đã biến mất.
NSString * BellMac_CustomSoundPath(void);

// Chép tệp người dùng chọn vào kho riêng của app rồi ghi nhận làm chuông riêng. Chép chứ không
// giữ đường dẫn gốc: người dùng xoá file nguồn / rút USB thì chuông vẫn phải kêu.
// Trả NO + `outMessage` (câu tiếng Việt hiện thẳng cho người dùng) nếu macOS không phát được tệp
// đó hoặc chép hỏng. KHÔNG tự đổi lựa chọn hiện tại khi thất bại.
BOOL BellMac_InstallCustomSound(NSURL *src, NSString **outMessage);

NSDate * BellMac_NextRingDate(void);
#endif

#endif /* BellMac_h */
