//
//  BrandColorsUIKit.h
//  mindful-key — iOS container app (onboarding, story 1.7)
//
//  Wrapper UIColor CỤC BỘ cho container app. Đọc hex gốc từ shared/BrandPalette.h (nguồn màu
//  dùng chung macOS/iOS — KHÔNG sửa file đó) và khai thêm 2 hằng số PHÁI SINH đã kiểm contrast
//  thật (tealStrong, stoneStrong) — theo DESIGN.md §1.1/§2.10/§3, cố ý KHÔNG nhét vào
//  BrandPalette.h (đó là nguồn màu GỐC).
//
//  Cặp light/dark lấy từ DESIGN.md §1.1 (số đã verify). Màu chỉ TRANG TRÍ/CTA — TUYỆT ĐỐI
//  không dùng để mã hoá cảm xúc (hiến chương §2.2). Nút cam luôn đi với chữ TỐI (ink.primary),
//  luật cứng §3, cả 2 theme.
//

#import <UIKit/UIKit.h>

@interface BrandColorsUIKit : NSObject

+ (UIColor *)surfacePage;    // nền màn
+ (UIColor *)surfaceCard;    // nền card / reassure
+ (UIColor *)inkPrimary;     // chữ chính (cũng là chữ trên nút cam)
+ (UIColor *)inkSecondary;   // chữ phụ / helper / fallback (KHÔNG tô đỏ khi lỗi hệ thống)
+ (UIColor *)brandTeal;      // tiêu đề/link/sóng
+ (UIColor *)tealStrong;     // chữ trên nền tealLight (số bước) — phái sinh
+ (UIColor *)tealLight;      // nền số bước
+ (UIColor *)orange;         // CTA
+ (UIColor *)onOrange;       // chữ trên CTA cam (luôn tối)
+ (UIColor *)stoneStrong;    // đường phẳng "không bao giờ" mang nghĩa — phái sinh
+ (UIColor *)divider;        // step indicator đoạn tắt / đường ngăn (trang trí)

@end
