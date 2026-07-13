//
//  PanelViewController.h
//  Mindful Keyboard — based on OpenKey
//
//  [MINDFUL] "Áo mới" Bước 1 — nội dung popover trạng thái (menu-bar), bố cục 3 TAB thay vì
//  scroll-list dài: header "〜 mindful-key" → thanh tab (segmented kiểu Haynoi, white-active)
//  "Hôm nay · Chuông · Bộ gõ" → đúng 1 thẻ đang chọn → chân trang riêng tư. Mỗi tab vừa 1 màn,
//  chiều cao popover co theo tab đang mở. 3 view con (GatekeeperCardView/BellSettingsView/
//  InputMethodCardView) TÁI DÙNG y hệt bản scroll-list cũ — chỉ đổi container xếp chúng.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface PanelViewController : NSViewController

/// Bấm nút gear ⋯ trên header → host hiện menu cũ (mọi mục còn lại). `anchor` là nút gear để
/// định vị menu. Host (AppDelegate) gắn hành vi.
@property (nonatomic, copy, nullable) void (^onShowMenu)(NSView *anchor);

/// Bấm thẻ "Bộ gõ ▸" → host mở cài đặt bộ gõ đầy đủ (PHA 1: cửa sổ 4-tab cũ).
@property (nonatomic, copy, nullable) void (^onOpenFullSettings)(void);

/// Đọc lại toàn bộ trạng thái (gọi mỗi khi popover sắp mở).
- (void)refreshAll;

/// Kích thước nội dung mong muốn cho popover (rộng 360, cao co theo nội dung tới ngưỡng rồi cuộn).
- (NSSize)panelContentSize;

@end

NS_ASSUME_NONNULL_END
