//
//  GatekeeperCardView.h
//  Mindful Keyboard — based on OpenKey
//
//  [MINDFUL] Story 1.4 — Card "Gác cổng gửi tin" (Feature #1, tính năng vương miện).
//
//  Ràng buộc HIẾN CHƯƠNG khoá trong file này (docs/AGENT-BRIEF.md §2.2/2.3):
//    - Card full-width, viền teal đậm hơn card khác — luôn nổi bật nhất, KHÔNG ngang hàng
//      với card Chuông/Bộ gõ.
//    - Chứa EmotionWaveView ở chế độ THU GỌN + đúng 1 câu mô tả quan-sát-không-phán-xét.
//    - State "tắt": sóng phẳng + copy trung tính, KHÔNG màu đỏ / xám-chết cảnh báo.
//    - Lối tắt "Soi lại hôm nay →" gọi ReflectionScreenMac_Show().
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface GatekeeperCardView : NSView

/// Đọc lại trạng thái thật (bật/tắt gác cổng + send-risk hiện tại) và cập nhật giao diện.
/// Gọi khi panel mở hoặc khi trạng thái đổi.
- (void)refresh;

@end

NS_ASSUME_NONNULL_END
