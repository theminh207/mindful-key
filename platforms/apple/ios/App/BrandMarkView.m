//
//  BrandMarkView.m
//  mindful-key — iOS container app (onboarding, story 1.7)
//
//  Xem BrandMarkView.h. // TODO(chủ dự án): asset nhận diện chờ chốt Q10b — sóng vẽ tay tạm.
//

#import "BrandMarkView.h"
#import "BrandColorsUIKit.h"

static NSString *const kWaveAnimationKey = @"mkWaveAmplitude";

@interface BrandMarkView ()
@property (nonatomic, assign) BrandMarkStyle style;
@property (nonatomic, strong) CAShapeLayer *waveLayer;
@end

@implementation BrandMarkView

- (instancetype)initWithStyle:(BrandMarkStyle)style {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _style = style;
        self.backgroundColor = [UIColor clearColor];
        self.isAccessibilityElement = NO;   // trang trí — nghĩa nằm ở nhãn chữ đi kèm

        _waveLayer = [CAShapeLayer layer];
        _waveLayer.fillColor = [UIColor clearColor].CGColor;
        _waveLayer.lineWidth = 2.5;
        _waveLayer.lineCap = kCALineCapRound;
        _waveLayer.lineJoin = kCALineJoinRound;
        [self.layer addSublayer:_waveLayer];
        [self mk_applyStrokeColor];
    }
    return self;
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(44, 24);
}

- (void)traitCollectionDidChange:(UITraitCollection *)previous {
    [super traitCollectionDidChange:previous];
    // Màu động (Light/Dark) không tự cập nhật cho CGColor → set lại khi theme đổi.
    [self mk_applyStrokeColor];
}

- (void)mk_applyStrokeColor {
    UIColor *c = (self.style == BrandMarkStyleWave) ? [BrandColorsUIKit brandTeal]
                                                    : [BrandColorsUIKit stoneStrong];
    self.waveLayer.strokeColor = c.CGColor;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.waveLayer.frame = self.bounds;
    // Đường nền: sóng ở biên độ "gợn nhẹ" (mặt hồ phẳng lặng), hoặc đường phẳng.
    CGFloat baseAmp = (self.style == BrandMarkStyleWave) ? [self mk_lowAmplitude] : 0.0;
    self.waveLayer.path = [self mk_wavePathWithAmplitude:baseAmp].CGPath;
}

- (CGFloat)mk_lowAmplitude  { return CGRectGetHeight(self.bounds) * 0.12; }
- (CGFloat)mk_highAmplitude { return CGRectGetHeight(self.bounds) * 0.32; }

// Đường sin 1.5 chu kỳ gợi hình dấu ngã `~`.
- (UIBezierPath *)mk_wavePathWithAmplitude:(CGFloat)amp {
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGFloat w = CGRectGetWidth(self.bounds);
    CGFloat midY = CGRectGetHeight(self.bounds) / 2.0;
    NSInteger steps = 48;
    for (NSInteger i = 0; i <= steps; i++) {
        CGFloat t = (CGFloat)i / (CGFloat)steps;
        CGFloat x = t * w;
        CGFloat y = midY - amp * sin(t * M_PI * 3.0);   // 1.5 chu kỳ
        if (i == 0) {
            [path moveToPoint:CGPointMake(x, y)];
        } else {
            [path addLineToPoint:CGPointMake(x, y)];
        }
    }
    return path;
}

- (void)startWaveAnimationIfAllowed {
    if (self.style != BrandMarkStyleWave) return;              // đường phẳng luôn tĩnh
    if (UIAccessibilityIsReduceMotionEnabled()) return;        // Reduce Motion → đứng yên
    if (CGRectIsEmpty(self.bounds)) return;

    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"path"];
    anim.fromValue = (id)[self mk_wavePathWithAmplitude:[self mk_lowAmplitude]].CGPath;
    anim.toValue   = (id)[self mk_wavePathWithAmplitude:[self mk_highAmplitude]].CGPath;
    anim.duration  = 1.3;                 // 1 chu kỳ gợn ~2.6s (autoreverse) — DESIGN.md §Interaction
    anim.autoreverses = YES;
    anim.repeatCount = HUGE_VALF;
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [self.waveLayer addAnimation:anim forKey:kWaveAnimationKey];
}

- (void)stopWaveAnimation {
    [self.waveLayer removeAnimationForKey:kWaveAnimationKey];
}

@end
