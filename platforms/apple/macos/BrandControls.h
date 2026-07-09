//
//  BrandControls.h
//  Mindful Keyboard — based on OpenKey
//
//  [MINDFUL] Story 1.1 — bộ control AppKit tái dùng theo token NOW BRAND OS.
//  3 control nền tảng cho các card sau (1.3–1.6) dùng lại: PillSwitch, StatusDot, CTAButton.
//
//  Ràng buộc HIẾN CHƯƠNG khoá trong file này (xem docs/AGENT-BRIEF.md §2.2/2.3):
//    - PillSwitch bật = teal (KHÔNG dùng màu xanh-lá hệ thống / tint mặc định NSSwitch).
//    - StatusDot chỉ nhận boolean bật/tắt — KHÔNG tham số biên độ/mức/màu, để không ai
//      lỡ dùng nó biểu đạt cảm xúc.
//    - CTAButton nền cam + chữ TỐI ở MỌI state (chữ trắng trên cam trượt WCAG 2.61:1).
//    - KHÔNG SF Symbol mặt người / icon cảnh báo hệ thống, KHÔNG màu semantic đỏ/vàng/xanh-lá.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

/// Toggle kiểu "pill" vẽ tay để đảm bảo màu bật = NOW Teal (NSSwitch hệ thống không đổi
/// được màu xanh-lá mặc định nếu không dùng API riêng tư). Bật = teal, tắt = divider.
/// Dùng như 1 control target/action thông thường.
@interface PillSwitch : NSControl
/// Trạng thái bật/tắt. Set qua đây không bắn action; click của người dùng mới bắn action.
@property (nonatomic, assign, getter=isOn) BOOL on;
- (void)setOn:(BOOL)on animated:(BOOL)animated;
@end

/// Dấu chấm trạng thái KỸ THUẬT nhị phân (1 màu duy nhất): bật = tô đặc teal,
/// tắt = chỉ viền divider không tô. API cố tình CHỈ nhận boolean — không có tham số
/// biên độ/mức/màu, để không component nào dùng lại nó cho trạng thái cảm xúc.
@interface StatusDot : NSView
@property (nonatomic, assign, getter=isOn) BOOL on;
- (void)setOn:(BOOL)on;
@end

/// Nút hành động (CTA): nền NOW Orange, chữ TỐI (charcoal) ở mọi state, bo góc 8px.
/// Cam CHỈ được dùng ở đây trong bộ control này. Có đủ hover/focus/active/disabled.
@interface CTAButton : NSButton
@end

/// [MINDFUL] Story 1.9 — mở rộng BrandControls (không đổi API PillSwitch/StatusDot/CTAButton
/// đã "done" ở story 1.1). Nút phụ trung tính (Đóng/Xoá/Nạp file/Xuất file…): nền trắng, viền
/// Brand.divider 1px, chữ charcoal, bo góc 8px. Cùng kiểu hover/focus/active/disabled như
/// CTAButton nhưng KHÔNG BAO GIỜ cam — cam CHỈ được dùng ở CTAButton.
@interface SecondaryButton : NSButton
@end

/// [MINDFUL] Story 1.9 — helper card-wrap tái dùng cho các story thay áo sau (1.7/1.8/1.10):
/// áp bo góc 16px + bóng ngọc bích `0 8px 30px rgba(29,124,145,0.08)` + nền trắng lên 1
/// container view bất kỳ (NSView hoặc subclass, kể cả NSBox khi đã tắt fill/border gốc).
@interface NSView (BrandCard)
- (void)applyBrandCardStyle;
@end

NS_ASSUME_NONNULL_END
