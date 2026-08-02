//
//  NudgeCoordinatorMac.h
//  ModernKey
//
//  [MINDFUL] Bước 7 — gộp tín hiệu "nhắc thụ động" (MoodWatchMac) và "chuông" (BellMac) vào
//  1 mạch nhắc, tránh dồn dập 2 lời nhắc cùng lúc cho cùng 1 khoảnh khắc căng thẳng.
//
//  KHÔNG áp dụng cho gác cổng gửi tin (SendGatekeeperMac) — đó là Feature #1, luôn phải hiện
//  khi điều kiện đủ, không bị cooldown chung này che mất (xem docs/tasks/PRD.md §1).
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

// [MINDFUL] 2026-08-02 (issue #9) — ngưỡng "gợn" của MÔ HÌNH CŨ (send-risk, đọc nội dung câu).
// KHÔNG còn dùng để kích chuông (chuông nay đọc CPM qua BellPolicy — xem TypingCadenceMac.h) —
// hàm này CÒN SỐNG chỉ vì `MoodPhrasingMac_DayShapeSentence`/`ReflectionScreenMac` vẫn dùng nó để
// viết câu quan sát ("Sáng và chiều có gợn...") cho nhật ký send-risk hiện tại (nhánh chưa gỡ,
// việc của #13). Xoá hàm này SỚM HƠN #13 sẽ vỡ build 2 file đó — đã kiểm bằng `git grep`.
// Đọc mức nhạy người dùng chọn (UserDefaults "vBellSensitivity" 1..3).
double NudgeCoordinatorMac_RippleThreshold(void);

#ifdef __cplusplus
}
#endif

#endif /* NudgeCoordinatorMac_h */
