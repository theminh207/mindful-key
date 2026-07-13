//
//  PanelViewController.mm
//  Mindful Keyboard — based on OpenKey
//
//  [MINDFUL] "Áo mới" Bước 1 — xem PanelViewController.h.
//

#import "PanelViewController.h"
#import "GatekeeperCardView.h"
#import "BellSettingsView.h"
#import "InputMethodCardView.h"
#import "BrandColors.h"

static const CGFloat kPanelW  = 360.0;
static const CGFloat kMargin  = 16.0;
static const CGFloat kCardW   = kPanelW - 2 * kMargin;   // 328
static const CGFloat kHeaderH = 38.0;
static const CGFloat kFooterH = 34.0;

// Thanh tab (đầu popover, dưới header) — kiểu Haynoi: track nền xám nhạt, ô đang chọn = pill
// TRẮNG nổi (bóng nhẹ) + chữ đậm hơn. CỐ Ý không dùng teal-fill (đó là ngôn ngữ của MKSegmented
// trong BellSettingsView — 1 control khác, ở tầng field-level, không phải nav-level).
static const CGFloat kTabBarH      = 34.0;
static const CGFloat kTabGapTop    = 12.0;   // đáy header → đỉnh tab bar
static const CGFloat kTabGapBottom = 14.0;   // đáy tab bar → đỉnh nội dung

typedef NS_ENUM(NSInteger, MKPanelTab) {
    MKPanelTabToday = 0,   // "Hôm nay" — GatekeeperCardView
    MKPanelTabBell  = 1,   // "Chuông"  — BellSettingsView
    MKPanelTabInput = 2,   // "Bộ gõ"   — InputMethodCardView
};

// View lật (gốc trên-trái, y tăng xuống) để xếp mục top-down tự nhiên. Chính là view của popover
// (không dùng NSScrollView — mỗi tab vừa 1 màn, kích thước popover = kích thước nội dung tab đó).
@interface MKFlippedView : NSView
@end
@implementation MKFlippedView
- (BOOL)isFlipped { return YES; }
@end

#pragma mark - MKTabBar (segmented kiểu Haynoi: track xám nhạt, active = pill trắng nổi)

@interface MKTabBar : NSView
@property (nonatomic, copy) NSArray<NSString *> *titles;
@property (nonatomic, assign) NSInteger selectedIndex;   // 0-based
@property (nonatomic, copy, nullable) void (^onSelect)(NSInteger index);
@end

@implementation MKTabBar {
    NSView *_indicator;                     // pill trắng nổi sau nhãn đang chọn
    NSMutableArray<NSButton *> *_buttons;
}

- (instancetype)initWithFrame:(NSRect)f {
    if ((self = [super initWithFrame:f])) {
        self.wantsLayer = YES;
        self.layer.backgroundColor = [Brand softWhite].CGColor;   // track xám nhạt
        _selectedIndex = 0;
        _buttons = [NSMutableArray array];

        _indicator = [[NSView alloc] initWithFrame:NSZeroRect];
        _indicator.wantsLayer = YES;
        _indicator.layer.backgroundColor = [NSColor whiteColor].CGColor;
        // Bóng nhẹ (KHÔNG phải viền màu cảm xúc) — chỉ để ô đang chọn "nổi" lên khỏi track.
        _indicator.layer.shadowColor = [NSColor blackColor].CGColor;
        _indicator.layer.shadowOpacity = 0.12;
        _indicator.layer.shadowRadius = 3.0;
        _indicator.layer.shadowOffset = CGSizeMake(0, -1.0);
        [self addSubview:_indicator];
    }
    return self;
}

- (void)setTitles:(NSArray<NSString *> *)titles {
    _titles = [titles copy];
    for (NSButton *b in _buttons) [b removeFromSuperview];
    [_buttons removeAllObjects];
    for (NSUInteger i = 0; i < titles.count; i++) {
        NSButton *b = [NSButton buttonWithTitle:@"" target:self action:@selector(onTapSegment:)];
        b.tag = (NSInteger)i;
        b.bordered = NO;
        ((NSButtonCell *)b.cell).backgroundColor = [NSColor clearColor];
        [self addSubview:b];
        [_buttons addObject:b];
    }
    [self updateAppearance];
    self.needsLayout = YES;
}

- (void)setSelectedIndex:(NSInteger)i {
    if (_selectedIndex == i) return;
    _selectedIndex = i;
    [self updateAppearance];
    self.needsLayout = YES;
}

- (void)onTapSegment:(NSButton *)sender {
    if (sender.tag == _selectedIndex) return;
    _selectedIndex = sender.tag;
    [self updateAppearance];
    self.needsLayout = YES;
    if (self.onSelect) self.onSelect(_selectedIndex);
}

- (void)updateAppearance {
    for (NSUInteger i = 0; i < _buttons.count; i++) {
        BOOL sel = ((NSInteger)i == _selectedIndex);
        NSFont *f = [NSFont systemFontOfSize:12.5 weight:(sel ? NSFontWeightSemibold : NSFontWeightRegular)];
        NSColor *c = sel ? [Brand charcoal] : [Brand muted];
        _buttons[i].attributedTitle = [[NSAttributedString alloc] initWithString:(_titles[i] ?: @"")
            attributes:@{ NSForegroundColorAttributeName:c, NSFontAttributeName:f }];
    }
}

- (void)layout {
    [super layout];
    self.layer.cornerRadius = NSHeight(self.bounds) / 2.0;

    NSInteger n = (NSInteger)_buttons.count;
    if (n == 0) return;
    CGFloat segW = NSWidth(self.bounds) / n;
    for (NSInteger i = 0; i < n; i++) {
        _buttons[i].frame = NSMakeRect(i * segW, 0, segW, NSHeight(self.bounds));
    }

    CGFloat inset = 3.0;
    NSRect ind = NSMakeRect(_selectedIndex * segW + inset, inset,
                            segW - 2 * inset, NSHeight(self.bounds) - 2 * inset);
    _indicator.layer.cornerRadius = NSHeight(ind) / 2.0;
    // Trượt nhẹ giữa các ô khi đổi tab; tôn trọng "Giảm chuyển động" (cùng ngôn ngữ PillSwitch).
    if (![[NSWorkspace sharedWorkspace] accessibilityDisplayShouldReduceMotion]) {
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *ctx) {
            ctx.duration = 0.15;
            _indicator.animator.frame = ind;
        } completionHandler:nil];
    } else {
        _indicator.frame = ind;
    }
}

- (NSAccessibilityRole)accessibilityRole { return NSAccessibilityTabGroupRole; }

@end

#pragma mark - PanelViewController

@implementation PanelViewController {
    // Header (chrome teal)
    NSView             *_header;
    NSView             *_hdrDot;       // chấm trắng: bộ gõ Việt đang bật
    NSTextField        *_hdrStatus;    // "Tiếng Việt đang bật"
    NSButton           *_gear;         // ⋯ → menu cũ

    MKTabBar           *_tabBar;       // "Hôm nay · Chuông · Bộ gõ"

    GatekeeperCardView *_gatekeeper;
    BellSettingsView   *_bell;
    InputMethodCardView*_input;
    NSView             *_footerDiv;    // đường kẻ mảnh trước chân trang (kiểu Haynoi)
    NSTextField        *_privacy;

    CGFloat             _lastHeight;   // chiều cao nội dung lần reflow gần nhất
}

- (void)loadView {
    MKFlippedView *root = [[MKFlippedView alloc] initWithFrame:NSMakeRect(0, 0, kPanelW, 400)];
    root.wantsLayer = YES;
    root.layer.backgroundColor = [NSColor whiteColor].CGColor;   // nền trắng liền mạch (Haynoi-style)
    self.view = root;

    [self buildHeader];

    __weak PanelViewController *weakSelf = self;

    _tabBar = [[MKTabBar alloc] initWithFrame:NSZeroRect];
    _tabBar.titles = @[@"Hôm nay", @"Chuông", @"Bộ gõ"];
    _tabBar.onSelect = ^(NSInteger index) { (void)index; [weakSelf reflow]; };
    [root addSubview:_tabBar];

    _gatekeeper = [[GatekeeperCardView alloc] initWithFrame:NSMakeRect(kMargin, 0, kCardW, 96)];
    [root addSubview:_gatekeeper];

    // [MINDFUL] Bell/Input mặc định thu gọn (dùng cho bản scroll-list cũ, xếp chung 1 danh sách).
    // Trong tab riêng thì KHÔNG cần disclosure nữa — tab đã tự phân tách rồi — nên bung sẵn qua
    // API cộng thêm expandForTabPresentation (KHÔNG đổi logic đọc/ghi UserDefaults bên trong).
    _bell = [[BellSettingsView alloc] initWithFrame:NSMakeRect(kMargin, 0, kCardW, 100)];
    [_bell expandForTabPresentation];
    _bell.onLayoutChanged = ^{ [weakSelf reflow]; };   // đổi cao khi 1 mục con trong Chuông bung (vd Nâng cao)
    [root addSubview:_bell];

    _input = [[InputMethodCardView alloc] initWithFrame:NSMakeRect(kMargin, 0, kCardW, 48)];
    [_input expandForTabPresentation];
    _input.onOpen = ^{ if (weakSelf.onOpenFullSettings) weakSelf.onOpenFullSettings(); };
    _input.onLayoutChanged = ^{ [weakSelf reflow]; };
    [root addSubview:_input];

    _footerDiv = [[NSView alloc] initWithFrame:NSZeroRect];
    _footerDiv.wantsLayer = YES;
    _footerDiv.layer.backgroundColor = [Brand divider].CGColor;
    [root addSubview:_footerDiv];

    _privacy = [NSTextField labelWithString:@"Xử lý trên máy · không gửi nội dung gõ đi đâu"];
    _privacy.font = [NSFont systemFontOfSize:11 weight:NSFontWeightRegular];
    _privacy.textColor = [Brand muted];
    _privacy.alignment = NSTextAlignmentCenter;
    _privacy.backgroundColor = [NSColor clearColor];
    _privacy.bordered = NO;
    _privacy.lineBreakMode = NSLineBreakByWordWrapping;
    _privacy.maximumNumberOfLines = 2;
    [root addSubview:_privacy];

    [self refreshAll];
}

- (void)buildHeader {
    _header = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, kPanelW, kHeaderH)];
    _header.wantsLayer = YES;
    _header.layer.backgroundColor = [Brand teal].CGColor;   // chrome ngọc bích
    [self.view addSubview:_header];

    NSTextField *title = [NSTextField labelWithString:@"〜 mindful-key"];
    title.font = [NSFont systemFontOfSize:15 weight:NSFontWeightBold];
    title.textColor = [NSColor whiteColor];
    title.backgroundColor = [NSColor clearColor];
    title.bordered = NO;
    [_header addSubview:title];
    title.frame = NSMakeRect(kMargin, (kHeaderH - 20) / 2.0, 160, 20);

    _gear = [NSButton buttonWithTitle:@"⋯" target:self action:@selector(onGear:)];
    _gear.bordered = NO;
    ((NSButtonCell *)_gear.cell).backgroundColor = [NSColor clearColor];
    _gear.attributedTitle = [[NSAttributedString alloc] initWithString:@"⋯"
        attributes:@{ NSForegroundColorAttributeName:[NSColor whiteColor],
                      NSFontAttributeName:[NSFont systemFontOfSize:16 weight:NSFontWeightBold] }];
    [_header addSubview:_gear];
    _gear.frame = NSMakeRect(kPanelW - kMargin - 24, (kHeaderH - 24) / 2.0, 24, 24);

    _hdrStatus = [NSTextField labelWithString:@"Tiếng Việt đang bật"];
    _hdrStatus.font = [NSFont systemFontOfSize:11 weight:NSFontWeightRegular];
    _hdrStatus.textColor = [NSColor whiteColor];
    _hdrStatus.backgroundColor = [NSColor clearColor];
    _hdrStatus.bordered = NO;
    _hdrStatus.alignment = NSTextAlignmentRight;
    [_header addSubview:_hdrStatus];

    _hdrDot = [[NSView alloc] initWithFrame:NSZeroRect];
    _hdrDot.wantsLayer = YES;
    _hdrDot.layer.backgroundColor = [NSColor whiteColor].CGColor;
    _hdrDot.layer.cornerRadius = 3.5;
    [_header addSubview:_hdrDot];
}

#pragma mark - Refresh + reflow

- (void)refreshAll {
    [_gatekeeper refresh];
    [_bell refresh];
    [_input refresh];

    BOOL vnOn = ([[NSUserDefaults standardUserDefaults] integerForKey:@"InputMethod"] == 1);
    _hdrStatus.stringValue = vnOn ? @"Tiếng Việt đang bật" : @"Đang gõ tiếng Anh";
    _hdrDot.hidden = !vnOn;

    [self reflow];
}

// Header → tab bar → ĐÚNG 1 thẻ đang chọn → chân trang. view = đúng chiều cao nội dung tab đó
// (popover co theo tab, không phải tổng 3 thẻ như bản scroll-list cũ).
- (void)reflow {
    CGFloat y = 0;
    _header.frame = NSMakeRect(0, y, kPanelW, kHeaderH);
    [self layoutHeaderChildren];
    y += kHeaderH;

    y += kTabGapTop;
    _tabBar.frame = NSMakeRect(kMargin, y, kCardW, kTabBarH);
    y += kTabBarH + kTabGapBottom;

    MKPanelTab tab = (MKPanelTab)_tabBar.selectedIndex;
    _gatekeeper.hidden = (tab != MKPanelTabToday);
    _bell.hidden       = (tab != MKPanelTabBell);
    _input.hidden      = (tab != MKPanelTabInput);

    CGFloat contentH;
    switch (tab) {
        case MKPanelTabBell:
            contentH = [_bell preferredHeight];
            _bell.frame = NSMakeRect(kMargin, y, kCardW, contentH);
            break;
        case MKPanelTabInput:
            contentH = [_input preferredHeight];
            _input.frame = NSMakeRect(kMargin, y, kCardW, contentH);
            break;
        case MKPanelTabToday:
        default:
            contentH = [_gatekeeper preferredHeight];
            _gatekeeper.frame = NSMakeRect(kMargin, y, kCardW, contentH);
            break;
    }
    y += contentH;

    _footerDiv.frame = NSMakeRect(0, y, kPanelW, 1.0);  y += 1.0;
    y += 10.0;
    _privacy.frame = NSMakeRect(kMargin, y, kCardW, kFooterH);  y += kFooterH + 12.0;

    _lastHeight = y;
    NSRect rf = self.view.frame; rf.size = NSMakeSize(kPanelW, y); self.view.frame = rf;
    self.preferredContentSize = NSMakeSize(kPanelW, y);   // NSPopover theo dõi để đổi kích thước
}

- (void)layoutHeaderChildren {
    NSSize ss = _hdrStatus.intrinsicContentSize;
    CGFloat statusW = ss.width + 6.0;                   // +6 để không cụt chữ cuối
    CGFloat statusRight = kPanelW - kMargin - 24 - 8;   // 8px trước gear
    _hdrStatus.frame = NSMakeRect(statusRight - statusW, (kHeaderH - ss.height) / 2.0, statusW, ss.height);
    _hdrDot.frame = NSMakeRect(NSMinX(_hdrStatus.frame) - 12, (kHeaderH - 7) / 2.0, 7, 7);
}

- (NSSize)panelContentSize { return NSMakeSize(kPanelW, _lastHeight); }

- (void)onGear:(id)sender {
    if (self.onShowMenu) self.onShowMenu(_gear);
}

@end
