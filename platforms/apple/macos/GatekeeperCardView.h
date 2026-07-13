//
//  GatekeeperCardView.h
//  Mindful Keyboard — based on OpenKey
//
//  [MINDFUL] Story 1.4 — Card "Gác cổng gửi tin" (Feature #1, tính năng vương miện).
//  [MINDFUL] Áo mới v2 (2026-07-13, decision-log "Diện mạo mới v2") — đổi từ dải nền tealLight
//  sang thẻ TRẮNG viền mảnh (khớp mockup-v2-tabbed.html .card trong tab "Hôm nay"). Tiêu đề tĩnh
//  "Gác cổng gửi tin" bị bỏ — tít giờ là CÂU TRẠNG THÁI động lấy thẳng từ EmotionWaveView.
//
//  Ràng buộc HIẾN CHƯƠNG khoá trong file này (docs/AGENT-BRIEF.md §2.2/2.3):
//    - Chứa EmotionWaveView + đúng 1 câu mô tả quan-sát-không-phán-xét làm tít.
//    - State "tắt": sóng phẳng + copy trung tính, KHÔNG màu đỏ / xám-chết cảnh báo.
//    - Lối tắt "Soi lại hôm nay →" gọi ReflectionScreenMac_Show().
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface GatekeeperCardView : NSView

/// Đọc lại trạng thái thật (bật/tắt gác cổng + send-risk hiện tại) và cập nhật giao diện.
/// Gọi khi panel mở hoặc khi trạng thái đổi.
- (void)refresh;

/// Chiều cao cần để hiện đủ (sóng + tít trạng thái + hàng phụ đề/link) — host popover dùng để xếp thẻ.
- (CGFloat)preferredHeight;

@end

NS_ASSUME_NONNULL_END
