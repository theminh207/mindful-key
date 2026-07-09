//
//  BrandColors.h
//  Mindful Keyboard — based on OpenKey
//
//  Token màu NOW BRAND OS (docs/BRAND-ASSETS.md). Đọc từ Assets.xcassets Color Set —
//  KHÔNG hard-code hex ở đây để tránh lệch giữa asset catalog và code khi brand đổi màu.

#import <Cocoa/Cocoa.h>

@interface Brand : NSObject

+ (NSColor *)teal;         // #1D7C91 — thương hiệu chính, tiêu đề
+ (NSColor *)tealLight;    // #E8F2F4 — hover, nền phụ
+ (NSColor *)orange;       // #FF7A1A — CTA/lớp nhịp thở/khoảnh khắc con người — KHÔNG dùng để mã hóa trạng thái cảm xúc
+ (NSColor *)orangeLight;  // #FFF2E8
+ (NSColor *)charcoal;     // #2A2A2A — chữ chính
+ (NSColor *)muted;        // #666666 — chữ phụ
+ (NSColor *)softWhite;    // #F8F8F8 — nền trang/card
+ (NSColor *)divider;      // #E5E7E8 — đường ngăn mảnh, viền/nền off của toggle
+ (NSColor *)stone;        // #8A9BA0 — sắc độ trung tính-đá cho sóng biên độ thấp (KHÔNG dùng như "màu cảnh báo")

@end
