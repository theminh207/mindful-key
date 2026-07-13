//
//  SuggestionBarView.mm
//  mindful-key — iOS keyboard extension (Round 2, story 2.1 + 2.5)
//
//  Xem SuggestionBarView.h. View UIKit thuần (không blur/ảnh nền/bóng nặng, không nạp từ điển)
//  — đúng NFR-01 (trần jetsam ~48-60MB). Nền secondarySystemBackgroundColor khớp màu phím chức
//  năng hiện có (trung tính, không mã hoá valence — hiến chương).
//
//  Story 2.5: con sóng `~` ambient (CAShapeLayer, tự chứa trong file này — KHÔNG import chéo
//  target `ios/App/BrandMarkView`, xem Dev Notes story 2.5 "ràng buộc kiến trúc quan trọng
//  nhất"). Kỹ thuật vẽ (đường sin CAShapeLayer, 1.5 chu kỳ) THAM CHIẾU lại BrandMarkView.m
//  (story 1.7) nhưng viết mới hoàn toàn cho target extension này.

#import "SuggestionBarView.h"
#import "BrandPalette.h"

// Phái sinh dark-mode của brand.teal — KHÔNG có trong BrandPalette.h (đó là nguồn hex GỐC, chỉ
// light). Giá trị y hệt kMkTealDark ở ios/App/BrandColorsUIKit.m (0x4FB6CC) — target extension
// này KHÔNG link được BrandColorsUIKit (khác target, xem Dev Notes), nên lặp lại hằng số cục bộ
// tại đây, đúng tiền lệ "hex value dùng chung, wrapper UIColor viết riêng cho iOS" (story 1.7).
// Nếu đổi màu teal dark sau này, sửa CẢ 2 nơi (BrandColorsUIKit.m + file này).
#define kMkTealDarkExtension 0x4FB6CC

// Biên độ pixel tối đa = tỉ lệ chiều cao thanh — khớp `mk_highAmplitude` (0.32) của BrandMarkView
// làm chuẩn thị giác thống nhất xuyên brand. amplitude=0.0 (vùng chết Q1) vẽ ra ĐƯỜNG THẲNG tuyệt
// đối (khác BrandMarkView, vốn luôn có biên độ nền tối thiểu) — đúng nghĩa "mặt hồ phẳng" AC#1.
static const CGFloat kWaveMaxAmplitudeFraction = 0.32;
static NSString *const kWaveTransitionAnimationKey = @"mkEmotionWaveTransition";

const CGFloat SuggestionBarViewHeight = 40;

static UIColor *SuggestionBarWaveColor(void) {
    return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *tc) {
        UInt32 hex = (tc.userInterfaceStyle == UIUserInterfaceStyleDark) ? kMkTealDarkExtension : kBrandPaletteTeal;
        return [UIColor colorWithRed:((hex >> 16) & 0xFF) / 255.0
                               green:((hex >> 8) & 0xFF) / 255.0
                                blue:(hex & 0xFF) / 255.0
                               alpha:1.0];
    }];
}

@interface SuggestionBarView ()
@property (nonatomic, strong, nullable) CAShapeLayer *waveLayer;   // lazy — chỉ tạo khi gọi setWaveAmplitude: lần đầu (AC#7)
@property (nonatomic, assign) double lastWaveAmplitude;            // 0.0-1.0, để vẽ lại đúng khi Reduce Motion đổi giữa phiên
@end

@implementation SuggestionBarView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.backgroundColor = [UIColor secondarySystemBackgroundColor];
        [self.heightAnchor constraintEqualToConstant:SuggestionBarViewHeight].active = YES;
        // Bar rỗng không có nội dung trực quan cho VoiceOver — không chặn focus của các phím bên
        // dưới. Con sóng story 2.5 CŨNG là trang trí thuần tuý (Q2: chỉ sóng, không chữ) — không
        // đổi cờ này khi sóng bắt đầu vẽ, không có gì để đọc kèm theo (xem Dev Notes AC#7).
        self.isAccessibilityElement = NO;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                   selector:@selector(mk_reduceMotionStatusChanged)
                                                       name:UIAccessibilityReduceMotionStatusDidChangeNotification
                                                     object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setSuggestions:(NSArray<NSString *> *)suggestions {
    // Story 2.1: hố cắm sẵn, KHÔNG wiring giả. Engine chưa có API gợi ý từ/tự sửa lỗi (xem audit
    // trong Dev Agent Record của story 2.1) nên nơi gọi hàm này trong story chỉ truyền mảng rỗng
    // — thân hàm để trống là chủ đích (không render gì), không phải bug bỏ sót.
}

#pragma mark - Story 2.5: con sóng ambient

- (void)setWaveAmplitude:(double)amplitude {
    double clamped = amplitude < 0.0 ? 0.0 : (amplitude > 1.0 ? 1.0 : amplitude);
    self.lastWaveAmplitude = clamped;

    if (self.waveLayer == nil) {
        [self mk_createWaveLayer];
    }
    [self mk_applyAmplitude:clamped animated:!UIAccessibilityIsReduceMotionEnabled()];
}

- (void)mk_createWaveLayer {
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.fillColor = [UIColor clearColor].CGColor;
    layer.strokeColor = SuggestionBarWaveColor().CGColor;   // AC#3: teal cố định, không nhánh theo risk
    layer.lineWidth = 2.0;
    layer.lineCap = kCALineCapRound;
    layer.lineJoin = kCALineJoinRound;
    layer.frame = self.bounds;
    [self.layer addSublayer:layer];
    self.waveLayer = layer;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.waveLayer == nil) return;   // chưa từng gọi setWaveAmplitude: -> không có gì để vẽ lại
    self.waveLayer.frame = self.bounds;
    // Đổi cỡ khung (vd xoay máy) — vẽ lại tĩnh ở đúng biên độ hiện tại, không animate transition.
    [self mk_applyAmplitude:self.lastWaveAmplitude animated:NO];
}

- (void)mk_reduceMotionStatusChanged {
    if (self.waveLayer == nil) return;
    [self mk_applyAmplitude:self.lastWaveAmplitude animated:!UIAccessibilityIsReduceMotionEnabled()];
}

// AC#1/#5: vẽ path ở amplitude [0.0-1.0] đã chuẩn hoá. `animated=NO` (Reduce Motion BẬT, hoặc
// layout lại) -> set path TĨNH tức thời, đúng hình sóng ở biên độ hiện tại (KHÔNG phải đường
// phẳng cứng trừ khi amplitude thật sự = 0, KHÔNG biến mất). `animated=YES` -> chuyển tiếp mượt
// từ path cũ sang path mới (CABasicAnimation "path", ~0.35s) thay vì nhảy cấp đột ngột — đây là
// phần "dao động"/sự sống của con sóng theo AC#5 (khi Reduce Motion tắt); KHÔNG phải animation
// lặp vô hạn (tránh giật hình khi risk cập nhật dồn dập, xem Testing story 2.5 edge case).
- (void)mk_applyAmplitude:(double)amplitude animated:(BOOL)animated {
    CGFloat ampPx = (CGFloat)amplitude * CGRectGetHeight(self.bounds) * kWaveMaxAmplitudeFraction;
    UIBezierPath *newPath = [self mk_wavePathWithAmplitudePixels:ampPx];

    if (!animated) {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];   // set tức thời, không để implicit animation của CALayer chen vào
        self.waveLayer.path = newPath.CGPath;
        [CATransaction commit];
        [self.waveLayer removeAnimationForKey:kWaveTransitionAnimationKey];
        return;
    }

    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"path"];
    anim.fromValue = (__bridge id)(self.waveLayer.presentationLayer.path ?: self.waveLayer.path);
    anim.toValue = (__bridge id)newPath.CGPath;
    anim.duration = 0.35;
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [self.waveLayer addAnimation:anim forKey:kWaveTransitionAnimationKey];
    self.waveLayer.path = newPath.CGPath;   // giá trị model cập nhật ngay — animation ở trên chỉ là hiệu ứng chuyển tiếp thị giác
}

// Đường sin 1.5 chu kỳ gợi hình dấu ngã `~` — cùng công thức tham chiếu BrandMarkView.m (story 1.7).
- (UIBezierPath *)mk_wavePathWithAmplitudePixels:(CGFloat)ampPx {
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGFloat w = CGRectGetWidth(self.bounds);
    CGFloat midY = CGRectGetHeight(self.bounds) / 2.0;
    NSInteger steps = 48;
    for (NSInteger i = 0; i <= steps; i++) {
        CGFloat t = (CGFloat)i / (CGFloat)steps;
        CGFloat x = t * w;
        CGFloat y = midY - ampPx * sin(t * (CGFloat)M_PI * 3.0);   // 1.5 chu kỳ
        if (i == 0) {
            [path moveToPoint:CGPointMake(x, y)];
        } else {
            [path addLineToPoint:CGPointMake(x, y)];
        }
    }
    return path;
}

@end
