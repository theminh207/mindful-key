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

static const CGFloat kCardRadius   = 16.0;
static const CGFloat kCardBorder   = 1.5;   // viền teal đậm hơn card khác (card khác không viền)
static const CGFloat kPad          = 16.0;

@implementation GatekeeperCardView {
    EmotionWaveView *_wave;
    NSTextField *_title;
    NSTextField *_desc;
    NSButton *_reflectLink;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
    if ((self = [super initWithFrame:frameRect])) {
        self.wantsLayer = YES;
        self.layer.cornerRadius = kCardRadius;
        self.layer.borderWidth = kCardBorder;
        self.layer.borderColor = [Brand teal].CGColor;
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

- (void)layout {
    [super layout];
    CGFloat w = NSWidth(self.bounds);
    CGFloat top = NSHeight(self.bounds) - kPad;

    NSSize titleSize = _title.intrinsicContentSize;
    _title.frame = NSMakeRect(kPad, top - titleSize.height, w - 2 * kPad, titleSize.height);

    CGFloat waveY = NSMinY(_title.frame) - 8 - 24;
    _wave.frame = NSMakeRect(kPad, waveY, w - 2 * kPad, 24);

    NSSize linkSize = _reflectLink.attributedTitle.size;
    _reflectLink.frame = NSMakeRect(w - kPad - linkSize.width - 8, kPad - 2, linkSize.width + 8, linkSize.height + 4);

    CGFloat descW = w - 2 * kPad - linkSize.width - 12;
    _desc.frame = NSMakeRect(kPad, kPad - 2, descW, 32);
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
