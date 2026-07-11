//
//  AppGroupBridge.h
//  mindful-key — shared (macOS + iOS)
//
//  Cầu nối "nhịp tim" (heartbeat) giữa keyboard extension và container app qua App Group
//  NSUserDefaults. Vấn đề nền tảng: iOS KHÔNG có API công khai để container tự hỏi "bàn phím
//  của tôi đã được bật trong Cài đặt chưa". Giải pháp thực dụng: extension ghi 1 timestamp mỗi
//  lần nó chạy; container đọc lại khi vào foreground để đoán "đã từng chạy".
//
//  ⚠️ GIỚI HẠN CHẤP NHẬN ĐƯỢC (Round 1, KHÔNG phải bug): heartbeat chỉ nói "bàn phím ĐÃ TỪNG
//  chạy", KHÔNG có tín hiệu ngược — nếu người dùng TẮT lại bàn phím trong Cài đặt, container
//  không cách nào biết. Đừng khẳng định sai "đang bật".
//
//  RÀNG BUỘC RIÊNG TƯ (cứng): App Group NSUserDefaults ở đây CHỈ chứa 2 khoá vận hành —
//  1 timestamp (NSDate) + 1 bool Full Access. TUYỆT ĐỐI không nhận/ghi bất kỳ NSString nào
//  chứa nội dung người dùng gõ (NFR-03 / FR-A07).
//
//  KHÔNG import UIKit/AppKit — thuần Foundation, để tests/ios chạy được trên host và để file
//  dùng chung được cho cả vỏ macOS lẫn iOS mà không lệ thuộc API riêng OS.
//

#ifndef AppGroupBridge_h
#define AppGroupBridge_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// 3 trạng thái container suy ra từ App Group heartbeat.
typedef NS_ENUM(NSInteger, AppGroupKeyboardStatus) {
    AppGroupKeyboardStatusNeverRan = 0,        // chưa từng ghi heartbeat → hướng dẫn kích hoạt
    AppGroupKeyboardStatusRanNoFullAccess,     // đã chạy, chưa cấp Full Access
    AppGroupKeyboardStatusRanWithFullAccess,   // đã chạy, có Full Access
};

// Gọi TỪ keyboard extension (viewDidLoad, mỗi lần bàn phím dựng). Ghi timestamp hiện tại +
// cờ Full Access (đọc từ self.hasFullAccess của extension — cờ này CHỈ đọc được từ bên trong
// extension) vào App Group dùng chung. Suite nil (entitlement sai) → im lặng bỏ qua, không crash.
// FOUNDATION_EXPORT = extern "C" khi biên dịch C++ (.mm) → giữ C linkage nhất quán, để container
// (.m, Objective-C thuần) và extension (.mm, Objective-C++) cùng gọi được một symbol.
FOUNDATION_EXPORT void KeyboardExtension_WriteHeartbeat(BOOL hasFullAccess);

// Gọi TỪ container app (lúc vào foreground). Mở App Group, đọc 2 khoá, trả 1 trong 3 trạng thái.
// Suite nil / chưa có heartbeat → AppGroupKeyboardStatusNeverRan (fallback an toàn về hướng dẫn).
FOUNDATION_EXPORT AppGroupKeyboardStatus ContainerApp_ReadKeyboardStatus(void);

// Hàm THUẦN suy trạng thái từ 2 giá trị đầu vào — tách khỏi việc mở NSUserDefaults thật để
// test được trên host (không cần entitlements/Simulator). heartbeatAt == nil → NeverRan.
FOUNDATION_EXPORT AppGroupKeyboardStatus AppGroupBridge_DeriveStatus(NSDate *_Nullable heartbeatAt, BOOL hasFullAccess);

NS_ASSUME_NONNULL_END

#endif /* AppGroupBridge_h */
