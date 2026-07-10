//
//  NudgeCoordinatorMac.h
//  ModernKey
//
//  [MINDFUL] Bước 7 — gộp tín hiệu "nhắc thụ động" (MoodWatchMac) và "chuông" (BellMac) vào
//  1 mạch nhắc, tránh dồn dập 2 lời nhắc cùng lúc cho cùng 1 khoảnh khắc căng thẳng.
//
//  KHÔNG áp dụng cho gác cổng gửi tin (SendGatekeeperMac) — đó là Feature #1, luôn phải hiện
//  khi điều kiện đủ, không bị cooldown chung này che mất (xem docs/PRD.md §1).
//

#ifndef NudgeCoordinatorMac_h
#define NudgeCoordinatorMac_h

#ifdef __cplusplus
extern "C" {
#endif

// YES nếu đã đủ lâu (>= cooldown) kể từ lần nhắc gần nhất (thụ động HOẶC chuông).
BOOL NudgeCoordinatorMac_ShouldNudge(void);

// Gọi ngay khi 1 lời nhắc (thụ động hoặc chuông) vừa hiện ra, để lời nhắc kia lùi lại.
void NudgeCoordinatorMac_MarkNudged(void);

// [MINDFUL] Story 1.5 — số câu căng thẳng LIÊN TIẾP cần đạt trước khi chuông rung theo chuỗi.
// Đọc mức nhạy người dùng chọn (UserDefaults "vBellSensitivity" 1..3) và ánh xạ:
//   1 = Ít nhạy  → ngưỡng CAO hơn (khó rung hơn)
//   2 = Vừa      → 3 (giữ hành vi hiện hành khi chưa từng lưu)
//   3 = Nhạy     → ngưỡng THẤP hơn (dễ rung hơn)
// Lưu ý: story 1.5 chỉ dựng getter này. Việc gọi nó THAY cho hằng số kTenseStreakTrigger hardcode
// trong MoodWatchMac.mm (mood-layer) là 1 việc riêng, NGOÀI phạm vi 1.5 (xem story Dev Notes #2).
int NudgeCoordinatorMac_TenseStreakTrigger(void);

#ifdef __cplusplus
}
#endif

#endif /* NudgeCoordinatorMac_h */
