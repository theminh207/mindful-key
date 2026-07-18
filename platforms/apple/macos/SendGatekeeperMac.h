//
//  SendGatekeeperMac.h
//  ModernKey
//
//  [MINDFUL] Bước 5 — gác cổng gửi tin thật trên macOS. Phát hiện "sắp gửi trong app chat"
//  (Enter/Return không Shift, trong app đã allow-list) và kích hoạt hợp đồng "nhịp thở"
//  (BreathingPause.h) trước khi tin thực sự rời máy.
//

#ifndef SendGatekeeperMac_h
#define SendGatekeeperMac_h

#import <Cocoa/Cocoa.h>

#ifdef __cplusplus
extern "C" {
#endif

// [MINDFUL] 2026-07-19 — công tắc bật/tắt gác cổng gửi tin (Feature #1). MẶC ĐỊNH BẬT (=1).
// Tắt = ShouldIntercept luôn trả NO (không chặn Enter, không hiện màn Nhịp thở), nhưng lớp cảm
// xúc/nhật ký/sông VẪN chạy độc lập (do vMoodWatch quản). Nạp từ NSUserDefaults "vSendGatekeeper"
// trong AppDelegate fillData, đổi qua menu khay "Gác cổng gửi tin".
extern int vSendGatekeeper;

// Gọi từ OpenKeyCallback, NGAY SAU check "đừng xử lý sự kiện tự mình tạo ra" (dòng đầu hàm).
// Trả YES nếu đây là khoảnh khắc cần chặn-mềm: Enter/Return không Shift, app đang focus nằm
// trong allow-list, VÀ send-risk hiện tại (MoodWatchMac_LastSendRisk()) đã vượt ngưỡng.
BOOL SendGatekeeperMac_ShouldIntercept(CGEventRef event, CGEventType type);

// Hiện overlay nhịp thở thật (NSPanel nổi, non-activating — không cướp focus khỏi app chat).
// PHẢI gọi trên main thread (dispatch_async nếu gọi từ event tap callback). An toàn gọi nhiều
// lần liên tiếp — nếu đã có overlay đang hiện, gọi thêm không tạo overlay chồng lên nhau.
void SendGatekeeperMac_ShowPause(void);

#ifdef __cplusplus
}
#endif

#endif /* SendGatekeeperMac_h */
