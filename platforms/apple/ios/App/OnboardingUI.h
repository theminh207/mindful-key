//
//  OnboardingUI.h
//  mindful-key — iOS container app (onboarding, story 1.7)
//
//  Xưởng dựng UI dùng chung cho 3 màn onboarding (Kích hoạt / Full Access / Home) — gom style
//  tiêu đề, CTA, nút ghost, chỉ báo bước, header nhận diện về 1 chỗ (DRY + nhất quán a11y).
//
//  Type dùng iOS Text Styles (Dynamic Type) — KHÔNG hard-code pt (DESIGN.md §1.2). Mọi label
//  bật adjustsFontForContentSizeCategory để co giãn theo cài đặt người dùng (NFR-09).
//  // TODO(chủ dự án): font brand Montserrat/Inter (DESIGN.md §1.2) chờ bundle — tạm dùng SF Pro
//  hệ thống để có Dynamic Type miễn phí; gắn với đợt chốt asset Q10b.
//

#import <UIKit/UIKit.h>

@interface OnboardingUI : NSObject

+ (UILabel *)titleLabel:(NSString *)text;       // .title2 Semibold, ink.primary, trait heading
+ (UILabel *)subtitleLabel:(NSString *)text;    // .subheadline, ink.secondary
+ (UILabel *)bodyLabel:(NSString *)text;        // .body, ink.primary
+ (UIButton *)primaryCTA:(NSString *)title;     // cam, chữ tối, cao ≥ 50pt, radius 8
+ (UIButton *)ghostButton:(NSString *)title;    // chữ teal, nền trong suốt, hit ≥ 44pt

// Chỉ báo bước trình tự (KHÔNG phải thanh phần thưởng) — a11y "Bước {current} trên {total}".
+ (UIView *)stepIndicatorCurrent:(NSInteger)current total:(NSInteger)total;

@end
