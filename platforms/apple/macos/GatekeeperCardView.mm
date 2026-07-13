//
//  GatekeeperCardView.mm
//  Mindful Keyboard — based on OpenKey
//
//  [MINDFUL] Story 1.4 — xem GatekeeperCardView.h cho hợp đồng + ràng buộc hiến chương.
//

#import "GatekeeperCardView.h"
#import "EmotionWaveView.h"
#import "BrandColors.h"
#import "MoodWatchMac.h"
#import "ReflectionScreenMac.h"

static const CGFloat kPad          = 16.0;
static const CGFloat kTitleH       = 22.0;  // "Gác cổng gửi tin" (system 17pt bold)
static const CGFloat kDescH        = 34.0;  // mô tả tối đa 2 dòng ở bề rộng panel hẹp (~328pt)

@implementation GatekeeperCardView {
    EmotionWaveView *_wave;
    NSTextField *_title;
    NSTextField *_desc;
    NSButton *_reflectLink;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
    if ((self = [super initWithFrame:frameRect])) {
        // [MINDFUL] Compact (như Haynoi): Gác cổng là DẢI nền tealLight full-width (điểm nhấn Feature #1
        // bằng sắc nền, không phải hộp viền) — canh lề thẳng với các mục dưới, nhẹ & gọn.
        self.wantsLayer = YES;
        self.layer.backgroundColor = [Brand tealLight].CGColor;

        _title = [self labelWithString:@"Gác cổng gửi tin"
                                  font:[NSFont systemFontOfSize:17 weight:NSFontWeightBold]
                                 color:[Brand charcoal]];
        [self addSubview:_title];

        _wave = [[EmotionWaveView alloc] initWithFrame:NSZeroRect];  // mặc định thu gọn
        [self addSubview:_wave];

        _desc = [self labelWithString:@"Khi sóng gợn nhiều, mình sẽ dừng lại hỏi trước khi gửi."
                                 font:[NSFont systemFontOfSize:13 weight:NSFontWeightRegular]
                                color:[Brand muted]];
        _desc.lineBreakMode = NSLineBreakByWordWrapping;
        _desc.maximumNumberOfLines = 2;
        [self addSubview:_desc];

        // "Soi lại hôm nay →" — link text (KHÔNG phải nút cam CTA), tông teal.
        _reflectLink = [NSButton buttonWithTitle:@"" target:self action:@selector(onReflect:)];
        _reflectLink.bordered = NO;
        _reflectLink.bezelStyle = NSBezelStyleInline;
        [(NSButtonCell *)_reflectLink.cell setBackgroundColor:[NSColor clearColor]];
        _reflectLink.attributedTitle = [self linkTitle:@"Soi lại hôm nay →"];
        [self addSubview:_reflectLink];

        [self refresh];
    }
    return self;
}

- (NSTextField *)labelWithString:(NSString *)s font:(NSFont *)f color:(NSColor *)c {
    NSTextField *l = [NSTextField labelWithString:s];
    l.font = f;
    l.textColor = c;
    l.backgroundColor = [NSColor clearColor];
    l.bordered = NO;
    l.editable = NO;
    return l;
}

- (NSAttributedString *)linkTitle:(NSString *)s {
    return [[NSAttributedString alloc] initWithString:s attributes:@{
        NSForegroundColorAttributeName : [Brand teal],
        NSFontAttributeName : [NSFont systemFontOfSize:13 weight:NSFontWeightSemibold]
    }];
}

#pragma mark - Layout (frame-based, để khớp panel absolute-frame hiện tại)

- (CGFloat)preferredHeight { return kPad + kTitleH + 8.0 + kDescH + kPad; }

- (void)layout {
    [super layout];
    CGFloat w = NSWidth(self.bounds);
    CGFloat h = NSHeight(self.bounds);
    CGFloat top = h - kPad;

    // Hàng trên: tiêu đề (trái) + link "Soi lại hôm nay →" (phải), cùng hàng.
    NSSize linkSize = _reflectLink.attributedTitle.size;
    _reflectLink.frame = NSMakeRect(w - kPad - linkSize.width - 8, top - kTitleH - 2,
                                    linkSize.width + 8, kTitleH + 4);
    _title.frame = NSMakeRect(kPad, top - kTitleH, w - 2 * kPad - linkSize.width - 12, kTitleH);

    // Hàng dưới: sóng (trái) + mô tả 2 dòng (phải), canh dòng đầu — sóng KHÔNG vẽ chồng lên chữ.
    CGFloat descTop = top - kTitleH - 8.0;   // đỉnh vùng mô tả (đo từ trên xuống)
    CGFloat waveW = 56.0, waveH = 18.0;
    _wave.frame = NSMakeRect(kPad, descTop - waveH, waveW, waveH);
    CGFloat descX = kPad + waveW + 10.0;
    _desc.frame = NSMakeRect(descX, descTop - kDescH, w - descX - kPad, kDescH);
}

#pragma mark - State

- (void)refresh {
    BOOL enabled = MoodWatchMac_IsEnabled() != 0;
    if (enabled) {
        double risk = MoodWatchMac_LastSendRisk();   // 0..1 (concern #1: input duy nhất của sóng)
        [_wave setAmplitude:(CGFloat)risk animated:YES];
        _desc.stringValue = @"Khi sóng gợn nhiều, mình sẽ dừng lại hỏi trước khi gửi.";
    } else {
        // State "tắt": sóng phẳng + copy trung tính. KHÔNG đỏ/xám-chết.
        [_wave setAmplitude:0 animated:NO];
        _desc.stringValue = @"Gác cổng đang tắt.";
    }
    [_desc setTextColor:[Brand muted]];
    self.needsLayout = YES;
}

- (void)onReflect:(id)sender {
    ReflectionScreenMac_Show();
}

@end
