//
//  ActivationViewController.h
//  mindful-key — iOS container app (onboarding Màn 01, story 1.7)
//
//  Màn 01 — Kích hoạt bàn phím: dẫn người dùng bật Mindful Key trong Cài đặt hệ thống (3 bước
//  đánh số + "Mở Cài đặt" + fallback "Chưa thấy?"). Tự chuyển sang Màn 02 do AppDelegate điều
//  phối khi App Group heartbeat báo bàn phím đã chạy. Lối tiến thủ công (onContinueAnyway) chỉ
//  hiện SAU KHI người dùng đã rời sang Cài đặt rồi quay lại mà heartbeat chưa nhảy — để không
//  kẹt vĩnh viễn nếu App Group hụt (finding FRICTION-LOG 2026-07-12), nhưng cũng không hiện ngay
//  từ đầu để khỏi khuyến khích bỏ qua bước bật thật.
//

#import <UIKit/UIKit.h>

@interface ActivationViewController : UIViewController
// Gọi khi người dùng tự bấm "Đã thêm xong — tiếp tục" (lối thoát êm khi heartbeat không nhảy).
@property (nonatomic, copy) void (^onContinueAnyway)(void);
@end
