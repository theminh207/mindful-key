//
//  OnboardingUI.m
//  mindful-key — iOS container app (onboarding, story 1.7)
//

#import "OnboardingUI.h"
#import "BrandColorsUIKit.h"

@implementation OnboardingUI

+ (UILabel *)mk_baseLabelStyle:(UIFontTextStyle)style text:(NSString *)text color:(UIColor *)color {
    UILabel *l = [[UILabel alloc] init];
    l.text = text;
    l.font = [UIFont preferredFontForTextStyle:style];
    l.adjustsFontForContentSizeCategory = YES;   // Dynamic Type
    l.textColor = color;
    l.numberOfLines = 0;
    l.translatesAutoresizingMaskIntoConstraints = NO;
    return l;
}

+ (UILabel *)titleLabel:(NSString *)text {
    UILabel *l = [self mk_baseLabelStyle:UIFontTextStyleTitle2 text:text color:[BrandColorsUIKit inkPrimary]];
    // .title2 mặc định Regular → làm đậm Semibold, GIỮ Dynamic Type (metrics scale font đậm).
    UIFontDescriptor *d = [[UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleTitle2]
                           fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
    l.font = [UIFontMetrics.defaultMetrics scaledFontForFont:[UIFont fontWithDescriptor:d size:0]];
    l.accessibilityTraits |= UIAccessibilityTraitHeader;
    return l;
}

+ (UILabel *)subtitleLabel:(NSString *)text {
    return [self mk_baseLabelStyle:UIFontTextStyleSubheadline text:text color:[BrandColorsUIKit inkSecondary]];
}

+ (UILabel *)bodyLabel:(NSString *)text {
    return [self mk_baseLabelStyle:UIFontTextStyleBody text:text color:[BrandColorsUIKit inkPrimary]];
}

+ (UIButton *)primaryCTA:(NSString *)title {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    [b setTitle:title forState:UIControlStateNormal];
    [b setTitleColor:[BrandColorsUIKit onOrange] forState:UIControlStateNormal];   // chữ TỐI (luật cứng §3)
    b.backgroundColor = [BrandColorsUIKit orange];
    b.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline]; // .body Semibold ~ headline
    b.titleLabel.adjustsFontForContentSizeCategory = YES;
    b.titleLabel.numberOfLines = 0;
    b.titleLabel.textAlignment = NSTextAlignmentCenter;
    b.layer.cornerRadius = 8.0;   // radius.control
    b.translatesAutoresizingMaskIntoConstraints = NO;
    b.contentEdgeInsets = UIEdgeInsetsMake(14, 16, 14, 16);
    [b.heightAnchor constraintGreaterThanOrEqualToConstant:50.0].active = YES;   // CTA Màn 01 ≥ 50pt
    return b;
}

+ (UIButton *)ghostButton:(NSString *)title {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    [b setTitle:title forState:UIControlStateNormal];
    [b setTitleColor:[BrandColorsUIKit brandTeal] forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    b.titleLabel.adjustsFontForContentSizeCategory = YES;
    b.titleLabel.numberOfLines = 0;
    b.titleLabel.textAlignment = NSTextAlignmentCenter;
    b.translatesAutoresizingMaskIntoConstraints = NO;
    [b.heightAnchor constraintGreaterThanOrEqualToConstant:44.0].active = YES;   // hit target sàn cứng
    return b;
}

+ (UIView *)stepIndicatorCurrent:(NSInteger)current total:(NSInteger)total {
    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisHorizontal;
    stack.distribution = UIStackViewDistributionFillEqually;
    stack.spacing = 6;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    for (NSInteger i = 1; i <= total; i++) {
        UIView *seg = [[UIView alloc] init];
        seg.backgroundColor = (i == current) ? [BrandColorsUIKit brandTeal] : [BrandColorsUIKit divider];
        seg.layer.cornerRadius = 2.0;
        seg.translatesAutoresizingMaskIntoConstraints = NO;
        [seg.heightAnchor constraintEqualToConstant:4.0].active = YES;
        [seg.widthAnchor constraintEqualToConstant:22.0].active = YES;
        [stack addArrangedSubview:seg];
    }
    stack.isAccessibilityElement = YES;
    stack.accessibilityLabel = [NSString stringWithFormat:@"Bước %ld trên %ld", (long)current, (long)total];
    return stack;
}

@end
