//
//  BrandMarkView.h
//  mindful-key — iOS container app (onboarding, story 1.7)
//
//  Con sóng `~` (dấu ngã) — nhận diện lõi theo hiến chương §2.3 (biến hình theo BIÊN ĐỘ, trung
//  tính, "quan sát không phán xét"). Vẽ bằng CAShapeLayer, KHÔNG phải asset chính thức.
//
//  // TODO(chủ dự án): asset nhận diện chờ chốt Q10b — glyph sóng đây là PLACEHOLDER tự vẽ.
//  Khi chủ dự án chốt glyph sóng chính thức (SVG/vector) + wordmark, thay chỗ này.
//
//  2 kiểu: Wave (sóng gợn — "có nhịp/xảy ra") và Flat (đường phẳng — "không xảy ra"), phục vụ
//  "cặp biên độ mang nghĩa" ở Màn 02 (DESIGN.md §2.10). Nghĩa nằm ở NHÃN CHỮ đi kèm, view này
//  chỉ minh hoạ → isAccessibilityElement = NO. Reduce Motion: sóng ĐỨNG YÊN (vẫn là hình sóng,
//  chỉ dừng chuyển động — AC #6).
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, BrandMarkStyle) {
    BrandMarkStyleWave = 0,   // sóng `~` teal, gợn biên độ (ambient)
    BrandMarkStyleFlat,       // đường phẳng stoneStrong, tĩnh (điểm nhấn "không bao giờ")
};

@interface BrandMarkView : UIView

- (instancetype)initWithStyle:(BrandMarkStyle)style;

// Bật/tắt animation biên độ. Tự bỏ qua khi Reduce Motion bật (giữ sóng đứng yên).
- (void)startWaveAnimationIfAllowed;
- (void)stopWaveAnimation;

@end
