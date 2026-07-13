//
//  NudgeCoordinatorIOS.h
//  mindful-key — iOS keyboard extension (Round 2, story 2.6)
//
//  Chuông NHẮC NGHỈ sau N câu căng thẳng LIÊN TIẾP — mirror 1:1 mô hình đã chứng minh chạy ổn
//  định trên macOS (`NudgeCoordinatorMac` + `BellMac_RingForTenseStreak` + phần đếm chuỗi liên
//  tiếp trong `MoodWatchMac.mm`, ĐỌC TRỰC TIẾP, KHÔNG SỬA — xem Dev Notes story 2.6). 3 hằng số
//  dưới đây COPY ĐÚNG giá trị macOS, không tự chế (đổi tên tránh riêng từ tiếng Anh bị brand-lint
//  chặn — HIẾN CHƯƠNG §2.2 cấm mọi từ khoá gamification, kể cả trong code/comment — GIÁ TRỊ giữ
//  nguyên, chỉ tên gọi khác):
//    - kTenseStreakThreshold = 0.35  [Source: MoodWatchMac.mm dòng 47]
//    - kTenseStreakTrigger   = 3     [Source: MoodWatchMac.mm dòng 48]
//    - kCooldownSeconds      = 45.0  [Source: NudgeCoordinatorMac.mm dòng 11]
//
//  CẤU HÌNH (bật/tắt + tạm hoãn) KHÔNG sống ở đây — xem `platforms/apple/shared/BellReminderSettingsBridge.h`.
//  Lý do tách: màn Cài đặt (container app, target MindfulKeyiOS) cần đọc/ghi 2 khoá đó nhưng
//  KHÔNG được kéo theo phần hiệu ứng thật (UIKit + AudioToolbox) của file NÀY vào target container
//  (file này CHỈ compile vào target extension MindfulKeyKeyboard). File này GỌI SANG
//  BellReminderSettingsBridge để đọc cấu hình, không tự làm I/O App Group riêng.
//
//  KIẾN TRÚC — tách THUẦN (đếm số câu liên tiếp + gate + cooldown, Foundation-only, host-testable)
//  khỏi HIỆU ỨNG THẬT (haptic + âm, UIKit/AudioToolbox-only, chỉ verify thủ công trên
//  Simulator/thiết bị) — đúng pattern đã dùng ở KeyboardBridge/EmotionWaveAmplitude. File .mm dùng
//  `TARGET_OS_IPHONE` để phần hiệu ứng tự biến mất khi biên dịch cho test host macOS (không cần
//  file thứ 2).
//
//  NƠI GỌI (production) — KHÔNG phải KeyboardViewController.mm. Engine chỉ cho phép DUY NHẤT 1
//  callback `vOnWordCommitted` toàn cục; MoodBridge (story 2.2) đã chiếm callback đó và tính risk
//  MỖI TỪ COMMIT trên 1 serial queue riêng (g_moodQueue). KeyboardViewController KHÔNG có tín hiệu
//  rời rạc "vừa có 1 lần commit mới" — nó chỉ POLL (mỗi 300ms, story 2.5) giá trị risk mới nhất để
//  vẽ sóng ambient, và poll theo nhịp thời gian sẽ phá vỡ đúng ngữ nghĩa "đếm theo LẦN COMMIT" của
//  AC#1 (1 câu căng có thể bị poll trúng nhiều lần → đếm sai, quá nhanh). Vì vậy
//  `NudgeCoordinatorIOS_RegisterSentenceRisk` được gọi TỪ BÊN TRONG `MoodBridge.mm`, ngay cạnh chỗ
//  `g_lastSendRisk` được ghi — đúng vị trí macOS gọi (`MoodWatchMac.mm` đếm chuỗi liên tiếp ngay
//  cạnh chỗ gán `g_lastSendRisk = risk;`, cùng 1 callback, cùng 1 serial queue). Đây là 1 LỆCH so
//  với chữ Tasks gốc của story (nói "wire ở KeyboardViewController.mm") — [Inference], xem Dev
//  Agent Record cuối story để giải trình đầy đủ cho Opus review. AC#6 (ô bảo mật) vẫn giữ nguyên:
//  MoodBridge đã return sớm khi `g_secureFieldActive` bật, TRƯỚC khi chạm tới điểm gọi hàm này —
//  risk không bao giờ tới được `NudgeCoordinatorIOS_RegisterSentenceRisk` khi đang ở ô bảo mật.
//
//  THREAD SAFETY — `NudgeCoordinatorIOS_RegisterSentenceRisk` CHỈ được gọi từ `g_moodQueue`
//  (serial, xem MoodBridge.mm) — vì luôn đơn luồng tại điểm gọi, biến static bên trong (đếm số câu
//  liên tiếp, mốc thời gian nhắc gần nhất) KHÔNG cần khoá riêng, đúng y hệt `g_tenseStreak` bên
//  MoodWatchMac.mm cũng là 1 static int trần không khoá.
//
//  KHÔNG GAMIFY (AC#5, hiến chương): số đếm nội bộ KHÔNG BAO GIỜ được đọc ra để hiển thị UI — file
//  này KHÔNG có getter nào trả về con số đếm hiện tại.
//

#ifndef NudgeCoordinatorIOS_h
#define NudgeCoordinatorIOS_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif

// === Hằng số mirror macOS (copy nguyên giá trị — xem header comment) ===
extern const double NudgeCoordinatorIOS_TenseThreshold;          // 0.35
extern const int NudgeCoordinatorIOS_ConsecutiveTenseTrigger;    // 3
extern const NSTimeInterval NudgeCoordinatorIOS_CooldownSeconds; // 45.0

// Gọi 1 lần mỗi khi MoodBridge (2.2) vừa tính xong 1 giá trị risk mới cho 1 từ commit (xem giải
// trình "NƠI GỌI" ở trên) — KHÔNG gọi theo keystroke, KHÔNG gọi theo nhịp poll UI. Tự đọc cấu hình
// bật/tắt + trạng thái hoãn (qua BellReminderSettingsBridge) + đồng hồ thật; nếu đủ điều kiện sẽ
// tự kích hiệu ứng (haptic + âm) trên main queue. Không trả về gì cho production call site
// (fire-and-forget, giống BellMac_RingForTenseStreak).
void NudgeCoordinatorIOS_RegisterSentenceRisk(double risk);

// ===== CHỈ DÙNG TRONG TEST (tests/ios/nudge_coordinator_ios_test.mm) =====
// KHÔNG gọi từ code sản phẩm — đúng nguyên tắc *_ForTesting đã dùng ở MoodBridge/KeyboardSettingsBridge.

// Reset bộ đếm nội bộ + cooldown về trạng thái ban đầu — mỗi ca test độc lập, không rò rỉ state
// giữa các lần gọi (hàm production ở trên dùng CHUNG state static với hàm test dưới đây).
void NudgeCoordinatorIOS_ResetStateForTesting(void);

// Lõi thuần — KHÔNG chạm App Group thật, KHÔNG chạm hiệu ứng thật (haptic/âm) — enabled/snoozed/now
// truyền tay vào thay vì đọc qua BellReminderSettingsBridge. Trả YES đúng khi lần gọi NÀY khiến
// "chuông" thật sự đủ điều kiện rung (qua hết toàn bộ gate: đạt ngưỡng số câu liên tiếp + bật +
// không hoãn + hết cooldown).
BOOL NudgeCoordinatorIOS_RegisterSentenceRiskForTesting(double risk, BOOL enabled, BOOL snoozed, NSTimeInterval now);

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END

#endif /* NudgeCoordinatorIOS_h */
