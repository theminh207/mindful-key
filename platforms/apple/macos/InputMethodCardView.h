//
//  InputMethodCardView.h
//  Mindful Keyboard — based on OpenKey
//
//  [MINDFUL] Panel — thẻ "Bộ gõ" thu gọn trong popover. Hiện kiểu gõ đang dùng (Telex/VNI…) +
//  chấm trạng thái bộ gõ Việt đang bật; bấm → mở cài đặt bộ gõ đầy đủ (PHA 1: cửa sổ 4-tab cũ).
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface InputMethodCardView : NSView

/// Bấm "Cài đặt đầy đủ ▸" trong thẻ → mở cửa sổ cài đặt bộ gõ 4-tab (phần chưa gộp vào panel).
@property (nonatomic, copy, nullable) void (^onOpen)(void);

/// Gọi khi bung/thu thẻ (đổi chiều cao) → host xếp lại panel + đổi cỡ popover.
@property (nonatomic, copy, nullable) void (^onLayoutChanged)(void);

/// Đọc lại kiểu gõ / bảng mã / trạng thái Việt-Anh và cập nhật control.
- (void)refresh;

/// Chiều cao thẻ theo trạng thái (thu gọn / bung) để host xếp trong panel.
- (CGFloat)preferredHeight;

/// [MINDFUL] Popover 3-tab ("Áo mới" Bước 1) — gọi 1 LẦN ngay sau khi tạo view khi đặt trong
/// tab "Bộ gõ" riêng: bung nội dung sẵn (không chờ bấm mở) + ẩn hàng tiêu đề "● Bộ gõ Telex ▸"
/// (tab đã có nhãn riêng nên hàng đó thừa).
- (void)expandForTabPresentation;

@end

NS_ASSUME_NONNULL_END
