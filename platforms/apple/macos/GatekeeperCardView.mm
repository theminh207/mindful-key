//
//  GatekeeperCardView.mm
//  Mindful Keyboard — based on OpenKey
//
//  [MINDFUL] Story 1.4 / Áo mới v2 — xem GatekeeperCardView.h cho hợp đồng + ràng buộc hiến chương.
//

#import "GatekeeperCardView.h"
#import "EmotionWaveView.h"
#import "BrandColors.h"
#import "BrandControls.h"
#import "MoodWatchMac.h"
#import "ReflectionScreenMac.h"

static const CGFloat kPad         = 14.0;  // padding trong thẻ (mockup .card: 13px 14px)
static const CGFloat kWaveH       = 26.0;
static const CGFloat kWaveGap     = 6.0;   // sóng → tít
static const CGFloat kTitleH      = 20.0;  // tít trạng thái, 16pt semibold
static const CGFloat kTitleGap    = 8.0;   // tít → hàng phụ đề/link
static const CGFloat kSubRowH     = 34.0;  // hàng phụ đề/link — chừa chỗ tối đa 2 dòng cho state "tắt"

@implementation GatekeeperCardView {
    EmotionWaveView *_wave;
    NSTextField *_title;    // câu TRẠNG THÁI động ("Mặt hồ đang gợn nhẹ"...) — KHÔNG còn tít tĩnh
    NSTextField *_caption;  // "Gác cổng đang canh khi anh gõ" / "Bật lại trong Cài đặt..."
    NSButton *_reflectLink; // "Soi lại hôm nay →" — cam, link (KHÔNG phải CTA)
}

- (instancetype)initWithFrame:(NSRect)frameRect {
    if ((self = [super initWithFrame:frameRect])) {
        // [MINDFUL] Áo mới v2 — thẻ TRẮNG viền mảnh (thay dải nền tealLight cũ).
        [self applyThinCardStyle];

        _wave = [[EmotionWaveView alloc] initWithFrame:NSZeroRect];  // mặc định thu gọn
        [self addSubview:_wave];

        _title = [self labelWithString:@"" font:[NSFont systemFontOfSize:16 weight:NSFontWeightSemibold] color:[Brand charcoal]];
        [self addSubview:_title];

        _caption = [self labelWithString:@"" font:[NSFont systemFontOfSize:12.5 weight:NSFontWeightRegular] color:[Brand muted]];
        _caption.lineBreakMode = NSLineBreakByWordWrapping;
        _caption.maximumNumberOfLines = 2;
        [self addSubview:_caption];

        // "Soi lại hôm nay →" — link text (KHÔNG phải nút cam CTA), tông cam.
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
        NSForegroundColorAttributeName : [Brand orange],
        NSFontAttributeName : [NSFont systemFontOfSize:12.5 weight:NSFontWeightSemibold]
    }];
}

#pragma mark - Layout (frame-based, để khớp panel absolute-frame hiện tại)

- (CGFloat)preferredHeight { return kPad + kWaveH + kWaveGap + kTitleH + kTitleGap + kSubRowH + kPad; }

- (void)layout {
    [super layout];
    CGFloat w = NSWidth(self.bounds);
    CGFloat h = NSHeight(self.bounds);
    CGFloat top = h - kPad;

    _wave.frame = NSMakeRect(kPad, top - kWaveH, w - 2 * kPad, kWaveH);
    top -= kWaveH + kWaveGap;

    _title.frame = NSMakeRect(kPad, top - kTitleH, w - 2 * kPad, kTitleH);
    top -= kTitleH + kTitleGap;

    // Hàng phụ đề (trái) + link (phải), canh dòng đầu.
    NSSize linkSize = _reflectLink.attributedTitle.size;
    _reflectLink.frame = NSMakeRect(w - kPad - linkSize.width, top - linkSize.height,
                                    linkSize.width, linkSize.height);
    _caption.frame = NSMakeRect(kPad, top - kSubRowH, w - 2 * kPad - linkSize.width - 10.0, kSubRowH);
}

#pragma mark - State

- (void)refresh {
    BOOL enabled = MoodWatchMac_IsEnabled() != 0;
    if (enabled) {
        double risk = MoodWatchMac_LastSendRisk();   // 0..1 (concern #1: input duy nhất của sóng)
        [_wave setAmplitude:(CGFloat)risk animated:YES];
        // [MINDFUL] Áo mới v2 — tít = TRẠNG THÁI, lấy thẳng từ EmotionWaveView (đã tự phân 3 mức
        // theo biên độ: phẳng lặng / gợn nhẹ / gợn sóng). KHÔNG tự chế câu khác ở đây.
        _title.stringValue = _wave.stateDescription;
        _caption.stringValue = @"Gác cổng đang canh khi anh gõ";
    } else {
        // State "tắt": sóng phẳng + copy trung tính. KHÔNG đỏ/xám-chết.
        [_wave setAmplitude:0 animated:NO];
        _title.stringValue = @"Gác cổng đang tắt";
        _caption.stringValue = @"Bật lại trong Cài đặt khi anh sẵn sàng";
    }
    self.needsLayout = YES;
}

- (void)onReflect:(id)sender {
    ReflectionScreenMac_Show();
}

@end
