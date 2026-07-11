//
//  FullAccessViewController.h
//  mindful-key — iOS container app (onboarding Màn 02, story 1.7)
//
//  Màn 02 — Về Full Access: minh bạch quyền TRƯỚC khi iOS hỏi, dùng "cặp biên độ mang nghĩa"
//  (sóng teal "Bật lên để" / đường phẳng stoneStrong "Không bao giờ") + luôn có lối "Để sau".
//

#import <UIKit/UIKit.h>

@interface FullAccessViewController : UIViewController

// Gọi khi người dùng chọn "Bật Truy cập Đầy đủ" (sau khi mở Cài đặt) HOẶC "Để sau" — cả 2 đều
// đi tới Home. AppDelegate gán để điều hướng.
@property (nonatomic, copy) void (^onFinish)(void);

@end
