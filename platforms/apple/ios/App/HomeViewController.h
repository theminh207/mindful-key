//
//  HomeViewController.h
//  mindful-key — iOS container app (Màn Home, story 1.7)
//
//  Màn Home tối thiểu Round 1: trạng thái "Bàn phím đã sẵn sàng" + ô gõ thử + nhắc chạm 🌐.
//  Nếu App Group heartbeat báo bàn phím CHƯA từng chạy → nhắc nhẹ quay lại Màn 01 (giọng bình
//  thản, KHÔNG quở). Kế thừa ô "gõ thử" của Mốc A/B để vẫn kiểm bàn phím thủ công được.
//

#import <UIKit/UIKit.h>

@interface HomeViewController : UIViewController

// Gọi khi người dùng chạm "Quay lại hướng dẫn" ở nhánh "chưa bật". AppDelegate gán để điều hướng.
@property (nonatomic, copy) void (^onReturnToActivation)(void);

// Story 2.4: gọi khi người dùng chạm nút "Gõ tắt…" — AppDelegate gán để push
// MacroManagerViewController. Lối vào riêng, không phụ thuộc SettingsViewController của story 2.3
// (xem story 2.4 Dev Notes "Lối vào từ Home — CONTENDED với story 2.3").
@property (nonatomic, copy) void (^onOpenMacroManager)(void);

@end
