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

NS_ASSUME_NONNULL_END
